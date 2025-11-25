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
  beach,
  night,
  eclipse,
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
      primary: Color(0xFF5CA0C5), // Darker Blue
      secondary: Color(0xFFDDA570), // Darker Orange
      tertiary: Color(0xFF85B59F), // Darker Green
      surface: Color(0xFFF0F9FF),
      error: Color(0xFFFFB3BA),
      onPrimary: Colors.white,
      onSecondary: Colors.white, // Changed to white for better contrast on darker secondary
      onTertiary: Colors.white, // Changed to white
      onSurface: Color(0xFF2A4A5A), // Darker text
      scaffoldBackground: Color(0xFFF0F9FF),
      backgroundPath: null,
    ),
    AppTheme.lavender: ThemeConfig(
      name: 'Lavande',
      primary: Color(0xFF987298), // Darker Purple
      secondary: Color(0xFFB6A3DF), // Darker Secondary
      tertiary: Color(0xFFA483CF), // Darker Tertiary
      surface: Color(0xFFF5F0FF),
      error: Color(0xFFFFB3BA),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onTertiary: Colors.white,
      onSurface: Color(0xFF3B2A5A), // Darker text
      scaffoldBackground: Color(0xFFF5F0FF),
      backgroundPath: null,
    ),
    AppTheme.rosePowder: ThemeConfig(
      name: 'Rose Poudré',
      primary: Color(0xFFCF8691), // Darker Pink
      secondary: Color(0xFFCFA1AC), // Darker Secondary
      tertiary: Color(0xFFCF909B), // Darker Tertiary
      surface: Color(0xFFFFF0F5),
      error: Color(0xFFFF6B6B),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onTertiary: Colors.white,
      onSurface: Color(0xFF4A3B4A), // Darker text
      scaffoldBackground: Color(0xFFFFF0F5),
      backgroundPath: null,
    ),
    AppTheme.mint: ThemeConfig(
      name: 'Menthe',
      primary: Color(0xFF6BA88F), // Darker Mint
      secondary: Color(0xFFA4C4B6), // Darker Secondary
      tertiary: Color(0xFF78A898), // Darker Tertiary
      surface: Color(0xFFF0FFF5),
      error: Color(0xFFFFB3BA),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onTertiary: Colors.white,
      onSurface: Color(0xFF2A4A3A), // Darker text
      scaffoldBackground: Color(0xFFF0FFF5),
      backgroundPath: null,
    ),
    AppTheme.peach: ThemeConfig(
      name: 'Pêche',
      primary: Color(0xFFDDA570), // Darker Peach
      secondary: Color(0xFFCFB494), // Darker Secondary
      tertiary: Color(0xFFCF9C69), // Darker Tertiary
      surface: Color(0xFFFFF8F0),
      error: Color(0xFFFFB3BA),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onTertiary: Colors.white,
      onSurface: Color(0xFF4A3B2A), // Darker text
      scaffoldBackground: Color(0xFFFFF8F0),
      backgroundPath: null,
    ),
    AppTheme.spring: ThemeConfig(
      name: 'Printemps',
      primary: Color(0xFF60BE60), // Darker Green
      secondary: Color(0xFFCF86A9), // Darker Pink
      tertiary: Color(0xFF98B699), // Darker Tertiary
      surface: Color(0xFFF1F8F4),
      error: Color(0xFFFFB3BA),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onTertiary: Colors.white,
      onSurface: Color(0xFF1A3B1A), // Darker text
      scaffoldBackground: Color(0xFFF1F8F4),
      backgroundPath: 'assets/backgrounds/spring_bg.png',
    ),
    AppTheme.summer: ThemeConfig(
      name: 'Été',
      primary: Color(0xFF579EBB), // Darker Sky Blue
      secondary: Color(0xFFCFA700), // Darker Gold
      tertiary: Color(0xFF80B0B6), // Darker Tertiary
      surface: Color(0xFFF0F8FF),
      error: Color(0xFFFFB3BA),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onTertiary: Colors.white,
      onSurface: Color(0xFF1A3B5A), // Darker text
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
      primary: Color(0xFF7DA8B6), // Darker Blue
      secondary: Color(0xFFB0C7CA), // Darker Cyan
      tertiary: Color(0xFF808E95), // Darker Blue Grey
      surface: Color(0xFFF8FBFF),
      error: Color(0xFFFFB3BA),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onTertiary: Colors.white,
      onSurface: Color(0xFF1A2A3B), // Darker text
      scaffoldBackground: Color(0xFFF8FBFF),
      backgroundPath: 'assets/backgrounds/winter_bg.png',
    ),
    AppTheme.beach: ThemeConfig(
      name: 'Plage',
      primary: Color(0xFF00A8CC), // Turquoise
      secondary: Color(0xFFE8C547), // Sandy yellow
      tertiary: Color(0xFF0077B6), // Deep ocean blue
      surface: Color(0xFFFFFBF5),
      error: Color(0xFFFF6B6B),
      onPrimary: Colors.white,
      onSecondary: Color(0xFF2C3E50), // Dark text on sandy color
      onTertiary: Colors.white,
      onSurface: Color(0xFF2C3E50), // Dark text
      scaffoldBackground: Color(0xFFFFFBF5), // Light sandy background
      backgroundPath: 'assets/backgrounds/beach_bg.png',
    ),
    AppTheme.night: ThemeConfig(
      name: 'Nuit',
      primary: Color(0xFF6B9AC4), // Soft blue for primary elements
      secondary: Color(0xFF9B86BD), // Soft purple for secondary elements
      tertiary: Color(0xFF4A90A4), // Teal accent
      surface: Color(0xFF1E1E2E), // Dark surface
      error: Color(0xFFFF6B6B), // Soft red for errors
      onPrimary: Color(0xFF0D1117), // Dark text on primary
      onSecondary: Color(0xFF0D1117), // Dark text on secondary
      onTertiary: Colors.white, // Light text on tertiary
      onSurface: Color(0xFFE0E0E0), // Light text on dark surface
      scaffoldBackground: Color(0xFF0D1117), // Deep dark background (GitHub dark)
      backgroundPath: 'assets/backgrounds/night_bg.png',
    ),
    AppTheme.eclipse: ThemeConfig(
      name: 'Éclipse',
      primary: Color(0xFFD4AF37), // Golden for primary elements
      secondary: Color(0xFF9B59B6), // Deep purple for secondary elements
      tertiary: Color(0xFFE67E22), // Orange accent
      surface: Color(0xFF1A1A2E), // Dark surface
      error: Color(0xFFFF6B6B), // Soft red for errors
      onPrimary: Color(0xFF0A0A0F), // Dark text on primary
      onSecondary: Colors.white, // Light text on secondary
      onTertiary: Colors.white, // Light text on tertiary
      onSurface: Color(0xFFE0E0E0), // Light text on dark surface
      scaffoldBackground: Color(0xFF0A0A0F), // Very dark background
      backgroundPath: 'assets/backgrounds/eclipse_bg.png',
    ),
  };

  ThemeData toThemeData() {
    // Determine if this is a dark theme based on scaffold background luminance
    final isDark = scaffoldBackground.computeLuminance() < 0.5;
    
    return ThemeData(
      colorScheme: isDark
          ? ColorScheme.dark(
              primary: primary,
              secondary: secondary,
              tertiary: tertiary,
              surface: surface,
              error: error,
              onPrimary: onPrimary,
              onSecondary: onSecondary,
              onTertiary: onTertiary,
              onSurface: onSurface,
            )
          : ColorScheme.light(
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
      textTheme: TextTheme(
        bodyLarge: TextStyle(
          fontSize: 18,
          color: onSurface,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          color: onSurface,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        titleLarge: TextStyle(
          fontSize: 24,
          color: onSurface,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
        titleMedium: TextStyle(
          fontSize: 20,
          color: onSurface,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
        color: isDark ? surface : Colors.white,
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

