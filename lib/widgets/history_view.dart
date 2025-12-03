import 'package:flutter/material.dart';
import '../models/emotion.dart';
import '../models/victory_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/day_entry.dart';
import '../services/database_service.dart';
import '../utils/sprite_utils.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../utils/localization_utils.dart';
import '../services/tree_service.dart';
import '../services/preferences_service.dart';
import '../screens/charts_screen.dart';

class HistoryView extends StatefulWidget {
  final VoidCallback? onHistoryChanged;

  const HistoryView({super.key, this.onHistoryChanged});

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
    
    // Trier par date décroissante (plus récent en premier)
    history.sort((a, b) => b.date.compareTo(a.date));

    if (mounted) {
      setState(() {
        _history = history;
        _isLoading = false;
      });
    }

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
              'Chargement de l\'historique...', // TODO: Localize this too if needed, but keeping simple for now
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
              'Aucun historique pour le moment', // TODO: Localize
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    // Separate today's entries from past entries
    final now = DateTime.now();
    final todayEntries = _history.where((entry) {
      return entry.date.year == now.year &&
             entry.date.month == now.month &&
             entry.date.day == now.day;
    }).toList();
    
    final pastEntries = _history.where((entry) {
      return !(entry.date.year == now.year &&
               entry.date.month == now.month &&
               entry.date.day == now.day);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          itemCount: (todayEntries.isNotEmpty ? 1 : 0) + // Today header
                     todayEntries.length +
                     (pastEntries.isNotEmpty && todayEntries.isNotEmpty ? 1 : 0) + // History header
                     pastEntries.length,
          itemBuilder: (context, index) {
            int adjustedIndex = index;
            
            // Today section header
            if (todayEntries.isNotEmpty && adjustedIndex == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16, top: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.today_rounded,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.today,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              );
            }
            if (todayEntries.isNotEmpty) {
              adjustedIndex--;
            }
            
            // Today entries
            if (todayEntries.isNotEmpty && adjustedIndex >= 0 && adjustedIndex < todayEntries.length) {
              final entry = todayEntries[adjustedIndex];
              return _TimelineEntry(
                date: entry.date,
                emotion: entry.emotion,
                comment: entry.comment,
                victoryCards: entry.victoryCards,
                isLast: false, // Not last in today section
                onDeleteVictory: (victoryId) => _deleteVictory(entry.date, victoryId),
              );
            }
            if (todayEntries.isNotEmpty) {
              adjustedIndex -= todayEntries.length;
            }
            
            // History section header
            if (pastEntries.isNotEmpty && todayEntries.isNotEmpty && adjustedIndex == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16, top: 24),
                child: Row(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 20,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.history,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              );
            }
            if (pastEntries.isNotEmpty && todayEntries.isNotEmpty) {
              adjustedIndex--;
            }
            
            // Past entries
            if (adjustedIndex >= 0 && adjustedIndex < pastEntries.length) {
              final entry = pastEntries[adjustedIndex];
              final isLast = adjustedIndex == pastEntries.length - 1;

              return _TimelineEntry(
                date: entry.date,
                emotion: entry.emotion,
                comment: entry.comment,
                victoryCards: entry.victoryCards,
                isLast: isLast,
                onDeleteVictory: (victoryId) => _deleteVictory(entry.date, victoryId),
              );
            }
            
            // Fallback - should never reach here
            return const SizedBox.shrink();
          },
        ),
      ),
      floatingActionButton: null,
    );
  }

  Future<void> _deleteVictory(DateTime date, int victoryId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Check if the deleted victory is from today
      final now = DateTime.now();
      final isToday = date.year == now.year &&
                      date.month == now.month &&
                      date.day == now.day;
      
      // Optimistically update the UI first (remove from local state)
      setState(() {
        final entryIndex = _history.indexWhere((e) =>
          e.date.year == date.year &&
          e.date.month == date.month &&
          e.date.day == date.day
        );
        
        if (entryIndex >= 0) {
          final entry = _history[entryIndex];
          final updatedVictories = entry.victoryCards.where((v) => v.id != victoryId).toList();
          
          if (updatedVictories.isEmpty) {
            // Remove entire entry if no victories left
            _history.removeAt(entryIndex);
          } else {
            // Update entry with remaining victories
            _history[entryIndex] = DayEntry(
              date: entry.date,
              emotion: entry.emotion,
              comment: entry.comment,
              victoryCards: updatedVictories,
            );
          }
        }
      });
      
      // Then perform the actual deletion and other operations
      await DatabaseService().deleteVictoryFromEntry(user.uid, date, victoryId);
      
      // If the victory is from today, uncheck it in today's victories
      if (isToday) {
        final todayVictories = await PreferencesService.getTodayVictories();
        final updatedVictories = todayVictories.map((v) {
          if (v.id == victoryId) {
            return v.copyWith(
              isAccomplished: false,
              timestamp: null,
            );
          }
          return v;
        }).toList();
        
        // Save updated victories locally
        await PreferencesService.saveTodayVictories(updatedVictories);
        
        // Sync with Firestore
        await DatabaseService().updateTodayVictories(user.uid, updatedVictories);
      }
      
      // Also remove a leaf from the tree if it exists
      // We need to load the tree, remove a leaf, and save it back
      final treeState = await PreferencesService.getTreeState();
      if (treeState != null) {
        // Create a temporary controller to handle logic
        final tempController = TreeController();
        tempController.setTree(treeState);
        
        // Remove a leaf
        if (tempController.removeLeaf(notify: false)) {
          // Save updated tree
          await PreferencesService.saveTreeState(tempController.tree!);
          
          // Also update leaf count in resources
          final resources = await PreferencesService.getTreeResources();
          if (resources.leafCount > 0) {
             await PreferencesService.saveTreeResources(
               resources.copyWith(leafCount: resources.leafCount - 1)
             );
          }
          
          // Sync to Firebase
          DatabaseService().saveTreeState(user.uid, tempController.tree!).catchError((e) {
            debugPrint('Error syncing tree after leaf removal: $e');
          });
        }
      }

      // Silently reload history in the background to ensure sync (without showing loading)
      _reloadHistorySilently();
      
      // Notify parent that history changed (so home screen can refresh)
      if (widget.onHistoryChanged != null) {
        widget.onHistoryChanged!();
      }
    }
  }

  /// Reload history without showing loading indicator
  Future<void> _reloadHistorySilently() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final history = await DatabaseService().getHistory(user.uid);
    
    // Trier par date décroissante (plus récent en premier)
    history.sort((a, b) => b.date.compareTo(a.date));

    if (mounted) {
      setState(() {
        _history = history;
      });
    }
  }
}

