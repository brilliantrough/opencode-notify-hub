import 'dart:async';

import 'package:client/auth/auth_controller.dart';
import 'package:client/auth/auth_state.dart';
import 'package:client/history/notification_history.dart';
import 'package:client/notifications/notification_router.dart';
import 'package:client/notifications/notification_service.dart';
import 'package:client/realtime/active_sessions.dart';
import 'package:client/realtime/event_deduper.dart';
import 'package:client/realtime/instance_presence.dart';
import 'package:client/realtime/notify_event.dart';
import 'package:client/realtime/realtime_controller.dart';
import 'package:client/realtime/ws_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeWsClient implements WsClient {
  final StreamController<NotifyEvent> _events =
      StreamController<NotifyEvent>.broadcast();
  final StreamController<WsStatus> _status =
      StreamController<WsStatus>.broadcast();
  final StreamController<List<OpenCodeInstancePresence>> _instancePresences =
      StreamController<List<OpenCodeInstancePresence>>.broadcast();

  var connectCalls = 0;
  var disconnectCalls = 0;

  @override
  Stream<NotifyEvent> get events => _events.stream;

  @override
  Stream<WsStatus> get status => _status.stream;

  @override
  Stream<List<OpenCodeInstancePresence>> get instancePresences =>
      _instancePresences.stream;

  @override
  void connect() {
    connectCalls++;
  }

  @override
  void disconnect() {
    disconnectCalls++;
  }

  void emit(NotifyEvent event) => _events.add(event);

  void emitPresence(List<OpenCodeInstancePresence> instances) =>
      _instancePresences.add(instances);
}

class FakeNotificationService implements NotificationService {
  final List<NotifyRequest> shown = [];
  var throwOnShow = false;

  @override
  Future<void> init() async {}

  @override
  Future<void> show(NotifyRequest request) async {
    if (throwOnShow) {
      throw StateError('platform notification failure');
    }
    shown.add(request);
  }

  @override
  Future<bool> permissionGranted() async => true;

  @override
  Future<void> openPermissionSettings() async {}
}

/// [AuthController] seeded with a fixed state; [setAuth] toggles it later.
class SeededAuthController extends AuthController {
  SeededAuthController(this._seed);

  AuthState _seed;

  @override
  AuthState build() => _seed;

  void setAuth(AuthState next) {
    _seed = next;
    state = next;
  }
}

const _authenticated = Authenticated(accessToken: 'token', email: 'a@b.c');

NotifyEvent _actionRequired(String eventId) => NotifyEvent(
  eventId: eventId,
  occurredAt: DateTime.utc(2026, 1, 1, 12),
  machine: 'macbook',
  project: 'linewrite',
  directory: '/repo',
  sessionId: 'sess-1',
  sessionTitle: 'Fix login',
  type: NotifyEventType.actionRequired,
  requestId: 'req-1',
  actionKind: ActionKind.permission,
  permissionType: 'filesystem',
);

