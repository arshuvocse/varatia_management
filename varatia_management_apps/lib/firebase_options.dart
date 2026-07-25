import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDEnTTtFVzqjC2arfVRwYO0ji4uQZga-Lk',
    appId: String.fromEnvironment(
      'FIREBASE_WEB_APP_ID',
      defaultValue: '1:500162660899:android:31af266d69918946cebf96',
    ),
    messagingSenderId: '500162660899',
    projectId: 'varatiamanagement',
    storageBucket: 'varatiamanagement.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDEnTTtFVzqjC2arfVRwYO0ji4uQZga-Lk',
    appId: '1:500162660899:android:31af266d69918946cebf96',
    messagingSenderId: '500162660899',
    projectId: 'varatiamanagement',
    storageBucket: 'varatiamanagement.firebasestorage.app',
  );

  static const FirebaseOptions ios = android;
  static const FirebaseOptions macos = android;
  static const FirebaseOptions windows = android;
  static const FirebaseOptions linux = android;
}
