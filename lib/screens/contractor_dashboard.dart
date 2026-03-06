import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/user_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/glass_container.dart';
import '../services/notification_service.dart';
import 'package:intl/intl.dart';

class ContractorDashboard extends StatefulWidget {
  const ContractorDashboard({super.key});

  @override
  State<ContractorDashboard> createState() => _ContractorDashboardState();
}

class _ContractorDashboardState extends State<ContractorDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserProvider>(context).userData;
    final isApproved = userData?['approved'] ?? false;
    final themeProvider = context.watch<ThemeProvider>();

    if (!isApproved) {
      return const PendingApprovalScreen();
    }

    final pages = [
      const ContractorOverview(),
      const ContractorTasksList(),
      const ContractorProfile(),
    ];

    return Scaffold(
      extendBody: true,
      body: pages[_currentIndex],
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: GlassContainer(
          padding: EdgeInsets.zero,
          blur: 20,
          borderRadius: 24,
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: Theme.of(context).primaryColor,
            unselectedItemColor: Colors.grey,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: "Overview"),
              BottomNavigationBarItem(icon: Icon(Icons.assignment_rounded), label: "Tasks"),
              BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Profile"),
            ],
          ),
        ),
      ),
    );
  }
}

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserProvider>(context).userData;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Verification Status"),
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
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            GlassContainer(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    backgroundImage: (userData?['profilePhoto'] != null && userData!['profilePhoto'].toString().isNotEmpty) 
                        ? NetworkImage(userData['profilePhoto']) 
                        : null,
                    child: (userData?['profilePhoto'] == null || userData!['profilePhoto'].toString().isEmpty) 
                        ? Icon(Icons.engineering_rounded, size: 60, color: Theme.of(context).primaryColor) 
                        : null,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    userData?['name'] ?? 'Contractor',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      userData?['specialization'] ?? 'Specialist',
                      style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            GlassContainer(
              padding: const EdgeInsets.all(24),
              color: Colors.orange.shade50,
              borderColor: Colors.orange.withOpacity(0.2),
              child: const Column(
                children: [
                  Icon(Icons.hourglass_empty_rounded, size: 48, color: Colors.orange),
                  const SizedBox(height: 16),
                  Text(
                    "Review in Progress",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Your profile is currently under admin review. You will gain access to your dashboard once your account is approved.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.orange, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).primaryColor),
                ),
                const SizedBox(width: 12),
                const Text("Waiting for admin approval...", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ContractorOverview extends StatelessWidget {
  const ContractorOverview({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = Provider.of<UserProvider>(context).uid;
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Overview"),
        actions: [
          IconButton(
            icon: Icon(themeProvider.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            onPressed: () => themeProvider.toggleTheme(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('complaints')
            .where('assignedTo', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final docs = snapshot.data?.docs ?? [];
          final stats = {
            'Total': docs.length,
            'Pending': docs.where((d) => d['status'] == 'Pending' || d['status'] == 'Assigned').length,
            'Accepted': docs.where((d) => d['status'] == 'Accepted').length,
            'In Progress': docs.where((d) => d['status'] == 'In Progress').length,
            'Completed': docs.where((d) => d['status'] == 'Completed').length,
          };

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              GlassContainer(
                gradient: LinearGradient(
                  colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Total Tasks Assigned", style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Text("${stats['Total']}", style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                   _buildStatCard(context, "Pending", stats['Pending']!, const Color(0xFF64748B)),
                   _buildStatCard(context, "Accepted", stats['Accepted']!, const Color(0xFF0EA5E9)),
                   _buildStatCard(context, "In Progress", stats['In Progress']!, const Color(0xFF8B5CF6)),
                   _buildStatCard(context, "Completed", stats['Completed']!, const Color(0xFF10B981)),
                ],
              ),
              const SizedBox(height: 32),
              const Text("Performance Metrics", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildProgressList(context, stats),
              const SizedBox(height: 100), // Space for bottom nav
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, int count, Color color) {
    return GlassContainer(
      padding: EdgeInsets.zero,
      borderColor: color.withOpacity(0.2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(_getIconForStatus(label), size: 18, color: color),
          ),
          const SizedBox(height: 12),
          Text("$count", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildProgressList(BuildContext context, Map<String, int> stats) {
    final total = stats['Total'] == 0 ? 1 : stats['Total']!;
    return GlassContainer(
      child: Column(
        children: stats.entries.where((e) => e.key != 'Total').map((e) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    Text("${((e.value / total) * 100).toInt()}%", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: e.value / total,
                    backgroundColor: Colors.grey.withOpacity(0.1),
                    color: _getColorForStatus(e.key),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _getIconForStatus(String status) {
    switch (status) {
      case 'Pending': return Icons.history_rounded;
      case 'Accepted': return Icons.check_circle_outline_rounded;
      case 'In Progress': return Icons.build_rounded;
      case 'Completed': return Icons.verified_rounded;
      default: return Icons.help_outline_rounded;
    }
  }

  Color _getColorForStatus(String status) {
    switch (status) {
      case 'Pending': return const Color(0xFF64748B);
      case 'Accepted': return const Color(0xFF0EA5E9);
      case 'In Progress': return const Color(0xFF8B5CF6);
      case 'Completed': return const Color(0xFF10B981);
      default: return Colors.grey;
    }
  }
}

class ContractorTasksList extends StatefulWidget {
  const ContractorTasksList({super.key});

  @override
  State<ContractorTasksList> createState() => _ContractorTasksListState();
}

class _ContractorTasksListState extends State<ContractorTasksList> {
  String selectedStatus = 'All';
  String selectedHostel = 'All';

  @override
  Widget build(BuildContext context) {
    final uid = Provider.of<UserProvider>(context).uid;

    return Scaffold(
      appBar: AppBar(title: const Text("My Tasks")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              borderRadius: 16,
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedStatus,
                        isExpanded: true,
                        items: ['All', 'Assigned', 'Accepted', 'In Progress', 'Completed']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13))))
                            .toList(),
                        onChanged: (v) => setState(() => selectedStatus = v!),
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 20),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedHostel,
                        isExpanded: true,
                        items: ['All', 'Sahara', 'Siberia', 'Swaraj', 'Sagar', 'Sarovar', 'Alakananda', 'Aiswarya', 'Anagha', 'Ananya', 'Anaswara']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13))))
                            .toList(),
                        onChanged: (v) => setState(() => selectedHostel = v!),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: uid == null 
              ? const Center(child: CircularProgressIndicator())
              : StreamBuilder<QuerySnapshot>(
                  stream: _getFilteredStream(uid),
                  builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final tasks = snapshot.data?.docs ?? [];

                if (tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_late_rounded, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text("No tasks found", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final data = task.data() as Map<String, dynamic>;

                    return _buildTaskCard(context, task, data);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, DocumentSnapshot doc, Map<String, dynamic> data) {
    Color statusColor = _getStatusColor(data['status']);
    
    return GlassContainer(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _viewDetails(context, doc),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      data['status']?.toUpperCase() ?? 'PENDING',
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                  ),
                  Text(_formatDate(data['createdAt']), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 12),
              Text(data['title'] ?? 'Complaint', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on_rounded, size: 14, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 4),
                  Text("${data['hostel']} • Room ${data['room']}", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
              const Divider(height: 32, thickness: 0.5),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.category_rounded, size: 14, color: Theme.of(context).primaryColor),
                  ),
                  const SizedBox(width: 8),
                  Text(data['category'] ?? 'General', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const Spacer(),
                  const Text("View Details", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                  const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.blueAccent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "N/A";
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return "${date.day}/${date.month}/${date.year}";
    }
    return timestamp.toString();
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Assigned': return const Color(0xFF2563EB);
      case 'Accepted': return const Color(0xFF0EA5E9);
      case 'In Progress': return const Color(0xFF8B5CF6);
      case 'Completed': return const Color(0xFF10B981);
      default: return const Color(0xFF64748B);
    }
  }

  Stream<QuerySnapshot> _getFilteredStream(String uid) {
    Query query = FirebaseFirestore.instance.collection('complaints').where('assignedTo', isEqualTo: uid);
    if (selectedStatus != 'All') query = query.where('status', isEqualTo: selectedStatus);
    if (selectedHostel != 'All') query = query.where('hostel', isEqualTo: selectedHostel);
    return query.snapshots();
  }

  void _viewDetails(BuildContext context, DocumentSnapshot doc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskDetailsSheet(doc: doc),
    );
  }
}

class TaskDetailsSheet extends StatelessWidget {
  final DocumentSnapshot doc;
  const TaskDetailsSheet({super.key, required this.doc});

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final status = data['status'];

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withOpacity(0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(data['title'] ?? 'Complaint', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900))),
                  _buildStatusIndicator(status),
                ],
              ),
              const SizedBox(height: 16),
              Text(data['description'] ?? 'No description provided.', style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), height: 1.5)),
              if (data['imageUrl'] != null) ...[
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    data['imageUrl'],
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                  ),
                ),
              ],
              const Divider(height: 40, thickness: 0.5),
              const Text("TASK DETAILS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
              const SizedBox(height: 16),
              _detailRow(context, Icons.apartment_rounded, "Hostel", data['hostel']),
              _detailRow(context, Icons.door_sliding_rounded, "Room", data['room']),
              _detailRow(context, Icons.person_rounded, "Student", data['name'] ?? data['studentName']),
              _detailRow(context, Icons.phone_iphone_rounded, "Phone", data['studentPhone'] ?? 'N/A'),
              _detailRow(context, Icons.category_rounded, "Category", data['category']),
              const SizedBox(height: 32),
              _buildActionButtons(context, status),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String status) {
     Color color = const Color(0xFF64748B);
    if (status == 'Assigned') color = const Color(0xFF2563EB);
    if (status == 'Accepted') color = const Color(0xFF0EA5E9);
    if (status == 'In Progress') color = const Color(0xFF8B5CF6);
    if (status == 'Completed') color = const Color(0xFF10B981);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(status.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }

  Widget _buildActionButtons(BuildContext context, String status) {
    if (status == 'Completed') return const SizedBox.shrink();

    String btnText = "Accept Complaint";
    Color btnColor = const Color(0xFF0EA5E9);
    String nextStatus = "Accepted";

    if (status == 'Accepted') {
      btnText = "Start Work";
      btnColor = const Color(0xFF8B5CF6);
      nextStatus = "In Progress";
    } else if (status == 'In Progress') {
      btnText = "Mark Completed";
      btnColor = const Color(0xFF10B981);
      nextStatus = "Completed";
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _updateStatus(context, nextStatus),
        style: ElevatedButton.styleFrom(
          backgroundColor: btnColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(btnText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    Map<String, dynamic> updateData = {'status': newStatus};

    if (newStatus == 'Accepted') {
      final DateTime? date = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 30)),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: Theme.of(context).primaryColor,
              ),
            ),
            child: child!,
          );
        },
      );

      if (date == null) return;

      if (!context.mounted) return;
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time == null) return;

      final scheduledTimestamp = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );

      updateData['scheduledVisit'] = Timestamp.fromDate(scheduledTimestamp);
    }

    await doc.reference.update(updateData);

    if (newStatus == 'Accepted') {
      final String visitTime = DateFormat('MMM dd, hh:mm a').format((updateData['scheduledVisit'] as Timestamp).toDate());
      final data = doc.data() as Map<String, dynamic>;
      await NotificationService.showNotification(
        title: "Complaint Accepted!",
        body: "Your '${data['title']}' is scheduled for $visitTime",
        color: Colors.green,
      );
    }

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus == 'Accepted' ? "Task Accepted & Scheduled" : "Task marked as $newStatus"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        )
      );
    }
  }

  Widget _detailRow(BuildContext context, IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              Text(value ?? 'N/A', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class ContractorProfile extends StatelessWidget {
  const ContractorProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserProvider>(context).userData;

    return Scaffold(
      appBar: AppBar(title: const Text("My Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
             GlassContainer(
               padding: const EdgeInsets.all(32),
               child: Column(
                 children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      backgroundImage: (userData?['profilePhoto'] != null && userData!['profilePhoto'].toString().isNotEmpty)
                          ? NetworkImage(userData['profilePhoto']) 
                          : null,
                      child: (userData?['profilePhoto'] == null || userData!['profilePhoto'].toString().isEmpty)
                          ? Icon(Icons.person_rounded, size: 60, color: Theme.of(context).primaryColor) 
                          : null,
                    ),
                    const SizedBox(height: 24),
                    Text(userData?['name'] ?? 'N/A', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                    Text(userData?['phone'] ?? 'N/A', style: const TextStyle(color: Colors.grey, fontSize: 16)),
                    const SizedBox(height: 32),
                    const Divider(thickness: 0.5),
                    _profileItem(context, Icons.engineering_rounded, "Role", userData?['specialization']),
                    _profileItem(context, Icons.history_rounded, "Experience", "${userData?['experience'] ?? '0'} Years"),
                    _profileItem(context, Icons.verified_rounded, "Status", (userData?['approved'] ?? false) ? "Approved" : "Pending"),
                 ],
               ),
             ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _confirmLogout(context),
                icon: const Icon(Icons.logout_rounded),
                label: const Text("Sign Out", style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.redAccent,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _profileItem(BuildContext context, IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                Text(value ?? 'N/A', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Provider.of<UserProvider>(context, listen: false).clearUser();
                Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
              }
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
