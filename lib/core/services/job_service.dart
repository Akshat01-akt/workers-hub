import 'package:cloud_firestore/cloud_firestore.dart';

class JobService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Fetch Jobs (Real-time stream)
  Stream<QuerySnapshot> getJobs() {
    return _firestore
        .collection('jobs')
        .orderBy('postedAt', descending: true)
        .snapshots();
  }

  // 2. Fetch My Applications
  Stream<QuerySnapshot> getMyApplications(String workerId) {
    return _firestore
        .collection('workers')
        .doc(workerId)
        .collection('applied_jobs')
        .orderBy('appliedAt', descending: true)
        .snapshots();
  }

  // 3. Apply for Job
  Future<void> applyForJob({
    required String jobId,
    required String workerId,
    required Map<String, dynamic> jobData,
  }) async {
    // Check if already applied (Check subcollection for faster read)
    final existingApp = await _firestore
        .collection('workers')
        .doc(workerId)
        .collection('applied_jobs')
        .doc(jobId)
        .get();

    if (existingApp.exists) {
      throw Exception('You have already applied for this job.');
    }

    final applicationData = {
      'jobId': jobId,
      'workerId': workerId,
      'status': 'pending',
      'appliedAt': FieldValue.serverTimestamp(),
      'jobTitle': jobData['title'],
      'companyName': jobData['companyName'],
      'location': jobData['location'],
      'hourlyRate': jobData['hourlyRate'],
    };

    // batch write for atomicity
    final batch = _firestore.batch();

    // 1. Add to global applications collection
    final globalRef = _firestore.collection('applications').doc();
    batch.set(globalRef, applicationData);

    // 2. Add to worker's subcollection
    final workerRef = _firestore
        .collection('workers')
        .doc(workerId)
        .collection('applied_jobs')
        .doc(jobId); // Use jobId as doc ID to easily check existence
    batch.set(workerRef, applicationData);

    await batch.commit();
  }

  // 4. Seed Mock Data (Temporary)
  Future<void> seedMockJobs() async {
    final jobsCollection = _firestore.collection('jobs');
    final snapshot = await jobsCollection.limit(1).get();

    // Only seed if empty
    if (snapshot.docs.isEmpty) {
      final List<Map<String, dynamic>> mockJobs = [
        {
          'title': 'Senior Plumber',
          'companyName': 'Rapid Fix Services',
          'location': 'Mumbai, MH',
          'hourlyRate': 650,
          'description':
              'Looking for an experienced plumber for residential repairs.',
          'postedAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Site Electrician',
          'companyName': 'VoltWorks',
          'location': 'Pune, MH',
          'hourlyRate': 800,
          'description': 'Industrial wiring and maintenance work. Shift based.',
          'postedAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Carpenter Helper',
          'companyName': 'WoodCraft Interiors',
          'location': 'Thane, MH',
          'hourlyRate': 400,
          'description': 'Assist in furniture assembly and wood cutting.',
          'postedAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Civil Supervisor',
          'companyName': 'BuildTower Infra',
          'location': 'Navi Mumbai, MH',
          'hourlyRate': 1200,
          'description':
              'Supervise construction site workers and manage materials.',
          'postedAt': FieldValue.serverTimestamp(),
        },
      ];

      for (var job in mockJobs) {
        await jobsCollection.add(job);
      }
    }
  }
}
