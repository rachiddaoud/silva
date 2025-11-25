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
import '../utils/quotes_data.dart';
import '../l10n/app_localizations.dart';
import '../l10n/app_localizations_en.dart';
import '../l10n/app_localizations_fr.dart';
import 'package:flutter/widgets.dart';
import '../utils/localization_utils.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static const platform = MethodChannel('com.silva/notifications');
  
  // Callback pour gérer la navigation depuis la notification
  static VoidCallback? onNotificationTappedCallback;
  
  // Constantes pour identifier le type de notification
  static const String _morningNotificationType = 'morning_quote';
  static const String _eveningNotificationType = 'evening_reminder';
  static const String _dayReminderNotificationType = 'day_reminder';
  
  // Constantes pour les actions de notification
  static const String _actionCompleteNow = 'action_complete_now';
  static const String _actionMarkDone = 'action_mark_done';

  // Get current locale code from preferences
  static Future<String> _getLocaleCode() async {
    final localeCode = await PreferencesService.getLocale();
    return localeCode ?? 'fr'; // Default to French
  }

  // Create appropriate AppLocalizations instance
  static AppLocalizations _getLocalizations(String localeCode) {
    final locale = Locale(localeCode);
    if (localeCode == 'en') {
      return AppLocalizationsEn();
    }
    return AppLocalizationsFr();
  }

  // Get current quote in the appropriate language
  static Future<String> _getCurrentQuote() async {
    final localeCode = await _getLocaleCode();
    final quotes = getDailyQuotes(localeCode);
    final dayOfYear = DateTime.now().difference(
      DateTime(DateTime.now().year, 1, 1),
    ).inDays;
    return quotes[dayOfYear % quotes.length];
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

    // Les catégories d'actions iOS sont configurées nativement dans AppDelegate.swift
    // Pas besoin d'appel de méthode channel ici
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

    // Get locale and localizations
    final localeCode = await _getLocaleCode();
    final l10n = _getLocalizations(localeCode);
    
    // Get user name
    final userName = await PreferencesService.getUserName();
    final name = userName ?? (localeCode == 'en' ? 'you' : 'vous');
    
    // Format message
    final title = l10n.notifFinishDay;
    final body = l10n.notifFinishDayBody(name);

    await _notifications.zonedSchedule(
      0,
      title,
      body,
      _nextInstanceOf22PM(),
      NotificationDetails(
        android: AndroidNotificationDetails(
         'daily_reminder',
          localeCode == 'en' ? 'Daily reminder' : 'Rappel quotidien',
          channelDescription: localeCode == 'en' ? 'Reminder to finish the day at 10 PM' : 'Rappel pour terminer la journée à 22h',
          importance: Importance.high,
          priority: Priority.high,
          actions: [
            AndroidNotificationAction(
              _actionCompleteNow,
              l10n.notifFinishNow,
              showsUserInterface: true,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
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

    // Get locale and localizations
    final localeCode = await _getLocaleCode();
    final l10n = _getLocalizations(localeCode);
    
    // Get user name
    final userName = await PreferencesService.getUserName();
    final name = userName ?? (localeCode == 'en' ? 'you' : 'vous');
    
    // Get quote of the day
    final quote = await _getCurrentQuote();
    
    // Format message
    final title = l10n.notifGoodMorning(name);
    final body = l10n.notifQuoteOfDay(quote);

    await _notifications.zonedSchedule(
      1, // Different ID from evening notification (0)
      title,
      body,
      _nextInstanceOf9AM(),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'morning_quote',
          localeCode == 'en' ? 'Morning quote' : 'Citation du matin',
          channelDescription: localeCode == 'en' ? 'Quote of the day at 9 AM' : 'Citation du jour à 9h du matin',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
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

    // Get locale and localizations
    final localeCode = await _getLocaleCode();
    final l10n = _getLocalizations(localeCode);
    
    // Get today's victories
    final victories = await PreferencesService.getTodayVictories();
    final unaccomplishedVictories = victories.where((v) => !v.isAccomplished).toList();
    
    // If all victories are accomplished, don't schedule reminders
    if (unaccomplishedVictories.isEmpty) {
      await cancelDayReminders();
      return;
    }

    final random = Random();
    final userName = await PreferencesService.getUserName();
    final name = userName ?? (localeCode == 'en' ? 'you' : 'vous');

    // First notification at 12 PM
    final selectedVictory1 = unaccomplishedVictories[random.nextInt(unaccomplishedVictories.length)];
    final victoryText1 = getVictoryReminderTextByLocale(localeCode, selectedVictory1.id);
    
    await _notifications.zonedSchedule(
      2,
      l10n.notifReminder,
      l10n.notifReminderBody(name, victoryText1),
      _nextInstanceOf12PM(),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'day_reminder',
          localeCode == 'en' ? 'Day reminder' : 'Rappel de la journée',
          channelDescription: localeCode == 'en' ? 'Reminders for daily actions' : 'Rappels pour les actions de la journée',
          importance: Importance.high,
          priority: Priority.high,
          actions: [
            AndroidNotificationAction(
              _actionMarkDone,
              l10n.notifActionDone,
              showsUserInterface: true,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
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

    // Second notification at 5 PM
    final remainingVictories = unaccomplishedVictories
        .where((v) => v.id != selectedVictory1.id)
        .toList();
    final selectedVictory2 = remainingVictories.isNotEmpty
        ? remainingVictories[random.nextInt(remainingVictories.length)]
        : unaccomplishedVictories[random.nextInt(unaccomplishedVictories.length)];
    final victoryText2 = getVictoryReminderTextByLocale(localeCode, selectedVictory2.id);

    await _notifications.zonedSchedule(
      3,
      l10n.notifReminder,
      l10n.notifReminderBody(name, victoryText2),
      _nextInstanceOf5PM(),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'day_reminder',
          localeCode == 'en' ? 'Day reminder' : 'Rappel de la journée',
          channelDescription: localeCode == 'en' ? 'Reminders for daily actions' : 'Rappels pour les actions de la journée',
          importance: Importance.high,
          priority: Priority.high,
          actions: [
            AndroidNotificationAction(
              _actionMarkDone,
              l10n.notifActionDone,
              showsUserInterface: true,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
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
    // Get locale and localizations
    final localeCode = await _getLocaleCode();
    final l10n = _getLocalizations(localeCode);
    
    // Get user name
    final userName = await PreferencesService.getUserName();
    final name = userName ?? (localeCode == 'en' ? 'you' : 'vous');
    
    // Get quote of the day
    final quote = await _getCurrentQuote();
    
    // Get today's victories for reminders
    final victories = await PreferencesService.getTodayVictories();
    final unaccomplishedVictories = victories.where((v) => !v.isAccomplished).toList();
    final random = Random();
    
    // If all victories are accomplished, use all victories
    final availableVictories = unaccomplishedVictories.isNotEmpty 
        ? unaccomplishedVictories 
        : victories;
    
    // Select two different victories for reminders
    final selectedVictory1 = availableVictories[random.nextInt(availableVictories.length)];
    final victoryText1 = getVictoryReminderTextByLocale(localeCode, selectedVictory1.id);
    
    final remainingVictories = availableVictories
        .where((v) => v.id != selectedVictory1.id)
        .toList();
    final selectedVictory2 = remainingVictories.isNotEmpty
        ? remainingVictories[random.nextInt(remainingVictories.length)]
        : selectedVictory1;
    final victoryText2 = getVictoryReminderTextByLocale(localeCode, selectedVictory2.id);
    
    // 1. Morning notification (quote of the day)
    await _notifications.show(
      998, // Different ID to not interfere with scheduled notifications
      l10n.notifGoodMorning(name),
      l10n.notifQuoteOfDay(quote),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'morning_quote',
          localeCode == 'en' ? 'Morning quote' : 'Citation du matin',
          channelDescription: localeCode == 'en' ? 'Quote of the day at 9 AM' : 'Citation du jour à 9h du matin',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: _morningNotificationType,
    );
    
    // Wait a bit before showing the next notification
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 2. Day reminder at 12 PM
    await _notifications.show(
      997, // Different ID to not interfere with scheduled notifications
      l10n.notifReminder,
      l10n.notifReminderBody(name, victoryText1),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'day_reminder',
          localeCode == 'en' ? 'Day reminder' : 'Rappel de la journée',
          channelDescription: localeCode == 'en' ? 'Reminders for daily actions' : 'Rappels pour les actions de la journée',
          importance: Importance.high,
          priority: Priority.high,
          actions: [
            AndroidNotificationAction(
              _actionMarkDone,
              l10n.notifActionDone,
              showsUserInterface: true,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: 'DAY_REMINDER',
        ),
      ),
      payload: '$_dayReminderNotificationType|${selectedVictory1.id}',
    );
    
    // Wait a bit before showing the next notification
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 3. Day reminder at 5 PM
    await _notifications.show(
      996, // Different ID to not interfere with scheduled notifications
      l10n.notifReminder,
      l10n.notifReminderBody(name, victoryText2),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'day_reminder',
          localeCode == 'en' ? 'Day reminder' : 'Rappel de la journée',
          channelDescription: localeCode == 'en' ? 'Reminders for daily actions' : 'Rappels pour les actions de la journée',
          importance: Importance.high,
          priority: Priority.high,
          actions: [
            AndroidNotificationAction(
              _actionMarkDone,
              l10n.notifActionDone,
              showsUserInterface: true,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: 'DAY_REMINDER',
        ),
      ),
      payload: '$_dayReminderNotificationType|${selectedVictory2.id}',
    );
    
    // Wait a bit before showing the next notification
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 4. Evening notification (daily reminder)
    await _notifications.show(
      999, // Different ID to not interfere with scheduled notifications
      l10n.notifFinishDay,
      l10n.notifFinishDayBody(name),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          localeCode == 'en' ? 'Daily reminder' : 'Rappel quotidien',
          channelDescription: localeCode == 'en' ? 'Reminder to finish the day at 10 PM' : 'Rappel pour terminer la journée à 22h',
          importance: Importance.high,
          priority: Priority.high,
          actions: [
            AndroidNotificationAction(
              _actionCompleteNow,
              l10n.notifFinishNow,
              showsUserInterface: true,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
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

