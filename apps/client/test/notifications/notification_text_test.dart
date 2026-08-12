import 'package:client/notifications/notification_text.dart';
import 'package:client/realtime/notify_event.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> baseEnvelope() => {
      'eventId': '3b8f9c2e-1a4d-4e5f-9a6b-7c8d9e0f1a2b',
      'occurredAt': '2026-01-01T00:00:00.000Z',
      'source': {
        'machine': 'devbox',
        'project': 'api',
        'directory': '/work/api',
      },
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
    test('contains machine, project, and type for every event variant', () {
      final cases = {
        heartbeat(): 'heartbeat',
        question([
          {'question': 'Continue?'},
        ]): 'action_required',
        resolved(): 'action_resolved',
        terminal(): 'terminal',
      };
      for (final entry in cases.entries) {
        final title = buildNotificationTitle(entry.key);
        expect(title, contains('devbox'));
        expect(title, contains('api'));
        expect(title, contains(entry.value));
      }
    });

    test('is exactly "machine · project · type"', () {
      expect(
        buildNotificationTitle(terminal()),
        'devbox · api · terminal',
      );
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
        'Options: Postgres, SQLite',
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

      expect(body.split('\n').last, '…and 2 more questions');
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

      expect(body.split('\n').last, '…and 1 more question');
    });

    test('omits the remaining-count line at exactly three questions', () {
      final body = buildNotificationBody(
        question([
          {'question': 'Q1'},
          {'question': 'Q2'},
          {'question': 'Q3'},
        ]),
      );

      expect(body, isNot(contains('more question')));
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
    test('contains the permission type', () {
      expect(buildNotificationBody(permission()), contains('bash'));
    });
  });

  group('buildNotificationBody provider_action', () {
    test('is empty (provider detail stays in the app)', () {
      expect(buildNotificationBody(providerAction()), isEmpty);
    });
  });

  group('buildNotificationBody terminal', () {
    test('contains outcome and elapsed duration for every outcome', () {
      for (final outcome in ['completed', 'failed', 'stopped']) {
        final body = buildNotificationBody(terminal(outcome: outcome));
        expect(body, contains(outcome), reason: outcome);
        expect(body, contains('42'), reason: outcome);
      }
    });

    test('includes the summary when present', () {
      final body = buildNotificationBody(
        terminal(summary: 'All tests passed'),
      );

      expect(body, contains('All tests passed'));
    });

    test('omits the summary when absent', () {
      expect(buildNotificationBody(terminal()), 'completed in 42s');
    });
  });

  group('buildNotificationBody heartbeat and action_resolved', () {
    test('is empty (never shown as notifications per spec)', () {
      expect(buildNotificationBody(heartbeat()), isEmpty);
      expect(buildNotificationBody(resolved()), isEmpty);
    });
  });
}
