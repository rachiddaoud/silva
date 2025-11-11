import 'package:flutter/material.dart';
import '../models/victory_card.dart';

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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: card.isAccomplished
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFB5E5CF),
                    Color(0xFFA8D8C8),
                  ],
                )
              : null,
          color: card.isAccomplished ? null : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: card.isAccomplished
                ? const Color(0xFF8FD4B0)
                : const Color(0xFFD0E8F5),
            width: card.isAccomplished ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: card.isAccomplished
                  ? const Color(0xFFB5E5CF).withValues(alpha: 0.3)
                  : const Color(0xFF89CFF0).withValues(alpha: 0.1),
              blurRadius: card.isAccomplished ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  if (card.isAccomplished)
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                  Text(
                    card.emoji,
                    style: TextStyle(
                      fontSize: card.isAccomplished ? 36 : 32,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  card.text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: card.isAccomplished
                        ? const Color(0xFF4A6B5A)
                        : const Color(0xFF5A7A8A),
                    fontWeight: card.isAccomplished
                        ? FontWeight.w600
                        : FontWeight.w400,
                    height: 1.3,
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

