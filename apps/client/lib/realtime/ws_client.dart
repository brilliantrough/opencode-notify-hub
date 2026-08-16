import 'dart:async';
import 'dart:convert';
import 'dart:io' show HttpStatus, WebSocketException;
import 'dart:math';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../api/auth_interceptor.dart';
import '../auth/token_refresher.dart';
import '../config/app_config.dart';
import 'instance_presence.dart';
import 'notify_event.dart';

/// Connection state of a [WsClient].
enum WsStatus { disconnected, connecting, connected }

/// Realtime event stream of the notification gateway.
///
/// [connect] starts a reconnecting session and is idempotent; [disconnect]
/// stops it (cancelling any pending reconnect) and closes the socket.
abstract class WsClient {
  /// Parsed events; malformed frames are skipped, never emitted here.
  Stream<NotifyEvent> get events;

  /// Authoritative full snapshots of the account's OpenCode instances.
  Stream<List<OpenCodeInstancePresence>> get instancePresences;

  /// Status transitions, emitted on change only.
  Stream<WsStatus> get status;

  /// Starts the connect/reconnect loop. No-op while already running.
  void connect();

  /// Stops the loop, cancels any pending reconnect, and closes the socket.
  void disconnect();
}

/// Opens a [WebSocketChannel] to [uri] with the given HTTP upgrade [headers].
typedef WsConnector =
    WebSocketChannel Function(Uri uri, Map<String, dynamic> headers);

/// [WsClient] for the gateway `/v1/ws` endpoint with bearer auth,
/// exponential-backoff reconnects, and single-refresh `4401`/`401` recovery.
///
/// Auth: the access token comes from [AccessTokenHolder]; when empty it is
/// fetched once via [TokenRefresher]. A `4401`/`401` close triggers exactly
/// one refresh and an immediate retry with the new token. The same recovery
/// applies when the HTTP upgrade itself is rejected with `401`, which occurs
/// when a connection outage outlives the access token. Whenever a refresh
/// yields no token (session gone) the client stays disconnected instead of
/// hot-looping.
///
/// Backoff between ordinary reconnect attempts starts at 500ms, doubles up to
/// a 30s cap, and is jittered ±25% using the injected [Random] (the zone
/// clock drives the timers, so `fake_async` controls them in tests).
class GatewayWsClient implements WsClient {
  GatewayWsClient({
    required AppConfig config,
    required AccessTokenHolder tokenHolder,
    required TokenRefresher refresher,
    WsConnector? connector,
    Random? random,
    Duration connectTimeout = const Duration(seconds: 10),
  }) : _config = config,
       _tokenHolder = tokenHolder,
       _refresher = refresher,
       _connector = connector ?? _defaultConnector,
       _random = random ?? Random(),
       _connectTimeout = connectTimeout;

  static const Duration _baseBackoff = Duration(milliseconds: 500);
  static const Duration _maxBackoff = Duration(seconds: 30);
  static const Duration _pingInterval = Duration(seconds: 20);

  static WebSocketChannel _defaultConnector(
    Uri uri,
    Map<String, dynamic> headers,
  ) => IOWebSocketChannel.connect(
    uri,
    headers: headers,
    pingInterval: _pingInterval,
  );

  final AppConfig _config;
  final AccessTokenHolder _tokenHolder;
  final TokenRefresher _refresher;
  final WsConnector _connector;
  final Random _random;
  final Duration _connectTimeout;

  final StreamController<NotifyEvent> _events =
      StreamController<NotifyEvent>.broadcast();
  final StreamController<WsStatus> _status =
      StreamController<WsStatus>.broadcast();
  final StreamController<List<OpenCodeInstancePresence>> _instancePresences =
      StreamController<List<OpenCodeInstancePresence>>.broadcast();

  bool _running = false;

  /// Incremented on every [disconnect]. A run loop captures it at start and
  /// bails out after any await once it no longer matches, so a stale loop
  /// can never touch the new run's timers/channels or reconnect alongside
  /// it after a synchronous disconnect→connect.
  int _epoch = 0;
  WsStatus _lastStatus = WsStatus.disconnected;
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  void Function()? _cancelWait;

  @override
  Stream<NotifyEvent> get events => _events.stream;

  @override
  Stream<List<OpenCodeInstancePresence>> get instancePresences =>
      _instancePresences.stream;

  @override
  Stream<WsStatus> get status => _status.stream;

  @override
  void connect() {
    if (_running) {
      return;
    }
    _running = true;
    unawaited(_run());
  }

  @override
  void disconnect() {
    if (!_running) {
      return;
    }
    _running = false;
    _epoch++;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _cancelWait?.call();
    _cancelWait = null;
    final channel = _channel;
    _channel = null;
    if (channel != null) {
      unawaited(channel.sink.close());
    }
    _setStatus(WsStatus.disconnected);
  }

  void _setStatus(WsStatus status) {
    if (status == _lastStatus) {
      return;
    }
    _lastStatus = status;
    _status.add(status);
  }

  /// Stops the loop when the session is unrecoverable (no token anywhere).
  void _stop() {
    _running = false;
    _setStatus(WsStatus.disconnected);
  }

