import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notify_api/notify_api.dart' show AnswerQuestionBody, PendingApi;
import 'package:uuid/uuid.dart';

import '../auth/auth_controller.dart';
import '../auth/auth_state.dart';
import '../realtime/instance_presence.dart';
import 'pending_answer.dart';
import 'pending_interaction.dart';

final pendingApiProvider = Provider<PendingApi>(
  (ref) => ref.watch(apiClientProvider).notifyApi.getPendingApi(),
);

typedef PendingInteractionLoader = Future<List<PendingInteraction>> Function();

final pendingInteractionLoaderProvider = Provider<PendingInteractionLoader>((
  ref,
) {
  final api = ref.watch(pendingApiProvider);
  return () async {
    final response = await api.getPendingInteractions();
    final snapshot = response.data;
    if (snapshot == null) {
      throw StateError('Empty pending-interactions response');
    }
    return snapshot.interactions.map(PendingInteraction.fromGenerated).toList();
  };
});

final pendingInteractionsProvider =
    AsyncNotifierProvider<
      PendingInteractionsController,
      List<PendingInteraction>
    >(PendingInteractionsController.new);

/// Per-request submission lifecycle for answering a pending question. The
/// workbench and the focused page read this to show submitting and result
/// states without sending or rejecting anything on navigation.
final questionSubmissionStatesProvider =
    NotifierProvider<
      QuestionSubmissionStates,
      Map<String, QuestionSubmissionState>
    >(QuestionSubmissionStates.new);

class QuestionSubmissionStates
    extends Notifier<Map<String, QuestionSubmissionState>> {
  @override
  Map<String, QuestionSubmissionState> build() => const {};

  void reset(String requestId) {
    final next = Map<String, QuestionSubmissionState>.from(state);
    next.remove(requestId);
    state = next;
  }

  void mark(String requestId, QuestionSubmissionState value) {
    final next = Map<String, QuestionSubmissionState>.from(state);
    next[requestId] = value;
    state = next;
  }
}

typedef CommandIdGenerator = String Function();

/// Generates a unique client command id for each question submission. The
/// gateway correlates its terminal outcome back to this id.
final commandIdGeneratorProvider = Provider<CommandIdGenerator>((ref) {
  const uuid = Uuid();
  return uuid.v4;
});

typedef QuestionAnswerSender =
    Future<QuestionAnswerResult> Function({
      required String instanceId,
      required String requestId,
      required String commandId,
      required List<List<String>> answers,
    });

/// Submits one complete ordered answer set through the generated
/// [PendingApi.answerQuestion] and maps the gateway's terminal outcome.
/// Gateway 4xx errors surface as a thrown [DioException].
final questionAnswerSenderProvider = Provider<QuestionAnswerSender>((ref) {
  final api = ref.watch(pendingApiProvider);
  return ({
    required instanceId,
    required requestId,
    required commandId,
    required answers,
  }) async {
    final response = await api.answerQuestion(
      instanceId: instanceId,
      requestId: requestId,
      answerQuestionBody: AnswerQuestionBody((b) {
        b.commandId = commandId;
        b.answers.replace([
          for (final answer in answers) BuiltList<String>.of(answer),
        ]);
      }),
    );
    final data = response.data;
    if (data == null) {
      throw StateError('Empty answer-question response');
    }
    return QuestionAnswerResult(
      commandId: data.commandId,
      outcome: questionAnswerOutcomeFromStatus(data.status),
    );
  };
});

