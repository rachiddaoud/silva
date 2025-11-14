import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/victory_card.dart';
import '../models/emotion.dart';
import '../models/theme_config.dart';
import '../widgets/victory_card_widget.dart';
import 'day_completion_screen.dart';
import '../widgets/today_history_toggle.dart';
import '../widgets/history_view.dart';
import '../widgets/profile_menu.dart';
import '../services/preferences_service.dart';
import '../services/notification_service.dart';
import '../app_navigator.dart';

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

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
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
    WidgetsBinding.instance.addObserver(this);
    _victories = VictoryCard.getDefaultVictories();
    _pageController = PageController(initialPage: 0);
    _checkAndResetVictories();
    _setupNotificationCallback();
  }

  void _setupNotificationCallback() {
    // Définir le callback pour gérer les clics sur les notifications
    NotificationService.onNotificationTappedCallback = () {
      // Naviguer vers l'écran de complétion avec les victoires actuelles
      final navigator = navigatorKey.currentState;
      if (navigator != null && mounted) {
        navigator.push(
          MaterialPageRoute(
            builder: (context) => DayCompletionScreen(
              victories: _victories,
              onComplete: _completeDay,
            ),
          ),
        );
      }
    };
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    // Nettoyer le callback
    NotificationService.onNotificationTappedCallback = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Vérifier si on doit réinitialiser quand l'app revient au premier plan
    if (state == AppLifecycleState.resumed) {
      _checkAndResetVictories();
    }
  }

  Future<void> _checkAndResetVictories() async {
    final shouldReset = await PreferencesService.shouldResetVictories();
    if (shouldReset && mounted) {
      setState(() {
        _victories = VictoryCard.getDefaultVictories();
      });
      await PreferencesService.setLastResetDate(DateTime.now());
    }
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DayCompletionScreen(
          victories: _victories,
          onComplete: _completeDay,
        ),
      ),
    );
  }

  void _completeDay(Emotion emotion, String comment) {
    final accomplishedCount =
        _victories.where((v) => v.isAccomplished).length;

    // Ne pas réinitialiser les victoires - elles seront réinitialisées à minuit
    // Les victoires restent telles quelles après avoir terminé la journée

    // Afficher le message de félicitations
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Bravo ! Vous avez terminé $accomplishedCount victoire${accomplishedCount > 1 ? 's' : ''} aujourd'hui.",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Theme.of(context).colorScheme.onTertiary,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.08),
                  theme.colorScheme.secondary.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.greatVibes(
                  fontSize: 32,
                  fontWeight: FontWeight.w400,
                  color: theme.colorScheme.onSurface,
                  height: 0.9,
                  letterSpacing: 0.5,
                ),
                children: [
                  TextSpan(
                    text: '❝ ',
                    style: GoogleFonts.greatVibes(
                      fontSize: 50,
                      fontWeight: FontWeight.w400,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  TextSpan(
                    text: _currentQuote,
                  ),
                  TextSpan(
                    text: ' ❞',
                    style: GoogleFonts.greatVibes(
                      fontSize: 50,
                      fontWeight: FontWeight.w400,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Titre Victoires
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Icon(
                  Icons.star_rounded,
                  color: theme.colorScheme.secondary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Victoires',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          // Grille 3x3 des victoires (taille réduite)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
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


