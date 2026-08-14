import 'dart:async';
import 'dart:convert';

import 'package:client/fcm/fcm_background.dart';
import 'package:client/history/notification_history.dart';
import 'package:client/realtime/notify_event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, Object?> baseEnvelope(String type) => {
  'eventId': 'evt-$type',
  'type': type,
  'occurredAt': '2026-01-01T00:00:00.000Z',
  'source': {
    'machine': 'devbox',
    'project': 'api',
    'directory': '/work/api',
  },
  'session': {'id': 'ses_1', 'title': 'Implement API'},
};

Map<String, Object?> terminalEnvelope({String eventId = 'evt-terminal'}) => {
  ...baseEnvelope('terminal'),
  'eventId': eventId,
  'payload': {'outcome': 'completed', 'elapsedSeconds': 42},
};

Map<String, Object?> actionRequiredEnvelope({
  String eventId = 'evt-action_required',
}) => {
  ...baseEnvelope('action_required'),
  'eventId': eventId,
  'payload': {
    'requestId': 'per_1',
    'kind': 'permission',
    'permission': {'permission': 'bash', 'summary': 'Run rm -rf build/'},
  },
};

Map<String, Object?> heartbeatEnvelope() => {
  ...baseEnvelope('heartbeat'),
  'payload': {'status': 'busy', 'elapsedSeconds': 60},
};

Map<String, Object?> actionResolvedEnvelope() => {
  ...baseEnvelope('action_resolved'),
  'payload': {'requestId': 'req_1', 'kind': 'question'},
};

Map<String, dynamic> dataOf(Map<String, Object?> envelope) => {
  'event': jsonEncode(envelope),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('parseFcmEventData', () {
    test('maps a valid data["event"] JSON string to a NotifyEvent', () {
      final event = parseFcmEventData(dataOf(terminalEnvelope()));

      expect(event, isNotNull);
      expect(event!.eventId, 'evt-terminal');
      expect(event.type, NotifyEventType.terminal);
      expect(event.outcome, TerminalOutcome.completed);
      expect(event.machine, 'devbox');
    });

    test('returns null when the event key is missing', () {
      expect(parseFcmEventData(const {}), isNull);
    });

    test('returns null when the event value is not a string', () {
      expect(parseFcmEventData({'event': 42}), isNull);
    });

    test('returns null for invalid JSON', () {
      expect(parseFcmEventData(const {'event': '{nope'}), isNull);
    });

    test('returns null for a non-object JSON payload', () {
      expect(parseFcmEventData(const {'event': '[1,2]'}), isNull);
    });

    test('returns null for a malformed envelope', () {
      final malformed = terminalEnvelope()..remove('eventId');
      expect(parseFcmEventData(dataOf(malformed)), isNull);
    });
  });

  group('processBackgroundMessageData', () {
    late PrefsNotificationHistory history;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      history = await PrefsNotificationHistory.load();
    });

    test('records an action_required event with rendered title/body', () async {
      await processBackgroundMessageData(
        dataOf(actionRequiredEnvelope()),
        history,
        now: () => DateTime.utc(2026, 1, 2),
      );

      expect(history.entries, hasLength(1));
      final entry = history.entries.single;
      expect(entry.eventId, 'evt-action_required');
      expect(entry.title, 'api · devbox · 需要授权');
      expect(entry.body, '请求权限：bash\nRun rm -rf build/');
      expect(entry.receivedAt, DateTime.utc(2026, 1, 2));
    });

    test('records a terminal event', () async {
      await processBackgroundMessageData(
        dataOf(terminalEnvelope()),
        history,
        now: () => DateTime.utc(2026, 1, 2),
      );

      expect(history.entries, hasLength(1));
      expect(history.entries.single.title, 'api · devbox · 任务已完成');
      expect(history.entries.single.body, '用时 42 秒');
    });

    test('skips heartbeat events entirely', () async {
      await processBackgroundMessageData(dataOf(heartbeatEnvelope()), history);

      expect(history.entries, isEmpty);
    });

    test('skips action_resolved events entirely', () async {
      await processBackgroundMessageData(
        dataOf(actionResolvedEnvelope()),
        history,
      );

      expect(history.entries, isEmpty);
    });

    test('ignores malformed payloads without touching history', () async {
      await processBackgroundMessageData(const {'event': '{broken'}, history);
      await processBackgroundMessageData(const {}, history);

      expect(history.entries, isEmpty);
    });

    test('dedupes against history: an already-recorded event is skipped',
        () async {
      await processBackgroundMessageData(
        dataOf(actionRequiredEnvelope()),
        history,
      );
      await processBackgroundMessageData(
        dataOf(actionRequiredEnvelope()),
        history,
      );

      expect(history.entries, hasLength(1));
    });

    test('dedupe is per event ID: distinct events are both recorded',
        () async {
      await processBackgroundMessageData(
        dataOf(actionRequiredEnvelope()),
        history,
      );
      await processBackgroundMessageData(
        dataOf(terminalEnvelope()),
        history,
      );

      expect(history.entries.map((e) => e.eventId), [
        'evt-terminal',
        'evt-action_required',
      ]);
    });

    test('dedupe survives reloads (history is persisted)', () async {
      await processBackgroundMessageData(
        dataOf(actionRequiredEnvelope()),
        history,
      );

      // Simulate a fresh background isolate reading the persisted history.
      final reloaded = await PrefsNotificationHistory.load();
      await processBackgroundMessageData(
        dataOf(actionRequiredEnvelope()),
        reloaded,
      );

      expect(reloaded.entries, hasLength(1));
    });

    test('concurrent calls for the same event record exactly one entry',
        () async {
      await Future.wait([
        processBackgroundMessageData(dataOf(actionRequiredEnvelope()), history),
        processBackgroundMessageData(dataOf(actionRequiredEnvelope()), history),
      ]);

      expect(history.entries, hasLength(1));
    });

    test('concurrent calls for distinct events both record, serialized',
        () async {
      await Future.wait([
        processBackgroundMessageData(dataOf(actionRequiredEnvelope()), history),
        processBackgroundMessageData(dataOf(terminalEnvelope()), history),
      ]);

      expect(history.entries.map((e) => e.eventId), [
        'evt-terminal',
        'evt-action_required',
      ]);
    });
  });

  group('ActionQueue', () {
    test('runs actions one at a time, in call order', () async {
      final queue = ActionQueue();
      final started = <String>[];
      final gate = Completer<void>();

      final first = queue.run(() async {
        started.add('first');
        await gate.future;
        return 1;
      });
      final second = queue.run(() async {
        started.add('second');
        return 2;
      });

      await pumpEventQueue();
      // The second action must not start while the first is still pending.
      expect(started, ['first']);

      gate.complete();
      final results = await Future.wait([first, second]);
      expect(results, [1, 2]);
      expect(started, ['first', 'second']);
    });

    test('a failing action does not jam the queue', () async {
      final queue = ActionQueue();

      await expectLater(
        queue.run<int>(() async => throw StateError('boom')),
        throwsStateError,
      );
      expect(await queue.run(() async => 42), 42);
    });
  });
}
