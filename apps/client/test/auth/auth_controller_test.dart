import 'package:client/api/auth_interceptor.dart';
import 'package:client/auth/auth_controller.dart';
import 'package:client/auth/auth_state.dart';
import 'package:client/auth/credentials_store.dart';
import 'package:client/auth/token_refresher.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:notify_api/notify_api.dart';

class MockAuthApi extends Mock implements AuthApi {}

class MockTokenRefresher extends Mock implements TokenRefresher {}

/// Controller seeded directly into [AwaitingVerification] with no held
/// password, simulating a verification flow whose in-memory password was
/// lost (e.g. notifier recreated).
class UnverifiedController extends AuthController {
  @override
  AuthState build() => const AwaitingVerification('user@example.com');
}

/// Store whose [clear] fails with a non-Exception throwable, to prove
/// cleanup of holder/state still runs.
class FailingClearStore extends InMemoryCredentialsStore {
  @override
  Future<void> clear() async {
    await super.clear();
    throw StateError('clear failed');
  }
}

/// Store whose [read] fails (e.g. platform keychain unavailable).
class _ThrowingReadStore extends InMemoryCredentialsStore {
  @override
  Future<Credentials?> read() async {
    throw StateError('keychain read failed');
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(RegisterBody((b) => b
      ..email = ''
      ..password = ''));
    registerFallbackValue(LoginBody((b) => b
      ..email = ''
      ..password = ''));
    registerFallbackValue(VerifyEmailBody((b) => b
      ..email = ''
      ..code = ''));
    registerFallbackValue(EmailBody((b) => b.email = ''));
    registerFallbackValue(ResetPasswordBody((b) => b
      ..email = ''
      ..code = ''
      ..password = ''));
    registerFallbackValue(RefreshBody((b) => b.refreshToken = ''));
  });

  const email = 'user@example.com';
  const password = 's3cret-password';

  late MockAuthApi authApi;
  late MockTokenRefresher refresher;
  late InMemoryCredentialsStore store;
  late InMemoryAccessTokenHolder tokenHolder;
  late ProviderContainer container;

  AuthController controller() => container.read(authControllerProvider.notifier);

  AuthState state() => container.read(authControllerProvider);

  Response<void> voidResponse({int statusCode = 204}) {
    return Response<void>(
      statusCode: statusCode,
      requestOptions: RequestOptions(path: '/v1/auth/void'),
    );
  }

  Response<TokenPair> tokenPairResponse({
    String accessToken = 'access-1',
    String refreshToken = 'refresh-1',
  }) {
    return Response<TokenPair>(
      data: TokenPair(
        (b) => b
          ..accessToken = accessToken
          ..refreshToken = refreshToken,
      ),
      statusCode: 200,
      requestOptions: RequestOptions(path: '/v1/auth/login'),
    );
  }

  DioException dioError({int? statusCode, String? code}) {
    final requestOptions = RequestOptions(path: '/v1/auth/x');
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
              data: code == null
                  ? null
                  : <String, dynamic>{
                      'error': <String, dynamic>{'code': code, 'message': 'm'},
                    },
            ),
    );
  }

  setUp(() {
    authApi = MockAuthApi();
    refresher = MockTokenRefresher();
    store = InMemoryCredentialsStore();
    tokenHolder = InMemoryAccessTokenHolder();
    container = ProviderContainer(
      overrides: [
        authApiProvider.overrideWithValue(authApi),
        credentialsStoreProvider.overrideWithValue(store),
        tokenRefresherProvider.overrideWithValue(refresher),
        accessTokenHolderProvider.overrideWithValue(tokenHolder),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('bootstrap', () {
    test('without stored credentials becomes Unauthenticated', () async {
      expect(state(), isA<AuthUnknown>());

      await controller().bootstrap();

      expect(state(), isA<Unauthenticated>());
      verifyNever(() => refresher.refresh());
    });

    test(
      'with stored credentials refreshes and becomes Authenticated',
      () async {
        await store.save(refreshToken: 'refresh-0', accountEmail: email);
        when(() => refresher.refresh()).thenAnswer((_) async => 'access-1');

        await controller().bootstrap();

        final s = state();
        expect(s, isA<Authenticated>());
        final authenticated = s as Authenticated;
        expect(authenticated.accessToken, 'access-1');
        expect(authenticated.email, email);
        expect(tokenHolder.accessToken, 'access-1');
      },
    );

    test('with rejected refresh token becomes Unauthenticated', () async {
      await store.save(refreshToken: 'refresh-0', accountEmail: email);
      when(() => refresher.refresh()).thenAnswer((_) async => null);

      await controller().bootstrap();

      expect(state(), isA<Unauthenticated>());
    });

    test(
      'a non-Dio refresh error becomes Unauthenticated instead of wedging '
      'on the loading spinner',
      () async {
        await store.save(refreshToken: 'refresh-0', accountEmail: email);
        when(() => refresher.refresh()).thenThrow(StateError('boom'));

        await controller().bootstrap();

        expect(state(), isA<Unauthenticated>());
      },
    );

    test(
      'a failing credentials read becomes Unauthenticated instead of '
      'wedging on the loading spinner',
      () async {
        final failingStore = _ThrowingReadStore();
        final c = ProviderContainer(
          overrides: [
            authApiProvider.overrideWithValue(authApi),
            credentialsStoreProvider.overrideWithValue(failingStore),
            tokenRefresherProvider.overrideWithValue(refresher),
            accessTokenHolderProvider.overrideWithValue(tokenHolder),
          ],
        );
        addTearDown(c.dispose);

        await c.read(authControllerProvider.notifier).bootstrap();

        expect(c.read(authControllerProvider), isA<Unauthenticated>());
        verifyNever(() => refresher.refresh());
      },
    );
  });

  group('register', () {
    test('success transitions to AwaitingVerification', () async {
      when(
        () => authApi.register(registerBody: any(named: 'registerBody')),
      ).thenAnswer((_) async => voidResponse());

      await controller().register(email, password);

      final s = state();
      expect(s, isA<AwaitingVerification>());
      expect((s as AwaitingVerification).email, email);
    });

    test('409 EMAIL_TAKEN throws AuthEmailTaken and keeps state', () async {
      when(
        () => authApi.register(registerBody: any(named: 'registerBody')),
      ).thenThrow(dioError(statusCode: 409, code: 'EMAIL_TAKEN'));

      await expectLater(
        controller().register(email, password),
        throwsA(isA<AuthEmailTaken>()),
      );
      expect(state(), isA<AuthUnknown>());
    });
  });

  group('verifyEmail', () {
    test('bad code throws AuthInvalidCode and stays AwaitingVerification', () async {
      when(
        () => authApi.register(registerBody: any(named: 'registerBody')),
      ).thenAnswer((_) async => voidResponse());
      when(
        () => authApi.verifyEmail(verifyEmailBody: any(named: 'verifyEmailBody')),
      ).thenThrow(dioError(statusCode: 400, code: 'INVALID_CODE'));

      await controller().register(email, password);
      await expectLater(
        controller().verifyEmail(email, '000000'),
        throwsA(isA<AuthInvalidCode>()),
      );

      expect(state(), isA<AwaitingVerification>());
    });

    test(
      'success after register persists tokens and becomes Authenticated',
      () async {
        when(
          () => authApi.register(registerBody: any(named: 'registerBody')),
        ).thenAnswer((_) async => voidResponse());
        when(
          () => authApi.verifyEmail(
            verifyEmailBody: any(named: 'verifyEmailBody'),
          ),
        ).thenAnswer((_) async => voidResponse());
        when(
          () => authApi.login(loginBody: any(named: 'loginBody')),
        ).thenAnswer((_) async => tokenPairResponse());

        await controller().register(email, password);
        await controller().verifyEmail(email, '123456');

        final s = state();
        expect(s, isA<Authenticated>());
        expect((s as Authenticated).email, email);
        final credentials = await store.read();
        expect(credentials?.refreshToken, 'refresh-1');
        expect(credentials?.accountEmail, email);
        expect(tokenHolder.accessToken, 'access-1');
      },
    );

    test('uses the AwaitingVerification state email, not a stale caller '
        'email', () async {
      when(
        () => authApi.register(registerBody: any(named: 'registerBody')),
      ).thenAnswer((_) async => voidResponse());
      when(
        () =>
            authApi.verifyEmail(verifyEmailBody: any(named: 'verifyEmailBody')),
      ).thenAnswer((_) async => voidResponse());
      when(
        () => authApi.login(loginBody: any(named: 'loginBody')),
      ).thenAnswer((_) async => tokenPairResponse());

      await controller().register(email, password);
      await controller().verifyEmail('stale@example.com', '123456');

      final verifyBody =
          verify(
                () => authApi.verifyEmail(
                  verifyEmailBody: captureAny(named: 'verifyEmailBody'),
                ),
              ).captured.single
              as VerifyEmailBody;
      expect(verifyBody.email, email);
      final loginBody =
          verify(
                () => authApi.login(
                  loginBody: captureAny(named: 'loginBody'),
                ),
              ).captured.single
              as LoginBody;
      expect(loginBody.email, email);
      expect((state() as Authenticated).email, email);
    });

    test('returns early when the state is not AwaitingVerification', () async {
      expect(state(), isA<AuthUnknown>());

      await controller().verifyEmail(email, '123456');

      expect(state(), isA<AuthUnknown>());
      verifyNever(
        () =>
            authApi.verifyEmail(verifyEmailBody: any(named: 'verifyEmailBody')),
      );
    });

    test('without a held password becomes Unauthenticated after successful '
        'verification', () async {
      when(
        () =>
            authApi.verifyEmail(verifyEmailBody: any(named: 'verifyEmailBody')),
      ).thenAnswer((_) async => voidResponse());
      final unverifiedContainer = ProviderContainer(
        overrides: [
          authApiProvider.overrideWithValue(authApi),
          credentialsStoreProvider.overrideWithValue(store),
          tokenRefresherProvider.overrideWithValue(refresher),
          accessTokenHolderProvider.overrideWithValue(tokenHolder),
          authControllerProvider.overrideWith(UnverifiedController.new),
        ],
      );
      addTearDown(unverifiedContainer.dispose);
      expect(
        unverifiedContainer.read(authControllerProvider),
        isA<AwaitingVerification>(),
      );

      await unverifiedContainer
          .read(authControllerProvider.notifier)
          .verifyEmail('stale@example.com', '123456');

      expect(
        unverifiedContainer.read(authControllerProvider),
        isA<Unauthenticated>(),
      );
      final verifyBody =
          verify(
                () => authApi.verifyEmail(
                  verifyEmailBody: captureAny(named: 'verifyEmailBody'),
                ),
              ).captured.single
              as VerifyEmailBody;
      expect(verifyBody.email, email);
      verifyNever(() => authApi.login(loginBody: any(named: 'loginBody')));
      expect(await store.read(), isNull);
    });

    test(
      'when verification succeeds but the automatic login fails, transitions '
      'to Unauthenticated',
      () async {
        when(
          () => authApi.register(registerBody: any(named: 'registerBody')),
        ).thenAnswer((_) async => voidResponse());
        when(
          () => authApi.verifyEmail(
            verifyEmailBody: any(named: 'verifyEmailBody'),
          ),
        ).thenAnswer((_) async => voidResponse());
        when(
          () => authApi.login(loginBody: any(named: 'loginBody')),
        ).thenThrow(dioError());

        await controller().register(email, password);
        await controller().verifyEmail(email, '123456');

        // The code is consumed and the email is verified; the user lands on
        // the login screen. The held password is retained (login() clears it
        // only on success) so a later login flow can still pair with it.
        expect(state(), isA<Unauthenticated>());
        expect(await store.read(), isNull);
        expect(tokenHolder.accessToken, isNull);
      },
    );
  });

  group('login', () {
    test('success persists refresh token and becomes Authenticated', () async {
      when(
        () => authApi.login(loginBody: any(named: 'loginBody')),
      ).thenAnswer((_) async => tokenPairResponse());

      await controller().login(email, password);

      final s = state();
      expect(s, isA<Authenticated>());
      final authenticated = s as Authenticated;
      expect(authenticated.accessToken, 'access-1');
      expect(authenticated.email, email);
      final credentials = await store.read();
      expect(credentials?.refreshToken, 'refresh-1');
      expect(credentials?.accountEmail, email);
      expect(tokenHolder.accessToken, 'access-1');
    });

    test('403 EMAIL_UNVERIFIED throws AuthUnverified and transitions to '
        'AwaitingVerification', () async {
      when(
        () => authApi.login(loginBody: any(named: 'loginBody')),
      ).thenThrow(dioError(statusCode: 403, code: 'EMAIL_UNVERIFIED'));

      await expectLater(
        controller().login(email, password),
        throwsA(isA<AuthUnverified>()),
      );

      final s = state();
      expect(s, isA<AwaitingVerification>());
      expect((s as AwaitingVerification).email, email);
    });

    test('401 INVALID_CREDENTIALS throws AuthInvalidCredentials', () async {
      when(
        () => authApi.login(loginBody: any(named: 'loginBody')),
      ).thenThrow(dioError(statusCode: 401, code: 'INVALID_CREDENTIALS'));

      await expectLater(
        controller().login(email, password),
        throwsA(isA<AuthInvalidCredentials>()),
      );
      expect(state(), isA<AuthUnknown>());
    });

    test('connection failure throws AuthNetwork', () async {
      when(
        () => authApi.login(loginBody: any(named: 'loginBody')),
      ).thenThrow(dioError());

      await expectLater(
        controller().login(email, password),
        throwsA(isA<AuthNetwork>()),
      );
    });

    test('unrecognized error code throws AuthUnknownFailure', () async {
      when(
        () => authApi.login(loginBody: any(named: 'loginBody')),
      ).thenThrow(dioError(statusCode: 400, code: 'VALIDATION_FAILED'));

      await expectLater(
        controller().login(email, password),
        throwsA(isA<AuthUnknownFailure>()),
      );
      expect(state(), isA<AuthUnknown>());
    });
  });

  group('resetPassword', () {
    test(
      'success becomes Unauthenticated and clears stored credentials',
      () async {
        await store.save(refreshToken: 'refresh-0', accountEmail: email);
        when(
          () => authApi.resetPassword(
            resetPasswordBody: any(named: 'resetPasswordBody'),
          ),
        ).thenAnswer((_) async => voidResponse());

        await controller().resetPassword(email, '123456', 'new-password');

        expect(state(), isA<Unauthenticated>());
        expect(await store.read(), isNull);
        expect(tokenHolder.accessToken, isNull);
      },
    );

    test('bad code throws AuthInvalidCode and keeps credentials', () async {
      await store.save(refreshToken: 'refresh-0', accountEmail: email);
      when(
        () => authApi.resetPassword(
          resetPasswordBody: any(named: 'resetPasswordBody'),
        ),
      ).thenThrow(dioError(statusCode: 400, code: 'INVALID_CODE'));

      await expectLater(
        controller().resetPassword(email, '000000', 'new-password'),
        throwsA(isA<AuthInvalidCode>()),
      );

      expect(await store.read(), isNotNull);
    });

    test('holder and state cleanup run even when store.clear throws a '
        'non-Exception', () async {
      final failingStore = FailingClearStore();
      final failingContainer = ProviderContainer(
        overrides: [
          authApiProvider.overrideWithValue(authApi),
          credentialsStoreProvider.overrideWithValue(failingStore),
          tokenRefresherProvider.overrideWithValue(refresher),
          accessTokenHolderProvider.overrideWithValue(tokenHolder),
        ],
      );
      addTearDown(failingContainer.dispose);
      when(
        () => authApi.login(loginBody: any(named: 'loginBody')),
      ).thenAnswer((_) async => tokenPairResponse());
      when(
        () => authApi.resetPassword(
          resetPasswordBody: any(named: 'resetPasswordBody'),
        ),
      ).thenAnswer((_) async => voidResponse());

      await failingContainer
          .read(authControllerProvider.notifier)
          .login(email, password);
      expect(
        failingContainer.read(authControllerProvider),
        isA<Authenticated>(),
      );

      await expectLater(
        failingContainer
            .read(authControllerProvider.notifier)
            .resetPassword(email, '123456', 'new-password'),
        throwsA(isA<StateError>()),
      );

      // The reset succeeded server-side (all refresh families revoked), so
      // the local session must be dropped even though clearing threw.
      expect(failingContainer.read(authControllerProvider), isA<Unauthenticated>());
      expect(tokenHolder.accessToken, isNull);
    });
  });

  group('logout', () {
    test('revokes the refresh token and becomes Unauthenticated', () async {
      when(
        () => authApi.login(loginBody: any(named: 'loginBody')),
      ).thenAnswer((_) async => tokenPairResponse());
      when(
        () => authApi.logout(refreshBody: any(named: 'refreshBody')),
      ).thenAnswer((_) async => voidResponse());

      await controller().login(email, password);
      await controller().logout();

      expect(state(), isA<Unauthenticated>());
      expect(await store.read(), isNull);
      expect(tokenHolder.accessToken, isNull);
      verify(
        () => authApi.logout(
          refreshBody: any(
            named: 'refreshBody',
            that: predicate<RefreshBody>((b) => b.refreshToken == 'refresh-1'),
          ),
        ),
      ).called(1);
    });

    test('clears the store even when the HTTP revoke fails', () async {
      when(
        () => authApi.login(loginBody: any(named: 'loginBody')),
      ).thenAnswer((_) async => tokenPairResponse());
      when(
        () => authApi.logout(refreshBody: any(named: 'refreshBody')),
      ).thenThrow(dioError());

      await controller().login(email, password);
      await controller().logout();

      expect(state(), isA<Unauthenticated>());
      expect(await store.read(), isNull);
      expect(tokenHolder.accessToken, isNull);
    });

    test('clears store, holder, and state even when the revoke throws a '
        'non-Exception', () async {
      when(
        () => authApi.login(loginBody: any(named: 'loginBody')),
      ).thenAnswer((_) async => tokenPairResponse());
      when(
        () => authApi.logout(refreshBody: any(named: 'refreshBody')),
      ).thenThrow(ArgumentError('boom'));

      await controller().login(email, password);
      await controller().logout();

      expect(state(), isA<Unauthenticated>());
      expect(await store.read(), isNull);
      expect(tokenHolder.accessToken, isNull);
    });
  });
}
