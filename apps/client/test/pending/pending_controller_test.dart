import 'dart:async';

import 'package:client/auth/auth_controller.dart';
import 'package:client/auth/auth_state.dart';
import 'package:client/pending/command_outcome.dart';
import 'package:client/pending/pending_answer.dart';
import 'package:client/pending/pending_controller.dart';
import 'package:client/pending/pending_interaction.dart';
import 'package:client/pending/pending_permission.dart';
import 'package:client/realtime/instance_presence.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:notify_api/notify_api.dart' show PendingApi;

class MockPendingApi extends Mock implements PendingApi {}

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
      String sessionId,
      String commandId,
      List<List<String>> answers,
    })
  >
  received = [];
  Completer<QuestionAnswerResult>? gate;
  QuestionAnswerOutcome outcome = QuestionAnswerOutcome.accepted;
  Object? throwError;

  Future<QuestionAnswerResult> call({
    required String instanceId,
    required String requestId,
    required String sessionId,
    required String commandId,
    required List<List<String>> answers,
  }) async {
    calls++;
    received.add((
      instanceId: instanceId,
      requestId: requestId,
      sessionId: sessionId,
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
  CommandOutcomeLoader? outcomeLoader,
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
        final loaded = await (loader?.call(call) ?? Future.value([question]));
        return (interactions: loaded, queriedInstanceIds: null);
      }),
      questionAnswerSenderProvider.overrideWithValue(sender),
      commandOutcomeLoaderProvider.overrideWithValue(
        outcomeLoader ?? ScriptedOutcomeLoader().call,
      ),
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

/// Controllable outcome loader for controller tests. Resolves to an accepted
/// record by default so an unknown submission stays unknown and still triggers
/// the authoritative re-read.
class ScriptedOutcomeLoader {
  int calls = 0;
  final List<String> queried = [];
  Completer<CommandOutcomeInfo>? gate;
  CommandOutcomeInfo result = const CommandOutcomeInfo(
    status: CommandOutcomeStatus.accepted,
    kind: CommandOutcomeKind.question,
  );
  Object? throwError;

  Future<CommandOutcomeInfo> call(String commandId) async {
    calls++;
    queried.add(commandId);
    final current = gate;
    if (current != null) {
      return current.future;
    }
    final error = throwError;
    if (error != null) {
      throw error;
    }
    return result;
  }
}

/// Controllable decision sender for controller tests.
class ScriptedDecisionSender {
  int calls = 0;
  final List<
    ({
      String instanceId,
      String requestId,
      String sessionId,
      String commandId,
      PermissionDecision decision,
    })
  >
  received = [];
  Completer<PermissionDecisionResult>? gate;
  PermissionDecisionOutcome outcome = PermissionDecisionOutcome.accepted;
  Object? throwError;

  Future<PermissionDecisionResult> call({
    required String instanceId,
    required String requestId,
    required String sessionId,
    required String commandId,
    required PermissionDecision decision,
  }) async {
    calls++;
    received.add((
      instanceId: instanceId,
      requestId: requestId,
      sessionId: sessionId,
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
  CommandOutcomeLoader? outcomeLoader,
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
        final loaded = await (loader?.call(call) ?? Future.value([permission]));
        return (interactions: loaded, queriedInstanceIds: null);
      }),
      permissionDecisionSenderProvider.overrideWithValue(sender),
      commandOutcomeLoaderProvider.overrideWithValue(
        outcomeLoader ?? ScriptedOutcomeLoader().call,
      ),
      commandIdGeneratorProvider.overrideWithValue(commandId ?? () => 'cmd-1'),
    ],
  );
}

