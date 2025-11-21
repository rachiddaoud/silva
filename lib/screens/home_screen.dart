import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/victory_card.dart';
import '../models/emotion.dart';
import '../models/theme_config.dart';
import '../models/day_entry.dart';
import '../widgets/victory_card_widget.dart';
import 'day_completion_screen.dart';
import '../widgets/today_history_toggle.dart';
import '../widgets/history_view.dart';
import '../widgets/path_view.dart';
import '../widgets/daily_quote_card.dart';
import 'settings_screen.dart';
import '../services/preferences_service.dart';
import '../services/notification_service.dart';
import '../services/database_service.dart';
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
  bool _isDayCompleted = false;
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
    _checkDayCompletion();
    _setupNotificationCallback();
    _refreshMorningNotification();
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
      _checkDayCompletion();
      _refreshMorningNotification();
      // Recharger les victoires pour refléter les changements depuis les notifications
      _reloadVictories();
    }
  }
  
  Future<void> _reloadVictories() async {
    final savedVictories = await PreferencesService.getTodayVictories();
    if (mounted) {
      setState(() {
        _victories = savedVictories;
      });
    }
  }

  Future<void> _refreshMorningNotification() async {
    // Reprogrammer les notifications pour mettre à jour la citation du jour et le nom de l'utilisateur
    final enabled = await PreferencesService.areNotificationsEnabled();
    if (enabled) {
      await NotificationService.scheduleMorningNotification();
      await NotificationService.scheduleDailyNotification();
      await NotificationService.scheduleDayReminders();
    }
  }

  Future<void> _checkAndResetVictories() async {
    final shouldReset = await PreferencesService.shouldResetVictories();
    if (shouldReset && mounted) {
      setState(() {
        _victories = VictoryCard.getDefaultVictories();
      });
      await PreferencesService.setLastResetDate(DateTime.now());
      await PreferencesService.saveTodayVictories(_victories);
      // Reprogrammer les rappels de la journée
      await NotificationService.scheduleDayReminders();
    } else {
      // Charger les victoires sauvegardées
      final savedVictories = await PreferencesService.getTodayVictories();
      if (mounted) {
        setState(() {
          _victories = savedVictories;
        });
      }
    }
    
    // Ensure yesterday exists (persistence check)
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await DatabaseService().ensureYesterdayExists(user.uid);
    }
  }


  Future<void> _checkDayCompletion() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final todayEntry = await DatabaseService().getTodayDayEntry(user.uid);
      if (mounted) {
        setState(() {
          // Day is completed if we have an entry with an emotion
          _isDayCompleted = todayEntry?.emotion != null;
        });
      }
    }
  }


  void _onViewModeChanged(ViewMode mode) {
    setState(() {
      _currentView = mode;
    });
    int pageIndex = 0;
    if (mode == ViewMode.history) {
      pageIndex = 1;
    } else if (mode == ViewMode.path) {
      pageIndex = 2;
    }
    _pageController.animateToPage(
      pageIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      if (index == 0) {
        _currentView = ViewMode.today;
      } else if (index == 1) {
        _currentView = ViewMode.history;
      } else if (index == 2) {
        _currentView = ViewMode.path;
      }
    });
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          currentTheme: widget.currentTheme,
          onThemeChanged: widget.onThemeChanged,
        ),
      ),
    );
  }

  void _toggleVictory(int index) async {
    setState(() {
      _victories[index].isAccomplished =
          !_victories[index].isAccomplished;
    });
    // Sauvegarder les victoires mises à jour
    await PreferencesService.saveTodayVictories(_victories);
    
    // Sync with Firestore if user is logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await DatabaseService().updateTodayVictories(user.uid, _victories);
    }

    // Reprogrammer les rappels si nécessaire
    await NotificationService.scheduleDayReminders();
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

  void _completeDay(Emotion emotion, String comment) async {
    final accomplishedCount =
        _victories.where((v) => v.isAccomplished).length;

    // Récupérer les victoires accomplies
    final accomplishedVictories =
        _victories.where((v) => v.isAccomplished).toList();

    // Créer l'entrée d'historique
    final dayEntry = DayEntry(
      date: DateTime.now(),
      emotion: emotion,
      comment: comment.isEmpty ? null : comment,
      victoryCards: accomplishedVictories,
    );

    // Sauvegarder l'entrée
    // await PreferencesService.saveDayEntry(dayEntry);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await DatabaseService().saveDayEntry(user.uid, dayEntry);
    }
    
    if (mounted) {
      setState(() {
        _isDayCompleted = true;
      });
    }

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
    
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(20.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Citation du jour
              // Citation du jour
              DailyQuoteCard(quote: _currentQuote),
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
            ]),
          ),
        ),
        // Grille 3x3 des victoires
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return VictoryCardWidget(
                  key: ValueKey(_victories[index].id),
                  card: _victories[index],
                  onTap: () => _toggleVictory(index),
                );
              },
              childCount: _victories.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 100), // Espace pour le FAB
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeConfig = ThemeConfig.themes[widget.currentTheme];
    final backgroundPath = themeConfig?.backgroundPath;
    
    return Scaffold(
      body: Stack(
        children: [
          // Background image for seasonal themes
          if (backgroundPath != null)
            Positioned.fill(
              child: Image.asset(
                backgroundPath,
                fit: BoxFit.cover,
                cacheWidth: 1080, // Optimization: Limit memory usage
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: theme.scaffoldBackgroundColor,
                  );
                },
              ),
            ),
          // Main content
          SafeArea(
            child: Column(
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
                      const PathView(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Floating profile button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: GestureDetector(
              onTap: _navigateToSettings,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: _buildProfileImage(theme),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _shouldShowEndDayButton()
          ? FloatingActionButton(
              onPressed: _showEmotionCheckin,
              child: const Icon(Icons.nightlight_round),
            )
          : null,
    );
  }

  bool _shouldShowEndDayButton() {
    if (_currentView != ViewMode.today) return false;
    if (_isDayCompleted) return false;
    
    final now = DateTime.now();
    return now.hour >= 22;
  }

  Widget _buildProfileImage(ThemeData theme) {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.photoURL != null) {
      return CircleAvatar(
        radius: 12,
        backgroundImage: NetworkImage(user!.photoURL!),
        backgroundColor: Colors.transparent,
      );
    }
    return Icon(
      Icons.person,
      color: theme.colorScheme.onPrimary,
      size: 24,
    );
  }
}


