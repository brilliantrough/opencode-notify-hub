import 'dart:async';
import 'dart:developer' show log;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../devices/devices_controller.dart';
import '../history/notification_history.dart';
import '../notifications/notification_router.dart';
import '../notifications/notification_text.dart';
import '../realtime/notify_event.dart';
import '../realtime/realtime_controller.dart';
import 'fcm_background.dart';

/// Abstraction over [FirebaseMessaging] so [FcmService] stays unit-testable
/// without the FCM platform channel.
abstract class FcmClient {
  /// Requests the runtime notification permission (`POST_NOTIFICATIONS` on
  /// Android 13+). Returns whether posting alerts is authorized.
  Future<bool> requestPermission();

  /// Foreground message stream (`FirebaseMessaging.onMessage`).
  Stream<RemoteMessage> get messages;

  /// Notification-tap stream (`FirebaseMessaging.onMessageOpenedApp`):
  /// messages whose system notification brought the app to the foreground.
  Stream<RemoteMessage> get openedAppMessages;

  /// The message that opened the app from a terminated state, if any
  /// (`FirebaseMessaging.getInitialMessage`).
  Future<RemoteMessage?> getInitialMessage();

  /// Registration-token refresh stream (`FirebaseMessaging.onTokenRefresh`).
  Stream<String> get tokenRefreshes;

  /// The current registration token, when available.
  Future<String?> getToken();

  /// Invalidates the current registration token (sign-out), so the gateway
  /// stops pushing to this install.
  Future<void> deleteToken();

  /// Registers the top-level background message handler.
  void registerBackgroundHandler(BackgroundMessageHandler handler);
}

/// [FcmClient] backed by the real [FirebaseMessaging] instance.
class FirebaseMessagingClient implements FcmClient {
  FirebaseMessagingClient(this._messaging);

  final FirebaseMessaging _messaging;

  @override
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Stream<RemoteMessage> get messages => FirebaseMessaging.onMessage;

  @override
  Stream<RemoteMessage> get openedAppMessages =>
      FirebaseMessaging.onMessageOpenedApp;

  @override
  Future<RemoteMessage?> getInitialMessage() => _messaging.getInitialMessage();

  @override
  Stream<String> get tokenRefreshes => _messaging.onTokenRefresh;

  @override
  Future<String?> getToken() => _messaging.getToken();

  @override
  Future<void> deleteToken() => _messaging.deleteToken();

  @override
  void registerBackgroundHandler(BackgroundMessageHandler handler) =>
      FirebaseMessaging.onBackgroundMessage(handler);
}

/// The real messaging instance. Overridden in tests.
final fcmClientProvider = Provider<FcmClient>(
  (ref) => FirebaseMessagingClient(FirebaseMessaging.instance),
);

/// Android FCM wiring. Constructed lazily; call [FcmService.init] once the
/// user is authenticated (the token publish targets the registered device).
final fcmServiceProvider = Provider<FcmService>((ref) {
  final service = FcmService(
    client: ref.watch(fcmClientProvider),
    router: ref.watch(notificationRouterProvider),
    history: ref.watch(notificationHistoryProvider),
    currentDeviceId: () async =>
        (await ref.read(sharedPreferencesProvider)).getString(deviceIdPrefsKey),
    updateFcmToken: (deviceId, token) async {
      await ref
          .read(devicesControllerProvider.notifier)
          .updateFcmToken(deviceId, token);
    },
  );
  ref.onDispose(service.dispose);
  return service;
});

/// Owns the Android FCM lifecycle: runtime permission, background handler
/// registration, foreground message routing, opened-app/initial-message
/// history recording, and registration-token sync.
///
/// Foreground messages are parsed via [parseFcmEventData] and fed into the
/// shared [NotificationRouter] (same path as WebSocket events, so dedupe and
/// history semantics match). Opened-app and initial messages instead record
/// straight into the [NotificationHistory] — the system already rendered
/// their notification, so routing them through the router would double-alert
/// (design §10.2: FCM notifications enter the local notification list).
/// Token refreshes — and the initial token — are published to the gateway
/// for the currently registered device; before device registration completes
/// there is nothing to update and the token is
/// dropped (registration publishes the then-current token separately).
class FcmService {
  FcmService({
    required FcmClient client,
    required NotificationRouter router,
    required NotificationHistory history,
    required Future<String?> Function() currentDeviceId,
    required Future<void> Function(String deviceId, String token)
    updateFcmToken,
  }) : _client = client,
       _router = router,
       _history = history,
       _currentDeviceId = currentDeviceId,
       _updateFcmToken = updateFcmToken;

