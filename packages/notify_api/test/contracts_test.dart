import 'dart:convert';

import 'package:notify_api/notify_api.dart';
import 'package:test/test.dart';

/// Spec §7.1 terminal example: the canonical event envelope carried by
/// POST /v1/events and by WsServerMessage frames.
const eventId = '3b8f9c2e-1a4d-4e5f-9a6b-7c8d9e0f1a2b';

Map<String, Object?> terminalEvent() => {
      'eventId': eventId,
      'type': 'terminal',
      'occurredAt': '2026-01-01T00:00:00.000Z',
      'source': {
        'machine': 'devbox',
        'project': 'api',
        'directory': '/work/api',
      },
      'session': {'id': 'ses_1', 'title': 'Implement API'},
      'payload': {'outcome': 'completed', 'elapsedSeconds': 42},
    };

Map<String, Object?> actionRequiredEvent(Map<String, Object?> payload) => {
      ...terminalEvent()
        ..remove('payload'),
      'type': 'action_required',
      'payload': payload,
    };

/// Deserializes [json] as a NotifyEvent, asserts the payload variant type,
/// and proves the event re-serializes to byte-identical JSON.
T roundTripActionRequired<T>(Map<String, Object?> json) {
  final event =
      standardSerializers.deserializeWith(NotifyEvent.serializer, json)!;
  final required = event.oneOf.value as NotifyEventOneOf1;
  expect(required.type, NotifyEventOneOf1TypeEnum.actionRequired);
  final payload = required.payload.oneOf.value;
  expect(payload, isA<T>());

  final out = standardSerializers.serializeWith(NotifyEvent.serializer, event);
  expect(jsonDecode(jsonEncode(out)), json);
  return payload as T;
}

