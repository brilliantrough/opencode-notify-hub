import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../auth/auth_controller.dart';
import '../config/server_config.dart';

const _maxRequestBodyBytes = 500000;

typedef WebUiSocketConnector =
    WebSocketChannel Function(Uri uri, Map<String, dynamic> headers);

typedef WebUiTunnelFactory = GatewayWebUiTunnel Function(String instanceId);

final webUiTunnelFactoryProvider = Provider<WebUiTunnelFactory>((ref) {
  final config = ref.watch(appConfigProvider);
  final tokenHolder = ref.watch(accessTokenHolderProvider);
  final refresher = ref.watch(tokenRefresherProvider);
  return (instanceId) {
    final token = tokenHolder.accessToken;
    if (token == null) throw StateError('No authenticated session');
    return GatewayWebUiTunnel(
      gatewayUri: Uri.parse(config.gatewayWebUiWsBase),
      accessToken: token,
      instanceId: instanceId,
      refreshToken: () async {
        final token = await refresher.refresh();
        if (token != null) tokenHolder.accessToken = token;
        return token;
      },
    );
  };
});

class GatewayWebUiTunnel {
  GatewayWebUiTunnel({
    required this.gatewayUri,
    required this.accessToken,
    required this.instanceId,
    WebUiSocketConnector? connector,
    this.initialPath = '/',
    this.refreshToken,
  }) : _connector = connector ?? _defaultConnector;

  final Uri gatewayUri;
  String accessToken;
  final Future<String?> Function()? refreshToken;
  final String instanceId;
  final WebUiSocketConnector _connector;
  String initialPath;

  final Map<String, _PendingResponse> _pending = {};
  final Completer<void> _done = Completer<void>();
  WebSocketChannel? _channel;
  StreamSubscription<Object?>? _subscription;
  HttpServer? _server;
  String? _tunnelId;
  Completer<String>? _ready;
  Future<void>? _closing;
  var _closed = false;
  var _nextRequest = 0;
  final _connectionChanges = StreamController<bool>.broadcast();
  final _random = Random();
  Timer? _renewal;
  Timer? _retry;
  int _attempt = 0;
  int _generation = 0;
  bool _connected = false;
  bool _reconnecting = false;

  Stream<bool> get connectionChanges => _connectionChanges.stream;

  Future<void> get done => _done.future;

  static WebSocketChannel _defaultConnector(
    Uri uri,
    Map<String, dynamic> headers,
  ) => IOWebSocketChannel.connect(
    uri,
    headers: headers,
    pingInterval: const Duration(seconds: 20),
  );

  Future<Uri> start() async {
    if (_closed) throw StateError('WebUI tunnel is closed');
    if (_channel != null) throw StateError('WebUI tunnel already started');
    try {
      await _connect();
    } catch (error) {
      if (!_unauthorized(error) || refreshToken == null) rethrow;
      await _refreshAccess();
      await _connect();
    }
    if (_closed) throw StateError('WebUI tunnel was closed while opening');
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    if (_closed) {
      await server.close(force: true);
      throw StateError('WebUI tunnel was closed while opening');
    }
    _server = server;
    server.listen((request) {
      unawaited(
        _handleRequest(request).catchError((Object _) async {
          try {
            await request.response.close();
          } catch (_) {
            /* Browser disconnected. */
          }
        }),
      );
    });
    if (!_connected) _scheduleReconnect();
    final path = initialPath.startsWith('/') ? initialPath : '/$initialPath';
    return Uri(
      scheme: 'http',
      host: '127.0.0.1',
      port: server.port,
      path: path,
    );
  }

  bool _unauthorized(Object error) {
    final inner = error is WebSocketChannelException ? error.inner : error;
    return inner is WebSocketException && inner.httpStatusCode == 401;
  }

