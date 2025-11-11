import 'package:flutter/material.dart';
import '../models/victory_card.dart';
import '../models/emotion.dart';
import '../widgets/victory_card_widget.dart';
import '../widgets/emotion_checkin_modal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<VictoryCard> _victories;
  final List<String> _dailyQuotes = [
    "Vous faites de votre mieux, et c'est suffisant.",
    "Le repos n'est pas une récompense, c'est une nécessité.",
    "Prendre soin de vous, c'est prendre soin de votre bébé.",
  ];

  @override
  void initState() {
    super.initState();
    _victories = VictoryCard.getDefaultVictories();
  }

  void _toggleVictory(int index) {
    setState(() {
      _victories[index].isAccomplished =
          !_victories[index].isAccomplished;
    });
  }

  void _showEmotionCheckin() {
    showDialog(
      context: context,
      builder: (context) => EmotionCheckinModal(
        victoriesCount: _victories.where((v) => v.isAccomplished).length,
        onValidate: _completeDay,
      ),
    );
  }

  void _completeDay(Emotion emotion) {
    final accomplishedCount =
        _victories.where((v) => v.isAccomplished).length;

    // Réinitialiser toutes les cartes
    setState(() {
      _victories = VictoryCard.getDefaultVictories();
    });

    // Afficher le message de félicitations
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Bravo ! Vous avez terminé $accomplishedCount victoire${accomplishedCount > 1 ? 's' : ''} aujourd'hui.",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF4A6B5A),
            ),
          ),
          backgroundColor: const Color(0xFFB5E5CF),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          duration: const Duration(seconds: 3),
          elevation: 1,
        ),
      );
    }
  }

  String get _currentQuote {
    // Pour le POC, utiliser la première citation
    // Ou rotation simple basée sur le jour
    final dayOfYear = DateTime.now().difference(
      DateTime(DateTime.now().year, 1, 1),
    ).inDays;
    return _dailyQuotes[dayOfYear % _dailyQuotes.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Citation du jour
              Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFFFFF),
                      Color(0xFFF0F9FF),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF89CFF0).withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.favorite,
                      color: Color(0xFFFFB3BA),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _currentQuote,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF5A7A8A),
                          height: 1.6,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.favorite,
                      color: Color(0xFFFFB3BA),
                      size: 24,
                    ),
                  ],
                ),
              ),
              // Titre Accomplissements
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFFD4A3),
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Accomplissements',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4A6B7A),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB5E5CF).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_victories.where((v) => v.isAccomplished).length}/9',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4A6B5A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Grille 3x3 des victoires
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: _victories.length,
                  itemBuilder: (context, index) {
                    return VictoryCardWidget(
                      card: _victories[index],
                      onTap: () => _toggleVictory(index),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showEmotionCheckin,
        icon: const Icon(Icons.celebration_rounded),
        label: const Text(
          "Terminer ma journée",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

