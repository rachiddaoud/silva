import 'package:flutter/material.dart';

class WireframeSmiley extends StatelessWidget {
  final String emoji;
  final bool isSelected;
  final Color moodColor;
  final VoidCallback onTap;

  const WireframeSmiley({
    super.key,
    required this.emoji,
    required this.isSelected,
    required this.moodColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isSelected
              ? moodColor.withValues(alpha: 0.15)
              : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? moodColor : moodColor.withValues(alpha: 0.4),
            width: isSelected ? 2.5 : 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: moodColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            emoji,
            style: TextStyle(
              fontSize: isSelected ? 32 : 28,
            ),
          ),
        ),
      ),
    );
  }
}