  Future<void> _connect() async {
    final generation = ++_generation;
    final channel = _connector(gatewayUri, {
      'Authorization': 'Bearer $accessToken',
    });
    _channel = channel;
    try {
      await channel.ready.timeout(const Duration(seconds: 10));
      if (_closed || generation != _generation) {
        throw StateError('Tunnel closed');
      }
      final ready = Completer<String>();
      _ready = ready;
      final waiting = ready.future.timeout(const Duration(seconds: 10));
      _subscription = channel.stream.listen(
        (raw) {
          if (generation != _generation) return;
          unawaited(_handleFrame(raw).catchError((Object _) => _lost(channel)));
        },
        onError: (Object error) {
          if (!ready.isCompleted) ready.completeError(error);
          _lost(channel);
        },
        onDone: () {
          if (!ready.isCompleted) {
            ready.completeError(StateError('Tunnel disconnected'));
          }
          _lost(channel);
        },
      );
      try {
        channel.sink.add(
          jsonEncode({'type': 'webui_tunnel_open', 'instanceId': instanceId}),
        );
      } catch (error) {
        if (!ready.isCompleted) ready.completeError(error);
      }
      _tunnelId = await waiting;
      if (_closed || generation != _generation) {
        throw StateError('Tunnel closed');
      }
      _connected = true;
      _attempt = 0;
      _connectionChanges.add(true);
    } catch (_) {
      if (_channel == channel) {
        _channel = null;
        _generation++;
        _renewal?.cancel();
        await _subscription?.cancel();
        _subscription = null;
        unawaited(channel.sink.close());
      }
      rethrow;
    }
  }

  void _lost(WebSocketChannel channel) {
    if (_closed || _channel != channel) return;
    _channel = null;
    _generation++;
    _connected = false;
    _tunnelId = null;
    _renewal?.cancel();
    final subscription = _subscription;
    _subscription = null;
    unawaited(subscription?.cancel());
    unawaited(channel.sink.close());
    final pending = _pending.values.toList();
    _pending.clear();
    for (final response in pending) {
      unawaited(response.fail().catchError((Object _) {}));
    }
    if (_server == null) return; // Initial failure is reported by start().
    _connectionChanges.add(false);
    _scheduleReconnect(channel.closeCode == 4401);
  }

  void _scheduleReconnect([bool expired = false]) {
    if (_closed || _retry != null) return;
    final ms = min(500 * (1 << min(_attempt++, 6)), 30000);
    _retry = Timer(
      Duration(
        milliseconds: expired && _attempt == 1
            ? 0
            : (ms * (0.75 + _random.nextDouble() * 0.5)).round(),
      ),
      () {
        _retry = null;
        unawaited(_reconnect(expired));
      },
    );
  }

  Future<void> _refreshAccess() async {
    final token = await refreshToken?.call();
    if (_closed) throw StateError('Tunnel closed');
    if (token == null) {
      await close();
      throw StateError('Authentication expired');
    }
    accessToken = token;
  }

  Future<void> _reconnect(bool expired) async {
    if (_closed || _reconnecting) return;
    _reconnecting = true;
    try {
      if (expired) await _refreshAccess();
      if (_closed) return;
      await _connect();
    } catch (error) {
      if (_closed) return;
      if (_unauthorized(error)) {
        try {
          await _refreshAccess();
        } catch (_) {
          _scheduleReconnect(true);
          return;
        }
      }
      _scheduleReconnect();
    } finally {
      _reconnecting = false;
    }
  }

  void resume({bool afterSleep = false}) {
    if (_closed || _server == null || _reconnecting) return;
    final channel = _channel;
    if (afterSleep && _connected && channel != null) _lost(channel);
    if (_connected || _channel != null) return;
    _retry?.cancel();
    _retry = null;
    unawaited(_reconnect(false));
  }

  void _scheduleRenewal(int expiresAtMs) {
    if (refreshToken == null || _closed) return;
    _renewal?.cancel();
    final delay = max(
      1000,
      expiresAtMs - DateTime.now().millisecondsSinceEpoch - 60000,
    );
    _renewal = Timer(Duration(milliseconds: delay), () => unawaited(_renew()));
  }

  Future<void> _renew() async {
    final channel = _channel;
    if (_closed || channel == null) return;
    try {
      await _refreshAccess();
      if (_closed || _channel != channel) return;
      channel.sink.add(
        jsonEncode({'type': 'webui_auth_refresh', 'accessToken': accessToken}),
      );
      // The acknowledged expiry reschedules this timer; missing acknowledgements reconnect.
      _renewal = Timer(const Duration(seconds: 10), () => _lost(channel));
    } catch (_) {
      if (!_closed && _channel == channel) {
        _renewal = Timer(const Duration(seconds: 5), () => unawaited(_renew()));
      }
    }
  }

