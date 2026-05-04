import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2A0F54);
  static const Color primaryLight = Color(0xFF5D39ED);
  static const Color white = Colors.white;
  static const Color white70 = Colors.white70;

  // Light theme
  static const Color background = Color(0xFFF8F7FF);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);

  // Dark theme
  static const Color backgroundDark = Color(0xFF0F111A);
  static const Color surfaceDark = Color(0xFF171A24);
  static const Color textPrimaryDark = Color(0xFFE9EAF2);
  static const Color textSecondaryDark = Color(0xFF9BA3B8);

  static Color successSurface(Brightness brightness) {
    return brightness == Brightness.dark
        ? const Color(0xFF153D2C)
        : const Color(0xFFE8F6EE);
  }

  static Color successText(Brightness brightness) {
    return brightness == Brightness.dark
        ? const Color(0xFFA6F2C3)
        : const Color(0xFF1D6B44);
  }

  static Color warningSurface(Brightness brightness) {
    return brightness == Brightness.dark
        ? const Color(0xFF3D2B14)
        : const Color(0xFFFFF4E8);
  }

  static Color warningText(Brightness brightness) {
    return brightness == Brightness.dark
        ? const Color(0xFFFFD7A1)
        : const Color(0xFF8B4A00);
  }

  // Onboarding page accent colors
  static const Color onboarding1 = Color(0xFF5D39ED);
  static const Color onboarding2 = Color(0xFF7B2FBE);
  static const Color onboarding3 = Color(0xFF2A5FD9);
  static const Color onboarding4 = Color(0xFF1A6B5A);
}
