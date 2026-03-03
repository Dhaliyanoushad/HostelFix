import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContractorDashboard extends StatefulWidget {
  const ContractorDashboard({super.key});

  @override
  State<ContractorDashboard> createState() => _ContractorDashboardState();
}

class _ContractorDashboardState extends State<ContractorDashboard> {
  String selectedStatus = 'Assigned'; // Default to Assigned for contractors
  final List<String> statuses = ['Assigned', 'In Progress', 'Completed'];

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
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getComplaintsStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final complaints = snapshot.data!.docs;

                if (complaints.isEmpty) {
                  return const Center(
                    child: Text("No tasks found for this status."),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: complaints.length,
                  itemBuilder: (context, index) {
                    final doc = complaints[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final isEmergency = data['priority'] == 'high';

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
                        title: Text(data['title'] ?? 'Task'),
                        subtitle: Text("Status: ${data['status']}"),
                        trailing: TextButton(
                          onPressed: () {},
                          child: Text(
                            isEmergency ? "ACCEPT NOW" : "View Details",
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: statuses.map((status) {
          final isSelected = selectedStatus == status;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(status),
              selected: isSelected,
              onSelected: (val) {
                if (val) setState(() => selectedStatus = status);
              },
              selectedColor: Colors.orangeAccent,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Stream<QuerySnapshot> _getComplaintsStream() {
    return FirebaseFirestore.instance
        .collection('complaints')
        .where('status', isEqualTo: selectedStatus)
        .snapshots();
  }
}
