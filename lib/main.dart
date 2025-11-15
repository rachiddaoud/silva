import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'models/theme_config.dart';
import 'services/preferences_service.dart';
import 'services/notification_service.dart';
import 'app_navigator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser les notifications
  await NotificationService.initialize();
  await NotificationService.requestPermissions();
  await NotificationService.scheduleDailyNotification();
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AppTheme _currentTheme = AppTheme.babyBlue;
  bool _isOnboardingComplete = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Load theme and onboarding status
    final theme = await PreferencesService.getTheme();
    final onboardingComplete = await PreferencesService.isOnboardingComplete();
    
    setState(() {
      _currentTheme = theme;
      _isOnboardingComplete = onboardingComplete;
      _isLoading = false;
    });
  }

  void _onThemeChanged(AppTheme theme) {
    setState(() {
      _currentTheme = theme;
    });
    PreferencesService.setTheme(theme);
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
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('fr', 'FR'),
      home: _isLoading
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : _isOnboardingComplete
              ? HomeScreen(
                  onThemeChanged: _onThemeChanged,
                  currentTheme: _currentTheme,
                )
              : OnboardingScreen(
                  onComplete: _onOnboardingComplete,
                ),
    );
  }
}