// Widget pour une entrée de la timeline
class _TimelineEntry extends StatelessWidget {
  final DateTime date;
  final Emotion? emotion; // Nullable pour les jours non remplis
  final String? comment;
  final List<VictoryCard> victoryCards;
  final bool isLast;
  final Function(int victoryId) onDeleteVictory;

  const _TimelineEntry({
    required this.date,
    this.emotion,
    this.comment,
    required this.victoryCards,
    required this.isLast,
    required this.onDeleteVictory,
  });

  String _formatDate(BuildContext context, DateTime date) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final l10n = AppLocalizations.of(context)!;
    
    if (date.year == today.year &&
        date.month == today.month &&
        date.day == today.day) {
      return l10n.today;
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return l10n.yesterday;
    } else {
      final locale = Localizations.localeOf(context).toString();
      return DateFormat.yMMMd(locale).format(date);
    }
  }

  bool _isToday() {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canDelete = _isToday();

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
                    _formatDate(context, date),
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
                            Text(
                              getEmotionName(context, Emotion.emotions.indexOf(e)),
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
                          AppLocalizations.of(context)!.dayNotFilled,
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
                  // Tags des victoires (toujours afficher si présentes)
                  if (victoryCards.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Builder(
                      builder: (context) {
                        final color = emotion?.moodColor ?? theme.colorScheme.primary;
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: victoryCards.map((victory) {
                            return _VictoryTag(
                              victory: victory,
                              color: color,
                              canDelete: canDelete,
                              onDelete: () => onDeleteVictory(victory.id),
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
  final bool canDelete;
  final VoidCallback onDelete;

  const _VictoryTag({
    required this.victory,
    required this.color,
    this.canDelete = false,
    required this.onDelete,
  });

  String _formatTime(DateTime? timestamp) {
    if (timestamp == null) return '';
    final hour = timestamp.hour;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette victoire ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final tagContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.6),
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
          Flexible(
            child: Text(
              getVictoryText(context, victory.id),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.95),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (victory.timestamp != null) ...[
            const SizedBox(width: 6),
            Text(
              '• ${_formatTime(victory.timestamp)}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ],
      ),
    );

    if (!canDelete) {
      return tagContent;
    }

    return Dismissible(
      key: ValueKey('victory_${victory.id}_${victory.timestamp?.millisecondsSinceEpoch}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) => _confirmDelete(context),
      onDismissed: (direction) => onDelete(),
      background: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerLeft,
        child: const Icon(Icons.delete, color: Colors.white, size: 18),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete, color: Colors.white, size: 18),
      ),
      child: tagContent,
    );
  }
}

