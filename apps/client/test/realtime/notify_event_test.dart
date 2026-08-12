import 'dart:convert';

import 'package:client/realtime/notify_event.dart';
import 'package:flutter_test/flutter_test.dart';

/// Spec §7.1 terminal example: the canonical event envelope carried by
/// POST /v1/events, WsServerMessage frames, and FCM `data['event']`.
const eventId = '3b8f9c2e-1a4d-4e5f-9a6b-7c8d9e0f1a2b';

Map<String, Object?> baseEnvelope() => {
      'eventId': eventId,
      'type': 'terminal',
      'occurredAt': '2026-01-01T00:00:00.000Z',
      'source': {
        'machine': 'devbox',
        'project': 'api',
        'directory': '/work/api',
      },
      'session': {'id': 'ses_1', 'title': 'Implement API'},
    };

Map<String, Object?> heartbeatEvent() => {
      ...baseEnvelope(),
      'type': 'heartbeat',
      'payload': {'status': 'busy', 'elapsedSeconds': 60},
    };

Map<String, Object?> questionEvent(List<Map<String, Object?>> questions) => {
      ...baseEnvelope(),
      'type': 'action_required',
      'payload': {
        'requestId': 'req_1',
        'kind': 'question',
        'questions': questions,
      },
    };

Map<String, Object?> permissionEvent() => {
      ...baseEnvelope(),
      'type': 'action_required',
      'payload': {
        'requestId': 'per_1',
        'kind': 'permission',
        'permission': {'permission': 'bash', 'summary': 'Run rm -rf build/'},
      },
    };

Map<String, Object?> providerActionEvent() => {
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
          'link': 'https://provider.example/reconnect',
        },
      },
    };

Map<String, Object?> resolvedEvent(String kind) => {
      ...baseEnvelope(),
      'type': 'action_resolved',
      'payload': {'requestId': 'req_1', 'kind': kind},
    };

Map<String, Object?> terminalEvent({
  String outcome = 'completed',
  int elapsedSeconds = 42,
  String? summary,
}) => {
      ...baseEnvelope(),
      'type': 'terminal',
      'payload': {
        'outcome': outcome,
        'elapsedSeconds': elapsedSeconds,
        'summary': ?summary,
      },
    };

