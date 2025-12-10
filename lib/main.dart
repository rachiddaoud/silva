import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart'; // Now contains LoginScreen
import 'screens/onboarding_screen.dart';
import 'models/theme_config.dart';
import 'models/app_category.dart';
import 'services/preferences_service.dart';
import 'services/notification_service.dart';
import 'app_navigator.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import '../l10n/app_localizations.dart';
import 'services/analytics_service.dart';
import 'package:home_widget/home_widget.dart';
import 'services/home_widget_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Initialize analytics service
  await AnalyticsService.instance.init();
  // Initialize HomeWidget with app group ID
  await HomeWidget.setAppGroupId(HomeWidgetService.appGroupId);
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
  Locale? _locale;
  AppCategory? _currentCategory;

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
    final localeFuture = PreferencesService.getLocale();
    final categoryFuture = PreferencesService.getAppCategory();
    
    final results = await Future.wait([
      themeFuture,
      localeFuture,
      categoryFuture,
    ]);
    
    final theme = results[0] as AppTheme;
    final localeCode = results[1] as String?;
    final category = results[2] as AppCategory?;
    
    notificationFuture.then((_) {
      debugPrint('Notifications initialized');
    });
    
    // Check if user is logged in via Firebase
    final currentUser = FirebaseAuth.instance.currentUser;
    final bool isLoggedIn = currentUser != null;

    // Set analytics user ID and properties if logged in
    if (currentUser != null) {
      await AnalyticsService.instance.setUserId(currentUser.uid);
      await AnalyticsService.instance.setUserProperties(
        email: currentUser.email,
        locale: localeCode,
      );
    }

    // Track app open
    await AnalyticsService.instance.logEvent(
      name: AnalyticsEvents.appOpen,
    );

    // Listen to auth state changes for analytics
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        await AnalyticsService.instance.setUserId(user.uid);
        await AnalyticsService.instance.setUserProperties(
          email: user.email,
          locale: localeCode,
        );
        // Reload category if user changes (e.g. login)
        final cat = await PreferencesService.getAppCategory();
        if (mounted) {
           setState(() {
             _isOnboardingComplete = true;
             _currentCategory = cat;
           });
        }
      } else {
        await AnalyticsService.instance.setUserId(null);
        if (mounted) {
           setState(() {
             _isOnboardingComplete = false;
             _currentCategory = null;
           });
        }
      }
    });

    if (mounted) {
      setState(() {
        _currentTheme = theme;
        _locale = localeCode != null ? Locale(localeCode) : null;
        _isOnboardingComplete = isLoggedIn;
        _currentCategory = category;
        _isLoading = false;
      });
    }
  }

  Future<void> _initNotifications() async {
    await NotificationService.initialize();
    // Request permissions might show a dialog, so maybe do this later or check if already granted
    // For now, we keep the original flow but non-blocking for the main UI
    final permissionGranted = await NotificationService.requestPermissions();
    debugPrint('🔔 Notification permissions granted: $permissionGranted');
    
    // Check and request exact alarm permission (Android 12+)
    final canScheduleExact = await NotificationService.canScheduleExactAlarms();
    if (!canScheduleExact) {
      debugPrint('⚠️ Exact alarms not allowed, requesting permission...');
      await NotificationService.requestExactAlarmPermission();
    }
    
    await NotificationService.scheduleDailyNotification();
    await NotificationService.scheduleMorningNotification();
    await NotificationService.scheduleDayReminders();
    
    // Debug: Print all pending notifications
    await NotificationService.debugPrintPendingNotifications();
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
    // This is called when login is successful.
    // We need to check if category is set.
    // Since we just logged in, we might need to fetch it.
    PreferencesService.getAppCategory().then((category) {
      if (mounted) {
        setState(() {
          _isOnboardingComplete = true;
          _currentCategory = category;
        });
      }
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
          : !_isOnboardingComplete
              ? LoginScreen(
                  onLoginSuccess: _onOnboardingComplete,
                )
              : _currentCategory == null
                  ? const OnboardingScreen()
                  : HomeScreen(
                      onThemeChanged: _onThemeChanged,
                      onLocaleChanged: _onLocaleChanged,
                      currentTheme: _currentTheme,
                      currentLocale: _locale,
                    ),
    );
  }
}
