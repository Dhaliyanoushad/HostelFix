import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF0B0F1A);
  static const Color cardBg = Color(0xFF121A2F);
  static const Color primaryAccent = Color(0xFF3A7BFF);
  static const Color secondaryAccent = Color(0xFF00C6FF);
  static const Color highlightGlow = Color(0xFF4DA3FF);
  static const Color textFieldBg = Color(0xFF1A233A);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF9CA3AF);

  static const LinearGradient mainGradient = LinearGradient(
    colors: [primaryAccent, secondaryAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFF0B0F1A), Color(0xFF101A35)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
