import 'package:client/realtime/active_sessions.dart';
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

void main() {
  Future<void> pumpHome(
    WidgetTester tester, {
    WsStatus status = WsStatus.connected,
    Map<String, ActiveSession> sessions = const {},
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          wsStatusProvider.overrideWith((ref) => Stream.value(status)),
          activeSessionsProvider.overrideWith(() => FakeActiveSessions(sessions)),
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

  testWidgets('session rows show machine, project, and elapsed time', (
    tester,
  ) async {
    await pumpHome(
      tester,
      sessions: {'s1': session(id: 's1')},
    );

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
}
