import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hostel_fix/services/notification_service.dart';
import '../providers/user_provider.dart';
import '../widgets/custom_widgets.dart';
import '../theme/app_theme.dart';

class ContractorDashboard extends StatefulWidget {
  const ContractorDashboard({super.key});

  @override
  State<ContractorDashboard> createState() => _ContractorDashboardState();
}

class _ContractorDashboardState extends State<ContractorDashboard> {
  String selectedStatus = 'Assigned';
  final List<String> statuses = ['Assigned', 'In Progress', 'Completed'];

  @override
  Widget build(BuildContext context) {
    final contractorId = Provider.of<UserProvider>(context).uid;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Operative Task-Log"),
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
        child: Column(
          children: [
            const SizedBox(height: 100),
            _buildFilterBar(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('complaints')
                    .where('assignedContractorId', isEqualTo: contractorId)
                    .where('status', isEqualTo: selectedStatus)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final complaints = snapshot.data!.docs;

                  if (complaints.isEmpty) {
                    return const Center(
                      child: Text(
                        "Zero assignments in this sector",
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: complaints.length,
                    itemBuilder: (context, index) {
                      final doc = complaints[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final isHigh = data['priority'] == 'high';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: GlassCard(
                          showGlow: isHigh,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      data['title'] ?? 'Task',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  if (isHigh)
                                    const Icon(
                                      Icons.bolt_rounded,
                                      color: Colors.orangeAccent,
                                      size: 20,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_rounded,
                                    size: 14,
                                    color: AppColors.primaryAccent,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${data['hostel']} • Room ${data['room']}",
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                data['issueDescription'] ??
                                    data['description'] ??
                                    '',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              const Divider(color: Colors.white10, height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (selectedStatus == 'Assigned')
                                    NeonButton(
                                      label: "INITIALIZE WORK",
                                      height: 45,
                                      onPressed: () => _updateTaskStatus(
                                        doc.id,
                                        'In Progress',
                                      ),
                                    ),
                                  if (selectedStatus == 'In Progress')
                                    NeonButton(
                                      label: "COMPLETE TASK",
                                      height: 45,
                                      onPressed: () => _updateTaskStatus(
                                        doc.id,
                                        'Completed',
                                      ),
                                    ),
                                  if (selectedStatus == 'Completed')
                                    const Icon(
                                      Icons.verified_rounded,
                                      color: Colors.greenAccent,
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.textFieldBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: statuses.map((status) {
            final isSelected = selectedStatus == status;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => selectedStatus = status),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryAccent.withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      status,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.primaryAccent
                            : AppColors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _updateTaskStatus(String id, String newStatus) async {
    await FirebaseFirestore.instance.collection('complaints').doc(id).update({
      'status': newStatus,
    });
    if (newStatus == 'Completed') {
      await NotificationService.showNotification(
        title: "Work Completed",
        body: "The contractor has finished working on your complaint.",
      );
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sector Registry Updated: $newStatus")),
      );
    }
  }
}
