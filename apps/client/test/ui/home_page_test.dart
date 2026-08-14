import 'package:client/pending/pending_controller.dart';
import 'package:client/pending/pending_interaction.dart';
import 'package:client/realtime/active_sessions.dart';
import 'package:client/realtime/instance_presence.dart';
import 'package:client/realtime/ws_client.dart';
import 'package:client/ui/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
