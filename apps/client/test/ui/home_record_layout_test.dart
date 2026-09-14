import 'package:client/pending/pending_controller.dart';
import 'package:client/realtime/active_sessions.dart';
import 'package:client/realtime/instance_presence.dart';
import 'package:client/realtime/ws_client.dart';
import 'package:client/sessions/session_catalog.dart';
import 'package:client/sessions/webui_browser_controller.dart';
import 'package:client/ui/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'home_page_test.dart'
    show
        FakeInstancePresences,
        FakePendingInteractions,
        FakeSessionCatalog,
        FakeWebUiBrowserController;

void main() {
  testWidgets(
    'entry and saved session rows stay compact with right-aligned working actions',
    (tester) async {
      final entry = OpenCodeInstancePresence(
        instanceId: 'server',
        machine: 'long-machine-name',
        project: 'long-project-name',
        directory: '/work/a/very/long/project/path',
        openCodeVersion: '1.18.30',
        protocolVersion: 2,
        state: InstancePresenceState.controllable,
        lastSeenAt: DateTime.utc(2026),
        webUiAvailable: true,
      );
      final saved = RemoteSession(
        instanceId: entry.instanceId,
        pinned: true,
        session: ActiveSession(
          sessionId: 'saved',
          machine: entry.machine,
          project: entry.project,
          directory: entry.directory,
          title: 'A long saved session title',
          lastHeartbeatAt: DateTime.utc(2026),
          running: false,
        ),
      );
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;
      for (final width in [320.0, 600.0, 1200.0]) {
        for (final scale in [1.0, 2.0]) {
          tester.view.physicalSize = Size(width, 1200);
          final browser = FakeWebUiBrowserController();
          await tester.pumpWidget(
            ProviderScope(
              key: ValueKey('$width-$scale'),
              overrides: [
                instancePresencesProvider.overrideWith(
                  () => FakeInstancePresences({'server': entry}),
                ),
                sessionCatalogProvider.overrideWith(
                  () => FakeSessionCatalog(
                    SessionCatalogState(sessions: {saved.key: saved}),
                  ),
                ),
                pendingInteractionsProvider.overrideWith(
                  () => FakePendingInteractions(const []),
                ),
                offlineLastKnownProvider.overrideWith((ref) => const []),
                webUiBrowserControllerProvider.overrideWith(() => browser),
                wsStatusProvider.overrideWith(
                  (ref) => Stream.value(WsStatus.connected),
                ),
              ],
              child: MaterialApp(
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: const HomePage(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final row = find.byKey(const ValueKey('instance-server'));
          final open = find.byKey(const ValueKey('webui-instance-server'));
          expect(tester.getRect(open).right, greaterThan(width - 24));
          if (scale == 1) {
            expect(tester.getSize(row).height, lessThanOrEqualTo(72));
          }
          expect(
            tester.takeException(),
            isNull,
            reason: 'width=$width scale=$scale',
          );
          await tester.tap(open);
          await tester.pumpAndSettle();
          expect(browser.openCalls, 1);
          expect(browser.openedDirectory, entry.directory);
          await tester.tap(find.text('本机历史'));
          await tester.pumpAndSettle();
          expect(find.byKey(const ValueKey('session-saved')), findsOneWidget);
          await tester.tap(find.byTooltip('更多会话操作'));
          await tester.pumpAndSettle();
          expect(find.text('删除本机会话记录'), findsOneWidget);
          expect(find.text('发送到 OpenCode'), findsOneWidget);
          expect(
            tester.takeException(),
            isNull,
            reason: 'history width=$width scale=$scale',
          );
        }
      }
      await tester.pumpWidget(const SizedBox());
    },
  );
}
