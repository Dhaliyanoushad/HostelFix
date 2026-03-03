import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cupertino_icons/cupertino_icons.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text("Admin Dashboard - HostelFix"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('complaints')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allComplaints = snapshot.data!.docs;
          final emergencyComplaints = allComplaints
              .where((doc) => doc['priority'] == 'high')
              .toList();
          final normalComplaints = allComplaints
              .where((doc) => doc['priority'] != 'high')
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (emergencyComplaints.isNotEmpty) ...[
                const Text(
                  "🚨 EMERGENCY COMPLAINTS",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                ...emergencyComplaints.map(
                  (c) => buildComplaintCard(c, true, context),
                ),
                const SizedBox(height: 24),
              ],
              const Text(
                "Normal Complaints",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...normalComplaints.map(
                (c) => buildComplaintCard(c, false, context),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildComplaintCard(
    DocumentSnapshot doc,
    bool isEmergency,
    BuildContext context,
  ) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: isEmergency
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.15),
                      blurRadius: 15,
                      spreadRadius: 4,
                    ),
                  ],
                )
              : null,
          child: Card(
            elevation: isEmergency ? 0 : 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: isEmergency
                  ? const BorderSide(color: Colors.redAccent, width: 1.5)
                  : BorderSide.none,
            ),
            color: isEmergency ? Colors.white.withOpacity(0.9) : Colors.white,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Icon(
                isEmergency
                    ? Icons.warning_amber_rounded
                    : Icons.report_problem,
                color: isEmergency ? Colors.red : Colors.blueAccent,
                size: 32,
              ),
              title: Text(
                doc['title'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Room: ${doc['room']} | ID: ${doc['studentId']}"),
                  const SizedBox(height: 4),
                  Text(
                    doc['description'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              trailing: ElevatedButton(
                onPressed: () {
                  // Quick Assign Logic Placeholder
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Quick Assigning Contractor..."),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEmergency ? Colors.red : Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Assign"),
              ),
            ),
          ),
        ),
        if (isEmergency)
          Positioned(
            top: 5,
            right: 5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: const Text(
                "URGENT",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
