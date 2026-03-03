import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/user_provider.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String selectedStatus = 'All';
  final List<String> statuses = [
    'All',
    'Pending',
    'Assigned',
    'In Progress',
    'Completed',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Provider.of<UserProvider>(context, listen: false).clearUser();
                Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
              }
            },
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

                // Client-side sorting to avoid composite index requirement
                final allComplaints = snapshot.data!.docs.toList();
                allComplaints.sort((a, b) {
                  final t1 =
                      (a.data() as Map<String, dynamic>)['createdAt']
                          as Timestamp?;
                  final t2 =
                      (b.data() as Map<String, dynamic>)['createdAt']
                          as Timestamp?;
                  if (t1 == null) return 1;
                  if (t2 == null) return -1;
                  return t2.compareTo(t1);
                });

                final emergencyComplaints = allComplaints
                    .where((doc) => doc['priority'] == 'high')
                    .toList();
                final normalComplaints = allComplaints
                    .where((doc) => doc['priority'] != 'high')
                    .toList();

                if (allComplaints.isEmpty) {
                  return const Center(
                    child: Text("No complaints found for this status."),
                  );
                }

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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...normalComplaints.map(
                      (c) => buildComplaintCard(c, false, context),
                    ),
                  ],
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
        children: [
          const Icon(Icons.filter_list, size: 20),
          const SizedBox(width: 10),
          const Text("Status: "),
          const SizedBox(width: 10),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: statuses.map((status) {
                  final isSelected = selectedStatus == status;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(status),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) setState(() => selectedStatus = status);
                      },
                      selectedColor: Colors.blueAccent,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getComplaintsStream() {
    Query query = FirebaseFirestore.instance.collection('complaints');
    if (selectedStatus != 'All') {
      query = query.where('status', isEqualTo: selectedStatus);
    }
    return query.snapshots();
  }

  Widget buildComplaintCard(
    DocumentSnapshot doc,
    bool isEmergency,
    BuildContext context,
  ) {
    // ... (rest of buildComplaintCard logic, keeping but cleaning)
    final data = doc.data() as Map<String, dynamic>;
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
                data['title'] ?? 'No Title',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Room: ${data['room'] ?? 'N/A'} | ID: ${data['registerNumber'] ?? 'N/A'}",
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data['issueDescription'] ?? data['description'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              trailing: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Assigning Contractor...")),
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
