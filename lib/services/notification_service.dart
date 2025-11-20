import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'preferences_service.dart';
import '../app_navigator.dart';
import '../screens/day_completion_screen.dart';
import '../models/emotion.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static const platform = MethodChannel('com.ma_bulle/notifications');
  
  // Callback pour gérer la navigation depuis la notification
  static VoidCallback? onNotificationTappedCallback;
  
  // Constantes pour identifier le type de notification
  static const String _morningNotificationType = 'morning_quote';
  static const String _eveningNotificationType = 'evening_reminder';
  static const String _dayReminderNotificationType = 'day_reminder';
  
  // Constantes pour les actions de notification
  static const String _actionCompleteNow = 'action_complete_now';
  static const String _actionMarkDone = 'action_mark_done';

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

    // Enregistrer les catégories d'actions iOS
    await _setupIOSNotificationCategories();
  }

  static Future<void> _setupIOSNotificationCategories() async {
    try {
      await platform.invokeMethod('setupNotificationCategories');
    } catch (e) {
      print('Erreur lors de la configuration des catégories iOS: $e');
    }
  }

  static void _onNotificationTapped(NotificationResponse response) async {
    final navigator = navigatorKey.currentState;
    
    // Identifier le type de notification via le payload ou l'ID
    final notificationType = response.payload ?? '';
    final notificationId = response.id ?? -1;
    final actionId = response.actionId;
    
    // Gérer les actions des notifications de rappel de la journée
    final isDayReminder = notificationId == 2 || 
                         notificationId == 3 || 
                         notificationId == 996 || 
                         notificationId == 997 || 
                         notificationType.startsWith(_dayReminderNotificationType);
    
    if (isDayReminder) {
      if (actionId == _actionMarkDone) {
        // Action "J'ai fait cette action" -> marquer la victoire comme accomplie
        final payload = response.payload ?? '';
        // Le payload contient "day_reminder|victoryId"
        final parts = payload.split('|');
        if (parts.length >= 2) {
          final victoryId = int.tryParse(parts[1]);
          if (victoryId != null) {
            await PreferencesService.markVictoryAsAccomplished(victoryId);
            // Reprogrammer les rappels pour exclure cette victoire
            await scheduleDayReminders();
            // Annuler la notification
            await _notifications.cancel(notificationId);
            // Si l'app est ouverte, retourner à l'accueil pour rafraîchir l'interface
            if (navigator != null) {
              navigator.popUntil((route) => route.isFirst);
            }
          }
        }
        return;
      } else {
        // Tap sur la notification -> ouvrir l'app
        if (navigator != null) {
          navigator.popUntil((route) => route.isFirst);
        }
        return;
      }
    }
    
    // Gérer les actions des notifications du soir
    if (notificationId == 0 || notificationId == 999 || notificationType == _eveningNotificationType) {
      if (actionId == _actionCompleteNow) {
        // Action "Terminer maintenant" -> ouvrir l'écran de complétion
        if (navigator != null) {
          if (onNotificationTappedCallback != null) {
            onNotificationTappedCallback!();
            return;
          }
          
          final victories = await PreferencesService.getTodayVictories();
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
        return;
      } else {
        // Tap sur la notification elle-même (sans action) -> ouvrir l'écran de complétion
        if (navigator != null) {
          if (onNotificationTappedCallback != null) {
            onNotificationTappedCallback!();
            return;
          }
          
          final victories = await PreferencesService.getTodayVictories();
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
        return;
      }
    }
    
    // Notification du matin (ID 1 ou 998) -> naviguer vers l'accueil
    if (notificationId == 1 || notificationId == 998 || notificationType == _morningNotificationType) {
      // Pop toutes les routes jusqu'à la racine (accueil)
      if (navigator != null) {
        navigator.popUntil((route) => route.isFirst);
      }
      return;
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
      await cancelDayReminders();
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
          actions: [
            const AndroidNotificationAction(
              _actionCompleteNow,
              'Terminer maintenant',
              showsUserInterface: true,
            ),
          ],
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: 'EVENING_REMINDER',
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

  static Future<void> scheduleDayReminders() async {
    final enabled = await PreferencesService.areNotificationsEnabled();
    if (!enabled) {
      await cancelDayReminders();
      return;
    }

    // Récupérer les victoires du jour
    final victories = await PreferencesService.getTodayVictories();
    final unaccomplishedVictories = victories.where((v) => !v.isAccomplished).toList();
    
    // Si toutes les victoires sont accomplies, ne pas programmer de rappel
    if (unaccomplishedVictories.isEmpty) {
      await cancelDayReminders();
      return;
    }

    final random = Random();
    final userName = await PreferencesService.getUserName();
    final name = userName ?? 'vous';

    // Première notification à 12h
    final selectedVictory1 = unaccomplishedVictories[random.nextInt(unaccomplishedVictories.length)];
    await _notifications.zonedSchedule(
      2,
      'Petit rappel 💚',
      '$name, n\'oubliez pas : ${selectedVictory1.text}',
      _nextInstanceOf12PM(),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'day_reminder',
          'Rappel de la journée',
          channelDescription: 'Rappels pour les actions de la journée',
          importance: Importance.high,
          priority: Priority.high,
          actions: [
            AndroidNotificationAction(
              _actionMarkDone,
              'J\'ai fait cette action',
              showsUserInterface: true,
            ),
          ],
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: 'DAY_REMINDER',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '$_dayReminderNotificationType|${selectedVictory1.id}',
    );

    // Deuxième notification à 17h
    // Filtrer à nouveau pour exclure la victoire déjà sélectionnée si possible
    final remainingVictories = unaccomplishedVictories
        .where((v) => v.id != selectedVictory1.id)
        .toList();
    final selectedVictory2 = remainingVictories.isNotEmpty
        ? remainingVictories[random.nextInt(remainingVictories.length)]
        : unaccomplishedVictories[random.nextInt(unaccomplishedVictories.length)];

    await _notifications.zonedSchedule(
      3,
      'Petit rappel 💚',
      '$name, n\'oubliez pas : ${selectedVictory2.text}',
      _nextInstanceOf5PM(),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'day_reminder',
          'Rappel de la journée',
          channelDescription: 'Rappels pour les actions de la journée',
          importance: Importance.high,
          priority: Priority.high,
          actions: [
            AndroidNotificationAction(
              _actionMarkDone,
              'J\'ai fait cette action',
              showsUserInterface: true,
            ),
          ],
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: 'DAY_REMINDER',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '$_dayReminderNotificationType|${selectedVictory2.id}',
    );
  }

  static tz.TZDateTime _nextInstanceOf12PM() {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      12,
      0,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  static tz.TZDateTime _nextInstanceOf5PM() {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      17,
      0,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  static Future<void> cancelDayReminders() async {
    await _notifications.cancel(2);
    await _notifications.cancel(3);
  }

  static Future<void> showTestNotification() async {
    // Récupérer le nom de l'utilisateur
    final userName = await PreferencesService.getUserName();
    final name = userName ?? 'vous';
    
    // Récupérer la citation du jour
    final quote = _getCurrentQuote();
    
    // Récupérer les victoires du jour pour les rappels
    final victories = await PreferencesService.getTodayVictories();
    final unaccomplishedVictories = victories.where((v) => !v.isAccomplished).toList();
    final random = Random();
    
    // Si toutes les victoires sont accomplies, utiliser toutes les victoires
    final availableVictories = unaccomplishedVictories.isNotEmpty 
        ? unaccomplishedVictories 
        : victories;
    
    // Sélectionner deux victoires différentes pour les rappels
    final selectedVictory1 = availableVictories[random.nextInt(availableVictories.length)];
    final remainingVictories = availableVictories
        .where((v) => v.id != selectedVictory1.id)
        .toList();
    final selectedVictory2 = remainingVictories.isNotEmpty
        ? remainingVictories[random.nextInt(remainingVictories.length)]
        : selectedVictory1;
    
    // 1. Notification du matin (citation du jour)
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
    
    // Attendre un peu avant d'afficher la notification suivante
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 2. Notification de rappel à 12h
    await _notifications.show(
      997, // ID différent pour ne pas interférer avec les notifications programmées
      'Petit rappel 💚',
      '$name, n\'oubliez pas : ${selectedVictory1.text}',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'day_reminder',
          'Rappel de la journée',
          channelDescription: 'Rappels pour les actions de la journée',
          importance: Importance.high,
          priority: Priority.high,
          actions: [
            AndroidNotificationAction(
              _actionMarkDone,
              'J\'ai fait cette action',
              showsUserInterface: true,
            ),
          ],
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: 'DAY_REMINDER',
        ),
      ),
      payload: '$_dayReminderNotificationType|${selectedVictory1.id}',
    );
    
    // Attendre un peu avant d'afficher la notification suivante
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 3. Notification de rappel à 17h
    await _notifications.show(
      996, // ID différent pour ne pas interférer avec les notifications programmées
      'Petit rappel 💚',
      '$name, n\'oubliez pas : ${selectedVictory2.text}',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'day_reminder',
          'Rappel de la journée',
          channelDescription: 'Rappels pour les actions de la journée',
          importance: Importance.high,
          priority: Priority.high,
          actions: [
            AndroidNotificationAction(
              _actionMarkDone,
              'J\'ai fait cette action',
              showsUserInterface: true,
            ),
          ],
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: 'DAY_REMINDER',
        ),
      ),
      payload: '$_dayReminderNotificationType|${selectedVictory2.id}',
    );
    
    // Attendre un peu avant d'afficher la notification suivante
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 4. Notification du soir (rappel quotidien)
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
          actions: [
            const AndroidNotificationAction(
              _actionCompleteNow,
              'Terminer maintenant',
              showsUserInterface: true,
            ),
          ],
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: 'EVENING_REMINDER',
        ),
      ),
      payload: _eveningNotificationType,
    );
  }
}

