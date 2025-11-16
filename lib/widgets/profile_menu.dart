import 'package:flutter/material.dart';
import '../models/theme_config.dart';
import '../services/preferences_service.dart';
import '../services/notification_service.dart';

class ProfileMenu extends StatefulWidget {
  final AppTheme currentTheme;
  final ValueChanged<AppTheme> onThemeChanged;

  const ProfileMenu({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
  });

  @override
  State<ProfileMenu> createState() => _ProfileMenuState();
}

class _ProfileMenuState extends State<ProfileMenu> {
  bool _notificationsEnabled = true;
  String? _userName;
  DateTime? _dateOfBirth;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final enabled = await PreferencesService.areNotificationsEnabled();
    final name = await PreferencesService.getUserName();
    final dob = await PreferencesService.getDateOfBirth();
    setState(() {
      _notificationsEnabled = enabled;
      _userName = name;
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
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choisir un thème',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            // Color themes section
            Text(
              'Couleurs',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 24,
              children: colorThemes.map((theme) {
                return _buildThemeButton(theme);
              }).toList(),
            ),
            const SizedBox(height: 32),
            // Seasonal themes section
            Text(
              'Saisons',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 24,
              children: seasonalThemes.map((theme) {
                return _buildThemeButton(theme);
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildThemeButton(AppTheme appTheme) {
    final config = ThemeConfig.themes[appTheme]!;
    final isSelected = widget.currentTheme == appTheme;
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () {
        widget.onThemeChanged(appTheme);
        Navigator.pop(context);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  config.primary,
                  config.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? config.primary
                    : Colors.transparent,
                width: isSelected ? 3 : 0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: config.primary.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 32,
                  )
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            config.name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // User info section
          if (_userName != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                    child: Icon(
                      Icons.person,
                      color: theme.colorScheme.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userName!,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        if (_dateOfBirth != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${_calculateAge(_dateOfBirth)} ans',
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 32),
          ],
          // Thème
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.palette,
                color: theme.colorScheme.primary,
              ),
            ),
            title: const Text('Thème'),
            subtitle: Text(
              ThemeConfig.themes[widget.currentTheme]!.name,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showThemeSelector,
          ),
          // Notifications
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.notifications,
                color: theme.colorScheme.secondary,
              ),
            ),
            title: const Text('Notifications'),
            subtitle: Text(
              _notificationsEnabled
                  ? 'Citation à 9h • Rappel à 22h'
                  : 'Notifications désactivées',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: _toggleNotifications,
              activeThumbColor: theme.colorScheme.primary,
            ),
          ),
          // Test de notification
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.bug_report,
                color: theme.colorScheme.secondary,
              ),
            ),
            title: const Text('Tester les notifications'),
            subtitle: Text(
              'Envoyer toutes les notifications de test',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            trailing: const Icon(Icons.send),
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
          const Divider(height: 32),
          // À propos (optionnel)
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.info_outline,
                color: theme.colorScheme.tertiary,
              ),
            ),
            title: const Text('À propos'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Mes Petits Pas'),
                  content: const Text(
                    'Une application pour vous accompagner dans votre parcours post-partum. Chaque petit pas compte.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Fermer'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

