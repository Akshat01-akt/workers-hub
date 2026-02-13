import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream to listen for authentication changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign In
  Future<void> signIn({required String email, required String password}) async {
    UserCredential result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (result.user != null) {
      await _firestore.collection('users').doc(result.user!.uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    }
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
      // Create user document in Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'role': 'new', // Default role, forcing selection later
        'profileImage': null,
      });

      // Update display name
      await user.updateDisplayName(name);

      // Sign out immediately to force user to sign in manually
      await signOut();
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

  // Update User Role
  Future<void> updateUserRole({
    required String uid,
    required String role,
  }) async {
    await _firestore.collection('users').doc(uid).update({'role': role});
  }

  // Create Worker Profile
  Future<void> createWorkerProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    data['createdAt'] = FieldValue.serverTimestamp();
    data['uid'] = uid;

    await _firestore.collection('workers').doc(uid).set(data);
    await updateUserRole(uid: uid, role: 'worker');
  }

  // Create Contractor Profile
  Future<void> createContractorProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    data['createdAt'] = FieldValue.serverTimestamp();
    data['uid'] = uid;

    await _firestore.collection('contractors').doc(uid).set(data);
    await updateUserRole(uid: uid, role: 'contractor');
  }

  // Get User Role
  Future<String?> getUserRole(String uid) async {
    DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return (doc.data() as Map<String, dynamic>)['role'] as String?;
    }
    return null;
  }
}
