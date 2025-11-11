import 'dart:async';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/emotion.dart';
import '../models/victory_card.dart';
import '../widgets/wireframe_smiley.dart';

class DayCompletionScreen extends StatefulWidget {
  final List<VictoryCard> victories;
  final Function(Emotion, String) onComplete;

  const DayCompletionScreen({
    super.key,
    required this.victories,
    required this.onComplete,
  });

  @override
  State<DayCompletionScreen> createState() => _DayCompletionScreenState();
}

class _DayCompletionScreenState extends State<DayCompletionScreen> {
  Emotion? selectedEmotion;
  final TextEditingController _commentController = TextEditingController();
  final List<String> _placeholderSuggestions = [
    "C'est dur mais j'ai tenu",
    "Aujourd'hui j'ai fait de mon mieux",
    "Petit à petit, jour après jour",
    "Je suis fière de mes petits pas",
    "Chaque victoire compte",
    "J'ai pris soin de moi aujourd'hui",
  ];
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
        .map((v) => '${v.emoji} ${v.text}')
        .join('\n');
    
    final comment = _commentController.text.trim();
    final emotionText = selectedEmotion!.name;
    
    final shareText = '''
🌟 Ma journée du ${_formatDate(DateTime.now())}

$_accomplishedCount victoire${_accomplishedCount > 1 ? 's' : ''} accomplie${_accomplishedCount > 1 ? 's' : ''} :
$victoriesText

💭 Comment je me sens : $emotionText ${selectedEmotion!.emoji}

${comment.isNotEmpty ? '💬 $comment' : ''}

#MesPetitsPas #PostPartum
''';

    Share.share(shareText);
  }

  String _formatDate(DateTime date) {
    final months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _validateDay() {
    if (selectedEmotion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez sélectionner votre humeur'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    widget.onComplete(
      selectedEmotion!,
      _commentController.text.trim(),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Terminer ma journée',
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
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
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Chaque petit pas compte, même les plus petits 🌱',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (_accomplishedVictories.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: _accomplishedVictories.map((victory) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                victory.emoji,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                victory.text,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Sélection de l'émotion
            Text(
              "Comment vous sentez-vous aujourd'hui ?",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            // Smileys emoji centrés sur une seule ligne (5 seulement)
            Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Prendre seulement les 5 premières émotions
                    ...Emotion.emotions.take(5).toList().map((emotion) {
                      final isSelected = selectedEmotion == emotion;
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: WireframeSmiley(
                          emoji: emotion.emoji,
                          isSelected: isSelected,
                          moodColor: emotion.moodColor,
                          onTap: () {
                            setState(() {
                              selectedEmotion = emotion;
                            });
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Champ de commentaire
            Text(
              'Un mot sur votre journée ?',
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
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
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
            const SizedBox(height: 32),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: selectedEmotion != null ? _shareDay : null,
                    icon: const Icon(Icons.share),
                    label: const Text('Partager'),
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
                    label: const Text('Valider'),
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
    );
  }
}

