import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_widgets.dart';
import '../theme/app_theme.dart';

class MyComplaintsPage extends StatelessWidget {
  final String? initialFilter;
  const MyComplaintsPage({super.key, this.initialFilter});

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserProvider>(context).userData;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text("My Activity")),
      body: FuturisticBackground(
        child: userData == null
            ? const Center(
                child: Text(
                  "User not logged in",
                  style: TextStyle(color: Colors.white),
                ),
              )
            : StreamBuilder<QuerySnapshot>(
                stream: () {
                  Query query = FirebaseFirestore.instance
                      .collection('complaints')
                      .where(
                        Filter.or(
                          Filter('studentId', isEqualTo: userData['uid']),
                          Filter('uid', isEqualTo: userData['uid']),
                        ),
                      );

                  if (initialFilter != null) {
                    query = query.where('status', isEqualTo: initialFilter);
                  }

                  return query.snapshots();
                }(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Error: ${snapshot.error}",
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryAccent,
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "No records found",
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }

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
                    padding: const EdgeInsets.fromLTRB(24, 100, 24, 100),
                    itemCount: complaints.length,
                    itemBuilder: (context, index) {
                      final data =
                          complaints[index].data() as Map<String, dynamic>;
                      return ComplaintCardView(data: data);
                    },
                  );
                },
              ),
      ),
    );
  }
}

class ComplaintCardView extends StatelessWidget {
  final Map<String, dynamic> data;
  const ComplaintCardView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final String status = data['status'] ?? 'Pending';
    final String date = data['createdAt'] != null
        ? DateFormat('dd MMM yyyy').format(data['createdAt'].toDate())
        : '—';
    final String desc = data['issueDescription'] ?? data['description'] ?? '';
    final String priority = data['priority'] ?? 'normal';

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: GlassCard(
        showGlow: priority == 'high',
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    data['title'] ?? 'No Title',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                _StatusTag(status: status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoBadge(
                  Icons.category_rounded,
                  data['category'] ?? 'General',
                ),
                const SizedBox(width: 8),
                if (priority == 'high')
                  _buildInfoBadge(
                    Icons.warning_rounded,
                    'Emergency',
                    color: Colors.redAccent,
                  ),
              ],
            ),
            if (desc.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                desc,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Ref: #${data['registerNumber']?.toString().split('_').last ?? 'N/A'}",
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryAccent,
                  ),
                ),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge(
    IconData icon,
    String label, {
    Color color = AppColors.secondaryAccent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  final String status;
  const _StatusTag({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'Resolved':
      case 'Completed':
        color = Colors.greenAccent;
        break;
      case 'In Progress':
      case 'Assigned':
        color = Colors.orangeAccent;
        break;
      default:
        color = Colors.redAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
