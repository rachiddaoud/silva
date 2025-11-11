import 'package:flutter/material.dart';
import '../models/victory_card.dart';
import '../models/emotion.dart';
import '../models/theme_config.dart';
import '../widgets/victory_card_widget.dart';
import '../widgets/emotion_checkin_modal.dart';
import '../widgets/today_history_toggle.dart';
import '../widgets/history_view.dart';
import '../widgets/profile_menu.dart';

class HomeScreen extends StatefulWidget {
  final AppTheme currentTheme;
  final ValueChanged<AppTheme> onThemeChanged;

  const HomeScreen({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<VictoryCard> _victories;
  late PageController _pageController;
  ViewMode _currentView = ViewMode.today;
  final List<String> _dailyQuotes = [
    "Vous faites de votre mieux, et c'est suffisant.",
    "Le repos n'est pas une récompense, c'est une nécessité.",
    "Prendre soin de vous, c'est prendre soin de votre bébé.",
  ];

  @override
  void initState() {
    super.initState();
    _victories = VictoryCard.getDefaultVictories();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onViewModeChanged(ViewMode mode) {
    setState(() {
      _currentView = mode;
    });
    _pageController.animateToPage(
      mode == ViewMode.today ? 0 : 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentView = index == 0 ? ViewMode.today : ViewMode.history;
    });
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ProfileMenu(
        currentTheme: widget.currentTheme,
        onThemeChanged: widget.onThemeChanged,
      ),
    );
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

  Widget _buildTodayView() {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Citation du jour
          Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  theme.colorScheme.surface,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.favorite,
                  color: theme.colorScheme.error,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _currentQuote,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurface,
                      height: 1.6,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.favorite,
                  color: theme.colorScheme.error,
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
                Icon(
                  Icons.star_rounded,
                  color: theme.colorScheme.secondary,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  'Accomplissements',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
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
                    color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_victories.where((v) => v.isAccomplished).length}/9',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Grille 3x3 des victoires
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
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
          const SizedBox(height: 100), // Espace pour le FAB
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: _showProfileMenu,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                child: Icon(
                  Icons.person,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Toggle central
          Center(
            child: TodayHistoryToggle(
              selectedMode: _currentView,
              onModeChanged: _onViewModeChanged,
            ),
          ),
          // PageView pour basculer entre les vues
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: [
                _buildTodayView(),
                const HistoryView(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _currentView == ViewMode.today
          ? FloatingActionButton.extended(
              onPressed: _showEmotionCheckin,
              icon: const Icon(Icons.celebration_rounded),
              label: const Text(
                "Terminer ma journée",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          : null,
    );
  }
}

