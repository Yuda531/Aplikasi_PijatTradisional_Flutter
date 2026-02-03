import 'package:flutter/material.dart';

/// Application color palette with leaf-green theme for health-oriented design.
class AppColors {
  AppColors._();

  // Primary: Bright leaf-green
  static const Color primary = Color(0xFF4CAF50);
  static const Color primaryLight = Color(0xFF81C784);
  static const Color primaryDark = Color(0xFF388E3C);

  // Background: Clean white
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF5F5F5);
  static const Color surfaceVariant = Color(0xFFE8F5E9);

  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status colors
  static const Color success = Color(0xFF66BB6A);
  static const Color warning = Color(0xFFFFB74D);
  static const Color error = Color(0xFFE57373);
  static const Color info = Color(0xFF64B5F6);

  // Booking status colors
  static const Color pending = Color(0xFFFFB74D);
  static const Color confirmed = Color(0xFF4CAF50);
  static const Color completed = Color(0xFF2196F3);
  static const Color cancelled = Color(0xFFE57373);
}
