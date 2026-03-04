import 'package:flutter/material.dart';
import '../widgets/custom_widgets.dart';
import '../theme/app_theme.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.build, color: AppColors.secondaryAccent),
            SizedBox(width: 8),
            Text("HostelFix"),
          ],
        ),
      ),
      body: FuturisticBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.home_work_rounded,
                  size: 100,
                  color: AppColors.primaryAccent,
                ),
                const SizedBox(height: 24),
                Text(
                  "Smart Hostel Management",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    shadows: [
                      Shadow(
                        color: AppColors.primaryAccent.withOpacity(0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Futuristic solution for tracking issues and maintaining your living space.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 48),
                NeonButton(
                  label: "GET STARTED",
                  onPressed: () => Navigator.pushNamed(context, '/select-role'),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/select-signup-role'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55),
                    side: const BorderSide(color: AppColors.secondaryAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "CREATE ACCOUNT",
                    style: TextStyle(
                      color: AppColors.secondaryAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
