import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hostel_fix/services/notification_service.dart';
import '../providers/user_provider.dart';

class WardenDashboard extends StatefulWidget {
  const WardenDashboard({super.key});

  @override
  State<WardenDashboard> createState() => _WardenDashboardState();
}

class _WardenDashboardState extends State<WardenDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final String wardenHostel = userProvider.hostel ?? '';

    final List<Widget> _views = [
      WardenHomeView(hostelName: wardenHostel),
      StudentApprovalView(hostelName: wardenHostel),
      WardenStudentListView(hostelName: wardenHostel),
      WardenComplaintsView(hostelName: wardenHostel),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(_getTitle()),
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
      body: _views[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.pinkAccent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.how_to_reg),
            label: "Approvals",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Students"),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_problem),
            label: "Work",
          ),
        ],
      ),
    );
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return "Warden Overview";
      case 1:
        return "Pending Students";
      case 2:
        return "Hostel Students";
      case 3:
        return "Complaint Management";
      default:
        return "Dashboard";
    }
  }
}

// 📌 1. HOME VIEW WITH STATUS CARDS
class WardenHomeView extends StatelessWidget {
  final String hostelName;
  const WardenHomeView({super.key, required this.hostelName});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('complaints')
          .where('hostel', isEqualTo: hostelName)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        int pending = docs.where((doc) => doc['status'] == 'Pending').length;
        int assigned = docs.where((doc) => doc['status'] == 'Assigned').length;
        int inProgress = docs
            .where((doc) => doc['status'] == 'In Progress')
            .length;
        int completed = docs
            .where((doc) => doc['status'] == 'Completed')
            .length;

        return GridView.count(
          padding: const EdgeInsets.all(16),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildStatCard(
              "Pending",
              pending,
              Colors.orange,
              Icons.new_releases,
            ),
            _buildStatCard("Assigned", assigned, Colors.blue, Icons.person_add),
            _buildStatCard(
              "In Progress",
              inProgress,
              Colors.purple,
              Icons.engineering,
            ),
            _buildStatCard(
              "Completed",
              completed,
              Colors.green,
              Icons.check_circle,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, int count, Color color, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 📌 2. STUDENT APPROVAL VIEW
class StudentApprovalView extends StatelessWidget {
  final String hostelName;
  const StudentApprovalView({super.key, required this.hostelName});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Student')
          .where('hostel', isEqualTo: hostelName)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty)
          return const Center(child: Text("No students waiting for approval."));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(
                  data['name'] ?? 'N/A',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "Room: ${data['room'] ?? 'N/A'} | ${data['phone'] ?? 'N/A'}",
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () =>
                          _updateStatus(context, docs[index].id, true),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () =>
                          _updateStatus(context, docs[index].id, false),
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

  void _updateStatus(BuildContext context, String uid, bool approve) async {
    if (approve) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'status': 'approved',
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Student Approved")));
    } else {
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Student Rejected")));
    }
  }
}

// 📌 3. STUDENT LIST VIEW
class WardenStudentListView extends StatelessWidget {
  final String hostelName;
  const WardenStudentListView({super.key, required this.hostelName});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Student')
          .where('hostel', isEqualTo: hostelName)
          .where('status', isEqualTo: 'approved')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty)
          return const Center(child: Text("No approved students."));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(
                  data['name'] ?? 'N/A',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("Room: ${data['room'] ?? 'N/A'}"),
                trailing: Text(data['phone'] ?? 'N/A'),
              ),
            );
          },
        );
      },
    );
  }
}

// 📌 4. COMPLAINT MANAGEMENT VIEW
class WardenComplaintsView extends StatelessWidget {
  final String hostelName;
  const WardenComplaintsView({super.key, required this.hostelName});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('complaints')
          .where('hostel', isEqualTo: hostelName)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty)
          return const Center(child: Text("No complaints for this hostel."));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final status = data['status'] ?? 'Pending';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          data['title'] ?? 'Title',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        _buildStatusBadge(status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(data['issueDescription'] ?? data['description'] ?? ''),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Room: ${data['room'] ?? 'N/A'}",
                          style: const TextStyle(color: Colors.grey),
                        ),
                        Row(
                          children: [
                            if (status == 'Pending')
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () =>
                                    _showAssignDialog(context, docs[index].id),
                                child: const Text("ASSIGN"),
                              ),
                            const SizedBox(width: 8),
                            if (status != 'Closed' && status != 'Completed')
                              OutlinedButton(
                                onPressed: () =>
                                    _closeComplaint(context, docs[index].id),
                                child: const Text(
                                  "CLOSE",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                          ],
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

  Widget _buildStatusBadge(String status) {
    Color color = Colors.orange;
    if (status == 'Assigned') color = Colors.blue;
    if (status == 'In Progress') color = Colors.purple;
    if (status == 'Completed') color = Colors.green;
    if (status == 'Closed') color = Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showAssignDialog(BuildContext context, String complaintId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Assign Contractor"),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'Contractor')
                .where('status', isEqualTo: 'approved')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final c = docs[index].data() as Map<String, dynamic>;
                  return ListTile(
                    title: Text(c['name'] ?? 'N/A'),
                    subtitle: Text(c['specialization'] ?? 'N/A'),
                    onTap: () async {
                      await FirebaseFirestore.instance
                          .collection('complaints')
                          .doc(complaintId)
                          .update({
                            'status': 'Assigned',
                            'assignedContractorId': docs[index].id,
                          });
                      Navigator.pop(ctx);
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _closeComplaint(BuildContext context, String id) async {
    await FirebaseFirestore.instance.collection('complaints').doc(id).update({
      'status': 'Closed',
    });
    await NotificationService.showNotification(
      title: "Complaint Closed",
      body: "Your complaint has been resolved/closed by the warden.",
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Complaint Closed")));
  }
}
