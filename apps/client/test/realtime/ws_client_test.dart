import 'dart:async';
import 'dart:convert';
import 'dart:io' show WebSocketException;
import 'dart:math';

import 'package:client/api/auth_interceptor.dart';
import 'package:client/auth/token_refresher.dart';
import 'package:client/config/app_config.dart';
import 'package:client/realtime/notify_event.dart';
import 'package:client/realtime/ws_client.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// A reconnecting [WsClient] is exercised against a fake connector: every
/// connection attempt is recorded and handed a [FakeWebSocketChannel] the
/// test drives (frames in, close codes out). All timers run on the
/// [fakeAsync] clock; the injected [FixedRandom] makes jitter deterministic
/// (0.5 yields exactly the nominal backoff).

class FixedRandom implements Random {
  FixedRandom(this.value);

  final double value;

  @override
  double nextDouble() => value;

  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => false;
}

class FakeRefresher implements TokenRefresher {
  final List<Future<String?> Function()> _queue = [];
  int calls = 0;

  void enqueue(String? token) => _queue.add(() async => token);

  /// Queues a refresh that stays pending until the returned completer is
  /// completed (or errored) by the test.
  Completer<String?> enqueuePending() {
    final completer = Completer<String?>();
    _queue.add(() => completer.future);
    return completer;
  }

  @override
  Future<String?> refresh() {
    calls++;
    if (_queue.isEmpty) {
      return Future<String?>.value();
    }
    return _queue.removeAt(0)();
  }
}

class FakeWebSocketSink implements WebSocketSink {
  final List<Object?> sent = [];
  bool closed = false;
  int? closeCode;
  String? closeReason;

  @override
  void add(Object? data) => sent.add(data);

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<Object?> stream) async {
    await for (final event in stream) {
      sent.add(event);
    }
  }

  @override
  Future<void> close([int? closeCode, String? closeReason]) {
    closed = true;
    this.closeCode = closeCode;
    this.closeReason = closeReason;
    return Future<void>.value();
  }

  @override
  Future<void> get done => Future<void>.value();
}

class FakeWebSocketChannel extends StreamChannelMixin<Object?>
    implements WebSocketChannel {
  FakeWebSocketChannel({Object? readyError})
    : _ready = readyError == null
          ? Future<void>.value()
          : Future<void>.error(readyError);

  final StreamController<Object?> _incoming = StreamController<Object?>();
  final Future<void> _ready;

  @override
  final FakeWebSocketSink sink = FakeWebSocketSink();

  @override
  int? closeCode;

  @override
  String? closeReason;

  @override
  String? get protocol => null;

  @override
  Future<void> get ready => _ready;

  @override
  Stream<Object?> get stream => _incoming.stream;

  void serverAdd(Object? frame) => _incoming.add(frame);

  void serverClose([int? code, String? reason]) {
    closeCode = code;
    closeReason = reason;
    unawaited(_incoming.close());
  }
}

class ConnectorCall {
  ConnectorCall(this.uri, this.headers);

  final Uri uri;
  final Map<String, dynamic> headers;
}

class FakeConnector {
  final List<ConnectorCall> calls = [];
  final List<FakeWebSocketChannel> channels = [];
  final List<Object> readyErrors = [];

  void failNextReady(Object error) => readyErrors.add(error);

  WebSocketChannel call(Uri uri, Map<String, dynamic> headers) {
    calls.add(ConnectorCall(uri, headers));
    final channel = FakeWebSocketChannel(
      readyError: readyErrors.isEmpty ? null : readyErrors.removeAt(0),
    );
    channels.add(channel);
    return channel;
  }
}

/// Spec §7.1 terminal event, the canonical realtime envelope.
Map<String, Object?> terminalEnvelope() => {
  'eventId': '3b8f9c2e-1a4d-4e5f-9a6b-7c8d9e0f1a2b',
  'type': 'terminal',
  'occurredAt': '2026-01-01T00:00:00.000Z',
  'source': {'machine': 'devbox', 'project': 'api', 'directory': '/work/api'},
  'session': {'id': 'ses_1', 'title': 'Implement API'},
  'payload': {'outcome': 'completed', 'elapsedSeconds': 42},
};

String eventFrame() =>
    jsonEncode({'type': 'event', 'event': terminalEnvelope()});