  Future<void> close() => _closing ??= _close();

  Future<void> _close() async {
    if (_closed) {
      if (!_done.isCompleted) _done.complete();
      return;
    }
    _closed = true;
    _generation++;
    _renewal?.cancel();
    _retry?.cancel();
    _retry = null;
    if (_ready != null && !_ready!.isCompleted) {
      _ready!.completeError(StateError('Tunnel closed'));
    }
    final tunnelId = _tunnelId;
    final channel = _channel;
    if (tunnelId != null && channel != null) {
      try {
        channel.sink.add(
          jsonEncode({'type': 'webui_tunnel_close', 'tunnelId': tunnelId}),
        );
      } catch (_) {
        // The remote side may already have closed the tunnel.
      }
    }
    try {
      try {
        await _server?.close(force: true);
      } catch (_) {
        // Teardown remains best-effort when the local listener already failed.
      }
      try {
        await _subscription?.cancel();
      } catch (_) {
        // The WebSocket stream may already have terminated with an error.
      }
      try {
        await channel?.sink.close();
      } catch (_) {
        // The remote peer may already be unavailable.
      }
      final responses = _pending.values.toList();
      _pending.clear();
      for (final pending in responses) {
        try {
          await pending.fail();
        } catch (_) {
          // One broken browser response must not prevent the rest from closing.
        }
      }
    } finally {
      unawaited(_connectionChanges.close());
      if (!_done.isCompleted) _done.complete();
    }
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final tunnelId = _tunnelId;
    final channel = _channel;
    // A local browser may only address this listener, never use it as a forward proxy.
    final origin = request.headers.value('origin');
    if (request.uri.hasAuthority ||
        request.headers.value('host') != '127.0.0.1:${_server?.port}' ||
        (origin != null && origin != 'http://127.0.0.1:${_server?.port}')) {
      request.response.statusCode = HttpStatus.forbidden;
      await request.response.close();
      return;
    }
    if (_closed || !_connected || tunnelId == null || channel == null) {
      request.response.statusCode = HttpStatus.serviceUnavailable;
      request.response.headers.set('retry-after', '2');
      if (request.headers.value('accept')?.contains('text/html') ?? false) {
        request.response.headers.contentType = ContentType.html;
        request.response.write(
          '<!doctype html><meta charset="utf-8"><meta http-equiv="refresh" content="2"><title>正在重连</title><p>正在重新连接 OpenCode，请保持 Notify 运行…</p>',
        );
      }
      await request.response.close();
      return;
    }
    final body = <int>[];
    try {
      await for (final chunk in request) {
        body.addAll(chunk);
        if (body.length > _maxRequestBodyBytes) {
          request.response.statusCode = HttpStatus.requestEntityTooLarge;
          await request.response.close();
          return;
        }
      }
    } catch (_) {
      request.response.statusCode = HttpStatus.badRequest;
      await request.response.close();
      return;
    }
    if (!_connected || _channel != channel || _tunnelId != tunnelId) {
      request.response.statusCode = HttpStatus.serviceUnavailable;
      await request.response.close();
      return;
    }
    final requestId = _requestId();
    final pending = _PendingResponse(request.response);
    _pending[requestId] = pending;
    unawaited(
      request.response.done.then(
        (_) => _cancelRequest(requestId, pending, tunnelId, channel),
        onError: (Object _) =>
            _cancelRequest(requestId, pending, tunnelId, channel),
      ),
    );
    final headers = <String, List<String>>{};
    request.headers.forEach((name, values) {
      headers[name] = values;
    });
    try {
      channel.sink.add(
        jsonEncode({
          'type': 'webui_http_request',
          'tunnelId': tunnelId,
          'requestId': requestId,
          'method': request.method,
          'path': request.uri.toString(),
          'headers': headers,
          if (body.isNotEmpty) 'body': base64Encode(body),
        }),
      );
    } catch (_) {
      _pending.remove(requestId);
      await pending.fail();
      _lost(channel);
    }
    await pending.done;
  }

