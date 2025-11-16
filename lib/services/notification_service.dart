import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'preferences_service.dart';
import '../app_navigator.dart';
import '../screens/day_completion_screen.dart';
import '../models/victory_card.dart';
import '../models/emotion.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  // Callback pour gérer la navigation depuis la notification
  static VoidCallback? onNotificationTappedCallback;
  
  // Constantes pour identifier le type de notification
  static const String _morningNotificationType = 'morning_quote';
  static const String _eveningNotificationType = 'evening_reminder';

  // Citations du jour
  static const List<String> _dailyQuotes = [
    "Vous faites de votre mieux, et c'est suffisant.",
    "Le repos n'est pas une récompense, c'est une nécessité.",
    "Prendre soin de vous, c'est prendre soin de votre bébé.",
  ];

  // Obtenir la citation du jour
  static String _getCurrentQuote() {
    final dayOfYear = DateTime.now().difference(
      DateTime(DateTime.now().year, 1, 1),
    ).inDays;
    return _dailyQuotes[dayOfYear % _dailyQuotes.length];
  }

  static Future<void> initialize() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Paris'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const macosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: macosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  static void _onNotificationTapped(NotificationResponse response) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    
    // Identifier le type de notification via le payload ou l'ID
    final notificationType = response.payload ?? '';
    final notificationId = response.id;
    
    // Notification du matin (ID 1 ou 998) -> naviguer vers l'accueil
    if (notificationId == 1 || notificationId == 998 || notificationType == _morningNotificationType) {
      // Pop toutes les routes jusqu'à la racine (accueil)
      navigator.popUntil((route) => route.isFirst);
      return;
    }
    
    // Notification du soir (ID 0 ou 999) -> naviguer vers l'écran de complétion
    if (notificationId == 0 || notificationId == 999 || notificationType == _eveningNotificationType) {
      // Appeler le callback personnalisé si défini (défini par HomeScreen)
      if (onNotificationTappedCallback != null) {
        onNotificationTappedCallback!();
        return;
      }
      
      // Fallback : naviguer avec des victoires par défaut
      final victories = VictoryCard.getDefaultVictories();
      navigator.push(
        MaterialPageRoute(
          builder: (context) => DayCompletionScreen(
            victories: victories,
            onComplete: (Emotion emotion, String comment) {
              navigator.pop();
            },
          ),
        ),
      );
    }
  }

  static Future<bool> requestPermissions() async {
    final android = await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    final ios = await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    return (android ?? false) || (ios ?? false);
  }

  static Future<void> scheduleDailyNotification() async {
    final enabled = await PreferencesService.areNotificationsEnabled();
    if (!enabled) {
      await cancelDailyNotification();
      await cancelMorningNotification();
      return;
    }

    // Récupérer le nom de l'utilisateur
    final userName = await PreferencesService.getUserName();
    final name = userName ?? 'vous';
    
    // Formater le message avec le nom de l'utilisateur
    final title = 'Terminer votre journée';
    final body = '$name, n\'oubliez pas de terminer votre journée et de noter votre humeur !';

    await _notifications.zonedSchedule(
      0,
      title,
      body,
      _nextInstanceOf22PM(),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Rappel quotidien',
          channelDescription: 'Rappel pour terminer la journée à 22h',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: _eveningNotificationType,
    );
  }

  static tz.TZDateTime _nextInstanceOf22PM() {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      22,
      0,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  static Future<void> cancelDailyNotification() async {
    await _notifications.cancel(0);
  }

  static Future<void> scheduleMorningNotification() async {
    final enabled = await PreferencesService.areNotificationsEnabled();
    if (!enabled) {
      await cancelMorningNotification();
      return;
    }

    // Récupérer le nom de l'utilisateur
    final userName = await PreferencesService.getUserName();
    final name = userName ?? 'vous';
    
    // Récupérer la citation du jour
    final quote = _getCurrentQuote();
    
    // Formater le message avec le nom de l'utilisateur
    final title = 'Bonjour $name !';
    final body = 'Votre citation du jour : $quote';

    await _notifications.zonedSchedule(
      1, // ID différent de la notification du soir (0)
      title,
      body,
      _nextInstanceOf9AM(),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'morning_quote',
          'Citation du matin',
          channelDescription: 'Citation du jour à 9h du matin',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // Ne pas utiliser matchDateTimeComponents car on reprogramme chaque jour
      // pour mettre à jour la citation
      payload: _morningNotificationType,
    );
  }

  static tz.TZDateTime _nextInstanceOf9AM() {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      9,
      0,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  static Future<void> cancelMorningNotification() async {
    await _notifications.cancel(1);
  }

  static Future<void> showTestNotification() async {
    // Récupérer le nom de l'utilisateur
    final userName = await PreferencesService.getUserName();
    final name = userName ?? 'vous';
    
    // Récupérer la citation du jour
    final quote = _getCurrentQuote();
    
    // Notification du matin (citation du jour)
    await _notifications.show(
      998, // ID différent pour ne pas interférer avec les notifications programmées
      'Bonjour $name !',
      'Votre citation du jour : $quote',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'morning_quote',
          'Citation du matin',
          channelDescription: 'Citation du jour à 9h du matin',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: _morningNotificationType,
    );
    
    // Attendre un peu avant d'afficher la deuxième notification
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Notification du soir (rappel quotidien)
    await _notifications.show(
      999, // ID différent pour ne pas interférer avec les notifications programmées
      'Terminer votre journée',
      '$name, n\'oubliez pas de terminer votre journée et de noter votre humeur !',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Rappel quotidien',
          channelDescription: 'Rappel pour terminer la journée à 22h',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: _eveningNotificationType,
    );
  }
}

