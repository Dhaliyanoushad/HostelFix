import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/glass_container.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MyComplaintsPage extends StatelessWidget {
  const MyComplaintsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userData = userProvider.userData;
    final themeProvider = context.watch<ThemeProvider>();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("My Reports", style: TextStyle(fontWeight: FontWeight.w900)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: GlassContainer(
                padding: EdgeInsets.zero,
                borderRadius: 12,
                child: TabBar(
                  isScrollable: true,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Theme.of(context).primaryColor.withOpacity(0.15),
                  ),
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: const [
                    Tab(text: "All"),
                    Tab(text: "Pending"),
                    Tab(text: "In Progress"),
                    Tab(text: "Completed"),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: userData == null
            ? const Center(child: Text("Please sign in to view your reports"))
            : TabBarView(
                children: [
                  _ComplaintsList(userData: userData, filterStatus: 'All'),
                  _ComplaintsList(userData: userData, filterStatus: 'Pending'),
                  _ComplaintsList(userData: userData, filterStatus: 'In Progress'),
                  _ComplaintsList(userData: userData, filterStatus: 'Completed'),
                ],
              ),
      ),
    );
  }
}

class _ComplaintsList extends StatelessWidget {
  final Map<String, dynamic> userData;
  final String filterStatus;

  const _ComplaintsList({required this.userData, required this.filterStatus});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
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
              padding: const EdgeInsets.all(32),
              child: Text(
                "Error loading data: ${snapshot.error}",
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
          return _buildEmptyState();
        }

        // Client-side filtering and sorting
        var complaints = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] ?? 'Pending';
          
          if (filterStatus == 'All') return true;
          if (filterStatus == 'Pending') return status == 'Pending' || status == 'Assigned';
          if (filterStatus == 'In Progress') return status == 'In Progress' || status == 'Accepted';
          if (filterStatus == 'Completed') return status == 'Completed' || status == 'Resolved';
          return false;
        }).toList();

        if (complaints.isEmpty) {
          return _buildEmptyState();
        }

        complaints.sort((a, b) {
          final t1 = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          final t2 = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          if (t1 == null) return 1;
          if (t2 == null) return -1;
          return t2.compareTo(t1);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: complaints.length,
          itemBuilder: (context, index) {
            final data = complaints[index].data() as Map<String, dynamic>;
            return _ComplaintListItem(data: data);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_rounded, size: 80, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Text(
            filterStatus == 'All' ? "No reports found" : "No $filterStatus reports",
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text("All clear! No issues reported here.", style: TextStyle(color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}

class _ComplaintListItem extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ComplaintListItem({required this.data});

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'Pending';
    final date = data['createdAt'] != null
        ? DateFormat('MMM dd, yyyy • hh:mm a').format(data['createdAt'].toDate())
        : 'Processing...';
    final String desc = data['issueDescription'] ?? data['description'] ?? 'No description provided';
    final priority = data['priority'] ?? 'normal';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: EdgeInsets.zero,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: _buildStatusIcon(status),
          title: Text(
            data['title'] ?? 'Maintenance Request',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(data['category'] ?? 'General', style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          trailing: _buildStatusBadge(status, priority),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(thickness: 0.5, height: 24),
                  const Text("DETAILS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1)),
                  const SizedBox(height: 8),
                  Text(desc, style: TextStyle(height: 1.5, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8))),
                  if (data['imageUrl'] != null) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        data['imageUrl'],
                        width: double.infinity,
                        height: 150,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(child: CircularProgressIndicator()),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("REPORTED ON", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                          Text(date, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      if (data['assignedToName'] != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text("ASSIGNED TO", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                            Text(data['assignedToName'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                    ],
                  ),
                  if (data['scheduledVisit'] != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.event_available_rounded, size: 20, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("SCHEDULED VISIT", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                              Text(
                                DateFormat('MMM dd, yyyy • hh:mm a').format((data['scheduledVisit'] as Timestamp).toDate()),
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    IconData icon;
    Color color;
    switch (status) {
      case 'Completed':
      case 'Resolved':
        icon = Icons.check_circle_rounded;
        color = Colors.green;
        break;
      case 'In Progress':
        icon = Icons.pending_rounded;
        color = Colors.orange;
        break;
      case 'Accepted':
      case 'Assigned':
        icon = Icons.engineering_rounded;
        color = Colors.blue;
        break;
      default:
        icon = Icons.access_time_filled_rounded;
        color = Colors.redAccent;
    }
    return Icon(icon, color: color, size: 28);
  }

  Widget _buildStatusBadge(String status, String priority) {
    Color color = Colors.grey;
    if (status == 'Pending') color = (priority == 'high' ? Colors.redAccent : Colors.orange);
    if (status == 'Assigned') color = Colors.blue;
    if (status == 'Accepted') color = Colors.lightBlue;
    if (status == 'In Progress') color = Colors.purple;
    if (status == 'Completed' || status == 'Resolved') color = Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.3))),
      child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
