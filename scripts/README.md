# Firebase App Distribution Setup

This directory contains scripts to distribute test builds of Silva to testers via Firebase App Distribution.

## Quick Start Guide

### 1. First-Time Setup

#### Login to Firebase
```bash
firebase login
```

#### List Your Firebase Apps
```bash
firebase apps:list
```

This will show you all your Firebase app IDs. You need these for distribution.

### 2. Edit Distribution Scripts

Before using the scripts, you need to update them with your information:

#### For Android (`distribute_android.sh`):
- ✅ Firebase App ID is already set: `1:174370766580:android:88ca971d45e3d0f932a8a1`
- ⚠️ Update tester emails on line 33: Replace `your-tester@example.com` with actual tester emails

#### For iOS (`distribute_ios.sh`):
- ⚠️ Get your iOS Firebase App ID from Firebase Console or `GoogleService-Info.plist`
- ⚠️ Update tester emails: Replace `your-tester@example.com` with actual tester emails

### 3. Distribute a Build

#### For Android:
```bash
./scripts/distribute_android.sh
```

#### For iOS:
```bash
./scripts/distribute_ios.sh
```

The script will:
1. Build the app in release mode
2. Ask you for release notes
3. Upload to Firebase App Distribution
4. Send email notifications to testers

## Using Tester Groups (Recommended)

Instead of listing individual emails, you can create tester groups in Firebase Console:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **ma-bulle-auth-demo**
3. Go to **App Distribution** in the left sidebar
4. Click **Testers & Groups** tab
5. Create groups like:
   - `internal` (for internal team)
   - `beta` (for beta testers)
   - `alpha` (for alpha testers)

Then update your scripts to use groups instead:
```bash
--groups "internal,beta"
```

## App IDs Reference

Your Firebase App IDs:
- **Android**: `1:174370766580:android:88ca971d45e3d0f932a8a1`
- **iOS**: Get from GoogleService-Info.plist (GOOGLE_APP_ID)

## Tips

1. **Version Numbers**: Increment version in `pubspec.yaml` before each distribution:
   ```yaml
   version: 1.0.1+2  # Increment build number
   ```

2. **Release Notes**: Be descriptive! Testers need to know what changed:
   ```
   - Fixed login bug
   - Added new tree animations
   - Improved performance
   ```

3. **Feedback Loop**: Set up a way for testers to provide feedback (email, Slack, etc.)

4. **Monitor**: Check Firebase Console → App Distribution to see:
   - Who downloaded the build
   - Who installed it
   - Crash reports (if Crashlytics is enabled)

## Troubleshooting

### "App not found" error
- Make sure you're using the correct App ID
- Verify the app exists in Firebase Console
- Check that you have App Distribution enabled for your project

### "Authentication failed"
```bash
firebase login --reauth
```

### "Build not found"
- Check that the build completed successfully
- Verify the build path in the script matches the actual output path

## Alternative: Manual Upload

You can also upload manually through Firebase Console:
1. Build your app: `flutter build apk --release`
2. Go to Firebase Console → App Distribution
3. Click "Distribute" → "Upload a build"
4. Select your APK/IPA
5. Add testers and release notes
6. Click "Distribute"

## Resources

- [Firebase App Distribution Docs](https://firebase.google.com/docs/app-distribution)
- [Flutter Build Docs](https://docs.flutter.dev/deployment)
- Workflow guide: `.agent/workflows/firebase-app-distribution.md`
