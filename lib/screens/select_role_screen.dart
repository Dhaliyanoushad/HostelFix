import 'package:flutter/material.dart';
import 'login_page.dart';
import '../widgets/custom_widgets.dart';
import '../theme/app_theme.dart';

class SelectRoleScreen extends StatelessWidget {
  const SelectRoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FuturisticBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Welcome Back",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Select your role to login",
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 48),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    children: [
                      _buildRoleCard(
                        context,
                        "Student",
                        Icons.person,
                        AppColors.primaryAccent,
                      ),
                      _buildRoleCard(
                        context,
                        "Warden",
                        Icons.security,
                        Colors.pinkAccent,
                      ),
                      _buildRoleCard(
                        context,
                        "Admin",
                        Icons.admin_panel_settings,
                        Colors.redAccent,
                      ),
                      _buildRoleCard(
                        context,
                        "Contractor",
                        Icons.handyman,
                        Colors.greenAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacementNamed(
                      context,
                      '/select-signup-role',
                    ),
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 14),
                        children: [
                          TextSpan(
                            text: "Don't have an account? ",
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          TextSpan(
                            text: "Sign Up",
                            style: TextStyle(
                              color: AppColors.secondaryAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context,
    String role,
    IconData icon,
    Color color,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LoginPage(role: role)),
        );
      },
      child: GlassCard(
        showGlow: true,
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              role,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
