import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let widgetChannel = FlutterMethodChannel(name: "com.rachid.silva/widget",
                                              binaryMessenger: controller.binaryMessenger)
    
    widgetChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      
      if call.method == "saveToAppGroup" {
        guard let args = call.arguments as? [String: Any],
              let key = args["key"] as? String,
              let value = args["value"] as? String else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing key or value", details: nil))
          return
        }
        
        let appGroup = "group.com.rachid.silva.widgets"
        if let userDefaults = UserDefaults(suiteName: appGroup) {
          userDefaults.set(value, forKey: key)
          userDefaults.synchronize()
          print("✅ [AppDelegate] Saved to App Group: \(key) = \(value.prefix(30))...")
          result(true)
        } else {
          print("❌ [AppDelegate] Failed to get App Group UserDefaults")
          result(FlutterError(code: "APP_GROUP_ERROR", message: "Cannot access App Group", details: nil))
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    })
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
