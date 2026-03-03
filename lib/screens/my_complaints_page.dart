import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MyComplaintsPage extends StatelessWidget {
  const MyComplaintsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userData = userProvider.userData;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(title: const Text("My Complaints"), centerTitle: true),
      body: userData == null
          ? const Center(child: Text("User not logged in"))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('complaints')
                  .where(
                    Filter.or(
                      Filter('studentId', isEqualTo: userData['uid']),
                      Filter('uid', isEqualTo: userData['uid']),
                    ),
                  )
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        "Error: ${snapshot.error}",
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No complaints submitted yet",
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                // Client-side sorting to avoid composite index requirement
                final complaints = snapshot.data!.docs.toList();
                complaints.sort((a, b) {
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

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: complaints.length,
                  itemBuilder: (context, index) {
                    final data =
                        complaints[index].data() as Map<String, dynamic>;
                    return ComplaintCard(data: data);
                  },
                );
              },
            ),
    );
  }
}

/* ===================== COMPLAINT CARD ===================== */

class ComplaintCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const ComplaintCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final String status = data['status'] ?? 'Pending';

    final String date = data['createdAt'] != null
        ? DateFormat('dd MMM yyyy').format(data['createdAt'].toDate())
        : '—';

    // Handle both old and new field names for description
    final String desc = data['issueDescription'] ?? data['description'] ?? '';

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    data['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                StatusChip(status: status),
              ],
            ),
            const SizedBox(height: 8),
            Text("Category : ${data['category']}"),
            Text("Priority : ${data['priority']}"),
            if (desc.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                desc,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              "Submitted on $date",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

/* ===================== STATUS CHIP ===================== */

class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;

    switch (status) {
      case 'Resolved':
        color = Colors.green;
        break;
      case 'In Progress':
        color = Colors.orange;
        break;
      default:
        color = Colors.red;
    }

    return Chip(
      label: Text(status, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
    );
  }
}
