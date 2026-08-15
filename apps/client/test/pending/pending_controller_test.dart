import 'dart:async';

import 'package:client/auth/auth_controller.dart';
import 'package:client/auth/auth_state.dart';
import 'package:client/pending/pending_answer.dart';
import 'package:client/pending/pending_controller.dart';
import 'package:client/pending/pending_interaction.dart';
import 'package:client/pending/pending_permission.dart';
import 'package:client/realtime/instance_presence.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MutableAuthController extends AuthController {
  MutableAuthController(this._initial);

  final AuthState _initial;

  @override
  AuthState build() => _initial;

  void replace(AuthState next) => state = next;
}

PendingQuestion interaction(String id, DateTime occurredAt) => PendingQuestion(
  instanceId: '6f0d91b0-93e4-43a9-9449-0bed03e651aa',
  machine: 'dev-box',
  project: 'api',
  directory: '/work/api',
  sessionId: 'ses-$id',
  sessionTitle: 'Session $id',
  requestId: id,
  occurredAt: occurredAt,
  tool: null,
  questions: const [
    PendingQuestionItem(
      header: 'Database',
      question: 'Which database?',
      options: [],
      multiple: false,
      custom: true,
    ),
  ],
);

PendingQuestion interactionOn({
  required String instanceId,
  required String id,
  required DateTime occurredAt,
}) => PendingQuestion(
  instanceId: instanceId,
  machine: 'dev-box',
  project: 'api',
  directory: '/work/api',
  sessionId: 'ses-$id',
  sessionTitle: 'Session $id',
  requestId: id,
  occurredAt: occurredAt,
  tool: null,
  questions: const [
    PendingQuestionItem(
      header: 'Database',
      question: 'Which database?',
      options: [],
      multiple: false,
      custom: true,
    ),
  ],
);

PendingQuestion multiQuestion(String id, DateTime occurredAt) =>
    PendingQuestion(
      instanceId: '6f0d91b0-93e4-43a9-9449-0bed03e651aa',
      machine: 'dev-box',
      project: 'api',
      directory: '/work/api',
      sessionId: 'ses-$id',
      sessionTitle: 'Session $id',
      requestId: id,
      occurredAt: occurredAt,
      tool: null,
      questions: const [
        PendingQuestionItem(
          header: 'Database',
          question: 'Which database?',
          options: [
            PendingOption(
              label: 'PostgreSQL',
              description: 'Production parity',
            ),
            PendingOption(label: 'SQLite', description: 'Fast local runs'),
          ],
          multiple: false,
          custom: true,
        ),
        PendingQuestionItem(
          header: 'Migration',
          question: 'What else should the migration do?',
          options: [
            PendingOption(label: 'Migrate data', description: 'Copy rows'),
            PendingOption(label: 'Add indexes', description: 'Speed queries'),
          ],
          multiple: true,
          custom: true,
        ),
      ],
    );

/// Controllable answer sender for controller tests.
class ScriptedAnswerSender {
  int calls = 0;
  final List<
    ({
      String instanceId,
      String requestId,
      String commandId,
      List<List<String>> answers,
    })
  >
  received = [];
  Completer<QuestionAnswerResult>? gate;
  QuestionAnswerOutcome outcome = QuestionAnswerOutcome.confirmed;
  Object? throwError;

  Future<QuestionAnswerResult> call({
    required String instanceId,
    required String requestId,
    required String commandId,
    required List<List<String>> answers,
  }) async {
    calls++;
    received.add((
      instanceId: instanceId,
      requestId: requestId,
      commandId: commandId,
      answers: answers,
    ));
    final current = gate;
    if (current != null) {
      return current.future;
    }
    final error = throwError;
    if (error != null) {
      throw error;
    }
    return QuestionAnswerResult(commandId: commandId, outcome: outcome);
  }
}

ProviderContainer answerContainer({
  required PendingQuestion question,
  required QuestionAnswerSender sender,
  Future<List<PendingInteraction>> Function(int call)? loader,
  String Function()? commandId,
}) {
  var calls = 0;
  return ProviderContainer(
    overrides: [
      authControllerProvider.overrideWith(
        () => MutableAuthController(
          const Authenticated(
            accessToken: 'access-1',
            email: 'user@example.com',
          ),
        ),
      ),
      pendingInteractionLoaderProvider.overrideWithValue(() async {
        final call = calls++;
        return loader?.call(call) ?? [question];
      }),
      questionAnswerSenderProvider.overrideWithValue(sender),
      commandIdGeneratorProvider.overrideWithValue(commandId ?? () => 'cmd-1'),
    ],
  );
}

