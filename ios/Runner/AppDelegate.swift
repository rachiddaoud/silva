import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Configurer les catégories de notifications avec actions pour iOS
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      
      // Catégorie pour les rappels de la journée
      let markDoneAction = UNNotificationAction(
        identifier: "action_mark_done",
        title: "J'ai fait cette action",
        options: []
      )
      
      let dayReminderCategory = UNNotificationCategory(
        identifier: "DAY_REMINDER",
        actions: [markDoneAction],
        intentIdentifiers: [],
        options: []
      )
      
      // Catégorie pour le rappel du soir
      let completeNowAction = UNNotificationAction(
        identifier: "action_complete_now",
        title: "Terminer maintenant",
        options: [.foreground]
      )
      
      let eveningReminderCategory = UNNotificationCategory(
        identifier: "EVENING_REMINDER",
        actions: [completeNowAction],
        intentIdentifiers: [],
        options: []
      )
      
      // Enregistrer les catégories
      UNUserNotificationCenter.current().setNotificationCategories([
        dayReminderCategory,
        eveningReminderCategory
      ])
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
