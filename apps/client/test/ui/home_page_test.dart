import 'dart:async';

import 'package:client/auth/auth_controller.dart';
import 'package:client/auth/auth_state.dart';
import 'package:client/pending/pending_answer.dart';
import 'package:client/pending/pending_controller.dart';
import 'package:client/pending/pending_interaction.dart';
import 'package:client/pending/pending_permission.dart';
import 'package:client/realtime/active_sessions.dart';
import 'package:client/realtime/instance_presence.dart';
import 'package:client/realtime/ws_client.dart';
import 'package:client/ui/home_page.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_auth_controller.dart';

class FakeActiveSessions extends ActiveSessions {
  FakeActiveSessions(this._initial);

  final Map<String, ActiveSession> _initial;

  @override
  Map<String, ActiveSession> build() => _initial;
}

class FakeInstancePresences extends InstancePresences {
  FakeInstancePresences(this._initial);

  final Map<String, OpenCodeInstancePresence> _initial;

  @override
  Map<String, OpenCodeInstancePresence> build() => _initial;
}

class FakePendingInteractions extends PendingInteractionsController {
  FakePendingInteractions(this._initial);

  final List<PendingInteraction> _initial;

  @override
  Future<List<PendingInteraction>> build() async => _initial;
}

class AnswerScript {
  int calls = 0;
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

class DecideScript {
  int calls = 0;
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

Future<void> pumpAnswerableHome(
  WidgetTester tester, {
  required List<PendingInteraction> Function() loader,
  required AnswerScript script,
  DecideScript? decide,
}) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        wsStatusProvider.overrideWith(
          (ref) => Stream.value(WsStatus.connected),
        ),
        activeSessionsProvider.overrideWith(() => FakeActiveSessions(const {})),
        instancePresencesProvider.overrideWith(
          () => FakeInstancePresences(const {}),
        ),
        authControllerProvider.overrideWith(
          () => FakeAuthController(
            const Authenticated(
              accessToken: 'token',
              email: 'user@example.com',
            ),
          ),
        ),
        pendingInteractionLoaderProvider.overrideWithValue(() async {
          return loader();
        }),
        questionAnswerSenderProvider.overrideWithValue(script.call),
        if (decide != null)
          permissionDecisionSenderProvider.overrideWithValue(decide.call),
        commandIdGeneratorProvider.overrideWithValue(() => 'cmd-1'),
      ],
      child: const MaterialApp(home: HomePage()),
    ),
  );
  await tester.pumpAndSettle();
}

const tileKey = ValueKey(
  'interaction-6f0d91b0-93e4-43a9-9449-0bed03e651aa-question-1',
);

Future<void> answerAndSubmit(WidgetTester tester) async {
  await tester.tap(find.byKey(tileKey));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('question-0-option-0')));
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('submit-answer')));
  await tester.pumpAndSettle();
}

