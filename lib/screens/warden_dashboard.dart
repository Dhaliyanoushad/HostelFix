import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/user_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/glass_container.dart';
import '../services/notification_service.dart';

class WardenDashboard extends StatefulWidget {
  const WardenDashboard({super.key});

  @override
  State<WardenDashboard> createState() => _WardenDashboardState();
}

class _WardenDashboardState extends State<WardenDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserProvider>(context).userData;
    final hostelName = userData?['hostel'] ?? '';

    final pages = [
      WardenOverview(hostelName: hostelName),
      StudentVerificationView(hostelName: hostelName),
      WardenComplaintsList(hostelName: hostelName),
      const WardenProfile(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: "Overview"),
          BottomNavigationBarItem(icon: Icon(Icons.group_add_rounded), label: "Students"),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_rounded), label: "Complaints"),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Profile"),
        ],
      ),
    );
  }
}

// --- 1. OVERVIEW ---
class WardenOverview extends StatelessWidget {
  final String hostelName;
  const WardenOverview({super.key, required this.hostelName});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text("$hostelName Overview"),
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
            .where('hostel', isEqualTo: hostelName)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final docs = snapshot.data!.docs;
          final stats = {
            'Total': docs.length,
            'Pending': docs.where((d) => d['status'] == 'Pending').length,
            'Assigned': docs.where((d) => d['status'] == 'Assigned').length,
            'In Progress': docs.where((d) => d['status'] == 'In Progress').length,
            'Completed': docs.where((d) => d['status'] == 'Completed').length,
          };

          // Analysis Calculations
          Map<String, int> categoryCounts = {};
          Map<String, int> roomCounts = {};
          for (var doc in docs) {
            String cat = doc['category'] ?? 'Other';
            categoryCounts[cat] = (categoryCounts[cat] ?? 0) + 1;
            
            String room = doc['room'] ?? 'Unknown';
            roomCounts[room] = (roomCounts[room] ?? 0) + 1;
          }

