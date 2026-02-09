import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// SIGN UP
  Future<String?> signUp({
    required String name,
    required String email,
    required String studentId,
    required String hostel,
    required String password,
  }) async {
    try {
      // 1️⃣ Create Firebase Auth user
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2️⃣ Save extra data in Firestore
      await _db.collection('users').doc(studentId).set({
        'uid': cred.user!.uid,
        'name': name,
        'email': email,
        'studentId': studentId,
        'hostel': hostel,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null; // success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Something went wrong';
    }
  }

  /// LOGIN using Student ID
  Future<String?> loginWithStudentId({
    required String studentId,
    required String password,
  }) async {
    try {
      // 1️⃣ Find email from Firestore using studentId
      DocumentSnapshot doc = await _db.collection('users').doc(studentId).get();

      if (!doc.exists) {
        return 'Student ID not found';
      }

      String email = doc['email'];

      // 2️⃣ Login using email + password
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      return null; // success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Login failed';
    }
  }

  /// LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }
}
