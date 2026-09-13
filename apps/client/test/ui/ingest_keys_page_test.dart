import 'package:client/ingest_keys/ingest_keys_controller.dart';
import 'package:client/ui/ingest_keys_page.dart';
import 'package:client/auth/auth_controller.dart';
import 'package:client/auth/auth_state.dart';
import 'package:client/config/app_config.dart';
import 'package:client/config/server_config.dart';
import 'package:client/ingest_keys/local_key_secrets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notify_api/notify_api.dart';

class _Auth extends AuthController {
  @override
  AuthState build() =>
      const Authenticated(accessToken: 'test', email: 'user@example.com');
}

/// Fake controller: canned data, records calls, no gateway.
class FakeIngestKeysController extends IngestKeysController {
  FakeIngestKeysController(this._initial);

  final List<IngestKey> _initial;
  final List<String> createdNames = [];
  final List<String> revokedIds = [];
  int listCalls = 0;
  String nextSecret = 'nk-secret-abc';
  int _nextId = 100;
  late List<IngestKey> _keys;

  @override
  Future<List<IngestKey>> build() async {
    _keys = List.of(_initial);
    return _keys;
  }

  @override
  Future<CreateIngestKeyResponse> create(String name) async {
    createdNames.add(name);
    final now = DateTime.utc(2026, 2, 1);
    final id = 'key-${_nextId++}';
    await ref.read(localKeySecretsProvider).save(id, nextSecret);
    _keys = [..._keys, IngestKey(id: id, name: name, createdAt: now)];
    state = AsyncData(_keys);
    return CreateIngestKeyResponse(
      (b) => b
        ..id = id
        ..name = name
        ..secret = nextSecret
        ..createdAt = now.toUtc(),
    );
  }

  @override
  Future<List<IngestKey>> list() async {
    listCalls += 1;
    state = AsyncData(_keys);
    return _keys;
  }

  @override
  Future<void> revoke(String id) async {
    revokedIds.add(id);
    _keys = [
      for (final key in _keys)
        if (key.id != id) key,
    ];
    state = AsyncData(_keys);
  }
}

void main() {
  final t1 = DateTime.utc(2026, 1, 2, 10);

  late FakeIngestKeysController controller;
  late List<MethodCall> platformCalls;

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_Auth.new),
          appConfigProvider.overrideWithValue(
            AppConfig(gatewayHttpBase: 'https://gw.example.com'),
          ),
          ingestKeysControllerProvider.overrideWith(() => controller),
        ],
        child: const MaterialApp(home: IngestKeysPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    platformCalls = [];
  });

  void mockClipboard(WidgetTester tester) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        platformCalls.add(call);
        return null;
      },
    );
  }

  testWidgets('lists the ingest keys', (tester) async {
    mockClipboard(tester);
    controller = FakeIngestKeysController([
      IngestKey(id: 'key-1', name: 'ci-runner', createdAt: t1),
      IngestKey(id: 'key-2', name: 'laptop', createdAt: t1),
    ]);

    await pumpPage(tester);

    expect(find.text('ci-runner'), findsOneWidget);
    expect(find.text('laptop'), findsOneWidget);
    expect(find.text('新建密钥'), findsOneWidget);
  });

  testWidgets('refresh button reloads key usage metadata', (tester) async {
    mockClipboard(tester);
    controller = FakeIngestKeysController([
      IngestKey(
        id: 'key-1',
        name: 'ci-runner',
        createdAt: t1,
        lastUsedAt: DateTime.utc(2026, 1, 3, 12),
      ),
    ]);

    await pumpPage(tester);
    await tester.tap(find.byKey(const ValueKey('refresh-ingest-keys')));
    await tester.pumpAndSettle();

    expect(controller.listCalls, 1);
    expect(find.textContaining('最近使用'), findsOneWidget);
  });

  testWidgets('created key can be reopened and exported with a machine name', (
    tester,
  ) async {
    mockClipboard(tester);
    controller = FakeIngestKeysController(const []);

    await pumpPage(tester);

    await tester.tap(find.text('新建密钥'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'new-key');
    await tester.pump();
    await tester.tap(find.text('创建'));
    await tester.pumpAndSettle();

    expect(find.text('nk-secret-abc'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('reveal-key')));
    await tester.pumpAndSettle();
    expect(find.text('nk-secret-abc'), findsOneWidget);
    expect(controller.createdNames, ['new-key']);

    // Copy writes the secret to the clipboard.
    await tester.tap(find.byKey(const ValueKey('copy-key')));
    await tester.pumpAndSettle();
    final setData = platformCalls.singleWhere(
      (call) => call.method == 'Clipboard.setData',
    );
    expect(
      (setData.arguments as Map<dynamic, dynamic>)['text'],
      'nk-secret-abc',
    );

    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();
    expect(find.text('nk-secret-abc'), findsNothing);
    expect(find.text('new-key'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('configure-key-100')));
    await tester.pumpAndSettle();
    expect(find.text('nk-secret-abc'), findsNothing);
    await tester.enterText(
      find.byKey(const ValueKey('notify-machine')),
      "ali'yun",
    );
    await tester.tap(find.byKey(const ValueKey('copy-key-env')));
    await tester.pumpAndSettle();
    final command =
        (platformCalls
                    .lastWhere((call) => call.method == 'Clipboard.setData')
                    .arguments
                as Map)['text']
            as String;
    expect(command, contains("export NOTIFY_INGEST_KEY='nk-secret-abc'"));
    expect(command, contains("export NOTIFY_MACHINE='ali'\"'\"'yun'"));
  });

  testWidgets('old key can be imported on a narrow screen and copied again', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    mockClipboard(tester);
    controller = FakeIngestKeysController([
      IngestKey(id: 'key-1', name: 'aliyun', createdAt: t1),
    ]);
    await pumpPage(tester);
    await tester.tap(find.byKey(const ValueKey('configure-key-1')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.enterText(
      find.byKey(const ValueKey('import-key')),
      'incomplete-key',
    );
    await tester.tap(find.text('保存到本机'));
    await tester.pumpAndSettle();
    expect(find.textContaining('请输入完整的 keyId.secret'), findsOneWidget);
    final secret = '${'a' * 12}.${'b' * 43}';
    await tester.enterText(find.byKey(const ValueKey('import-key')), secret);
    await tester.tap(find.text('保存到本机'));
    await tester.pumpAndSettle();
    expect(find.text('已保存在本机，可重复查看和复制'), findsOneWidget);
    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('configure-key-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('copy-key-env')));
    await tester.pumpAndSettle();
    final command =
        (platformCalls
                    .lastWhere((call) => call.method == 'Clipboard.setData')
                    .arguments
                as Map)['text']
            as String;
    expect(command, contains(secret));
    expect(command, contains('YOUR_MACHINE_NAME'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('revoke calls the controller and removes the row', (
    tester,
  ) async {
    mockClipboard(tester);
    controller = FakeIngestKeysController([
      IngestKey(id: 'key-1', name: 'ci-runner', createdAt: t1),
      IngestKey(id: 'key-2', name: 'laptop', createdAt: t1),
    ]);

    await pumpPage(tester);

    await tester.tap(find.byKey(const ValueKey('revoke-key-1')));
    await tester.pumpAndSettle();
    expect(controller.revokedIds, isEmpty);
    await tester.tap(find.text('撤销密钥'));
    await tester.pumpAndSettle();

    expect(controller.revokedIds, ['key-1']);
    expect(find.text('ci-runner'), findsNothing);
    expect(find.text('laptop'), findsOneWidget);
  });
}
