import 'package:flutter/material.dart';
import '../models/emotion.dart';
import '../models/victory_card.dart';
import '../models/day_entry.dart';
import '../services/preferences_service.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  List<DayEntry> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    final history = await PreferencesService.getHistory();
    
    // Trier par date décroissante (plus récent en premier)
    history.sort((a, b) => b.date.compareTo(a.date));

    if (mounted) {
      setState(() {
        _history = history;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Chargement de l\'historique...',
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    if (_history.isEmpty) {
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

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        itemCount: _history.length,
        itemBuilder: (context, index) {
          final entry = _history[index];
          final isLast = index == _history.length - 1;

          return _TimelineEntry(
            date: entry.date,
            emotion: entry.emotion,
            comment: entry.comment,
            victoryCards: entry.victoryCards,
            isLast: isLast,
          );
        },
      ),
    );
  }
}

// Widget pour une entrée de la timeline
class _TimelineEntry extends StatelessWidget {
  final DateTime date;
  final Emotion emotion;
  final String? comment;
  final List<VictoryCard> victoryCards;
  final bool isLast;

  const _TimelineEntry({
    required this.date,
    required this.emotion,
    required this.comment,
    required this.victoryCards,
    required this.isLast,
  });

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
      final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
      return "${weekdays[date.weekday - 1]} ${date.day} ${months[date.month - 1]}";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline node (cercle + ligne)
          _TimelineNode(
            color: emotion.moodColor,
            emoji: emotion.emoji,
            isLast: isLast,
          ),
          const SizedBox(width: 16),
          // Contenu
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date et émotion
                  Text(
                    _formatDate(date),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        emotion.moodColor == const Color(0xFFFF6B6B) || 
                        emotion.moodColor == const Color(0xFFFF8E53) ||
                        emotion.moodColor == const Color(0xFFFFB347)
                            ? Icons.mood_bad_rounded
                            : emotion.moodColor == const Color(0xFFFFD93D)
                                ? Icons.sentiment_neutral_rounded
                                : Icons.mood_rounded,
                        size: 16,
                        color: emotion.moodColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        emotion.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  // Commentaire si présent
                  if (comment?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: emotion.moodColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: emotion.moodColor.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        comment!,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                  // Tags des victoires
                  if (victoryCards.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: victoryCards.map((victory) {
                        return _VictoryTag(
                          emoji: victory.emoji,
                          text: victory.text,
                          color: emotion.moodColor,
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget pour le nœud de timeline
class _TimelineNode extends StatelessWidget {
  final Color color;
  final String emoji;
  final bool isLast;

  const _TimelineNode({
    required this.color,
    required this.emoji,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: Column(
        children: [
          // Cercle avec emoji
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: color,
                width: 2.5,
              ),
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          // Ligne verticale
          if (!isLast)
            Expanded(
              child: Container(
                width: 2,
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      color.withValues(alpha: 0.4),
                      color.withValues(alpha: 0.1),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Widget pour un tag de victoire
class _VictoryTag extends StatelessWidget {
  final String emoji;
  final String text;
  final Color color;

  const _VictoryTag({
    required this.emoji,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

