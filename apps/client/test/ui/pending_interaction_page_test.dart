import 'package:client/pending/pending_interaction.dart';
import 'package:client/ui/pending_interaction_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

PendingQuestion question() => PendingQuestion(
  instanceId: '6f0d91b0-93e4-43a9-9449-0bed03e651aa',
  machine: 'build-host',
  project: 'shop-api',
  directory: '/work/shop-api',
  sessionId: 'ses-1',
  sessionTitle: 'Checkout migration',
  requestId: 'question-1',
  occurredAt: DateTime.utc(2026, 8, 14, 9),
  tool: const PendingTool(messageId: 'msg-1', callId: 'call-1'),
  questions: const [
    PendingQuestionItem(
      header: 'Database',
      question: 'Which database should the migration target?',
      options: [
        PendingOption(label: 'PostgreSQL', description: 'Production parity'),
        PendingOption(label: 'SQLite', description: 'Fast local runs'),
      ],
      multiple: true,
      custom: true,
    ),
  ],
);

PendingPermission permission() => PendingPermission(
  instanceId: '6f0d91b0-93e4-43a9-9449-0bed03e651aa',
  machine: 'build-host',
  project: 'shop-api',
  directory: '/work/shop-api',
  sessionId: 'ses-2',
  sessionTitle: 'Release build',
  requestId: 'permission-1',
  occurredAt: DateTime.utc(2026, 8, 14, 9),
  tool: const PendingTool(messageId: 'msg-2', callId: 'call-2'),
  permission: 'bash',
  patterns: const ['docker build .', '/work/shop-api/Dockerfile'],
  always: const ['docker build *'],
  metadata: const {'command': 'docker build .', 'path': '/work/shop-api'},
);

void main() {
  testWidgets('question detail renders complete read-only content', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: PendingInteractionPage(interaction: question())),
    );

    expect(find.text('build-host'), findsOneWidget);
    expect(find.text('/work/shop-api'), findsOneWidget);
    expect(find.textContaining('Checkout migration'), findsOneWidget);
    expect(
      find.text('Which database should the migration target?'),
      findsOneWidget,
    );
    expect(find.text('Production parity'), findsOneWidget);
    expect(find.text('Fast local runs'), findsOneWidget);
    expect(find.text('可多选'), findsOneWidget);
    expect(find.text('可自定义回答'), findsOneWidget);
    expect(find.text('提交'), findsNothing);
  });

  testWidgets('permission detail renders authorization context', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: PendingInteractionPage(interaction: permission())),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('bash'), findsOneWidget);
    expect(find.text('docker build .'), findsWidgets);
    expect(find.text('/work/shop-api/Dockerfile'), findsOneWidget);
    expect(find.text('docker build *'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.textContaining('"path": "/work/shop-api"'), findsOneWidget);
    expect(find.text('msg-2'), findsOneWidget);
    expect(find.text('允许'), findsNothing);
    expect(find.text('拒绝'), findsNothing);
  });
}