void main() {
  group('NotifyEvent.parse variants', () {
    test('parses the spec §7.1 terminal example', () {
      final event = NotifyEvent.parse(terminalEvent());

      expect(event.eventId, eventId);
      expect(event.type, NotifyEventType.terminal);
      expect(
        event.occurredAt,
        DateTime.parse('2026-01-01T00:00:00.000Z'),
      );
      expect(event.machine, 'devbox');
      expect(event.project, 'api');
      expect(event.directory, '/work/api');
      expect(event.sessionId, 'ses_1');
      expect(event.sessionTitle, 'Implement API');
      expect(event.outcome, TerminalOutcome.completed);
      expect(event.elapsedSeconds, 42);
      expect(event.summary, isNull);
      expect(event.requestId, isNull);
      expect(event.actionKind, isNull);
    });

    test('parses a heartbeat event', () {
      final event = NotifyEvent.parse(heartbeatEvent());

      expect(event.type, NotifyEventType.heartbeat);
      expect(event.elapsedSeconds, 60);
      expect(event.requestId, isNull);
      expect(event.actionKind, isNull);
      expect(event.questions, isEmpty);
      expect(event.outcome, isNull);
    });

    test('parses an action_required question event with all prompts', () {
      final event = NotifyEvent.parse(
        questionEvent([
          {
            'question': 'Which database should I use?',
            'options': [
              {'label': 'Postgres', 'description': 'Relational'},
              {'label': 'SQLite'},
            ],
            'multiple': false,
          },
          {
            'question': 'Proceed with the migration?',
            'options': [
              {'label': 'Yes'},
              {'label': 'No'},
            ],
          },
        ]),
      );

      expect(event.type, NotifyEventType.actionRequired);
      expect(event.actionKind, ActionKind.question);
      expect(event.requestId, 'req_1');
      expect(event.questions, hasLength(2));

      final first = event.questions[0];
      expect(first.text, 'Which database should I use?');
      expect(first.multiple, isFalse);
      expect(first.options, hasLength(2));
      expect(first.options[0].label, 'Postgres');
      expect(first.options[0].description, 'Relational');
      expect(first.options[1].label, 'SQLite');
      expect(first.options[1].description, isNull);

      final second = event.questions[1];
      expect(second.text, 'Proceed with the migration?');
      expect(second.options.map((o) => o.label), ['Yes', 'No']);
    });

    test('parses an action_required permission event', () {
      final event = NotifyEvent.parse(permissionEvent());

      expect(event.type, NotifyEventType.actionRequired);
      expect(event.actionKind, ActionKind.permission);
      expect(event.requestId, 'per_1');
      expect(event.permissionType, 'bash');
      expect(event.questions, isEmpty);
    });

    test('parses an action_required provider_action event', () {
      final event = NotifyEvent.parse(providerActionEvent());

      expect(event.type, NotifyEventType.actionRequired);
      expect(event.actionKind, ActionKind.providerAction);
      expect(event.requestId, 'pro_1');
    });

    test('parses an action_resolved question event', () {
      final event = NotifyEvent.parse(resolvedEvent('question'));

      expect(event.type, NotifyEventType.actionResolved);
      expect(event.actionKind, ActionKind.question);
      expect(event.requestId, 'req_1');
    });

    test('parses an action_resolved permission event', () {
      final event = NotifyEvent.parse(resolvedEvent('permission'));

      expect(event.type, NotifyEventType.actionResolved);
      expect(event.actionKind, ActionKind.permission);
      expect(event.requestId, 'req_1');
    });

    test('parses all three terminal outcomes', () {
      final expected = {
        'completed': TerminalOutcome.completed,
        'failed': TerminalOutcome.failed,
        'stopped': TerminalOutcome.stopped,
      };
      for (final entry in expected.entries) {
        final event = NotifyEvent.parse(terminalEvent(outcome: entry.key));
        expect(event.type, NotifyEventType.terminal);
        expect(event.outcome, entry.value, reason: entry.key);
      }
    });

    test('parses the optional terminal summary when present', () {
      final event = NotifyEvent.parse(
        terminalEvent(outcome: 'failed', summary: 'Tests failed: 3'),
      );

      expect(event.outcome, TerminalOutcome.failed);
      expect(event.summary, 'Tests failed: 3');
    });
  });

  group('NotifyEvent.parse transport forms', () {
    test('parses a JSON-decoded FCM data["event"] payload', () {
      // FCM data values are strings: the client receives the serialized
      // envelope and must jsonDecode it before parsing.
      final dataEvent = jsonEncode(
        terminalEvent(outcome: 'stopped', summary: 'Stopped by user'),
      );
      final decoded = jsonDecode(dataEvent) as Map<String, Object?>;

      final event = NotifyEvent.parse(decoded);

      expect(event.eventId, eventId);
      expect(event.type, NotifyEventType.terminal);
      expect(event.outcome, TerminalOutcome.stopped);
      expect(event.summary, 'Stopped by user');
    });
  });

  group('NotifyEvent.parse malformed input', () {
    test('throws FormatException when eventId is missing', () {
      final json = terminalEvent()..remove('eventId');
      expect(() => NotifyEvent.parse(json), throwsFormatException);
    });

    test('throws FormatException for an unknown event type', () {
      final json = terminalEvent()..['type'] = 'question';
      expect(() => NotifyEvent.parse(json), throwsFormatException);
    });

    test('throws FormatException on discriminator/payload mismatch', () {
      final json = terminalEvent()
        ..['payload'] = {'status': 'busy', 'elapsedSeconds': 60};
      expect(() => NotifyEvent.parse(json), throwsFormatException);
    });

    test('throws FormatException when a field has the wrong type', () {
      final json = terminalEvent()
        ..['payload'] = {'outcome': 'completed', 'elapsedSeconds': '42'};
      expect(() => NotifyEvent.parse(json), throwsFormatException);
    });

    test('throws FormatException when source is missing', () {
      final json = terminalEvent()..remove('source');
      expect(() => NotifyEvent.parse(json), throwsFormatException);
    });
  });
}
