import 'package:client/notifications/notification_text.dart';
import 'package:client/realtime/notify_event.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> baseEnvelope() => {
  'eventId': '3b8f9c2e-1a4d-4e5f-9a6b-7c8d9e0f1a2b',
  'occurredAt': '2026-01-01T00:00:00.000Z',
  'source': {'machine': 'devbox', 'project': 'api', 'directory': '/work/api'},
  'session': {'id': 'ses_1', 'title': 'Implement API'},
};

NotifyEvent heartbeat() => NotifyEvent.parse({
  ...baseEnvelope(),
  'type': 'heartbeat',
  'payload': {'status': 'busy', 'elapsedSeconds': 60},
});

NotifyEvent question(List<Map<String, Object?>> questions) =>
    NotifyEvent.parse({
      ...baseEnvelope(),
      'type': 'action_required',
      'payload': {
        'requestId': 'req_1',
        'kind': 'question',
        'questions': questions,
      },
    });

NotifyEvent permission() => NotifyEvent.parse({
  ...baseEnvelope(),
  'type': 'action_required',
  'payload': {
    'requestId': 'per_1',
    'kind': 'permission',
    'permission': {'permission': 'bash', 'summary': 'Run rm -rf build/'},
  },
});

NotifyEvent providerAction() => NotifyEvent.parse({
  ...baseEnvelope(),
  'type': 'action_required',
  'payload': {
    'requestId': 'pro_1',
    'kind': 'provider_action',
    'providerAction': {
      'provider': 'anthropic',
      'title': 'Sign-in required',
      'message': 'Your Anthropic session has expired.',
      'label': 'Reconnect',
    },
  },
});

NotifyEvent resolved() => NotifyEvent.parse({
  ...baseEnvelope(),
  'type': 'action_resolved',
  'payload': {'requestId': 'req_1', 'kind': 'question'},
});

NotifyEvent terminal({String outcome = 'completed', String? summary}) =>
    NotifyEvent.parse({
      ...baseEnvelope(),
      'type': 'terminal',
      'payload': {
        'outcome': outcome,
        'elapsedSeconds': 42,
        'summary': ?summary,
      },
    });

