import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// SIGN UP
  Future<Map<String, dynamic>?> signUp({
    required String name,
    required String email,
    String? studentId,
    String? hostel,
    required String password,
    required String role,
    String? gender,
    String? phone,
    String? specialization,
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
        'phone': phone,
        'specialization': specialization,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // 2️⃣ Save extra data in Firestore
      // Use studentId as doc ID if available (for backward compatibility), otherwise use UID
      String docId = (studentId != null && studentId.isNotEmpty)
          ? studentId
          : cred.user!.uid;

      await _db.collection('users').doc(docId).set(userData);

      // 3️⃣ Create public lookup entry for Students (to allow login by ID without public user-profile reads)
      if (role == 'Student' && studentId != null && studentId.isNotEmpty) {
        await _db.collection('public_lookups').doc(studentId).set({
          'email': email,
          'uid': cred.user!.uid,
        });
      }

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
      // 1️⃣ Find email from public_lookups using studentId
      DocumentSnapshot lookupDoc = await _db
          .collection('public_lookups')
          .doc(studentId)
          .get();

      if (!lookupDoc.exists) {
        throw 'Student ID not found. Ensure you have registered.';
      }

      String email = lookupDoc['email'];
      String uid = lookupDoc['uid'];

      // 2️⃣ Login using email + password (directly)
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // 3️⃣ Fetch full user data after successful auth
      return await fetchUserData(uid);
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

  /// LOGIN using Phone
  Future<Map<String, dynamic>?> loginWithPhone({
    required String phone,
    required String password,
  }) async {
    try {
      // 1️⃣ Find email from Firestore using phone
      QuerySnapshot snap = await _db
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        throw 'Phone number not found';
      }

      String email = snap.docs.first['email'];

      // 2️⃣ Login using email + password
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      return snap.docs.first.data() as Map<String, dynamic>?;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Login failed';
    } catch (e) {
      throw e.toString();
    }
  }

  /// LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }
}
