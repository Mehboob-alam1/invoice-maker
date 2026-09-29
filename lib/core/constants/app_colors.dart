import 'package:flutter/material.dart';

/// Central color palette for the app (aligned with blue Material seed).
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF3B82F6);
  static const Color secondary = Color(0xFF38BDF8);
  static const Color tertiary = Color(0xFF20C997); // success / paid green

  // Status
  static const Color success = Color(0xFF20C997);
  static const Color warning = Color(0xFFFFB020);
  static const Color danger = Color(0xFFFF5A5F);
  static const Color info = Color(0xFF3E8EFA);

  // Light theme surfaces
  static const Color lightBackground = Color(0xFFF7F7FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE7E7F0);
  static const Color lightTextPrimary = Color(0xFF14141F);
  static const Color lightTextSecondary = Color(0xFF6B6B7B);

  // Dark theme surfaces
  static const Color darkBackground = Color(0xFF0F0F16);
  static const Color darkSurface = Color(0xFF1A1A24);
  static const Color darkCard = Color(0xFF20202D);
  static const Color darkBorder = Color(0xFF2E2E3E);
  static const Color darkTextPrimary = Color(0xFFF3F3F8);
  static const Color darkTextSecondary = Color(0xFFA5A5B8);

  // Gradients
  static const List<Color> heroGradientLight = [
    Color(0xFFEDEBFF),
    Color(0xFFF7F7FB),
  ];
  static const List<Color> heroGradientDark = [
    Color(0xFF2A2A55),
    Color(0xFF0F0F16),
  ];
  static const List<Color> unlockGradient = [
    Color(0xFF1D4ED8),
    Color(0xFF3B82F6),
    Color(0xFF38BDF8),
  ];
}
