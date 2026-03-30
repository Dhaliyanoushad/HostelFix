import 'package:flutter/material.dart';
import 'dart:ui';
import 'signup_page.dart';
import '../widgets/glass_container.dart';

class SelectSignupRoleScreen extends StatelessWidget {
  const SelectSignupRoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF10B981).withOpacity(0.08),
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, top: 8),
              child: IconButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false),
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                tooltip: "Back to Home",
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Hero(
                    tag: 'logo',
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.build_circle_rounded, size: 64, color: Color(0xFF10B981)),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "Join HostelFix",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Create your account to start managing issues",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                  ),
                  const SizedBox(height: 48),
                  
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildRoleCard(context, "Student", Icons.person_rounded, const Color(0xFF2563EB)),
                      _buildRoleCard(context, "Warden", Icons.security_rounded, const Color(0xFF10B981)),
                      _buildRoleCard(context, "Admin", Icons.admin_panel_settings_rounded, const Color(0xFFEF4444)),
                      _buildRoleCard(context, "Contractor", Icons.handyman_rounded, const Color(0xFF8B5CF6)),
                    ],
                  ),

                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/select-role'),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                        children: [
                          TextSpan(text: "Already have an account? ", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                          TextSpan(
                            text: "Login",
                            style: TextStyle(color: const Color(0xFF10B981), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard(BuildContext context, String role, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SignupPage(role: role)),
        );
      },
      child: GlassContainer(
        padding: EdgeInsets.zero,
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
              role,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
