import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notify_api/notify_api.dart';

import '../api/api_client.dart';
import '../api/auth_interceptor.dart';
import '../config/server_config.dart';
import 'auth_state.dart';
import 'credentials_store.dart';
import 'token_refresher.dart';

/// A recoverable authentication failure, mapped from a [DioException] by
/// [AuthController]. The gateway's semantic `error.code` (see
/// `ErrorResponse` in the OpenAPI contract) decides the concrete type.
sealed class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// `409 EMAIL_TAKEN` — the email is already registered.
class AuthEmailTaken extends AuthFailure {
  const AuthEmailTaken([super.message = 'Email already registered']);
}

/// `401 INVALID_CREDENTIALS` — wrong email or password.
class AuthInvalidCredentials extends AuthFailure {
  const AuthInvalidCredentials([super.message = 'Invalid email or password']);
}

/// `403 EMAIL_UNVERIFIED` — login is blocked until the email is verified.
class AuthUnverified extends AuthFailure {
  const AuthUnverified([super.message = 'Email address is not verified']);
}

/// `400 INVALID_CODE` — verification/reset code invalid, expired, or used.
class AuthInvalidCode extends AuthFailure {
  const AuthInvalidCode([super.message = 'Invalid, expired, or used code']);
}

/// No response reached the client (connection error, timeout, ...).
class AuthNetwork extends AuthFailure {
  const AuthNetwork([super.message = 'Network error']);
}

/// Any other failure (unexpected status/code, serialization, 5xx, ...).
class AuthUnknownFailure extends AuthFailure {
  const AuthUnknownFailure([super.message = 'Unexpected authentication error']);
}

final credentialsStoreProvider = Provider<CredentialsStore>(
  (ref) => SecureCredentialsStore(),
);

/// The app's HTTP client bundle. Disposed with the container.
final apiClientProvider = Provider<ApiClient>((ref) {
  final client = buildApiClient(
    config: ref.watch(appConfigProvider),
    credentialsStore: ref.watch(credentialsStoreProvider),
    onSessionExpired: () =>
        ref.read(authControllerProvider.notifier).handleSessionExpired(),
    // The container-scoped refresher: the interceptor and the WebSocket
    // client share one single-flight refresh.
    tokenRefresher: ref.watch(tokenRefresherProvider),
  );
  ref.onDispose(() => client.dio.close());
  return client;
});

final authApiProvider = Provider<AuthApi>(
  (ref) => ref.watch(apiClientProvider).notifyApi.getAuthApi(),
);

/// The session's single, container-scoped [TokenRefresher].
///
/// Every refresh consumer — the `AuthInterceptor` (via [apiClientProvider]),
/// the realtime [GatewayWsClient], and the [AuthController] bootstrap —
/// shares this one instance, so concurrent `401`/`4401` failures trigger
/// exactly one `/v1/auth/refresh` call (see [DioTokenRefresher]).
///
/// The refresh endpoint is an `/auth/` path and needs no bearer token, so
/// this provider intentionally builds its own bare [Dio] instead of
/// depending on [apiClientProvider] (which consumes this provider).
final tokenRefresherProvider = Provider<TokenRefresher>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ref.watch(appConfigProvider).gatewayHttpBase,
      connectTimeout: gatewayConnectTimeout,
      sendTimeout: gatewaySendTimeout,
      receiveTimeout: gatewayReceiveTimeout,
    ),
  );
  ref.onDispose(dio.close);
  return DioTokenRefresher(
    authApi: NotifyApi(dio: dio, interceptors: const []).getAuthApi(),
    store: ref.watch(credentialsStoreProvider),
  );
});

final accessTokenHolderProvider = Provider<AccessTokenHolder>(
  (ref) => ref.watch(apiClientProvider).accessTokenHolder,
);

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

/// Drives the [AuthState] machine: registration, email verification,
/// login/logout, password reset, and session bootstrap.
///
/// Side effects beyond the state itself:
/// - the refresh token is persisted via [CredentialsStore] on login and on
///   successful verification (never the access token);
/// - the in-memory [AccessTokenHolder] is kept in sync so the
///   `AuthInterceptor` can attach the bearer token;
/// - failures are surfaced as thrown [AuthFailure]s; the state only changes
///   on success, except that a login rejected with `EMAIL_UNVERIFIED` moves
///   to [AwaitingVerification].
class AuthController extends Notifier<AuthState> {
  /// Password held between [register] (or an unverified [login]) and
  /// [verifyEmail]. `POST /v1/auth/verify-email` returns `204` with no
  /// tokens, so a successful verification completes the flow by logging in
  /// with this password; it is cleared on login, logout, and reset.
  String? _pendingPassword;

