import 'dart:async';
import 'dart:typed_data';

import 'package:client/api/auth_interceptor.dart';
import 'package:client/auth/auth_controller.dart';
import 'package:client/auth/credentials_store.dart';
import 'package:client/auth/token_refresher.dart';
import 'package:client/config/app_config.dart';
import 'package:client/realtime/ws_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:notify_api/notify_api.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class MockAuthApi extends Mock implements AuthApi {}

class MockTokenRefresher extends Mock implements TokenRefresher {}

/// Records requests and delegates responses to [handler].
class FakeHttpClientAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  Future<ResponseBody> Function(RequestOptions options)? handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return handler!(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonBody(String body, int statusCode) {
  return ResponseBody.fromString(
    body,
    statusCode,
    headers: {
      'content-type': ['application/json'],
    },
  );
}

class FakeWebSocketSink implements WebSocketSink {
  @override
  void add(Object? data) {}

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<Object?> stream) async {}

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {}

  @override
  Future<void> get done => Future<void>.value();
}

class FakeWebSocketChannel extends StreamChannelMixin<Object?>
    implements WebSocketChannel {
  final StreamController<Object?> _incoming = StreamController<Object?>();

  @override
  final FakeWebSocketSink sink = FakeWebSocketSink();

  @override
  int? closeCode;

  @override
  String? closeReason;

  @override
  String? get protocol => null;

  @override
  Future<void> get ready => Future<void>.value();

  @override
  Stream<Object?> get stream => _incoming.stream;

  void serverClose([int? code]) {
    closeCode = code;
    unawaited(_incoming.close());
  }
}

class FakeConnector {
  final List<Map<String, dynamic>> calls = [];
  final List<FakeWebSocketChannel> channels = [];

  WebSocketChannel call(Uri uri, Map<String, dynamic> headers) {
    calls.add(headers);
    final channel = FakeWebSocketChannel();
    channels.add(channel);
    return channel;
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(RefreshBody((b) => b.refreshToken = ''));
  });

  group('container-scoped TokenRefresher', () {
    test('the api client interceptor uses the injected tokenRefresherProvider '
        'instance', () async {
      final refresher = MockTokenRefresher();
      when(() => refresher.refresh()).thenAnswer((_) async => 'new-token');
      final adapter = FakeHttpClientAdapter();
      adapter.handler = (options) async =>
          switch (options.headers['Authorization']) {
            'Bearer old-token' => jsonBody('{"error":"expired"}', 401),
            'Bearer new-token' => jsonBody('{"ok":true}', 200),
            _ => jsonBody('{}', 500),
          };
      final container = ProviderContainer(
        overrides: [tokenRefresherProvider.overrideWithValue(refresher)],
      );
      addTearDown(container.dispose);

      final client = container.read(apiClientProvider);
      client.dio.httpClientAdapter = adapter;
      container.read(accessTokenHolderProvider).accessToken = 'old-token';

      final response = await client.dio.get('/v1/devices');

      expect(response.statusCode, 200);
      verify(() => refresher.refresh()).called(1);
    });

    test(
      'a concurrent interceptor 401 and WS 4401 share one /v1/auth/refresh',
      () async {
        final store = InMemoryCredentialsStore();
        await store.save(
          refreshToken: 'refresh-0',
          accountEmail: 'user@example.com',
        );
        final authApi = MockAuthApi();
        final refreshCompleter = Completer<Response<TokenPair>>();
        when(
          () => authApi.refresh(refreshBody: any(named: 'refreshBody')),
        ).thenAnswer((_) => refreshCompleter.future);
        final refresher = DioTokenRefresher(authApi: authApi, store: store);

        // HTTP consumer: an interceptor-equipped Dio.
        final adapter = FakeHttpClientAdapter();
        adapter.handler = (options) async =>
            switch (options.headers['Authorization']) {
              'Bearer old-token' => jsonBody('{"error":"expired"}', 401),
              'Bearer access-new' => jsonBody('{"ok":true}', 200),
              _ => jsonBody('{}', 500),
            };
        final dio = Dio(BaseOptions(baseUrl: 'https://gateway.test'))
          ..httpClientAdapter = adapter;
        final holder = InMemoryAccessTokenHolder()..accessToken = 'old-token';
        dio.interceptors.add(
          AuthInterceptor(
            holder: holder,
            refresher: refresher,
            dio: dio,
            onSessionExpired: () {},
          ),
        );

        // WS consumer: a GatewayWsClient on the SAME refresher instance.
        final connector = FakeConnector();
        final ws = GatewayWsClient(
          config: AppConfig(gatewayHttpBase: 'https://gateway.test'),
          tokenHolder: holder,
          refresher: refresher,
          connector: connector.call,
        );
        addTearDown(ws.disconnect);

        ws.connect();
        await pumpEventQueue();
        expect(connector.calls, hasLength(1));

        // The WS drops with 4401 while an HTTP request fails with 401:
        // both consumers need a refresh at the same time.
        connector.channels.single.serverClose(4401);
        final httpRequest = dio.get('/v1/devices');
        await pumpEventQueue();

        // Exactly one refresh call is in flight across both consumers.
        verify(
          () => authApi.refresh(refreshBody: any(named: 'refreshBody')),
        ).called(1);

        refreshCompleter.complete(
          Response<TokenPair>(
            data: TokenPair(
              (b) => b
                ..accessToken = 'access-new'
                ..refreshToken = 'refresh-new',
            ),
            statusCode: 200,
            requestOptions: RequestOptions(path: '/v1/auth/refresh'),
          ),
        );

        final response = await httpRequest;
        await pumpEventQueue();

        expect(response.statusCode, 200);
        expect(holder.accessToken, 'access-new');
        expect(
          connector.calls,
          hasLength(2),
          reason: 'WS reconnects with the refreshed token',
        );
        expect(connector.calls.last['Authorization'], 'Bearer access-new');
      },
    );
  });
}