void main() {
  late ProviderContainer container;
  late FakeWsClient client;
  late FakeNotificationService service;
  late RealtimeController controller;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
    client = FakeWsClient();
    service = FakeNotificationService();
    controller = RealtimeController(
      client: client,
      router: NotificationRouter(
        service: service,
        activeSessions: container.read(activeSessionsProvider.notifier),
        deduper: EventDeduper(),
        history: InMemoryNotificationHistory(),
        readSettings: () => const NotificationSettings(),
      ),
      onInstancePresences: container
          .read(instancePresencesProvider.notifier)
          .replaceAll,
    );
  });

  test('start connects the client and routes events into the router', () async {
    controller.start();
    client.emit(_actionRequired('evt-1'));
    await Future<void>.delayed(Duration.zero);

    expect(client.connectCalls, 1);
    expect(service.shown.map((r) => r.eventId), ['evt-1']);
  });

  test('routes authoritative instance presence into its projection', () async {
    final instance = OpenCodeInstancePresence(
      instanceId: '6f0d91b0-93e4-43a9-9449-0bed03e651aa',
      machine: 'devbox',
      project: 'notify',
      directory: '/work/notify',
      openCodeVersion: '1.18.18',
      protocolVersion: 1,
      state: InstancePresenceState.controllable,
      lastSeenAt: DateTime.utc(2026, 8, 14, 9),
    );
    controller.start();

    client.emitPresence([instance]);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(instancePresencesProvider), {
      instance.instanceId: instance,
    });
  });

  test('start is idempotent: one connect and one subscription', () async {
    controller.start();
    controller.start();
    client.emit(_actionRequired('evt-1'));
    await Future<void>.delayed(Duration.zero);

    expect(client.connectCalls, 1);
    expect(service.shown, hasLength(1));
  });

  test('stop disconnects and stops routing events', () async {
    controller.start();
    controller.stop();
    client.emit(_actionRequired('evt-1'));
    await Future<void>.delayed(Duration.zero);

    expect(client.disconnectCalls, 1);
    expect(service.shown, isEmpty);
  });

  test('start after stop re-subscribes and reconnects', () async {
    controller.start();
    controller.stop();
    controller.start();
    client.emit(_actionRequired('evt-1'));
    await Future<void>.delayed(Duration.zero);

    expect(client.connectCalls, 2);
    expect(service.shown.map((r) => r.eventId), ['evt-1']);
  });

  test('a throwing notification service is logged, not unhandled, '
      'and the event is still recorded in history', () async {
    final history = InMemoryNotificationHistory();
    service.throwOnShow = true;
    controller = RealtimeController(
      client: client,
      router: NotificationRouter(
        service: service,
        activeSessions: container.read(activeSessionsProvider.notifier),
        deduper: EventDeduper(),
        history: history,
        readSettings: () => const NotificationSettings(),
      ),
      onInstancePresences: container
          .read(instancePresencesProvider.notifier)
          .replaceAll,
    );

    controller.start();
    client.emit(_actionRequired('evt-1'));
    await Future<void>.delayed(Duration.zero);

    // The history write precedes the alert, so the event survives the
    // platform failure; the error must not escape as an unhandled async
    // error (which would fail this test).
    expect(history.entries.map((e) => e.eventId), ['evt-1']);
    expect(service.shown, isEmpty);
  });

  group('realtimeControllerProvider', () {
    late FakeWsClient client;
    late FakeNotificationService service;
    var wsBuilds = 0;

    ProviderContainer buildContainer(AuthState seed) {
      final c = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(() => SeededAuthController(seed)),
          wsClientProvider.overrideWith((ref) {
            wsBuilds++;
            return client;
          }),
          notificationServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    SeededAuthController authOf(ProviderContainer c) =>
        c.read(authControllerProvider.notifier) as SeededAuthController;

    setUp(() {
      client = FakeWsClient();
      service = FakeNotificationService();
      wsBuilds = 0;
    });

    test(
      'authenticated: controller starts with connect and a live subscription',
      () async {
        final c = buildContainer(_authenticated);

        final controller = c.read(realtimeControllerProvider);

        expect(controller, isNotNull);
        expect(client.connectCalls, 1);
        client.emit(_actionRequired('evt-1'));
        await Future<void>.delayed(Duration.zero);
        expect(service.shown.map((r) => r.eventId), ['evt-1']);
      },
    );

    test('unauthenticated: no controller and the WsClient is never built', () {
      final c = buildContainer(const Unauthenticated());

      expect(c.read(realtimeControllerProvider), isNull);
      expect(wsBuilds, 0);
      expect(client.connectCalls, 0);
    });

    test('toggling auth starts and stops the controller', () async {
      final c = buildContainer(const Unauthenticated());
      expect(c.read(realtimeControllerProvider), isNull);

      authOf(c).setAuth(_authenticated);
      expect(c.read(realtimeControllerProvider), isNotNull);
      expect(client.connectCalls, 1);

      client.emit(_actionRequired('evt-1'));
      await Future<void>.delayed(Duration.zero);
      expect(service.shown, hasLength(1));

      authOf(c).setAuth(const Unauthenticated());
      expect(c.read(realtimeControllerProvider), isNull);
      expect(client.disconnectCalls, 1);

      // Events after logout are no longer routed.
      client.emit(_actionRequired('evt-2'));
      await Future<void>.delayed(Duration.zero);
      expect(service.shown, hasLength(1));
    });

    test('background disconnects and foreground reconnects '
        '(appForegroundProvider gating)', () async {
      final c = buildContainer(_authenticated);
      expect(c.read(realtimeControllerProvider), isNotNull);
      expect(client.connectCalls, 1);

      // Backgrounded: the rebuilt controller is not started, the socket
      // closes, and events are no longer routed.
      c.read(appForegroundProvider.notifier).setForeground(false);
      expect(c.read(realtimeControllerProvider), isNotNull);
      expect(client.disconnectCalls, 1);
      client.emit(_actionRequired('evt-background'));
      await Future<void>.delayed(Duration.zero);
      expect(service.shown, isEmpty);

      // Foregrounded again: a fresh controller reconnects and resumes
      // routing.
      c.read(appForegroundProvider.notifier).setForeground(true);
      expect(c.read(realtimeControllerProvider), isNotNull);
      expect(client.connectCalls, 2);
      client.emit(_actionRequired('evt-foreground'));
      await Future<void>.delayed(Duration.zero);
      expect(service.shown.map((r) => r.eventId), ['evt-foreground']);
    });
  });
}
