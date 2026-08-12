import 'package:client/history/notification_history.dart';
import 'package:flutter_test/flutter_test.dart';

HistoryEntry _entry(String eventId) => HistoryEntry(
  eventId: eventId,
  title: 'title-$eventId',
  body: 'body-$eventId',
  receivedAt: DateTime.utc(2026, 1, 1),
);

void main() {
  group('InMemoryNotificationHistory', () {
    test('capacity 0 throws ArgumentError', () {
      expect(() => InMemoryNotificationHistory(capacity: 0), throwsArgumentError);
    });

    test('entries are newest-first', () {
      final history = InMemoryNotificationHistory();

      history.add(_entry('a'));
      history.add(_entry('b'));
      history.add(_entry('c'));

      expect(history.entries.map((e) => e.eventId), ['c', 'b', 'a']);
    });

    test('51 entries keep the newest 50 and drop the oldest', () {
      final history = InMemoryNotificationHistory();

      for (var i = 0; i < 51; i++) {
        history.add(_entry('evt-$i'));
      }

      expect(history.entries, hasLength(50));
      expect(history.entries.first.eventId, 'evt-50');
      expect(history.entries.last.eventId, 'evt-1');
      expect(
        history.entries.any((e) => e.eventId == 'evt-0'),
        isFalse,
        reason: 'the oldest entry is dropped',
      );
    });

    test('a custom capacity bounds the entries the same way', () {
      final history = InMemoryNotificationHistory(capacity: 2);

      history.add(_entry('a'));
      history.add(_entry('b'));
      history.add(_entry('c'));

      expect(history.entries.map((e) => e.eventId), ['c', 'b']);
    });

    test('entries view is unmodifiable', () {
      final history = InMemoryNotificationHistory();
      history.add(_entry('a'));

      expect(
        () => history.entries.add(_entry('b')),
        throwsUnsupportedError,
      );
    });
  });
}
