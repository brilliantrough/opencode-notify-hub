import 'dart:async';

import 'package:client/auth/credentials_store.dart';
import 'package:client/auth/token_refresher.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:notify_api/notify_api.dart';

class MockAuthApi extends Mock implements AuthApi {}

void main() {
  setUpAll(() {
    registerFallbackValue(RefreshBody((b) => b.refreshToken = ''));
  });

  late MockAuthApi authApi;
  late InMemoryCredentialsStore store;
  late DioTokenRefresher refresher;

  const accountEmail = 'user@example.com';

  Response<TokenPair> tokenPairResponse({
    required String accessToken,
    required String refreshToken,
  }) {
    return Response<TokenPair>(
      data: TokenPair(
        (b) => b
          ..accessToken = accessToken
          ..refreshToken = refreshToken,
      ),
      statusCode: 200,
      requestOptions: RequestOptions(path: '/v1/auth/refresh'),
    );
  }

  DioException dioError({int? statusCode}) {
    final requestOptions = RequestOptions(path: '/v1/auth/refresh');
    return DioException(
      requestOptions: requestOptions,
      type: statusCode == null
          ? DioExceptionType.connectionError
          : DioExceptionType.badResponse,
      response: statusCode == null
          ? null
          : Response<dynamic>(
              statusCode: statusCode,
              requestOptions: requestOptions,
            ),
    );
  }

  setUp(() async {
    authApi = MockAuthApi();
    store = InMemoryCredentialsStore();
    await store.save(
      refreshToken: 'refresh-old',
      accountEmail: accountEmail,
    );
    refresher = DioTokenRefresher(authApi: authApi, store: store);
  });

  group('DioTokenRefresher', () {
    test('concurrent refresh calls share one in-flight request', () async {
      final completer = Completer<Response<TokenPair>>();
      when(
        () => authApi.refresh(refreshBody: any(named: 'refreshBody')),
      ).thenAnswer((_) => completer.future);

      final results = [
        refresher.refresh(),
        refresher.refresh(),
        refresher.refresh(),
      ];
      completer.complete(
        tokenPairResponse(accessToken: 'access-new', refreshToken: 'refresh-new'),
      );

      expect(await Future.wait(results), ['access-new', 'access-new', 'access-new']);
      verify(
        () => authApi.refresh(refreshBody: any(named: 'refreshBody')),
      ).called(1);
    });

    test('success persists rotated refresh token and returns access token',
        () async {
      when(
        () => authApi.refresh(refreshBody: any(named: 'refreshBody')),
      ).thenAnswer(
        (_) async => tokenPairResponse(
          accessToken: 'access-new',
          refreshToken: 'refresh-rotated',
        ),
      );

      final accessToken = await refresher.refresh();

      expect(accessToken, 'access-new');
      final stored = await store.read();
      expect(stored, isNotNull);
      expect(stored!.refreshToken, 'refresh-rotated');
      expect(stored.accountEmail, accountEmail);

      final captured = verify(
        () => authApi.refresh(refreshBody: captureAny(named: 'refreshBody')),
      ).captured;
      expect((captured.single as RefreshBody).refreshToken, 'refresh-old');
    });

    test('401 clears credentials and returns null', () async {
      when(
        () => authApi.refresh(refreshBody: any(named: 'refreshBody')),
      ).thenThrow(dioError(statusCode: 401));

      expect(await refresher.refresh(), isNull);
      expect(await store.read(), isNull);
    });

    test('403 clears credentials and returns null', () async {
      when(
        () => authApi.refresh(refreshBody: any(named: 'refreshBody')),
      ).thenThrow(dioError(statusCode: 403));

      expect(await refresher.refresh(), isNull);
      expect(await store.read(), isNull);
    });

    test('network error rethrows and keeps credentials', () async {
      when(
        () => authApi.refresh(refreshBody: any(named: 'refreshBody')),
      ).thenThrow(dioError());

      await expectLater(refresher.refresh(), throwsA(isA<DioException>()));
      final stored = await store.read();
      expect(stored, isNotNull);
      expect(stored!.refreshToken, 'refresh-old');
    });

    test('returns null without calling the API when no credentials stored',
        () async {
      await store.clear();

      expect(await refresher.refresh(), isNull);
      verifyNever(
        () => authApi.refresh(refreshBody: any(named: 'refreshBody')),
      );
    });
  });
}
