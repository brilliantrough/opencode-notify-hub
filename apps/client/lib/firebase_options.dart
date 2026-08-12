import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Placeholder Firebase options for the Android client.
///
/// DEPLOYMENT STEP: this file is intentionally NOT generated from a real
/// Firebase project (none exists yet). Before shipping Android builds, run
/// `flutterfire configure` (FlutterFire CLI) against the real project to
/// regenerate this file, and add `android/app/google-services.json` together
/// with the Google Services Gradle plugin.
///
/// Only Android carries (dummy) values; every other platform throws
/// [UnsupportedError], so accidental use — in unit tests or desktop builds —
/// fails loudly instead of silently initializing against a dummy project.
/// Tests never touch this class: the FCM pieces under `lib/fcm/` inject all
/// Firebase-facing dependencies.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions is not configured for web — '
        'run flutterfire configure.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions only has placeholder values for Android — '
          'run flutterfire configure to add this platform.',
        );
    }
  }

  /// Dummy values, structurally valid but bound to no real Firebase project.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'PLACEHOLDER_API_KEY',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'opencode-notify-placeholder',
    storageBucket: 'opencode-notify-placeholder.appspot.com',
  );
}
