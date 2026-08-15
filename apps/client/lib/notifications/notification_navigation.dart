import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_state.dart';
import '../pending/pending_controller.dart';
import '../pending/pending_interaction.dart';
import '../realtime/instance_presence.dart';
import '../realtime/notify_event.dart';
import '../ui/pending_interaction_page.dart';
import 'notification_intent.dart';

/// Resolves a clicked notification to its focused request page.
///
/// The click handler stores the [NotificationTarget] in the in-memory intent
/// slot first, so a click that arrives while the app is still logging in is
/// carried until the session becomes authenticated (the bootstrap auth
/// listener then replays it via [processStoredIntent]).
///
/// Once authenticated the flow awaits an authoritative pending snapshot
/// refresh, then resolves the owning instance by (machine, project,
/// directory, requestId, kind) from the fresh snapshot, the presence
/// projection, and finally the retained last-known requests:
///
/// - the owning instance is controllable → push the interactive
///   [PendingInteractionPage] on the app navigator;
/// - the owning instance is offline and the retained last-known still holds
///   the request → push the read-only page with the instance's last-online
///   time;
/// - anything else (handled elsewhere, unknown/conflicting/incompatible
///   instance, no retained match) → a 该请求已被处理或不可用 SnackBar and the
///   user stays on the workbench.
///
/// A sync failure shows 同步失败 instead. The intent slot is always cleared
/// at a terminal outcome; it survives only the unauthenticated wait.
class NotificationNavigation {
  NotificationNavigation({
    required AuthState Function() readAuth,
    required PendingInteractionsController pending,
    required Map<String, OpenCodeInstancePresence> Function() readInstances,
    required Map<String, List<PendingInteraction>> Function() readLastKnown,
    required NotificationIntentStore intentStore,
    required GlobalKey<NavigatorState> navigatorKey,
    required void Function(String message) showSnackBar,
    required Future<List<PendingInteraction>> Function() readPendingFuture,
  }) : _readAuth = readAuth,
       _pending = pending,
       _readInstances = readInstances,
       _readLastKnown = readLastKnown,
       _intentStore = intentStore,
       _navigatorKey = navigatorKey,
       _showSnackBar = showSnackBar,
       _readPendingFuture = readPendingFuture;

  final AuthState Function() _readAuth;
  final PendingInteractionsController _pending;
  final Map<String, OpenCodeInstancePresence> Function() _readInstances;
  final Map<String, List<PendingInteraction>> Function() _readLastKnown;
  final NotificationIntentStore _intentStore;
  final GlobalKey<NavigatorState> _navigatorKey;
  final void Function(String message) _showSnackBar;
  final Future<List<PendingInteraction>> Function() _readPendingFuture;

  bool _processing = false;

  /// Deep-link entry from a realtime alert click. Events that cannot build a
  /// target (provider actions, missing request ids) are ignored.
  void onActionRequiredClick(NotifyEvent event) {
    final target = NotificationTarget.tryFromEvent(event);
    if (target == null) {
      return;
    }
    unawaited(processTarget(target));
  }

  /// Handles [target] (typically from a notification click): saves it into
  /// the intent slot, waits for authentication, then resolves it.
  Future<void> processTarget(NotificationTarget target) async {
    _intentStore.save(target);
    if (_readAuth() is! Authenticated) {
      return;
    }
    await _process(target);
  }

  /// Replays the stored intent once a session is present (login, bootstrap).
  Future<void> processStoredIntent() async {
    final target = _intentStore.peek();
    if (target == null || _readAuth() is! Authenticated) {
      return;
    }
    await _process(target);
  }

  Future<void> _process(NotificationTarget target) async {
    // Re-entry guard: one resolution at a time. A newer click that arrives
    // mid-resolution has already overwritten the intent slot (processTarget),
    // so after the current target settles the loop picks the newer one up
    // instead of dropping it.
    if (_processing) {
      return;
    }
    _processing = true;
    try {
      var current = target;
      while (true) {
        await _resolve(current);
        final next = _intentStore.peek();
        if (next == null || next == current) {
          _intentStore.clear();
          return;
        }
        current = next;
      }
    } finally {
      _processing = false;
    }
  }

