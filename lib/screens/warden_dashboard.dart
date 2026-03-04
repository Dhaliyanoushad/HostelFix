import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hostel_fix/services/notification_service.dart';
import '../providers/user_provider.dart';
import '../widgets/custom_widgets.dart';
import '../theme/app_theme.dart';

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
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(_getTitle()),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
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
      body: FuturisticBackground(
        child: SafeArea(
          bottom: false,
          child: IndexedStack(index: _currentIndex, children: _views),
        ),
      ),
      bottomNavigationBar: _buildFloatingNavBar(),
    );
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return "Warden Hub";
      case 1:
        return "Identity Verification";
      case 2:
        return "Inmate Directory";
      case 3:
        return "Service Requests";
      default:
        return "Dashboard";
    }
  }

  Widget _buildFloatingNavBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.cardBg.withOpacity(0.95),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(0, Icons.grid_view_rounded),
          _navItem(1, Icons.how_to_reg_rounded),
          _navItem(2, Icons.people_alt_rounded),
          _navItem(3, Icons.handyman_rounded),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: isSelected
            ? BoxDecoration(
                color: AppColors.secondaryAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              )
            : null,
        child: Icon(
          icon,
          color: isSelected
              ? AppColors.secondaryAccent
              : AppColors.textSecondary,
          size: 26,
        ),
      ),
    );
  }
}

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
          padding: const EdgeInsets.all(24),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildStatCard(
              "OPEN",
              pending,
              Colors.orangeAccent,
              Icons.new_releases_rounded,
            ),
            _buildStatCard(
              "ALLOCATED",
              assigned,
              AppColors.primaryAccent,
              Icons.person_add_rounded,
            ),
            _buildStatCard(
              "PROCESSING",
              inProgress,
              Colors.purpleAccent,
              Icons.memory_rounded,
            ),
            _buildStatCard(
              "ARCHIVED",
              completed,
              Colors.greenAccent,
              Icons.verified_rounded,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, int count, Color color, IconData icon) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

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
          return const Center(
            child: Text(
              "All Scanned Data Verified",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GlassCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    data['name'] ?? 'N/A',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    "Unit: ${data['room']} • ${data['phone']}",
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.cancel_rounded,
                          color: Colors.redAccent,
                        ),
                        onPressed: () =>
                            _updateStatus(context, docs[index].id, false),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.greenAccent,
                        ),
                        onPressed: () =>
                            _updateStatus(context, docs[index].id, true),
                      ),
                    ],
                  ),
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
      ).showSnackBar(const SnackBar(content: Text("Access Authorized ✅")));
    } else {
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Access Denied ❌")));
    }
  }
}

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
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.textFieldBg,
                    child: Icon(Icons.person, color: Colors.white, size: 20),
                  ),
                  title: Text(
                    data['name'] ?? 'N/A',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    "Unit ${data['room']}",
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  trailing: Icon(
                    Icons.contact_phone_rounded,
                    color: AppColors.primaryAccent.withOpacity(0.5),
                    size: 18,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

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
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final status = data['status'] ?? 'Pending';
            final isHigh = data['priority'] == 'high';

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GlassCard(
                showGlow: isHigh,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            data['title'] ?? 'Title',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        _buildStatusTag(status),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      data['issueDescription'] ?? data['description'] ?? '',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const Divider(color: Colors.white10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Unit: ${data['room']}",
                          style: const TextStyle(
                            color: AppColors.primaryAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            if (status == 'Pending')
                              IconButton(
                                icon: const Icon(
                                  Icons.person_add_alt_1_rounded,
                                  color: AppColors.secondaryAccent,
                                ),
                                onPressed: () =>
                                    _showAssignDialog(context, docs[index].id),
                              ),
                            if (status != 'Closed' && status != 'Completed')
                              IconButton(
                                icon: const Icon(
                                  Icons.verified_user_rounded,
                                  color: Colors.greenAccent,
                                ),
                                onPressed: () =>
                                    _closeComplaint(context, docs[index].id),
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

  Widget _buildStatusTag(String status) {
    Color color = Colors.orangeAccent;
    if (status == 'Assigned') color = AppColors.primaryAccent;
    if (status == 'In Progress') color = Colors.purpleAccent;
    if (status == 'Completed') color = Colors.greenAccent;
    if (status == 'Closed') color = Colors.blueGrey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  void _showAssignDialog(BuildContext context, String complaintId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text(
          "Assign Operative",
          style: TextStyle(color: Colors.white),
        ),
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
                    title: Text(
                      c['name'] ?? 'N/A',
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      c['specialization'] ?? 'N/A',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    trailing: const Icon(
                      Icons.bolt_rounded,
                      color: AppColors.primaryAccent,
                    ),
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
      title: "Task Resolved",
      body: "Resolution update for ticket #$id has been finalized.",
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Archive Finalized ✅")));
  }
}
