import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:client/app.dart';
import 'package:client/auth/auth_controller.dart';
import 'package:client/auth/auth_state.dart';
import 'package:client/auth/credentials_store.dart';
import 'package:client/bootstrap.dart';
import 'package:client/config/app_config.dart';
import 'package:client/config/server_config.dart';
import 'package:client/history/notification_history.dart';
import 'package:client/notifications/alert_sound.dart';
import 'package:client/notifications/notification_service.dart';
import 'package:client/realtime/instance_presence.dart';
import 'package:client/realtime/realtime_controller.dart';
import 'package:client/settings/settings_controller.dart';
import 'package:client/ui/history_page.dart';
import 'package:client/ui/pending_interaction_page.dart';
import 'package:client/ui/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// In-process fake gateway: HTTP endpoints for auth refresh/logout and
/// device registration, plus a WebSocket endpoint at `/v1/ws` the test can
/// push realtime events through.
class FakeGateway {
  FakeGateway._(this._server);

  final HttpServer _server;

  final List<Map<String, dynamic>> registeredDevices = [];
  var refreshCalls = 0;
  var logoutCalls = 0;

  /// The pending-interactions snapshot served by `GET /v1/pending-interactions`.
  List<Map<String, Object?>> pendingInteractions = [];
  var answerCalls = 0;
  var decisionCalls = 0;

  WebSocket? _socket;
  final Completer<void> _socketClosed = Completer<void>();

  String get httpBase => 'http://127.0.0.1:${_server.port}';

  bool get socketConnected => _socket != null;

  bool get socketClosed => _socketClosed.isCompleted;

  static Future<FakeGateway> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final gateway = FakeGateway._(server);
    server.listen(gateway._handle);
    return gateway;
  }

  Future<void> _handle(HttpRequest request) async {
    if (request.uri.path == '/v1/ws') {
      final socket = await WebSocketTransformer.upgrade(request);
      _socket = socket;
      socket.listen(
        (_) {},
        onDone: () {
          if (!_socketClosed.isCompleted) {
            _socketClosed.complete();
          }
        },
      );
      return;
    }
    final path = request.uri.path;
    if (request.method == 'POST' &&
        path.startsWith('/v1/pending-interactions/') &&
        path.endsWith('/answer')) {
      answerCalls++;
      _json(request, 200, {
        'commandId': 'cmd-answer-$answerCalls',
        'status': 'confirmed',
      });
      return;
    }
    if (request.method == 'POST' &&
        path.startsWith('/v1/pending-interactions/') &&
        path.endsWith('/decision')) {
      decisionCalls++;
      _json(request, 200, {
        'commandId': 'cmd-decision-$decisionCalls',
        'status': 'confirmed',
      });
      return;
    }
    switch ((request.method, request.uri.path)) {
      case ('POST', '/v1/auth/refresh'):
        refreshCalls++;
        _json(request, 200, {
          'accessToken': 'at-$refreshCalls',
          'refreshToken': 'rt-next-$refreshCalls',
        });
      case ('POST', '/v1/auth/logout'):
        logoutCalls++;
        request.response.statusCode = 204;
        await request.response.close();
      case ('GET', '/v1/devices'):
        _json(request, 200, registeredDevices);
      case ('POST', '/v1/devices'):
        final body = jsonDecode(await utf8.decoder.bind(request).join());
        final device = <String, dynamic>{
          'id': 'dev-${registeredDevices.length + 1}',
          'name': body['name'],
          'platform': body['platform'],
          'enabled': true,
          'soundEnabled': true,
        };
        registeredDevices.add(device);
        _json(request, 200, device);
      case ('GET', '/v1/pending-interactions'):
        _json(request, 200, {
          'generatedAt': '2026-08-14T10:00:00.000Z',
          'interactions': pendingInteractions,
        });
      default:
        request.response.statusCode = 404;
        await request.response.close();
    }
  }

  static Future<void> _json(
    HttpRequest request,
    int status,
    Object? payload,
  ) async {
    request.response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(payload));
    await request.response.close();
  }

  /// Pushes one realtime event frame to the connected client.
  void sendEvent(Map<String, Object?> envelope) {
    _socket!.add(jsonEncode({'type': 'event', 'event': envelope}));
  }

  /// Pushes one authoritative instance-presence snapshot to the client.
  void sendPresence(List<Map<String, Object?>> instances) {
    _socket!.add(
      jsonEncode({'type': 'instance_presence', 'instances': instances}),
    );
  }

  Future<void> stop() async {
    await _socket?.close();
    await _server.close(force: true);
  }
}

