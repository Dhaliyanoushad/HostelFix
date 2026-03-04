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
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length:
          4, // 0: Complaints (Existing), 1: Approvals, 2: Contractors, 3: Hostels
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          title: const Text("Admin Panel"),
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
          bottom: const TabBar(
            isScrollable: false,
            labelPadding: EdgeInsets.symmetric(horizontal: 4),
            labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: "Complaints"),
              Tab(text: "Approvals"),
              Tab(text: "Contractors"),
              Tab(text: "Hostels"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ComplaintsView(),
            ContractorApprovalView(),
            ContractorListView(),
            HostelsView(),
          ],
        ),
      ),
    );
  }
}

// 📌 EXISTING COMPLAINTS VIEW (Refactored from previous version)
class ComplaintsView extends StatefulWidget {
  const ComplaintsView({super.key});

  @override
  State<ComplaintsView> createState() => _ComplaintsViewState();
}

class _ComplaintsViewState extends State<ComplaintsView> {
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
    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _getComplaintsStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              if (docs.isEmpty)
                return const Center(child: Text("No complaints found."));

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final isEmergency = data['priority'] == 'high';
                  return _buildComplaintCard(docs[index], isEmergency, context);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: statuses.map((status) {
            final isSelected = selectedStatus == status;
            return Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: ChoiceChip(
                label: Text(status, style: const TextStyle(fontSize: 11)),
                selected: isSelected,
                onSelected: (val) {
                  if (val) setState(() => selectedStatus = status);
                },
                selectedColor: Colors.blueAccent,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _getComplaintsStream() {
    Query query = FirebaseFirestore.instance.collection('complaints');
    if (selectedStatus != 'All')
      query = query.where('status', isEqualTo: selectedStatus);
    return query.snapshots();
  }

  Widget _buildComplaintCard(
    DocumentSnapshot doc,
    bool isEmergency,
    BuildContext context,
  ) {
    final data = doc.data() as Map<String, dynamic>;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isEmergency
            ? const BorderSide(color: Colors.red, width: 1.5)
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Icon(
          isEmergency ? Icons.warning_rounded : Icons.report_problem_outlined,
          color: isEmergency ? Colors.red : Colors.blueAccent,
        ),
        title: Text(
          data['title'] ?? 'No Title',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          "${data['room'] ?? 'N/A'} | ${data['issueDescription'] ?? data['description'] ?? ''}",
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: isEmergency
            ? const Icon(Icons.priority_high, color: Colors.red, size: 18)
            : null,
      ),
    );
  }
}

// 📌 1. CONTRACTOR APPROVAL VIEW
class ContractorApprovalView extends StatelessWidget {
  const ContractorApprovalView({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Contractor')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty)
          return const Center(child: Text("No pending approvals."));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(
                        data['name'] ?? 'N/A',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "${data['specialization'] ?? 'N/A'} | ${data['phone'] ?? 'N/A'}",
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () =>
                              _handleApproval(context, docs[index].id, true),
                          child: const Text(
                            "ACCEPT",
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              _handleApproval(context, docs[index].id, false),
                          child: const Text(
                            "REJECT",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleApproval(BuildContext context, String uid, bool accept) async {
    if (accept) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'status': 'approved',
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Contractor Approved")));
    } else {
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Contractor Rejected & Deleted")),
      );
    }
  }
}

// 📌 2. CONTRACTORS LIST VIEW
class ContractorListView extends StatelessWidget {
  const ContractorListView({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Contractor')
          .where('status', isEqualTo: 'approved')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty)
          return const Center(child: Text("No approved contractors."));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.engineering)),
                title: Text(
                  data['name'] ?? 'N/A',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "${data['specialization'] ?? 'N/A'} | ${data['phone'] ?? 'N/A'}",
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDelete(context, docs[index].id),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, String uid) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text(
          "Are you sure you want to delete this contractor? They will no longer be able to log in.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .delete();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Contractor Deleted")),
              );
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// 📌 3. HOSTELS VIEW
class HostelsView extends StatelessWidget {
  const HostelsView({super.key});

  @override
  Widget build(BuildContext context) {
    // Assuming hostels are fetched from a 'hostels' collection or inferred from users
    // For this app, let's fetch all Warden users to identify hostels and then aggregate students
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final allUsers = snapshot.data!.docs;

        // Identify unique hostels and their wardens safely
        final wardens = allUsers.where((u) {
          final data = u.data() as Map<String, dynamic>?;
          return data != null && data['role'] == 'Warden';
        }).toList();

        final hostels = wardens
            .map((w) {
              final data = w.data() as Map<String, dynamic>?;
              return data?['hostel'] as String?;
            })
            .whereType<String>()
            .toSet()
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: hostels.length,
          itemBuilder: (context, index) {
            final hostelName = hostels[index];
            final wardenDoc = wardens.firstWhere(
              (w) => (w.data() as Map<String, dynamic>)['hostel'] == hostelName,
            );
            final wardenData = wardenDoc.data() as Map<String, dynamic>;
            final studentCount = allUsers.where((u) {
              final data = u.data() as Map<String, dynamic>?;
              return data != null &&
                  data['role'] == 'Student' &&
                  data['hostel'] == hostelName;
            }).length;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hostelName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text("Warden: ${wardenData['name'] ?? 'N/A'}"),
                    Text("Total Students: $studentCount"),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StudentListPage(
                              hostelName: hostelName,
                              wardenName: wardenData['name'] ?? 'N/A',
                            ),
                          ),
                        );
                      },
                      child: const Text("View Students"),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// 📌 4. STUDENTS LIST PER HOSTEL PAGE
class StudentListPage extends StatefulWidget {
  final String hostelName;
  final String wardenName;
  const StudentListPage({
    super.key,
    required this.hostelName,
    required this.wardenName,
  });

  @override
  State<StudentListPage> createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  String search = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.hostelName)),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blueAccent.withOpacity(0.1),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Warden: ${widget.wardenName}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(
                    hintText: "Search student...",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                  onChanged: (v) => setState(() => search = v.toLowerCase()),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'Student')
                  .where('hostel', isEqualTo: widget.hostelName)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final students = snapshot.data!.docs.where((s) {
                  final data = s.data() as Map<String, dynamic>?;
                  if (data == null) return false;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  return name.contains(search);
                }).toList();

                if (students.isEmpty)
                  return const Center(child: Text("No students found."));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final s = students[index].data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          s['name'] ?? 'N/A',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("Room: ${s['room'] ?? 'N/A'}"),
                        trailing: Text(s['phone'] ?? 'N/A'),
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
}
