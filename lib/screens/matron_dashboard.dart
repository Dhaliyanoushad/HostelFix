import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/user_provider.dart';

class WardenDashboard extends StatefulWidget {
  const WardenDashboard({super.key});

  @override
  State<WardenDashboard> createState() => _WardenDashboardState();
}

class _WardenDashboardState extends State<WardenDashboard> {
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
        title: const Text("Warden Dashboard"),
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

                // Client-side sorting
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
                final otherComplaints = allComplaints
                    .where((doc) => doc['priority'] != 'high')
                    .toList();

                if (allComplaints.isEmpty) {
                  return const Center(
                    child: Text("No complaints match this filter."),
                  );
                }

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
                        (c) => buildWardenCard(c, true, context),
                      ),
                      const Divider(height: 32),
                    ],
                    const Text(
                      "Complaints",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...otherComplaints.map(
                      (c) => buildWardenCard(c, false, context),
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
                  if (val) {
                    setState(() => selectedStatus = status);
                  }
                },
                selectedColor: Colors.pinkAccent,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            );
          }).toList(),
        ),
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

  Widget buildWardenCard(
    DocumentSnapshot doc,
    bool isEmergency,
    BuildContext context,
  ) {
    final data = doc.data() as Map<String, dynamic>;
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
          color: isEmergency
              ? Colors.white.withValues(alpha: 0.9)
              : Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(
              data['title'] ?? 'No Title',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "Room ${data['room'] ?? 'N/A'} | ID: ${data['registerNumber'] ?? 'N/A'} | ${data['status'] ?? 'Pending'}\n${data['issueDescription'] ?? data['description'] ?? ''}",
            ),
            trailing: Wrap(
              spacing: 8,
              children: [
                IconButton(
                  icon: const Icon(Icons.person_add, color: Colors.blue),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  onPressed: () {},
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
