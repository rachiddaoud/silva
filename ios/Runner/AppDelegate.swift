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
    
    // Register platform channel for saving widget images to App Group
    // We'll set this up after the engine is ready
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "com.rachid.silva/widget_image",
        binaryMessenger: controller.binaryMessenger
      )
      
      channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
        if call.method == "saveImageToAppGroup" {
          guard let args = call.arguments as? [String: Any],
                let imageData = args["imageData"] as? FlutterStandardTypedData,
                let filename = args["filename"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
          }
          
          let appGroup = "group.com.rachid.silva.widgets"
          if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) {
            let fileURL = containerURL.appendingPathComponent(filename)
            do {
              try imageData.data.write(to: fileURL)
              result(filename) // Return filename for UserDefaults
            } catch {
              result(FlutterError(code: "SAVE_ERROR", message: error.localizedDescription, details: nil))
            }
          } else {
            result(FlutterError(code: "APP_GROUP_ERROR", message: "Could not access App Group container", details: nil))
          }
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }
    
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
