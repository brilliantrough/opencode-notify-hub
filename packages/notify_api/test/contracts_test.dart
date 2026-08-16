import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:notify_api/notify_api.dart';
import 'package:test/test.dart';

/// Spec §7.1 terminal example: the canonical event envelope carried by
/// POST /v1/events and by WsServerMessage frames.
const eventId = '3b8f9c2e-1a4d-4e5f-9a6b-7c8d9e0f1a2b';

Map<String, Object?> terminalEvent() => {
  'eventId': eventId,
  'type': 'terminal',
  'occurredAt': '2026-01-01T00:00:00.000Z',
  'source': {'machine': 'devbox', 'project': 'api', 'directory': '/work/api'},
  'session': {'id': 'ses_1', 'title': 'Implement API'},
  'payload': {'outcome': 'completed', 'elapsedSeconds': 42},
};

Map<String, Object?> actionRequiredEvent(Map<String, Object?> payload) => {
  ...terminalEvent()..remove('payload'),
  'type': 'action_required',
  'payload': payload,
};

/// Deserializes [json] as a NotifyEvent, asserts the payload variant type,
/// and proves the event re-serializes to byte-identical JSON.
T roundTripActionRequired<T>(Map<String, Object?> json) {
  final event = standardSerializers.deserializeWith(
    NotifyEvent.serializer,
    json,
  )!;
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
      final event = standardSerializers.deserializeWith(
        NotifyEvent.serializer,
        json,
      )!;

      final terminal = event.oneOf.value as NotifyEventOneOf3;
      expect(terminal.eventId, eventId);
      expect(terminal.type, NotifyEventOneOf3TypeEnum.terminal);
      expect(terminal.source_.machine, 'devbox');
      expect(terminal.session.id, 'ses_1');
      expect(
        terminal.payload.outcome,
        NotifyEventOneOf3PayloadOutcomeEnum.completed,
      );
      expect(terminal.payload.elapsedSeconds, 42);

      final out = standardSerializers.serializeWith(
        NotifyEvent.serializer,
        event,
      );
      expect(jsonDecode(jsonEncode(out)), json);
    });

    test('deserializes each variant by its type discriminator', () {
      final envelope = terminalEvent()
        ..remove('type')
        ..remove('payload');

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
      final payload = roundTripActionRequired<NotifyEventOneOf1PayloadOneOf>(
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
      expect(payload.questions.first.question, 'Which database should I use?');
      expect(payload.questions.first.options, hasLength(2));
      expect(payload.questions.first.options!.first.label, 'Postgres');
      expect(payload.questions.first.multiple, isFalse);
    });

    test('permission payload round-trips', () {
      final payload = roundTripActionRequired<NotifyEventOneOf1PayloadOneOf1>(
        actionRequiredEvent({
          'requestId': 'per_1',
          'kind': 'permission',
          'permission': {'permission': 'bash', 'summary': 'Run rm -rf build/'},
        }),
      );

      expect(payload.requestId, 'per_1');
      expect(payload.kind, NotifyEventOneOf1PayloadOneOf1KindEnum.permission);
      expect(payload.permission.permission, 'bash');
      expect(payload.permission.summary, 'Run rm -rf build/');
    });

    test('provider_action payload round-trips', () {
      final payload = roundTripActionRequired<NotifyEventOneOf1PayloadOneOf2>(
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
      expect(
        payload.kind,
        NotifyEventOneOf1PayloadOneOf2KindEnum.providerAction,
      );
      expect(payload.providerAction.provider, 'anthropic');
      expect(payload.providerAction.title, 'Sign-in required');
      expect(
        payload.providerAction.message,
        'Your Anthropic session has expired.',
      );
      expect(payload.providerAction.label, 'Reconnect');
      expect(payload.providerAction.link, 'https://provider.example/reconnect');
    });
  });

  group('WsServerMessage wrapper', () {
    test('round-trips the terminal event frame', () {
      final frame = {'type': 'event', 'event': terminalEvent()};
      final message = standardSerializers.deserializeWith(
        WsServerMessage.serializer,
        frame,
      )!;

      final eventMessage = message.oneOf.value as WsServerMessageOneOf;
      expect(eventMessage.type, WsServerMessageOneOfTypeEnum.event);
      final terminal = eventMessage.event.oneOf.value as NotifyEventOneOf3;
      expect(terminal.eventId, eventId);
      expect(
        terminal.payload.outcome,
        NotifyEventOneOf3PayloadOutcomeEnum.completed,
      );

      final out = standardSerializers.serializeWith(
        WsServerMessage.serializer,
        message,
      );
      expect(jsonDecode(jsonEncode(out)), frame);
    });

    test('round-trips an instance presence snapshot', () {
      final frame = {
        'type': 'instance_presence',
        'instances': [
          {
            'instanceId': '6f0d91b0-93e4-43a9-9449-0bed03e651aa',
            'machine': 'devbox',
            'project': 'notify',
            'directory': '/work/notify',
            'openCodeVersion': '1.18.18',
            'protocolVersion': 1,
            'state': 'controllable',
            'lastSeenAt': '2026-08-14T09:00:00.000Z',
          },
        ],
      };
      final message = standardSerializers.deserializeWith(
        WsServerMessage.serializer,
        frame,
      )!;
      final presence = message.oneOf.value as WsServerMessageOneOf1;

      expect(presence.type, WsServerMessageOneOf1TypeEnum.instancePresence);
      expect(presence.instances.single.machine, 'devbox');
      expect(
        presence.instances.single.state,
        WsServerMessageOneOf1InstancesInnerStateEnum.controllable,
      );
      final out = standardSerializers.serializeWith(
        WsServerMessage.serializer,
        message,
      );
      expect(jsonDecode(jsonEncode(out)), frame);
    });
  });

  test('round-trips a complete pending-interaction snapshot', () {
    final snapshotJson = {
      'generatedAt': '2026-08-14T09:00:05.000Z',
      'interactions': [
        {
          'kind': 'question',
          'instanceId': '6f0d91b0-93e4-43a9-9449-0bed03e651aa',
          'machine': 'devbox',
          'project': 'notify',
          'directory': '/work/notify',
          'sessionId': 'ses-1',
          'sessionTitle': 'Implement API',
          'requestId': 'question-1',
          'occurredAt': '2026-08-14T09:00:00.000Z',
          'tool': {'messageId': 'msg-1', 'callId': 'call-1'},
          'questions': [
            {
              'header': 'Database',
              'question': 'Which database?',
              'options': [
                {'label': 'Postgres', 'description': 'Production parity'},
              ],
              'multiple': false,
              'custom': true,
            },
          ],
        },
        {
          'kind': 'permission',
          'instanceId': '6f0d91b0-93e4-43a9-9449-0bed03e651aa',
          'machine': 'devbox',
          'project': 'notify',
          'directory': '/work/notify',
          'sessionId': 'ses-2',
          'sessionTitle': 'Build release',
          'requestId': 'permission-1',
          'occurredAt': '2026-08-14T09:00:01.000Z',
          'permission': 'bash',
          'patterns': ['docker build .'],
          'always': ['docker build *'],
          'metadata': {
            'command': 'docker build .',
            'nested': {'path': '/work/notify'},
          },
        },
      ],
    };
    final snapshot = standardSerializers.deserializeWith(
      PendingSnapshot.serializer,
      snapshotJson,
    )!;

    final question =
        snapshot.interactions.first.oneOf.value as PendingInteractionOneOf;
    final permission =
        snapshot.interactions.last.oneOf.value as PendingInteractionOneOf1;
    expect(
      question.questions.single.options.single.description,
      'Production parity',
    );
    expect(question.tool!.callId, 'call-1');
    expect(permission.patterns.single, 'docker build .');
    expect(permission.always.single, 'docker build *');
    expect(
      permission.metadata.value,
      snapshotJson['interactions'] is List
          ? (snapshotJson['interactions'] as List)[1]['metadata']
          : null,
    );

    final out = standardSerializers.serializeWith(
      PendingSnapshot.serializer,
      snapshot,
    );
    expect(jsonDecode(jsonEncode(out)), snapshotJson);
  });

  test('round-trips the optional queried instance ids scope', () {
    final snapshotJson = {
      'generatedAt': '2026-08-14T09:00:05.000Z',
      'interactions': <Object?>[],
      'queriedInstanceIds': ['6f0d91b0-93e4-43a9-9449-0bed03e651aa'],
    };
    final snapshot = standardSerializers.deserializeWith(
      PendingSnapshot.serializer,
      snapshotJson,
    )!;
    expect(
      snapshot.queriedInstanceIds!.single,
      '6f0d91b0-93e4-43a9-9449-0bed03e651aa',
    );

    final out = standardSerializers.serializeWith(
      PendingSnapshot.serializer,
      snapshot,
    );
    expect(jsonDecode(jsonEncode(out)), snapshotJson);

    // An absent field round-trips as null and is not re-emitted.
    final without = standardSerializers.deserializeWith(
      PendingSnapshot.serializer,
      snapshotJson..remove('queriedInstanceIds'),
    )!;
    expect(without.queriedInstanceIds, isNull);
  });

  group('Question answer command', () {
    test('AnswerQuestionBody round-trips the ordered answer set', () {
      final body = AnswerQuestionBody((b) {
        b.commandId = 'cmd-42';
        b.sessionId = 'ses-42';
        b.answers.replace([
          BuiltList<String>(['PostgreSQL']),
          BuiltList<String>(['Migrate', 'PostgreSQL', 'Use read replicas']),
        ]);
      });

      final out = standardSerializers.serializeWith(
        AnswerQuestionBody.serializer,
        body,
      );
      expect(jsonDecode(jsonEncode(out)), {
        'answers': [
          ['PostgreSQL'],
          ['Migrate', 'PostgreSQL', 'Use read replicas'],
        ],
        'commandId': 'cmd-42',
        'sessionId': 'ses-42',
      });

      final restored = standardSerializers.deserializeWith(
        AnswerQuestionBody.serializer,
        out,
      )!;
      expect(restored.commandId, 'cmd-42');
      expect(restored.sessionId, 'ses-42');
      expect(restored.answers.map((answer) => answer.toList()), [
        ['PostgreSQL'],
        ['Migrate', 'PostgreSQL', 'Use read replicas'],
      ]);
    });

    test('CommandAccepted round-trips the one-way acknowledgement', () {
      final json = {'commandId': 'cmd-42', 'status': 'accepted'};
      final accepted = standardSerializers.deserializeWith(
        CommandAccepted.serializer,
        json,
      )!;
      expect(accepted.commandId, 'cmd-42');
      expect(accepted.status, CommandAcceptedStatusEnum.accepted);

      final out = standardSerializers.serializeWith(
        CommandAccepted.serializer,
        accepted,
      );
      expect(jsonDecode(jsonEncode(out)), json);
    });
  });

  group('Permission decision command', () {
    test('DecidePermissionBody round-trips every decision', () {
      const decisions = [
        (DecidePermissionBodyDecisionEnum.once, 'once'),
        (DecidePermissionBodyDecisionEnum.reject, 'reject'),
        (DecidePermissionBodyDecisionEnum.always, 'always'),
      ];
      for (final (decision, wire) in decisions) {
        final body = DecidePermissionBody((b) {
          b.commandId = 'cmd-42';
          b.sessionId = 'ses-42';
          b.decision = decision;
        });

        final out = standardSerializers.serializeWith(
          DecidePermissionBody.serializer,
          body,
        );
        expect(jsonDecode(jsonEncode(out)), {
          'commandId': 'cmd-42',
          'decision': wire,
          'sessionId': 'ses-42',
        });

        final restored = standardSerializers.deserializeWith(
          DecidePermissionBody.serializer,
          out,
        )!;
        expect(restored.commandId, 'cmd-42');
        expect(restored.sessionId, 'ses-42');
        expect(restored.decision, decision);
      }
    });

  });

  group('Command outcome correlation', () {
    Map<String, Object?> commandOutcomeJson({
      required String kind,
      required String status,
    }) => {
      'commandId': 'cmd-42',
      'instanceId': '6f0d91b0-93e4-43a9-9449-0bed03e651aa',
      'kind': kind,
      'requestId': 'request-1',
      'status': status,
      'updatedAt': '2026-08-14T09:00:00.000Z',
    };

    test('CommandOutcome round-trips every status', () {
      const statuses = [
        (CommandOutcomeStatusEnum.accepted, 'accepted'),
        (CommandOutcomeStatusEnum.confirmed, 'confirmed'),
        (CommandOutcomeStatusEnum.stale, 'stale'),
        (CommandOutcomeStatusEnum.upstreamError, 'upstream_error'),
        (CommandOutcomeStatusEnum.resultUnknown, 'result_unknown'),
      ];
      for (final (status, wire) in statuses) {
        final json = commandOutcomeJson(kind: 'question', status: wire);
        final outcome = standardSerializers.deserializeWith(
          CommandOutcome.serializer,
          json,
        )!;
        expect(outcome.commandId, 'cmd-42');
        expect(outcome.instanceId, '6f0d91b0-93e4-43a9-9449-0bed03e651aa');
        expect(outcome.kind, CommandOutcomeKindEnum.question);
        expect(outcome.requestId, 'request-1');
        expect(outcome.status, status);
        expect(outcome.updatedAt, DateTime.utc(2026, 8, 14, 9));

        // The body-free shape round-trips byte-identically: only correlation
        // and status metadata, never the answer or decision body.
        final out = standardSerializers.serializeWith(
          CommandOutcome.serializer,
          outcome,
        );
        expect(jsonDecode(jsonEncode(out)), json);
      }
    });

    test('CommandOutcome round-trips both kinds', () {
      const kinds = [
        (CommandOutcomeKindEnum.question, 'question'),
        (CommandOutcomeKindEnum.permission, 'permission'),
      ];
      for (final (kind, wire) in kinds) {
        final json = commandOutcomeJson(kind: wire, status: 'confirmed');
        final outcome = standardSerializers.deserializeWith(
          CommandOutcome.serializer,
          json,
        )!;
        expect(outcome.kind, kind);

        final out = standardSerializers.serializeWith(
          CommandOutcome.serializer,
          outcome,
        );
        expect(jsonDecode(jsonEncode(out)), json);
      }
    });
  });
}
