import 'package:flutter/material.dart';
import 'signup_page.dart';
import '../widgets/custom_widgets.dart';
import '../theme/app_theme.dart';

class SelectSignupRoleScreen extends StatelessWidget {
  const SelectSignupRoleScreen({super.key});

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
                    "Join HostelFix",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Select your role to register",
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
                        AppColors.secondaryAccent,
                      ),
                      _buildRoleCard(
                        context,
                        "Warden",
                        Icons.security,
                        Colors.pinkAccent,
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
                    onTap: () =>
                        Navigator.pushReplacementNamed(context, '/select-role'),
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 14),
                        children: [
                          TextSpan(
                            text: "Already have an account? ",
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          TextSpan(
                            text: "Login",
                            style: TextStyle(
                              color: AppColors.primaryAccent,
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
          MaterialPageRoute(builder: (context) => SignupPage(role: role)),
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
