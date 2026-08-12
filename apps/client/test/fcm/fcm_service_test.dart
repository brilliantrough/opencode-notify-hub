import 'dart:async';
import 'dart:convert';

import 'package:client/fcm/fcm_service.dart';
import 'package:client/history/notification_history.dart';
import 'package:client/notifications/notification_router.dart';
import 'package:client/notifications/notification_service.dart';
import 'package:client/realtime/active_sessions.dart';
import 'package:client/realtime/event_deduper.dart';
import 'package:firebase_messaging/firebase_messaging.dart'
    hide NotificationSettings;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeFcmClient implements FcmClient {
  final messagesController = StreamController<RemoteMessage>();
  final openedAppController = StreamController<RemoteMessage>();
  final tokenController = StreamController<String>();
  var permissionRequested = 0;
  var permissionGranted = true;
  String? token;
  RemoteMessage? initialMessage;
  BackgroundMessageHandler? registeredHandler;
  var deleteTokenCalls = 0;
  var throwOnDeleteToken = false;

  @override
  Future<bool> requestPermission() async {
    permissionRequested++;
    return permissionGranted;
  }

  @override
  Stream<RemoteMessage> get messages => messagesController.stream;

  @override
  Stream<RemoteMessage> get openedAppMessages => openedAppController.stream;

  @override
  Future<RemoteMessage?> getInitialMessage() async => initialMessage;

  @override
  Stream<String> get tokenRefreshes => tokenController.stream;

  @override
  Future<String?> getToken() async => token;

  @override
  Future<void> deleteToken() async {
    deleteTokenCalls++;
    if (throwOnDeleteToken) {
      throw StateError('deleteToken failed');
    }
  }

  @override
  void registerBackgroundHandler(BackgroundMessageHandler handler) {
    registeredHandler = handler;
  }
}

class FakeNotificationService implements NotificationService {
  final List<NotifyRequest> shown = [];

  @override
  Future<void> init() async {}

  @override
  Future<void> show(NotifyRequest request) async {
    shown.add(request);
  }

  @override
  Future<bool> permissionGranted() async => true;

  @override
  Future<void> openPermissionSettings() async {}
}

RemoteMessage messageOf(Map<String, Object?> envelope) => RemoteMessage(
  data: {'event': jsonEncode(envelope)},
);

Map<String, Object?> terminalEnvelope({String eventId = 'evt-term'}) => {
  'eventId': eventId,
  'type': 'terminal',
  'occurredAt': '2026-01-01T00:00:00.000Z',
  'source': {
    'machine': 'devbox',
    'project': 'api',
    'directory': '/work/api',
  },
  'session': {'id': 'ses_1', 'title': 'Implement API'},
  'payload': {'outcome': 'completed', 'elapsedSeconds': 42},
};

Map<String, Object?> heartbeatEnvelope({String eventId = 'evt-hb'}) => {
  'eventId': eventId,
  'type': 'heartbeat',
  'occurredAt': '2026-01-01T00:00:00.000Z',
  'source': {
    'machine': 'devbox',
    'project': 'api',
    'directory': '/work/api',
  },
  'session': {'id': 'ses_1', 'title': 'Implement API'},
  'payload': {'status': 'busy', 'elapsedSeconds': 60},
};

