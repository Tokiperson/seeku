import 'package:flutter/material.dart';

class SeekUColors {
  const SeekUColors._();

  static const cquBlue = Color(0xFF005BAC);
  static const cquBlueDark = Color(0xFF003F7D);
  static const sky = Color(0xFFE8F2FF);
  static const surface = Color(0xFFF7FAFE);
  static const border = Color(0xFFD7E3F4);
  static const text = Color(0xFF172033);
  static const muted = Color(0xFF64748B);
  static const success = Color(0xFF1E9E75);
  static const warning = Color(0xFFE2A100);
}

ThemeData buildSeekUTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: SeekUColors.cquBlue,
    primary: SeekUColors.cquBlue,
    secondary: SeekUColors.success,
    surface: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: SeekUColors.surface,
    fontFamily: 'Microsoft YaHei',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: SeekUColors.text,
      surfaceTintColor: Colors.white,
      centerTitle: false,
      elevation: 0,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.white,
      selectedIconTheme: const IconThemeData(color: SeekUColors.cquBlue),
      selectedLabelTextStyle: const TextStyle(
        color: SeekUColors.cquBlue,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelTextStyle: const TextStyle(color: SeekUColors.muted),
      indicatorColor: SeekUColors.sky,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: SeekUColors.border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: SeekUColors.border),
      ),
    ),
  );
}
