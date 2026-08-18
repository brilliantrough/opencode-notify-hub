import 'package:client/history/notification_history.dart';
import 'package:client/realtime/realtime_controller.dart';
import 'package:client/ui/history_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  HistoryEntry entry(
    String eventId,
    String title,
    DateTime receivedAt, {
    String? body,
    String? directoryName,
    String? directory,
    String? sessionTitle,
    String? status,
    String? machine,
    String? project,
  }) => HistoryEntry(
    eventId: eventId,
    title: title,
    body: body ?? 'body of $title',
    receivedAt: receivedAt,
    occurredAt: receivedAt.subtract(const Duration(seconds: 2)),
    eventType: 'terminal',
    directoryName: directoryName,
    directory: directory,
    sessionTitle: sessionTitle,
    sessionId: sessionTitle == null ? null : 'ses-$eventId',
    status: status,
    machine: machine,
    project: project,
  );

  Future<void> pumpHistory(
    WidgetTester tester,
    NotificationHistory history,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [notificationHistoryProvider.overrideWithValue(history)],
        child: const MaterialApp(home: HistoryPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('empty state when there is no history', (tester) async {
    await pumpHistory(tester, InMemoryNotificationHistory());
    expect(find.text('暂无通知历史'), findsOneWidget);
  });

  testWidgets('shows a compact table newest first', (tester) async {
    final history = InMemoryNotificationHistory();
    final base = DateTime.utc(2026, 2, 1, 10);
    history.add(
      entry(
        'e1',
        'oldest entry',
        base,
        directoryName: 'old-dir',
        sessionTitle: 'Old session',
        status: '任务已完成',
        machine: 'old-machine',
      ),
    );
    history.add(
      entry(
        'e2',
        'middle entry',
        base.add(const Duration(hours: 1)),
        directoryName: 'middle-dir',
        sessionTitle: 'Middle session',
        status: '需要授权',
        machine: 'middle-machine',
      ),
    );
    history.add(
      entry(
        'e3',
        'newest entry',
        base.add(const Duration(hours: 2)),
        directoryName: 'new-dir',
        sessionTitle: 'Newest session',
        status: '任务失败',
        machine: 'new-machine',
      ),
    );

    await pumpHistory(tester, history);

    expect(find.text('时间'), findsOneWidget);
    expect(find.text('机器'), findsOneWidget);
    expect(find.text('目录'), findsOneWidget);
    expect(find.text('会话'), findsOneWidget);
    expect(find.text('状态'), findsOneWidget);
    expect(find.text('body of newest entry'), findsNothing);
    expect(find.text('new-machine'), findsOneWidget);

    final newestY = tester.getTopLeft(find.text('new-dir')).dy;
    final middleY = tester.getTopLeft(find.text('middle-dir')).dy;
    final oldestY = tester.getTopLeft(find.text('old-dir')).dy;
    expect(newestY, lessThan(middleY));
    expect(middleY, lessThan(oldestY));
  });

  testWidgets('clicking a row expands and collapses its detail table', (
    tester,
  ) async {
    final history = InMemoryNotificationHistory();
    history.add(
      entry(
        'detail',
        'notify · Fix login · 任务已完成',
        DateTime.utc(2026, 2, 1, 10),
        body: '用时 42 秒\nAll tests passed',
        directoryName: 'notify',
        directory: '/work/opencode-notify',
        sessionTitle: 'Fix login',
        status: '任务已完成',
        machine: 'devbox',
        project: 'linewrite',
      ),
    );
    await pumpHistory(tester, history);

    expect(find.text('用时 42 秒\nAll tests passed').hitTestable(), findsNothing);
    expect(find.text('devbox'), findsOneWidget);

    await tester.tap(find.text('notify'));
    await tester.pumpAndSettle();

    expect(find.byKey(HistoryPage.detailsKey('detail')), findsOneWidget);
    expect(
      find.text('用时 42 秒\nAll tests passed').hitTestable(),
      findsOneWidget,
    );
    expect(find.text('工作目录'), findsOneWidget);
    expect(find.text('/work/opencode-notify'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(HistoryPage.detailsKey('detail')),
        matching: find.text('机器'),
      ),
      findsOneWidget,
    );
    expect(find.text('devbox'), findsNWidgets(2));
    expect(find.text('Session ID'), findsOneWidget);
    expect(find.text('Event ID'), findsOneWidget);

    await tester.tap(find.text('notify'));
    await tester.pumpAndSettle();
    expect(find.text('用时 42 秒\nAll tests passed').hitTestable(), findsNothing);
  });

  testWidgets('compact rows show machine and directory together', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final history = InMemoryNotificationHistory()
      ..add(
        entry(
          'compact',
          'compact entry',
          DateTime.utc(2026, 2, 1, 10),
          machine: 'devbox',
          directoryName: 'notify',
          sessionTitle: 'Fix login',
          status: '需要回答',
        ),
      );

    await pumpHistory(tester, history);

    expect(find.text('devbox · notify'), findsOneWidget);
    expect(find.text('Fix login'), findsOneWidget);
  });

  testWidgets('legacy entries without structured fields still expand', (
    tester,
  ) async {
    final history = InMemoryNotificationHistory()
      ..add(
        entry(
          'legacy',
          'legacy title',
          DateTime.utc(2026, 2, 1, 10),
          body: 'legacy body',
        ),
      );

    await pumpHistory(tester, history);
    expect(find.text('legacy title'), findsOneWidget);
    await tester.tap(find.text('legacy title'));
    await tester.pumpAndSettle();
    expect(find.text('legacy body'), findsOneWidget);
    expect(find.text('Event ID'), findsOneWidget);
  });

  for (final scale in [1.0, 1.25, 1.5, 2.0]) {
    testWidgets('renders long expanded details at ${scale}x display scale', (
      tester,
    ) async {
      tester.view.devicePixelRatio = scale;
      tester.view.physicalSize = Size(1280 * scale, 720 * scale);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final history = InMemoryNotificationHistory();
      history.add(
        entry(
          'long-$scale',
          'OpenCode task completed with a deliberately long notification title',
          DateTime.utc(2026, 2, 1, 10),
          directoryName: 'opencode-notify-with-a-long-directory-name',
          directory:
              r'C:\Users\example\Projects\opencode-notify\very-long-path',
          sessionTitle:
              'A long session title remains readable without shifting columns',
          status: '任务已完成',
          body:
              'A long notification body remains readable without clipping or '
              'overflow when Windows display scaling changes.',
        ),
      );

      await pumpHistory(tester, history);
      await tester.tap(find.text('opencode-notify-with-a-long-directory-name'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(HistoryPage.detailsKey('long-$scale')), findsOneWidget);
    });
  }
}
