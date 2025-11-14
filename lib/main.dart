import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final theme = await PreferencesService.getTheme();
    setState(() {
      _currentTheme = theme;
    });
  }

  void _onThemeChanged(AppTheme theme) {
    setState(() {
      _currentTheme = theme;
    });
    PreferencesService.setTheme(theme);
  }

  @override
  Widget build(BuildContext context) {
    final themeConfig = ThemeConfig.themes[_currentTheme]!;
    
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Mes Petits Pas',
      theme: themeConfig.toThemeData(),
      home: HomeScreen(
        onThemeChanged: _onThemeChanged,
        currentTheme: _currentTheme,
      ),
    );
  }
}
