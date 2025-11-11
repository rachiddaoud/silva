import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mes Petits Pas',
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF89CFF0), // Baby blue joyeux
          secondary: const Color(0xFFFFD4A3), // Pêche doux et chaleureux
          tertiary: const Color(0xFFB5E5CF), // Vert menthe doux
          surface: const Color(0xFFF0F9FF), // Bleu ciel très clair
          error: const Color(0xFFFFB3BA), // Rose corail doux
          onPrimary: Colors.white,
          onSecondary: const Color(0xFF6B5B4F), // Beige foncé doux
          onTertiary: const Color(0xFF4A6B5A), // Vert foncé doux
          onSurface: const Color(0xFF5A7A8A), // Bleu-gris doux
        ),
        scaffoldBackgroundColor: const Color(0xFFF0F9FF),
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
          backgroundColor: const Color(0xFF89CFF0),
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
