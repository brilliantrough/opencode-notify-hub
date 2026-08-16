import 'package:client/config/server_config.dart';
import 'package:client/config/app_config.dart';
import 'package:client/ui/plugin_setup_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<MethodCall> platformCalls;

  Future<void> pumpSetup(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig(gatewayHttpBase: 'https://gw.example.com'),
          ),
        ],
        child: const MaterialApp(home: PluginSetupPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  String? lastClipboardText() {
    final setData = platformCalls.lastWhere(
      (call) => call.method == 'Clipboard.setData',
    );
    return (setData.arguments as Map<dynamic, dynamic>)['text'] as String?;
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

  testWidgets('shows the plugin install path, gateway URL, env keys, and '
      'restart note', (tester) async {
    mockClipboard(tester);
    await pumpSetup(tester);

    expect(
      find.text(
        '~/.config/opencode/plugins/session-notify.js',
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('https://gw.example.com', findRichText: true),
      findsWidgets,
    );
    expect(find.textContaining('NOTIFY_GATEWAY_URL'), findsWidgets);
    expect(find.textContaining('NOTIFY_INGEST_KEY'), findsWidgets);
    expect(find.textContaining('重启'), findsWidgets);
    // Points the user at the ingest-keys page for the secret.
    expect(find.textContaining('密钥'), findsWidgets);
    expect(find.byType(SelectableText), findsNothing);
    final codeTexts = tester
        .widgetList<Text>(find.byType(Text))
        .where(
          (text) =>
              text.data?.contains('session-notify.js') == true ||
              text.data?.contains('NOTIFY_GATEWAY_URL=') == true,
        );
    expect(codeTexts, isNotEmpty);
    expect(codeTexts.every((text) => text.style?.fontFamily == null), isTrue);
  });

  testWidgets('copy button for the install path writes to the clipboard', (
    tester,
  ) async {
    mockClipboard(tester);
    await pumpSetup(tester);

    await tester.tap(find.byKey(PluginSetupPage.copyPathKey));
    await tester.pumpAndSettle();

    expect(lastClipboardText(), '~/.config/opencode/plugins/session-notify.js');
    expect(find.text('已复制'), findsOneWidget);
  });

  testWidgets('copy button for the environment example includes the gateway '
      'URL and both variable names', (tester) async {
    mockClipboard(tester);
    await pumpSetup(tester);

    await tester.tap(find.byKey(PluginSetupPage.copyEnvKey));
    await tester.pumpAndSettle();

    final text = lastClipboardText();
    expect(text, contains('NOTIFY_GATEWAY_URL=https://gw.example.com'));
    expect(text, contains('NOTIFY_INGEST_KEY='));
    expect(find.text('已复制'), findsOneWidget);
  });
}