class PendingInteractionsController
    extends AsyncNotifier<List<PendingInteraction>> {
  bool _building = false;
  bool _refreshQueued = false;
  Future<void>? _activeRefresh;
  int _epoch = 0;

  @override
  Future<List<PendingInteraction>> build() async {
    _epoch++;
    _building = true;
    _refreshQueued = false;
    final auth = ref.watch(authControllerProvider);
    ref.listen(instancePresencesProvider, (previous, next) {
      if (_actionableSignature(previous) != _actionableSignature(next)) {
        if (_building) {
          _refreshQueued = true;
        } else {
          unawaited(refresh());
        }
      }
    });
    if (auth is! Authenticated) {
      _building = false;
      return const [];
    }
    try {
      return await _fetch();
    } finally {
      _building = false;
      if (_refreshQueued) {
        scheduleMicrotask(() => unawaited(refresh()));
      }
    }
  }

  Future<void> refresh() {
    if (_building) {
      _refreshQueued = true;
      return Future.value();
    }
    final active = _activeRefresh;
    if (active != null) {
      _refreshQueued = true;
      return active;
    }
    final operation = _runRefreshLoop();
    _activeRefresh = operation;
    return operation.whenComplete(() {
      _activeRefresh = null;
      if (_refreshQueued && !_building) {
        unawaited(refresh());
      }
    });
  }

  Future<void> _runRefreshLoop() async {
    final epoch = _epoch;
    if (ref.read(authControllerProvider) is! Authenticated) {
      state = const AsyncData([]);
      return;
    }
    do {
      _refreshQueued = false;
      state = const AsyncLoading<List<PendingInteraction>>();
      final next = await AsyncValue.guard(_fetch);
      if (epoch != _epoch ||
          ref.read(authControllerProvider) is! Authenticated) {
        return;
      }
      state = next;
    } while (_refreshQueued &&
        ref.read(authControllerProvider) is Authenticated);
  }

  Future<List<PendingInteraction>> _fetch() async {
    final interactions = [
      ...await ref.read(pendingInteractionLoaderProvider)(),
    ];
    interactions.sort((left, right) {
      final byTime = left.occurredAt.compareTo(right.occurredAt);
      if (byTime != 0) return byTime;
      final byInstance = left.instanceId.compareTo(right.instanceId);
      if (byInstance != 0) return byInstance;
      return left.requestId.compareTo(right.requestId);
    });
    return interactions;
  }

  /// Submits [answers] for [question] with a fresh client-generated command
  /// id and drives the per-request submission state.
  ///
  /// Only a confirmed outcome removes the request from the workbench;
  /// stale, upstream-error, and gateway-rejected outcomes keep it and trigger
  /// an authoritative snapshot re-read, while unknown and transport failures
  /// keep it visible without re-reading. Gateway 4xx rejections never remove
  /// the request and never propagate.
  Future<void> answerQuestion({
    required PendingQuestion question,
    required List<List<String>> answers,
  }) async {
    final requestId = question.requestId;
    final commandId = ref.read(commandIdGeneratorProvider)();
    _markSubmission(requestId, QuestionSubmissionState.submitting);
    try {
      final result = await ref.read(questionAnswerSenderProvider)(
        instanceId: question.instanceId,
        requestId: requestId,
        commandId: commandId,
        answers: answers,
      );
      switch (result.outcome) {
        case QuestionAnswerOutcome.confirmed:
          _markSubmission(requestId, QuestionSubmissionState.confirmed);
          _removeInteraction(requestId);
          await reconcile();
        case QuestionAnswerOutcome.stale:
          _markSubmission(requestId, QuestionSubmissionState.stale);
          await reconcile();
        case QuestionAnswerOutcome.upstreamError:
          _markSubmission(requestId, QuestionSubmissionState.upstreamError);
          await reconcile();
        case QuestionAnswerOutcome.resultUnknown:
          _markSubmission(requestId, QuestionSubmissionState.resultUnknown);
      }
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      if (statusCode != null && statusCode >= 400 && statusCode < 500) {
        _markSubmission(requestId, QuestionSubmissionState.rejected);
        await reconcile();
      } else {
        _markSubmission(requestId, QuestionSubmissionState.resultUnknown);
      }
    } catch (_) {
      _markSubmission(requestId, QuestionSubmissionState.resultUnknown);
    }
  }

  /// Refetches the authoritative snapshot and replaces the list without first
  /// clearing current data. Queues behind an in-flight [refresh].
  Future<void> reconcile() async {
    if (_building) {
      _refreshQueued = true;
      return;
    }
    final active = _activeRefresh;
    if (active != null) {
      _refreshQueued = true;
      await active;
      return;
    }
    final epoch = _epoch;
    if (ref.read(authControllerProvider) is! Authenticated) {
      state = const AsyncData([]);
      return;
    }
    final next = await AsyncValue.guard(_fetch);
    if (epoch != _epoch || ref.read(authControllerProvider) is! Authenticated) {
      return;
    }
    state = next;
  }

  void _removeInteraction(String requestId) {
    final current = state.value ?? const <PendingInteraction>[];
    state = AsyncData([
      for (final interaction in current)
        if (interaction.requestId != requestId) interaction,
    ]);
  }

  void _markSubmission(String requestId, QuestionSubmissionState value) {
    ref.read(questionSubmissionStatesProvider.notifier).mark(requestId, value);
  }

  static String _actionableSignature(
    Map<String, OpenCodeInstancePresence>? instances,
  ) {
    if (instances == null) return '';
    final values =
        instances.values
            .where(
              (instance) =>
                  instance.state == InstancePresenceState.controllable,
            )
            .map(
              (instance) =>
                  '${instance.instanceId}:${instance.lastSeenAt.toIso8601String()}',
            )
            .toList()
          ..sort();
    return values.join('|');
  }
}
