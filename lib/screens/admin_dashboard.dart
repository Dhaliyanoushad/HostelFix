import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/user_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/glass_container.dart';
import '../services/notification_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Admin Control Panel"),
          actions: [
            IconButton(
              icon: Icon(themeProvider.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
              onPressed: () => themeProvider.toggleTheme(),
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              onPressed: () => _showLogoutDialog(context),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(70),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: GlassContainer(
                padding: EdgeInsets.zero,
                borderRadius: 16,
                child: TabBar(
                  isScrollable: true,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).primaryColor.withOpacity(0.15),
                  ),
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: const [
                    Tab(text: "Approval Req.", icon: Icon(Icons.pending_actions_rounded, size: 20)),
                    Tab(text: "Contractors", icon: Icon(Icons.engineering_rounded, size: 20)),
                    Tab(text: "Hostels", icon: Icon(Icons.apartment_rounded, size: 20)),
                    Tab(text: "Students", icon: Icon(Icons.people_alt_rounded, size: 20)),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            PendingRequestsView(),
            ApprovedContractorsView(),
            HostelListView(),
            StudentListView(),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out of the admin panel?"),
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

class PendingRequestsView extends StatelessWidget {
  const PendingRequestsView({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('approved', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(Icons.check_circle_outline_rounded, "No pending requests", "All contractors have been processed.");
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return GlassContainer(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                        backgroundImage: (data['profilePhoto'] != null && data['profilePhoto'].toString().isNotEmpty) 
                            ? NetworkImage(data['profilePhoto']) 
                            : null,
                        child: (data['profilePhoto'] == null || data['profilePhoto'].toString().isEmpty) 
                            ? Icon(Icons.person_rounded, size: 30, color: Theme.of(context).primaryColor) 
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['name'] ?? 'Unknown',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (data['role'] == 'Warden' ? Colors.pink : Theme.of(context).primaryColor).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                data['role'] == 'Warden' ? "WARDEN: ${data['hostel'] ?? 'N/A'}" : (data['specialization'] ?? 'N/A'),
                                style: TextStyle(color: data['role'] == 'Warden' ? Colors.pink : Theme.of(context).primaryColor, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32, thickness: 0.5),
                  _infoRow(context, Icons.phone_rounded, "Phone", data['phone'] ?? 'N/A'),
                  if (data['role'] == 'Contractor')
                    _infoRow(context, Icons.work_history_rounded, "Job Experience", data['experience'] ?? 'N/A'),
                  if (data['role'] == 'Warden')
                    _infoRow(context, Icons.qr_code_rounded, "Hostel Code", data['hostelCode'] ?? 'N/A'),
                  const SizedBox(height: 16),
                  if (data['verificationImageUrl'] != null && data['verificationImageUrl'].toString().isNotEmpty) ...[
                    const Text("VERIFICATION DOCUMENT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1)),
                    const SizedBox(height: 8),
                    Text("Type: ${data['verificationType'] ?? 'Aadhaar Card'}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _showFullImage(context, data['verificationImageUrl']),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.network(
                              data['verificationImageUrl'],
                              width: double.infinity,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(height: 120, color: Colors.grey.shade100, child: const Icon(Icons.broken_image_rounded)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.zoom_in_rounded, color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text("VIEW DOCUMENT", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _approveRequest(doc.id, data['uid'], data['name'] ?? 'User', data['role']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Accept Request", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _rejectRequest(doc.id, data['uid'], data['name'] ?? 'User', data['role']),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFEF4444),
                            side: const BorderSide(color: Color(0xFFEF4444)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Reject", style: TextStyle(fontWeight: FontWeight.bold)),
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
    );
  }

  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _approveRequest(String id, String uid, String name, String role) async {
    await FirebaseFirestore.instance.collection('users').doc(id).update({'approved': true});
    await NotificationService.sendNotification(
      recipientId: uid,
      title: "$role Approved",
      body: "The profile for $name has been verified and approved.",
    );
  }

  void _rejectRequest(String id, String uid, String name, String role) async {
    await NotificationService.sendNotification(
      recipientId: uid,
      title: "$role Rejected",
      body: "The registration request for $name was declined.",
    );
    await FirebaseFirestore.instance.collection('users').doc(id).delete();
  }
}

class ApprovedContractorsView extends StatelessWidget {
  const ApprovedContractorsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'Contractor')
              .where('approved', isEqualTo: true)
              .snapshots(),
          builder: (context, snapshot) {
            int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
            return GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              gradient: LinearGradient(
                colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Active contractors on system",
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                    child: Text(
                      "$count",
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'Contractor')
                .where('approved', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState(Icons.engineering_rounded, "No Contractors", "Approved contractors will appear here.");
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;

                  return GlassContainer(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                        backgroundImage: (data['profilePhoto'] != null && data['profilePhoto'].toString().isNotEmpty)
                            ? NetworkImage(data['profilePhoto']) 
                            : null,
                        child: (data['profilePhoto'] == null || data['profilePhoto'].toString().isEmpty)
                            ? Icon(Icons.person_rounded, color: Theme.of(context).primaryColor) 
                            : null,
                      ),
                      title: Text(data['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text("${data['specialization']} • ${data['phone']}", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 13)),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                        onPressed: () => _confirmDelete(context, doc.id, data['name']),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, String id, String? name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Contractor"),
        content: Text("Are you sure you want to permanently remove ${name ?? 'this contractor'} from the system?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('users').doc(id).delete();
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class HostelListView extends StatelessWidget {
  const HostelListView({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'Warden').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(Icons.apartment_rounded, "No Hostels", "Hostels with assigned wardens will show here.");
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final hostelName = data['hostel'] ?? 'Unknown Hostel';
            final wardenName = data['name'] ?? 'N/A';

            return GlassContainer(
              padding: EdgeInsets.zero,
              child: ExpansionTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.apartment_rounded, color: Theme.of(context).primaryColor),
                ),
                title: Text(hostelName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Text("Warden: $wardenName", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 13)),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.02)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Registered Students", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 12),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .where('role', isEqualTo: 'Student')
                              .where('hostel', isEqualTo: hostelName)
                              .snapshots(),
                          builder: (context, studentsSnap) {
                            if (!studentsSnap.hasData) return const LinearProgressIndicator();
                            final students = studentsSnap.data!.docs;
                            if (students.isEmpty) return const Text("No students found in this hostel", style: TextStyle(color: Colors.grey, fontSize: 13));

                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: students.length,
                              separatorBuilder: (context, _) => const Divider(height: 0.5),
                              itemBuilder: (context, i) {
                                final sData = students[i].data() as Map<String, dynamic>;
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  leading: CircleAvatar(radius: 14, backgroundColor: Theme.of(context).primaryColor.withOpacity(0.05), child: Text("${i + 1}", style: TextStyle(fontSize: 10, color: Theme.of(context).primaryColor))),
                                  title: Text(sData['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w500)),
                                  subtitle: Text("ID: ${sData['studentId'] ?? 'N/A'}", style: const TextStyle(fontSize: 11)),
                                );
                              },
                            );
                          },
                        )
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class StudentListView extends StatelessWidget {
  const StudentListView({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'Student').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final students = snapshot.hasData ? snapshot.data!.docs : [];
        if (students.isEmpty) return _buildEmptyState(Icons.people_alt_rounded, "No Students", "Student database is empty.");

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: GlassContainer(
                padding: EdgeInsets.zero,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search students...",
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: Colors.transparent,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final data = students[index].data() as Map<String, dynamic>;
                  return GlassContainer(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1), child: Icon(Icons.person_rounded, color: Theme.of(context).primaryColor)),
                      title: Text(data['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("${data['hostel']} • Room: ${data['room']}"),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

Widget _infoRow(BuildContext context, IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
        const SizedBox(width: 8),
        Text("$label: ", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
      ],
    ),
  );
}

Widget _buildEmptyState(IconData icon, String title, String subtitle) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 80, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        Text(subtitle, style: TextStyle(color: Colors.grey.shade500)),
      ],
    ),
  );
}
