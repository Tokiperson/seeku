import 'package:flutter/material.dart';

class SeekUColors {
  const SeekUColors._();

  static const cquBlue = Color(0xFF005BAC);
  static const cquBlueDark = Color(0xFF003F7D);
  static const sky = Color(0xFFE8F2FF);
  static const scheduleSurface = Color(0xFFEAF4FF);
  static const surface = Color(0xFFF6F8FC);
  static const border = Color(0xFFE2EAF5);
  static const text = Color(0xFF172033);
  static const muted = Color(0xFF64748B);
  static const success = Color(0xFF1E9E75);
  static const warning = Color(0xFFE2A100);
  static const warningText = Color(0xFF8A5A00);
  static const warningSoft = Color(0xFFFFF8E5);
  static const warningBorder = Color(0xFFFFD978);
  static const danger = Color(0xFFD64545);
  static const nowLine = Color(0xFFFFA8B8);
}

ThemeData buildSeekUTheme({
  Color primaryColor = SeekUColors.cquBlue,
  double fontScale = 1,
}) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: primaryColor,
    primary: primaryColor,
    secondary: SeekUColors.success,
    surface: Colors.white,
  );
  final baseTextTheme = Typography.material2021().black.apply(
    bodyColor: SeekUColors.text,
    displayColor: SeekUColors.text,
    fontFamily: 'Microsoft YaHei UI',
  );
  final textTheme = baseTextTheme.apply(fontSizeFactor: fontScale);

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: SeekUColors.surface,
    fontFamily: 'Microsoft YaHei UI',
    visualDensity: VisualDensity.standard,
    textTheme: textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: SeekUColors.text,
      surfaceTintColor: Colors.white,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.white,
      selectedIconTheme: IconThemeData(color: primaryColor),
      selectedLabelTextStyle: TextStyle(
        color: primaryColor,
        fontWeight: FontWeight.w700,
      ),
      unselectedIconTheme: const IconThemeData(color: SeekUColors.muted),
      unselectedLabelTextStyle: const TextStyle(color: SeekUColors.muted),
      indicatorColor: SeekUColors.sky,
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: SeekUColors.sky,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? primaryColor
              : SeekUColors.muted,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w600,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 1,
      shadowColor: const Color(0x1A0F2A4A),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: SeekUColors.border),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: SeekUColors.border,
      thickness: 1,
      space: 1,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14 * fontScale,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: SeekUColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14 * fontScale,
        ),
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
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primaryColor, width: 1.4),
      ),
    ),
  );
}
