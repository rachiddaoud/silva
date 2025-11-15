import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/theme_config.dart';
import '../models/day_entry.dart';
import '../models/emotion.dart';
import '../models/victory_card.dart';

class PreferencesService {
  static const String _themeKey = 'selected_theme';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _historyKey = 'day_history';
  static const String _lastResetDateKey = 'last_reset_date';
  static const String _userNameKey = 'user_name';
  static const String _dateOfBirthKey = 'date_of_birth';
  static const String _onboardingCompleteKey = 'onboarding_complete';

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

  // Historique
  static Future<List<DayEntry>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_historyKey);
    if (historyJson == null) return [];
    
    try {
      final List<dynamic> jsonList = jsonDecode(historyJson);
      return jsonList
          .map((json) => DayEntry.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // En cas d'erreur de parsing, retourner une liste vide
      return [];
    }
  }

  static Future<void> saveDayEntry(DayEntry entry) async {
    final history = await getHistory();
    
    // Vérifier si une entrée existe déjà pour cette date
    final existingIndex = history.indexWhere((e) =>
        e.date.year == entry.date.year &&
        e.date.month == entry.date.month &&
        e.date.day == entry.date.day);
    
    if (existingIndex >= 0) {
      // Remplacer l'entrée existante
      history[existingIndex] = entry;
    } else {
      // Ajouter la nouvelle entrée
      history.add(entry);
    }
    
    // Sérialiser en JSON et sauvegarder
    final prefs = await SharedPreferences.getInstance();
    final jsonList = history.map((e) => e.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(jsonList));
  }

  // Initialiser les données mock d'une semaine (seulement si l'historique est vide)
  static Future<void> initializeMockData() async {
    final history = await getHistory();
    if (history.isNotEmpty) return; // Ne pas écraser les données existantes

    final now = DateTime.now();
    final defaultVictories = VictoryCard.getDefaultVictories();
    final random = Random();
    
    // Liste de commentaires possibles
    final possibleComments = [
      'Très belle journée, je me sens vraiment bien !',
      'Journée tranquille, quelques moments de repos.',
      'Journée difficile mais j\'ai tenu bon.',
      'Belle énergie aujourd\'hui !',
      'Petit à petit, jour après jour.',
      'J\'ai fait de mon mieux aujourd\'hui.',
      'Quelques moments difficiles mais j\'ai réussi à tenir.',
      'Journée calme et reposante.',
      'Je suis fière de mes petits pas.',
      'Chaque victoire compte, même les plus petites.',
      'J\'ai pris soin de moi aujourd\'hui.',
      'Journée chargée mais j\'ai géré.',
      null, // Parfois pas de commentaire
      null,
    ];
    
    final mockEntries = <DayEntry>[];
    
    // Générer des données pour les 7 derniers jours
    // Garantir qu'au moins 4 jours sur 7 sont remplis
    final filledDaysCount = random.nextInt(4) + 4; // Entre 4 et 7 jours remplis
    final filledDaysIndices = <int>{};
    
    // Choisir aléatoirement quels jours seront remplis
    while (filledDaysIndices.length < filledDaysCount) {
      filledDaysIndices.add(random.nextInt(7));
    }
    
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i + 1));
      final isFilled = filledDaysIndices.contains(i);
      
      if (isFilled) {
        // Choisir une émotion aléatoire
        final emotionIndex = random.nextInt(Emotion.emotions.length);
        final emotion = Emotion.emotions[emotionIndex];
        
        // Choisir un commentaire aléatoire (ou null)
        final commentIndex = random.nextInt(possibleComments.length);
        final comment = possibleComments[commentIndex];
        
        // Choisir un nombre aléatoire de victoires (entre 2 et 7)
        final numVictories = random.nextInt(6) + 2; // 2 à 7 victoires
        final shuffledVictories = List<VictoryCard>.from(defaultVictories);
        shuffledVictories.shuffle(random);
        final selectedVictories = shuffledVictories.take(numVictories).toList();
        
        mockEntries.add(DayEntry(
          date: date,
          emotion: emotion,
          comment: comment,
          victoryCards: selectedVictories,
        ));
      } else {
        // Jour vide
        mockEntries.add(DayEntry(
          date: date,
          emotion: null,
          comment: null,
          victoryCards: [],
        ));
      }
    }

    // Sauvegarder les données mock
    final prefs = await SharedPreferences.getInstance();
    final jsonList = mockEntries.map((e) => e.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(jsonList));
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

  // User name
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  static Future<void> setUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
  }

  // Date of birth
  static Future<DateTime?> getDateOfBirth() async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString(_dateOfBirthKey);
    if (dateString == null) return null;
    return DateTime.parse(dateString);
  }

  static Future<void> setDateOfBirth(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dateOfBirthKey, date.toIso8601String());
  }

  // Onboarding completion
  static Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompleteKey) ?? false;
  }

  static Future<void> setOnboardingComplete(bool complete) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompleteKey, complete);
  }
}

