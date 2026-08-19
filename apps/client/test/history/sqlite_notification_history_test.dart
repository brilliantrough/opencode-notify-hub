import 'dart:io';

import 'package:client/history/notification_history.dart';
import 'package:client/history/sqlite_notification_history.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

HistoryEntry _entry(String eventId, int minute) => HistoryEntry(
  eventId: eventId,
  title: 'title-$eventId',
  body: 'body-$eventId',
  receivedAt: DateTime.utc(2026, 1, 1, 0, minute),
);

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  tearDownAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
  });

  group('SqliteNotificationHistory', () {
    late SqliteNotificationHistory history;

    setUp(() {
      history = SqliteNotificationHistory(NativeDatabase.memory());
    });

    tearDown(() => history.close());

    test('starts empty and validates paging arguments', () async {
      expect(
        await history.loadPage(offset: 0, limit: 50),
        isA<HistoryBatch>()
            .having((batch) => batch.entries, 'entries', isEmpty)
            .having((batch) => batch.totalCount, 'totalCount', 0),
      );
      await expectLater(
        history.loadPage(offset: -1, limit: 10),
        throwsArgumentError,
      );
      await expectLater(
        history.loadPage(offset: 0, limit: 0),
        throwsArgumentError,
      );
    });

    test('orders newest first and only loads the requested page', () async {
      for (var i = 0; i < 75; i++) {
        await history.add(_entry('evt-$i', i));
      }

      final first = await history.loadPage(offset: 0, limit: 20);
      final second = await history.loadPage(offset: 20, limit: 20);

      expect(first.totalCount, 75);
      expect(first.entries, hasLength(20));
      expect(first.entries.first.eventId, 'evt-74');
      expect(first.entries.last.eventId, 'evt-55');
      expect(second.entries.first.eventId, 'evt-54');
      expect(second.entries.last.eventId, 'evt-35');
    });

    test('keeps only the newest configured capacity', () async {
      await history.close();
      history = SqliteNotificationHistory(NativeDatabase.memory(), capacity: 3);
      for (var i = 0; i < 5; i++) {
        await history.add(_entry('evt-$i', i));
      }

      final page = await history.loadPage(offset: 0, limit: 10);

      expect(page.entries.map((entry) => entry.eventId), [
        'evt-4',
        'evt-3',
        'evt-2',
      ]);
      expect(page.totalCount, 3);
      expect(await history.contains('evt-0'), isFalse);
    });

    test('round-trips all structured fields', () async {
      await history.add(
        HistoryEntry(
          eventId: 'structured',
          title: 'title',
          body: 'body',
          receivedAt: DateTime.utc(2026, 1, 2, 3, 4),
          occurredAt: DateTime.utc(2026, 1, 2, 3, 3),
          status: '任务已完成',
          eventType: 'terminal',
          machine: 'devbox',
          project: 'linewrite',
          directory: '/work/notify',
          directoryName: 'notify',
          sessionId: 'ses_1',
          sessionTitle: 'Fix login',
          requestId: 'req_1',
        ),
      );

      final entry = (await history.loadPage(
        offset: 0,
        limit: 1,
      )).entries.single;

      expect(entry.receivedAt, DateTime.utc(2026, 1, 2, 3, 4));
      expect(entry.occurredAt, DateTime.utc(2026, 1, 2, 3, 3));
      expect(entry.status, '任务已完成');
      expect(entry.eventType, 'terminal');
      expect(entry.machine, 'devbox');
      expect(entry.project, 'linewrite');
      expect(entry.directory, '/work/notify');
      expect(entry.directoryName, 'notify');
      expect(entry.sessionId, 'ses_1');
      expect(entry.sessionTitle, 'Fix login');
      expect(entry.requestId, 'req_1');
    });

    test('ignores duplicate event IDs and emits one change', () async {
      var changes = 0;
      final subscription = history.changes.listen((_) => changes += 1);

      await history.add(_entry('same', 1));
      await history.add(_entry('same', 2));

      final page = await history.loadPage(offset: 0, limit: 10);
      expect(page.entries, hasLength(1));
      expect(page.entries.single.receivedAt, DateTime.utc(2026, 1, 1, 0, 1));
      expect(changes, 1);
      await subscription.cancel();
    });

    test('survives closing and reopening a file database', () async {
      final temporary = await Directory.systemTemp.createTemp(
        'notify-history-',
      );
      final file = File('${temporary.path}/history.sqlite');
      final first = SqliteNotificationHistory(NativeDatabase(file));
      await first.add(_entry('persisted', 1));
      await first.close();

      final second = SqliteNotificationHistory(NativeDatabase(file));
      final page = await second.loadPage(offset: 0, limit: 10);
      expect(page.entries.single.eventId, 'persisted');
      expect(await second.contains('persisted'), isTrue);
      await second.close();
      await temporary.delete(recursive: true);
    });

    test('serializes concurrent writes from two WAL connections', () async {
      await history.close();
      final temporary = await Directory.systemTemp.createTemp(
        'notify-history-',
      );
      final file = File('${temporary.path}/history.sqlite');
      final first = SqliteNotificationHistory(
        NativeDatabase.createInBackground(
          file,
          setup: configureNotificationHistoryDatabase,
        ),
      );
      await first.loadPage(offset: 0, limit: 1);
      final second = SqliteNotificationHistory(
        NativeDatabase.createInBackground(
          file,
          setup: configureNotificationHistoryDatabase,
        ),
      );
      await second.loadPage(offset: 0, limit: 1);

      for (var index = 0; index < 20; index += 2) {
        await Future.wait([
          first.add(_entry('concurrent-$index', index)),
          second.add(_entry('concurrent-${index + 1}', index + 1)),
        ]);
      }

      final page = await first.loadPage(offset: 0, limit: 100);
      expect(page.totalCount, 20);
      expect(page.entries.map((entry) => entry.eventId).toSet(), hasLength(20));
      await first.close();
      await second.close();
      await temporary.delete(recursive: true);
    });

    test('rejects a non-positive capacity', () {
      final executor = NativeDatabase.memory();
      expect(
        () => SqliteNotificationHistory(executor, capacity: 0),
        throwsArgumentError,
      );
      executor.close();
    });
  });
}
