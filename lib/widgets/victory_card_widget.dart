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
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: card.isAccomplished
                ? const Color(0xFF8FD4B0)
                : const Color(0xFFD0E8F5),
            width: card.isAccomplished ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: card.isAccomplished
                  ? const Color(0xFFB5E5CF).withValues(alpha: 0.2)
                  : const Color(0xFF89CFF0).withValues(alpha: 0.08),
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
              Text(
                card.emoji,
                style: TextStyle(
                  fontSize: card.isAccomplished ? 28 : 24,
                ),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  card.text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: card.isAccomplished
                        ? const Color(0xFF4A6B5A)
                        : const Color(0xFF5A7A8A),
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