PendingPermission permission(String id, DateTime occurredAt) =>
    PendingPermission(
      instanceId: '6f0d91b0-93e4-43a9-9449-0bed03e651aa',
      machine: 'dev-box',
      project: 'api',
      directory: '/work/api',
      sessionId: 'ses-$id',
      sessionTitle: 'Session $id',
      requestId: id,
      occurredAt: occurredAt,
      tool: null,
      permission: 'bash',
      patterns: const ['docker build .'],
      always: const ['docker build *'],
      metadata: const {'command': 'docker build .'},
    );

/// Controllable decision sender for controller tests.
class ScriptedDecisionSender {
  int calls = 0;
  final List<
    ({
      String instanceId,
      String requestId,
      String commandId,
      PermissionDecision decision,
    })
  >
  received = [];
  Completer<PermissionDecisionResult>? gate;
  PermissionDecisionOutcome outcome = PermissionDecisionOutcome.confirmed;
  Object? throwError;

  Future<PermissionDecisionResult> call({
    required String instanceId,
    required String requestId,
    required String commandId,
    required PermissionDecision decision,
  }) async {
    calls++;
    received.add((
      instanceId: instanceId,
      requestId: requestId,
      commandId: commandId,
      decision: decision,
    ));
    final current = gate;
    if (current != null) {
      return current.future;
    }
    final error = throwError;
    if (error != null) {
      throw error;
    }
    return PermissionDecisionResult(commandId: commandId, outcome: outcome);
  }
}

ProviderContainer decisionContainer({
  required PendingPermission permission,
  required PermissionDecisionSender sender,
  Future<List<PendingInteraction>> Function(int call)? loader,
  String Function()? commandId,
}) {
  var calls = 0;
  return ProviderContainer(
    overrides: [
      authControllerProvider.overrideWith(
        () => MutableAuthController(
          const Authenticated(
            accessToken: 'access-1',
            email: 'user@example.com',
          ),
        ),
      ),
      pendingInteractionLoaderProvider.overrideWithValue(() async {
        final call = calls++;
        return loader?.call(call) ?? [permission];
      }),
      permissionDecisionSenderProvider.overrideWithValue(sender),
      commandIdGeneratorProvider.overrideWithValue(commandId ?? () => 'cmd-1'),
    ],
  );
}