void main() {
  Future<void> pumpHome(
    WidgetTester tester, {
    WsStatus status = WsStatus.connected,
    Map<String, ActiveSession> sessions = const {},
    Map<String, OpenCodeInstancePresence> instances = const {},
    List<PendingInteraction> interactions = const [],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          wsStatusProvider.overrideWith((ref) => Stream.value(status)),
          activeSessionsProvider.overrideWith(
            () => FakeActiveSessions(sessions),
          ),
          instancePresencesProvider.overrideWith(
            () => FakeInstancePresences(instances),
          ),
          pendingInteractionsProvider.overrideWith(
            () => FakePendingInteractions(interactions),
          ),
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  ActiveSession session({
    required String id,
    String machine = 'dev-box',
    String project = 'shop-api',
    String title = 'Fix checkout bug',
    Set<String> pending = const {},
  }) => ActiveSession(
    sessionId: id,
    machine: machine,
    project: project,
    title: title,
    lastHeartbeatAt: DateTime.now().subtract(const Duration(minutes: 5)),
    running: true,
    pendingRequestIds: pending,
  );

  OpenCodeInstancePresence instance(String id, InstancePresenceState state) =>
      OpenCodeInstancePresence(
        instanceId: id,
        machine: 'dev-box',
        project: 'shop-api',
        directory: '/work/shop-api',
        openCodeVersion: state == InstancePresenceState.incompatible
            ? '1.18.17'
            : '1.18.18',
        protocolVersion: 1,
        state: state,
        lastSeenAt: DateTime.now().subtract(const Duration(minutes: 2)),
      );

  PendingQuestion pendingQuestion(String id, DateTime occurredAt) =>
      PendingQuestion(
        instanceId: '6f0d91b0-93e4-43a9-9449-0bed03e651aa',
        machine: 'dev-box',
        project: 'shop-api',
        directory: '/work/shop-api',
        sessionId: 'ses-$id',
        sessionTitle: 'Fix checkout bug',
        requestId: id,
        occurredAt: occurredAt,
        tool: null,
        questions: const [
          PendingQuestionItem(
            header: 'Database',
            question: 'Which database?',
            options: [
              PendingOption(label: 'Postgres', description: 'Production'),
            ],
            multiple: false,
            custom: true,
          ),
        ],
      );

  PendingPermission pendingPermission(String id, DateTime occurredAt) =>
      PendingPermission(
        instanceId: '6f0d91b0-93e4-43a9-9449-0bed03e651aa',
        machine: 'dev-box',
        project: 'shop-api',
        directory: '/work/shop-api',
        sessionId: 'ses-$id',
        sessionTitle: 'Release build',
        requestId: id,
        occurredAt: occurredAt,
        tool: null,
        permission: 'bash',
        patterns: const ['docker build .'],
        always: const ['docker build *'],
        metadata: const {'command': 'docker build .'},
      );

  PendingQuestion offlinePendingQuestion(
    String instanceId,
    String id,
    DateTime occurredAt,
  ) => PendingQuestion(
    instanceId: instanceId,
    machine: 'dev-box',
    project: 'shop-api',
    directory: '/work/shop-api',
    sessionId: 'ses-$id',
    sessionTitle: 'Fix checkout bug',
    requestId: id,
    occurredAt: occurredAt,
    tool: null,
    questions: const [
      PendingQuestionItem(
        header: 'Database',
        question: 'Which database?',
        options: [PendingOption(label: 'Postgres', description: 'Production')],
        multiple: false,
        custom: true,
      ),
    ],
  );

  OpenCodeInstancePresence offlinePresence(String id) =>
      OpenCodeInstancePresence(
        instanceId: id,
        machine: 'dev-box',
        project: 'shop-api',
        directory: '/work/shop-api',
        openCodeVersion: '1.18.18',
        protocolVersion: 1,
        state: InstancePresenceState.offline,
        lastSeenAt: DateTime.now().subtract(const Duration(minutes: 2)),
      );

  testWidgets('shows 已连接 when the socket is connected', (tester) async {
    await pumpHome(tester, status: WsStatus.connected);
    expect(find.text('已连接'), findsOneWidget);
  });

  testWidgets('shows 连接中 while connecting', (tester) async {
    await pumpHome(tester, status: WsStatus.connecting);
    expect(find.text('连接中'), findsOneWidget);
  });

  testWidgets('shows 未连接 when disconnected', (tester) async {
    await pumpHome(tester, status: WsStatus.disconnected);
    expect(find.text('未连接'), findsOneWidget);
  });

  testWidgets('empty state when there are no active sessions', (tester) async {
    await pumpHome(tester);
    expect(find.text('暂无活动会话'), findsOneWidget);
  });

  testWidgets(
    'shows pending requests before active sessions and opens detail',
    (tester) async {
      await pumpHome(
        tester,
        interactions: [
          pendingQuestion(
            'question-1',
            DateTime.now().subtract(const Duration(minutes: 10)),
          ),
        ],
        sessions: {'s1': session(id: 's1')},
      );

      final pendingHeader = tester.getTopLeft(find.text('待处理请求')).dy;
      final sessionHeader = tester.getTopLeft(find.text('活动会话')).dy;
      expect(pendingHeader, lessThan(sessionHeader));
      expect(find.text('待回答'), findsOneWidget);
      expect(find.byKey(const ValueKey('pending-refresh')), findsOneWidget);

      await tester.tap(
        find.byKey(
          const ValueKey(
            'interaction-6f0d91b0-93e4-43a9-9449-0bed03e651aa-question-1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('待处理问题'), findsOneWidget);
      expect(find.text('Which database?'), findsOneWidget);
      expect(find.text('Production'), findsOneWidget);
    },
  );

  testWidgets('session rows show machine, project, and elapsed time', (
    tester,
  ) async {
    await pumpHome(tester, sessions: {'s1': session(id: 's1')});

    expect(find.text('dev-box · shop-api'), findsOneWidget);
    expect(find.textContaining('Fix checkout bug'), findsOneWidget);
    expect(find.textContaining('5分钟前'), findsOneWidget);
  });

  testWidgets('sessions with pending actions show a count badge', (
    tester,
  ) async {
    await pumpHome(
      tester,
      sessions: {
        's1': session(id: 's1', pending: {'r1', 'r2'}),
        's2': session(id: 's2', machine: 'laptop', project: 'blog'),
      },
    );

    expect(find.byKey(const ValueKey('pending-s1')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('pending-s1')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
    // No badge for sessions without pending actions.
    expect(find.byKey(const ValueKey('pending-s2')), findsNothing);
  });

  testWidgets('renders every OpenCode instance presence state', (tester) async {
    await pumpHome(
      tester,
      instances: {
        'one': instance('one', InstancePresenceState.controllable),
        'two': instance('two', InstancePresenceState.conflicting),
        'three': instance('three', InstancePresenceState.incompatible),
        'four': instance('four', InstancePresenceState.offline),
      },
    );

    expect(find.text('OpenCode 实例'), findsOneWidget);
    expect(find.text('可远程操作'), findsOneWidget);
    expect(find.text('项目冲突'), findsOneWidget);
    expect(find.text('版本不兼容'), findsOneWidget);
    expect(find.text('离线'), findsOneWidget);
    expect(find.byKey(const ValueKey('instance-one')), findsOneWidget);
  });

  testWidgets(
    'offline requests render in the read-only section between pending and '
    'instances and open the read-only page',
    (tester) async {
      const offlineId = 'off-1';
      final actionable = pendingQuestion(
        'question-1',
        DateTime.now().subtract(const Duration(minutes: 10)),
      );
      final offline = offlinePendingQuestion(
        offlineId,
        'req-offline',
        DateTime.now().subtract(const Duration(minutes: 10)),
      );
      await pumpHome(
        tester,
        interactions: [actionable, offline],
        instances: {offlineId: offlinePresence(offlineId)},
      );

      expect(find.text('离线请求（只读）'), findsOneWidget);
      final pendingY = tester.getTopLeft(find.text('待处理请求')).dy;
      final offlineY = tester.getTopLeft(find.text('离线请求（只读）')).dy;
      final instancesY = tester.getTopLeft(find.text('OpenCode 实例')).dy;
      expect(pendingY, lessThan(offlineY));
      expect(offlineY, lessThan(instancesY));
      expect(
        find.byKey(const ValueKey('offline-off-1-req-offline')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('offline-off-1-req-offline')));
      await tester.pumpAndSettle();

      expect(find.textContaining('实例离线'), findsOneWidget);
      expect(find.byKey(const ValueKey('submit-answer')), findsNothing);
    },
  );

  testWidgets('a lone offline request avoids the empty state', (tester) async {
    const offlineId = 'off-1';
    await pumpHome(
      tester,
      interactions: [
        offlinePendingQuestion(
          offlineId,
          'req-offline',
          DateTime.now().subtract(const Duration(minutes: 10)),
        ),
      ],
      instances: {offlineId: offlinePresence(offlineId)},
    );

    expect(find.text('暂无活动会话'), findsNothing);
    expect(find.text('离线请求（只读）'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('offline-off-1-req-offline')),
      findsOneWidget,
    );
  });

  testWidgets(
    'the request leaves the workbench only after OpenCode confirms it',
    (tester) async {
      final script = AnswerScript()..gate = Completer<QuestionAnswerResult>();
      var confirmed = false;
      final pending = pendingQuestion(
        'question-1',
        DateTime.now().subtract(const Duration(minutes: 10)),
      );
      await pumpAnswerableHome(
        tester,
        loader: () => confirmed ? const <PendingInteraction>[] : [pending],
        script: script,
      );
      expect(find.byKey(tileKey), findsOneWidget);

      await tester.tap(find.byKey(tileKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('question-0-option-0')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('submit-answer')));
      await tester.pump();

      expect(find.byKey(const ValueKey('answer-submitting')), findsOneWidget);
      expect(script.calls, 1);

      confirmed = true;
      script.gate!.complete(
        const QuestionAnswerResult(
          commandId: 'cmd-1',
          outcome: QuestionAnswerOutcome.confirmed,
        ),
      );
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byKey(tileKey), findsNothing);
      expect(find.text('待处理请求'), findsNothing);
    },
  );

  for (final scenario in [
    (name: 'stale', outcome: QuestionAnswerOutcome.stale),
    (name: 'upstream error', outcome: QuestionAnswerOutcome.upstreamError),
    (name: 'result unknown', outcome: QuestionAnswerOutcome.resultUnknown),
  ]) {
    testWidgets('a ${scenario.name} outcome keeps the pending tile', (
      tester,
    ) async {
      final script = AnswerScript()..outcome = scenario.outcome;
      final pending = pendingQuestion(
        'question-1',
        DateTime.now().subtract(const Duration(minutes: 10)),
      );
      await pumpAnswerableHome(tester, loader: () => [pending], script: script);

      await answerAndSubmit(tester);
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byKey(tileKey), findsOneWidget);
      expect(find.text('待处理请求'), findsOneWidget);
    });
  }

  testWidgets('a 4xx gateway rejection keeps the pending tile', (tester) async {
    final script = AnswerScript()
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
    final pending = pendingQuestion(
      'question-1',
      DateTime.now().subtract(const Duration(minutes: 10)),
    );
    await pumpAnswerableHome(tester, loader: () => [pending], script: script);

    await answerAndSubmit(tester);
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byKey(tileKey), findsOneWidget);
  });

  group('permission decisions', () {
    const permissionTileKey = ValueKey(
      'interaction-6f0d91b0-93e4-43a9-9449-0bed03e651aa-permission-1',
    );

    Future<void> decideAndSubmit(WidgetTester tester) async {
      await tester.tap(find.byKey(permissionTileKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('permission-allow-once')));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
    }

    testWidgets(
      'a confirmed permission decision leaves the workbench only after '
      'OpenCode confirms it',
      (tester) async {
        final script = DecideScript()
          ..gate = Completer<PermissionDecisionResult>();
        var confirmed = false;
        final pending = pendingPermission(
          'permission-1',
          DateTime.now().subtract(const Duration(minutes: 10)),
        );
        await pumpAnswerableHome(
          tester,
          loader: () => confirmed ? const <PendingInteraction>[] : [pending],
          script: AnswerScript(),
          decide: script,
        );
        expect(find.byKey(permissionTileKey), findsOneWidget);

        await tester.tap(find.byKey(permissionTileKey));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('permission-allow-once')));
        await tester.pump();

        expect(
          find.byKey(const ValueKey('permission-submitting')),
          findsOneWidget,
        );
        expect(script.calls, 1);

        confirmed = true;
        script.gate!.complete(
          const PermissionDecisionResult(
            commandId: 'cmd-1',
            outcome: PermissionDecisionOutcome.confirmed,
          ),
        );
        await tester.pumpAndSettle();
        await tester.pageBack();
        await tester.pumpAndSettle();

        expect(find.byKey(permissionTileKey), findsNothing);
        expect(find.text('待处理请求'), findsNothing);
      },
    );

    for (final scenario in [
      (name: 'stale', outcome: PermissionDecisionOutcome.stale),
      (
        name: 'upstream error',
        outcome: PermissionDecisionOutcome.upstreamError,
      ),
      (
        name: 'result unknown',
        outcome: PermissionDecisionOutcome.resultUnknown,
      ),
    ]) {
      testWidgets('a ${scenario.name} outcome keeps the permission tile', (
        tester,
      ) async {
        final script = DecideScript()..outcome = scenario.outcome;
        final pending = pendingPermission(
          'permission-1',
          DateTime.now().subtract(const Duration(minutes: 10)),
        );
        await pumpAnswerableHome(
          tester,
          loader: () => [pending],
          script: AnswerScript(),
          decide: script,
        );

        await decideAndSubmit(tester);

        expect(find.byKey(permissionTileKey), findsOneWidget);
        expect(find.text('待处理请求'), findsOneWidget);
      });
    }

    testWidgets('a 4xx rejection keeps the permission tile', (tester) async {
      final script = DecideScript()
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
      final pending = pendingPermission(
        'permission-1',
        DateTime.now().subtract(const Duration(minutes: 10)),
      );
      await pumpAnswerableHome(
        tester,
        loader: () => [pending],
        script: AnswerScript(),
        decide: script,
      );

      await decideAndSubmit(tester);

      expect(find.byKey(permissionTileKey), findsOneWidget);
    });
  });
}
