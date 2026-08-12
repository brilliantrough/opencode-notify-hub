import 'package:client/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DefaultFirebaseOptions placeholder', () {
    test('currentPlatform returns the Android placeholder on Android', () {
      // flutter_test defaults defaultTargetPlatform to Android.
      expect(defaultTargetPlatform, TargetPlatform.android);
      expect(
        DefaultFirebaseOptions.currentPlatform.projectId,
        'opencode-notify-placeholder',
      );
    });

    test('currentPlatform throws off Android so tests never need it', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      expect(
        () => DefaultFirebaseOptions.currentPlatform,
        throwsUnsupportedError,
      );
    });

    test('exposes placeholder Android options', () {
      const options = DefaultFirebaseOptions.android;

      expect(options, isA<FirebaseOptions>());
      expect(options.projectId, 'opencode-notify-placeholder');
      expect(options.messagingSenderId, '000000000000');
    });
  });
}
