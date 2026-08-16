import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notify_api/notify_api.dart'
    show
        AnswerQuestionBody,
        DecidePermissionBody,
        DecidePermissionBodyDecisionEnum,
        PendingApi,
        PendingSnapshot;
import 'package:uuid/uuid.dart';

import '../auth/auth_controller.dart';
import '../auth/auth_state.dart';
import '../realtime/instance_presence.dart';
import 'command_outcome.dart';
import 'pending_answer.dart';
import 'pending_interaction.dart';
import 'pending_permission.dart';

final pendingApiProvider = Provider<PendingApi>(
  (ref) => ref.watch(apiClientProvider).notifyApi.getPendingApi(),
);

typedef CommandOutcomeLoader =
    Future<CommandOutcomeInfo> Function(String commandId);

/// Queries the gateway's body-free in-memory outcome for a client-generated
/// [commandId] and maps it to the domain [CommandOutcomeInfo]. The outcome
/// carries only correlation and status metadata — never the question answers
/// or the permission decision. A missing/expired correlation (404) or a
/// transport failure surfaces as a thrown [DioException].
final commandOutcomeLoaderProvider = Provider<CommandOutcomeLoader>((ref) {
  final api = ref.watch(pendingApiProvider);
  return (commandId) async {
    final response = await api.getCommandOutcome(commandId: commandId);
    final data = response.data;
    if (data == null) {
      throw StateError('Empty command-outcome response');
    }
    return commandOutcomeFromGenerated(data);
  };
});

/// One authoritative pending-interactions snapshot: the interactions plus the
/// gateway's raw queried instance set. [queriedInstanceIds] is null when the
/// generated snapshot omitted the field, signaling the presence-derived
/// fallback for the queried scope.
typedef PendingSnapshotLoad = ({
  List<PendingInteraction> interactions,
  Set<String>? queriedInstanceIds,
});

typedef PendingInteractionLoader = Future<PendingSnapshotLoad> Function();

final pendingInteractionLoaderProvider = Provider<PendingInteractionLoader>((
  ref,
) {
  final api = ref.watch(pendingApiProvider);
  return () async {
    final Response<PendingSnapshot> response;
    try {
      response = await api.getPendingInteractions();
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        // Production gateways from before remote-unblock phase 1 have no
        // pending snapshot route. Existing notification features remain usable.
        return (
          interactions: const <PendingInteraction>[],
          queriedInstanceIds: const <String>{},
        );
      }
      rethrow;
    }
    final snapshot = response.data;
    if (snapshot == null) {
      throw StateError('Empty pending-interactions response');
    }
    return (
      interactions: snapshot.interactions
          .map(PendingInteraction.fromGenerated)
          .toList(),
      queriedInstanceIds: snapshot.queriedInstanceIds?.toSet(),
    );
  };
});

final pendingInteractionsProvider =
    AsyncNotifierProvider<
      PendingInteractionsController,
      List<PendingInteraction>
    >(PendingInteractionsController.new);

/// One last-known pending interaction of an offline instance, wrapped with
/// the instance's last-online time for read-only display.
class OfflinePendingInteraction {
  const OfflinePendingInteraction({
    required this.interaction,
    required this.lastSeenAt,
  });

  final PendingInteraction interaction;
  final DateTime lastSeenAt;
}

/// Read-only last-known requests of instances that are currently offline.
///
/// Watches the presence projection and the pending snapshot: for every
/// instance whose presence state is [InstancePresenceState.offline], the
/// current snapshot's items are merged with the controller's retained
/// last-known (which survives the instance leaving a snapshot), deduplicated
/// by request id, and wrapped with the instance's last-online time.
final offlineLastKnownProvider = Provider<List<OfflinePendingInteraction>>((
  ref,
) {
  final instances = ref.watch(instancePresencesProvider);
  final snapshot = ref.watch(pendingInteractionsProvider);
  final lastKnown = ref
      .watch(pendingInteractionsProvider.notifier)
      .lastKnownByInstance;
  final offline = <OfflinePendingInteraction>[];
  for (final presence in instances.values) {
    if (presence.state != InstancePresenceState.offline) {
      continue;
    }
    final seen = <String>{};
    final items = [
      ...?snapshot.value?.where(
        (item) => item.instanceId == presence.instanceId,
      ),
      ...?lastKnown[presence.instanceId],
    ];
    for (final interaction in items) {
      if (!seen.add(interaction.requestId)) {
        continue;
      }
      offline.add(
        OfflinePendingInteraction(
          interaction: interaction,
          lastSeenAt: presence.lastSeenAt,
        ),
      );
    }
  }
  return offline;
});

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

