import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:workers_hub/core/services/auth_service.dart';
import 'package:workers_hub/core/services/database_service.dart';

class JobService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Helper: convert Firestore doc to plain map with 'id' field
  Map<String, dynamic> _docToMap(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return {'id': doc.id, ...data};
  }

  // 1. Real-time stream of ALL jobs
  Stream<List<Map<String, dynamic>>> getJobs() {
    return _db
        .collection('jobs')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_docToMap).toList());
  }

  // 2. My Applications stream (worker)
  Stream<List<Map<String, dynamic>>> getMyApplications(String workerId) {
    return _db
        .collection('applications')
        .where('worker_id', isEqualTo: workerId)
        .snapshots()
        .map((snap) {
          final docs = snap.docs.map(_docToMap).toList();
          // Sort client-side (newest first) — avoids composite index requirement
          docs.sort((a, b) {
            final aTime =
                (a['applied_at'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
            final bTime =
                (b['applied_at'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
            return bTime.compareTo(aTime);
          });
          return docs;
        });
  }

  // 3. Apply for a Job
  Future<void> applyForJob({
    required String jobId,
    required String workerId,
    required Map<String, dynamic> jobData,
  }) async {
    final user = AuthService().currentUser;
    if (user == null) throw Exception('User not logged in');

    // Check for duplicate
    final existing = await _db
        .collection('applications')
        .where('job_id', isEqualTo: jobId)
        .where('worker_id', isEqualTo: workerId)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('You have already applied for this job.');
    }

    // Fetch worker profile for rich applicant data
    Map<String, dynamic>? workerProfile;
    try {
      workerProfile = await DatabaseService().getProfile(workerId);
    } catch (_) {}

    final contractorId = jobData['contractor_id'] ?? jobData['contractorId'];
    final companyName = jobData['company_name'] ?? jobData['companyName'];
    final title = jobData['title'];
    final location = jobData['location'];
    final hourlyRate = jobData['hourly_rate'] ?? jobData['hourlyRate'];
    final workerName = workerProfile?['name'] ?? user.displayName ?? 'Unknown';
    final workerImage = workerProfile?['photo_url'] ?? user.photoURL;
    final workerSkills =
        (workerProfile?['skills'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final workerExperience = workerProfile?['experience'] ?? '';

    await _db.collection('applications').add({
      'job_id': jobId,
      'worker_id': workerId,
      'contractor_id': contractorId,
      'job_title': title,
      'company_name': companyName,
      'location': location,
      'hourly_rate': hourlyRate,
      'worker_name': workerName,
      'worker_image': workerImage,
      'worker_skills': workerSkills,
      'worker_experience': workerExperience,
      'status': 'pending',
      'applied_at': FieldValue.serverTimestamp(),
    });
  }

  // 4. Create Job
  Future<void> createJob(Map<String, dynamic> jobData) async {
    await _db.collection('jobs').add({
      ...jobData,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 5. Get Jobs by Contractor (stream)
  Stream<List<Map<String, dynamic>>> getJobsByContractor(String contractorId) {
    return _db
        .collection('jobs')
        .where('contractor_id', isEqualTo: contractorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_docToMap).toList());
  }

  // 6. Delete Job
  Future<void> deleteJob(String jobId) async {
    await _db.collection('jobs').doc(jobId).delete();
  }

  // 7. Seed Mock Data
  Future<void> seedMockJobs() async {
    final user = AuthService().currentUser;
    final contractorId = user?.uid ?? 'mock_contractor';

    final batch = _db.batch();
    final mockJobs = [
      {
        'title': 'Senior Plumber',
        'company_name': 'Rapid Fix Services',
        'location': 'Mumbai, MH',
        'hourly_rate': 650,
        'description':
            'Looking for an experienced plumber for residential repairs.',
        'contractor_id': contractorId,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': 'Site Electrician',
        'company_name': 'VoltWorks',
        'location': 'Pune, MH',
        'hourly_rate': 800,
        'description': 'Industrial wiring and maintenance work.',
        'contractor_id': contractorId,
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    for (final job in mockJobs) {
      batch.set(_db.collection('jobs').doc(), job);
    }
    await batch.commit();
  }

  // 8. Get Applicants for a specific Job (stream)
  Stream<List<Map<String, dynamic>>> getApplicants(String jobId) {
    return _db
        .collection('applications')
        .where('job_id', isEqualTo: jobId)
        .snapshots()
        .map((snap) => snap.docs.map(_docToMap).toList());
  }

  // 9. Get all applicants for a contractor (stream)
  Stream<List<Map<String, dynamic>>> getAllApplicants(String contractorId) {
    return _db
        .collection('applications')
        .where('contractor_id', isEqualTo: contractorId)
        .snapshots()
        .map((snap) {
          final docs = snap.docs.map(_docToMap).toList();
          // Sort client-side (newest first)
          docs.sort((a, b) {
            final aTime =
                (a['applied_at'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
            final bTime =
                (b['applied_at'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
            return bTime.compareTo(aTime);
          });
          return docs;
        });
  }

  // 10. Update Application Status + send notification message
  Future<void> updateApplicationStatus({
    required String applicationId,
    required String jobId,
    required String workerId,
    required String newStatus,
    String? jobTitle,
    String? contractorId,
  }) async {
    final batch = _db.batch();

    // Update status
    batch.update(_db.collection('applications').doc(applicationId), {
      'status': newStatus,
    });

    // Send notification message to worker
    final msgTitle = newStatus == 'accepted'
        ? 'Application Accepted 🎉'
        : 'Application Update';
    final msgBody = newStatus == 'accepted'
        ? 'Congratulations! Your application for "${jobTitle ?? 'the job'}" has been accepted.'
        : 'Your application for "${jobTitle ?? 'the job'}" has been rejected.';

    batch.set(_db.collection('messages').doc(), {
      'sender_id': contractorId ?? 'system',
      'receiver_id': workerId,
      'title': msgTitle,
      'body': msgBody,
      'job_id': jobId,
      'is_read': false,
      'created_at': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
}
