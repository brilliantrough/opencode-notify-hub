import 'package:client/history/notification_history.dart';
import 'package:client/realtime/realtime_controller.dart';
import 'package:client/ui/history_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  HistoryEntry entry(String eventId, String title, DateTime receivedAt) =>
      HistoryEntry(
        eventId: eventId,
        title: title,
        body: 'body of $title',
        receivedAt: receivedAt,
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

  testWidgets('lists entries newest first', (tester) async {
    final history = InMemoryNotificationHistory();
    final base = DateTime.utc(2026, 2, 1, 10);
    history.add(entry('e1', 'oldest entry', base));
    history.add(entry('e2', 'middle entry', base.add(const Duration(hours: 1))));
    history.add(entry('e3', 'newest entry', base.add(const Duration(hours: 2))));

    await pumpHistory(tester, history);

    expect(find.text('newest entry'), findsOneWidget);
    expect(find.text('middle entry'), findsOneWidget);
    expect(find.text('oldest entry'), findsOneWidget);
    expect(find.text('body of newest entry'), findsOneWidget);

    final newestY = tester.getTopLeft(find.text('newest entry')).dy;
    final middleY = tester.getTopLeft(find.text('middle entry')).dy;
    final oldestY = tester.getTopLeft(find.text('oldest entry')).dy;
    expect(newestY, lessThan(middleY));
    expect(middleY, lessThan(oldestY));
  });
}
