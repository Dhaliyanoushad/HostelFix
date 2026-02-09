import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ComplaintService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> submitComplaint({
    required String name,
    required String studentId,
    required String hostelBlock,
    required String room,
    required String category,
    required String priority,
    required String title,
    required String description,
  }) async {
    try {
      final user = _auth.currentUser;

      await _firestore.collection('complaints').add({
        'uid': user!.uid,
        'name': name,
        'studentId': studentId,
        'hostelBlock': hostelBlock,
        'room': room,
        'category': category,
        'priority': priority,
        'title': title,
        'description': description,
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null; // success
    } catch (e) {
      return e.toString();
    }
  }
}
