import 'package:flutter/material.dart';
import '../models/emotion.dart';
import '../models/victory_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/day_entry.dart';
import '../services/preferences_service.dart';
import '../services/database_service.dart';
import '../utils/sprite_utils.dart';

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

    // Initialiser les données mock si l'historique est vide
    // await PreferencesService.initializeMockData();

    // final history = await PreferencesService.getHistory();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _history = [];
          _isLoading = false;
        });
      }
      return;
    }

    final history = await DatabaseService().getHistory(user.uid);
    
    // Générer une liste des 7 derniers jours (excluant aujourd'hui)
    final now = DateTime.now();
    final List<DayEntry> completeHistory = [];
    
    for (int i = 1; i <= 7; i++) {
      final date = now.subtract(Duration(days: i));
      // Normaliser la date à minuit pour la comparaison
      final normalizedDate = DateTime(date.year, date.month, date.day);
      
      // Chercher si une entrée existe pour cette date
      final existingEntry = history.firstWhere(
        (e) {
          final eNormalized = DateTime(e.date.year, e.date.month, e.date.day);
          return eNormalized == normalizedDate;
        },
        orElse: () => DayEntry(
          date: normalizedDate,
          emotion: null, // Jour vide
          comment: null,
          victoryCards: [],
        ),
      );
      
      completeHistory.add(existingEntry);
    }
    
    // Trier par date décroissante (plus récent en premier)
    completeHistory.sort((a, b) => b.date.compareTo(a.date));

    if (mounted) {
      setState(() {
        _history = completeHistory;
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
  final Emotion? emotion; // Nullable pour les jours non remplis
  final String? comment;
  final List<VictoryCard> victoryCards;
  final bool isLast;

  const _TimelineEntry({
    required this.date,
    this.emotion,
    this.comment,
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
            color: emotion != null 
                ? emotion!.moodColor 
                : theme.colorScheme.onSurface.withValues(alpha: 0.2),
            emotion: emotion,
            isLast: isLast,
            isEmpty: emotion == null,
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
                  // Afficher l'émotion si présente, sinon "Jour non rempli"
                  if (emotion != null) ...[
                    Builder(
                      builder: (context) {
                        final e = emotion!; // Non-null dans ce bloc
                        return Row(
                          children: [
                            Icon(
                              e.moodColor == const Color(0xFFFF6B6B) || 
                              e.moodColor == const Color(0xFFFF8E53) ||
                              e.moodColor == const Color(0xFFFFB347)
                                  ? Icons.mood_bad_rounded
                                  : e.moodColor == const Color(0xFFFFD93D)
                                      ? Icons.sentiment_neutral_rounded
                                      : Icons.mood_rounded,
                              size: 16,
                              color: e.moodColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              e.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ] else
                    Row(
                      children: [
                        Icon(
                          Icons.circle_outlined,
                          size: 16,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Jour non rempli',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  // Commentaire si présent (seulement si jour rempli)
                  if (emotion != null && (comment?.isNotEmpty ?? false)) ...[
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        final e = emotion!;
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: e.moodColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: e.moodColor.withValues(alpha: 0.2),
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
                        );
                      },
                    ),
                  ],
                  // Tags des victoires (seulement si jour rempli)
                  if (emotion != null && victoryCards.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Builder(
                      builder: (context) {
                        final e = emotion!;
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: victoryCards.map((victory) {
                            return _VictoryTag(
                              victory: victory,
                              color: e.moodColor,
                            );
                          }).toList(),
                        );
                      },
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
  final Emotion? emotion;
  final bool isLast;
  final bool isEmpty;

  const _TimelineNode({
    required this.color,
    this.emotion,
    required this.isLast,
    this.isEmpty = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: Column(
        children: [
          // Cercle avec doodle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isEmpty 
                  ? Colors.transparent 
                  : color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: color,
                width: isEmpty ? 1.5 : 2.5,
                style: isEmpty ? BorderStyle.solid : BorderStyle.solid,
              ),
            ),
            child: Center(
              child: isEmpty
                  ? Text(
                      '○',
                      style: TextStyle(
                        fontSize: 16,
                        color: color,
                      ),
                    )
                  : emotion != null
                      ? Image.asset(
                          emotion!.imagePath,
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                        )
                      : const SizedBox.shrink(),
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
  final VictoryCard victory;
  final Color color;

  const _VictoryTag({
    required this.victory,
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
          SpriteDisplay(
            victoryId: victory.spriteId,
            size: 20,
            showBorder: false,
          ),
          const SizedBox(width: 4),
          Text(
            victory.text,
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