  void _cancelRequest(
    String id,
    _PendingResponse response,
    String tunnelId,
    WebSocketChannel channel,
  ) {
    if (_pending[id] != response) return;
    _pending.remove(id);
    if (_channel == channel) {
      try {
        channel.sink.add(
          jsonEncode({
            'type': 'webui_http_cancel',
            'tunnelId': tunnelId,
            'requestId': id,
          }),
        );
      } catch (_) {
        _lost(channel);
      }
    }
    unawaited(response.fail().catchError((Object _) {}));
  }

  Future<void> _handleFrame(Object? raw) async {
    if (raw is! String) return;
    final Object? value;
    try {
      value = jsonDecode(raw);
    } on FormatException {
      return;
    }
    if (value is! Map<String, dynamic>) return;
    if ((value['type'] == 'webui_tunnel_ready' ||
            value['type'] == 'webui_auth_ready') &&
        value['expiresAtMs'] is int) {
      _scheduleRenewal(value['expiresAtMs'] as int);
    }
    if (value['type'] == 'webui_tunnel_ready' && value['tunnelId'] is String) {
      if (!(_ready?.isCompleted ?? true)) {
        _ready!.complete(value['tunnelId'] as String);
      }
      return;
    }
    if (value['type'] == 'webui_tunnel_error') {
      if (!(_ready?.isCompleted ?? true)) {
        _ready!.completeError(StateError('OpenCode instance is unavailable'));
      }
      return;
    }
    if (value['tunnelId'] != _tunnelId || value['requestId'] is! String) {
      return;
    }
    final requestId = value['requestId'] as String;
    final pending = _pending[requestId];
    if (pending == null) return;
    switch (value['type']) {
      case 'webui_http_response_start':
        final status = value['status'];
        final headers = value['headers'];
        if (status is int && headers is Map) {
          pending.start(status, headers);
        }
        return;
      case 'webui_http_response_chunk':
        final body = value['body'];
        if (body is String) {
          try {
            await pending.add(base64Decode(body));
          } catch (_) {
            final channel = _channel;
            final tunnelId = _tunnelId;
            if (channel != null && tunnelId != null) {
              _cancelRequest(requestId, pending, tunnelId, channel);
            }
          }
        }
        return;
      case 'webui_http_response_end':
        _pending.remove(requestId);
        try {
          await pending.end();
        } catch (_) {
          /* Browser already disconnected. */
        }
        return;
    }
  }

  String _requestId() {
    final value = _nextRequest++;
    final hex = value.toRadixString(16).padLeft(12, '0');
    return '00000000-0000-4000-8000-$hex';
  }
}

class _PendingResponse {
  _PendingResponse(this.response);

  final HttpResponse response;
  final Completer<void> _done = Completer<void>();
  var _started = false;
  var _ended = false;
  Future<void> _writes = Future<void>.value();

  Future<void> get done => _done.future;

  void start(int status, Map<dynamic, dynamic> rawHeaders) {
    if (_started || _ended) return;
    _started = true;
    response.statusCode = status;
    for (final entry in rawHeaders.entries) {
      final name = entry.key;
      final values = entry.value;
      if (name is! String || values is! List) continue;
      final lower = name.toLowerCase();
      if (lower == 'connection' ||
          lower == 'transfer-encoding' ||
          lower == 'content-length') {
        continue;
      }
      for (final value in values) {
        if (value is String) response.headers.add(name, value);
      }
    }
    if (response.headers.contentLength == -1) {
      response.headers.chunkedTransferEncoding = true;
    }
    if (response.headers.contentType?.mimeType == 'text/event-stream') {
      response.bufferOutput = false;
    }
  }

  Future<void> add(List<int> bytes) {
    if (_ended) return Future<void>.value();
    if (!_started) start(HttpStatus.badGateway, const {});
    _writes = _writes.then((_) async {
      response.add(bytes);
      await response.flush();
    });
    return _writes;
  }

  Future<void> end() async {
    if (_ended) return;
    _ended = true;
    if (!_started) response.statusCode = HttpStatus.badGateway;
    try {
      await _writes;
    } finally {
      try {
        await response.close();
      } finally {
        if (!_done.isCompleted) _done.complete();
      }
    }
  }

  Future<void> fail() async {
    if (_ended) return;
    if (!_started) response.statusCode = HttpStatus.badGateway;
    await end();
  }
}
