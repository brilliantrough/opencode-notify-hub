import 'dart:async';

import 'package:client/history/notification_history.dart';
import 'package:client/history/resilient_notification_history.dart';
import 'package:flutter_test/flutter_test.dart';

class FailingHistory implements NotificationHistory {
  final StreamController<void> controller = StreamController.broadcast();
  var closeCalls = 0;

  @override
  Stream<void> get changes => controller.stream;

  @override
  Future<void> add(HistoryEntry entry) => Future.error(StateError('disk'));

  @override
  Future<bool> contains(String eventId) => Future.error(StateError('disk'));

  @override
  Future<HistoryBatch> loadPage({required int offset, required int limit}) =>
      Future.error(StateError('disk'));

  @override
  Future<void> close() async {
    closeCalls += 1;
    await controller.close();
  }
}

HistoryEntry _entry(String eventId) => HistoryEntry(
  eventId: eventId,
  title: 'title',
  body: 'body',
  receivedAt: DateTime.utc(2026),
);

void main() {
  test('switches once to in-memory history when SQLite fails', () async {
    final primary = FailingHistory();
    final fallback = InMemoryNotificationHistory();
    final history = ResilientNotificationHistory(
      primary: primary,
      fallback: fallback,
    );

    expect(await history.contains('missing'), isFalse);
    await history.add(_entry('saved-in-memory'));
    final page = await history.loadPage(offset: 0, limit: 10);

    expect(page.entries.single.eventId, 'saved-in-memory');
    expect(primary.closeCalls, 1);
    await history.close();
  });
}
