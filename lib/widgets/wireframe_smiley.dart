import 'package:flutter/material.dart';

/// Widget pour afficher un doodle d'émotion dans un cercle avec bordure colorée
class WireframeSmiley extends StatelessWidget {
  final String emoji;
  final String imagePath;
  final bool isSelected;
  final Color moodColor;
  final VoidCallback onTap;

  const WireframeSmiley({
    super.key,
    required this.emoji,
    required this.imagePath,
    required this.isSelected,
    required this.moodColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isSelected ? 1.0 : 0.6,
        child: Image.asset(
          imagePath,
          width: 70,
          height: 70,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

