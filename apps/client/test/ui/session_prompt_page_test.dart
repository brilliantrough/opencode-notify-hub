import 'package:client/pending/pending_controller.dart';
import 'package:client/realtime/active_sessions.dart';
import 'package:client/realtime/instance_presence.dart';
import 'package:client/sessions/session_prompt_controller.dart';
import 'package:client/ui/session_prompt_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final session = ActiveSession(
    sessionId: 'ses-1',
    machine: 'devbox',
    project: 'notify',
    directory: '/work/notify',
    title: 'Implement API',
    lastHeartbeatAt: DateTime.utc(2026, 8, 18),
    running: false,
  );
  final target = OpenCodeInstancePresence(
    instanceId: 'instance-1',
    machine: 'devbox',
    project: 'notify',
    directory: '/work/notify',
    openCodeVersion: '1.18.18',
    protocolVersion: 1,
    state: InstancePresenceState.controllable,
    lastSeenAt: DateTime.utc(2026, 8, 18),
  );

  testWidgets('submits text once and locks the accepted prompt', (
    tester,
  ) async {
    final sent = <String>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          commandIdGeneratorProvider.overrideWithValue(() => 'command-1'),
          sessionPromptSenderProvider.overrideWithValue(({
            required instanceId,
            required sessionId,
            required commandId,
            required text,
          }) async {
            sent.add('$instanceId|$sessionId|$commandId|$text');
            return true;
          }),
        ],
        child: MaterialApp(
          home: SessionPromptPage(session: session, target: target),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('session-prompt-input')),
      'Continue and run the tests',
    );
    await tester.tap(find.byKey(const ValueKey('send-session-prompt')));
    await tester.pumpAndSettle();

    expect(sent, ['instance-1|ses-1|command-1|Continue and run the tests']);
    expect(find.text('已发送到 OpenCode。'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('send-session-prompt')),
          )
          .onPressed,
      isNull,
    );
  });
}
