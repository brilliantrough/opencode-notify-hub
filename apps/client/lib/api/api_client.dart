import 'package:dio/dio.dart';
import 'package:notify_api/notify_api.dart';

import '../auth/credentials_store.dart';
import '../auth/token_refresher.dart';
import '../config/app_config.dart';
import 'auth_interceptor.dart';

/// The app's HTTP client bundle: a configured [Dio], the generated gateway
/// API, and the session's access-token holder.
class ApiClient {
  const ApiClient({
    required this.dio,
    required this.notifyApi,
    required this.accessTokenHolder,
  });

  final Dio dio;
  final NotifyApi notifyApi;
  final AccessTokenHolder accessTokenHolder;
}

/// Builds the [ApiClient] for the gateway at [AppConfig.gatewayHttpBase],
/// wiring bearer attachment and coordinated `401` refresh via
/// [AuthInterceptor].
///
/// [tokenRefresher] injects the session's refresh coordinator; pass the
/// container-scoped instance so the interceptor shares its single-flight
/// guarantee with every other consumer (e.g. the realtime WebSocket
/// client). When omitted, a private [DioTokenRefresher] is created —
/// acceptable only when no other consumer exists.
ApiClient buildApiClient({
  required AppConfig config,
  required CredentialsStore credentialsStore,
  required void Function() onSessionExpired,
  AccessTokenHolder? accessTokenHolder,
  TokenRefresher? tokenRefresher,
}) {
  final dio = Dio(BaseOptions(baseUrl: config.gatewayHttpBase));
  // `interceptors: const []` keeps the generated default auth interceptors
  // off; bearer attachment is handled by [AuthInterceptor] below.
  final notifyApi = NotifyApi(dio: dio, interceptors: const []);
  final holder = accessTokenHolder ?? InMemoryAccessTokenHolder();
  final refresher =
      tokenRefresher ??
      DioTokenRefresher(
        authApi: notifyApi.getAuthApi(),
        store: credentialsStore,
      );
  dio.interceptors.add(
    AuthInterceptor(
      holder: holder,
      refresher: refresher,
      dio: dio,
      onSessionExpired: onSessionExpired,
    ),
  );
  return ApiClient(dio: dio, notifyApi: notifyApi, accessTokenHolder: holder);
}