void main() {
  group('buildNotificationTitle', () {
    test(
      'uses machine, directory, session title, and status for every variant',
      () {
        final cases = {
          heartbeat(): '任务进行中',
          question([
            {'question': 'Continue?'},
          ]): '需要回答',
          resolved(): '操作已处理',
          terminal(): '任务已完成',
        };
        for (final entry in cases.entries) {
          final title = buildNotificationTitle(entry.key);
          expect(title, contains('devbox'));
          expect(title, contains('api'));
          expect(title, contains('Implement API'));
          expect(title, contains(entry.value));
        }
      },
    );

    test('is exactly "machine · directory · session · status"', () {
      expect(
        buildNotificationTitle(terminal()),
        'devbox · api · Implement API · 任务已完成',
      );
    });

    test('distinguishes action kinds and terminal outcomes', () {
      expect(
        buildNotificationTitle(permission()),
        'devbox · api · Implement API · 需要授权',
      );
      expect(
        buildNotificationTitle(providerAction()),
        'devbox · api · Implement API · 需要操作',
      );
      expect(
        buildNotificationTitle(terminal(outcome: 'failed')),
        'devbox · api · Implement API · 任务失败',
      );
      expect(
        buildNotificationTitle(terminal(outcome: 'stopped')),
        'devbox · api · Implement API · 任务已停止',
      );
    });
  });

  group('buildHistoryEntry', () {
    test('records rendered text and structured event context', () {
      final event = permission();
      final receivedAt = DateTime.utc(2026, 1, 2);

      final entry = buildHistoryEntry(event, receivedAt: receivedAt);

      expect(entry.title, 'devbox · api · Implement API · 需要授权');
      expect(entry.body, '请求权限：bash\nRun rm -rf build/');
      expect(entry.receivedAt, receivedAt);
      expect(entry.occurredAt, event.occurredAt);
      expect(entry.status, '需要授权');
      expect(entry.eventType, 'action_required');
      expect(entry.machine, 'devbox');
      expect(entry.project, 'api');
      expect(entry.directory, '/work/api');
      expect(entry.directoryName, 'api');
      expect(entry.sessionId, 'ses_1');
      expect(entry.sessionTitle, 'Implement API');
      expect(entry.requestId, 'per_1');
    });
  });

  group('buildNotificationBody question', () {
    test('shows question text and option labels', () {
      final body = buildNotificationBody(
        question([
          {
            'question': 'Which database should I use?',
            'options': [
              {'label': 'Postgres', 'description': 'Relational'},
              {'label': 'SQLite'},
            ],
          },
        ]),
      );

      expect(
        body,
        'Which database should I use?\n'
        '选项：Postgres、SQLite',
      );
    });

    test('shows up to the first three questions', () {
      final body = buildNotificationBody(
        question([
          {'question': 'Q1'},
          {'question': 'Q2'},
          {'question': 'Q3'},
          {'question': 'Q4'},
          {'question': 'Q5'},
        ]),
      );

      expect(body, contains('Q1'));
      expect(body, contains('Q2'));
      expect(body, contains('Q3'));
      expect(body, isNot(contains('Q4')));
      expect(body, isNot(contains('Q5')));
    });

    test('appends a remaining-count line when more than three exist', () {
      final body = buildNotificationBody(
        question([
          {'question': 'Q1'},
          {'question': 'Q2'},
          {'question': 'Q3'},
          {'question': 'Q4'},
          {'question': 'Q5'},
        ]),
      );

      expect(body.split('\n').last, '还有 2 个问题');
    });

    test('uses the singular form for one remaining question', () {
      final body = buildNotificationBody(
        question([
          {'question': 'Q1'},
          {'question': 'Q2'},
          {'question': 'Q3'},
          {'question': 'Q4'},
        ]),
      );

      expect(body.split('\n').last, '还有 1 个问题');
    });

    test('omits the remaining-count line at exactly three questions', () {
      final body = buildNotificationBody(
        question([
          {'question': 'Q1'},
          {'question': 'Q2'},
          {'question': 'Q3'},
        ]),
      );

      expect(body, isNot(contains('还有')));
    });

    test('omits the options line for a question without options', () {
      final body = buildNotificationBody(
        question([
          {'question': 'Free-form answer?'},
        ]),
      );

      expect(body, 'Free-form answer?');
    });
  });

  group('buildNotificationBody permission', () {
    test('shows the permission type and summary', () {
      expect(
        buildNotificationBody(permission()),
        '请求权限：bash\nRun rm -rf build/',
      );
    });
  });

  group('buildNotificationBody provider_action', () {
    test('shows the provider action message', () {
      expect(
        buildNotificationBody(providerAction()),
        'Your Anthropic session has expired.',
      );
    });
  });

  group('buildNotificationBody terminal', () {
    test('contains outcome and elapsed duration for every outcome', () {
      for (final outcome in ['completed', 'failed', 'stopped']) {
        final body = buildNotificationBody(terminal(outcome: outcome));
        expect(body, startsWith('用时 42 秒'), reason: outcome);
        expect(body, contains('42'), reason: outcome);
      }
    });

    test('includes the summary when present', () {
      final body = buildNotificationBody(terminal(summary: 'All tests passed'));

      expect(body, contains('All tests passed'));
    });

    test('omits the summary when absent', () {
      expect(buildNotificationBody(terminal()), '用时 42 秒');
    });
  });

  group('buildNotificationBody heartbeat and action_resolved', () {
    test('is empty (never shown as notifications per spec)', () {
      expect(buildNotificationBody(heartbeat()), isEmpty);
      expect(buildNotificationBody(resolved()), isEmpty);
    });
  });
}
