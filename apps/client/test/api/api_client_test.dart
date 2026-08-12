import 'package:client/api/api_client.dart';
import 'package:client/api/auth_interceptor.dart';
import 'package:client/auth/credentials_store.dart';
import 'package:client/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notify_api/notify_api.dart';

void main() {
  group('buildApiClient', () {
    test('wires the gateway base URL, generated API, and auth interceptor',
        () {
      final client = buildApiClient(
        config: AppConfig(gatewayHttpBase: 'https://gateway.test'),
        credentialsStore: InMemoryCredentialsStore(),
        onSessionExpired: () {},
      );

      expect(client.dio.options.baseUrl, 'https://gateway.test');
      expect(client.notifyApi.getAuthApi(), isA<AuthApi>());
      expect(client.accessTokenHolder, isA<AccessTokenHolder>());
      expect(
        client.dio.interceptors.whereType<AuthInterceptor>(),
        hasLength(1),
      );
    });

    test('reuses a provided access token holder', () {
      final holder = InMemoryAccessTokenHolder();

      final client = buildApiClient(
        config: AppConfig(gatewayHttpBase: 'https://gateway.test'),
        credentialsStore: InMemoryCredentialsStore(),
        onSessionExpired: () {},
        accessTokenHolder: holder,
      );

      expect(client.accessTokenHolder, same(holder));
    });
  });
}
