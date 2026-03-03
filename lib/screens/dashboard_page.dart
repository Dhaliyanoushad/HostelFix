import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/user_provider.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text("HostelFix Dashboard"),
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
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 800 ? 4 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            dashboardCard(
              title: "Report Issue",
              icon: Icons.report_problem,
              color: Colors.redAccent,
              onTap: () {
                Navigator.pushNamed(context, '/report-issue');
              },
            ),

            dashboardCard(
              title: "My Complaints",
              icon: Icons.list_alt,
              color: Colors.blueAccent,
              onTap: () {
                Navigator.pushNamed(context, '/my-complaints');
              },
            ),
            dashboardCard(
              title: "In Progress",
              icon: Icons.build,
              color: Colors.orangeAccent,
            ),
            dashboardCard(
              title: "Completed",
              icon: Icons.check_circle,
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget dashboardCard({
    required String title,
    required IconData icon,
    required Color color,
    VoidCallback? onTap, // 👈 ADD THIS
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap, // 👈 USE IT HERE
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, size: 30, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