/// Per-request submission lifecycle for deciding a pending permission. The
/// workbench and the focused page read this to show submitting and result
/// states without sending or rejecting anything on navigation.
final permissionSubmissionStatesProvider =
    NotifierProvider<
      PermissionSubmissionStates,
      Map<String, PermissionDecisionState>
    >(PermissionSubmissionStates.new);

class PermissionSubmissionStates
    extends Notifier<Map<String, PermissionDecisionState>> {
  @override
  Map<String, PermissionDecisionState> build() => const {};

  void reset(String requestId) {
    final next = Map<String, PermissionDecisionState>.from(state);
    next.remove(requestId);
    state = next;
  }

  void mark(String requestId, PermissionDecisionState value) {
    final next = Map<String, PermissionDecisionState>.from(state);
    next[requestId] = value;
    state = next;
  }
}

typedef CommandIdGenerator = String Function();

/// Generates a unique client command id for each submission. The Gateway uses
/// it for delivery de-duplication and optional diagnostic outcome tracking.
final commandIdGeneratorProvider = Provider<CommandIdGenerator>((ref) {
  const uuid = Uuid();
  return uuid.v4;
});

typedef QuestionAnswerSender =
    Future<QuestionAnswerResult> Function({
      required String instanceId,
      required String requestId,
      required String sessionId,
      required String commandId,
      required List<List<String>> answers,
    });

