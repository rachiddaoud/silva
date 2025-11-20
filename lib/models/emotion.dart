import 'package:flutter/material.dart';

class Emotion {
  final String name;
  final String emoji;
  final String description;
  final int moodScore; // 0 = très négatif (rouge), 5 = très positif (vert)
  final String imagePath; // Chemin vers l'image doodle

  const Emotion({
    required this.name,
    required this.emoji,
    required this.description,
    required this.moodScore,
    required this.imagePath,
  });

  // Retourne la couleur selon le score d'humeur (rouge à vert)
  Color get moodColor {
    switch (moodScore) {
      case 0: // Très négatif - Rouge
        return const Color(0xFFFF6B6B);
      case 1: // Négatif - Rouge-orange
        return const Color(0xFFFF8E53);
      case 2: // Légèrement négatif - Orange
        return const Color(0xFFFFB347);
      case 3: // Neutre - Jaune
        return const Color(0xFFFFD93D);
      case 4: // Positif - Vert clair
        return const Color(0xFF6BCF7F);
      case 5: // Très positif - Vert
        return const Color(0xFF4ECDC4);
      default:
        return const Color(0xFFFFD93D);
    }
  }

  static const List<Emotion> emotions = [
    Emotion(
      name: "Épuisée",
      emoji: "😴",
      description: "Épuisée",
      moodScore: 0, // Rouge
      imagePath: "assets/doodles/crying.png",
    ),
    Emotion(
      name: "Triste / Débordée",
      emoji: "😔",
      description: "Triste / Débordée",
      moodScore: 1, // Rouge-orange
      imagePath: "assets/doodles/sad.png",
    ),
    Emotion(
      name: "Anxieuse",
      emoji: "😰",
      description: "Anxieuse",
      moodScore: 1, // Rouge-orange
      imagePath: "assets/doodles/crying.png",
    ),
    Emotion(
      name: "Bof / Neutre",
      emoji: "😐",
      description: "Bof / Neutre",
      moodScore: 3, // Jaune
      imagePath: "assets/doodles/neutral.png",
    ),
    Emotion(
      name: "OK / Calme",
      emoji: "😌",
      description: "OK / Calme",
      moodScore: 4, // Vert clair
      imagePath: "assets/doodles/smiling.png",
    ),
    Emotion(
      name: "Fière / Joyeuse",
      emoji: "😊",
      description: "Fière / Joyeuse",
      moodScore: 5, // Vert
      imagePath: "assets/doodles/happy.png",
    ),
  ];
}