  AuthApi get _authApi => ref.read(authApiProvider);
  CredentialsStore get _store => ref.read(credentialsStoreProvider);
  TokenRefresher get _refresher => ref.read(tokenRefresherProvider);
  AccessTokenHolder get _tokenHolder => ref.read(accessTokenHolderProvider);

  @override
  AuthState build() => const AuthUnknown();

  /// Restores the session from the credentials store.
  ///
  /// Without stored credentials, or when the refresh token was rejected
  /// (and cleared by the [TokenRefresher]), the state becomes
  /// [Unauthenticated]. A local store or transient refresh failure becomes
  /// [AuthRestoreFailed] and preserves credentials for a retry. Every failure
  /// path lands on a terminal state, so errors of any kind are caught here.
  Future<void> bootstrap() async {
    state = const AuthUnknown();
    final Credentials? credentials;
    try {
      credentials = await _store.read();
    } catch (_) {
      // Unreadable store (e.g. platform keychain unavailable).
      state = const AuthRestoreFailed();
      return;
    }
    if (credentials == null) {
      state = const Unauthenticated();
      return;
    }
    final String? token;
    try {
      token = await _refresher.refresh();
    } catch (_) {
      state = const AuthRestoreFailed();
      return;
    }
    if (token == null) {
      state = const Unauthenticated();
      return;
    }
    _tokenHolder.accessToken = token;
    state = Authenticated(accessToken: token, email: credentials.accountEmail);
  }

  /// Discards a failed stored-session restore and opens the normal login flow.
  Future<void> abandonSessionRestore() async {
    try {
      await _store.clear();
    } catch (_) {
      // Login must remain reachable even when the platform store is unhealthy.
    }
    _tokenHolder.accessToken = null;
    _pendingPassword = null;
    state = const Unauthenticated();
  }

  /// Registers a new account. On success the state becomes
  /// [AwaitingVerification] and the password is held (in memory only) so
  /// [verifyEmail] can complete the flow with an automatic login.
  Future<void> register(String email, String password) async {
    try {
      await _authApi.register(
        registerBody: RegisterBody(
          (b) => b
            ..email = email
            ..password = password,
        ),
      );
    } on DioException catch (error) {
      throw _mapError(error);
    }
    _pendingPassword = password;
    state = AwaitingVerification(email);
  }

  /// Verifies the account email with the SMTP-delivered code.
  ///
  /// Verification only makes sense within the registration flow: when the
  /// state is not [AwaitingVerification] this returns early without calling
  /// the gateway. The [email] argument is ignored in favor of the state's
  /// email, so a stale caller email can never be paired with the held
  /// password for the automatic login below.
  ///
  /// The endpoint returns no tokens, so on success the flow is completed by
  /// logging in with the password held from [register]/[login]. Without a
  /// held password (e.g. the in-memory password was lost), or when that
  /// automatic login fails (e.g. network), the state becomes
  /// [Unauthenticated] and the user logs in manually — the code is already
  /// consumed, so staying in [AwaitingVerification] would be a dead end.
  Future<void> verifyEmail(String email, String code) async {
    final current = state;
    if (current is! AwaitingVerification) {
      return;
    }
    final stateEmail = current.email;
    try {
      await _authApi.verifyEmail(
        verifyEmailBody: VerifyEmailBody(
          (b) => b
            ..email = stateEmail
            ..code = code,
        ),
      );
    } on DioException catch (error) {
      throw _mapError(error);
    }
    final password = _pendingPassword;
    if (password == null) {
      state = const Unauthenticated();
      return;
    }
    try {
      await login(stateEmail, password);
    } on AuthFailure {
      // The verification succeeded (the code is consumed); only the
      // automatic login failed. The held password is retained — login()
      // clears it only on success — so a later login flow can reuse it.
      state = const Unauthenticated();
    }
  }

