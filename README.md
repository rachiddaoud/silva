# Silva

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Replacing App Icons

To replace the default Flutter logo with your custom app logo:

### Android
Replace the icon files in `android/app/src/main/res/mipmap-*/ic_launcher.png`:
- `mipmap-mdpi/ic_launcher.png` (48x48)
- `mipmap-hdpi/ic_launcher.png` (72x72)
- `mipmap-xhdpi/ic_launcher.png` (96x96)
- `mipmap-xxhdpi/ic_launcher.png` (144x144)
- `mipmap-xxxhdpi/ic_launcher.png` (192x192)

### iOS
Replace the icon files in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`:
- Various sizes from 20x20 to 1024x1024 (see Contents.json for exact sizes)

### Web
Replace the icon files in `web/icons/`:
- `Icon-192.png` (192x192)
- `Icon-512.png` (512x512)
- `Icon-maskable-192.png` (192x192, maskable)
- `Icon-maskable-512.png` (512x512, maskable)

### macOS
Replace the icon files in `macos/Runner/Assets.xcassets/AppIcon.appiconset/`:
- Various sizes as specified in Contents.json

**Note:** You can use tools like [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons) to automatically generate all required icon sizes from a single source image.

## Analytics

This app uses Firebase Analytics to track user behavior and app performance. Analytics is automatically initialized when the app starts.

### Testing Analytics Locally

To test analytics events in debug mode:

**Android:**
```bash
adb shell setprop debug.firebase.analytics.app com.example.silva
```

**iOS:**
Add the following argument in Xcode scheme:
```
-FIRDebugEnabled
```

Then view events in real-time in the Firebase Console under Analytics > DebugView.

### Adding New Events

To add a new analytics event:

1. Add the event name constant to `AnalyticsEvents` in `lib/services/analytics_service.dart`
2. Use `AnalyticsService.instance.logEvent()` to track the event:
   ```dart
   await AnalyticsService.instance.logEvent(
     name: AnalyticsEvents.yourEventName,
     parameters: {
       AnalyticsParams.yourParam: value,
     },
   );
   ```

### Privacy & Consent

Analytics respects user privacy preferences. To disable analytics collection:
```dart
await AnalyticsService.instance.setAnalyticsCollectionEnabled(false);
```

### Tracked Events

The app tracks the following events:
- Authentication: `login_attempt`, `login_success`, `login_failure`, `logout`
- User engagement: `mood_selected`, `activity_completed`, `daily_goal_completed`
- Navigation: Screen views for `home`, `day_completion`, `settings`
- Sharing: `share_initiated`
- Settings: `language_changed`, `settings_opened`
- App lifecycle: `app_open`

See `lib/services/analytics_service.dart` for the complete list of events and parameters.
