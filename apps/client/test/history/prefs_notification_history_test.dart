import 'package:client/history/notification_history.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

HistoryEntry _entry(String eventId) => HistoryEntry(
  eventId: eventId,
  title: 'title-$eventId',
  body: 'body-$eventId',
  receivedAt: DateTime.utc(2026, 1, 1),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PrefsNotificationHistory', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('starts empty when nothing was stored', () async {
      final history = await PrefsNotificationHistory.load();

      expect(history.entries, isEmpty);
    });

    test('entries are newest-first', () async {
      final history = await PrefsNotificationHistory.load();

      await history.add(_entry('a'));
      await history.add(_entry('b'));
      await history.add(_entry('c'));

      expect(history.entries.map((e) => e.eventId), ['c', 'b', 'a']);
    });

    test('51 entries keep the newest 50 and drop the oldest', () async {
      final history = await PrefsNotificationHistory.load();

      for (var i = 0; i < 51; i++) {
        await history.add(_entry('evt-$i'));
      }

      expect(history.entries, hasLength(50));
      expect(history.entries.first.eventId, 'evt-50');
      expect(history.entries.last.eventId, 'evt-1');
      expect(history.entries.any((e) => e.eventId == 'evt-0'), isFalse);
    });

    test('survives a restart: a new instance loads the persisted entries', () async {
      final first = await PrefsNotificationHistory.load();
      await first.add(_entry('a'));
      await first.add(_entry('b'));

      final second = await PrefsNotificationHistory.load();

      expect(second.entries.map((e) => e.eventId), ['b', 'a']);
      expect(second.entries.first.title, 'title-b');
      expect(second.entries.first.body, 'body-b');
      expect(second.entries.first.receivedAt, DateTime.utc(2026, 1, 1));
    });

    test('the 50-entry cap survives a restart', () async {
      final first = await PrefsNotificationHistory.load();
      for (var i = 0; i < 51; i++) {
        await first.add(_entry('evt-$i'));
      }

      final second = await PrefsNotificationHistory.load();

      expect(second.entries, hasLength(50));
      expect(second.entries.first.eventId, 'evt-50');
      expect(second.entries.last.eventId, 'evt-1');
    });

    test('contains reports recorded and unknown event IDs', () async {
      final history = await PrefsNotificationHistory.load();
      await history.add(_entry('known'));

      expect(history.contains('known'), isTrue);
      expect(history.contains('unknown'), isFalse);
    });

    test('contains works after a restart', () async {
      final first = await PrefsNotificationHistory.load();
      await first.add(_entry('persisted'));

      final second = await PrefsNotificationHistory.load();

      expect(second.contains('persisted'), isTrue);
      expect(second.contains('missing'), isFalse);
    });

    test('corrupt stored JSON loads as empty history', () async {
      SharedPreferences.setMockInitialValues({
        'notification_history_v1': '{not valid json',
      });

      final history = await PrefsNotificationHistory.load();

      expect(history.entries, isEmpty);
    });

    test('stored JSON of the wrong shape loads as empty history', () async {
      SharedPreferences.setMockInitialValues({
        'notification_history_v1': '{"unexpected": "shape"}',
      });

      final history = await PrefsNotificationHistory.load();

      expect(history.entries, isEmpty);
    });

    test('recovers from corrupt JSON on the next add', () async {
      SharedPreferences.setMockInitialValues({
        'notification_history_v1': '{not valid json',
      });
      final history = await PrefsNotificationHistory.load();

      await history.add(_entry('fresh'));

      final reloaded = await PrefsNotificationHistory.load();
      expect(reloaded.entries.map((e) => e.eventId), ['fresh']);
    });
  });

  group('PrefsNotificationHistory.hydrating', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('starts empty and hydrates the stored entries asynchronously',
        () async {
      final seed = await PrefsNotificationHistory.load();
      await seed.add(_entry('a'));
      await seed.add(_entry('b'));

      final history = PrefsNotificationHistory.hydrating();
      // The synchronous view is empty until the disk load completes.
      expect(history.entries, isEmpty);

      await history.ready;

      expect(history.entries.map((e) => e.eventId), ['b', 'a']);
      expect(history.contains('a'), isTrue);
    });

    test('entries added before hydration completes are kept in front and '
        'persisted with the hydrated ones', () async {
      final seed = await PrefsNotificationHistory.load();
      await seed.add(_entry('stored'));

      final history = PrefsNotificationHistory.hydrating();
      // Added synchronously after construction, racing the hydration.
      final added = history.add(_entry('fresh'));

      await Future.wait([added, history.ready]);

      expect(history.entries.map((e) => e.eventId), ['fresh', 'stored']);
      final reloaded = await PrefsNotificationHistory.load();
      expect(reloaded.entries.map((e) => e.eventId), ['fresh', 'stored']);
    });

    test('hydration drops stored duplicates of freshly added event IDs',
        () async {
      final seed = await PrefsNotificationHistory.load();
      await seed.add(_entry('same'));

      final history = PrefsNotificationHistory.hydrating();
      await history.add(_entry('same'));
      await history.ready;

      expect(history.entries.map((e) => e.eventId), ['same']);
    });

    test('hydrates to an empty history when nothing was stored', () async {
      final history = PrefsNotificationHistory.hydrating();

      await history.ready;

      expect(history.entries, isEmpty);
      // Persistence becomes active after hydration.
      await history.add(_entry('x'));
      final reloaded = await PrefsNotificationHistory.load();
      expect(reloaded.entries.map((e) => e.eventId), ['x']);
    });
  });
}
