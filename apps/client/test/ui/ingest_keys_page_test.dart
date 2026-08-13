import 'package:client/ingest_keys/ingest_keys_controller.dart';
import 'package:client/ui/ingest_keys_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notify_api/notify_api.dart';

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
          ingestKeysControllerProvider.overrideWith(() => controller),
        ],
        child: const MaterialApp(home: IngestKeysPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
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

  testWidgets('create shows the secret exactly once with a copy button', (
    tester,
  ) async {
    mockClipboard(tester);
    controller = FakeIngestKeysController(const []);

    await pumpPage(tester);

    await tester.tap(find.text('新建密钥'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'new-key');
    await tester.tap(find.text('创建'));
    await tester.pumpAndSettle();

    // The secret dialog shows the one-time secret and a copy button.
    expect(find.text('nk-secret-abc'), findsOneWidget);
    expect(find.text('复制'), findsOneWidget);
    expect(controller.createdNames, ['new-key']);

    // Copy writes the secret to the clipboard.
    await tester.tap(find.text('复制'));
    await tester.pumpAndSettle();
    final setData = platformCalls.singleWhere(
      (call) => call.method == 'Clipboard.setData',
    );
    expect(
      (setData.arguments as Map<dynamic, dynamic>)['text'],
      'nk-secret-abc',
    );

    // After closing, the secret is gone: it is never stored.
    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();
    expect(find.text('nk-secret-abc'), findsNothing);
    // The list was refreshed with the new (secret-free) row.
    expect(find.text('new-key'), findsOneWidget);
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

    expect(controller.revokedIds, ['key-1']);
    expect(find.text('ci-runner'), findsNothing);
    expect(find.text('laptop'), findsOneWidget);
  });
}