          var sortedCategories = categoryCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          var sortedRooms = roomCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                "Welcome to $hostelName Dashboard",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                "Keep track of all maintenance activity in your hostel.",
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              ),
              const SizedBox(height: 24),
              // --- STAT CARDS ---
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildStatCard(context, "Pending", stats['Pending']!, Colors.orange),
                  _buildStatCard(context, "Completed", stats['Completed']!, Colors.green),
                ],
              ),
              const SizedBox(height: 32),

              // --- ANALYSIS SECTION ---
              Text("Maintenance Analysis", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: GlassContainer(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Top Categories", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                          const SizedBox(height: 12),
                          ...sortedCategories.take(3).map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(e.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                Text("${e.value}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GlassContainer(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Critical Rooms", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                          const SizedBox(height: 12),
                          ...sortedRooms.take(3).map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Room ${e.key}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                Text("${e.value}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Resolution Rate
              GlassContainer(
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.analytics_rounded, color: Colors.white)),
                  title: const Text("Resolution Efficiency", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Overall hostel health score"),
                  trailing: Text(
                    "${stats['Total'] == 0 ? 0 : ((stats['Completed']! / stats['Total']!) * 100).toStringAsFixed(1)}%",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Theme.of(context).primaryColor),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, int count, Color color) {
    return GlassContainer(
      padding: EdgeInsets.zero,
      gradient: LinearGradient(
        colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderColor: color.withOpacity(0.2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text("$count", style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

// --- 2. STUDENT VERIFICATION ---
class StudentVerificationView extends StatelessWidget {
  final String hostelName;
  const StudentVerificationView({super.key, required this.hostelName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student Verification")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'Student')
            .where('hostel', isEqualTo: hostelName)
            .where('approved', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final students = snapshot.data!.docs;

          if (students.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_user_rounded, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text("No pending students", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              final data = student.data() as Map<String, dynamic>;

              return GlassContainer(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          backgroundImage: (data['profilePhoto'] != null && data['profilePhoto'].toString().isNotEmpty) ? NetworkImage(data['profilePhoto']) : null,
                          child: (data['profilePhoto'] == null || data['profilePhoto'].toString().isEmpty) ? Icon(Icons.person_rounded, color: Theme.of(context).primaryColor) : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              Text("ID: ${data['studentId'] ?? 'N/A'}", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32, thickness: 0.5),
                    Text("Room: ${data['room'] ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text("Phone: ${data['phone'] ?? 'N/A'}", style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _verifyStudent(student.id, data['name'] ?? 'Student', true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("Approve"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _verifyStudent(student.id, data['name'] ?? 'Student', false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("Reject"),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _verifyStudent(String id, String name, bool approve) async {
    if (approve) {
      await FirebaseFirestore.instance.collection('users').doc(id).update({'approved': true});
      await NotificationService.showNotification(
        title: "Account Approved",
        body: "HostelFix account for $name has been approved by warden.",
        color: Colors.green,
      );
    } else {
      await NotificationService.showNotification(
        title: "Account Rejected",
        body: "The registration request for $name was rejected.",
        color: Colors.red,
      );
      await FirebaseFirestore.instance.collection('users').doc(id).delete();
    }
  }
}

// --- 3. COMPLAINTS LIST ---
class WardenComplaintsList extends StatefulWidget {
  final String hostelName;
  const WardenComplaintsList({super.key, required this.hostelName});

  @override
  State<WardenComplaintsList> createState() => _WardenComplaintsListState();
}

class _WardenComplaintsListState extends State<WardenComplaintsList> {
  String selectedStatus = 'All';
  String selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hostel Complaints")),
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
                        items: ['All', 'Pending', 'Assigned', 'In Progress', 'Completed']
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
                        value: selectedCategory,
                        isExpanded: true,
                        items: ['All', 'Electrician', 'Plumber', 'Carpenter', 'Painter', 'Cleaning', 'Other']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13))))
                            .toList(),
                        onChanged: (v) => setState(() => selectedCategory = v!),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getFilteredStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final complaints = snapshot.data!.docs;

                if (complaints.isEmpty) return const Center(child: Text("No complaints matching filters"));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: complaints.length,
                  itemBuilder: (context, index) {
                    final complaint = complaints[index];
                    final data = complaint.data() as Map<String, dynamic>;

                    return GlassContainer(
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        onTap: () => _viewDetails(context, complaint),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(data['title'] ?? 'Complaint', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Room: ${data['room']} • ${data['category']}", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                        trailing: _buildStatusBadge(data['status']),
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

  Stream<QuerySnapshot> _getFilteredStream() {
    Query query = FirebaseFirestore.instance.collection('complaints').where('hostel', isEqualTo: widget.hostelName);
    if (selectedStatus != 'All') query = query.where('status', isEqualTo: selectedStatus);
    if (selectedCategory != 'All') query = query.where('category', isEqualTo: selectedCategory);
    return query.snapshots();
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    if (status == 'Pending') color = Colors.orange;
    if (status == 'Assigned') color = Colors.blue;
    if (status == 'In Progress') color = Colors.purple;
    if (status == 'Completed') color = Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3))),
      child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  void _viewDetails(BuildContext context, DocumentSnapshot doc) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ComplaintDetailsScreen(doc: doc)));
  }
}

// --- 4. COMPLAINT DETAILS ---
class ComplaintDetailsScreen extends StatelessWidget {
  final DocumentSnapshot doc;
  const ComplaintDetailsScreen({super.key, required this.doc});

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final status = data['status'];

    return Scaffold(
      appBar: AppBar(title: const Text("Complaint Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassContainer(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _statusLabel(status),
                      Text(data['category'] ?? 'General', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(data['title'] ?? 'Title', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  Text(data['description'] ?? 'No description.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), height: 1.5)),
                  if (data['imageUrl'] != null) ...[
                    const SizedBox(height: 20),
                    const Text("ATTACHED PHOTO", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1)),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        data['imageUrl'],
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 200,
                            color: Colors.grey.withOpacity(0.1),
                            child: const Center(child: CircularProgressIndicator()),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text("Requester Info", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            GlassContainer(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _infoRow(context, Icons.person_rounded, "Student", data['name'] ?? data['studentName']),
                  _infoRow(context, Icons.meeting_room_rounded, "Room", data['room']),
                  _infoRow(context, Icons.phone_rounded, "Phone", data['studentPhone'] ?? 'N/A'),
                  _infoRow(context, Icons.calendar_today_rounded, "Reported Date", data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate().toString().split('.')[0] : 'N/A'),
                ],
              ),
            ),
            if (data['assignedTo'] != null) ...[
              const SizedBox(height: 24),
              const Text("Assigned Handling", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              GlassContainer(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _infoRow(context, Icons.engineering_rounded, "Contractor", data['assignedToName'] ?? 'Verified Staff'),
                    if (data['scheduledVisit'] != null)
                      _infoRow(context, Icons.event_available_rounded, "Scheduled Visit", (data['scheduledVisit'] as Timestamp).toDate().toString().split('.')[0]),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 48),
            if (status == 'Pending')
              SizedBox(width: double.infinity, child: ElevatedButton.icon(
                onPressed: () => _assignContractor(context),
                icon: const Icon(Icons.person_add_rounded),
                label: const Text("Assign Contractor", style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              )),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: OutlinedButton.icon(
              onPressed: () => _deleteComplaint(context),
              icon: const Icon(Icons.delete_sweep_rounded),
              label: const Text("Delete Complaint"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.all(18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _statusLabel(String status) {
    Color color = Colors.grey;
    if (status == 'Pending') color = Colors.orange;
    if (status == 'Assigned') color = Colors.blue;
    if (status == 'In Progress') color = Colors.purple;
    if (status == 'Completed') color = Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
    );
  }

  void _assignContractor(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => AssignContractorScreen(complaintId: doc.id, category: (doc.data() as Map)['category'])));
  }

  void _deleteComplaint(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Complaint"),
        content: const Text("Are you sure you want to delete this complaint?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(onPressed: () async {
            final data = doc.data() as Map<String, dynamic>;
            final title = data['title'] ?? 'Complaint';
            await doc.reference.delete();
            await NotificationService.showNotification(
              title: "Complaint Dismissed",
              body: "Your report '$title' was dismissed as irrelevant by the warden.",
              color: Colors.redAccent,
            );
            if (context.mounted) {
              Navigator.pop(ctx);
              Navigator.pop(context);
            }
          }, child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      )
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor.withOpacity(0.6)),
          const SizedBox(width: 12),
          Text("$label: ", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
          Text(value ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// --- 5. ASSIGN CONTRACTOR SCREEN ---
class AssignContractorScreen extends StatefulWidget {
  final String complaintId;
  final String category;
  const AssignContractorScreen({super.key, required this.complaintId, required this.category});

  @override
  State<AssignContractorScreen> createState() => _AssignContractorScreenState();
}

class _AssignContractorScreenState extends State<AssignContractorScreen> {
  bool showAll = false;

  String get normalizedCategory {
    final cat = widget.category.trim();
    if (cat == 'Electricity' || cat == 'Electrical') return 'Electrician';
    if (cat == 'Water' || cat == 'Plumbing') return 'Plumber';
    return cat;
  }

  @override
  Widget build(BuildContext context) {
    String searchTitle = showAll ? "All Staff" : "Assign $normalizedCategory";
    
    return Scaffold(
      appBar: AppBar(
        title: Text(searchTitle),
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => showAll = !showAll),
            icon: Icon(showAll ? Icons.filter_list_rounded : Icons.people_rounded, color: Theme.of(context).primaryColor),
            label: Text(showAll ? "Filter Roles" : "Show All", style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final contractors = snapshot.data?.docs ?? [];

          if (contractors.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.engineering_rounded, size: 80, color: Colors.grey.shade200),
                  const SizedBox(height: 16),
                  Text(
                    "No ${showAll ? '' : normalizedCategory + ' '}found",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  if (!showAll)
                    ElevatedButton(
                      onPressed: () => setState(() => showAll = true),
                      child: const Text("View All Verified Staff"),
                    )
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: contractors.length,
            itemBuilder: (context, index) {
              final contractor = contractors[index];
              final data = contractor.data() as Map<String, dynamic>;

              return GlassContainer(
                padding: EdgeInsets.zero,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    backgroundImage: (data['profilePhoto'] != null && data['profilePhoto'].toString().isNotEmpty) 
                        ? NetworkImage(data['profilePhoto']) 
                        : null,
                    child: (data['profilePhoto'] == null || data['profilePhoto'].toString().isEmpty) 
                        ? Icon(Icons.person_rounded, color: Theme.of(context).primaryColor) 
                        : null,
                  ),
                  title: Text(data['name'] ?? 'Staff', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${data['specialization']} • ${data['experience']}y Exp", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  trailing: ElevatedButton(
                    onPressed: () => _assign(context, contractor.id, data['name']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Assign"),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Stream<QuerySnapshot> _getStream() {
    Query query = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'Contractor')
        .where('approved', isEqualTo: true);
    
    if (!showAll) {
      query = query.where('specialization', isEqualTo: normalizedCategory);
    }
    
    return query.snapshots();
  }

  void _assign(BuildContext context, String contractorUid, String? contractorName) async {
    await FirebaseFirestore.instance.collection('complaints').doc(widget.complaintId).update({
      'status': 'Assigned',
      'assignedTo': contractorUid,
      'assignedToName': contractorName ?? 'Staff',
    });

    await NotificationService.showNotification(
      title: "New Task Assigned",
      body: "A new maintenance request has been assigned to $contractorName.",
      color: Colors.blueAccent,
    );
    
    if (context.mounted) {
      Navigator.pop(context); // Close assign screen
      Navigator.pop(context); // Close details screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Assigned to $contractorName successfully"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        )
      );
    }
  }
}

// --- 6. WARDEN PROFILE ---
class WardenProfile extends StatelessWidget {
  const WardenProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserProvider>(context).userData;

    return Scaffold(
      appBar: AppBar(title: const Text("My Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const SizedBox(height: 20),
            GlassContainer(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    backgroundImage: (userData?['profilePhoto'] != null && userData!['profilePhoto'].toString().isNotEmpty) ? NetworkImage(userData['profilePhoto']) : null,
                    child: userData?['profilePhoto'] == null ? Icon(Icons.person_rounded, size: 60, color: Theme.of(context).primaryColor) : null,
                  ),
                  const SizedBox(height: 24),
                  Text(userData?['name'] ?? 'N/A', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                  Text(userData?['email'] ?? 'N/A', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                  const SizedBox(height: 32),
                  const Divider(thickness: 0.5),
                  _profileItem(context, Icons.apartment_rounded, "Hostel", userData?['hostel']),
                  _profileItem(context, Icons.qr_code_rounded, "Hostel Code", userData?['hostelCode']),
                  _profileItem(context, Icons.phone_rounded, "Phone", userData?['phone']),
                ],
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Provider.of<UserProvider>(context, listen: false).clearUser();
                  Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text("Sign Out", style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.redAccent,
                  padding: const EdgeInsets.all(18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
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
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                Text(value ?? 'N/A', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