  /// Resends the verification email. Anti-enumeration: the gateway answers
  /// the same way for known and unknown emails.
  Future<void> resendVerification(String email) async {
    try {
      await _authApi.resendVerification(
        emailBody: EmailBody((b) => b.email = email),
      );
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  /// Logs in with email and password.
  ///
  /// On success the refresh token is persisted, the access token is held in
  /// memory, and the state becomes [Authenticated]. A `403 EMAIL_UNVERIFIED`
  /// response moves the state to [AwaitingVerification] (and holds the
  /// password for a subsequent [verifyEmail]) before throwing
  /// [AuthUnverified].
  Future<void> login(String email, String password) async {
    final TokenPair tokenPair;
    try {
      final response = await _authApi.login(
        loginBody: LoginBody(
          (b) => b
            ..email = email
            ..password = password,
        ),
      );
      final data = response.data;
      if (data == null) {
        throw const AuthUnknownFailure('Empty login response');
      }
      tokenPair = data;
    } on DioException catch (error) {
      final failure = _mapError(error);
      if (failure is AuthUnverified) {
        _pendingPassword = password;
        state = AwaitingVerification(email);
      }
      throw failure;
    }
    await _store.save(
      refreshToken: tokenPair.refreshToken,
      accountEmail: email,
    );
    _tokenHolder.accessToken = tokenPair.accessToken;
    _pendingPassword = null;
    state = Authenticated(accessToken: tokenPair.accessToken, email: email);
  }

  /// Sends a password reset email. Anti-enumeration: same response for
  /// known and unknown emails.
  Future<void> forgotPassword(String email) async {
    try {
      await _authApi.forgotPassword(
        emailBody: EmailBody((b) => b.email = email),
      );
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  /// Resets the password with the SMTP-delivered code.
  ///
  /// A successful reset revokes every refresh-token family of the user on
  /// the server, so the stored credentials are dead: they are cleared
  /// locally and the state becomes [Unauthenticated].
  Future<void> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    try {
      await _authApi.resetPassword(
        resetPasswordBody: ResetPasswordBody(
          (b) => b
            ..email = email
            ..code = code
            ..password = newPassword,
        ),
      );
    } on DioException catch (error) {
      throw _mapError(error);
    }
    // The reset succeeded: every refresh-token family is revoked, so the
    // local session must be dropped even if one cleanup step fails.
    try {
      await _store.clear();
    } finally {
      _tokenHolder.accessToken = null;
      _pendingPassword = null;
      state = const Unauthenticated();
    }
  }

  /// Signs out: best-effort server-side revocation of the refresh token,
  /// then unconditional local cleanup. Local sign-out proceeds even when
  /// the revoke request fails (e.g. offline) — any throwable from the
  /// revoke and storage errors are swallowed so the local session is always
  /// dropped.
  Future<void> logout() async {
    try {
      final credentials = await _store.read();
      if (credentials != null) {
        await _authApi.logout(
          refreshBody: RefreshBody(
            (b) => b.refreshToken = credentials.refreshToken,
          ),
        );
      }
    } catch (_) {
      // Best-effort revoke: local sign-out proceeds regardless.
    }
    try {
      await _store.clear();
    } catch (_) {
      // Best-effort secure-storage cleanup must not block local sign-out.
    }
    _tokenHolder.accessToken = null;
    _pendingPassword = null;
    state = const Unauthenticated();
  }

  /// Called by the `AuthInterceptor` when a `401` could not be recovered:
  /// the refresh token was rejected and already cleared from the store, so
  /// only the in-memory session is dropped here.
  void handleSessionExpired() {
    _tokenHolder.accessToken = null;
    _pendingPassword = null;
    state = const Unauthenticated();
  }

  /// Maps a [DioException] to a semantic [AuthFailure] using the gateway's
  /// `ErrorResponse.error.code` where available.
  AuthFailure _mapError(DioException error) {
    final response = error.response;
    if (response == null) {
      return const AuthNetwork();
    }
    final code = _errorCode(response.data);
    return switch (code) {
      'EMAIL_TAKEN' => const AuthEmailTaken(),
      'INVALID_CREDENTIALS' => const AuthInvalidCredentials(),
      'EMAIL_UNVERIFIED' => const AuthUnverified(),
      'INVALID_CODE' => const AuthInvalidCode(),
      _ => AuthUnknownFailure('HTTP ${response.statusCode}'),
    };
  }

  static String? _errorCode(dynamic data) {
    if (data is Map<String, dynamic>) {
      final error = data['error'];
      if (error is Map<String, dynamic>) {
        final code = error['code'];
        if (code is String) {
          return code;
        }
      }
    }
    return null;
  }
}
