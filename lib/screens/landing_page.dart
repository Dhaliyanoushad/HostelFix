import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/glass_container.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.build_circle_rounded, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(width: 12),
            Text(
              "HostelFix",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => themeProvider.toggleTheme(),
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            tooltip: "Toggle Theme",
          ),
          const SizedBox(width: 8),
          Consumer<UserProvider>(
            builder: (context, userProvider, _) {
              if (userProvider.userData != null) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: ElevatedButton(
                    onPressed: () => _navigateToDashboard(context, userProvider.userData!['role']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Dashboard"),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/select-role'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Login"),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Decorative Elements
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).primaryColor.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent.withOpacity(0.05),
              ),
            ),
          ),

          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 120, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Chip(
                  label: Text("PRO HOSTEL MAINTENANCE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                  side: BorderSide.none,
                  backgroundColor: Color(0xFFDBEAFE),
                  labelStyle: TextStyle(color: Color(0xFF1E40AF)),
                ),
                const SizedBox(height: 16),
                Text(
                  "Your Hostel Issue,\nSolved Faster",
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Report issues instantly, track progress in real-time, and enjoy a comfortable hostel life with our smart maintenance system.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/select-signup-role'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: const Text("Get Started", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text("Learn More", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 60),
                Text(
                  "Key Features",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 24),
                _buildGlassFeature(
                  context: context,
                  icon: Icons.bolt_rounded,
                  color: Colors.amber,
                  title: "Instant Reporting",
                  description: "Report any maintenance issue in seconds using our streamlined interface.",
                ),
                const SizedBox(height: 16),
                _buildGlassFeature(
                  context: context,
                  icon: Icons.track_changes_rounded,
                  color: Colors.blue,
                  title: "Real-time Tracking",
                  description: "Monitor the status of your complaints from 'Pending' to 'Resolved' live.",
                ),
                const SizedBox(height: 16),
                _buildGlassFeature(
                  context: context,
                  icon: Icons.verified_rounded,
                  color: Colors.green,
                  title: "Verified Staff",
                  description: "Professional contractors assigned by wardens to ensure high-quality fixes.",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassFeature({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDashboard(BuildContext context, String role) {
    if (role == 'Admin') {
      Navigator.pushReplacementNamed(context, '/admin-dashboard');
    } else if (role == 'Warden') {
      Navigator.pushReplacementNamed(context, '/warden-dashboard');
    } else if (role == 'Contractor') {
      Navigator.pushReplacementNamed(context, '/contractor-dashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }
}