void main() {
  late InMemoryAccessTokenHolder holder;
  late FakeRefresher refresher;
  late FakeConnector connector;
  late List<WsStatus> statuses;
  late List<NotifyEvent> events;

  GatewayWsClient buildClient({double jitter = 0.5}) {
    final client = GatewayWsClient(
      config: AppConfig(gatewayHttpBase: 'https://gateway.example.com'),
      tokenHolder: holder,
      refresher: refresher,
      connector: connector.call,
      random: FixedRandom(jitter),
    );
    client.status.listen(statuses.add);
    client.events.listen(events.add);
    return client;
  }

  setUp(() {
    holder = InMemoryAccessTokenHolder();
    refresher = FakeRefresher();
    connector = FakeConnector();
    statuses = [];
    events = [];
  });

  group('GatewayWsClient', () {
    test('connects to the gateway WS endpoint with the bearer token', () {
      fakeAsync((async) {
        holder.accessToken = 'tok-1';
        final client = buildClient();

        client.connect();
        async.flushMicrotasks();

        expect(connector.calls, hasLength(1));
        expect(
          connector.calls.single.uri,
          Uri.parse('wss://gateway.example.com/v1/ws'),
        );
        expect(connector.calls.single.headers['Authorization'], 'Bearer tok-1');
        expect(statuses, [WsStatus.connecting, WsStatus.connected]);
      });
    });

    test('connect is idempotent while running', () {
      fakeAsync((async) {
        holder.accessToken = 'tok-1';
        final client = buildClient();

        client.connect();
        async.flushMicrotasks();
        client.connect();
        async.flushMicrotasks();

        expect(connector.calls, hasLength(1));
      });
    });

    test('fetches a token via the refresher when the holder is empty', () {
      fakeAsync((async) {
        refresher.enqueue('fresh-tok');
        final client = buildClient();

        client.connect();
        async.flushMicrotasks();

        expect(refresher.calls, 1);
        expect(
          connector.calls.single.headers['Authorization'],
          'Bearer fresh-tok',
        );
        expect(holder.accessToken, 'fresh-tok');
      });
    });

    test('stays disconnected without hot loop when refresh yields null', () {
      fakeAsync((async) {
        refresher.enqueue(null);
        final client = buildClient();

        client.connect();
        async.flushMicrotasks();

        expect(refresher.calls, 1);
        expect(connector.calls, isEmpty);
        expect(statuses, [WsStatus.connecting, WsStatus.disconnected]);

        async.elapse(const Duration(minutes: 5));
        async.flushMicrotasks();
        expect(refresher.calls, 1, reason: 'no reconnect hot loop');
        expect(connector.calls, isEmpty);
      });
    });

    test('emits parsed events and skips malformed frames', () {
      fakeAsync((async) {
        holder.accessToken = 'tok-1';
        final client = buildClient();

        client.connect();
        async.flushMicrotasks();
        final channel = connector.channels.single;

        channel.serverAdd(eventFrame());
        async.flushMicrotasks();
        expect(events, hasLength(1));
        expect(events.single.type, NotifyEventType.terminal);
        expect(events.single.outcome, TerminalOutcome.completed);

        channel.serverAdd('not json at all');
        channel.serverAdd(jsonEncode(['a', 'list']));
        channel.serverAdd(jsonEncode({'type': 'pong'}));
        channel.serverAdd(jsonEncode({'type': 'event', 'event': 'broken'}));
        channel.serverAdd(
          jsonEncode({
            'type': 'event',
            'event': {'garbage': true},
          }),
        );
        channel.serverAdd(42);
        async.flushMicrotasks();
        expect(events, hasLength(1), reason: 'malformed frames are skipped');

        channel.serverAdd(eventFrame());
        async.flushMicrotasks();
        expect(events, hasLength(2), reason: 'stream stays alive');
      });
    });

    test('refreshes after each 4401 on accepted silent connections', () {
      fakeAsync((async) {
        holder.accessToken = 'tok-1';
        refresher.enqueue('tok-2');
        refresher.enqueue('tok-3');
        refresher.enqueue('tok-4');
        final client = buildClient();

        client.connect();
        async.flushMicrotasks();
        expect(connector.calls.single.headers['Authorization'], 'Bearer tok-1');

        connector.channels[0].serverClose(4401);
        async.flushMicrotasks();
        expect(refresher.calls, 1);
        expect(connector.calls, hasLength(2));
        expect(connector.calls[1].headers['Authorization'], 'Bearer tok-2');
        expect(holder.accessToken, 'tok-2');

        // The HTTP upgrade itself proves the refreshed token worked; no
        // business frame is required before the next token expiry.
        connector.channels[1].serverClose(4401);
        async.flushMicrotasks();
        expect(refresher.calls, 2);
        expect(connector.calls, hasLength(3));
        expect(connector.calls[2].headers['Authorization'], 'Bearer tok-3');

        // Another silent token lifetime refreshes normally as well.
        connector.channels[2].serverClose(4401);
        async.flushMicrotasks();
        expect(refresher.calls, 3);
        expect(connector.calls, hasLength(4));
        expect(connector.calls[3].headers['Authorization'], 'Bearer tok-4');
        expect(statuses.last, WsStatus.connected);
      });
    });

    test('refreshes immediately when the HTTP upgrade returns 401', () {
      fakeAsync((async) {
        holder.accessToken = 'expired-tok';
        refresher.enqueue('fresh-tok');
        connector.failNextReady(
          WebSocketChannelException.from(
            const WebSocketException('Unauthorized', 401),
          ),
        );
        final client = buildClient();

        client.connect();
        async.flushMicrotasks();

        expect(refresher.calls, 1);
        expect(connector.calls, hasLength(2));
        expect(connector.calls[1].headers['Authorization'], 'Bearer fresh-tok');
        expect(holder.accessToken, 'fresh-tok');
        expect(statuses.last, WsStatus.connected);
      });
    });

    test('stops after a refreshed token is rejected during upgrade', () {
      fakeAsync((async) {
        holder.accessToken = 'expired-tok';
        refresher.enqueue('rejected-tok');
        final unauthorized = WebSocketChannelException.from(
          const WebSocketException('Unauthorized', 401),
        );
        connector.failNextReady(unauthorized);
        connector.failNextReady(unauthorized);
        final client = buildClient();

        client.connect();
        async.flushMicrotasks();

        expect(refresher.calls, 1);
        expect(connector.calls, hasLength(2));
        expect(statuses.last, WsStatus.disconnected);
      });
    });

    test('stops reconnecting when a 401 close refresh yields null', () {
      fakeAsync((async) {
        holder.accessToken = 'tok-1';
        refresher.enqueue(null);
        final client = buildClient();

        client.connect();
        async.flushMicrotasks();

        connector.channels.single.serverClose(401);
        async.flushMicrotasks();

        expect(refresher.calls, 1);
        expect(connector.calls, hasLength(1));
        expect(statuses.last, WsStatus.disconnected);

        async.elapse(const Duration(minutes: 5));
        async.flushMicrotasks();
        expect(connector.calls, hasLength(1));
      });
    });

    test('backs off 0.5/1/2/4/8/16/30/30s between reconnect attempts', () {
      const delays = [
        Duration(milliseconds: 500),
        Duration(seconds: 1),
        Duration(seconds: 2),
        Duration(seconds: 4),
        Duration(seconds: 8),
        Duration(seconds: 16),
        Duration(seconds: 30),
        Duration(seconds: 30),
      ];
      fakeAsync((async) {
        holder.accessToken = 'tok-1';
        final client = buildClient();

        client.connect();
        async.flushMicrotasks();
        expect(connector.calls, hasLength(1));

        for (final delay in delays) {
          connector.channels.last.serverClose(1000);
          async.flushMicrotasks();
          final attempts = connector.calls.length;

          async.elapse(delay - const Duration(milliseconds: 1));
          async.flushMicrotasks();
          expect(
            connector.calls,
            hasLength(attempts),
            reason: 'no reconnect before $delay',
          );

          async.elapse(const Duration(milliseconds: 1));
          async.flushMicrotasks();
          expect(
            connector.calls,
            hasLength(attempts + 1),
            reason: 'reconnect after $delay',
          );
        }
      });
    });

    test('applies the injected jitter to the backoff', () {
      fakeAsync((async) {
        holder.accessToken = 'tok-1';
        // Jitter 0.0 scales the nominal 500ms by 0.75 → 375ms.
        final client = buildClient(jitter: 0.0);

        client.connect();
        async.flushMicrotasks();
        connector.channels.single.serverClose(1000);
        async.flushMicrotasks();

        async.elapse(const Duration(milliseconds: 374));
        async.flushMicrotasks();
        expect(connector.calls, hasLength(1));

        async.elapse(const Duration(milliseconds: 1));
        async.flushMicrotasks();
        expect(connector.calls, hasLength(2));
      });
    });

    test('a successful connection resets the backoff', () {
      fakeAsync((async) {
        holder.accessToken = 'tok-1';
        final client = buildClient();

        client.connect();
        async.flushMicrotasks();

        connector.channels.last.serverClose(1000);
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 500));
        async.flushMicrotasks();
        expect(connector.calls, hasLength(2));

        connector.channels.last.serverClose(1000);
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();
        expect(connector.calls, hasLength(3));

        // Third attempt connected and delivered a frame, proving the
        // connection is real: the next drop restarts the backoff at 0.5s.
        connector.channels.last.serverAdd(eventFrame());
        async.flushMicrotasks();
        connector.channels.last.serverClose(1000);
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 499));
        async.flushMicrotasks();
        expect(connector.calls, hasLength(3));
        async.elapse(const Duration(milliseconds: 1));
        async.flushMicrotasks();
        expect(connector.calls, hasLength(4));
      });
    });

    test('disconnect cancels a pending reconnect', () {
      fakeAsync((async) {
        holder.accessToken = 'tok-1';
        final client = buildClient();

        client.connect();
        async.flushMicrotasks();
        connector.channels.single.serverClose(1000);
        async.flushMicrotasks();

        client.disconnect();
        async.flushMicrotasks();
        expect(statuses.last, WsStatus.disconnected);

        async.elapse(const Duration(minutes: 5));
        async.flushMicrotasks();
        expect(connector.calls, hasLength(1));
      });
    });

    test('disconnect then connect in the same microtask starts a single '
        'new run', () {
      fakeAsync((async) {
        holder.accessToken = 'tok-1';
        final client = buildClient();

        client.connect();
        async.flushMicrotasks();

        // Drop into a pending backoff, then disconnect+connect
        // synchronously while the old run is suspended in its wait.
        connector.channels.single.serverClose(1000);
        async.flushMicrotasks();
        expect(connector.calls, hasLength(1));

        client.disconnect();
        client.connect();
        async.flushMicrotasks();

        // The stale run must not reconnect alongside the new one.
        expect(connector.calls, hasLength(2));
        expect(statuses.last, WsStatus.connected);

        // No clobbered timer: nothing fires after the old backoff would
        // have elapsed.
        async.elapse(const Duration(minutes: 5));
        async.flushMicrotasks();
        expect(connector.calls, hasLength(2));
        expect(statuses.last, WsStatus.connected);

        // The new run reconnects normally after a drop.
        connector.channels.last.serverClose(1000);
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 500));
        async.flushMicrotasks();
        expect(connector.calls, hasLength(3));
      });
    });

    test(
      'a stale run\'s failing 4401 refresh does not stop the new session',
      () {
        fakeAsync((async) {
          holder.accessToken = 'tok-1';
          final pending = refresher.enqueuePending();
          final client = buildClient();

          client.connect();
          async.flushMicrotasks();
          expect(connector.calls, hasLength(1));

          // The 4401 close suspends the old run awaiting the refresh.
          connector.channels[0].serverClose(4401);
          async.flushMicrotasks();
          expect(refresher.calls, 1);

          // disconnect→connect while the stale refresh is pending.
          client.disconnect();
          client.connect();
          async.flushMicrotasks();
          expect(connector.calls, hasLength(2));
          expect(statuses.last, WsStatus.connected);

          // The stale refresh errors: the new session must survive.
          pending.completeError(StateError('network down'));
          async.flushMicrotasks();
          expect(statuses.last, WsStatus.connected);

          // The new session is alive and still reconnects after a drop.
          connector.channels[1].serverClose(1000);
          async.flushMicrotasks();
          async.elapse(const Duration(milliseconds: 500));
          async.flushMicrotasks();
          expect(connector.calls, hasLength(3));
          expect(statuses.last, WsStatus.connected);
        });
      },
    );

    test(
      'disconnect while connected closes the channel and stops the loop',
      () {
        fakeAsync((async) {
          holder.accessToken = 'tok-1';
          final client = buildClient();

          client.connect();
          async.flushMicrotasks();

          client.disconnect();
          async.flushMicrotasks();
          expect(connector.channels.single.sink.closed, isTrue);
          expect(statuses.last, WsStatus.disconnected);

          // A late close from the server must not trigger a reconnect.
          connector.channels.single.serverClose(1000);
          async.flushMicrotasks();
          async.elapse(const Duration(minutes: 5));
          async.flushMicrotasks();
          expect(connector.calls, hasLength(1));
          expect(statuses.last, WsStatus.disconnected);
        });
      },
    );
  });
}
