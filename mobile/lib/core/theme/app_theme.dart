import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  const background = Color(0xFFF6FBFF);
  const primary = Color(0xFF5DADE2);
  const primarySoft = Color(0xFFDFF2FF);

  final baseTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: background,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFF184A73),
      elevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFCAE6FA)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFCAE6FA)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primary, width: 1.4),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shadowColor: primary.withValues(alpha: 0.10),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
  );

  return baseTheme.copyWith(
    textTheme: baseTheme.textTheme.apply(
      bodyColor: const Color(0xFF184A73),
      displayColor: const Color(0xFF184A73),
    ),
    chipTheme: baseTheme.chipTheme.copyWith(
      backgroundColor: primarySoft,
      selectedColor: primary,
      side: BorderSide.none,
      labelStyle: const TextStyle(color: Color(0xFF184A73)),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
    ),
  );
}
