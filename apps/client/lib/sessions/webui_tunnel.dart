import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
  return (instanceId) {
    final token = tokenHolder.accessToken;
    if (token == null) throw StateError('No authenticated session');
    return GatewayWebUiTunnel(
      gatewayUri: Uri.parse(config.gatewayWebUiWsBase),
      accessToken: token,
      instanceId: instanceId,
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
  }) : _connector = connector ?? _defaultConnector;

  final Uri gatewayUri;
  final String accessToken;
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

  Future<void> get done => _done.future;

  static WebSocketChannel _defaultConnector(
    Uri uri,
    Map<String, dynamic> headers,
  ) => IOWebSocketChannel.connect(uri, headers: headers);

  Future<Uri> start() async {
    if (_closed) throw StateError('WebUI tunnel is closed');
    if (_channel != null) throw StateError('WebUI tunnel already started');
    final channel = _connector(gatewayUri, {
      'Authorization': 'Bearer $accessToken',
    });
    _channel = channel;
    await channel.ready.timeout(const Duration(seconds: 10));
    if (_closed) throw StateError('WebUI tunnel was closed while opening');
    final ready = Completer<String>();
    _ready = ready;
    _subscription = channel.stream.listen(
      (raw) => unawaited(_handleFrame(raw)),
      onError: (Object error, StackTrace stackTrace) {
        if (!ready.isCompleted) ready.completeError(error, stackTrace);
        unawaited(close());
      },
      onDone: () {
        if (!ready.isCompleted) {
          ready.completeError(StateError('WebUI tunnel closed before opening'));
        }
        unawaited(close());
      },
    );
    channel.sink.add(
      jsonEncode({'type': 'webui_tunnel_open', 'instanceId': instanceId}),
    );
    _tunnelId = await ready.future.timeout(const Duration(seconds: 10));
    if (_closed) throw StateError('WebUI tunnel was closed while opening');
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    if (_closed) {
      await server.close(force: true);
      throw StateError('WebUI tunnel was closed while opening');
    }
    _server = server;
    server.listen(_handleRequest);
    final path = initialPath.startsWith('/') ? initialPath : '/$initialPath';
    return Uri(
      scheme: 'http',
      host: '127.0.0.1',
      port: server.port,
      path: path,
    );
  }

  Future<void> close() => _closing ??= _close();

  Future<void> _close() async {
    if (_closed) {
      if (!_done.isCompleted) _done.complete();
      return;
    }
    _closed = true;
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
      for (final pending in _pending.values) {
        try {
          await pending.fail();
        } catch (_) {
          // One broken browser response must not prevent the rest from closing.
        }
      }
      _pending.clear();
    } finally {
      if (!_done.isCompleted) _done.complete();
    }
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final tunnelId = _tunnelId;
    final channel = _channel;
    if (_closed || tunnelId == null || channel == null) {
      request.response.statusCode = HttpStatus.badGateway;
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
    final requestId = _requestId();
    final pending = _PendingResponse(request.response);
    _pending[requestId] = pending;
    final headers = <String, List<String>>{};
    request.headers.forEach((name, values) {
      headers[name] = values;
    });
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
    await pending.done;
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
          } on FormatException {
            await pending.fail();
            _pending.remove(requestId);
          }
        }
        return;
      case 'webui_http_response_end':
        _pending.remove(requestId);
        await pending.end();
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
      await response.close();
    } finally {
      if (!_done.isCompleted) _done.complete();
    }
  }

  Future<void> fail() async {
    if (_ended) return;
    if (!_started) response.statusCode = HttpStatus.badGateway;
    await end();
  }
}
