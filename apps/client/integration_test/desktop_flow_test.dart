import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:client/app.dart';
import 'package:client/auth/auth_controller.dart';
import 'package:client/auth/auth_state.dart';
import 'package:client/auth/credentials_store.dart';
import 'package:client/bootstrap.dart';
import 'package:client/config/app_config.dart';
import 'package:client/history/notification_history.dart';
import 'package:client/notifications/notification_service.dart';
import 'package:client/realtime/realtime_controller.dart';
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
      final gateway = await FakeGateway.start();
      addTearDown(gateway.stop);

      // Stored login: credentials exist before the app boots.
      final store = InMemoryCredentialsStore();
      await store.save(
        refreshToken: 'rt-1',
        accountEmail: 'user@example.com',
      );
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
        UncontrolledProviderScope(
          container: container,
          child: const NotifyApp(),
        ),
      );
      await tester.pump();

      // Stored credentials restore the session via the fake gateway.
      await pumpUntil(
        tester,
        () => container.read(authControllerProvider) is Authenticated,
      );
      expect(gateway.refreshCalls, 1);

      // Bootstrap registers the current device with the gateway.
      await pumpUntil(tester, () => gateway.registeredDevices.isNotEmpty);

      // The realtime controller connects the WebSocket while authenticated.
      await pumpUntil(tester, () => gateway.socketConnected);
      expect(container.read(realtimeControllerProvider), isNotNull);

      // A terminal event produces exactly one alert and one history row.
      gateway.sendEvent(terminalEnvelope('evt-terminal-1'));
      await pumpUntil(tester, () => notifications.shown.isNotEmpty);
      await tester.pump();
      expect(notifications.shown, hasLength(1));
      expect(notifications.shown.single.eventId, 'evt-terminal-1');
      final history = container.read(notificationHistoryProvider);
      expect(history.entries, hasLength(1));
      expect(history.entries.single.eventId, 'evt-terminal-1');

      // Logout disconnects the socket and clears the stored credentials.
      await container.read(authControllerProvider.notifier).logout();
      await pumpUntil(tester, () => gateway.socketClosed);
      expect(container.read(realtimeControllerProvider), isNull);
      expect(container.read(authControllerProvider), isA<Unauthenticated>());
      expect(await store.read(), isNull);
    },
  );
}
