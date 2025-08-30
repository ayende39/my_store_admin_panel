import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<User?> signInAsAdmin(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final userDoc = await _db.collection('users').doc(cred.user!.uid).get();
    if (userDoc.exists && userDoc.data()?['role'] == 'admin') {
      return cred.user;
    } else {
      await _auth.signOut();
      throw Exception('Not authorized as admin.');
    }
  }

  Future<void> signOut() async => await _auth.signOut();
}