void main() {
  late ProviderContainer container;
  late FakeFcmClient fcm;
  late FakeNotificationService notifications;
  late NotificationRouter router;
  late InMemoryNotificationHistory history;
  late List<({String deviceId, String token})> tokenUpdates;
  String? currentDeviceId;

  FcmService buildService() => FcmService(
    client: fcm,
    router: router,
    history: history,
    currentDeviceId: () async => currentDeviceId,
    updateFcmToken: (deviceId, token) async {
      tokenUpdates.add((deviceId: deviceId, token: token));
    },
  );

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
    fcm = FakeFcmClient();
    notifications = FakeNotificationService();
    tokenUpdates = [];
    currentDeviceId = 'dev-1';
    history = InMemoryNotificationHistory();
    router = NotificationRouter(
      service: notifications,
      activeSessions: container.read(activeSessionsProvider.notifier),
      deduper: EventDeduper(),
      history: history,
      readSettings: () => const NotificationSettings(),
    );
  });

  tearDown(() async {
    // Not awaited: closing a controller that was never listened to (tests
    // that skip init) never completes.
    unawaited(fcm.messagesController.close());
    unawaited(fcm.openedAppController.close());
    unawaited(fcm.tokenController.close());
  });

  group('FcmService.init', () {
    test('requests the notification permission', () async {
      await buildService().init();

      expect(fcm.permissionRequested, 1);
    });

    test('registers the top-level background handler', () async {
      await buildService().init();

      expect(fcm.registeredHandler, isNotNull);
    });

    test('is idempotent: a second init does not re-subscribe', () async {
      final service = buildService();
      await service.init();
      await service.init();

      expect(fcm.permissionRequested, 1);
    });

    test('publishes the current token to the registered device', () async {
      fcm.token = 'tok-initial';

      await buildService().init();

      expect(tokenUpdates, [(deviceId: 'dev-1', token: 'tok-initial')]);
    });

    test('skips the initial token publish when no device is registered',
        () async {
      fcm.token = 'tok-initial';
      currentDeviceId = null;

      await buildService().init();

      expect(tokenUpdates, isEmpty);
    });

    test('skips the initial token publish when no token is available',
        () async {
      fcm.token = null;

      await buildService().init();

      expect(tokenUpdates, isEmpty);
    });
  });

  group('FcmService foreground messages', () {
    test('feeds a parsed event into the NotificationRouter', () async {
      await buildService().init();

      fcm.messagesController.add(messageOf(terminalEnvelope()));
      await pumpEventQueue();

      expect(notifications.shown, hasLength(1));
      final request = notifications.shown.single;
      expect(request.eventId, 'evt-term');
      expect(request.title, 'devbox · api · terminal');
      expect(request.body, 'completed in 42s');
    });

    test('ignores malformed foreground payloads', () async {
      await buildService().init();

      fcm.messagesController.add(const RemoteMessage(data: {'event': '{no'}));
      fcm.messagesController.add(const RemoteMessage(data: {}));
      await pumpEventQueue();

      expect(notifications.shown, isEmpty);
    });
  });

  group('FcmService opened-app messages', () {
    test(
      'records the event in history without alerting (the system already '
      'showed the notification)',
      () async {
        await buildService().init();

        fcm.openedAppController.add(messageOf(terminalEnvelope()));
        await pumpEventQueue();

        expect(history.contains('evt-term'), isTrue);
        final entry = history.entries.single;
        expect(entry.title, 'devbox · api · terminal');
        expect(entry.body, 'completed in 42s');
        expect(notifications.shown, isEmpty, reason: 'no double alert');
      },
    );

    test('dedupes against history: an already-recorded event is skipped',
        () async {
        history.add(
          HistoryEntry(
            eventId: 'evt-term',
            title: 't',
            body: 'b',
            receivedAt: DateTime(2026),
          ),
        );
        await buildService().init();

        fcm.openedAppController.add(messageOf(terminalEnvelope()));
        await pumpEventQueue();

        expect(history.entries, hasLength(1));
        expect(notifications.shown, isEmpty);
      },
    );

    test('ignores heartbeats, action_resolved, and malformed payloads',
        () async {
        await buildService().init();

        fcm.openedAppController.add(messageOf(heartbeatEnvelope()));
        fcm.openedAppController.add(const RemoteMessage(data: {'event': '{no'}));
        fcm.openedAppController.add(const RemoteMessage(data: {}));
        await pumpEventQueue();

        expect(history.entries, isEmpty);
        expect(notifications.shown, isEmpty);
      },
    );

    test('processes the initial message (cold start via notification tap)',
        () async {
        fcm.initialMessage = messageOf(terminalEnvelope());

        await buildService().init();

        expect(history.contains('evt-term'), isTrue);
        expect(notifications.shown, isEmpty);
      },
    );

    test('a null initial message records nothing', () async {
      fcm.initialMessage = null;

      await buildService().init();

      expect(history.entries, isEmpty);
    });
  });

  group('FcmService logout', () {
    test(
      'cancels the subscriptions and deletes the registration token',
      () async {
        final service = buildService();
        await service.init();

        await service.logout();

        expect(fcm.deleteTokenCalls, 1);
        fcm.messagesController.add(messageOf(terminalEnvelope()));
        fcm.openedAppController.add(
          messageOf(terminalEnvelope(eventId: 'evt-opened')),
        );
        fcm.tokenController.add('tok-after-logout');
        await pumpEventQueue();

        expect(notifications.shown, isEmpty);
        expect(history.entries, isEmpty);
        expect(tokenUpdates, isEmpty);
      },
    );

    test('is safe when never initialized', () async {
      await buildService().logout();

      expect(fcm.deleteTokenCalls, 1);
    });

    test('a failing deleteToken does not propagate', () async {
      fcm.throwOnDeleteToken = true;
      final service = buildService();
      await service.init();

      await service.logout();

      expect(fcm.deleteTokenCalls, 1);
    });
  });

  group('FcmService token refresh', () {
    test('publishes refreshed tokens via updateFcmToken', () async {
      await buildService().init();

      fcm.tokenController.add('tok-new');
      await pumpEventQueue();

      expect(tokenUpdates, [(deviceId: 'dev-1', token: 'tok-new')]);
    });

    test('skips the publish when no device is registered yet', () async {
      currentDeviceId = null;
      await buildService().init();

      fcm.tokenController.add('tok-new');
      await pumpEventQueue();

      expect(tokenUpdates, isEmpty);
    });
  });
}