/// Records shown alerts instead of touching the platform notification stack.
class RecordingNotificationService implements NotificationService {
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

/// Spec §7.1 terminal event, the canonical realtime envelope.
Map<String, Object?> terminalEnvelope(String eventId) => {
  'eventId': eventId,
  'type': 'terminal',
  'occurredAt': '2026-01-01T00:00:00.000Z',
  'source': {'machine': 'devbox', 'project': 'api', 'directory': '/work/api'},
  'session': {'id': 'ses_1', 'title': 'Implement API'},
  'payload': {'outcome': 'completed', 'elapsedSeconds': 42},
};

/// One `action_required` question envelope matching the pending-snapshot
/// shape the fake gateway serves.
Map<String, Object?> actionRequiredQuestionEnvelope({
  required String eventId,
  required String machine,
  required String project,
  required String directory,
  required String sessionId,
  required String sessionTitle,
  required String requestId,
}) => {
  'eventId': eventId,
  'type': 'action_required',
  'occurredAt': '2026-08-14T09:00:00.000Z',
  'source': {'machine': machine, 'project': project, 'directory': directory},
  'session': {'id': sessionId, 'title': sessionTitle},
  'payload': {
    'requestId': requestId,
    'kind': 'question',
    'questions': [
      {
        'question': 'Which database?',
        'multiple': false,
        'options': [
          {'label': 'PostgreSQL', 'description': 'Production parity'},
        ],
      },
    ],
  },
};

/// One question interaction for the fake gateway's pending snapshot.
Map<String, Object?> pendingQuestionInteraction({
  required String instanceId,
  required String machine,
  required String project,
  required String directory,
  required String sessionId,
  required String sessionTitle,
  required String requestId,
}) => {
  'instanceId': instanceId,
  'kind': 'question',
  'machine': machine,
  'project': project,
  'directory': directory,
  'sessionId': sessionId,
  'sessionTitle': sessionTitle,
  'requestId': requestId,
  'occurredAt': '2026-08-14T09:00:00.000Z',
  'questions': [
    {
      'header': 'Database',
      'question': 'Which database?',
      'options': [
        {'label': 'PostgreSQL', 'description': 'Production parity'},
      ],
      'multiple': false,
      'custom': true,
    },
  ],
};

/// A controllable presence entry for the fake gateway's instance snapshots.
Map<String, Object?> controllablePresence({
  required String instanceId,
  required String machine,
  required String project,
  required String directory,
}) => {
  'instanceId': instanceId,
  'machine': machine,
  'project': project,
  'directory': directory,
  'openCodeVersion': '1.18.18',
  'protocolVersion': 1,
  'state': 'controllable',
  'lastSeenAt': '2026-08-14T10:00:00.000Z',
};

/// An offline presence entry for the fake gateway's instance snapshots.
Map<String, Object?> offlinePresence({
  required String instanceId,
  required String machine,
  required String project,
  required String directory,
}) => {
  'instanceId': instanceId,
  'machine': machine,
  'project': project,
  'directory': directory,
  'openCodeVersion': '1.18.18',
  'protocolVersion': 1,
  'state': 'offline',
  'lastSeenAt': '2026-08-14T09:55:00.000Z',
};

/// Boots the app against a fresh [FakeGateway] with stored credentials and
/// waits until the session is authenticated, the device registered, and the
/// realtime socket connected.
Future<
  ({
    FakeGateway gateway,
    RecordingNotificationService notifications,
    ProviderContainer container,
    InMemoryCredentialsStore store,
  })
>
bootApp(WidgetTester tester) async {
  final gateway = await FakeGateway.start();
  addTearDown(gateway.stop);

  final store = InMemoryCredentialsStore();
  await store.save(refreshToken: 'rt-1', accountEmail: 'user@example.com');
  final notifications = RecordingNotificationService();

  final bootstrap = await AppBootstrap.initialize(
    notificationService: notifications,
    initDesktopWindowing: false,
    extraOverrides: [
      appConfigProvider.overrideWithValue(
        AppConfig(gatewayHttpBase: gateway.httpBase),
      ),
      credentialsStoreProvider.overrideWithValue(store),
      notificationHistoryProvider.overrideWithValue(
        InMemoryNotificationHistory(),
      ),
    ],
  );
  final container = ProviderContainer(overrides: bootstrap.overrides);
  // bootstrap.shutdown() disposes the container; no extra dispose here.
  addTearDown(bootstrap.shutdown);
  bootstrap.attach(container);

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const NotifyApp()),
  );
  await tester.pump();

  await pumpUntil(
    tester,
    () => container.read(authControllerProvider) is Authenticated,
  );
  await pumpUntil(tester, () => gateway.registeredDevices.isNotEmpty);
  await pumpUntil(tester, () => gateway.socketConnected);
  return (
    gateway: gateway,
    notifications: notifications,
    container: container,
    store: store,
  );
}

Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('condition not met within $timeout');
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await tester.pump();
  }
  await tester.pump();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'stored login boots authenticated, registers the device, routes one '
    'terminal event to notification + history, and logout tears down',
    (tester) async {
      final boot = await bootApp(tester);
      final gateway = boot.gateway;
      final notifications = boot.notifications;
      final container = boot.container;

      expect(gateway.refreshCalls, 1);
      expect(container.read(realtimeControllerProvider), isNotNull);
      // A terminal event produces exactly one alert and one history row.
      gateway.sendEvent(terminalEnvelope('evt-terminal-1'));
      await pumpUntil(tester, () => notifications.shown.isNotEmpty);
      await tester.pump();
      expect(notifications.shown, hasLength(1));
      expect(notifications.shown.single.eventId, 'evt-terminal-1');
      final history = container.read(notificationHistoryProvider);
      final historyPage = await history.loadPage(offset: 0, limit: 10);
      expect(historyPage.entries, hasLength(1));
      expect(historyPage.entries.single.eventId, 'evt-terminal-1');

      // The native desktop history page exposes compact source/session context
      // and expands into the complete local detail table.
      await tester.tap(find.text('历史').last);
      await pumpUntil(
        tester,
        () => find
            .byKey(HistoryPage.entryKey('evt-terminal-1'))
            .evaluate()
            .isNotEmpty,
      );
      expect(find.text('api'), findsOneWidget);
      expect(find.text('devbox'), findsOneWidget);
      expect(find.text('Implement API'), findsOneWidget);
      expect(find.text('任务已完成'), findsOneWidget);
      await tester.tap(find.byKey(HistoryPage.entryKey('evt-terminal-1')));
      await pumpUntil(
        tester,
        () => find
            .byKey(HistoryPage.detailsKey('evt-terminal-1'))
            .evaluate()
            .isNotEmpty,
      );
      expect(find.text('/work/api'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(HistoryPage.detailsKey('evt-terminal-1')),
          matching: find.text('devbox'),
        ),
        findsOneWidget,
      );

      // Logout disconnects the socket and clears the stored credentials.
      await container.read(authControllerProvider.notifier).logout();
      await pumpUntil(tester, () => gateway.socketClosed);
      expect(container.read(realtimeControllerProvider), isNull);
      expect(container.read(authControllerProvider), isA<Unauthenticated>());
      expect(await boot.store.read(), isNull);
    },
  );

  testWidgets(
    'clicking a question notification opens the focused request page',
    (tester) async {
      const instanceId = 'inst-1';
      const machine = 'devbox';
      const project = 'api';
      const directory = '/work/api';
      const requestId = 'req-1';

      final boot = await bootApp(tester);
      final gateway = boot.gateway;
      final notifications = boot.notifications;
      final container = boot.container;

      // The gateway serves the authoritative pending request for the click.
      gateway.pendingInteractions = [
        pendingQuestionInteraction(
          instanceId: instanceId,
          machine: machine,
          project: project,
          directory: directory,
          sessionId: 'ses-1',
          sessionTitle: 'Implement API',
          requestId: requestId,
        ),
      ];
      gateway.sendPresence([
        controllablePresence(
          instanceId: instanceId,
          machine: machine,
          project: project,
          directory: directory,
        ),
      ]);
      await pumpUntil(
        tester,
        () => container.read(instancePresencesProvider).isNotEmpty,
      );

      gateway.sendEvent(
        actionRequiredQuestionEnvelope(
          eventId: 'evt-click-1',
          machine: machine,
          project: project,
          directory: directory,
          sessionId: 'ses-1',
          sessionTitle: 'Implement API',
          requestId: requestId,
        ),
      );
      await pumpUntil(tester, () => notifications.shown.isNotEmpty);
      expect(notifications.shown.single.eventId, 'evt-click-1');
      expect(notifications.shown.single.onClick, isNotNull);

      // Clicking the alert deep-links into the interactive request page.
      notifications.shown.single.onClick!();
      await pumpUntil(
        tester,
        () => find.byType(PendingInteractionPage).evaluate().isNotEmpty,
      );
      expect(find.text('待处理问题'), findsOneWidget);
      expect(find.text('Which database?'), findsOneWidget);
      expect(find.byKey(const ValueKey('submit-answer')), findsOneWidget);
    },
  );

  testWidgets(
    'clicking a notification whose request was handled elsewhere reports '
    'and stays on the workbench',
    (tester) async {
      const machine = 'devbox';
      const project = 'api';
      const directory = '/work/api';

      final boot = await bootApp(tester);
      final gateway = boot.gateway;
      final notifications = boot.notifications;

      // The snapshot is empty: the request never reached the gateway.
      gateway.sendEvent(
        actionRequiredQuestionEnvelope(
          eventId: 'evt-gone-1',
          machine: machine,
          project: project,
          directory: directory,
          sessionId: 'ses-1',
          sessionTitle: 'Implement API',
          requestId: 'req-gone',
        ),
      );
      await pumpUntil(tester, () => notifications.shown.isNotEmpty);
      expect(notifications.shown.single.onClick, isNotNull);

      notifications.shown.single.onClick!();
      await pumpUntil(
        tester,
        () => find.text('该请求已被处理或不可用').evaluate().isNotEmpty,
      );
      expect(find.byType(PendingInteractionPage), findsNothing);
    },
  );

  testWidgets(
    'clicking a notification whose owning instance is offline opens the '
    'read-only page',
    (tester) async {
      const instanceId = 'inst-1';
      const machine = 'devbox';
      const project = 'api';
      const directory = '/work/api';
      const requestId = 'req-1';

      final boot = await bootApp(tester);
      final gateway = boot.gateway;
      final notifications = boot.notifications;
      final container = boot.container;

      gateway.pendingInteractions = [
        pendingQuestionInteraction(
          instanceId: instanceId,
          machine: machine,
          project: project,
          directory: directory,
          sessionId: 'ses-1',
          sessionTitle: 'Implement API',
          requestId: requestId,
        ),
      ];
      gateway.sendPresence([
        offlinePresence(
          instanceId: instanceId,
          machine: machine,
          project: project,
          directory: directory,
        ),
      ]);
      await pumpUntil(
        tester,
        () => container.read(instancePresencesProvider).isNotEmpty,
      );

      gateway.sendEvent(
        actionRequiredQuestionEnvelope(
          eventId: 'evt-offline-1',
          machine: machine,
          project: project,
          directory: directory,
          sessionId: 'ses-1',
          sessionTitle: 'Implement API',
          requestId: requestId,
        ),
      );
      await pumpUntil(tester, () => notifications.shown.isNotEmpty);

      notifications.shown.single.onClick!();
      await pumpUntil(
        tester,
        () => find.byType(PendingInteractionPage).evaluate().isNotEmpty,
      );
      expect(find.textContaining('实例离线'), findsOneWidget);
      expect(find.byKey(const ValueKey('submit-answer')), findsNothing);
    },
  );

  testWidgets('desktop settings exposes the bundled sound catalog', (
    tester,
  ) async {
    final boot = await bootApp(tester);
    await boot.container.read(settingsControllerProvider.notifier).hydrated;

    await tester.tap(find.text('设置').last);
    await pumpUntil(
      tester,
      () => find.byKey(SettingsPage.alertSoundPickerKey).evaluate().isNotEmpty,
    );
    expect(
      find.text(
        boot.container.read(settingsControllerProvider).alertSound.displayName,
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(SettingsPage.alertSoundPickerKey));
    await pumpUntil(
      tester,
      () => find.byKey(SettingsPage.alertSoundDialogKey).evaluate().isNotEmpty,
    );

    for (final sound in bundledAlertSounds) {
      expect(find.byKey(SettingsPage.soundOptionKey(sound.id)), findsOneWidget);
      expect(
        find.byKey(SettingsPage.soundPreviewKey(sound.id)),
        findsOneWidget,
      );
    }
    expect(find.byKey(SettingsPage.importSoundKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