void main() {
  const authenticated = Authenticated(
    accessToken: 'access-1',
    email: 'user@example.com',
  );

  test('default command ids are UUID v4 values accepted by the contract', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final commandId = container.read(commandIdGeneratorProvider)();

    expect(
      commandId,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
  });

  test('stays empty and does not load while unauthenticated', () async {
    var calls = 0;
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => MutableAuthController(const Unauthenticated()),
        ),
        pendingInteractionLoaderProvider.overrideWithValue(() async {
          calls++;
          return const [];
        }),
      ],
    );
    addTearDown(container.dispose);

    expect(await container.read(pendingInteractionsProvider.future), isEmpty);
    expect(calls, 0);
  });

  test('loads on authentication and orders longest waiting first', () async {
    var calls = 0;
    final newer = interaction('newer', DateTime.utc(2026, 8, 14, 10));
    final older = interaction('older', DateTime.utc(2026, 8, 14, 9));
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => MutableAuthController(authenticated),
        ),
        pendingInteractionLoaderProvider.overrideWithValue(() async {
          calls++;
          return [newer, older];
        }),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(pendingInteractionsProvider.future);

    expect(result.map((item) => item.requestId), ['older', 'newer']);
    expect(calls, 1);
  });

  test(
    'authentication recovery triggers the first authoritative load',
    () async {
      var calls = 0;
      final auth = MutableAuthController(const Unauthenticated());
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(() => auth),
          pendingInteractionLoaderProvider.overrideWithValue(() async {
            calls++;
            return [interaction('request', DateTime.utc(2026, 8, 14, 9))];
          }),
        ],
      );
      addTearDown(container.dispose);
      await container.read(pendingInteractionsProvider.future);

      auth.replace(authenticated);
      final result = await container.read(pendingInteractionsProvider.future);

      expect(result.single.requestId, 'request');
      expect(calls, 1);
    },
  );

  test('a controllable instance reconnect refreshes the snapshot', () async {
    var calls = 0;
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => MutableAuthController(authenticated),
        ),
        pendingInteractionLoaderProvider.overrideWithValue(() async {
          calls++;
          return const [];
        }),
      ],
    );
    addTearDown(container.dispose);
    await container.read(pendingInteractionsProvider.future);

    container.read(instancePresencesProvider.notifier).replaceAll([
      OpenCodeInstancePresence(
        instanceId: '6f0d91b0-93e4-43a9-9449-0bed03e651aa',
        machine: 'dev-box',
        project: 'api',
        directory: '/work/api',
        openCodeVersion: '1.18.18',
        protocolVersion: 1,
        state: InstancePresenceState.controllable,
        lastSeenAt: DateTime.utc(2026, 8, 14, 10),
      ),
    ]);
    await container.read(pendingInteractionsProvider.future);

    expect(calls, 2);
  });

  test('manual refresh replaces the snapshot', () async {
    var calls = 0;
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => MutableAuthController(authenticated),
        ),
        pendingInteractionLoaderProvider.overrideWithValue(() async {
          calls++;
          return [interaction('request-$calls', DateTime.utc(2026, 8, 14, 9))];
        }),
      ],
    );
    addTearDown(container.dispose);
    expect(
      (await container.read(
        pendingInteractionsProvider.future,
      )).single.requestId,
      'request-1',
    );

    await container.read(pendingInteractionsProvider.notifier).refresh();

    expect(
      container.read(pendingInteractionsProvider).requireValue.single.requestId,
      'request-2',
    );
  });

  test(
    'a refresh from the previous session cannot repopulate after logout',
    () async {
      final auth = MutableAuthController(authenticated);
      final delayed = Completer<List<PendingInteraction>>();
      var calls = 0;
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(() => auth),
          pendingInteractionLoaderProvider.overrideWithValue(() async {
            calls++;
            if (calls == 1) return const [];
            return delayed.future;
          }),
        ],
      );
      addTearDown(container.dispose);
      await container.read(pendingInteractionsProvider.future);

      final refresh = container
          .read(pendingInteractionsProvider.notifier)
          .refresh();
      auth.replace(const Unauthenticated());
      delayed.complete([
        interaction('old-account', DateTime.utc(2026, 8, 14, 9)),
      ]);
      await refresh;
      final current = await container.read(pendingInteractionsProvider.future);

      expect(current, isEmpty);
    },
  );

  group('answerQuestion', () {
    final question = multiQuestion('question-1', DateTime.utc(2026, 8, 14, 9));

    test('submits ordered answers with the injected command id and confirmed '
        'removes the interaction', () async {
      final sender = ScriptedAnswerSender()
        ..outcome = QuestionAnswerOutcome.confirmed;
      var loads = 0;
      final container = answerContainer(
        question: question,
        sender: sender.call,
        loader: (call) async {
          loads++;
          return call == 0 ? [question] : const <PendingInteraction>[];
        },
      );
      addTearDown(container.dispose);
      await container.read(pendingInteractionsProvider.future);

      await container
          .read(pendingInteractionsProvider.notifier)
          .answerQuestion(
            question: question,
            answers: const [
              ['PostgreSQL'],
              ['Migrate data', 'Add indexes'],
            ],
          );

      expect(sender.calls, 1);
      final sent = sender.received.single;
      expect(sent.commandId, 'cmd-1');
      expect(sent.instanceId, question.instanceId);
      expect(sent.requestId, 'question-1');
      expect(sent.answers, [
        ['PostgreSQL'],
        ['Migrate data', 'Add indexes'],
      ]);
      expect(loads, 2);
      expect(
        container.read(questionSubmissionStatesProvider)['question-1'],
        QuestionSubmissionState.confirmed,
      );
      expect(container.read(pendingInteractionsProvider).requireValue, isEmpty);
    });

    test(
      'shows submitting while in flight and resolves to confirmed',
      () async {
        final sender = ScriptedAnswerSender()
          ..gate = Completer<QuestionAnswerResult>();
        var loads = 0;
        final container = answerContainer(
          question: question,
          sender: sender.call,
          loader: (call) async {
            loads++;
            return call == 0 ? [question] : const <PendingInteraction>[];
          },
        );
        addTearDown(container.dispose);
        await container.read(pendingInteractionsProvider.future);

        final submission = container
            .read(pendingInteractionsProvider.notifier)
            .answerQuestion(
              question: question,
              answers: const [
                ['PostgreSQL'],
                ['Migrate data'],
              ],
            );
        await Future<void>.delayed(Duration.zero);
        expect(
          container.read(questionSubmissionStatesProvider)['question-1'],
          QuestionSubmissionState.submitting,
        );

        sender.gate!.complete(
          const QuestionAnswerResult(
            commandId: 'cmd-1',
            outcome: QuestionAnswerOutcome.confirmed,
          ),
        );
        await submission;
        expect(loads, 2);
        expect(
          container.read(questionSubmissionStatesProvider)['question-1'],
          QuestionSubmissionState.confirmed,
        );
        expect(
          container.read(pendingInteractionsProvider).requireValue,
          isEmpty,
        );
      },
    );

    test('stale keeps the interaction and re-reads the snapshot', () async {
      final sender = ScriptedAnswerSender()
        ..outcome = QuestionAnswerOutcome.stale;
      var loads = 0;
      final container = answerContainer(
        question: question,
        sender: sender.call,
        loader: (call) async {
          loads++;
          return [question];
        },
      );
      addTearDown(container.dispose);
      await container.read(pendingInteractionsProvider.future);

      await container
          .read(pendingInteractionsProvider.notifier)
          .answerQuestion(
            question: question,
            answers: const [
              ['PostgreSQL'],
              ['Migrate data'],
            ],
          );

      expect(loads, 2);
      expect(
        container.read(questionSubmissionStatesProvider)['question-1'],
        QuestionSubmissionState.stale,
      );
      expect(
        container
            .read(pendingInteractionsProvider)
            .requireValue
            .single
            .requestId,
        'question-1',
      );
    });

    test(
      'upstream error keeps the interaction and re-reads the snapshot',
      () async {
        final sender = ScriptedAnswerSender()
          ..outcome = QuestionAnswerOutcome.upstreamError;
        var loads = 0;
        final container = answerContainer(
          question: question,
          sender: sender.call,
          loader: (call) async {
            loads++;
            return [question];
          },
        );
        addTearDown(container.dispose);
        await container.read(pendingInteractionsProvider.future);

        await container
            .read(pendingInteractionsProvider.notifier)
            .answerQuestion(
              question: question,
              answers: const [
                ['PostgreSQL'],
                ['Migrate data'],
              ],
            );

        expect(loads, 2);
        expect(
          container.read(questionSubmissionStatesProvider)['question-1'],
          QuestionSubmissionState.upstreamError,
        );
        expect(
          container
              .read(pendingInteractionsProvider)
              .requireValue
              .single
              .requestId,
          'question-1',
        );
      },
    );

    test(
      'result unknown keeps the interaction visible without re-reading',
      () async {
        final sender = ScriptedAnswerSender()
          ..outcome = QuestionAnswerOutcome.resultUnknown;
        var loads = 0;
        final container = answerContainer(
          question: question,
          sender: sender.call,
          loader: (call) async {
            loads++;
            return [question];
          },
        );
        addTearDown(container.dispose);
        await container.read(pendingInteractionsProvider.future);

        await container
            .read(pendingInteractionsProvider.notifier)
            .answerQuestion(
              question: question,
              answers: const [
                ['PostgreSQL'],
                ['Migrate data'],
              ],
            );

        expect(loads, 1);
        expect(
          container.read(questionSubmissionStatesProvider)['question-1'],
          QuestionSubmissionState.resultUnknown,
        );
        expect(
          container
              .read(pendingInteractionsProvider)
              .requireValue
              .single
              .requestId,
          'question-1',
        );
      },
    );

    test(
      'a 4xx gateway rejection keeps the interaction and re-reads',
      () async {
        final sender = ScriptedAnswerSender()
          ..throwError = DioException(
            requestOptions: RequestOptions(
              path: '/v1/pending-interactions/i/questions/q/answer',
            ),
            response: Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 409,
            ),
            type: DioExceptionType.badResponse,
          );
        var loads = 0;
        final container = answerContainer(
          question: question,
          sender: sender.call,
          loader: (call) async {
            loads++;
            return [question];
          },
        );
        addTearDown(container.dispose);
        await container.read(pendingInteractionsProvider.future);

        await container
            .read(pendingInteractionsProvider.notifier)
            .answerQuestion(
              question: question,
              answers: const [
                ['PostgreSQL'],
                ['Migrate data'],
              ],
            );

        expect(loads, 2);
        expect(
          container.read(questionSubmissionStatesProvider)['question-1'],
          QuestionSubmissionState.rejected,
        );
        expect(
          container
              .read(pendingInteractionsProvider)
              .requireValue
              .single
              .requestId,
          'question-1',
        );
      },
    );

    test(
      'a transport failure keeps the interaction as result unknown',
      () async {
        final sender = ScriptedAnswerSender()
          ..throwError = DioException(
            requestOptions: RequestOptions(
              path: '/v1/pending-interactions/i/questions/q/answer',
            ),
            type: DioExceptionType.connectionError,
            error: 'no network',
          );
        var loads = 0;
        final container = answerContainer(
          question: question,
          sender: sender.call,
          loader: (call) async {
            loads++;
            return [question];
          },
        );
        addTearDown(container.dispose);
        await container.read(pendingInteractionsProvider.future);

        await container
            .read(pendingInteractionsProvider.notifier)
            .answerQuestion(
              question: question,
              answers: const [
                ['PostgreSQL'],
                ['Migrate data'],
              ],
            );

        expect(loads, 1);
        expect(
          container.read(questionSubmissionStatesProvider)['question-1'],
          QuestionSubmissionState.resultUnknown,
        );
        expect(
          container
              .read(pendingInteractionsProvider)
              .requireValue
              .single
              .requestId,
          'question-1',
        );
      },
    );

    test(
      'an unexpected sender failure keeps the interaction as unknown',
      () async {
        final sender = ScriptedAnswerSender()
          ..throwError = StateError('no response body');
        var loads = 0;
        final container = answerContainer(
          question: question,
          sender: sender.call,
          loader: (call) async {
            loads++;
            return [question];
          },
        );
        addTearDown(container.dispose);
        await container.read(pendingInteractionsProvider.future);

        await container
            .read(pendingInteractionsProvider.notifier)
            .answerQuestion(
              question: question,
              answers: const [
                ['PostgreSQL'],
                ['Migrate data'],
              ],
            );

        expect(loads, 1);
        expect(
          container.read(questionSubmissionStatesProvider)['question-1'],
          QuestionSubmissionState.resultUnknown,
        );
        expect(
          container
              .read(pendingInteractionsProvider)
              .requireValue
              .single
              .requestId,
          'question-1',
        );
      },
    );
  });

  group('decidePermission', () {
    final pendingPermission = permission(
      'permission-1',
      DateTime.utc(2026, 8, 14, 9),
    );

    test('allow once with the injected command id and confirmed removes '
        'the interaction', () async {
      final sender = ScriptedDecisionSender()
        ..outcome = PermissionDecisionOutcome.confirmed;
      var loads = 0;
      final container = decisionContainer(
        permission: pendingPermission,
        sender: sender.call,
        loader: (call) async {
          loads++;
          return call == 0 ? [pendingPermission] : const <PendingInteraction>[];
        },
      );
      addTearDown(container.dispose);
      await container.read(pendingInteractionsProvider.future);

      await container
          .read(pendingInteractionsProvider.notifier)
          .decidePermission(
            permission: pendingPermission,
            decision: PermissionDecision.once,
          );

      expect(sender.calls, 1);
      final sent = sender.received.single;
      expect(sent.commandId, 'cmd-1');
      expect(sent.instanceId, pendingPermission.instanceId);
      expect(sent.requestId, 'permission-1');
      expect(sent.decision, PermissionDecision.once);
      expect(loads, 2);
      expect(
        container.read(permissionSubmissionStatesProvider)['permission-1'],
        PermissionDecisionState.confirmed,
      );
      expect(container.read(pendingInteractionsProvider).requireValue, isEmpty);
    });

    test('reject with the injected command id and confirmed removes the '
        'interaction', () async {
      final sender = ScriptedDecisionSender()
        ..outcome = PermissionDecisionOutcome.confirmed;
      var loads = 0;
      final container = decisionContainer(
        permission: pendingPermission,
        sender: sender.call,
        loader: (call) async {
          loads++;
          return call == 0 ? [pendingPermission] : const <PendingInteraction>[];
        },
      );
      addTearDown(container.dispose);
      await container.read(pendingInteractionsProvider.future);

      await container
          .read(pendingInteractionsProvider.notifier)
          .decidePermission(
            permission: pendingPermission,
            decision: PermissionDecision.reject,
          );

      expect(sender.received.single.decision, PermissionDecision.reject);
      expect(loads, 2);
      expect(
        container.read(permissionSubmissionStatesProvider)['permission-1'],
        PermissionDecisionState.confirmed,
      );
      expect(container.read(pendingInteractionsProvider).requireValue, isEmpty);
    });

    test('always with the injected command id and confirmed removes the '
        'interaction', () async {
      final sender = ScriptedDecisionSender()
        ..outcome = PermissionDecisionOutcome.confirmed;
      var loads = 0;
      final container = decisionContainer(
        permission: pendingPermission,
        sender: sender.call,
        loader: (call) async {
          loads++;
          return call == 0 ? [pendingPermission] : const <PendingInteraction>[];
        },
      );
      addTearDown(container.dispose);
      await container.read(pendingInteractionsProvider.future);

      await container
          .read(pendingInteractionsProvider.notifier)
          .decidePermission(
            permission: pendingPermission,
            decision: PermissionDecision.always,
          );

      expect(sender.calls, 1);
      final sent = sender.received.single;
      expect(sent.commandId, 'cmd-1');
      expect(sent.instanceId, pendingPermission.instanceId);
      expect(sent.requestId, 'permission-1');
      expect(sent.decision, PermissionDecision.always);
      expect(loads, 2);
      expect(
        container.read(permissionSubmissionStatesProvider)['permission-1'],
        PermissionDecisionState.confirmed,
      );
      expect(container.read(pendingInteractionsProvider).requireValue, isEmpty);
    });

    test(
      'shows submitting while in flight and resolves to confirmed',
      () async {
        final sender = ScriptedDecisionSender()
          ..gate = Completer<PermissionDecisionResult>();
        var loads = 0;
        final container = decisionContainer(
          permission: pendingPermission,
          sender: sender.call,
          loader: (call) async {
            loads++;
            return call == 0
                ? [pendingPermission]
                : const <PendingInteraction>[];
          },
        );
        addTearDown(container.dispose);
        await container.read(pendingInteractionsProvider.future);

        final submission = container
            .read(pendingInteractionsProvider.notifier)
            .decidePermission(
              permission: pendingPermission,
              decision: PermissionDecision.once,
            );
        await Future<void>.delayed(Duration.zero);
        expect(
          container.read(permissionSubmissionStatesProvider)['permission-1'],
          PermissionDecisionState.submitting,
        );

        sender.gate!.complete(
          const PermissionDecisionResult(
            commandId: 'cmd-1',
            outcome: PermissionDecisionOutcome.confirmed,
          ),
        );
        await submission;
        expect(loads, 2);
        expect(
          container.read(permissionSubmissionStatesProvider)['permission-1'],
          PermissionDecisionState.confirmed,
        );
        expect(
          container.read(pendingInteractionsProvider).requireValue,
          isEmpty,
        );
      },
    );

    test('stale keeps the interaction and re-reads the snapshot', () async {
      final sender = ScriptedDecisionSender()
        ..outcome = PermissionDecisionOutcome.stale;
      var loads = 0;
      final container = decisionContainer(
        permission: pendingPermission,
        sender: sender.call,
        loader: (call) async {
          loads++;
          return [pendingPermission];
        },
      );
      addTearDown(container.dispose);
      await container.read(pendingInteractionsProvider.future);

      await container
          .read(pendingInteractionsProvider.notifier)
          .decidePermission(
            permission: pendingPermission,
            decision: PermissionDecision.once,
          );

      expect(loads, 2);
      expect(
        container.read(permissionSubmissionStatesProvider)['permission-1'],
        PermissionDecisionState.stale,
      );
      expect(
        container
            .read(pendingInteractionsProvider)
            .requireValue
            .single
            .requestId,
        'permission-1',
      );
    });

    test(
      'upstream error keeps the interaction and re-reads the snapshot',
      () async {
        final sender = ScriptedDecisionSender()
          ..outcome = PermissionDecisionOutcome.upstreamError;
        var loads = 0;
        final container = decisionContainer(
          permission: pendingPermission,
          sender: sender.call,
          loader: (call) async {
            loads++;
            return [pendingPermission];
          },
        );
        addTearDown(container.dispose);
        await container.read(pendingInteractionsProvider.future);

        await container
            .read(pendingInteractionsProvider.notifier)
            .decidePermission(
              permission: pendingPermission,
              decision: PermissionDecision.reject,
            );

        expect(loads, 2);
        expect(
          container.read(permissionSubmissionStatesProvider)['permission-1'],
          PermissionDecisionState.upstreamError,
        );
        expect(
          container
              .read(pendingInteractionsProvider)
              .requireValue
              .single
              .requestId,
          'permission-1',
        );
      },
    );

    test(
      'result unknown keeps the interaction visible without re-reading',
      () async {
        final sender = ScriptedDecisionSender()
          ..outcome = PermissionDecisionOutcome.resultUnknown;
        var loads = 0;
        final container = decisionContainer(
          permission: pendingPermission,
          sender: sender.call,
          loader: (call) async {
            loads++;
            return [pendingPermission];
          },
        );
        addTearDown(container.dispose);
        await container.read(pendingInteractionsProvider.future);

        await container
            .read(pendingInteractionsProvider.notifier)
            .decidePermission(
              permission: pendingPermission,
              decision: PermissionDecision.once,
            );

        expect(loads, 1);
        expect(
          container.read(permissionSubmissionStatesProvider)['permission-1'],
          PermissionDecisionState.resultUnknown,
        );
        expect(
          container
              .read(pendingInteractionsProvider)
              .requireValue
              .single
              .requestId,
          'permission-1',
        );
      },
    );

    test(
      'a 4xx gateway rejection keeps the interaction and re-reads',
      () async {
        final sender = ScriptedDecisionSender()
          ..throwError = DioException(
            requestOptions: RequestOptions(
              path: '/v1/pending-interactions/i/permissions/p/decision',
            ),
            response: Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 409,
            ),
            type: DioExceptionType.badResponse,
          );
        var loads = 0;
        final container = decisionContainer(
          permission: pendingPermission,
          sender: sender.call,
          loader: (call) async {
            loads++;
            return [pendingPermission];
          },
        );
        addTearDown(container.dispose);
        await container.read(pendingInteractionsProvider.future);

        await container
            .read(pendingInteractionsProvider.notifier)
            .decidePermission(
              permission: pendingPermission,
              decision: PermissionDecision.once,
            );

        expect(loads, 2);
        expect(
          container.read(permissionSubmissionStatesProvider)['permission-1'],
          PermissionDecisionState.rejected,
        );
        expect(
          container
              .read(pendingInteractionsProvider)
              .requireValue
              .single
              .requestId,
          'permission-1',
        );
      },
    );

    test(
      'a transport failure keeps the interaction as result unknown',
      () async {
        final sender = ScriptedDecisionSender()
          ..throwError = DioException(
            requestOptions: RequestOptions(
              path: '/v1/pending-interactions/i/permissions/p/decision',
            ),
            type: DioExceptionType.connectionError,
            error: 'no network',
          );
        var loads = 0;
        final container = decisionContainer(
          permission: pendingPermission,
          sender: sender.call,
          loader: (call) async {
            loads++;
            return [pendingPermission];
          },
        );
        addTearDown(container.dispose);
        await container.read(pendingInteractionsProvider.future);

        await container
            .read(pendingInteractionsProvider.notifier)
            .decidePermission(
              permission: pendingPermission,
              decision: PermissionDecision.once,
            );

        expect(loads, 1);
        expect(
          container.read(permissionSubmissionStatesProvider)['permission-1'],
          PermissionDecisionState.resultUnknown,
        );
        expect(
          container
              .read(pendingInteractionsProvider)
              .requireValue
              .single
              .requestId,
          'permission-1',
        );
      },
    );

    test(
      'an unexpected sender failure keeps the interaction as unknown',
      () async {
        final sender = ScriptedDecisionSender()
          ..throwError = StateError('no response body');
        var loads = 0;
        final container = decisionContainer(
          permission: pendingPermission,
          sender: sender.call,
          loader: (call) async {
            loads++;
            return [pendingPermission];
          },
        );
        addTearDown(container.dispose);
        await container.read(pendingInteractionsProvider.future);

        await container
            .read(pendingInteractionsProvider.notifier)
            .decidePermission(
              permission: pendingPermission,
              decision: PermissionDecision.once,
            );

        expect(loads, 1);
        expect(
          container.read(permissionSubmissionStatesProvider)['permission-1'],
          PermissionDecisionState.resultUnknown,
        );
        expect(
          container
              .read(pendingInteractionsProvider)
              .requireValue
              .single
              .requestId,
          'permission-1',
        );
      },
    );
  });

  group('last-known retention', () {
    test('retains last-known interactions for instances absent from a newer '
        'snapshot', () async {
      var calls = 0;
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(
            () => MutableAuthController(authenticated),
          ),
          pendingInteractionLoaderProvider.overrideWithValue(() async {
            calls++;
            if (calls == 1) {
              return [
                interactionOn(
                  instanceId: 'inst-a',
                  id: 'a',
                  occurredAt: DateTime.utc(2026, 8, 14, 9),
                ),
                interactionOn(
                  instanceId: 'inst-b',
                  id: 'b',
                  occurredAt: DateTime.utc(2026, 8, 14, 9, 1),
                ),
              ];
            }
            return [
              interactionOn(
                instanceId: 'inst-a',
                id: 'a2',
                occurredAt: DateTime.utc(2026, 8, 14, 9, 2),
              ),
            ];
          }),
        ],
      );
      addTearDown(container.dispose);

      await container.read(pendingInteractionsProvider.future);
      final controller = container.read(pendingInteractionsProvider.notifier);
      expect(controller.lastKnownByInstance['inst-a']!.single.requestId, 'a');
      expect(controller.lastKnownByInstance['inst-b']!.single.requestId, 'b');

      await controller.refresh();
      // inst-a refreshes; inst-b is absent but its last-known survives.
      expect(controller.lastKnownByInstance['inst-a']!.single.requestId, 'a2');
      expect(controller.lastKnownByInstance['inst-b']!.single.requestId, 'b');
    });

    test('clears the retained last-known on logout', () async {
      final auth = MutableAuthController(authenticated);
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(() => auth),
          pendingInteractionLoaderProvider.overrideWithValue(() async {
            return [
              interactionOn(
                instanceId: 'inst-a',
                id: 'a',
                occurredAt: DateTime.utc(2026, 8, 14, 9),
              ),
            ];
          }),
        ],
      );
      addTearDown(container.dispose);

      await container.read(pendingInteractionsProvider.future);
      expect(
        container
            .read(pendingInteractionsProvider.notifier)
            .lastKnownByInstance,
        isNotEmpty,
      );

      auth.replace(const Unauthenticated());
      await container.read(pendingInteractionsProvider.future);

      expect(
        container
            .read(pendingInteractionsProvider.notifier)
            .lastKnownByInstance,
        isEmpty,
      );
    });
  });

  group('offlineLastKnownProvider', () {
    OpenCodeInstancePresence presence(String id, InstancePresenceState state) =>
        OpenCodeInstancePresence(
          instanceId: id,
          machine: 'dev-box',
          project: 'api',
          directory: '/work/api',
          openCodeVersion: '1.18.18',
          protocolVersion: 1,
          state: state,
          lastSeenAt: DateTime.utc(2026, 8, 14, 10),
        );

    test(
      'wraps retained requests of offline instances with lastSeenAt',
      () async {
        final container = ProviderContainer(
          overrides: [
            authControllerProvider.overrideWith(
              () => MutableAuthController(authenticated),
            ),
            pendingInteractionLoaderProvider.overrideWithValue(() async {
              return [
                interactionOn(
                  instanceId: 'inst-a',
                  id: 'a',
                  occurredAt: DateTime.utc(2026, 8, 14, 9),
                ),
              ];
            }),
          ],
        );
        addTearDown(container.dispose);
        await container.read(pendingInteractionsProvider.future);

        container.read(instancePresencesProvider.notifier).replaceAll([
          presence('inst-a', InstancePresenceState.offline),
          presence('inst-b', InstancePresenceState.controllable),
        ]);

        final offline = container.read(offlineLastKnownProvider);
        expect(offline, hasLength(1));
        expect(offline.single.interaction.requestId, 'a');
        expect(offline.single.lastSeenAt, DateTime.utc(2026, 8, 14, 10));
      },
    );

    test(
      'keeps retained requests when the instance leaves the snapshot',
      () async {
        var calls = 0;
        final container = ProviderContainer(
          overrides: [
            authControllerProvider.overrideWith(
              () => MutableAuthController(authenticated),
            ),
            pendingInteractionLoaderProvider.overrideWithValue(() async {
              calls++;
              return calls == 1
                  ? [
                      interactionOn(
                        instanceId: 'inst-a',
                        id: 'a',
                        occurredAt: DateTime.utc(2026, 8, 14, 9),
                      ),
                    ]
                  : const <PendingInteraction>[];
            }),
          ],
        );
        addTearDown(container.dispose);
        await container.read(pendingInteractionsProvider.future);

        container.read(instancePresencesProvider.notifier).replaceAll([
          presence('inst-a', InstancePresenceState.offline),
        ]);

        // A later fetch drops the instance; the offline view still shows it.
        await container.read(pendingInteractionsProvider.notifier).refresh();
        expect(
          container.read(pendingInteractionsProvider).requireValue,
          isEmpty,
        );
        final offline = container.read(offlineLastKnownProvider);
        expect(offline.single.interaction.requestId, 'a');
        expect(offline.single.lastSeenAt, DateTime.utc(2026, 8, 14, 10));
      },
    );

    test('excludes requests of online instances', () async {
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(
            () => MutableAuthController(authenticated),
          ),
          pendingInteractionLoaderProvider.overrideWithValue(() async {
            return [
              interactionOn(
                instanceId: 'inst-a',
                id: 'a',
                occurredAt: DateTime.utc(2026, 8, 14, 9),
              ),
            ];
          }),
        ],
      );
      addTearDown(container.dispose);
      await container.read(pendingInteractionsProvider.future);

      container.read(instancePresencesProvider.notifier).replaceAll([
        presence('inst-a', InstancePresenceState.controllable),
      ]);

      expect(container.read(offlineLastKnownProvider), isEmpty);
    });
  });
}
