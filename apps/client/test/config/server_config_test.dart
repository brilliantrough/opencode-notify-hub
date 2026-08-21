import 'package:client/auth/auth_controller.dart';
import 'package:client/auth/credentials_store.dart';
import 'package:client/config/server_config.dart';
import 'package:client/config/server_switcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'server selection normalizes, persists, and rebuilds app config',
    () async {
      final store = MemoryServerConfigStore();
      final container = ProviderContainer(
        overrides: [serverConfigStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);

      expect(
        container.read(serverConfigProvider).gatewayHttpBase,
        ServerConfig.defaultGatewayHttpBase,
      );
      // The default is deliberately empty: the server address is private
      // to each deployment and must be entered once by the user.
      expect(ServerConfig.defaultGatewayHttpBase, '');

      await container
          .read(serverConfigProvider.notifier)
          .setServer('gateway.internal.example/');

      expect(
        container.read(serverConfigProvider).gatewayHttpBase,
        'https://gateway.internal.example',
      );
      expect(store.read(), 'https://gateway.internal.example');
      expect(
        container.read(appConfigProvider).gatewayHttpBase,
        'https://gateway.internal.example',
      );

      final restored = ProviderContainer(
        overrides: [serverConfigStoreProvider.overrideWithValue(store)],
      );
      addTearDown(restored.dispose);
      expect(
        restored.read(serverConfigProvider).gatewayHttpBase,
        'https://gateway.internal.example',
      );
    },
  );

  test('server selection accepts HTTPS and loopback HTTP origins', () {
    expect(
      ServerConfig.parse('https://gateway.example.com:8443/').gatewayHttpBase,
      'https://gateway.example.com:8443',
    );
    expect(
      ServerConfig.parse('http://127.0.0.1:8080').gatewayHttpBase,
      'http://127.0.0.1:8080',
    );
  });

  test('server selection rejects unsafe or non-origin URLs', () {
    for (final input in [
      'http://gateway.example.com',
      'https://user:pass@gateway.example.com',
      'https://gateway.example.com/api',
      'https://gateway.example.com?tenant=a',
    ]) {
      expect(() => ServerConfig.parse(input), throwsFormatException);
    }
  });

  test(
    'server switch logs out before persisting and resetting state',
    () async {
      final operations = <String>[];
      var current = 'https://old.example.com';
      final switcher = ServerSwitcher(
        readCurrent: () => current,
        logout: () async => operations.add('logout'),
        persist: (next) async {
          operations.add('persist:$next');
          current = next;
        },
        resetServerState: () => operations.add('reset'),
      );

      expect(await switcher.switchTo('new.example.com'), isTrue);
      expect(operations, [
        'logout',
        'persist:https://new.example.com',
        'reset',
      ]);

      operations.clear();
      expect(await switcher.switchTo('https://new.example.com'), isFalse);
      expect(operations, isEmpty);
    },
  );

  test(
    'changing server rebuilds the HTTP client with the new origin',
    () async {
      final store = MemoryServerConfigStore('https://old.example.com');
      final container = ProviderContainer(
        overrides: [
          serverConfigStoreProvider.overrideWithValue(store),
          credentialsStoreProvider.overrideWithValue(
            InMemoryCredentialsStore(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final oldClient = container.read(apiClientProvider);
      expect(oldClient.dio.options.baseUrl, 'https://old.example.com');

      await container
          .read(serverConfigProvider.notifier)
          .setServer('https://new.example.com');
      final newClient = container.read(apiClientProvider);

      expect(newClient, isNot(same(oldClient)));
      expect(newClient.dio.options.baseUrl, 'https://new.example.com');
    },
  );
}