  Future<void> _resolve(NotificationTarget target) async {
    await _pending.refresh();
    final snapshot = await _terminalSnapshot();
    if (snapshot is AsyncError) {
      _showSnackBar('同步失败');
      return;
    }
    final interactions = snapshot.value ?? const <PendingInteraction>[];
    final instances = _readInstances();
    final lastKnown = _readLastKnown();

    // 1. The authoritative snapshot is the primary owner lookup.
    final inSnapshot = _firstMatch(interactions, target);
    if (inSnapshot != null) {
      final presence = instances[inSnapshot.instanceId];
      if (presence != null &&
          presence.state == InstancePresenceState.controllable) {
        _push(PendingInteractionPage(interaction: inSnapshot));
        return;
      }
      if (presence != null && presence.state == InstancePresenceState.offline) {
        final retained = _firstMatch(_flatten(lastKnown), target);
        if (retained != null) {
          _push(
            PendingInteractionPage(
              interaction: retained,
              readOnly: true,
              lastSeenAt: presence.lastSeenAt,
            ),
          );
          return;
        }
      }
      // Conflicting / incompatible, or offline without a retained match.
      _showSnackBar('该请求已被处理或不可用');
      return;
    }

    // 2. Not in the snapshot: the retained last-known request is still
    //    readable when its owning instance is offline.
    final retained = _firstMatch(_flatten(lastKnown), target);
    if (retained != null) {
      final presence = instances[retained.instanceId];
      if (presence != null && presence.state == InstancePresenceState.offline) {
        _push(
          PendingInteractionPage(
            interaction: retained,
            readOnly: true,
            lastSeenAt: presence.lastSeenAt,
          ),
        );
        return;
      }
    }

    // Handled elsewhere, unknown instance, or no retained match.
    _showSnackBar('该请求已被处理或不可用');
  }

  void _push(Widget page) {
    _navigatorKey.currentState?.push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  /// Waits until the pending snapshot settles on a terminal value.
  ///
  /// The controller's [PendingInteractionsController.refresh] can return
  /// before the authoritative load finishes when it queues behind an
  /// in-flight build, so the raw `current` read may still be `AsyncLoading`.
  /// Each await on the provider's `future` resolves with the first non-loading
  /// state, so this loop converges once the load reports data or error.
  Future<AsyncValue<List<PendingInteraction>>> _terminalSnapshot() async {
    var snapshot = _pending.current;
    while (snapshot is AsyncLoading) {
      try {
        await _readPendingFuture();
      } on Object {
        // Loading resolved to an error; the loop's next read reflects it.
      }
      snapshot = _pending.current;
    }
    return snapshot;
  }

  static PendingInteraction? _firstMatch(
    List<PendingInteraction> interactions,
    NotificationTarget target,
  ) {
    for (final interaction in interactions) {
      if (target.matches(interaction)) {
        return interaction;
      }
    }
    return null;
  }

  static List<PendingInteraction> _flatten(
    Map<String, List<PendingInteraction>> lastKnown,
  ) => [for (final list in lastKnown.values) ...list];
}

/// The production [NotificationNavigation]: reads the realtime/prefs-free
/// providers and routes pushes and SnackBars through the app navigator.
final notificationNavigationProvider = Provider<NotificationNavigation>((ref) {
  return NotificationNavigation(
    readAuth: () => ref.read(authControllerProvider),
    pending: ref.read(pendingInteractionsProvider.notifier),
    readInstances: () => ref.read(instancePresencesProvider),
    readLastKnown: () =>
        ref.read(pendingInteractionsProvider.notifier).lastKnownByInstance,
    intentStore: ref.read(notificationIntentProvider.notifier),
    navigatorKey: ref.read(appNavigatorKeyProvider),
    showSnackBar: (message) {
      final context = ref.read(appNavigatorKeyProvider).currentContext;
      if (context != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    },
    readPendingFuture: () => ref.read(pendingInteractionsProvider.future),
  );
});