void main() {
  const authenticated = Authenticated(
    accessToken: 'access-1',
    email: 'user@example.com',
  );

  test('a gateway without remote unblock exposes an empty workbench', () async {
    final api = MockPendingApi();
    final request = RequestOptions(path: '/v1/pending-interactions');
    when(() => api.getPendingInteractions()).thenThrow(
      DioException(
        requestOptions: request,
        response: Response<void>(requestOptions: request, statusCode: 404),
        type: DioExceptionType.badResponse,
      ),
    );
    final container = ProviderContainer(
      overrides: [pendingApiProvider.overrideWithValue(api)],
    );
    addTearDown(container.dispose);

    final snapshot = await container.read(pendingInteractionLoaderProvider)();

    expect(snapshot.interactions, isEmpty);
    expect(snapshot.queriedInstanceIds, isEmpty);
  });

  test('pending snapshot loader still exposes gateway failures', () async {
    final api = MockPendingApi();
    final request = RequestOptions(path: '/v1/pending-interactions');
    when(() => api.getPendingInteractions()).thenThrow(
      DioException(
        requestOptions: request,
        response: Response<void>(requestOptions: request, statusCode: 500),
        type: DioExceptionType.badResponse,
      ),
    );
    final container = ProviderContainer(
      overrides: [pendingApiProvider.overrideWithValue(api)],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(pendingInteractionLoaderProvider)(),
      throwsA(isA<DioException>()),
    );
  });

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
          return (
            interactions: const <PendingInteraction>[],
            queriedInstanceIds: null,
          );
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
          return (interactions: [newer, older], queriedInstanceIds: null);
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
            return (
              interactions: [
                interaction('request', DateTime.utc(2026, 8, 14, 9)),
              ],
              queriedInstanceIds: null,
            );
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
          return (
            interactions: const <PendingInteraction>[],
            queriedInstanceIds: null,
          );
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
          return (
            interactions: [
              interaction('request-$calls', DateTime.utc(2026, 8, 14, 9)),
            ],
            queriedInstanceIds: null,
          );
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
            if (calls == 1) {
              return (
                interactions: const <PendingInteraction>[],
                queriedInstanceIds: null,
              );
            }
            final loaded = await delayed.future;
            return (interactions: loaded, queriedInstanceIds: null);
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

    test('submits session-scoped answers and accepted removes the interaction '
        'without refreshing authority', () async {
      final sender = ScriptedAnswerSender()
        ..outcome = QuestionAnswerOutcome.accepted;
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
      expect(sent.sessionId, question.sessionId);
      expect(sent.answers, [
        ['PostgreSQL'],
        ['Migrate data', 'Add indexes'],
      ]);
      expect(loads, 1);
      expect(
        container.read(questionSubmissionStatesProvider)['question-1'],
        QuestionSubmissionState.sent,
      );
      expect(container.read(pendingInteractionsProvider).requireValue, isEmpty);
    });

    test('accepted removal is durable across a later authoritative refresh', () async {
      final sender = ScriptedAnswerSender()
        ..outcome = QuestionAnswerOutcome.accepted;
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

      // The gateway accepted best-effort delivery: no reconcile happened and
      // the request left the workbench without a second loader call.
      expect(loads, 1);
      expect(container.read(pendingInteractionsProvider).requireValue, isEmpty);

      // A later authoritative snapshot still carrying the request must not
      // re-populate the workbench with an already-submitted interaction.
      await container.read(pendingInteractionsProvider.notifier).refresh();
      expect(loads, 2);
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
      'result unknown keeps the interaction visible and re-reads the snapshot',
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

        expect(loads, 2);
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
      'a 409 gateway rejection is presented as handled elsewhere and re-reads',
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
          QuestionSubmissionState.handledElsewhere,
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
      'a generic 4xx gateway rejection keeps the interaction and re-reads',
      () async {
        final sender = ScriptedAnswerSender()
          ..throwError = DioException(
            requestOptions: RequestOptions(
              path: '/v1/pending-interactions/i/questions/q/answer',
            ),
            response: Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 400,
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
      'a transport failure keeps the interaction as result unknown and re-reads '
      'the snapshot',
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

        expect(loads, 2);
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

    test('an unexpected sender failure keeps the interaction as unknown and '
        're-reads the snapshot', () async {
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

      expect(loads, 2);
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
    });

    test('a result unknown outcome whose recorded status is confirmed removes '
        'the interaction and re-reads authority', () async {
      final sender = ScriptedAnswerSender()
        ..outcome = QuestionAnswerOutcome.resultUnknown;
      final outcome = ScriptedOutcomeLoader()
        ..result = const CommandOutcomeInfo(
          status: CommandOutcomeStatus.confirmed,
          kind: CommandOutcomeKind.question,
        );
      var loads = 0;
      final container = answerContainer(
        question: question,
        sender: sender.call,
        outcomeLoader: outcome.call,
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
              ['Migrate data'],
            ],
          );

      expect(sender.calls, 1);
      expect(outcome.queried, ['cmd-1']);
      expect(loads, 2);
      expect(
        container.read(questionSubmissionStatesProvider)['question-1'],
        QuestionSubmissionState.confirmed,
      );
      expect(container.read(pendingInteractionsProvider).requireValue, isEmpty);
    });

    test('a result unknown outcome whose recorded status is stale is presented '
        'as handled elsewhere and re-reads authority', () async {
      final sender = ScriptedAnswerSender()
        ..outcome = QuestionAnswerOutcome.resultUnknown;
      final outcome = ScriptedOutcomeLoader()
        ..result = const CommandOutcomeInfo(
          status: CommandOutcomeStatus.stale,
          kind: CommandOutcomeKind.question,
        );
      var loads = 0;
      final container = answerContainer(
        question: question,
        sender: sender.call,
        outcomeLoader: outcome.call,
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

      expect(sender.calls, 1);
      expect(outcome.queried, ['cmd-1']);
      expect(loads, 2);
      expect(
        container.read(questionSubmissionStatesProvider)['question-1'],
        QuestionSubmissionState.handledElsewhere,
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

    test('a result unknown outcome that resolves to an upstream error re-reads '
        'authority', () async {
      final sender = ScriptedAnswerSender()
        ..outcome = QuestionAnswerOutcome.resultUnknown;
      final outcome = ScriptedOutcomeLoader()
        ..result = const CommandOutcomeInfo(
          status: CommandOutcomeStatus.upstreamError,
          kind: CommandOutcomeKind.question,
        );
      var loads = 0;
      final container = answerContainer(
        question: question,
        sender: sender.call,
        outcomeLoader: outcome.call,
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

      expect(sender.calls, 1);
      expect(outcome.queried, ['cmd-1']);
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
    });

    test('a result unknown outcome that resolves accepted stays result unknown '
        'and re-reads authority', () async {
      final sender = ScriptedAnswerSender()
        ..outcome = QuestionAnswerOutcome.resultUnknown;
      final outcome = ScriptedOutcomeLoader()
        ..result = const CommandOutcomeInfo(
          status: CommandOutcomeStatus.accepted,
          kind: CommandOutcomeKind.question,
        );
      var loads = 0;
      final container = answerContainer(
        question: question,
        sender: sender.call,
        outcomeLoader: outcome.call,
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

      expect(sender.calls, 1);
      expect(outcome.queried, ['cmd-1']);
      expect(loads, 2);
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
    });

    test('a 404 on the outcome query keeps the request as result unknown and '
        're-reads authority', () async {
      final sender = ScriptedAnswerSender()
        ..outcome = QuestionAnswerOutcome.resultUnknown;
      final outcome = ScriptedOutcomeLoader()
        ..throwError = DioException(
          requestOptions: RequestOptions(
            path: '/v1/pending-interactions/commands/cmd-1',
          ),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 404,
          ),
          type: DioExceptionType.badResponse,
        );
      var loads = 0;
      final container = answerContainer(
        question: question,
        sender: sender.call,
        outcomeLoader: outcome.call,
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

      expect(outcome.queried, ['cmd-1']);
      expect(loads, 2);
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
    });

    test('a transport failure on the outcome query keeps the request as result '
        'unknown and re-reads authority', () async {
      final sender = ScriptedAnswerSender()
        ..outcome = QuestionAnswerOutcome.resultUnknown;
      final outcome = ScriptedOutcomeLoader()
        ..throwError = DioException(
          requestOptions: RequestOptions(
            path: '/v1/pending-interactions/commands/cmd-1',
          ),
          type: DioExceptionType.connectionError,
          error: 'no network',
        );
      var loads = 0;
      final container = answerContainer(
        question: question,
        sender: sender.call,
        outcomeLoader: outcome.call,
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

      expect(outcome.queried, ['cmd-1']);
      expect(loads, 2);
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
    });

    test('a cache-expiry 404 on the outcome query converges when the fresh '
        'snapshot lacks the request', () async {
      final sender = ScriptedAnswerSender()
        ..outcome = QuestionAnswerOutcome.resultUnknown;
      final outcome = ScriptedOutcomeLoader()
        ..throwError = DioException(
          requestOptions: RequestOptions(
            path: '/v1/pending-interactions/commands/cmd-1',
          ),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 404,
          ),
          type: DioExceptionType.badResponse,
        );
      var loads = 0;
      final container = answerContainer(
        question: question,
        sender: sender.call,
        outcomeLoader: outcome.call,
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
              ['Migrate data'],
            ],
          );

      expect(sender.calls, 1);
      expect(outcome.queried, ['cmd-1']);
      expect(loads, 2);
      expect(
        container.read(questionSubmissionStatesProvider)['question-1'],
        QuestionSubmissionState.resultUnknown,
      );
      expect(container.read(pendingInteractionsProvider).requireValue, isEmpty);
    });

    test('an unknown outcome queries the same command id once and never '
        'auto-retries', () async {
      final sender = ScriptedAnswerSender()
        ..outcome = QuestionAnswerOutcome.resultUnknown;
      final outcome = ScriptedOutcomeLoader()
        ..result = const CommandOutcomeInfo(
          status: CommandOutcomeStatus.resultUnknown,
          kind: CommandOutcomeKind.question,
        );
      final container = answerContainer(
        question: question,
        sender: sender.call,
        outcomeLoader: outcome.call,
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

      expect(sender.calls, 1);
      expect(outcome.calls, 1);
      expect(outcome.queried, ['cmd-1']);
      expect(
        container.read(questionSubmissionStatesProvider)['question-1'],
        QuestionSubmissionState.resultUnknown,
      );
    });
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

    test('submits the session-scoped decision and accepted removes the '
        'interaction without refreshing authority', () async {
      final sender = ScriptedDecisionSender()
        ..outcome = PermissionDecisionOutcome.accepted;
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
      expect(sent.sessionId, pendingPermission.sessionId);
      expect(sent.decision, PermissionDecision.once);
      expect(loads, 1);
      expect(
        container.read(permissionSubmissionStatesProvider)['permission-1'],
        PermissionDecisionState.sent,
      );
      expect(container.read(pendingInteractionsProvider).requireValue, isEmpty);
    });

    test('accepted removal is durable across a later authoritative refresh', () async {
      final sender = ScriptedDecisionSender()
        ..outcome = PermissionDecisionOutcome.accepted;
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

      // The gateway accepted best-effort delivery: no reconcile happened and
      // the request left the workbench without a second loader call.
      expect(loads, 1);
      expect(container.read(pendingInteractionsProvider).requireValue, isEmpty);

      // A later authoritative snapshot still carrying the request must not
      // re-populate the workbench with an already-submitted interaction.
      await container.read(pendingInteractionsProvider.notifier).refresh();
      expect(loads, 2);
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
      'result unknown keeps the interaction visible and re-reads the snapshot',
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

        expect(loads, 2);
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
      'a 409 gateway rejection is presented as handled elsewhere and re-reads',
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
          PermissionDecisionState.handledElsewhere,
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
      'a generic 4xx gateway rejection keeps the interaction and re-reads',
      () async {
        final sender = ScriptedDecisionSender()
          ..throwError = DioException(
            requestOptions: RequestOptions(
              path: '/v1/pending-interactions/i/permissions/p/decision',
            ),
            response: Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 400,
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
      'a transport failure keeps the interaction as result unknown and re-reads '
      'the snapshot',
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

        expect(loads, 2);
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

    test('an unexpected sender failure keeps the interaction as unknown and '
        're-reads the snapshot', () async {
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

      expect(loads, 2);
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
    });

    test('a cache-expiry 404 on the outcome query converges while the request '
        'is still pending', () async {
      final sender = ScriptedDecisionSender()
        ..outcome = PermissionDecisionOutcome.resultUnknown;
      final outcome = ScriptedOutcomeLoader()
        ..throwError = DioException(
          requestOptions: RequestOptions(
            path: '/v1/pending-interactions/commands/cmd-1',
          ),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 404,
          ),
          type: DioExceptionType.badResponse,
        );
      var loads = 0;
      final container = decisionContainer(
        permission: pendingPermission,
        sender: sender.call,
        outcomeLoader: outcome.call,
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

      expect(sender.calls, 1);
      expect(outcome.queried, ['cmd-1']);
      expect(loads, 2);
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
    });

    test('a result unknown decision whose recorded status is confirmed removes '
        'the interaction and re-reads authority', () async {
      final sender = ScriptedDecisionSender()
        ..outcome = PermissionDecisionOutcome.resultUnknown;
      final outcome = ScriptedOutcomeLoader()
        ..result = const CommandOutcomeInfo(
          status: CommandOutcomeStatus.confirmed,
          kind: CommandOutcomeKind.permission,
        );
      var loads = 0;
      final container = decisionContainer(
        permission: pendingPermission,
        sender: sender.call,
        outcomeLoader: outcome.call,
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
      expect(outcome.queried, ['cmd-1']);
      expect(loads, 2);
      expect(
        container.read(permissionSubmissionStatesProvider)['permission-1'],
        PermissionDecisionState.confirmed,
      );
      expect(container.read(pendingInteractionsProvider).requireValue, isEmpty);
    });

    test(
      'a result unknown decision whose recorded status is stale is presented '
      'as handled elsewhere and re-reads authority',
      () async {
        final sender = ScriptedDecisionSender()
          ..outcome = PermissionDecisionOutcome.resultUnknown;
        final outcome = ScriptedOutcomeLoader()
          ..result = const CommandOutcomeInfo(
            status: CommandOutcomeStatus.stale,
            kind: CommandOutcomeKind.permission,
          );
        var loads = 0;
        final container = decisionContainer(
          permission: pendingPermission,
          sender: sender.call,
          outcomeLoader: outcome.call,
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

        expect(sender.calls, 1);
        expect(outcome.queried, ['cmd-1']);
        expect(loads, 2);
        expect(
          container.read(permissionSubmissionStatesProvider)['permission-1'],
          PermissionDecisionState.handledElsewhere,
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
              return (
                interactions: [
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
                ],
                queriedInstanceIds: null,
              );
            }
            return (
              interactions: [
                interactionOn(
                  instanceId: 'inst-a',
                  id: 'a2',
                  occurredAt: DateTime.utc(2026, 8, 14, 9, 2),
                ),
              ],
              queriedInstanceIds: null,
            );
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
            return (
              interactions: [
                interactionOn(
                  instanceId: 'inst-a',
                  id: 'a',
                  occurredAt: DateTime.utc(2026, 8, 14, 9),
                ),
              ],
              queriedInstanceIds: null,
            );
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

    test('a reconnect with zero pending clears the stale last-known', () async {
      var calls = 0;
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(
            () => MutableAuthController(authenticated),
          ),
          pendingInteractionLoaderProvider.overrideWithValue(() async {
            calls++;
            return calls == 1
                ? (
                    interactions: [
                      interactionOn(
                        instanceId: 'inst-a',
                        id: 'a',
                        occurredAt: DateTime.utc(2026, 8, 14, 9),
                      ),
                    ],
                    queriedInstanceIds: null,
                  )
                : (
                    interactions: const <PendingInteraction>[],
                    queriedInstanceIds: null,
                  );
          }),
        ],
      );
      addTearDown(container.dispose);

      await container.read(pendingInteractionsProvider.future);
      final controller = container.read(pendingInteractionsProvider.notifier);
      expect(controller.lastKnownByInstance['inst-a']!.single.requestId, 'a');

      container.read(instancePresencesProvider.notifier).replaceAll([
        presence('inst-a', InstancePresenceState.controllable),
      ]);
      await container.read(pendingInteractionsProvider.future);

      expect(controller.lastKnownByInstance['inst-a'], isEmpty);
    });

    test(
      'a reconnect with restored requests replaces the last-known',
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
                  ? (
                      interactions: [
                        interactionOn(
                          instanceId: 'inst-a',
                          id: 'a',
                          occurredAt: DateTime.utc(2026, 8, 14, 9),
                        ),
                      ],
                      queriedInstanceIds: null,
                    )
                  : (
                      interactions: [
                        interactionOn(
                          instanceId: 'inst-a',
                          id: 'a2',
                          occurredAt: DateTime.utc(2026, 8, 14, 9, 2),
                        ),
                      ],
                      queriedInstanceIds: null,
                    );
            }),
          ],
        );
        addTearDown(container.dispose);

        await container.read(pendingInteractionsProvider.future);
        final controller = container.read(pendingInteractionsProvider.notifier);
        expect(controller.lastKnownByInstance['inst-a']!.single.requestId, 'a');

        container.read(instancePresencesProvider.notifier).replaceAll([
          presence('inst-a', InstancePresenceState.controllable),
        ]);
        await container.read(pendingInteractionsProvider.future);

        expect(
          controller.lastKnownByInstance['inst-a']!.single.requestId,
          'a2',
        );
      },
    );

    test(
      'offline instances keep their last-known while others refresh',
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
                  ? (
                      interactions: [
                        interactionOn(
                          instanceId: 'inst-a',
                          id: 'a',
                          occurredAt: DateTime.utc(2026, 8, 14, 9),
                        ),
                      ],
                      queriedInstanceIds: null,
                    )
                  : (
                      interactions: const <PendingInteraction>[],
                      queriedInstanceIds: null,
                    );
            }),
          ],
        );
        addTearDown(container.dispose);

        container.read(instancePresencesProvider.notifier).replaceAll([
          presence('inst-a', InstancePresenceState.offline),
        ]);
        await container.read(pendingInteractionsProvider.future);
        final controller = container.read(pendingInteractionsProvider.notifier);
        expect(controller.lastKnownByInstance['inst-a']!.single.requestId, 'a');

        await controller.refresh();

        expect(controller.lastKnownByInstance['inst-a']!.single.requestId, 'a');
      },
    );

    test('a gateway exclusion wins over stale presence: the instance keeps its '
        'last-known while presence still shows it controllable', () async {
      var calls = 0;
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(
            () => MutableAuthController(authenticated),
          ),
          pendingInteractionLoaderProvider.overrideWithValue(() async {
            calls++;
            return calls == 1
                ? (
                    interactions: [
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
                    ],
                    queriedInstanceIds: {'inst-a', 'inst-b'},
                  )
                : (
                    interactions: [
                      interactionOn(
                        instanceId: 'inst-a',
                        id: 'a2',
                        occurredAt: DateTime.utc(2026, 8, 14, 9, 2),
                      ),
                    ],
                    queriedInstanceIds: {'inst-a'},
                  );
          }),
        ],
      );
      addTearDown(container.dispose);

      await container.read(pendingInteractionsProvider.future);
      final controller = container.read(pendingInteractionsProvider.notifier);
      expect(controller.lastKnownByInstance['inst-a']!.single.requestId, 'a');
      expect(controller.lastKnownByInstance['inst-b']!.single.requestId, 'b');

      // The gateway stopped querying inst-b while a stale presence still
      // shows it controllable. The gateway set is authoritative: inst-b is
      // not re-included by presence, so its last-known survives for the
      // offline read-only view instead of being wrongly cleared.
      container.read(instancePresencesProvider.notifier).replaceAll([
        presence('inst-a', InstancePresenceState.controllable),
        presence('inst-b', InstancePresenceState.controllable),
      ]);
      await container.read(pendingInteractionsProvider.future);

      expect(controller.lastKnownByInstance['inst-a']!.single.requestId, 'a2');
      expect(controller.lastKnownByInstance['inst-b']!.single.requestId, 'b');
    });

    test('an empty snapshot under the gateway queried set clears the retained '
        'last-known', () async {
      var calls = 0;
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(
            () => MutableAuthController(authenticated),
          ),
          pendingInteractionLoaderProvider.overrideWithValue(() async {
            calls++;
            return calls == 1
                ? (
                    interactions: [
                      interactionOn(
                        instanceId: 'inst-a',
                        id: 'a',
                        occurredAt: DateTime.utc(2026, 8, 14, 9),
                      ),
                    ],
                    queriedInstanceIds: {'inst-a'},
                  )
                : (
                    interactions: const <PendingInteraction>[],
                    queriedInstanceIds: {'inst-a'},
                  );
          }),
        ],
      );
      addTearDown(container.dispose);

      await container.read(pendingInteractionsProvider.future);
      final controller = container.read(pendingInteractionsProvider.notifier);
      expect(controller.lastKnownByInstance['inst-a']!.single.requestId, 'a');

      await controller.refresh();

      expect(controller.lastKnownByInstance['inst-a'], isEmpty);
    });

    test(
      'instances outside the gateway queried set keep their last-known',
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
                  ? (
                      interactions: [
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
                      ],
                      queriedInstanceIds: {'inst-a', 'inst-b'},
                    )
                  : (
                      interactions: [
                        interactionOn(
                          instanceId: 'inst-a',
                          id: 'a2',
                          occurredAt: DateTime.utc(2026, 8, 14, 9, 2),
                        ),
                      ],
                      queriedInstanceIds: {'inst-a'},
                    );
            }),
          ],
        );
        addTearDown(container.dispose);

        await container.read(pendingInteractionsProvider.future);
        final controller = container.read(pendingInteractionsProvider.notifier);
        expect(controller.lastKnownByInstance['inst-a']!.single.requestId, 'a');
        expect(controller.lastKnownByInstance['inst-b']!.single.requestId, 'b');

        await controller.refresh();

        expect(
          controller.lastKnownByInstance['inst-a']!.single.requestId,
          'a2',
        );
        expect(controller.lastKnownByInstance['inst-b']!.single.requestId, 'b');
      },
    );

    test('without the gateway queried field the presence-derived set is the '
        'fallback', () async {
      var calls = 0;
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(
            () => MutableAuthController(authenticated),
          ),
          pendingInteractionLoaderProvider.overrideWithValue(() async {
            calls++;
            return calls == 1
                ? (
                    interactions: [
                      interactionOn(
                        instanceId: 'inst-a',
                        id: 'a',
                        occurredAt: DateTime.utc(2026, 8, 14, 9),
                      ),
                    ],
                    queriedInstanceIds: null,
                  )
                : (
                    interactions: const <PendingInteraction>[],
                    queriedInstanceIds: null,
                  );
          }),
        ],
      );
      addTearDown(container.dispose);

      await container.read(pendingInteractionsProvider.future);
      final controller = container.read(pendingInteractionsProvider.notifier);
      expect(controller.lastKnownByInstance['inst-a']!.single.requestId, 'a');

      // A controllable presence drives the fallback queried set, so the
      // reconnected instance with zero pending is cleared.
      container.read(instancePresencesProvider.notifier).replaceAll([
        presence('inst-a', InstancePresenceState.controllable),
      ]);
      await container.read(pendingInteractionsProvider.future);

      expect(controller.lastKnownByInstance['inst-a'], isEmpty);
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
              return (
                interactions: [
                  interactionOn(
                    instanceId: 'inst-a',
                    id: 'a',
                    occurredAt: DateTime.utc(2026, 8, 14, 9),
                  ),
                ],
                queriedInstanceIds: null,
              );
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
                  ? (
                      interactions: [
                        interactionOn(
                          instanceId: 'inst-a',
                          id: 'a',
                          occurredAt: DateTime.utc(2026, 8, 14, 9),
                        ),
                      ],
                      queriedInstanceIds: null,
                    )
                  : (
                      interactions: const <PendingInteraction>[],
                      queriedInstanceIds: null,
                    );
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
            return (
              interactions: [
                interactionOn(
                  instanceId: 'inst-a',
                  id: 'a',
                  occurredAt: DateTime.utc(2026, 8, 14, 9),
                ),
              ],
              queriedInstanceIds: null,
            );
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
