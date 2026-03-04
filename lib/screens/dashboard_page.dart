import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/user_provider.dart';
import '../widgets/custom_widgets.dart';
import '../theme/app_theme.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Important for floating nav bar
      body: FuturisticBackground(
        child: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              _buildHomeTab(context),
              const Center(
                child: Text(
                  "Notifications",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const Center(
                child: Text("Profile", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildFloatingNavBar(),
    );
  }

  Widget _buildHomeTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          _buildHeader(context),
          const SizedBox(height: 32),
          const Text(
            "Hostel Services",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _dashboardCard(
                  title: "Report Issue",
                  icon: Icons.report_problem_rounded,
                  color: Colors.redAccent,
                  onTap: () => Navigator.pushNamed(context, '/report-issue'),
                ),
                _dashboardCard(
                  title: "My Complaints",
                  icon: Icons.list_alt_rounded,
                  color: AppColors.primaryAccent,
                  onTap: () => Navigator.pushNamed(context, '/my-complaints'),
                ),
                _dashboardCard(
                  title: "In Progress",
                  icon: Icons.build_circle_rounded,
                  color: Colors.orangeAccent,
                ),
                _dashboardCard(
                  title: "Completed",
                  icon: Icons.check_circle_rounded,
                  color: Colors.greenAccent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final user = Provider.of<UserProvider>(context).userData;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hello, ${user?['name']?.split(' ')[0] ?? 'Student'} 👋",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Hostel: ${user?['hostel'] ?? 'Loading...'}",
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        GestureDetector(
          onTap: () async {
            await FirebaseAuth.instance.signOut();
            if (context.mounted) {
              Provider.of<UserProvider>(context, listen: false).clearUser();
              Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.logout_rounded, color: Colors.redAccent),
          ),
        ),
      ],
    );
  }

  Widget _dashboardCard({
    required String title,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingNavBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.cardBg.withOpacity(0.95),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(0, Icons.home_rounded),
          _navItem(1, Icons.notifications_rounded),
          _navItem(2, Icons.person_rounded),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: isSelected
            ? BoxDecoration(
                color: AppColors.primaryAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              )
            : null,
        child: Icon(
          icon,
          color: isSelected ? AppColors.primaryAccent : AppColors.textSecondary,
          size: 28,
          shadows: isSelected
              ? [
                  Shadow(
                    color: AppColors.primaryAccent.withOpacity(0.5),
                    blurRadius: 10,
                  ),
                ]
              : [],
        ),
      ),
    );
  }
}
