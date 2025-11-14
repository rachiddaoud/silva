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
    // Appeler le callback personnalisé si défini (défini par HomeScreen)
    // Ce callback utilisera les victoires actuelles du HomeScreen
    if (onNotificationTappedCallback != null) {
      onNotificationTappedCallback!();
      return;
    }
    
    // Fallback : naviguer avec des victoires par défaut si le callback n'est pas défini
    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      // Créer les victoires par défaut pour l'écran de complétion
      final victories = VictoryCard.getDefaultVictories();
      
      // Naviguer vers l'écran de complétion
      navigator.push(
        MaterialPageRoute(
          builder: (context) => DayCompletionScreen(
            victories: victories,
            onComplete: (Emotion emotion, String comment) {
              // Callback simple qui ferme juste l'écran
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
      return;
    }

    await _notifications.zonedSchedule(
      0,
      'Terminer votre journée',
      'N\'oubliez pas de terminer votre journée et de noter votre humeur !',
      _nextInstanceOf22PM(),
      const NotificationDetails(
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

  static Future<void> showTestNotification() async {
    await _notifications.show(
      999, // ID différent pour ne pas interférer avec la notification programmée
      'Terminer votre journée',
      'N\'oubliez pas de terminer votre journée et de noter votre humeur !',
      const NotificationDetails(
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
    );
  }
}

