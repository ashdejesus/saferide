import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthService();

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserCredential> registerWithEmail(
    String email,
    String password,
  ) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _createOrUpdateUserDoc(cred.user);
    return cred;
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _createOrUpdateUserDoc(cred.user);
    return cred;
  }

  Future<UserCredential> signInAnonymously() async {
    final cred = await _auth.signInAnonymously();
    await _createOrUpdateUserDoc(cred.user);
    return cred;
  }

  Future<void> _createOrUpdateUserDoc(User? user) async {
    if (user == null) return;
    final users = FirebaseFirestore.instance.collection('users');
    final doc = users.doc(user.uid);

    final data = {
      'uid': user.uid,
      'email': user.email,
      'isAnonymous': user.isAnonymous,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      // placeholder for future inputs
      'profile': {},
    };

    await doc.set(data, SetOptions(merge: true));
  }

  Future<UserProfile> getUserProfile(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    return UserProfile.fromMap(doc.data()?['profile'] as Map<String, dynamic>?);
  }

  Future<void> updateUserProfile(String uid, UserProfile profile) async {
    final doc = FirebaseFirestore.instance.collection('users').doc(uid);
    await doc.set({
      'profile': profile.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
