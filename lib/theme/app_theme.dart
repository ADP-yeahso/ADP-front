import 'package:flutter/material.dart';

class AppColors {
  // Image 2 Palette (Named Roles)
  static const Color primary = Color(0xFF98CC6B); // Soft Leaf Green
  static const Color secondary = Color(0xFF24361B); // Deep Forest Green
  static const Color accent = Color(0xFFED7A3B); // Warm Tangerine
  static const Color background = Color(0xFFEEF2EC); // Pale Sage Mist

  // Image 1 Palette (Variants)
  static const Color green1 = Color(0xFF317E39);
  static const Color green2 = Color(0xFF144419);
  static const Color green3 = Color(0xFF6D8272);
  static const Color green4 = Color(0xFFA7E664);
  static const Color orange1 = Color(0xFFF7931A);
  static const Color lightGrayGreen = Color(0xFFECF0E7);
}

class AppTheme {
  static const seed = AppColors.primary;

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        fontFamily: 'Pretendard',
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        scaffoldBackgroundColor: const Color(0xFFFBF9F3),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Color(0xFF3A3A3A),
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: seed,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF3F1E9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
      );
}

enum Season { spring, summer, autumn, winter }

Season seasonOf(DateTime date) {
  final m = date.month;
  if (m >= 3 && m <= 5) return Season.spring;
  if (m >= 6 && m <= 8) return Season.summer;
  if (m >= 9 && m <= 11) return Season.autumn;
  return Season.winter;
}

extension SeasonStyle on Season {
  String get label => switch (this) {
        Season.spring => '봄',
        Season.summer => '여름',
        Season.autumn => '가을',
        Season.winter => '겨울',
      };

  List<Color> get skyGradient => switch (this) {
        Season.spring => const [Color(0xFFFDEBF0), Color(0xFFEFF6E4)],
        Season.summer => const [Color(0xFFE3F3EA), Color(0xFFDDF0F4)],
        Season.autumn => const [Color(0xFFFCEEDD), Color(0xFFF8E4D0)],
        Season.winter => const [Color(0xFFE9F1F7), Color(0xFFF5F6F8)],
      };

  Color get ground => switch (this) {
        Season.spring => const Color(0xFFCFE3B8),
        Season.summer => const Color(0xFFA9D19C),
        Season.autumn => const Color(0xFFE0BF8C),
        Season.winter => const Color(0xFFDCE6E9),
      };

}