/// Submits one complete ordered answer set through the generated
/// [PendingApi.answerQuestion]. A successful response is the Gateway's
/// immediate best-effort acceptance, not an OpenCode confirmation. Gateway
/// 4xx errors surface as a thrown [DioException].
final questionAnswerSenderProvider = Provider<QuestionAnswerSender>((ref) {
  final api = ref.watch(pendingApiProvider);
  return ({
    required instanceId,
    required requestId,
    required sessionId,
    required commandId,
    required answers,
  }) async {
    final response = await api.answerQuestion(
      instanceId: instanceId,
      requestId: requestId,
      answerQuestionBody: AnswerQuestionBody((b) {
        b.commandId = commandId;
        b.sessionId = sessionId;
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
      outcome: QuestionAnswerOutcome.accepted,
    );
  };
});

typedef PermissionDecisionSender =
    Future<PermissionDecisionResult> Function({
      required String instanceId,
      required String requestId,
      required String sessionId,
      required String commandId,
      required PermissionDecision decision,
    });

/// Submits one decision (allow once, always allow, or reject) through the
/// generated [PendingApi.decidePermission]. A successful response is the
/// Gateway's immediate best-effort acceptance, not an OpenCode confirmation.
/// Gateway 4xx errors surface as a thrown [DioException]. The page
/// sends [PermissionDecision.always] only after its confirmation dialog.
final permissionDecisionSenderProvider = Provider<PermissionDecisionSender>((
  ref,
) {
  final api = ref.watch(pendingApiProvider);
  return ({
    required instanceId,
    required requestId,
    required sessionId,
    required commandId,
    required decision,
  }) async {
    final response = await api.decidePermission(
      instanceId: instanceId,
      requestId: requestId,
      decidePermissionBody: DecidePermissionBody((b) {
        b.commandId = commandId;
        b.sessionId = sessionId;
        b.decision = switch (decision) {
          PermissionDecision.once => DecidePermissionBodyDecisionEnum.once,
          PermissionDecision.reject => DecidePermissionBodyDecisionEnum.reject,
          PermissionDecision.always => DecidePermissionBodyDecisionEnum.always,
        };
      }),
    );
    final data = response.data;
    if (data == null) {
      throw StateError('Empty decide-permission response');
    }
    return PermissionDecisionResult(
      commandId: data.commandId,
      outcome: PermissionDecisionOutcome.accepted,
    );
  };
});

/// How an unknown submission outcome resolved after querying the gateway's
/// body-free command correlation.
enum UnknownOutcomeResolution { confirmed, stale, upstreamError, unknown }

class PendingInteractionsController
    extends AsyncNotifier<List<PendingInteraction>> {
  bool _building = false;
  bool _refreshQueued = false;
  Future<void>? _activeRefresh;
  int _epoch = 0;

  /// Last-known interactions per instance, kept in memory only. Updated on
  /// every successful fetch; instances absent from a new snapshot keep their
  /// previous last-known requests so offline read-only views still work.
  /// Cleared on logout.
  final Map<String, List<PendingInteraction>> _lastKnownByInstance = {};

  /// Requests this controller has handed to the Gateway successfully. This is
  /// deliberately an in-memory, account-session suppression set: best-effort
  /// delivery may still fail upstream, but an accepted card does not reappear
  /// from a briefly stale snapshot. Logout clears the set.
  final Set<String> _submittedInteractionKeys = {};

  /// Unmodifiable view of the per-instance last-known retention.
  Map<String, List<PendingInteraction>> get lastKnownByInstance =>
      Map.unmodifiable(_lastKnownByInstance);

  /// The current authoritative snapshot value. Public read access to the
  /// notifier state for consumers (e.g. the notification navigation) that
  /// hold the controller directly instead of watching the provider.
  AsyncValue<List<PendingInteraction>> get current => state;

  /// Replaces the retention entry of every queried instance with the exact
  /// snapshot contents — including an empty list when the authoritative
  /// snapshot returned nothing — while preserving the entries of non-queried
  /// (offline) instances. The queried set is gateway-authoritative when the
  /// snapshot carried the queried instance ids; a reconnected instance with
  /// zero pending therefore deterministically clears its stale last-known, and
  /// an instance the gateway stopped querying keeps its last-known even when a
  /// stale presence still shows it controllable.
  void _retain(
    List<PendingInteraction> interactions,
    Set<String> queriedInstanceIds,
  ) {
    final byInstance = <String, List<PendingInteraction>>{};
    for (final interaction in interactions) {
      (byInstance[interaction.instanceId] ??= []).add(interaction);
    }
    // Snapshot instances were necessarily queried by the gateway, so they are
    // included alongside the authoritative queried set.
    for (final instanceId in {...queriedInstanceIds, ...byInstance.keys}) {
      _lastKnownByInstance[instanceId] = byInstance[instanceId] ?? const [];
    }
  }

  void _clearRetention() {
    _lastKnownByInstance.clear();
    _submittedInteractionKeys.clear();
  }

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
      _clearRetention();
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
      _clearRetention();
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
    final load = await ref.read(pendingInteractionLoaderProvider)();
    final interactions = [
      for (final interaction in load.interactions)
        if (!_submittedInteractionKeys.contains(
          _interactionKey(interaction.instanceId, interaction.requestId),
        ))
          interaction,
    ];
    interactions.sort((left, right) {
      final byTime = left.occurredAt.compareTo(right.occurredAt);
      if (byTime != 0) return byTime;
      final byInstance = left.instanceId.compareTo(right.instanceId);
      if (byInstance != 0) return byInstance;
      return left.requestId.compareTo(right.requestId);
    });
    _retain(interactions, load.queriedInstanceIds ?? _queriedInstanceIds());
    return interactions;
  }

  /// Presence-derived fallback for the set of instances the gateway queried:
  /// the currently controllable instances. Used only when the generated
  /// snapshot omitted the queried instance ids (backward compat). Offline,
  /// conflicting, incompatible, and unknown instances are never queried and
  /// keep their retained last-known.
  Set<String> _queriedInstanceIds() {
    final presences = ref.read(instancePresencesProvider);
    return {
      for (final presence in presences.values)
        if (presence.state == InstancePresenceState.controllable)
          presence.instanceId,
    };
  }

  /// Submits [answers] for [question] with a fresh client-generated command
  /// id and drives the per-request submission state.
  ///
  /// An accepted outcome marks the request sent and removes it optimistically
  /// without a snapshot re-read. Legacy terminal outcomes remain supported at
  /// this seam; stale,
  /// upstream-error, and gateway-rejected outcomes keep it and trigger an
  /// authoritative snapshot re-read. An unknown outcome — and a transport or
  /// unexpected failure — queries the same [commandId] once to converge on
  /// what the gateway recorded, never auto-retrying, then re-reads authority
  /// so the workbench reflects the fresh snapshot. A 409 gateway rejection
  /// (the in-flight race loser) is presented as handled-elsewhere. Gateway 4xx
  /// rejections never remove the request and never propagate.
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
        sessionId: question.sessionId,
        commandId: commandId,
        answers: answers,
      );
      switch (result.outcome) {
        case QuestionAnswerOutcome.accepted:
          _markSubmission(requestId, QuestionSubmissionState.sent);
          _removeSubmittedInteraction(question.instanceId, requestId);
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
          await _reconcileUnknownQuestion(requestId, commandId);
      }
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 409) {
        // The in-flight race loser: another client confirmed the request
        // first. Present the definitive handled-elsewhere message and refresh
        // authority so the workbench converges.
        _markSubmission(requestId, QuestionSubmissionState.handledElsewhere);
        await reconcile();
      } else if (statusCode != null && statusCode >= 400 && statusCode < 500) {
        _markSubmission(requestId, QuestionSubmissionState.rejected);
        await reconcile();
      } else {
        _markSubmission(requestId, QuestionSubmissionState.resultUnknown);
        await _reconcileUnknownQuestion(requestId, commandId);
      }
    } catch (_) {
      _markSubmission(requestId, QuestionSubmissionState.resultUnknown);
      await _reconcileUnknownQuestion(requestId, commandId);
    }
  }

  /// Submits a [decision] for [permission] with a fresh client-generated
  /// command id and drives the per-request submission state. Always allow is
  /// submitted here only after the page's confirmation dialog.
  ///
  /// An accepted outcome marks the request sent and removes it optimistically
  /// without a snapshot re-read. Legacy terminal outcomes remain supported at
  /// this seam; stale,
  /// upstream-error, and gateway-rejected outcomes keep it and trigger an
  /// authoritative snapshot re-read. An unknown outcome — and a transport or
  /// unexpected failure — queries the same [commandId] once to converge on
  /// what the gateway recorded, never auto-retrying, then re-reads authority
  /// so the workbench reflects the fresh snapshot. A 409 gateway rejection
  /// (the in-flight race loser) is presented as handled-elsewhere. Gateway 4xx
  /// rejections never remove the request and never propagate.
  Future<void> decidePermission({
    required PendingPermission permission,
    required PermissionDecision decision,
  }) async {
    final requestId = permission.requestId;
    final commandId = ref.read(commandIdGeneratorProvider)();
    _markPermissionSubmission(requestId, PermissionDecisionState.submitting);
    try {
      final result = await ref.read(permissionDecisionSenderProvider)(
        instanceId: permission.instanceId,
        requestId: requestId,
        sessionId: permission.sessionId,
        commandId: commandId,
        decision: decision,
      );
      switch (result.outcome) {
        case PermissionDecisionOutcome.accepted:
          _markPermissionSubmission(requestId, PermissionDecisionState.sent);
          _removeSubmittedInteraction(permission.instanceId, requestId);
        case PermissionDecisionOutcome.confirmed:
          _markPermissionSubmission(
            requestId,
            PermissionDecisionState.confirmed,
          );
          _removeInteraction(requestId);
          await reconcile();
        case PermissionDecisionOutcome.stale:
          _markPermissionSubmission(requestId, PermissionDecisionState.stale);
          await reconcile();
        case PermissionDecisionOutcome.upstreamError:
          _markPermissionSubmission(
            requestId,
            PermissionDecisionState.upstreamError,
          );
          await reconcile();
        case PermissionDecisionOutcome.resultUnknown:
          _markPermissionSubmission(
            requestId,
            PermissionDecisionState.resultUnknown,
          );
          await _reconcileUnknownPermission(requestId, commandId);
      }
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 409) {
        // The in-flight race loser: another client confirmed the request
        // first. Present the definitive handled-elsewhere message and refresh
        // authority so the workbench converges.
        _markPermissionSubmission(
          requestId,
          PermissionDecisionState.handledElsewhere,
        );
        await reconcile();
      } else if (statusCode != null && statusCode >= 400 && statusCode < 500) {
        _markPermissionSubmission(requestId, PermissionDecisionState.rejected);
        await reconcile();
      } else {
        _markPermissionSubmission(
          requestId,
          PermissionDecisionState.resultUnknown,
        );
        await _reconcileUnknownPermission(requestId, commandId);
      }
    } catch (_) {
      _markPermissionSubmission(
        requestId,
        PermissionDecisionState.resultUnknown,
      );
      await _reconcileUnknownPermission(requestId, commandId);
    }
  }

  /// Queries the same [commandId] once after a question outcome was unknown
  /// and converges the submission state and workbench on what the gateway
  /// recorded. Never resubmits. A still-unknown correlation (accepted,
  /// expired, or unreachable) still re-reads authority so the workbench
  /// converges on the fresh snapshot.
  Future<void> _reconcileUnknownQuestion(
    String requestId,
    String commandId,
  ) async {
    switch (await _resolveUnknownOutcome(commandId)) {
      case UnknownOutcomeResolution.confirmed:
        _markSubmission(requestId, QuestionSubmissionState.confirmed);
        _removeInteraction(requestId);
        await reconcile();
      case UnknownOutcomeResolution.stale:
        // A stale correlation means OpenCode no longer sees the request; the
        // authoritative re-read follows and the definitive handled-elsewhere
        // banner is shown.
        _markSubmission(requestId, QuestionSubmissionState.handledElsewhere);
        await reconcile();
      case UnknownOutcomeResolution.upstreamError:
        _markSubmission(requestId, QuestionSubmissionState.upstreamError);
        await reconcile();
      case UnknownOutcomeResolution.unknown:
        _markSubmission(requestId, QuestionSubmissionState.resultUnknown);
        await reconcile();
    }
  }

  /// Queries the same [commandId] once after a permission outcome was unknown
  /// and converges the submission state and workbench on what the gateway
  /// recorded. Never resubmits. A still-unknown correlation (accepted,
  /// expired, or unreachable) still re-reads authority so the workbench
  /// converges on the fresh snapshot.
  Future<void> _reconcileUnknownPermission(
    String requestId,
    String commandId,
  ) async {
    switch (await _resolveUnknownOutcome(commandId)) {
      case UnknownOutcomeResolution.confirmed:
        _markPermissionSubmission(requestId, PermissionDecisionState.confirmed);
        _removeInteraction(requestId);
        await reconcile();
      case UnknownOutcomeResolution.stale:
        _markPermissionSubmission(
          requestId,
          PermissionDecisionState.handledElsewhere,
        );
        await reconcile();
      case UnknownOutcomeResolution.upstreamError:
        _markPermissionSubmission(
          requestId,
          PermissionDecisionState.upstreamError,
        );
        await reconcile();
      case UnknownOutcomeResolution.unknown:
        _markPermissionSubmission(
          requestId,
          PermissionDecisionState.resultUnknown,
        );
        await reconcile();
    }
  }

  /// Resolves an unknown submission outcome by querying the gateway's
  /// body-free outcome correlation for [commandId] exactly once. A missing or
  /// expired correlation (404) and transport failures both leave the outcome
  /// undetermined and resolve to [UnknownOutcomeResolution.unknown]; accepted
  /// and still-pending records do the same. Callers always re-read authority
  /// afterwards so the workbench converges on the fresh snapshot.
  Future<UnknownOutcomeResolution> _resolveUnknownOutcome(
    String commandId,
  ) async {
    CommandOutcomeInfo info;
    try {
      info = await ref.read(commandOutcomeLoaderProvider)(commandId);
    } on DioException {
      return UnknownOutcomeResolution.unknown;
    } catch (_) {
      return UnknownOutcomeResolution.unknown;
    }
    return switch (info.status) {
      CommandOutcomeStatus.confirmed => UnknownOutcomeResolution.confirmed,
      CommandOutcomeStatus.stale => UnknownOutcomeResolution.stale,
      CommandOutcomeStatus.upstreamError =>
        UnknownOutcomeResolution.upstreamError,
      CommandOutcomeStatus.accepted ||
      CommandOutcomeStatus.resultUnknown => UnknownOutcomeResolution.unknown,
    };
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
      _clearRetention();
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

  void _removeSubmittedInteraction(String instanceId, String requestId) {
    _submittedInteractionKeys.add(_interactionKey(instanceId, requestId));
    _lastKnownByInstance[instanceId] = [
      for (final interaction in _lastKnownByInstance[instanceId] ?? const [])
        if (interaction.requestId != requestId) interaction,
    ];
    final current = state.value ?? const <PendingInteraction>[];
    state = AsyncData([
      for (final interaction in current)
        if (interaction.instanceId != instanceId || interaction.requestId != requestId)
          interaction,
    ]);
  }

  static String _interactionKey(String instanceId, String requestId) =>
      '$instanceId:$requestId';

  void _markSubmission(String requestId, QuestionSubmissionState value) {
    ref.read(questionSubmissionStatesProvider.notifier).mark(requestId, value);
  }

  void _markPermissionSubmission(
    String requestId,
    PermissionDecisionState value,
  ) {
    ref
        .read(permissionSubmissionStatesProvider.notifier)
        .mark(requestId, value);
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
