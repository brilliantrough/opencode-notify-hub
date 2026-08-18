import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:client/sessions/webui_tunnel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class _FakeSink implements WebSocketSink {
  final sent = <Object?>[];

  @override
  void add(Object? data) => sent.add(data);

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<Object?> stream) async {
    await for (final value in stream) {
      sent.add(value);
    }
  }

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {}

  @override
  Future<void> get done async {}
}

class _FakeChannel extends StreamChannelMixin<Object?>
    implements WebSocketChannel {
  final incoming = StreamController<Object?>();

  @override
  final _FakeSink sink = _FakeSink();

  @override
  Stream<Object?> get stream => incoming.stream;

  @override
  Future<void> get ready async {}

  @override
  int? closeCode;

  @override
  String? closeReason;

  @override
  String? get protocol => null;
}

void main() {
  test('serves one local HTTP request through Gateway tunnel frames', () async {
    final channel = _FakeChannel();
    final tunnel = GatewayWebUiTunnel(
      gatewayUri: Uri.parse('wss://notify.example.com/v1/webui/ws'),
      accessToken: 'access-token',
      instanceId: 'instance-1',
      connector: (_, _) => channel,
    );
    addTearDown(() async {
      await tunnel.close();
      await channel.incoming.close();
    });

    final start = tunnel.start();
    await _waitFor(() => channel.sink.sent.isNotEmpty);
    final open =
        jsonDecode(channel.sink.sent.single! as String) as Map<String, dynamic>;
    expect(open, {'type': 'webui_tunnel_open', 'instanceId': 'instance-1'});
    const tunnelId = '6f0d91b0-93e4-43a9-9449-0bed03e651aa';
    channel.incoming.add(
      jsonEncode({'type': 'webui_tunnel_ready', 'tunnelId': tunnelId}),
    );
    final localUri = await start;

    final http = HttpClient();
    addTearDown(() => http.close(force: true));
    final responseFuture = () async {
      final request = await http.getUrl(localUri.resolve('/api/session?x=1'));
      request.headers.set('accept', 'application/json');
      return request.close();
    }();
    await _waitFor(() => channel.sink.sent.length >= 2);
    final requestFrame =
        jsonDecode(channel.sink.sent[1]! as String) as Map<String, dynamic>;
    expect(requestFrame['type'], 'webui_http_request');
    expect(requestFrame['tunnelId'], tunnelId);
    expect(requestFrame['method'], 'GET');
    expect(requestFrame['path'], '/api/session?x=1');
    final requestId = requestFrame['requestId'] as String;

    channel.incoming.add(
      jsonEncode({
        'type': 'webui_http_response_start',
        'tunnelId': tunnelId,
        'requestId': requestId,
        'status': 200,
        'headers': {
          'content-type': ['application/json'],
        },
      }),
    );
    channel.incoming.add(
      jsonEncode({
        'type': 'webui_http_response_chunk',
        'tunnelId': tunnelId,
        'requestId': requestId,
        'body': base64Encode(utf8.encode('{"ok":true}')),
      }),
    );
    channel.incoming.add(
      jsonEncode({
        'type': 'webui_http_response_end',
        'tunnelId': tunnelId,
        'requestId': requestId,
      }),
    );

    final response = await responseFuture;
    expect(response.statusCode, 200);
    expect(await utf8.decoder.bind(response).join(), '{"ok":true}');
  });
}

Future<void> _waitFor(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('condition not reached');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}
