import 'package:flutter/material.dart';

/// App colors (same values used in login_screen.dart by the Auth part).
class AppColors {
  static const Color background = Color(0xFFFAF5F8);
  static const Color primary = Color(0xFF623166);
  static const Color dark = Color(0xFF35103C);
  static const Color lightPurple = Color(0xFFEADFE9);
  static const Color text = Color(0xFF2D1730);
  static const Color textSecondary = Color(0xFF806D80);
  static const Color border = Color(0xFFE8D8E6);

  static const Color star = Color(0xFFE0A82E);
  static const Color greenBg = Color(0xFFDDF3E4);
  static const Color greenText = Color(0xFF1E6B3A);

  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x142D1730),
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];
}
