import 'package:dio/dio.dart';
import 'package:notify_api/notify_api.dart';

import 'credentials_store.dart';

/// Coordinates access-token refresh for the session.
///
/// Returns the new access token, or `null` when the session is no longer
/// valid (no stored credentials, or the refresh token was rejected).
abstract class TokenRefresher {
  Future<String?> refresh();
}

/// [TokenRefresher] backed by the generated [AuthApi] refresh endpoint.
///
/// Concurrent callers share a single in-flight refresh: the first caller
/// starts the request and every later caller awaits the same [Future].
///
/// Outcomes:
/// - Success: the rotated refresh token is persisted (the account email is
///   preserved) and the new access token is returned.
/// - `401`/`403`: the stored credentials are cleared and `null` is returned;
///   the session is unrecoverable and the user must log in again.
/// - Any other [DioException] (e.g. transient network failure): rethrown so
///   the caller can retry later; credentials are kept and the user stays
///   logged in.
class DioTokenRefresher implements TokenRefresher {
  DioTokenRefresher({required AuthApi authApi, required CredentialsStore store})
    : _authApi = authApi,
      _store = store;

  final AuthApi _authApi;
  final CredentialsStore _store;

  Future<String?>? _inFlight;

  @override
  Future<String?> refresh() {
    return _inFlight ??= _doRefresh().whenComplete(() => _inFlight = null);
  }

  Future<String?> _doRefresh() async {
    final credentials = await _store.read();
    if (credentials == null) {
      return null;
    }

    try {
      final response = await _authApi.refresh(
        refreshBody: RefreshBody(
          (b) => b.refreshToken = credentials.refreshToken,
        ),
      );
      final tokenPair = response.data;
      if (tokenPair == null) {
        return null;
      }
      await _store.save(
        refreshToken: tokenPair.refreshToken,
        accountEmail: credentials.accountEmail,
      );
      return tokenPair.accessToken;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        await _store.clear();
        return null;
      }
      rethrow;
    }
  }
}
