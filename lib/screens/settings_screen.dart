import 'package:flutter/material.dart';
import '../models/theme_config.dart';
import '../services/preferences_service.dart';
import '../services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import '../l10n/app_localizations.dart';

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
  String? _userName;
  String? _photoURL;
  DateTime? _dateOfBirth;
  late AppTheme _currentTheme;
  late Locale? _currentLocale;

  @override
  void initState() {
    super.initState();
    _currentTheme = widget.currentTheme;
    _currentLocale = widget.currentLocale;
    _loadData();
  }

  Future<void> _loadData() async {
    final enabled = await PreferencesService.areNotificationsEnabled();
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? await PreferencesService.getUserName();
    final photoURL = user?.photoURL;
    final dob = await PreferencesService.getDateOfBirth();
    setState(() {
      _notificationsEnabled = enabled;
      _userName = name;
      _photoURL = photoURL;
      _dateOfBirth = dob;
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
    setState(() {
      _notificationsEnabled = value;
    });
    await PreferencesService.setNotificationsEnabled(value);
    if (value) {
      await NotificationService.scheduleDailyNotification();
      await NotificationService.scheduleMorningNotification();
    } else {
      await NotificationService.cancelDailyNotification();
      await NotificationService.cancelMorningNotification();
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
      AppTheme.beach,
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

  Widget _buildLanguageOption(Locale? locale, String label) {
    final isSelected = (_currentLocale?.languageCode == locale?.languageCode) &&
                       (_currentLocale == null && locale == null ||
                        _currentLocale != null && locale != null);
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: () {
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
                  icon: Icons.bug_report_outlined,
                  title: AppLocalizations.of(context)!.testNotifications,
                  subtitle: AppLocalizations.of(context)!.sendTest,
                  color: theme.colorScheme.tertiary,
                  onTap: () async {
                    await NotificationService.showTestNotification();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Notifications de test envoyées !'),
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
