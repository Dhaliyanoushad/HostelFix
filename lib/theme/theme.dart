import 'package:flutter/material.dart';

class AppColors {
  static const gradientStart = Color(0xFF667eea);
  static const gradientEnd = Color(0xFF764ba2);
  static const glassWhite = Color(0x30FFFFFF);
  static const textWhite = Colors.white;
  static const textGrey = Color(0xFFB0B0B0);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      fontFamily: 'Poppins',
      scaffoldBackgroundColor: Colors.transparent,
    );
  }
}