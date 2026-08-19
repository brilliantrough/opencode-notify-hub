import 'dart:convert';
import 'dart:io';

import 'package:client/history/history_schema.dart';
import 'package:client/history/notification_history.dart';
import 'package:sqlite3/sqlite3.dart';

const _legacyKeys = [
  'flutter.notification_history_v1',
  'notification_history_v1',
];

Future<void> main(List<String> arguments) async {
  if (arguments.contains('--help') || arguments.contains('-h')) {
    _usage();
    return;
  }
  final inputPath = _option(arguments, '--input');
  final databasePath = _option(arguments, '--database');
  if (inputPath == null || databasePath == null) {
    _usage();
    exitCode = 64;
    return;
  }

  try {
    final source = File(inputPath);
    final entries = _decodeEntries(await source.readAsString());
    final destination = File(databasePath);
    await destination.parent.create(recursive: true);
    final database = sqlite3.open(destination.path);
    try {
      final imported = _import(database, entries);
      final total =
          database
                  .select('SELECT COUNT(*) AS total FROM history_records')
                  .single['total']
              as int;
      stdout.writeln(
        'Imported $imported new entries; database contains $total entries.',
      );
      stdout.writeln('Source JSON was left unchanged: ${source.absolute.path}');
    } finally {
      database.close();
    }
  } on Object catch (error) {
    stderr.writeln('History import failed: $error');
    exitCode = 1;
  }
}

String? _option(List<String> arguments, String name) {
  final index = arguments.indexOf(name);
  if (index < 0 || index + 1 >= arguments.length) return null;
  return arguments[index + 1];
}

List<HistoryEntry> _decodeEntries(String source) {
  Object? decoded = jsonDecode(source);
  if (decoded is Map<String, dynamic>) {
    Object? value;
    for (final key in _legacyKeys) {
      if (decoded.containsKey(key)) {
        value = decoded[key];
        break;
      }
    }
    if (value == null) {
      throw const FormatException('notification_history_v1 key not found');
    }
    decoded = value is String ? jsonDecode(value) : value;
  } else if (decoded is String) {
    decoded = jsonDecode(decoded);
  }
  if (decoded is! List) {
    throw const FormatException('history must be a JSON list');
  }
  return [
    for (final item in decoded)
      if (item is Map<String, dynamic>) HistoryEntry.fromJson(item),
  ];
}

int _import(Database database, List<HistoryEntry> entries) {
  database.execute('PRAGMA busy_timeout = 5000');
  database.execute('PRAGMA journal_mode = WAL');
  database.execute('''
    CREATE TABLE IF NOT EXISTS history_records (
      event_id TEXT NOT NULL PRIMARY KEY,
      title TEXT NOT NULL,
      body TEXT NOT NULL,
      received_at_micros INTEGER NOT NULL,
      occurred_at_micros INTEGER,
      status TEXT,
      event_type TEXT,
      machine TEXT,
      project TEXT,
      directory TEXT,
      directory_name TEXT,
      session_id TEXT,
      session_title TEXT,
      request_id TEXT
    )
  ''');
  database.execute('''
    CREATE INDEX IF NOT EXISTS history_received_at_idx
    ON history_records (received_at_micros)
  ''');
  database.execute('PRAGMA user_version = 1');

  var imported = 0;
  database.execute('BEGIN IMMEDIATE');
  final statement = database.prepare('''
    INSERT OR IGNORE INTO history_records (
      event_id, title, body, received_at_micros, occurred_at_micros,
      status, event_type, machine, project, directory, directory_name,
      session_id, session_title, request_id
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  ''');
  try {
    for (final entry in entries) {
      statement.execute([
        entry.eventId,
        entry.title,
        entry.body,
        entry.receivedAt.toUtc().microsecondsSinceEpoch,
        entry.occurredAt?.toUtc().microsecondsSinceEpoch,
        entry.status,
        entry.eventType,
        entry.machine,
        entry.project,
        entry.directory,
        entry.directoryName,
        entry.sessionId,
        entry.sessionTitle,
        entry.requestId,
      ]);
      imported +=
          database.select('SELECT changes() AS changed').single['changed']
              as int;
    }
    database.execute('''
      DELETE FROM history_records WHERE event_id IN (
        SELECT event_id FROM history_records
        ORDER BY received_at_micros DESC, event_id DESC
        LIMIT -1 OFFSET $notificationHistoryCapacity
      )
    ''');
    database.execute('COMMIT');
  } catch (_) {
    database.execute('ROLLBACK');
    rethrow;
  } finally {
    statement.close();
  }
  database.execute('PRAGMA wal_checkpoint(TRUNCATE)');
  return imported;
}

void _usage() {
  stdout.writeln('''
Import legacy notification-history JSON into the client SQLite database.

Close OpenCode Notify before running this command.

Usage:
  dart run tool/import_notification_history.dart \\
    --input <shared_preferences.json-or-history.json> \\
    --database <notification_history.sqlite>
''');
}
