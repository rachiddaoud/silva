import 'package:flutter/material.dart';
import '../models/victory_card.dart';
import '../utils/sprite_utils.dart';

class VictoryCardWidget extends StatelessWidget {
  final VictoryCard card;
  final VoidCallback onTap;

  const VictoryCardWidget({
    super.key,
    required this.card,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = card.isAccomplished;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.4)
              : theme.cardTheme.color ?? Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.08),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? colorScheme.primary.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Sprite
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                decoration: isSelected
                    ? BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.2),
                            blurRadius: 12,
                            spreadRadius: -2,
                          )
                        ],
                      )
                    : null,
                child: SpriteDisplay(
                  victoryId: card.spriteId,
                  size: 48,
                  showBorder: false,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                card.text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected
                      ? colorScheme.onSurface
                      : colorScheme.onSurface.withValues(alpha: 0.75),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  height: 1.2,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Optional Checkmark for extra clarity
            if (isSelected) ...[
              const SizedBox(height: 4),
              Icon(
                Icons.check_circle,
                size: 14,
                color: colorScheme.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
