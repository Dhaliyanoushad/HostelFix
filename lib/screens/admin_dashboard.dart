import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/user_provider.dart';
import '../widgets/custom_widgets.dart';
import '../theme/app_theme.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text("Admin Cyber-Panel"),
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
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: AppColors.primaryAccent,
            indicatorWeight: 3,
            labelColor: AppColors.primaryAccent,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: const [
              Tab(text: "Tickets"),
              Tab(text: "Approval"),
              Tab(text: "Contractors"),
              Tab(text: "Hostels"),
            ],
          ),
        ),
        body: const FuturisticBackground(
          child: TabBarView(
            children: [
              ComplaintsView(),
              ContractorApprovalView(),
              ContractorListView(),
              HostelsView(),
            ],
          ),
        ),
      ),
    );
  }
}

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
        const SizedBox(height: 100), // Account for transparent AppBar
        _buildFilterBar(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _getComplaintsStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Center(
                  child: Text(
                    "Empty Archives",
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  return _buildComplaintCard(docs[index], context);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: statuses.map((status) {
          final isSelected = selectedStatus == status;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(status),
              selected: isSelected,
              onSelected: (val) {
                if (val) {
                  setState(() => selectedStatus = status);
                }
              },
              backgroundColor: AppColors.textFieldBg,
              selectedColor: AppColors.primaryAccent.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected
                    ? AppColors.primaryAccent
                    : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }).toList(),
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

  Widget _buildComplaintCard(DocumentSnapshot doc, BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final isHigh = data['priority'] == 'high';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        showGlow: isHigh,
        padding: const EdgeInsets.all(16),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isHigh ? Colors.redAccent : AppColors.primaryAccent)
                  .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isHigh
                  ? Icons.priority_high_rounded
                  : Icons.confirmation_number_rounded,
              color: isHigh ? Colors.redAccent : AppColors.primaryAccent,
            ),
          ),
          title: Text(
            data['title'] ?? 'N/A',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          subtitle: Text(
            "${data['room'] ?? 'N/A'} • ${data['status']}",
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

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
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(
            child: Text(
              "No Pending Clearances",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GlassCard(
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.textFieldBg,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(
                        data['name'] ?? 'N/A',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        "${data['specialization']} • ${data['phone']}",
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    const Divider(color: Colors.white10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () =>
                              _handleApproval(context, docs[index].id, false),
                          child: const Text(
                            "REJECT",
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryAccent.withValues(
                              alpha: 0.2,
                            ),
                            foregroundColor: AppColors.primaryAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () =>
                              _handleApproval(context, docs[index].id, true),
                          child: const Text(
                            "APPROVE",
                            style: TextStyle(fontWeight: FontWeight.bold),
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
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Access Granted ✅")));
      }
    } else {
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Access Revoked ❌")));
      }
    }
  }
}

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
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(
            child: Text(
              "Zero Contractors Active",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.engineering_rounded,
                    color: AppColors.secondaryAccent,
                  ),
                  title: Text(
                    data['name'] ?? 'N/A',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    "${data['specialization']} • ${data['phone']}",
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete_sweep_rounded,
                      color: Colors.redAccent,
                    ),
                    onPressed: () => _confirmDelete(context, docs[index].id),
                  ),
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
        backgroundColor: AppColors.cardBg,
        title: const Text(
          "Terminal Revocation",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Permanently delete this contractor from the grid?",
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "CANCEL",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .delete();
            },
            child: const Text(
              "REVOKE",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}

class HostelsView extends StatelessWidget {
  const HostelsView({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final allUsers = snapshot.data!.docs;
        final wardens = allUsers
            .where(
              (u) => (u.data() as Map<String, dynamic>)['role'] == 'Warden',
            )
            .toList();
        final hostels = wardens
            .map((w) => (w.data() as Map<String, dynamic>)['hostel'] as String)
            .toSet()
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
          itemCount: hostels.length,
          itemBuilder: (context, index) {
            final hName = hostels[index];
            final warden = wardens.firstWhere(
              (w) => (w.data() as Map<String, dynamic>)['hostel'] == hName,
            );
            final wData = warden.data() as Map<String, dynamic>;
            final sCount = allUsers
                .where(
                  (u) =>
                      (u.data() as Map<String, dynamic>)['role'] == 'Student' &&
                      (u.data() as Map<String, dynamic>)['hostel'] == hName,
                )
                .length;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          hName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Icon(
                          Icons.apartment_rounded,
                          color: AppColors.primaryAccent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Custodian: ${wData['name']}",
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    Text(
                      "Population: $sCount units",
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    NeonButton(
                      label: "INSPECT SECTOR",
                      height: 45,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StudentListPage(
                              hostelName: hName,
                              wardenName: wData['name'],
                            ),
                          ),
                        );
                      },
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(widget.hostelName)),
      body: FuturisticBackground(
        child: Column(
          children: [
            const SizedBox(height: 100),
            Padding(
              padding: const EdgeInsets.all(24),
              child: CustomTextField(
                label: "Scan Database...",
                controller: TextEditingController(text: search),
                prefixIcon: Icons.search_rounded,
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
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final students = snapshot.data!.docs.where((s) {
                    final name = (s.data() as Map<String, dynamic>)['name']
                        .toString()
                        .toLowerCase();
                    return name.contains(search.toLowerCase());
                  }).toList();

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final s = students[index].data() as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassCard(
                          showGlow: false,
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              s['name'] ?? 'N/A',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              "Unit: ${s['room'] ?? 'N/A'}",
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            trailing: Text(
                              s['studentId'] ?? '',
                              style: const TextStyle(
                                color: AppColors.primaryAccent,
                                fontSize: 10,
                              ),
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
      ),
    );
  }
}