  Future<void> _run() async {
    final epoch = _epoch;

    /// Whether this loop was superseded by a [disconnect] (possibly
    /// followed by a new [connect]) while suspended at an await. A stale
    /// loop must exit immediately without touching the new run's state.
    bool isStale() => epoch != _epoch;

    var attempt = 0;
    var authRetried = false;

    while (_running && !isStale()) {
      _setStatus(WsStatus.connecting);

      var token = _tokenHolder.accessToken;
      if (token == null) {
        final String? refreshed;
        try {
          refreshed = await _refresher.refresh();
        } catch (_) {
          // Transient refresh failure: retry like any failed attempt.
          await _waitBackoff(epoch, attempt++);
          continue;
        }
        if (isStale() || !_running) {
          return;
        }
        if (refreshed == null) {
          return _stop();
        }
        _tokenHolder.accessToken = refreshed;
        token = refreshed;
      }

      final WebSocketChannel channel;
      try {
        channel = await _openChannel(token);
      } catch (error) {
        if (isStale() || !_running) {
          return;
        }
        if (_isUnauthorizedHandshake(error)) {
          if (authRetried) {
            return _stop();
          }
          final String? refreshed;
          try {
            refreshed = await _refresher.refresh();
          } catch (_) {
            if (isStale() || !_running) {
              return;
            }
            return _stop();
          }
          if (isStale() || !_running) {
            return;
          }
          if (refreshed == null) {
            return _stop();
          }
          _tokenHolder.accessToken = refreshed;
          authRetried = true;
          continue;
        }
        await _waitBackoff(epoch, attempt++);
        continue;
      }
      if (isStale() || !_running) {
        unawaited(channel.sink.close());
        return;
      }

      _channel = channel;
      // A completed HTTP upgrade proves the token was accepted. This must
      // reset the auth guard even when the connection stays quiet for an
      // entire token lifetime and no business frame arrives.
      authRetried = false;
      _setStatus(WsStatus.connected);

      try {
        await for (final frame in channel.stream) {
          // A received frame proves the connection is real and the token
          // was accepted: reset both backoff and the auth-retry guard.
          attempt = 0;
          authRetried = false;
          _handleFrame(frame);
          if (isStale() || !_running) {
            break;
          }
        }
      } catch (_) {
        // A stream error is just a dropped connection: reconnect below.
      }
      if (isStale() || !_running) {
        return;
      }
      _channel = null;

      final closeCode = channel.closeCode;
      if (closeCode == 4401 || closeCode == 401) {
        if (authRetried) {
          return _stop();
        }
        final String? refreshed;
        try {
          refreshed = await _refresher.refresh();
        } catch (_) {
          // A stale loop must not stop the session that superseded it.
          if (isStale() || !_running) {
            return;
          }
          return _stop();
        }
        if (isStale() || !_running) {
          return;
        }
        if (refreshed == null) {
          return _stop();
        }
        _tokenHolder.accessToken = refreshed;
        authRetried = true;
        continue;
      }

      await _waitBackoff(epoch, attempt++);
    }
  }

  Future<WebSocketChannel> _openChannel(String token) async {
    final channel = _connector(Uri.parse(_config.gatewayWsBase), {
      'Authorization': 'Bearer $token',
    });
    try {
      await channel.ready.timeout(_connectTimeout);
      return channel;
    } catch (_) {
      unawaited(channel.sink.close());
      rethrow;
    }
  }

  /// Waits out the backoff for [attempt]; returns immediately when
  /// [disconnect] cancels the wait. If this loop's [epoch] is stale by the
  /// time the wait ends, the new run's timer fields are left untouched.
  Future<void> _waitBackoff(int epoch, int attempt) async {
    final completer = Completer<void>();
    _reconnectTimer = Timer(_backoffDelay(attempt), () {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });
    _cancelWait = () {
      if (!completer.isCompleted) {
        completer.complete();
      }
    };
    await completer.future;
    if (epoch == _epoch) {
      _reconnectTimer = null;
      _cancelWait = null;
    }
  }

  Duration _backoffDelay(int attempt) {
    // Clamp before shifting so the doubling cannot overflow.
    final scaled = _baseBackoff * (1 << min(attempt, 6));
    final capped = scaled > _maxBackoff ? _maxBackoff : scaled;
    final jitter = 0.75 + 0.5 * _random.nextDouble();
    return capped * jitter;
  }

  /// `IOWebSocketChannel.ready` wraps the `dart:io` upgrade failure, whose
  /// typed status code lets us distinguish an expired token from a network
  /// failure without parsing exception text.
  bool _isUnauthorizedHandshake(Object error) {
    final inner = error is WebSocketChannelException ? error.inner : error;
    return inner is WebSocketException &&
        inner.httpStatusCode == HttpStatus.unauthorized;
  }

  /// Parses one `{"type": "event", "event": ...}` frame into [events].
  /// Malformed JSON, unknown message types, and invalid envelopes are
  /// skipped without affecting the stream. Any error from
  /// [NotifyEvent.parse] (including a non-[FormatException] such as a
  /// `TypeError` from an internal cast) is treated as malformed so a bad
  /// frame can never tear down a healthy connection.
  void _handleFrame(Object? frame) {
    if (frame is! String) {
      return;
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(frame);
    } on FormatException {
      return;
    }
    if (decoded is! Map<String, dynamic>) {
      return;
    }
    if (decoded['type'] == 'instance_presence') {
      final rawInstances = decoded['instances'];
      if (rawInstances is! List) {
        return;
      }
      try {
        final instances = rawInstances
            .map(
              (item) => OpenCodeInstancePresence.parse(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(growable: false);
        _instancePresences.add(instances);
      } catch (_) {
        // One invalid item invalidates the authoritative snapshot.
      }
      return;
    }
    if (decoded['type'] != 'event') {
      return;
    }
    final payload = decoded['event'];
    if (payload is! Map<String, dynamic>) {
      return;
    }
    final NotifyEvent event;
    try {
      event = NotifyEvent.parse(payload);
    } catch (_) {
      return;
    }
    _events.add(event);
  }
}
