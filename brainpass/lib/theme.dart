// theme.dart
//
// Centralised colours and themes. The parent area is calm and clean; the kid
// earn-card is bright, big, and cheerful (spec §9.8).

import 'package:flutter/material.dart';

class AppColors {
  // Brand
  static const primary = Color(0xFF5B6CF6); // friendly indigo/blue
  static const primaryDark = Color(0xFF3F4FD6);
  static const accent = Color(0xFFFFC83D); // sunny yellow (stars!)

  // Kid earn-card gradient
  static const kidTop = Color(0xFF6D8BFF);
  static const kidBottom = Color(0xFF8E6CFF);

  // Feedback
  static const correct = Color(0xFF2FBF71); // green
  static const wrong = Color(0xFFFF6B6B); // soft red (gentle, not scary)

  // Neutrals
  static const bg = Color(0xFFF6F7FB);
  static const card = Colors.white;
  static const textDark = Color(0xFF1F2333);
  static const textMuted = Color(0xFF6B7080);
}

class AppTheme {
  /// Parent-facing theme: clean, readable, calm.
  static ThemeData parent() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
      ),
      scaffoldBackgroundColor: AppColors.bg,
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.textDark,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE8EAF2)),
        ),
      ),
    );
  }

  /// Kid-facing theme used inside the overlay isolate.
  static ThemeData kid() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.kidBottom,
        brightness: Brightness.light,
      ),
      fontFamily: null,
    );
  }
}
