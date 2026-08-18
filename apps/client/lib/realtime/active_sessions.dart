import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notify_event.dart';

final activeSessionsProvider =
    NotifierProvider<ActiveSessions, Map<String, ActiveSession>>(
      ActiveSessions.new,
    );

/// Client-side view of one agent session's liveness, derived from realtime
/// events.
///
/// [lastHeartbeatAt] is the `occurredAt` of the most recent heartbeat (or of
/// the event that first introduced the session). [running] is `true` from the
/// first heartbeat/action event until [ActiveSessions.markTerminal]; a
/// heartbeat arriving afterwards flips it back to `true` because a live
/// heartbeat means the session is alive again. [pendingRequestIds] holds the
/// `requestId`s of `action_required` events not yet matched by an
/// `action_resolved`.
class ActiveSession {
  const ActiveSession({
    required this.sessionId,
    required this.machine,
    required this.project,
    this.directory = '',
    required this.title,
    required this.lastHeartbeatAt,
    required this.running,
    this.pendingRequestIds = const {},
  });

  final String sessionId;
  final String machine;
  final String project;
  final String directory;
  final String title;
  final DateTime lastHeartbeatAt;
  final bool running;
  final Set<String> pendingRequestIds;

  ActiveSession copyWith({
    String? machine,
    String? project,
    String? directory,
    String? title,
    DateTime? lastHeartbeatAt,
    bool? running,
    Set<String>? pendingRequestIds,
  }) => ActiveSession(
    sessionId: sessionId,
    machine: machine ?? this.machine,
    project: project ?? this.project,
    directory: directory ?? this.directory,
    title: title ?? this.title,
    lastHeartbeatAt: lastHeartbeatAt ?? this.lastHeartbeatAt,
    running: running ?? this.running,
    pendingRequestIds: pendingRequestIds ?? this.pendingRequestIds,
  );
}

/// Tracks the active agent sessions, keyed by session ID.
///
/// All mutators are event-driven (fed by the `NotificationRouter`): unknown
/// session IDs in [clearPending]/[markTerminal] are ignored so out-of-order
/// or orphaned events can never corrupt the map.
class ActiveSessions extends Notifier<Map<String, ActiveSession>> {
  @override
  Map<String, ActiveSession> build() => const {};

  /// Creates or refreshes the session from a heartbeat event. A heartbeat
  /// always marks the session as running and refreshes its identity and
  /// [ActiveSession.lastHeartbeatAt].
  void upsertHeartbeat(NotifyEvent event) {
    final existing = state[event.sessionId];
    final updated = existing == null
        ? _fromEvent(event, running: true)
        : existing.copyWith(
            machine: event.machine,
            project: event.project,
            directory: event.directory,
            title: event.sessionTitle,
            lastHeartbeatAt: event.occurredAt,
            running: true,
          );
    state = {...state, event.sessionId: updated};
  }

  /// Creates or refreshes the session and records [NotifyEvent.requestId] as
  /// pending. An event without a request ID (not producible through
  /// [NotifyEvent.parse], but possible via the view model) still upserts the
  /// session without touching the pending set.
  void addPending(NotifyEvent event) {
    final existing = state[event.sessionId];
    final requestId = event.requestId;
    final pending = {...?existing?.pendingRequestIds, ?requestId};
    final updated = existing == null
        ? _fromEvent(event, running: true, pendingRequestIds: pending)
        : existing.copyWith(
            machine: event.machine,
            project: event.project,
            directory: event.directory,
            title: event.sessionTitle,
            running: true,
            pendingRequestIds: pending,
          );
    state = {...state, event.sessionId: updated};
  }

  /// Removes [requestId] from the session's pending set; a no-op when the
  /// session is unknown.
  void clearPending(String sessionId, String requestId) {
    final existing = state[sessionId];
    if (existing == null) {
      return;
    }
    state = {
      ...state,
      sessionId: existing.copyWith(
        pendingRequestIds: {...existing.pendingRequestIds}..remove(requestId),
      ),
    };
  }

  /// Marks the session's run as ended: no longer running, and any still
  /// pending requests are dropped because a finished run cannot be answered
  /// anymore. A no-op when the session is unknown.
  void markTerminal(String sessionId) {
    final existing = state[sessionId];
    if (existing == null) {
      return;
    }
    state = {
      ...state,
      sessionId: existing.copyWith(running: false, pendingRequestIds: const {}),
    };
  }

  static ActiveSession _fromEvent(
    NotifyEvent event, {
    required bool running,
    Set<String> pendingRequestIds = const {},
  }) => ActiveSession(
    sessionId: event.sessionId,
    machine: event.machine,
    project: event.project,
    directory: event.directory,
    title: event.sessionTitle,
    // The event that introduces the session is the best available "last
    // activity" timestamp until the first heartbeat arrives.
    lastHeartbeatAt: event.occurredAt,
    running: running,
    pendingRequestIds: pendingRequestIds,
  );
}
