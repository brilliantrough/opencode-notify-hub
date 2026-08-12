import 'dart:async';
import 'dart:typed_data';

import 'package:client/api/auth_interceptor.dart';
import 'package:client/auth/token_refresher.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTokenRefresher extends Mock implements TokenRefresher {}

/// A snapshot of one HTTP request observed by [FakeHttpClientAdapter].
class RecordedRequest {
  RecordedRequest(RequestOptions options)
    : path = options.path,
      authorization = options.headers['Authorization'] as String?,
      authRetried = options.extra['authRetried'] == true;

  final String path;
  final String? authorization;
  final bool authRetried;
}

/// Records every request and delegates the response to [handler].
class FakeHttpClientAdapter implements HttpClientAdapter {
  final List<RecordedRequest> requests = [];

  Future<ResponseBody> Function(RequestOptions options)? handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(RecordedRequest(options));
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
      Headers.contentTypeHeader: ['application/json'],
    },
  );
}

String? bearerOf(RequestOptions options) =>
    options.headers['Authorization'] as String?;

String? authOf(RecordedRequest request) => request.authorization;

void main() {
  late InMemoryAccessTokenHolder holder;
  late MockTokenRefresher refresher;
  late FakeHttpClientAdapter adapter;
  late Dio dio;
  late int sessionExpiredCalls;

  setUp(() {
    holder = InMemoryAccessTokenHolder();
    refresher = MockTokenRefresher();
    adapter = FakeHttpClientAdapter();
    sessionExpiredCalls = 0;
    final client = Dio(BaseOptions(baseUrl: 'https://gateway.test'))
      ..httpClientAdapter = adapter;
    dio = client;
    client.interceptors.add(
      AuthInterceptor(
        holder: holder,
        refresher: refresher,
        dio: client,
        onSessionExpired: () => sessionExpiredCalls++,
      ),
    );
  });

  group('bearer attachment', () {
    test('attaches the held bearer token to non-auth requests', () async {
      holder.accessToken = 'access-1';
      adapter.handler = (options) async => jsonBody('{}', 200);

      final response = await dio.get('/v1/devices');

      expect(response.statusCode, 200);
      expect(authOf(adapter.requests.single), 'Bearer access-1');
    });

    test('sends no Authorization header when no token is held', () async {
      adapter.handler = (options) async => jsonBody('{}', 200);

      await dio.get('/v1/devices');

      expect(authOf(adapter.requests.single), isNull);
    });

    test('skips bearer attachment on /auth/ paths', () async {
      holder.accessToken = 'access-1';
      adapter.handler = (options) async => jsonBody('{}', 200);

      await dio.post('/v1/auth/login', data: '{}');

      expect(authOf(adapter.requests.single), isNull);
    });
  });

  group('coordinated 401 retry', () {
    test('three parallel 401s share one refresh, then all replay', () async {
      holder.accessToken = 'old-token';
      when(() => refresher.refresh()).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return 'new-token';
      });
      adapter.handler = (options) async {
        return switch (bearerOf(options)) {
          'Bearer old-token' => jsonBody('{"error":"expired"}', 401),
          'Bearer new-token' => jsonBody('{"ok":true}', 200),
          _ => jsonBody('{}', 500),
        };
      };

      final responses = await Future.wait([
        dio.get('/v1/a'),
        dio.get('/v1/b'),
        dio.get('/v1/c'),
      ]);

      expect(responses.map((r) => r.statusCode), [200, 200, 200]);
      verify(() => refresher.refresh()).called(1);
      expect(holder.accessToken, 'new-token');
      expect(sessionExpiredCalls, 0);

      final original = adapter.requests
          .where((r) => r.authorization == 'Bearer old-token')
          .toList();
      final replayed = adapter.requests
          .where((r) => r.authorization == 'Bearer new-token')
          .toList();
      expect(original, hasLength(3));
      expect(replayed, hasLength(3));
      expect(
        replayed.every((r) => r.authRetried),
        isTrue,
      );
    });

    test('a 401 on an /auth/ path propagates without refreshing', () async {
      holder.accessToken = 'old-token';
      adapter.handler = (options) async => jsonBody('{}', 401);

      final status = await dio
          .post('/v1/auth/login', data: '{}')
          .then((r) => r.statusCode, onError: (Object e) => (e as DioException).response?.statusCode);

      expect(status, 401);
      verifyNever(() => refresher.refresh());
      expect(sessionExpiredCalls, 0);
      expect(holder.accessToken, 'old-token');
    });
  });

  group('session expiry', () {
    test(
      'refresh returning null expires the session once and 401s propagate',
      () async {
        holder.accessToken = 'old-token';
        when(() => refresher.refresh()).thenAnswer((_) async => null);
        adapter.handler = (options) async => jsonBody('{}', 401);

        final statuses = await Future.wait([
          for (final path in ['/v1/a', '/v1/b', '/v1/c'])
            dio.get(path).then(
              (r) => r.statusCode,
              onError: (Object e) => (e as DioException).response?.statusCode,
            ),
        ]);

        expect(statuses, [401, 401, 401]);
        verify(() => refresher.refresh()).called(1);
        expect(sessionExpiredCalls, 1);
        expect(holder.accessToken, isNull);
      },
    );
  });

  group('retry guard', () {
    test(
      'a 401 on the replayed request propagates without a second refresh',
      () async {
        holder.accessToken = 'old-token';
        when(() => refresher.refresh()).thenAnswer((_) async => 'new-token');
        adapter.handler = (options) async => jsonBody('{}', 401);

        final status = await dio.get('/v1/a').then(
          (r) => r.statusCode,
          onError: (Object e) => (e as DioException).response?.statusCode,
        );

        expect(status, 401);
        verify(() => refresher.refresh()).called(1);
        expect(sessionExpiredCalls, 0);
        expect(adapter.requests, hasLength(2));
        expect(adapter.requests.last.authorization, 'Bearer new-token');
        expect(adapter.requests.last.authRetried, isTrue);
      },
    );
  });

  group('guard pins', () {
    test('a 401 on a tokenless request propagates without refreshing',
        () async {
      adapter.handler = (options) async => jsonBody('{}', 401);

      final status = await dio.get('/v1/a').then(
        (r) => r.statusCode,
        onError: (Object e) => (e as DioException).response?.statusCode,
      );

      expect(status, 401);
      verifyNever(() => refresher.refresh());
      expect(sessionExpiredCalls, 0);
    });

    test(
      'a 401 sent with a now-stale token replays with the newer held token '
      'without refreshing again',
      () async {
        // Both requests go out with the old token; the first 401 refreshes
        // while the second is still in flight, so when the second 401 is
        // handled the holder already carries the newer token.
        holder.accessToken = 'old-token';
        final refreshCompleter = Completer<String>();
        when(() => refresher.refresh()).thenAnswer(
          (_) => refreshCompleter.future,
        );
        adapter.handler = (options) async {
          return switch (bearerOf(options)) {
            'Bearer old-token' => jsonBody('{}', 401),
            'Bearer new-token' => jsonBody('{"ok":true}', 200),
            _ => jsonBody('{}', 500),
          };
        };

        final first = dio.get('/v1/a');
        final second = dio.get('/v1/b');
        // Let both requests fail and the first error handler start refreshing.
        await Future<void>.delayed(const Duration(milliseconds: 20));
        refreshCompleter.complete('new-token');
        final responses = await Future.wait([first, second]);

        expect(responses.map((r) => r.statusCode), [200, 200]);
        // Only one refresh: the second 401 replayed with the newer held
        // token instead of refreshing again.
        verify(() => refresher.refresh()).called(1);
        expect(sessionExpiredCalls, 0);
        expect(
          adapter.requests
              .where((r) => r.authorization == 'Bearer old-token'),
          hasLength(2),
        );
        expect(
          adapter.requests
              .where((r) => r.authorization == 'Bearer new-token'),
          hasLength(2),
        );
      },
    );

    test(
      'a throwing refresher propagates the original 401 without expiring '
      'the session',
      () async {
        holder.accessToken = 'old-token';
        when(() => refresher.refresh()).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/v1/auth/refresh'),
            type: DioExceptionType.connectionError,
          ),
        );
        adapter.handler = (options) async => jsonBody('{}', 401);

        final error = await dio.get('/v1/a').then<DioException>(
          (r) => fail('expected a DioException, got ${r.statusCode}'),
          onError: (Object e) => e as DioException,
        );

        // The caller sees the original auth failure, not the refresh error.
        expect(error.response?.statusCode, 401);
        expect(error.requestOptions.path, '/v1/a');
        verify(() => refresher.refresh()).called(1);
        expect(sessionExpiredCalls, 0);
        expect(holder.accessToken, 'old-token');
      },
    );
  });
}
