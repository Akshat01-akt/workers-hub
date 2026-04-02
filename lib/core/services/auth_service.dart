import 'package:firebase_auth/firebase_auth.dart';
import 'package:workers_hub/core/services/database_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _db = DatabaseService();

  // Stream to listen for authentication changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign In
  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Sign Up
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    UserCredential result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    User? user = result.user;
    if (user != null) {
      await user.updateDisplayName(name);

      // Profile creation happens when the user selects a role
      // in the RoleSelectionScreen/RegistrationScreens.

      await signOut(); // Force re-login
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Password Reset
  Future<void> resetPassword({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Create Worker Profile (stored in Firestore)
  Future<void> createWorkerProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    final user = currentUser;
    final email = user?.email ?? '';
    final name = data['name'] ?? user?.displayName ?? '';

    // Create base profile in Firestore
    await _db.createProfile(uid: uid, email: email, role: 'worker', name: name);

    // Update with additional details
    await _db.updateProfile(
      uid: uid,
      phone: data['phone'] ?? data['phoneNumber'],
      skills: data['skill'] != null ? [data['skill'] as String] : null,
      experience: data['experience'],
      hourlyRate: (data['hourlyRate'] as num?)?.toDouble(),
      location: data['location'],
    );
  }

  // Create Contractor Profile (stored in Firestore)
  Future<void> createContractorProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    final user = currentUser;
    final email = user?.email ?? '';
    final name = data['name'] ?? user?.displayName ?? '';

    await _db.createProfile(
      uid: uid,
      email: email,
      role: 'contractor',
      name: name,
    );

    await _db.updateProfile(
      uid: uid,
      phone: data['phone'] ?? data['phoneNumber'],
      companyName: data['companyName'],
      location: data['location'],
    );
  }

  // Get User Role from Firestore
  Future<String?> getUserRole(String uid) async {
    try {
      final profile = await _db.getProfile(uid);
      if (profile != null) {
        return profile['role'] as String?;
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}
