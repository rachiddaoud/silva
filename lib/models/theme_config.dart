import 'package:flutter/material.dart';

enum AppTheme {
  babyBlue,
  lavender,
  rosePowder,
  mint,
  peach,
  spring,
  summer,
  autumn,
  winter,
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
  final String? backgroundPath;

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
    this.backgroundPath,
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
      backgroundPath: null,
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
      backgroundPath: null,
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
      backgroundPath: null,
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
      backgroundPath: null,
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
      backgroundPath: null,
    ),
    AppTheme.spring: ThemeConfig(
      name: 'Printemps',
      primary: Color(0xFF90EE90),
      secondary: Color(0xFFFFB6D9),
      tertiary: Color(0xFFC8E6C9),
      surface: Color(0xFFF1F8F4),
      error: Color(0xFFFFB3BA),
      onPrimary: Colors.white,
      onSecondary: Color(0xFF6B4A5A),
      onTertiary: Color(0xFF4A6B4A),
      onSurface: Color(0xFF4A6B4A),
      scaffoldBackground: Color(0xFFF1F8F4),
      backgroundPath: 'assets/backgrounds/spring_bg.png',
    ),
    AppTheme.summer: ThemeConfig(
      name: 'Été',
      primary: Color(0xFF87CEEB),
      secondary: Color(0xFFFFD700),
      tertiary: Color(0xFFB0E0E6),
      surface: Color(0xFFF0F8FF),
      error: Color(0xFFFFB3BA),
      onPrimary: Colors.white,
      onSecondary: Color(0xFF6B5A2F),
      onTertiary: Color(0xFF4A6B7A),
      onSurface: Color(0xFF4A6B8A),
      scaffoldBackground: Color(0xFFF0F8FF),
      backgroundPath: 'assets/backgrounds/summer_bg.png',
    ),
    AppTheme.autumn: ThemeConfig(
      name: 'Automne',
      primary: Color(0xFFFF8C42),
      secondary: Color(0xFFD2691E),
      tertiary: Color(0xFFFFB347),
      surface: Color(0xFFFFF5E6),
      error: Color(0xFFFFB3BA),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onTertiary: Color(0xFF6B4A2F),
      onSurface: Color(0xFF6B4A2F),
      scaffoldBackground: Color(0xFFFFF5E6),
      backgroundPath: 'assets/backgrounds/autumn_bg.png',
    ),
    AppTheme.winter: ThemeConfig(
      name: 'Hiver',
      primary: Color(0xFFADD8E6),
      secondary: Color(0xFFE0F7FA),
      tertiary: Color(0xFFB0BEC5),
      surface: Color(0xFFF8FBFF),
      error: Color(0xFFFFB3BA),
      onPrimary: Color(0xFF1A4D6B),
      onSecondary: Color(0xFF4A6B7A),
      onTertiary: Color(0xFF5A6B7A),
      onSurface: Color(0xFF4A5A6B),
      scaffoldBackground: Color(0xFFF8FBFF),
      backgroundPath: 'assets/backgrounds/winter_bg.png',
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

