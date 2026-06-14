import 'package:flutter/material.dart';

/// Curated color palette for the SmartSpend app.
class AppColors {
  AppColors._();

  // Primary palette — Teal/Emerald
  static const Color primary = Color(0xFF00BFA6);
  static const Color primaryLight = Color(0xFF5DF2D6);
  static const Color primaryDark = Color(0xFF008E76);

  // Surface colors — Dark mode
  static const Color darkBg = Color(0xFF0F1123);
  static const Color darkSurface = Color(0xFF1A1D35);
  static const Color darkCard = Color(0xFF222642);
  static const Color darkCardAlt = Color(0xFF2A2E4A);

  // Surface colors — Light mode
  static const Color lightBg = Color(0xFFF5F6FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);

  // Text colors
  static const Color textPrimary = Color(0xFFE8EAF6);
  static const Color textSecondary = Color(0xFF9DA3C2);
  static const Color textDark = Color(0xFF1A1D35);
  static const Color textDarkSecondary = Color(0xFF6B7280);

  // Accent colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFEF5350);
  static const Color info = Color(0xFF42A5F5);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00BFA6), Color(0xFF00E5CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF1A1D35), Color(0xFF0F1123)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF222642), Color(0xFF1A1D35)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Category colors
  static const Color foodColor = Color(0xFFFF6B6B);
  static const Color shoppingColor = Color(0xFF845EF7);
  static const Color travelColor = Color(0xFF339AF0);
  static const Color utilitiesColor = Color(0xFFFFD43B);
  static const Color entertainmentColor = Color(0xFFFF922B);
  static const Color othersColor = Color(0xFF69DB7C);
}
