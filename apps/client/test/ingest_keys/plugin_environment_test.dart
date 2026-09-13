import 'dart:io';

import 'package:client/ingest_keys/plugin_environment.dart';
import 'package:client/ingest_keys/local_key_secrets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Bash export preserves quotes, whitespace and shell metacharacters literally',
    () async {
      const machine =
          'my \'server\' "\$HOME" \$(printf SHOULD_NOT_RUN)\nsecond line';
      final command = pluginEnvironment(
        gateway: 'https://gw.example.com',
        credential: 'test.key',
        machine: machine,
      );
      final result = await Process.run('bash', [
        '--noprofile',
        '--norc',
        '-c',
        '$command\nprintf "%s\\0%s\\0%s" "\$NOTIFY_GATEWAY_URL" "\$NOTIFY_INGEST_KEY" "\$NOTIFY_MACHINE"',
      ]);
      expect(result.exitCode, 0);
      expect((result.stdout as String).split('\u0000'), [
        'https://gw.example.com',
        'test.key',
        machine,
      ]);
      expect(
        pluginEnvironment(
          gateway: 'https://gw.example.com',
          credential: 'test.key',
          machine: '',
        ),
        contains("export NOTIFY_MACHINE='YOUR_MACHINE_NAME'"),
      );
      expect(
        pluginEnvironment(
          gateway: 'https://gw.example.com',
          credential: 'test.key',
          machine: "ali'yun",
          shell: PluginShell.powershell,
        ),
        contains("\$env:NOTIFY_MACHINE = 'ali''yun'"),
      );
    },
    skip: Platform.isWindows,
  );

  test(
    'local secret survives store recreation and stays isolated by scope',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      await LocalKeySecrets(
        scope: 'gateway-A/user-A',
      ).save('key-1', 'test.key');
      final reopened = LocalKeySecrets(scope: 'gateway-A/user-A');
      expect(await reopened.read('key-1'), 'test.key');
      expect(
        await LocalKeySecrets(scope: 'gateway-A/user-B').read('key-1'),
        isNull,
      );
      expect(
        await LocalKeySecrets(scope: 'gateway-B/user-A').read('key-1'),
        isNull,
      );
      await reopened.remove('key-1');
      expect(
        await LocalKeySecrets(scope: 'gateway-A/user-A').read('key-1'),
        isNull,
      );
    },
  );
}
