import 'package:flutter/material.dart';
import '../models/emotion.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  // Données mock pour l'historique
  static List<Map<String, dynamic>> getMockHistory() {
    final now = DateTime.now();
    return [
      {
        'date': now.subtract(const Duration(days: 1)),
        'emotion': Emotion.emotions[5], // Fière / Joyeuse
        'victories': 7,
      },
      {
        'date': now.subtract(const Duration(days: 2)),
        'emotion': Emotion.emotions[4], // OK / Calme
        'victories': 5,
      },
      {
        'date': now.subtract(const Duration(days: 3)),
        'emotion': Emotion.emotions[3], // Bof / Neutre
        'victories': 4,
      },
      {
        'date': now.subtract(const Duration(days: 4)),
        'emotion': Emotion.emotions[2], // Anxieuse
        'victories': 3,
      },
      {
        'date': now.subtract(const Duration(days: 5)),
        'emotion': Emotion.emotions[4], // OK / Calme
        'victories': 6,
      },
    ];
  }

  String _formatDate(DateTime date) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    
    if (date.year == today.year &&
        date.month == today.month &&
        date.day == today.day) {
      return "Aujourd'hui";
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return "Hier";
    } else {
      final weekdays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      return "${weekdays[date.weekday - 1]} ${date.day}/${date.month}";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final history = getMockHistory();

    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun historique pour le moment',
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final entry = history[index];
        final date = entry['date'] as DateTime;
        final emotion = entry['emotion'] as Emotion;
        final victories = entry['victories'] as int;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                emotion.moodColor.withValues(alpha: 0.2),
                emotion.moodColor.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: emotion.moodColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: emotion.moodColor.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Emoji de l'émotion
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: emotion.moodColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: emotion.moodColor,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    emotion.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Informations
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(date),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      emotion.name,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              // Nombre de victoires
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: emotion.moodColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: emotion.moodColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$victories',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: emotion.moodColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

