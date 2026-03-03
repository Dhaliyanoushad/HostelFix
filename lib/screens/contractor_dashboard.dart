import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContractorDashboard extends StatelessWidget {
  const ContractorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text("Contractor Dashboard"),
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
            .where('status', isNotEqualTo: 'Completed')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final complaints = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              final doc = complaints[index];
              final isEmergency = doc['priority'] == 'high';

              return Card(
                color: isEmergency ? Colors.amber.shade50 : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isEmergency
                      ? const BorderSide(color: Colors.orange, width: 1)
                      : BorderSide.none,
                ),
                child: ListTile(
                  leading: Icon(
                    isEmergency ? Icons.flash_on : Icons.build,
                    color: isEmergency ? Colors.orange : Colors.grey,
                  ),
                  title: Text(doc['title']),
                  subtitle: Text("Status: ${doc['status']}"),
                  trailing: TextButton(
                    onPressed: () {},
                    child: Text(isEmergency ? "ACCEPT NOW" : "View Details"),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
