import 'package:flutter/material.dart';

class AppColors {
  // Brand palette — AMOLED dark first
  static const Color primaryDark = Color(0xFF071A2B);
  static const Color primaryGradientStart = Color(0xFF155EEF);
  static const Color primaryGradientEnd = Color(0xFF00C2FF);
  static const Color secondaryAccent = Color(0xFF00B8D9);
  static const Color notificationYellow = Color(0xFFFFC857);

  // Text
  static const Color textPrimary = Color(0xFFF0F0F8);
  static const Color textSecondary = Color(0xFF8A8AB0);

  // Backgrounds
  static const Color backgroundMain = Color(0xFF07131F);
  static const Color cardBackground = Color(0xFF10294A);
  static const Color surfaceElevated = Color(0xFF173A63);

  // Semantic
  static const Color success = Color(0xFF34C759);
  static const Color error = Color(0xFFFF3B30);
  static const Color warning = Color(0xFFFF9500);
  static const Color info = Color(0xFF007AFF);

  // UI
  static const Color dividerBorder = Color(0xFF24507A);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryGradientStart, primaryGradientEnd, Color(0xFF7B61FF)],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0B0E1A), Color(0xFF060914)],
  );

  // Shadows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x18000040), blurRadius: 12, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> softShadow = [
    BoxShadow(color: Color(0x0F000030), blurRadius: 8, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> primaryButtonShadow = [
    BoxShadow(color: Color(0x402E2A72), blurRadius: 16, offset: Offset(0, 6)),
  ];
}
