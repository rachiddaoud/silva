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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: card.isAccomplished
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.4),
                    colorScheme.primary.withValues(alpha: 0.6),
                  ],
                )
              : null,
          color: card.isAccomplished ? null : theme.cardTheme.color ?? Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: card.isAccomplished
                ? colorScheme.primary
                : colorScheme.onSurface.withValues(alpha: 0.2),
            width: card.isAccomplished ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: card.isAccomplished
                  ? colorScheme.primary.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: card.isAccomplished ? 6 : 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Display sprite from sprite sheet
              SpriteDisplay(
                victoryId: card.spriteId,
                size: card.isAccomplished ? 64 : 56,
                showBorder: false,
              ),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  card.text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: card.isAccomplished
                        ? colorScheme.onSurface // Darker text for better contrast
                        : colorScheme.onSurface.withValues(alpha: 0.8),
                    fontWeight: card.isAccomplished
                        ? FontWeight.w600
                        : FontWeight.w400,
                    height: 1.2,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

