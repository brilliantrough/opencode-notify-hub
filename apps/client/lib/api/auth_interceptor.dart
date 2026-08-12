import 'package:dio/dio.dart';

import '../auth/token_refresher.dart';

/// Holds the session's short-lived access token, in memory only.
///
/// The refresh token lives in `CredentialsStore`; the access token is never
/// persisted and is obtained via [TokenRefresher] when a request fails with
/// `401`.
abstract class AccessTokenHolder {
  String? get accessToken;

  set accessToken(String? token);
}

/// Volatile in-memory [AccessTokenHolder].
class InMemoryAccessTokenHolder implements AccessTokenHolder {
  @override
  String? accessToken;
}

/// Attaches the session bearer token and coordinates `401` recovery.
///
/// On a `401` for a non-auth request, the interceptor refreshes the access
/// token once and replays the failed request. Because this is a
/// [QueuedInterceptor], concurrent failures are handled one at a time: the
/// first failure refreshes, and queued failures simply replay with the token
/// the first failure obtained — so a burst of `401`s triggers exactly one
/// refresh.
///
/// If the refresh yields no token the session is unrecoverable:
/// [onSessionExpired] is invoked once (queued failures observe the cleared
/// holder and propagate without re-notifying) and the original `401` is
/// passed on.
///
/// Replays run on an interceptor-free companion client that shares the main
/// client's [HttpClientAdapter]. Replaying through the main client would
/// route a replay's own failure back into this interceptor's error queue
/// while the original error handler is still awaiting it — deadlocking the
/// queue. Each replay is tagged with [retriedExtraKey] so a replay that still
/// fails propagates instead of looping.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required AccessTokenHolder holder,
    required TokenRefresher refresher,
    required Dio dio,
    required void Function() onSessionExpired,
  }) : _holder = holder,
       _refresher = refresher,
       _dio = dio,
       _onSessionExpired = onSessionExpired;

  /// `RequestOptions.extra` key marking a request as an already-retried
  /// replay, guarding against refresh loops. Defense in depth: replays run
  /// on the interceptor-free companion client, so they never re-enter this
  /// interceptor; the flag additionally protects the propagation path if a
  /// replayed request's error is ever routed back here.
  static const String retriedExtraKey = 'authRetried';

  final AccessTokenHolder _holder;
  final TokenRefresher _refresher;
  final Dio _dio;
  final void Function() _onSessionExpired;

  Dio? _replayDio;

  /// Interceptor-free client used for replays; shares the main client's
  /// adapter so test doubles and transport config apply to replays too.
  Dio get _replayClient =>
      _replayDio ??= Dio(BaseOptions(baseUrl: _dio.options.baseUrl))
        ..httpClientAdapter = _dio.httpClientAdapter;

  static bool _isAuthPath(String path) => path.contains('/auth/');

  static String? _bearerToken(RequestOptions options) {
    final header = options.headers['Authorization'];
    if (header is String && header.startsWith('Bearer ')) {
      return header.substring('Bearer '.length);
    }
    return null;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!_isAuthPath(options.path)) {
      final token = _holder.accessToken;
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final sentToken = _bearerToken(options);
    if (err.response?.statusCode != 401 ||
        _isAuthPath(options.path) ||
        options.extra[retriedExtraKey] == true ||
        sentToken == null) {
      return handler.next(err);
    }

    final current = _holder.accessToken;
    if (current != null && current != sentToken) {
      // A queued 401 already refreshed the token; replay with it directly.
      return _replay(options, current, handler);
    }
    if (current == null) {
      // A queued 401 already found the session unrecoverable and notified;
      // propagate without re-refreshing or re-notifying.
      return handler.next(err);
    }

    final String? newToken;
    try {
      newToken = await _refresher.refresh();
    } on DioException {
      // Transient refresh failure (e.g. network): the session may still be
      // valid, so surface the original 401 instead of the refresh error and
      // leave the held token untouched — the caller can retry later.
      return handler.next(err);
    }
    if (newToken == null) {
      _holder.accessToken = null;
      _onSessionExpired();
      return handler.next(err);
    }
    _holder.accessToken = newToken;
    return _replay(options, newToken, handler);
  }

  Future<void> _replay(
    RequestOptions options,
    String accessToken,
    ErrorInterceptorHandler handler,
  ) async {
    options.headers['Authorization'] = 'Bearer $accessToken';
    options.extra[retriedExtraKey] = true;
    try {
      final response = await _replayClient.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (error) {
      handler.next(error);
    }
  }
}
