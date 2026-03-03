import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// SIGN UP
  Future<Map<String, dynamic>?> signUp({
    required String name,
    required String email,
    required String studentId,
    required String hostel,
    required String password,
    required String role,
    required String gender,
  }) async {
    try {
      // 1️⃣ Create Firebase Auth user
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userData = {
        'uid': cred.user!.uid,
        'name': name,
        'email': email,
        'studentId': studentId,
        'hostel': hostel,
        'role': role,
        'gender': gender,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // 2️⃣ Save extra data in Firestore
      await _db.collection('users').doc(studentId).set(userData);

      return userData; // success
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Signup failed';
    } catch (e) {
      throw e.toString();
    }
  }

  /// LOGIN using Email
  Future<Map<String, dynamic>?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // 1️⃣ Login using email + password (directly)
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2️⃣ Fetch user data by UID after login is successful
      return await fetchUserData(cred.user!.uid);
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Login failed';
    } catch (e) {
      throw e.toString();
    }
  }

  /// LOGIN using Student ID (Note: This fails if Firestore rules are private)
  Future<Map<String, dynamic>?> loginWithStudentId({
    required String studentId,
    required String password,
  }) async {
    try {
      // 1️⃣ Find email from Firestore using studentId (This line fails with permission-denied if unauth)
      DocumentSnapshot doc = await _db.collection('users').doc(studentId).get();

      if (!doc.exists) {
        throw 'Student ID not found';
      }

      String email = doc['email'];

      // 2️⃣ Login using email + password
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      return doc.data() as Map<String, dynamic>?;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Login failed';
    } catch (e) {
      throw e.toString();
    }
  }

  /// FETCH USER DATA by UID
  Future<Map<String, dynamic>?> fetchUserData(String uid) async {
    try {
      QuerySnapshot snap = await _db
          .collection('users')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        return snap.docs.first.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// GET ROLE
  Future<String?> getRole(String studentId) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(studentId).get();
      if (doc.exists) {
        return doc['role'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }
}
