import 'package:client/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig.gatewayWsBase', () {
    test('maps https to wss and appends /v1/ws', () {
      final config = AppConfig(gatewayHttpBase: 'https://gateway.example.com');

      expect(config.gatewayWsBase, 'wss://gateway.example.com/v1/ws');
    });

    test('maps http to ws', () {
      final config = AppConfig(gatewayHttpBase: 'http://localhost:8080');

      expect(config.gatewayWsBase, 'ws://localhost:8080/v1/ws');
    });

    test('strips a trailing slash before appending the path', () {
      final config = AppConfig(gatewayHttpBase: 'https://gateway.example.com/');

      expect(config.gatewayWsBase, 'wss://gateway.example.com/v1/ws');
    });

    test('throws ArgumentError on an unrecognized scheme', () {
      final config = AppConfig(gatewayHttpBase: 'ftp://gateway.example.com');

      expect(() => config.gatewayWsBase, throwsArgumentError);
    });

    test('throws ArgumentError when the scheme is missing', () {
      final config = AppConfig(gatewayHttpBase: 'gateway.example.com');

      expect(() => config.gatewayWsBase, throwsArgumentError);
    });
  });
}
