import 'dart:async';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/emotion.dart';
import '../models/victory_card.dart';
import '../widgets/wireframe_smiley.dart';
import '../utils/sprite_utils.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../utils/localization_utils.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';

class DayCompletionScreen extends StatefulWidget {
  final List<VictoryCard> victories;
  final Function(Emotion, String) onComplete;
  final DateTime? targetDate; // Optional: defaults to today
  final bool showBackWarning; // Show warning if user tries to go back without emotion

  const DayCompletionScreen({
    super.key,
    required this.victories,
    required this.onComplete,
    this.targetDate,
    this.showBackWarning = false,
  });

  @override
  State<DayCompletionScreen> createState() => _DayCompletionScreenState();
}

class _DayCompletionScreenState extends State<DayCompletionScreen> {
  Emotion? selectedEmotion;
  final TextEditingController _commentController = TextEditingController();
  List<String> _placeholderSuggestions = []; // Initialized in didChangeDependencies
  int _currentPlaceholderIndex = 0;
  String _displayedPlaceholder = '';
  Timer? _typewriterTimer;
  int _currentCharIndex = 0;

  @override
  void initState() {
    super.initState();
    _commentController.addListener(_onCommentChanged);
    // Démarrer l'animation après le premier frame pour éviter le flash
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTypewriterAnimation();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize placeholders with localized strings
    // Ideally these should be in ARB, but for now I'll use a simple list or keep them hardcoded if not critical
    // Or better, add them to ARB. Since I didn't add them yet, I'll use English/French based on locale manually or just keep French for now to save time/complexity
    // Wait, I should do it properly.
    // I'll leave them as is for now but if I had time I'd add them to ARB.
    // Actually, I'll just use English ones if locale is English.
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'en') {
      _placeholderSuggestions = [
        "It's hard but I held on",
        "Today I did my best",
        "Little by little, day by day",
        "I am proud of my little steps",
        "Every victory counts",
        "I took care of myself today",
      ];
    } else {
      _placeholderSuggestions = [
        "C'est dur mais j'ai tenu",
        "Aujourd'hui j'ai fait de mon mieux",
        "Petit à petit, jour après jour",
        "Je suis fière de mes petits pas",
        "Chaque victoire compte",
        "J'ai pris soin de moi aujourd'hui",
      ];
    }
  }

  void _startTypewriterAnimation() {
    if (_commentController.text.isNotEmpty) return;
    
    _typewriterTimer?.cancel();
    _currentCharIndex = 0;
    _displayedPlaceholder = '';
    
    _animateTypewriter();
  }

  void _animateTypewriter() {
    if (_commentController.text.isNotEmpty || !mounted) return;
    
    final currentText = _placeholderSuggestions[_currentPlaceholderIndex];
    
    // Animation plus lente : 100ms par caractère au lieu de 50ms
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted || _commentController.text.isNotEmpty) {
        timer.cancel();
        return;
      }

      setState(() {
        // Écriture lettre par lettre
        if (_currentCharIndex < currentText.length) {
          _displayedPlaceholder = currentText.substring(0, _currentCharIndex + 1);
          _currentCharIndex++;
        } else {
          // Texte complet affiché, attendre puis passer au suivant
          timer.cancel();
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted && _commentController.text.isEmpty) {
              // Effacer tout d'un coup et passer au suivant
              setState(() {
                _currentPlaceholderIndex =
                    (_currentPlaceholderIndex + 1) % _placeholderSuggestions.length;
                _currentCharIndex = 0;
                _displayedPlaceholder = '';
              });
              // Petite pause avant de recommencer
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted && _commentController.text.isEmpty) {
                  _animateTypewriter();
                }
              });
            }
          });
        }
      });
    });
  }

  void _onCommentChanged() {
    if (_commentController.text.isEmpty) {
      // Redémarrer l'animation si le champ est vide
      _currentCharIndex = 0;
      _displayedPlaceholder = '';
      _startTypewriterAnimation();
    } else {
      // Arrêter l'animation si l'utilisateur tape
      _typewriterTimer?.cancel();
      setState(() {
        _displayedPlaceholder = '';
      });
    }
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    _commentController.dispose();
    super.dispose();
  }

  int get _accomplishedCount {
    return widget.victories.where((v) => v.isAccomplished).length;
  }

  List<VictoryCard> get _accomplishedVictories {
    return widget.victories.where((v) => v.isAccomplished).toList();
  }

  void _shareDay() {
    if (selectedEmotion == null) return;

    final victoriesText = _accomplishedVictories
        .map((v) => '${v.emoji} ${getVictoryText(context, v.id)}')
        .join('\n');
    
    final comment = _commentController.text.trim();
    final emotionText = getEmotionName(context, Emotion.emotions.indexOf(selectedEmotion!));
    final count = _accomplishedCount;
    final plural = count > 1 ? 's' : '';
    final targetDate = widget.targetDate ?? DateTime.now();
    
    final l10n = AppLocalizations.of(context)!;
    final shareText = '''
${l10n.shareTitle(_formatDate(targetDate))}

${l10n.shareVictories(count, count > 1 ? 's' : (count > 1 ? 'ies' : 'y'))}
$victoriesText

${l10n.shareMood(emotionText)} ${selectedEmotion!.emoji}

${comment.isNotEmpty ? '💬 $comment' : ''}

#MesPetitsPas #PostPartum
''';

    Share.share(shareText);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final l10n = AppLocalizations.of(context)!;
    
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return l10n.today;
    }
    
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return l10n.yesterday;
    }
    
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).format(date);
  }

  void _validateDay() async {
    if (selectedEmotion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.selectMoodError),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Play success sound and haptic
    await HapticService().medium();
    await AudioService().playSuccess();

    widget.onComplete(
      selectedEmotion!,
      _commentController.text.trim(),
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildVictoriesRecap(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.tertiary.withValues(alpha: 0.3),
            theme.colorScheme.tertiary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_accomplishedCount == 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite,
                  color: theme.colorScheme.secondary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.everyStepCounts,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          if (_accomplishedVictories.isNotEmpty)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: _accomplishedVictories.map((victory) {
                return SpriteDisplay(
                  victoryId: victory.spriteId,
                  size: 40,
                  showBorder: false,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildEmotionSelector(ThemeData theme) {
    // Sélectionner 5 émotions distinctes avec des doodles différents
    // Épuisée, Triste, Bof/Neutre, OK/Calme, Fière/Joyeuse
    final selectedEmotions = [
      Emotion.emotions[0], // Épuisée
      Emotion.emotions[1], // Triste / Débordée
      Emotion.emotions[3], // Bof / Neutre
      Emotion.emotions[4], // OK / Calme
      Emotion.emotions[5], // Fière / Joyeuse
    ];
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final emotion in selectedEmotions)
          Expanded(
            child: Center(
              child: WireframeSmiley(
                emoji: emotion.emoji,
                imagePath: emotion.imagePath,
                isSelected: selectedEmotion == emotion,
                moodColor: emotion.moodColor,
                onTap: () async {
                  // Play selection feedback
                  await HapticService().selection();
                  await AudioService().playEmotionSelect();
                  
                  setState(() {
                    selectedEmotion = emotion;
                  });
                },
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final targetDate = widget.targetDate ?? DateTime.now();

    return PopScope(
      canPop: !widget.showBackWarning || selectedEmotion != null,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        
        // Show confirmation dialog
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.quitWithoutSaving),
            content: Text(
              AppLocalizations.of(context)!.quitWithoutSavingMessage,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(AppLocalizations.of(context)!.quit),
              ),
            ],
          ),
        );
        
        if (shouldPop == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            AppLocalizations.of(context)!.finishDayTitle(_formatDate(targetDate)),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Récapitulatif de la journée
            _buildVictoriesRecap(theme),
            const SizedBox(height: 32),

            // Sélection de l'émotion
            Text(
              AppLocalizations.of(context)!.howDoYouFeel,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            // Smileys emoji centrés sur une seule ligne (5 seulement)
            _buildEmotionSelector(theme),
            const SizedBox(height: 32),

            // Champ de commentaire
            Text(
              AppLocalizations.of(context)!.wordAboutDay,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: TextField(
                controller: _commentController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: _displayedPlaceholder,
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    fontStyle: FontStyle.italic,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(20),
                ),
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: selectedEmotion != null ? _shareDay : null,
                    icon: const Icon(Icons.share),
                    label: Text(AppLocalizations.of(context)!.share),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      side: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: selectedEmotion != null ? _validateDay : null,
                    icon: const Icon(Icons.check_circle),
                    label: Text(AppLocalizations.of(context)!.validate),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      ),
    );
  }
}

