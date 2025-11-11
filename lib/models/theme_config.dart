import 'package:flutter/material.dart';

enum AppTheme {
  babyBlue,
  lavender,
  rosePowder,
  mint,
  peach,
}

class ThemeConfig {
  final String name;
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color surface;
  final Color error;
  final Color onPrimary;
  final Color onSecondary;
  final Color onTertiary;
  final Color onSurface;
  final Color scaffoldBackground;

  const ThemeConfig({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.surface,
    required this.error,
    required this.onPrimary,
    required this.onSecondary,
    required this.onTertiary,
    required this.onSurface,
    required this.scaffoldBackground,
  });

  static const Map<AppTheme, ThemeConfig> themes = {
    AppTheme.babyBlue: ThemeConfig(
      name: 'Baby Blue',
      primary: Color(0xFF89CFF0),
      secondary: Color(0xFFFFD4A3),
      tertiary: Color(0xFFB5E5CF),
      surface: Color(0xFFF0F9FF),
      error: Color(0xFFFFB3BA),
      onPrimary: Colors.white,
      onSecondary: Color(0xFF6B5B4F),
      onTertiary: Color(0xFF4A6B5A),
      onSurface: Color(0xFF5A7A8A),
      scaffoldBackground: Color(0xFFF0F9FF),
    ),
    AppTheme.lavender: ThemeConfig(
      name: 'Lavande',
      primary: Color(0xFFC8A2C8),
      secondary: Color(0xFFE6D3FF),
      tertiary: Color(0xFFD4B3FF),
      surface: Color(0xFFF5F0FF),
      error: Color(0xFFFFB3BA),
      onPrimary: Colors.white,
      onSecondary: Color(0xFF5A4A6B),
      onTertiary: Color(0xFF6B5A7A),
      onSurface: Color(0xFF6B5A8A),
      scaffoldBackground: Color(0xFFF5F0FF),
    ),
    AppTheme.rosePowder: ThemeConfig(
      name: 'Rose Poudré',
      primary: Color(0xFFFFB6C1),
      secondary: Color(0xFFFFD1DC),
      tertiary: Color(0xFFFFC0CB),
      surface: Color(0xFFFFF0F5),
      error: Color(0xFFFF6B6B),
      onPrimary: Colors.white,
      onSecondary: Color(0xFF8B6B6D),
      onTertiary: Color(0xFF9B7B7D),
      onSurface: Color(0xFF7A6B7A),
      scaffoldBackground: Color(0xFFFFF0F5),
    ),
    AppTheme.mint: ThemeConfig(
      name: 'Menthe',
      primary: Color(0xFFB5E5CF),
      secondary: Color(0xFFD4F4E6),
      tertiary: Color(0xFFA8D8C8),
      surface: Color(0xFFF0FFF5),
      error: Color(0xFFFFB3BA),
      onPrimary: Colors.white,
      onSecondary: Color(0xFF4A6B5A),
      onTertiary: Color(0xFF5A7B6A),
      onSurface: Color(0xFF5A7A6A),
      scaffoldBackground: Color(0xFFF0FFF5),
    ),
    AppTheme.peach: ThemeConfig(
      name: 'Pêche',
      primary: Color(0xFFFFD4A3),
      secondary: Color(0xFFFFE4C4),
      tertiary: Color(0xFFFFCC99),
      surface: Color(0xFFFFF8F0),
      error: Color(0xFFFFB3BA),
      onPrimary: Colors.white,
      onSecondary: Color(0xFF8B6B4F),
      onTertiary: Color(0xFF9B7B5F),
      onSurface: Color(0xFF7A6B5A),
      scaffoldBackground: Color(0xFFFFF8F0),
    ),
  };

  ThemeData toThemeData() {
    return ThemeData(
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: secondary,
        tertiary: tertiary,
        surface: surface,
        error: error,
        onPrimary: onPrimary,
        onSecondary: onSecondary,
        onTertiary: onTertiary,
        onSurface: onSurface,
      ),
      scaffoldBackgroundColor: scaffoldBackground,
      textTheme: const TextTheme(
        bodyLarge: TextStyle(
          fontSize: 18,
          color: Color(0xFF5A7A8A),
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          color: Color(0xFF5A7A8A),
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        titleLarge: TextStyle(
          fontSize: 24,
          color: Color(0xFF4A6B7A),
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
        titleMedium: TextStyle(
          fontSize: 20,
          color: Color(0xFF4A6B7A),
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
        color: Colors.white,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}

