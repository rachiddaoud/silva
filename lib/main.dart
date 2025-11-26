import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart'; // Now contains LoginScreen
import 'models/theme_config.dart';
import 'services/preferences_service.dart';
import 'services/notification_service.dart';
import 'app_navigator.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import '../l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AppTheme _currentTheme = AppTheme.modernPastel;
  bool _isOnboardingComplete = false;
  bool _isLoading = true;
  Locale? _locale; // null means use system default

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Start notification initialization in parallel
    final notificationFuture = _initNotifications();
    
    // Load theme, onboarding status, and locale
    final themeFuture = PreferencesService.getTheme();
    final onboardingFuture = PreferencesService.isOnboardingComplete();
    final localeFuture = PreferencesService.getLocale();
    
    final results = await Future.wait([
      themeFuture,
      onboardingFuture,
      localeFuture,
      // We don't strictly need to wait for notifications to show the UI,
      // but we wait here to ensure everything is ready before potentially
      // showing the home screen. If this takes too long, we could remove
      // it from this wait and let it complete in background.
    ]);
    
    final theme = results[0] as AppTheme;
    final localeCode = results[2] as String?;
    // Note: onboardingComplete (results[1]) is intentionally not used
    // We rely solely on Firebase auth status, not local preferences
    
    // Ensure notifications are initialized (if not already by the wait above, 
    // though we didn't await notificationFuture in the list, let's just let it run)
    // Actually, let's just let notifications init in background to not block UI
    notificationFuture.then((_) {
      debugPrint('Notifications initialized');
    });
    
    // Check if user is logged in via Firebase
    final currentUser = FirebaseAuth.instance.currentUser;
    final bool isLoggedIn = currentUser != null;

    if (mounted) {
      setState(() {
        _currentTheme = theme;
        _locale = localeCode != null ? Locale(localeCode) : null;
        // Strictly check for login status. 
        // We ignore the local 'onboardingComplete' preference to ensure 
        // users must be authenticated via Firebase.
        _isOnboardingComplete = isLoggedIn;
        _isLoading = false;
      });
    }
  }

  Future<void> _initNotifications() async {
    await NotificationService.initialize();
    // Request permissions might show a dialog, so maybe do this later or check if already granted
    // For now, we keep the original flow but non-blocking for the main UI
    await NotificationService.requestPermissions();
    await NotificationService.scheduleDailyNotification();
    await NotificationService.scheduleMorningNotification();
  }

  void _onThemeChanged(AppTheme theme) {
    setState(() {
      _currentTheme = theme;
    });
    PreferencesService.setTheme(theme);
  }

  void _onLocaleChanged(Locale? locale) {
    setState(() {
      _locale = locale;
    });
    PreferencesService.setLocale(locale?.languageCode);
  }

  void _onOnboardingComplete() {
    setState(() {
      _isOnboardingComplete = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeConfig = ThemeConfig.themes[_currentTheme]!;
    
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Mes Petits Pas',
      theme: themeConfig.toThemeData(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: _locale, // Use saved locale or null for system default
      // locale: const Locale('fr', 'FR'), // Removed to allow system locale or user selection
      home: _isLoading
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            )
              : _isOnboardingComplete
                  ? HomeScreen(
                      onThemeChanged: _onThemeChanged,
                      onLocaleChanged: _onLocaleChanged,
                      currentTheme: _currentTheme,
                      currentLocale: _locale,
                    )
                  : LoginScreen(
                      onLoginSuccess: _onOnboardingComplete,
                    ),
    );
  }
}
