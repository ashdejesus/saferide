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
    String password, {
    String? name,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    if (name != null && name.trim().isNotEmpty) {
      await cred.user?.updateDisplayName(name.trim());
    }
    
    await _createOrUpdateUserDoc(cred.user, name: name);
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


  Future<void> _createOrUpdateUserDoc(User? user, {String? name}) async {
    if (user == null) return;
    final users = FirebaseFirestore.instance.collection('users');
    final doc = users.doc(user.uid);
    final snapshot = await doc.get();

    final displayName = name?.trim() ?? user.displayName ?? '';

    final data = {
      'uid': user.uid,
      'email': user.email,
      'updatedAt': FieldValue.serverTimestamp(),
      if (!snapshot.exists) 'createdAt': FieldValue.serverTimestamp(),
      'role': 'user',
      'profile': displayName.isNotEmpty ? {'name': displayName} : {},
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
