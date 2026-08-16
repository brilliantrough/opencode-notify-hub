import 'package:client/auth/credentials_store.dart';
import 'package:client/config/app_config.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InMemoryCredentialsStore', () {
    test('read returns null before any save', () async {
      final store = InMemoryCredentialsStore();
      expect(await store.read(), isNull);
    });

    test(
      'save then read round-trips refresh token and account email',
      () async {
        final store = InMemoryCredentialsStore();
        await store.save(
          refreshToken: 'refresh-abc',
          accountEmail: 'user@example.com',
        );
        final credentials = await store.read();
        expect(credentials, isNotNull);
        expect(credentials!.refreshToken, 'refresh-abc');
        expect(credentials.accountEmail, 'user@example.com');
      },
    );

    test('save overwrites previous credentials', () async {
      final store = InMemoryCredentialsStore();
      await store.save(refreshToken: 'old', accountEmail: 'old@example.com');
      await store.save(refreshToken: 'new', accountEmail: 'new@example.com');
      final credentials = await store.read();
      expect(credentials!.refreshToken, 'new');
      expect(credentials.accountEmail, 'new@example.com');
    });

    test('clear removes stored credentials', () async {
      final store = InMemoryCredentialsStore();
      await store.save(
        refreshToken: 'refresh-abc',
        accountEmail: 'user@example.com',
      );
      await store.clear();
      expect(await store.read(), isNull);
    });
  });

  group('SecureCredentialsStore', () {
    test('save and read use the platform secure storage', () async {
      final storage = MockSecureStorage();
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});
      when(() => storage.readAll()).thenAnswer(
        (_) async => {
          'refresh_token_v1': 'refresh-abc',
          'account_email_v1': 'user@example.com',
        },
      );
      final store = SecureCredentialsStore(storage: storage);

      await store.save(
        refreshToken: 'refresh-abc',
        accountEmail: 'user@example.com',
      );
      final credentials = await store.read();

      expect(credentials!.refreshToken, 'refresh-abc');
      expect(credentials.accountEmail, 'user@example.com');
      verify(
        () => storage.write(key: 'refresh_token_v1', value: 'refresh-abc'),
      ).called(1);
      verify(
        () => storage.write(key: 'account_email_v1', value: 'user@example.com'),
      ).called(1);
      verify(() => storage.readAll()).called(1);
    });

    test('clear attempts both deletes when the first one fails', () async {
      final storage = MockSecureStorage();
      when(
        () => storage.delete(key: 'refresh_token_v1'),
      ).thenThrow(StateError('delete failed'));
      when(
        () => storage.delete(key: 'account_email_v1'),
      ).thenAnswer((_) async {});
      final store = SecureCredentialsStore(storage: storage);

      await expectLater(store.clear(), throwsStateError);

      verify(() => storage.delete(key: 'refresh_token_v1')).called(1);
      verify(() => storage.delete(key: 'account_email_v1')).called(1);
    });
  });

  group('AppConfig', () {
    test('gatewayHttpBase uses the provided runtime server', () {
      final config = AppConfig(
        gatewayHttpBase: 'https://gateway.internal.example.com',
      );
      expect(config.gatewayHttpBase, 'https://gateway.internal.example.com');
    });

    test('https base converts to wss base with /v1/ws path', () {
      expect(
        AppConfig(gatewayHttpBase: 'https://notify.example.com').gatewayWsBase,
        'wss://notify.example.com/v1/ws',
      );
    });

    test('http base converts to ws base with /v1/ws path', () {
      expect(
        AppConfig(gatewayHttpBase: 'http://localhost:8080').gatewayWsBase,
        'ws://localhost:8080/v1/ws',
      );
    });

    test('trailing slash on base does not produce double slash', () {
      expect(
        AppConfig(gatewayHttpBase: 'https://notify.example.com/').gatewayWsBase,
        'wss://notify.example.com/v1/ws',
      );
    });
  });

  group('SecureCredentialsStore', () {
    const channel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('reads both credentials with one platform call', () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            if (call.method == 'readAll') {
              return <String, String>{
                'refresh_token_v1': 'refresh-abc',
                'account_email_v1': 'user@example.com',
              };
            }
            return null;
          });
      final store = SecureCredentialsStore(
        storage: const FlutterSecureStorage(),
      );

      final credentials = await store.read();

      expect(credentials?.refreshToken, 'refresh-abc');
      expect(credentials?.accountEmail, 'user@example.com');
      expect(calls.map((call) => call.method), ['readAll']);
    });
  });
}
