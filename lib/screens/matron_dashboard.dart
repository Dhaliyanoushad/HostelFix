import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MatronDashboard extends StatelessWidget {
  const MatronDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text("Matron Dashboard"),
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
          final otherComplaints = allComplaints
              .where((doc) => doc['priority'] != 'high')
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (emergencyComplaints.isNotEmpty) ...[
                const Text(
                  "🚨 Pinned Emergency",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                ...emergencyComplaints.map(
                  (c) => buildMatronCard(c, true, context),
                ),
                const Divider(height: 32),
              ],
              const Text(
                "Recent Complaints",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...otherComplaints.map((c) => buildMatronCard(c, false, context)),
            ],
          );
        },
      ),
    );
  }

  Widget buildMatronCard(
    DocumentSnapshot doc,
    bool isEmergency,
    BuildContext context,
  ) {
    return Stack(
      children: [
        Card(
          elevation: isEmergency ? 8 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isEmergency
                ? const BorderSide(color: Colors.redAccent, width: 2)
                : BorderSide.none,
          ),
          color: isEmergency ? Colors.white.withOpacity(0.9) : Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(
              doc['title'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("Room ${doc['room']} | ${doc['status']}"),
            trailing: Wrap(
              spacing: 8,
              children: [
                IconButton(
                  icon: const Icon(Icons.person_add, color: Colors.blue),
                  onPressed: () {}, // Assign Contractor dummy
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  onPressed: () {}, // Change status dummy
                ),
              ],
            ),
          ),
        ),
        if (isEmergency)
          Positioned(
            top: 0,
            right: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: const Text(
                "EMERGENCY",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
