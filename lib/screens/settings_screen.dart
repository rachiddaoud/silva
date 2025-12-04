import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/theme_config.dart';
import '../models/app_category.dart';
import '../models/victory_repository.dart';
import '../services/preferences_service.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/analytics_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import '../l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';


class SettingsScreen extends StatefulWidget {
  final AppTheme currentTheme;
  final ValueChanged<AppTheme> onThemeChanged;
  final Locale? currentLocale;
  final ValueChanged<Locale?> onLocaleChanged;

  const SettingsScreen({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
    this.currentLocale,
    required this.onLocaleChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _hapticEnabled = true;
  double _soundVolume = 0.7;
  String? _userName;
  String? _photoURL;
  DateTime? _dateOfBirth;
  AppCategory? _currentCategory;
  late AppTheme _currentTheme;
  late Locale? _currentLocale;

  @override
  void initState() {
    super.initState();
    _currentTheme = widget.currentTheme;
    _currentLocale = widget.currentLocale;
    _loadData();
    // Track screen view and profile viewed
    AnalyticsService.instance.logScreenView(screenName: 'settings');
    AnalyticsService.instance.logEvent(name: AnalyticsEvents.profileViewed);
  }

  Future<void> _loadData() async {
    final enabled = await PreferencesService.areNotificationsEnabled();
    final soundEnabled = await PreferencesService.getSoundEnabled();
    final hapticEnabled = await PreferencesService.getHapticEnabled();
    final soundVolume = await PreferencesService.getSoundVolume();
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? await PreferencesService.getUserName();
    final photoURL = user?.photoURL;
    final dob = await PreferencesService.getDateOfBirth();
    final category = await PreferencesService.getAppCategory();
    setState(() {
      _notificationsEnabled = enabled;
      _soundEnabled = soundEnabled;
      _hapticEnabled = hapticEnabled;
      _soundVolume = soundVolume;
      _userName = name;
      _photoURL = photoURL;
      _dateOfBirth = dob;
      _currentCategory = category;
    });
  }

  int? _calculateAge(DateTime? dateOfBirth) {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  Future<void> _toggleNotifications(bool value) async {
    // Track reminder toggled
    await AnalyticsService.instance.logEvent(
      name: AnalyticsEvents.reminderToggled,
      parameters: {
        AnalyticsParams.reminderType: 'all',
        'enabled': value.toString(),
      },
    );

    setState(() {
      _notificationsEnabled = value;
    });
    await PreferencesService.setNotificationsEnabled(value);
    if (value) {
      await NotificationService.scheduleDailyNotification();
      await NotificationService.scheduleMorningNotification();
      await NotificationService.scheduleDayReminders();
    } else {
      await NotificationService.cancelDailyNotification();
      await NotificationService.cancelMorningNotification();
      await NotificationService.cancelDayReminders();
    }
  }

  String _getLanguageName() {
    final l10n = AppLocalizations.of(context)!;
    if (_currentLocale == null) {
      return l10n.systemDefault;
    }
    switch (_currentLocale!.languageCode) {
      case 'fr':
        return l10n.french;
      case 'en':
        return l10n.english;
      default:
        return l10n.systemDefault;
    }
  }

  void _showThemeSelector() {
    final colorThemes = [
      AppTheme.babyBlue,
      AppTheme.lavender,
      AppTheme.rosePowder,
      AppTheme.mint,
      AppTheme.peach,
    ];
    
    final seasonalThemes = [
      AppTheme.spring,
      AppTheme.summer,
      AppTheme.autumn,
      AppTheme.winter,
    ];
    
    final darkThemes = [
      AppTheme.night,
      AppTheme.eclipse,
    ];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              AppLocalizations.of(context)!.chooseTheme,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            // Color themes section
            Text(
              AppLocalizations.of(context)!.colors,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: colorThemes.map((theme) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: _buildThemeButton(theme),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 32),
            // Seasonal themes section
            Text(
              AppLocalizations.of(context)!.seasons,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: seasonalThemes.map((theme) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: _buildThemeButton(theme),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 32),
            // Dark themes section
            Text(
              AppLocalizations.of(context)!.dark,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: darkThemes.map((theme) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: _buildThemeButton(theme),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showLanguageSelector() {
    final l10n = AppLocalizations.of(context)!;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              l10n.language,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildLanguageOption(null, '🌐 ${l10n.systemDefault}'),
            const SizedBox(height: 12),
            _buildLanguageOption(const Locale('fr'), '🇫🇷 ${l10n.french}'),
            const SizedBox(height: 12),
            _buildLanguageOption(const Locale('en'), '🇬🇧 ${l10n.english}'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showCategorySelector() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => _CategorySelectorScreen(
          currentCategory: _currentCategory,
          onCategorySelected: (category) async {
            // Track category change
            await AnalyticsService.instance.logEvent(
              name: AnalyticsEvents.profileUpdated,
              parameters: {
                AnalyticsParams.category: category.name,
                'category_display_name': category.displayName,
              },
            );

            // Update category in preferences
            await PreferencesService.setAppCategory(category);
            
            // Update category in Firebase if logged in
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              await DatabaseService().updateUserCategory(user.uid, category);
            }

            // Update today's victories to match the new category
            final newVictories = VictoryRepository.getVictoriesForCategory(category);
            await PreferencesService.saveTodayVictories(newVictories);
            
            // Sync with Firebase if logged in
            if (user != null) {
              await DatabaseService().updateTodayVictories(user.uid, newVictories);
            }

            setState(() {
              _currentCategory = category;
            });
            
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.categoryChanged),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
        ),
      ),
    );
  }


  Widget _buildLanguageOption(Locale? locale, String label) {
    final isSelected = (_currentLocale?.languageCode == locale?.languageCode) &&
                       (_currentLocale == null && locale == null ||
                        _currentLocale != null && locale != null);
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: () {
        // Track language change
        AnalyticsService.instance.logEvent(
          name: AnalyticsEvents.languageChanged,
          parameters: {
            AnalyticsParams.language: locale?.languageCode ?? 'system',
          },
        );

        widget.onLocaleChanged(locale);
        setState(() {
          _currentLocale = locale;
        });
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.05),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildThemeButton(AppTheme appTheme) {
    final config = ThemeConfig.themes[appTheme]!;
    final isSelected = _currentTheme == appTheme;
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () {
        // Track theme change
        AnalyticsService.instance.logEvent(
          name: AnalyticsEvents.profileUpdated,
          parameters: {
            AnalyticsParams.theme: appTheme.toString(),
          },
        );

        widget.onThemeChanged(appTheme);
        setState(() {
          _currentTheme = appTheme;
        });
        Navigator.pop(context);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: config.primary,
              image: config.backgroundPath != null
                  ? DecorationImage(
                      image: AssetImage(config.backgroundPath!),
                      fit: BoxFit.cover,
                    )
                  : null,
              gradient: config.backgroundPath == null
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        config.primary,
                        config.secondary,
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                if (isSelected)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(21),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            config.name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _sendFeedback() async {
    final l10n = AppLocalizations.of(context)!;
    final emailUri = Uri(
      scheme: 'mailto',
      path: 'daoud.mohamed.rachid@gmail.com',
      query: 'subject=${Uri.encodeComponent(l10n.feedbackEmailSubject)}',
    );

    try {
      final canLaunch = await canLaunchUrl(emailUri);
      if (canLaunch) {
        await launchUrl(
          emailUri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.feedbackEmailError),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error launching email: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.feedbackEmailError}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }


  @override

  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settingsTitle),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            child: Column(
              children: [
                // User info section
                if (_userName != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(alpha: 0.2),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 28,
                            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                            backgroundImage: _photoURL != null ? NetworkImage(_photoURL!) : null,
                            child: _photoURL == null ? Icon(
                              Icons.person,
                              color: theme.colorScheme.primary,
                              size: 32,
                            ) : null,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _userName!,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_dateOfBirth != null) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${_calculateAge(_dateOfBirth)} ans',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // Settings List
                _buildSettingsTile(
                  icon: Icons.category_outlined,
                  title: AppLocalizations.of(context)!.category,
                  subtitle: _currentCategory?.displayName ?? AppLocalizations.of(context)!.selectCategory,
                  onTap: _showCategorySelector,
                  color: _currentCategory?.color ?? theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                _buildSettingsTile(
                  icon: Icons.palette_outlined,
                  title: AppLocalizations.of(context)!.chooseTheme, // Or "Thème" if I add it to ARB, but "chooseTheme" is close enough or I can add "themeTitle"
                  subtitle: ThemeConfig.themes[_currentTheme]!.name,
                  onTap: _showThemeSelector,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                _buildSettingsTile(
                  icon: Icons.language_rounded,
                  title: AppLocalizations.of(context)!.language,
                  subtitle: _getLanguageName(),
                  onTap: _showLanguageSelector,
                  color: theme.colorScheme.tertiary,
                ),
                const SizedBox(height: 16),
                _buildSettingsTile(
                  icon: _notificationsEnabled ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
                  title: AppLocalizations.of(context)!.notifications,
                  subtitle: _notificationsEnabled ? AppLocalizations.of(context)!.active : AppLocalizations.of(context)!.inactive,
                  color: theme.colorScheme.secondary,
                  trailing: Switch.adaptive(
                    value: _notificationsEnabled,
                    onChanged: _toggleNotifications,
                    activeColor: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSettingsTile(
                  icon: _soundEnabled ? Icons.volume_up : Icons.volume_off,
                  title: AppLocalizations.of(context)!.soundEffects,
                  subtitle: _soundEnabled ? AppLocalizations.of(context)!.enabled : AppLocalizations.of(context)!.inactive,
                  color: theme.colorScheme.secondary,
                  trailing: Switch.adaptive(
                    value: _soundEnabled,
                    onChanged: (value) async {
                      setState(() {
                        _soundEnabled = value;
                      });
                      await PreferencesService.setSoundEnabled(value);
                    },
                    activeColor: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSettingsTile(
                  icon: Icons.vibration,
                  title: AppLocalizations.of(context)!.hapticFeedback,
                  subtitle: _hapticEnabled ? AppLocalizations.of(context)!.enabled : AppLocalizations.of(context)!.inactive,
                  color: theme.colorScheme.tertiary,
                  trailing: Switch.adaptive(
                    value: _hapticEnabled,
                    onChanged: (value) async {
                      setState(() {
                        _hapticEnabled = value;
                      });
                      await PreferencesService.setHapticEnabled(value);
                    },
                    activeColor: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSettingsTile(
                  icon: Icons.bug_report_outlined,
                  title: AppLocalizations.of(context)!.testNotifications,
                  subtitle: AppLocalizations.of(context)!.sendTest,
                  color: theme.colorScheme.tertiary,
                  onTap: () async {
                    await NotificationService.showTestNotification();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppLocalizations.of(context)!.testNotificationsSent),
                          backgroundColor: theme.colorScheme.secondary,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                _buildSettingsTile(
                  icon: Icons.feedback_outlined,
                  title: AppLocalizations.of(context)!.sendFeedback,
                  subtitle: AppLocalizations.of(context)!.sendFeedbackSubtitle,
                  color: theme.colorScheme.primary,
                  onTap: _sendFeedback,
                ),
                const SizedBox(height: 16),
                _buildSettingsTile(

                  icon: Icons.info_outline_rounded,
                  title: AppLocalizations.of(context)!.about,
                  color: theme.colorScheme.onSurface,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(AppLocalizations.of(context)!.appTitle),
                        content: Text(
                          AppLocalizations.of(context)!.aboutDescription,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(AppLocalizations.of(context)!.close),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                _buildSettingsTile(
                  icon: Icons.logout_rounded,
                  title: AppLocalizations.of(context)!.logout,
                  color: theme.colorScheme.error,
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(AppLocalizations.of(context)!.logout),
                        content: Text(AppLocalizations.of(context)!.logoutConfirmation),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(AppLocalizations.of(context)!.cancel),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                              foregroundColor: theme.colorScheme.error,
                            ),
                            child: Text(AppLocalizations.of(context)!.logout),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && mounted) {
                      // Track logout
                      await AnalyticsService.instance.logEvent(
                        name: AnalyticsEvents.logout,
                      );

                      await AuthService().signOut();
                      if (mounted) {
                        // Navigate to login screen and remove all previous routes
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => LoginScreen(
                              onLoginSuccess: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (context) => HomeScreen(
                                      currentTheme: widget.currentTheme,
                                      onThemeChanged: widget.onThemeChanged,
                                      currentLocale: widget.currentLocale,
                                      onLocaleChanged: widget.onLocaleChanged,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          (route) => false,
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.02),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
          ],
        ),
      ),
    );
  }
}

// Category Selector Screen with circular wheel design
class _CategorySelectorScreen extends StatefulWidget {
  final AppCategory? currentCategory;
  final Future<void> Function(AppCategory) onCategorySelected;

  const _CategorySelectorScreen({
    required this.currentCategory,
    required this.onCategorySelected,
  });

  @override
  State<_CategorySelectorScreen> createState() => _CategorySelectorScreenState();
}

class _CategorySelectorScreenState extends State<_CategorySelectorScreen>
    with SingleTickerProviderStateMixin {
  AppCategory? _selectedCategory;
  late AnimationController _controller;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.currentCategory;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onCategorySelected(AppCategory category) async {
    setState(() {
      _selectedCategory = category;
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _onContinue() async {
    if (_selectedCategory == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onCategorySelected(_selectedCategory!);
    } catch (e) {
      debugPrint('Error saving category: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
          icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  Text(
                    "Où en êtes-vous dans votre cycle de sérénité ?",
                    style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Choisissez le parcours qui vous correspond le mieux.",
                    style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = constraints.maxWidth;
                      final center = size / 2;
                      final radius = size / 2 * 0.9;

                      // Helper to position widgets
                      Widget positionImage(
                          double angleDeg, String assetPath, AppCategory category) {
                        // Angle in degrees from 3 o'clock
                        final angleRad = angleDeg * pi / 180;
                        // Distance from center (e.g. 60% of radius)
                        final dist = radius * 0.6;

                        final dx = center + dist * cos(angleRad);
                        final dy = center + dist * sin(angleRad);

                        final isSelected = _selectedCategory == category;

                        return Positioned(
                          left: dx - 40, // 40 is half of image size (80)
                          top: dy - 40,
                          child: IgnorePointer(
                            child: AnimatedScale(
                              scale: isSelected ? 1.2 : 1.0,
                              duration: const Duration(milliseconds: 300),
                              child: Image.asset(
                                assetPath,
                                width: 80,
                                height: 80,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        );
                      }

                      return GestureDetector(
                        onTapUp: (details) {
                          _handleTap(details, constraints.maxWidth);
                        },
                        child: Stack(
                          children: [
                            CustomPaint(
                              size: Size(constraints.maxWidth, constraints.maxWidth),
                              painter: CategoryWheelPainter(
                                selectedCategory: _selectedCategory,
                                animationValue: _controller.value,
                              ),
                            ),
                            // Future Maman: Top (-90°)
                            positionImage(-90, AppCategory.futureMaman.assetPath,
                                AppCategory.futureMaman),
                            // Nouvelle Maman: Bottom Right (30°)
                            positionImage(30, AppCategory.nouvelleMaman.assetPath,
                                AppCategory.nouvelleMaman),
                            // Serenite: Bottom Left (150°)
                            positionImage(
                                150,
                                AppCategory.sereniteQuotidienne.assetPath,
                                AppCategory.sereniteQuotidienne),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Selected Category Description
            AnimatedOpacity(
              opacity: _selectedCategory != null ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  children: [
                    Text(
                      _selectedCategory?.displayName ?? "",
                      style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedCategory?.description ?? "",
                      style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            height: 1.5,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Continue Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      _selectedCategory != null && !_isLoading ? _onContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Confirmer",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTap(TapUpDetails details, double size) {
    final center = Offset(size / 2, size / 2);
    final touchPoint = details.localPosition;
    final dy = touchPoint.dy - center.dy;
    final dx = touchPoint.dx - center.dx;

    double angle = atan2(dy, dx);
    // angle is now -pi to pi relative to 3 o'clock

    // Normalize to 0-2pi
    if (angle < 0) {
      angle += 2 * pi;
    }

    // Now angle is 0 to 2pi starting at 3 o'clock going clockwise

    // Let's convert touch angle to be relative to Top (0)
    double angleFromTop = angle + pi / 2;
    if (angleFromTop < 0) angleFromTop += 2 * pi;
    if (angleFromTop > 2 * pi) angleFromTop -= 2 * pi;

    // Now 0 is Top, increasing clockwise.
    // Top segment: 300° to 60°.
    // Right segment: 60° to 180°.
    // Left segment: 180° to 300°.

    AppCategory selected;
    double deg = angleFromTop * 180 / pi;

    if (deg >= 300 || deg < 60) {
      selected = AppCategory.futureMaman;
    } else if (deg >= 60 && deg < 180) {
      selected = AppCategory.nouvelleMaman;
    } else {
      selected = AppCategory.sereniteQuotidienne;
    }

    _onCategorySelected(selected);
  }
}

class CategoryWheelPainter extends CustomPainter {
  final AppCategory? selectedCategory;
  final double animationValue;

  CategoryWheelPainter({
    required this.selectedCategory,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 * 0.9;

    // Draw 3 segments
    // Future Maman: Top (300° to 60°)
    // Nouvelle Maman: Right (60° to 180°)
    // Serenite: Left (180° to 300°)

    // Angles in radians (starting from 3 o'clock = 0)
    // Top is -90° (-pi/2)

    // Future Maman: -90 - 60 = -150° to -90 + 60 = -30°
    // Rad: -5pi/6 to -pi/6
    _drawSegment(
      canvas,
      center,
      radius,
      -5 * pi / 6,
      2 * pi / 3,
      AppCategory.futureMaman,
    );

    // Nouvelle Maman: -30° to 90°
    // Rad: -pi/6 to pi/2
    _drawSegment(
      canvas,
      center,
      radius,
      -pi / 6,
      2 * pi / 3,
      AppCategory.nouvelleMaman,
    );

    // Serenite: 90° to 210°
    // Rad: pi/2 to 7pi/6
    _drawSegment(
      canvas,
      center,
      radius,
      pi / 2,
      2 * pi / 3,
      AppCategory.sereniteQuotidienne,
    );
  }

  void _drawSegment(Canvas canvas, Offset center, double radius,
      double startAngle, double sweepAngle, AppCategory category) {
    final isSelected = selectedCategory == category;
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = category.color;

    if (isSelected) {
      // Highlight effect
      paint.color = Color.lerp(category.color, Colors.white, 0.3)!;
    }

    // Draw arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      true,
      paint,
    );

    // Draw border
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white
      ..strokeWidth = 4;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      true,
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CategoryWheelPainter oldDelegate) {
    return oldDelegate.selectedCategory != selectedCategory ||
        oldDelegate.animationValue != animationValue;
  }
}