void main() {
  group('NotifyEvent discriminated variants', () {
    test('round-trips the spec §7.1 terminal example', () {
      final json = terminalEvent();
      final event =
          standardSerializers.deserializeWith(NotifyEvent.serializer, json)!;

      final terminal = event.oneOf.value as NotifyEventOneOf3;
      expect(terminal.eventId, eventId);
      expect(terminal.type, NotifyEventOneOf3TypeEnum.terminal);
      expect(terminal.source_.machine, 'devbox');
      expect(terminal.session.id, 'ses_1');
      expect(terminal.payload.outcome,
          NotifyEventOneOf3PayloadOutcomeEnum.completed);
      expect(terminal.payload.elapsedSeconds, 42);

      final out =
          standardSerializers.serializeWith(NotifyEvent.serializer, event);
      expect(jsonDecode(jsonEncode(out)), json);
    });

    test('deserializes each variant by its type discriminator', () {
      final envelope = terminalEvent()..remove('type')..remove('payload');

      final heartbeat = standardSerializers.deserializeWith(
        NotifyEvent.serializer,
        {
          ...envelope,
          'type': 'heartbeat',
          'payload': {'status': 'busy', 'elapsedSeconds': 60},
        },
      )!;
      expect(heartbeat.oneOf.value, isA<NotifyEventOneOf>());

      final actionRequired = standardSerializers.deserializeWith(
        NotifyEvent.serializer,
        {
          ...envelope,
          'type': 'action_required',
          'payload': {
            'requestId': 'req_1',
            'kind': 'question',
            'questions': [
              {
                'question': 'Which database should I use?',
                'options': [
                  {'label': 'Postgres', 'description': 'Relational'},
                  {'label': 'SQLite'},
                ],
                'multiple': false,
              },
            ],
          },
        },
      )!;
      expect(actionRequired.oneOf.value, isA<NotifyEventOneOf1>());

      final actionResolved = standardSerializers.deserializeWith(
        NotifyEvent.serializer,
        {
          ...envelope,
          'type': 'action_resolved',
          'payload': {'requestId': 'req_1', 'kind': 'question'},
        },
      )!;
      expect(actionResolved.oneOf.value, isA<NotifyEventOneOf2>());

      final terminal = standardSerializers.deserializeWith(
        NotifyEvent.serializer,
        terminalEvent(),
      )!;
      expect(terminal.oneOf.value, isA<NotifyEventOneOf3>());
    });

    test('rejects a heartbeat discriminator carrying a terminal payload', () {
      final bad = terminalEvent()..['type'] = 'heartbeat';
      expect(
        () => standardSerializers.deserializeWith(NotifyEvent.serializer, bad),
        throwsA(anything),
      );
    });

    test('rejects a terminal discriminator carrying a heartbeat payload', () {
      final bad = terminalEvent()
        ..['payload'] = {'status': 'busy', 'elapsedSeconds': 60};
      expect(
        () => standardSerializers.deserializeWith(NotifyEvent.serializer, bad),
        throwsA(anything),
      );
    });

    test('rejects an unknown event type', () {
      final bad = terminalEvent()..['type'] = 'question';
      expect(
        () => standardSerializers.deserializeWith(NotifyEvent.serializer, bad),
        throwsA(anything),
      );
    });
  });

  group('action_required payload kinds', () {
    test('question payload round-trips', () {
      final payload =
          roundTripActionRequired<NotifyEventOneOf1PayloadOneOf>(
        actionRequiredEvent({
          'requestId': 'req_1',
          'kind': 'question',
          'questions': [
            {
              'question': 'Which database should I use?',
              'options': [
                {'label': 'Postgres', 'description': 'Relational'},
                {'label': 'SQLite'},
              ],
              'multiple': false,
            },
          ],
        }),
      );

      expect(payload.requestId, 'req_1');
      expect(payload.kind, NotifyEventOneOf1PayloadOneOfKindEnum.question);
      expect(payload.questions, hasLength(1));
      expect(payload.questions.first.question,
          'Which database should I use?');
      expect(payload.questions.first.options, hasLength(2));
      expect(payload.questions.first.options!.first.label, 'Postgres');
      expect(payload.questions.first.multiple, isFalse);
    });

    test('permission payload round-trips', () {
      final payload =
          roundTripActionRequired<NotifyEventOneOf1PayloadOneOf1>(
        actionRequiredEvent({
          'requestId': 'per_1',
          'kind': 'permission',
          'permission': {
            'permission': 'bash',
            'summary': 'Run rm -rf build/',
          },
        }),
      );

      expect(payload.requestId, 'per_1');
      expect(payload.kind,
          NotifyEventOneOf1PayloadOneOf1KindEnum.permission);
      expect(payload.permission.permission, 'bash');
      expect(payload.permission.summary, 'Run rm -rf build/');
    });

    test('provider_action payload round-trips', () {
      final payload =
          roundTripActionRequired<NotifyEventOneOf1PayloadOneOf2>(
        actionRequiredEvent({
          'requestId': 'pro_1',
          'kind': 'provider_action',
          'providerAction': {
            'provider': 'anthropic',
            'title': 'Sign-in required',
            'message': 'Your Anthropic session has expired.',
            'label': 'Reconnect',
            'link': 'https://provider.example/reconnect',
          },
        }),
      );

      expect(payload.requestId, 'pro_1');
      expect(payload.kind,
          NotifyEventOneOf1PayloadOneOf2KindEnum.providerAction);
      expect(payload.providerAction.provider, 'anthropic');
      expect(payload.providerAction.title, 'Sign-in required');
      expect(payload.providerAction.message,
          'Your Anthropic session has expired.');
      expect(payload.providerAction.label, 'Reconnect');
      expect(payload.providerAction.link,
          'https://provider.example/reconnect');
    });
  });

  group('WsServerMessage wrapper', () {
    test('round-trips the terminal event frame', () {
      final frame = {'type': 'event', 'event': terminalEvent()};
      final message = standardSerializers.deserializeWith(
        WsServerMessage.serializer,
        frame,
      )!;

      expect(message.type, WsServerMessageTypeEnum.event);
      final terminal = message.event.oneOf.value as NotifyEventOneOf3;
      expect(terminal.eventId, eventId);
      expect(terminal.payload.outcome,
          NotifyEventOneOf3PayloadOutcomeEnum.completed);

      final out = standardSerializers.serializeWith(
        WsServerMessage.serializer,
        message,
      );
      expect(jsonDecode(jsonEncode(out)), frame);
    });
  });
}
