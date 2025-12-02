import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/victory_card.dart';
import '../models/emotion.dart';
import '../models/theme_config.dart';
import '../models/day_entry.dart';

import '../widgets/victory_card_widget.dart';
import 'day_completion_screen.dart';
import '../widgets/today_history_toggle.dart';
import '../widgets/history_view.dart';

import '../widgets/daily_quote_card.dart';
import '../widgets/home_tree_widget.dart';
import 'settings_screen.dart';
import '../services/preferences_service.dart';
import '../services/notification_service.dart';
import '../services/database_service.dart';
import '../app_navigator.dart';
import '../utils/quotes_data.dart';
import '../l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  final AppTheme currentTheme;
  final ValueChanged<AppTheme> onThemeChanged;
  final Locale? currentLocale;
  final ValueChanged<Locale?> onLocaleChanged;

  const HomeScreen({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
    this.currentLocale,
    required this.onLocaleChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late List<VictoryCard> _victories;
  late PageController _pageController;
  ViewMode _currentView = ViewMode.today;
  bool _isDayCompleted = false;
  // final List<String> _dailyQuotes = dailyQuotes; // Removed, using getDailyQuotes dynamically

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _victories = VictoryCard.getDefaultVictories();
    _pageController = PageController(initialPage: 0);
    _checkAndResetVictories();
    _checkDayCompletion();
    _checkYesterdayEmotion(); // Check if yesterday needs emotion
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
      _checkYesterdayEmotion(); // Check if yesterday needs emotion
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
    
    if (shouldReset) {
      // Before resetting, save the previous day's victories if they exist
      final lastResetDate = await PreferencesService.getLastResetDate();
      final savedVictories = await PreferencesService.getTodayVictories();
      
      // Only save if we have a valid previous date and some victories were accomplished
      if (lastResetDate != null) {
        final accomplishedVictories = savedVictories.where((v) => v.isAccomplished).toList();
        
        // We should check if an entry already exists for this date (e.g. manually completed)
        final history = await PreferencesService.getHistory();
        final existingIndex = history.indexWhere((e) =>
            e.date.year == lastResetDate.year &&
            e.date.month == lastResetDate.month &&
            e.date.day == lastResetDate.day);
            
        DayEntry entryToSave;
        
        if (existingIndex >= 0) {
          // Entry exists (maybe user did manual check-in), update victories but keep emotion/comment
          final existingEntry = history[existingIndex];
          entryToSave = DayEntry(
            date: existingEntry.date,
            emotion: existingEntry.emotion,
            comment: existingEntry.comment,
            victoryCards: accomplishedVictories, // Update with latest state
          );
          debugPrint('📝 Updating existing entry for ${lastResetDate.toString().substring(0, 10)}');
        } else {
          // No entry exists, create a new one (auto-save at midnight)
          entryToSave = DayEntry(
            date: lastResetDate,
            emotion: null, // No emotion recorded
            comment: null,
            victoryCards: accomplishedVictories,
          );
          debugPrint('📝 Creating new empty entry for ${lastResetDate.toString().substring(0, 10)} with ${accomplishedVictories.length} victories');
        }
        
        // Save locally
        await PreferencesService.saveDayEntry(entryToSave);
        debugPrint('✅ Saved locally');
        
        // Save remotely if logged in
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await DatabaseService().saveDayEntry(user.uid, entryToSave);
          debugPrint('✅ Saved to Firebase for user ${user.uid}');
        }
      }

      if (mounted) {
        setState(() {
          _victories = VictoryCard.getDefaultVictories();
        });
      }
      
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

  Future<void> _checkYesterdayEmotion() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final yesterdayEntry = await DatabaseService().getYesterdayDayEntry(user.uid);
      
      // Show prompt if yesterday exists but has no emotion
      if (yesterdayEntry != null && yesterdayEntry.emotion == null) {
        // Wait a bit for UI to settle before navigating
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _navigateToYesterdayCompletion(yesterdayEntry);
        }
      }
    }
  }

  void _navigateToYesterdayCompletion(DayEntry yesterdayEntry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DayCompletionScreen(
          victories: yesterdayEntry.victoryCards.isEmpty 
              ? VictoryCard.getDefaultVictories() 
              : yesterdayEntry.victoryCards,
          onComplete: (emotion, comment) async {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              final updatedEntry = DayEntry(
                date: yesterdayEntry.date,
                emotion: emotion,
                comment: comment.isEmpty ? null : comment,
                victoryCards: yesterdayEntry.victoryCards,
              );
              await DatabaseService().saveDayEntry(user.uid, updatedEntry);
            }
          },
          targetDate: yesterdayEntry.date,
          showBackWarning: true, // Show warning if user tries to go back without setting emotion
        ),
      ),
    );
  }


  void _onViewModeChanged(ViewMode mode) {
    setState(() {
      _currentView = mode;
    });
    int pageIndex = 0;
    if (mode == ViewMode.history) {
      pageIndex = 1;
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
        // Reload victories when switching back to today view
        // This ensures we see the latest state after deleting victories from history
        _reloadVictories();
      } else if (index == 1) {
        _currentView = ViewMode.history;
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
          currentLocale: widget.currentLocale,
          onLocaleChanged: widget.onLocaleChanged,
        ),
      ),
    );
  }

  void _toggleVictory(int index) async {
    // Only allow checking victories, not unchecking
    // Victories can only be removed via deletion from History page
    if (_victories[index].isAccomplished) {
      // Already accomplished, don't allow unchecking
      return;
    }
    
    setState(() {
      _victories[index].isAccomplished = true;
      _victories[index].timestamp = DateTime.now(); // Set timestamp when accomplished
    });
    
    // Update leaf counter in tree resources
    final resources = await PreferencesService.getTreeResources();
    // Since we only allow toggling ON, we always add a leaf
    final newLeafCount = resources.leafCount + 1;
    
    await PreferencesService.saveTreeResources(
      resources.copyWith(leafCount: newLeafCount),
    );
    
    // Refresh the tree widget to show updated leaf count
    // The widget will reload resources in didUpdateWidget when victoryCount changes
    // But we also trigger a refresh here to ensure immediate update
    if (mounted) {
      setState(() {
        // This will trigger a rebuild and didUpdateWidget will reload resources
      });
    }
    
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
            AppLocalizations.of(context)!.congratulationsMessage(accomplishedCount, accomplishedCount > 1 ? 's' : ''),
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
    final locale = Localizations.localeOf(context).languageCode;
    final quotes = getDailyQuotes(locale);
    return quotes[dayOfYear % quotes.length];
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
              
              // Arbre de croissance
              HomeTreeWidget(
                victoryCount: _victories.where((v) => v.isAccomplished).length,
              ),

              // Titre Victoires
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
                      AppLocalizations.of(context)!.victoriesTitle,
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
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8, // Adjusted for new card design
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
                      HistoryView(
                        onHistoryChanged: () {
                          // Reload victories when history changes (e.g., when a victory is deleted)
                          // This will trigger a rebuild, and the tree widget will reload
                          // its state and resources when victoryCount changes
                          _reloadVictories();
                        },
                      ),

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
