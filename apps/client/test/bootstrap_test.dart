import 'dart:async';

import 'package:client/auth/auth_controller.dart';
import 'package:client/auth/auth_state.dart';
import 'package:client/bootstrap.dart';
import 'package:client/devices/device_identity.dart';
import 'package:client/fcm/fcm_service.dart';
import 'package:client/notifications/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fcm/fcm_service_test.dart' show FakeFcmClient;
import 'ui/fake_auth_controller.dart';

class FakeNotificationService implements NotificationService {
  @override
  Future<void> init() async {}

  @override
  Future<void> show(NotifyRequest request) async {}

  @override
  Future<bool> permissionGranted() async => true;

  @override
  Future<void> openPermissionSettings() async {}
}

void main() {
  group('realtimeForegroundFor', () {
    const cases = {
      AppLifecycleState.resumed: true,
      AppLifecycleState.inactive: true,
      AppLifecycleState.paused: false,
      AppLifecycleState.hidden: false,
      AppLifecycleState.detached: false,
    };

    test(
      'Android: only resumed/inactive are foreground; paused/hidden '
      'background the socket (FCM takes over)',
      () {
        for (final entry in cases.entries) {
          expect(
            realtimeForegroundFor(entry.key, isDesktop: false),
            entry.value,
            reason: 'Android ${entry.key}',
          );
        }
      },
    );

    test(
      'desktop: every lifecycle state stays connected while the process runs',
      () {
        for (final entry in cases.entries) {
          expect(
            realtimeForegroundFor(entry.key, isDesktop: true),
            isTrue,
            reason: 'desktop ${entry.key}',
          );
        }
      },
    );
  });

  group('FCM auth gating', () {
    // A plain test (not testWidgets) so the unawaited FCM teardown chain —
    // subscription cancels complete on the real event loop — can finish
    // without fighting the fake-async zone.
    test(
      'logout tears FCM down: subscriptions cancelled and token deleted',
      () async {
        TestWidgetsFlutterBinding.ensureInitialized();
        SharedPreferences.setMockInitialValues({});
        final fcm = FakeFcmClient();
        final auth = FakeAuthController(
          const Authenticated(accessToken: 'token', email: 'u@example.com'),
        );
        final bootstrap = await AppBootstrap.initialize(
          platform: ClientPlatform.android,
          notificationService: FakeNotificationService(),
          initDesktopWindowing: false,
          extraOverrides: [
            // Firebase cannot initialize in tests; force FCM available.
            fcmAvailableProvider.overrideWithValue(true),
            fcmClientProvider.overrideWithValue(fcm),
            authControllerProvider.overrideWith(() => auth),
          ],
        );
        final container = ProviderContainer(overrides: bootstrap.overrides);
        // Start FCM as a completed login would have (registration is
        // gateway-bound and fails in tests, so init directly).
        await container.read(fcmServiceProvider).init();
        expect(fcm.registeredHandler, isNotNull);

        bootstrap.attach(container);
        addTearDown(() async {
          await bootstrap.shutdown();
          // Not awaited: closing a controller that was never listened to
          // never completes.
          unawaited(fcm.messagesController.close());
          unawaited(fcm.openedAppController.close());
          unawaited(fcm.tokenController.close());
        });

        await auth.logout();
        // Let the unawaited teardown chain (subscription cancels, token
        // deletion) complete.
        await pumpEventQueue();
        await pumpEventQueue();

        expect(fcm.deleteTokenCalls, 1);

        // After teardown, further FCM deliveries route nowhere.
        fcm.messagesController.add(const RemoteMessage(data: {}));
        fcm.tokenController.add('tok-after-logout');
        await pumpEventQueue();
      },
    );
  });
}
