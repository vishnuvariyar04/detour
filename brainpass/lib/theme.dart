// theme.dart
//
// The Nupo design system: one palette, one type scale (Nunito), one card
// language. Every screen builds from these tokens so the whole app feels like
// one product. Parent area is calm and premium; kid surfaces stay bright.

import 'package:flutter/material.dart';

class AppColors {
  // Brand
  static const primary = Color(0xFF7C3AED);
  static const primaryBright = Color(0xFF8B5CF6); // gradient partner
  static const primarySoft = Color(0xFFF6F1FF);
  static const primaryDeep = Color(0xFF5B21B6); // text on lilac // icon-badge / tint bg

  // Sunny yellow from the logo — the second brand color. Used for warmth,
  // rewards and highlights (halo behind the owl, stars, earn chips).
  static const accent = Color(0xFFF9C13C);
  static const accentSoft = Color(0xFFFFFCEF); // halo / tint bg
  static const accentDeep = Color(0xFF8A6100); // readable text on accentSoft

  // Kid earn-card gradient
  static const kidTop = Color(0xFF6D8BFF);
  static const kidBottom = Color(0xFF8E6CFF);

  // Feedback
  static const correct = Color(0xFF12B76A);
  static const correctSoft = Color(0xFFE7F8EF);
  static const wrong = Color(0xFFF04438);
  /// Finished state (Setup Flow), distinct from `correct`.
  static const done = Color(0xFF0E9384);
  static const wrongSoft = Color(0xFFFFF1F1);

  // Neutrals
  static const bg = Color(0xFFF6F1FF);
  static const card = Colors.white;
  static const cardBorder = Color(0xFFEADFFB);
  static const line = Color(0xFFECE9F8); // hairline borders
  static const textDark = Color(0xFF241C3B); // deep ink with purple cast
  static const textMuted = Color(0xFF7C7789);

  /// Full-screen background: soft purple wash fading to white.
  static BoxDecoration bgDecoration() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFEFEAFF), Color(0xFFFDFCFF)],
      ),
    );
  }

  /// The one shadow used under every floating card.
  static const List<BoxShadow> softShadow = [
    BoxShadow(color: Color(0x14311B92), blurRadius: 24, offset: Offset(0, 8)),
  ];

  /// The standard white card.
  static BoxDecoration cardDecoration({
    double radius = 24,
    Color color = card,
    Color borderColor = line,
    bool shadow = true,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor, width: 1.5),
      boxShadow: shadow ? softShadow : null,
    );
  }
}

/// Type scale — Nunito everywhere.
class AppText {
  static const display = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: AppColors.textDark,
    height: 1.15,
  );
  static const title = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w900,
    color: AppColors.textDark,
    height: 1.2,
  );
  static const cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: AppColors.textDark,
  );
  static const body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
    height: 1.45,
  );
  static const caption = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w700,
    color: AppColors.textMuted,
  );
  static const overline = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w900,
    color: AppColors.textMuted,
    letterSpacing: 1.1,
  );
}

class AppTheme {
  /// Parent-facing theme: clean, readable, calm.
  static ThemeData parent() {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'Nunito',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
      ),
      scaffoldBackgroundColor: AppColors.bg,
    );
    return base.copyWith(
      // Material Symbols are variable icons; fill=1 renders the filled style
      // everywhere (friendlier + more "designed" than outlines).
      iconTheme: const IconThemeData(fill: 1, weight: 600),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.textDark,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(58),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(29),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(58),
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: Color(0xFFDCD4F8), width: 1.5),
          textStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(29),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? Colors.white
              : const Color(0xFFB9B4CE),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primary
              : const Color(0xFFEAE7F5),
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.line, width: 1.5),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1),
    );
  }

  /// Kid-facing theme used inside the overlay isolate.
  static ThemeData kid() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Nunito',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.kidBottom,
        brightness: Brightness.light,
      ),
    );
  }
}
