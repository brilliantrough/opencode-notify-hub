import 'dart:async';

import 'package:client/auth/auth_controller.dart';
import 'package:client/auth/auth_state.dart';
import 'package:client/pending/pending_answer.dart';
import 'package:client/pending/pending_controller.dart';
import 'package:client/pending/pending_interaction.dart';
import 'package:client/pending/pending_permission.dart';
import 'package:client/ui/pending_interaction_page.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_auth_controller.dart';

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
      multiple: false,
      custom: true,
    ),
    PendingQuestionItem(
      header: 'Migration',
      question: 'What else should the migration do?',
      options: [
        PendingOption(label: 'Migrate data', description: 'Copy rows'),
        PendingOption(label: 'Add indexes', description: 'Speed queries'),
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

class ScriptedAnswerSender {
  int calls = 0;
  final List<
    ({
      String instanceId,
      String requestId,
      String commandId,
      List<List<String>> answers,
    })
  >
  received = [];
  Completer<QuestionAnswerResult>? gate;
  QuestionAnswerOutcome outcome = QuestionAnswerOutcome.confirmed;
  Object? throwError;

  Future<QuestionAnswerResult> call({
    required String instanceId,
    required String requestId,
    required String commandId,
    required List<List<String>> answers,
  }) async {
    calls++;
    received.add((
      instanceId: instanceId,
      requestId: requestId,
      commandId: commandId,
      answers: answers,
    ));
    final current = gate;
    if (current != null) {
      return current.future;
    }
    final error = throwError;
    if (error != null) {
      throw error;
    }
    return QuestionAnswerResult(commandId: commandId, outcome: outcome);
  }
}

class ScriptedDecisionSender {
  int calls = 0;
  final List<
    ({
      String instanceId,
      String requestId,
      String commandId,
      PermissionDecision decision,
    })
  >
  received = [];
  Completer<PermissionDecisionResult>? gate;
  PermissionDecisionOutcome outcome = PermissionDecisionOutcome.confirmed;
  Object? throwError;

  Future<PermissionDecisionResult> call({
    required String instanceId,
    required String requestId,
    required String commandId,
    required PermissionDecision decision,
  }) async {
    calls++;
    received.add((
      instanceId: instanceId,
      requestId: requestId,
      commandId: commandId,
      decision: decision,
    ));
    final current = gate;
    if (current != null) {
      return current.future;
    }
    final error = throwError;
    if (error != null) {
      throw error;
    }
    return PermissionDecisionResult(commandId: commandId, outcome: outcome);
  }
}

Future<void> pumpPage(
  WidgetTester tester, {
  required PendingInteraction interaction,
  required QuestionAnswerSender sender,
  PermissionDecisionSender? decisionSender,
}) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          () => FakeAuthController(
            const Authenticated(
              accessToken: 'token',
              email: 'user@example.com',
            ),
          ),
        ),
        pendingInteractionLoaderProvider.overrideWithValue(() async {
          return [interaction];
        }),
        questionAnswerSenderProvider.overrideWithValue(sender),
        if (decisionSender != null)
          permissionDecisionSenderProvider.overrideWithValue(decisionSender),
        commandIdGeneratorProvider.overrideWithValue(() => 'cmd-1'),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        PendingInteractionPage(interaction: interaction),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> answerEverything(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('question-0-option-1')));
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('question-1-option-0')));
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('question-1-option-1')));
  await tester.pump();
}

bool submitEnabled(WidgetTester tester) {
  final button = tester.widget<FilledButton>(
    find.byKey(const ValueKey('submit-answer')),
  );
  return button.onPressed != null;
}

bool allowOnceEnabled(WidgetTester tester) {
  final button = tester.widget<FilledButton>(
    find.byKey(const ValueKey('permission-allow-once')),
  );
  return button.onPressed != null;
}

bool rejectEnabled(WidgetTester tester) {
  final button = tester.widget<OutlinedButton>(
    find.byKey(const ValueKey('permission-reject')),
  );
  return button.onPressed != null;
}