  final FcmClient _client;
  final NotificationRouter _router;
  final NotificationHistory _history;
  final Future<String?> Function() _currentDeviceId;
  final Future<void> Function(String deviceId, String token) _updateFcmToken;

  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _openedAppSubscription;
  StreamSubscription<String>? _tokenSubscription;

  bool get _initialized => _messageSubscription != null;

  /// Requests the notification permission, registers the background handler,
  /// subscribes to foreground/opened-app messages and token refreshes,
  /// records the initial message (cold-start notification tap), and
  /// publishes the current token. Idempotent.
  Future<void> init() async {
    if (_initialized) {
      return;
    }
    await _client.requestPermission();
    _client.registerBackgroundHandler(fcmBackgroundHandler);
    _messageSubscription = _client.messages.listen(_onForegroundMessage);
    _openedAppSubscription = _client.openedAppMessages.listen(
      _onOpenedAppMessage,
    );
    _tokenSubscription = _client.tokenRefreshes.listen(_onTokenRefresh);
    final initialMessage = await _client.getInitialMessage();
    if (initialMessage != null) {
      _onOpenedAppMessage(initialMessage);
    }
    final token = await _client.getToken();
    if (token != null) {
      await _publishToken(token);
    }
  }

  /// Cancels all subscriptions. Safe to call when not initialized.
  Future<void> dispose() async {
    final messages = _messageSubscription;
    final openedApp = _openedAppSubscription;
    final tokens = _tokenSubscription;
    _messageSubscription = null;
    _openedAppSubscription = null;
    _tokenSubscription = null;
    await messages?.cancel();
    await openedApp?.cancel();
    await tokens?.cancel();
  }

  /// Tears FCM down on sign-out: cancels the subscriptions (like [dispose])
  /// and invalidates the registration token so the gateway stops pushing to
  /// this install. A later login re-initializes via [init], which fetches a
  /// fresh token.
  Future<void> logout() async {
    await dispose();
    try {
      await _client.deleteToken();
    } catch (error, stackTrace) {
      // Best-effort: local sign-out proceeds regardless.
      log(
        'failed to delete FCM token on logout',
        name: 'FcmService',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    final event = parseFcmEventData(message.data);
    if (event == null) {
      return;
    }
    unawaited(() async {
      try {
        await _router.handle(event);
      } catch (error, stackTrace) {
        log(
          'failed to route foreground FCM event ${event.eventId}',
          name: 'FcmService',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }());
  }

  /// Records an opened-app (or cold-start initial) message in the history
  /// without alerting: the system already showed the notification that the
  /// user tapped. Mirrors the background handler's semantics — malformed
  /// payloads, heartbeats, and `action_resolved` are ignored, and events
  /// already in the history are skipped (dedupe by event ID against the
  /// WebSocket/foreground-FCM path).
  void _onOpenedAppMessage(RemoteMessage message) {
    final event = parseFcmEventData(message.data);
    if (event == null) {
      return;
    }
    if (event.type == NotifyEventType.heartbeat ||
        event.type == NotifyEventType.actionResolved) {
      return;
    }
    if (_history.contains(event.eventId)) {
      return;
    }
    _history.add(buildHistoryEntry(event, receivedAt: DateTime.now()));
  }

  void _onTokenRefresh(String token) {
    unawaited(() async {
      try {
        await _publishToken(token);
      } catch (error, stackTrace) {
        log(
          'failed to publish FCM token',
          name: 'FcmService',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }());
  }

  Future<void> _publishToken(String token) async {
    final deviceId = await _currentDeviceId();
    if (deviceId == null) {
      return;
    }
    await _updateFcmToken(deviceId, token);
  }
}
