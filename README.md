# ma_bulle

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