void main() {
  testWidgets('renders every question, option, and custom field in order', (
    tester,
  ) async {
    await pumpPage(
      tester,
      interaction: question(),
      sender: ScriptedAnswerSender().call,
    );

    expect(
      find.text('Which database should the migration target?'),
      findsOneWidget,
    );
    expect(find.text('What else should the migration do?'), findsOneWidget);
    expect(find.text('PostgreSQL'), findsOneWidget);
    expect(find.text('Production parity'), findsOneWidget);
    expect(find.text('SQLite'), findsOneWidget);
    expect(find.text('Migrate data'), findsOneWidget);
    expect(find.text('Add indexes'), findsOneWidget);
    expect(find.byKey(const ValueKey('question-0-custom')), findsOneWidget);
    expect(find.byKey(const ValueKey('question-1-custom')), findsOneWidget);
    expect(find.byKey(const ValueKey('submit-answer')), findsOneWidget);
    expect(submitEnabled(tester), isFalse);
  });

  testWidgets('submit stays disabled until every question is answered', (
    tester,
  ) async {
    await pumpPage(
      tester,
      interaction: question(),
      sender: ScriptedAnswerSender().call,
    );

    await tester.tap(find.byKey(const ValueKey('question-0-option-1')));
    await tester.pump();
    expect(submitEnabled(tester), isFalse);

    await tester.tap(find.byKey(const ValueKey('question-1-option-0')));
    await tester.pump();
    expect(submitEnabled(tester), isTrue);
  });

  testWidgets('single-select custom text is exclusive with option selection', (
    tester,
  ) async {
    final sender = ScriptedAnswerSender();
    await pumpPage(tester, interaction: question(), sender: sender.call);

    await tester.tap(find.byKey(const ValueKey('question-0-option-0')));
    await tester.pump();
    RadioGroup<String> group = tester.widget<RadioGroup<String>>(
      find.byType(RadioGroup<String>),
    );
    expect(group.groupValue, 'PostgreSQL');

    await tester.enterText(
      find.byKey(const ValueKey('question-0-custom')),
      'MongoDB',
    );
    await tester.pump();
    group = tester.widget<RadioGroup<String>>(find.byType(RadioGroup<String>));
    expect(group.groupValue, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('question-1-custom')),
      'Reuse the existing migration',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('submit-answer')));
    await tester.pumpAndSettle();

    expect(sender.received.single.answers, [
      ['MongoDB'],
      ['Reuse the existing migration'],
    ]);
  });

  testWidgets('selecting a single option clears the custom text', (
    tester,
  ) async {
    final sender = ScriptedAnswerSender();
    await pumpPage(tester, interaction: question(), sender: sender.call);

    await tester.enterText(
      find.byKey(const ValueKey('question-0-custom')),
      'MongoDB',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('question-0-option-0')));
    await tester.pump();

    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('question-0-custom')),
    );
    expect(field.controller!.text, isEmpty);
    await tester.tap(find.byKey(const ValueKey('question-1-option-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('submit-answer')));
    await tester.pumpAndSettle();
    expect(sender.received.single.answers, [
      ['PostgreSQL'],
      ['Migrate data'],
    ]);
  });

  testWidgets('multi-select custom accompanies the selected options', (
    tester,
  ) async {
    final sender = ScriptedAnswerSender();
    await pumpPage(tester, interaction: question(), sender: sender.call);

    await answerEverything(tester);
    await tester.enterText(
      find.byKey(const ValueKey('question-1-custom')),
      'Use read replicas',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('submit-answer')));
    await tester.pumpAndSettle();

    expect(sender.received.single.answers, [
      ['SQLite'],
      ['Migrate data', 'Add indexes', 'Use read replicas'],
    ]);
  });

  testWidgets('shows submitting then confirmed and never resubmits', (
    tester,
  ) async {
    final sender = ScriptedAnswerSender()
      ..gate = Completer<QuestionAnswerResult>();
    await pumpPage(tester, interaction: question(), sender: sender.call);

    await answerEverything(tester);
    await tester.tap(find.byKey(const ValueKey('submit-answer')));
    await tester.pump();

    expect(find.byKey(const ValueKey('answer-submitting')), findsOneWidget);
    expect(find.text('正在提交回答…'), findsOneWidget);
    expect(submitEnabled(tester), isFalse);

    sender.gate!.complete(
      const QuestionAnswerResult(
        commandId: 'cmd-1',
        outcome: QuestionAnswerOutcome.confirmed,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('已确认'), findsOneWidget);
    expect(sender.calls, 1);
  });

  for (final scenario in [
    (
      name: 'stale',
      outcome: QuestionAnswerOutcome.stale,
      text: '该问题已失效，可能已在其他设备处理。',
    ),
    (
      name: 'upstream error',
      outcome: QuestionAnswerOutcome.upstreamError,
      text: '上游 OpenCode 返回错误，回答未被应用。',
    ),
    (
      name: 'result unknown',
      outcome: QuestionAnswerOutcome.resultUnknown,
      text: '结果未知，问题仍在等待回答。',
    ),
  ]) {
    testWidgets('${scenario.name} keeps the request visible', (tester) async {
      final sender = ScriptedAnswerSender()..outcome = scenario.outcome;
      await pumpPage(tester, interaction: question(), sender: sender.call);

      await answerEverything(tester);
      await tester.tap(find.byKey(const ValueKey('submit-answer')));
      await tester.pumpAndSettle();

      expect(find.text(scenario.text), findsOneWidget);
      expect(
        find.text('Which database should the migration target?'),
        findsOneWidget,
      );
      expect(submitEnabled(tester), isTrue);
    });
  }

  testWidgets('a 4xx rejection keeps the request visible', (tester) async {
    final sender = ScriptedAnswerSender()
      ..throwError = DioException(
        requestOptions: RequestOptions(
          path: '/v1/pending-interactions/i/questions/q/answer',
        ),
        response: Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 409,
        ),
        type: DioExceptionType.badResponse,
      );
    await pumpPage(tester, interaction: question(), sender: sender.call);

    await answerEverything(tester);
    await tester.tap(find.byKey(const ValueKey('submit-answer')));
    await tester.pumpAndSettle();

    expect(find.text('网关拒绝了该回答，请求可能已失效。'), findsOneWidget);
    expect(
      find.text('Which database should the migration target?'),
      findsOneWidget,
    );
    expect(submitEnabled(tester), isTrue);
  });

  testWidgets(
    'permission page renders the complete authorization object with only '
    'allow-once and reject actions',
    (tester) async {
      await pumpPage(
        tester,
        interaction: permission(),
        sender: ScriptedAnswerSender().call,
        decisionSender: ScriptedDecisionSender().call,
      );

      expect(find.text('待处理权限'), findsOneWidget);
      expect(find.text('build-host'), findsOneWidget);
      expect(find.text('shop-api'), findsOneWidget);
      expect(find.text('/work/shop-api'), findsOneWidget);
      expect(find.textContaining('Release build'), findsOneWidget);
      expect(find.text('bash'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('permission-pattern-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('permission-pattern-1')),
        findsOneWidget,
      );
      expect(find.text('docker build .'), findsWidgets);
      expect(find.text('/work/shop-api/Dockerfile'), findsOneWidget);
      expect(find.text('永久允许范围'), findsOneWidget);
      expect(find.byKey(const ValueKey('permission-always-0')), findsOneWidget);
      expect(find.text('docker build *'), findsOneWidget);
      expect(find.textContaining('"path": "/work/shop-api"'), findsOneWidget);
      expect(find.text('msg-2'), findsOneWidget);
      expect(find.text('call-2'), findsOneWidget);

      expect(
        find.byKey(const ValueKey('permission-allow-once')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('permission-reject')), findsOneWidget);
      expect(find.text('允许一次'), findsOneWidget);
      expect(find.text('拒绝'), findsOneWidget);
      expect(find.byKey(const ValueKey('submit-answer')), findsNothing);
      expect(find.byType(TextField), findsNothing);
    },
  );

  testWidgets('permission page never offers an always-allow action', (
    tester,
  ) async {
    await pumpPage(
      tester,
      interaction: permission(),
      sender: ScriptedAnswerSender().call,
      decisionSender: ScriptedDecisionSender().call,
    );

    expect(find.byKey(const ValueKey('permission-always-allow')), findsNothing);
    expect(find.textContaining('始终允许'), findsNothing);
    expect(find.textContaining('Always allow'), findsNothing);
  });

  testWidgets(
    'allow once shows submitting then confirmed and never resubmits',
    (tester) async {
      final sender = ScriptedDecisionSender()
        ..gate = Completer<PermissionDecisionResult>();
      await pumpPage(
        tester,
        interaction: permission(),
        sender: ScriptedAnswerSender().call,
        decisionSender: sender.call,
      );

      await tester.tap(find.byKey(const ValueKey('permission-allow-once')));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('permission-submitting')),
        findsOneWidget,
      );
      expect(find.text('正在提交权限决定…'), findsOneWidget);
      expect(allowOnceEnabled(tester), isFalse);
      expect(rejectEnabled(tester), isFalse);

      sender.gate!.complete(
        const PermissionDecisionResult(
          commandId: 'cmd-1',
          outcome: PermissionDecisionOutcome.confirmed,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('已确认'), findsOneWidget);
      expect(sender.calls, 1);
      expect(sender.received.single.decision, PermissionDecision.once);
      expect(allowOnceEnabled(tester), isFalse);
      expect(rejectEnabled(tester), isFalse);
    },
  );

  testWidgets('reject submits once and confirms the request', (tester) async {
    final sender = ScriptedDecisionSender()
      ..outcome = PermissionDecisionOutcome.confirmed;
    await pumpPage(
      tester,
      interaction: permission(),
      sender: ScriptedAnswerSender().call,
      decisionSender: sender.call,
    );

    await tester.tap(find.byKey(const ValueKey('permission-reject')));
    await tester.pumpAndSettle();

    expect(sender.calls, 1);
    expect(sender.received.single.decision, PermissionDecision.reject);
    expect(find.textContaining('已确认'), findsOneWidget);
  });

  for (final scenario in [
    (
      name: 'stale',
      outcome: PermissionDecisionOutcome.stale,
      text: '该权限请求已失效，可能已在其他设备处理。',
    ),
    (
      name: 'upstream error',
      outcome: PermissionDecisionOutcome.upstreamError,
      text: '上游 OpenCode 返回错误，决定未被应用。',
    ),
    (
      name: 'result unknown',
      outcome: PermissionDecisionOutcome.resultUnknown,
      text: '结果未知，权限请求仍在等待。',
    ),
  ]) {
    testWidgets('a ${scenario.name} outcome keeps the permission visible', (
      tester,
    ) async {
      final sender = ScriptedDecisionSender()..outcome = scenario.outcome;
      await pumpPage(
        tester,
        interaction: permission(),
        sender: ScriptedAnswerSender().call,
        decisionSender: sender.call,
      );

      await tester.tap(find.byKey(const ValueKey('permission-allow-once')));
      await tester.pumpAndSettle();

      expect(find.text(scenario.text), findsOneWidget);
      expect(find.text('bash'), findsOneWidget);
      expect(allowOnceEnabled(tester), isTrue);
      expect(rejectEnabled(tester), isTrue);
    });
  }

  testWidgets('a 4xx rejection keeps the permission request visible', (
    tester,
  ) async {
    final sender = ScriptedDecisionSender()
      ..throwError = DioException(
        requestOptions: RequestOptions(
          path: '/v1/pending-interactions/i/permissions/p/decision',
        ),
        response: Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 409,
        ),
        type: DioExceptionType.badResponse,
      );
    await pumpPage(
      tester,
      interaction: permission(),
      sender: ScriptedAnswerSender().call,
      decisionSender: sender.call,
    );

    await tester.tap(find.byKey(const ValueKey('permission-allow-once')));
    await tester.pumpAndSettle();

    expect(find.text('网关拒绝了该决定，请求可能已失效。'), findsOneWidget);
    expect(find.text('bash'), findsOneWidget);
    expect(allowOnceEnabled(tester), isTrue);
    expect(rejectEnabled(tester), isTrue);
  });

  testWidgets('back navigation never submits a permission decision', (
    tester,
  ) async {
    final sender = ScriptedDecisionSender();
    await pumpPage(
      tester,
      interaction: permission(),
      sender: ScriptedAnswerSender().call,
      decisionSender: sender.call,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(sender.calls, 0);
    expect(find.byType(PendingInteractionPage), findsNothing);
  });

  testWidgets('back navigation never submits or rejects', (tester) async {
    final sender = ScriptedAnswerSender();
    await pumpPage(tester, interaction: question(), sender: sender.call);

    await tester.tap(find.byKey(const ValueKey('question-0-option-0')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('question-1-custom')),
      'Draft answer',
    );
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(sender.calls, 0);
    expect(find.byType(PendingInteractionPage), findsNothing);
  });
}
