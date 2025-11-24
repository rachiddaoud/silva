// File generated manually based on firebase apps:sdkconfig output
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyANJaths-_q8VgiODSuYqgB8yIy5SOErZc',
    appId: '1:174370766580:android:88ca971d45e3d0f932a8a1',
    messagingSenderId: '174370766580',
    projectId: 'ma-bulle-auth-demo',
    storageBucket: 'ma-bulle-auth-demo.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA44s9JjLQnbGNV6tbYl7rvh1OwP5mec-w',
    appId: '1:174370766580:ios:6eead10cbb626bd532a8a1',
    messagingSenderId: '174370766580',
    projectId: 'ma-bulle-auth-demo',
    storageBucket: 'ma-bulle-auth-demo.firebasestorage.app',
    iosBundleId: 'com.example.silva',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDqKn51sQ7IZOF_DBK4Gzu_SMQ3fPuip2s',
    appId: '1:174370766580:web:6da7de5fc061026d32a8a1',
    messagingSenderId: '174370766580',
    projectId: 'ma-bulle-auth-demo',
    authDomain: 'ma-bulle-auth-demo.firebaseapp.com',
    storageBucket: 'ma-bulle-auth-demo.firebasestorage.app',
  );
}
