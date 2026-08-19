import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'notification_history.dart';
import 'history_schema.dart';

part 'sqlite_notification_history.g.dart';

void configureNotificationHistoryDatabase(sqlite.Database database) {
  database.execute('PRAGMA busy_timeout = 5000');
  database.execute('PRAGMA journal_mode = WAL');
}

@DataClassName('StoredHistoryEntry')
@TableIndex(name: 'history_received_at_idx', columns: {#receivedAtMicros})
class HistoryRecords extends Table {
  TextColumn get eventId => text()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  IntColumn get receivedAtMicros => integer()();
  IntColumn get occurredAtMicros => integer().nullable()();
  TextColumn get status => text().nullable()();
  TextColumn get eventType => text().nullable()();
  TextColumn get machine => text().nullable()();
  TextColumn get project => text().nullable()();
  TextColumn get directory => text().nullable()();
  TextColumn get directoryName => text().nullable()();
  TextColumn get sessionId => text().nullable()();
  TextColumn get sessionTitle => text().nullable()();
  TextColumn get requestId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {eventId};
}

@DriftDatabase(tables: [HistoryRecords])
class SqliteNotificationHistory extends _$SqliteNotificationHistory
    implements NotificationHistory {
  SqliteNotificationHistory(
    super.executor, {
    this.capacity = notificationHistoryCapacity,
  }) {
    if (capacity <= 0) {
      throw ArgumentError.value(capacity, 'capacity', 'must be positive');
    }
  }

  factory SqliteNotificationHistory.openDefault() =>
      SqliteNotificationHistory(_openDefaultConnection());

  final int capacity;
  final StreamController<void> _changes = StreamController.broadcast(
    sync: true,
  );

  @override
  int get schemaVersion => 1;

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<bool> contains(String eventId) async {
    final query = select(historyRecords)
      ..where((row) => row.eventId.equals(eventId))
      ..limit(1);
    return (await query.getSingleOrNull()) != null;
  }

  @override
  Future<void> add(HistoryEntry entry) async {
    bool retained;
    var attempt = 0;
    while (true) {
      try {
        retained = await _insertAndPrune(entry);
        break;
      } on sqlite.SqliteException catch (error) {
        final retryable = error.resultCode == 5 || error.resultCode == 6;
        if (!retryable || attempt >= 6) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 25 * (1 << attempt)));
        attempt += 1;
      }
    }
    if (retained) {
      _changes.add(null);
    }
  }

  Future<bool> _insertAndPrune(HistoryEntry entry) => transaction(() async {
    await into(
      historyRecords,
    ).insert(_toCompanion(entry), mode: InsertMode.insertOrIgnore);
    final changed = await customSelect(
      'SELECT changes() AS changed',
      readsFrom: {historyRecords},
    ).getSingle();
    if (changed.read<int>('changed') == 0) {
      return false;
    }
    await customStatement(
      'DELETE FROM history_records WHERE event_id IN ('
      'SELECT event_id FROM history_records '
      'ORDER BY received_at_micros DESC, event_id DESC LIMIT -1 OFFSET ?'
      ')',
      [capacity],
    );
    final retained = await customSelect(
      'SELECT 1 AS retained FROM history_records WHERE event_id = ?',
      variables: [Variable.withString(entry.eventId)],
      readsFrom: {historyRecords},
    ).getSingleOrNull();
    return retained != null;
  });

  @override
  Future<HistoryBatch> loadPage({
    required int offset,
    required int limit,
  }) async {
    if (offset < 0 || limit <= 0) {
      throw ArgumentError('offset must be non-negative and limit positive');
    }
    final countExpression = historyRecords.eventId.count();
    final countQuery = selectOnly(historyRecords)
      ..addColumns([countExpression]);
    final totalCount =
        (await countQuery.getSingle()).read(countExpression) ?? 0;
    final query = select(historyRecords)
      ..orderBy([
        (row) => OrderingTerm.desc(row.receivedAtMicros),
        (row) => OrderingTerm.desc(row.eventId),
      ])
      ..limit(limit, offset: offset);
    final rows = await query.get();
    return HistoryBatch(
      entries: List.unmodifiable(rows.map(_fromStored)),
      totalCount: totalCount,
    );
  }

  @override
  Future<void> close() async {
    await _changes.close();
    await super.close();
  }
}

HistoryRecordsCompanion _toCompanion(HistoryEntry entry) =>
    HistoryRecordsCompanion.insert(
      eventId: entry.eventId,
      title: entry.title,
      body: entry.body,
      receivedAtMicros: entry.receivedAt.toUtc().microsecondsSinceEpoch,
      occurredAtMicros: Value(entry.occurredAt?.toUtc().microsecondsSinceEpoch),
      status: Value(entry.status),
      eventType: Value(entry.eventType),
      machine: Value(entry.machine),
      project: Value(entry.project),
      directory: Value(entry.directory),
      directoryName: Value(entry.directoryName),
      sessionId: Value(entry.sessionId),
      sessionTitle: Value(entry.sessionTitle),
      requestId: Value(entry.requestId),
    );

HistoryEntry _fromStored(StoredHistoryEntry entry) => HistoryEntry(
  eventId: entry.eventId,
  title: entry.title,
  body: entry.body,
  receivedAt: DateTime.fromMicrosecondsSinceEpoch(
    entry.receivedAtMicros,
    isUtc: true,
  ),
  occurredAt: entry.occurredAtMicros == null
      ? null
      : DateTime.fromMicrosecondsSinceEpoch(
          entry.occurredAtMicros!,
          isUtc: true,
        ),
  status: entry.status,
  eventType: entry.eventType,
  machine: entry.machine,
  project: entry.project,
  directory: entry.directory,
  directoryName: entry.directoryName,
  sessionId: entry.sessionId,
  sessionTitle: entry.sessionTitle,
  requestId: entry.requestId,
);

QueryExecutor _openDefaultConnection() => LazyDatabase(() async {
  final support = await getApplicationSupportDirectory();
  final temporary = await getTemporaryDirectory();
  final file = File(p.join(support.path, notificationHistoryDatabaseFileName));
  return NativeDatabase.createInBackground(
    file,
    setup: (database) {
      sqlite.sqlite3.tempDirectory = temporary.path;
      configureNotificationHistoryDatabase(database);
    },
  );
});
