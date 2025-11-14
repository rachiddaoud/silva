import 'package:shared_preferences/shared_preferences.dart';
import '../models/theme_config.dart';

class PreferencesService {
  static const String _themeKey = 'selected_theme';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _historyKey = 'day_history';
  static const String _lastResetDateKey = 'last_reset_date';

  // Thème
  static Future<AppTheme> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? 0;
    return AppTheme.values[themeIndex];
  }

  static Future<void> setTheme(AppTheme theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, theme.index);
  }

  // Notifications
  static Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  static Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
  }

  // Historique (pour futur usage)
  static Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_historyKey);
    if (historyJson == null) return [];
    // Pour l'instant, retourner une liste vide ou mock
    // Future: parser le JSON
    return [];
  }

  static Future<void> saveDayEntry(Map<String, dynamic> entry) async {
    final history = await getHistory();
    history.add(entry);
    // Future: sérialiser en JSON et sauvegarder avec SharedPreferences
    // Pour l'instant, on ne sauvegarde pas vraiment
  }

  // Date de dernière réinitialisation des victoires
  static Future<DateTime?> getLastResetDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString(_lastResetDateKey);
    if (dateString == null) return null;
    return DateTime.parse(dateString);
  }

  static Future<void> setLastResetDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastResetDateKey, date.toIso8601String());
  }

  static Future<bool> shouldResetVictories() async {
    final lastReset = await getLastResetDate();
    if (lastReset == null) return true;
    
    final now = DateTime.now();
    // Vérifier si on est passé à un nouveau jour
    return now.year != lastReset.year ||
        now.month != lastReset.month ||
        now.day != lastReset.day;
  }
}

