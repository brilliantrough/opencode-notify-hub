import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../pending/pending_interaction.dart';
import '../realtime/notify_event.dart';

/// The kind of user action a notification deep link targets.
enum NotificationIntentKind { question, permission }

/// Where a clicked notification should lead: the owning
/// (machine, project, directory) tuple plus the request and its kind.
///
/// The instance id is deliberately absent — realtime envelopes carry no
/// instance id, so the owning instance is resolved later from the pending
/// snapshot, the presence projection, or the retained last-known requests.
class NotificationTarget {
  const NotificationTarget({
    required this.machine,
    required this.project,
    required this.directory,
    required this.requestId,
    required this.kind,
  });

  /// Builds a target from an `action_required` event. Returns `null` — never
  /// throws — when the event is not deep-linkable: no request id, or a kind
  /// that has no interaction page (provider actions, unknown).
  static NotificationTarget? tryFromEvent(NotifyEvent event) {
    final requestId = event.requestId;
    final kind = switch (event.actionKind) {
      ActionKind.question => NotificationIntentKind.question,
      ActionKind.permission => NotificationIntentKind.permission,
      _ => null,
    };
    if (requestId == null || kind == null) {
      return null;
    }
    return NotificationTarget(
      machine: event.machine,
      project: event.project,
      directory: event.directory,
      requestId: requestId,
      kind: kind,
    );
  }

  final String machine;
  final String project;
  final String directory;
  final String requestId;
  final NotificationIntentKind kind;

  /// Whether [interaction] is the request this target points at. The kind is
  /// checked too, so a kind mismatch can never resolve onto a foreign
  /// interaction that happens to share the tuple and request id. Machine and
  /// directory are compared under the same normalization the gateway uses
  /// for ownership, so case or path-separator drift between the event and
  /// the registration cannot strand an otherwise-resolvable target.
  bool matches(PendingInteraction interaction) =>
      _normalizeMachine(interaction.machine) == _normalizeMachine(machine) &&
      interaction.project == project &&
      _normalizeDirectory(interaction.directory) ==
          _normalizeDirectory(directory) &&
      interaction.requestId == requestId &&
      switch (kind) {
        NotificationIntentKind.question => interaction is PendingQuestion,
        NotificationIntentKind.permission => interaction is PendingPermission,
      };

  @override
  bool operator ==(Object other) =>
      other is NotificationTarget &&
      other.machine == machine &&
      other.project == project &&
      other.directory == directory &&
      other.requestId == requestId &&
      other.kind == kind;

  @override
  int get hashCode => Object.hash(machine, project, directory, requestId, kind);

  static String _normalizeMachine(String machine) =>
      machine.trim().toLowerCase();

  static String _normalizeDirectory(String directory) {
    var normalized = directory
        .trim()
        .replaceAll('\\', '/')
        .replaceAll(RegExp('/{2,}'), '/');
    if (normalized.length > 1) {
      normalized = normalized.replaceAll(RegExp('/\$'), '');
    }
    if (RegExp('^[A-Za-z]:/').hasMatch(normalized)) {
      normalized = normalized.toLowerCase();
    }
    return normalized;
  }
}

/// In-memory single-slot store for the notification deep link currently being
/// carried. Not persisted — surviving an app restart belongs to a later
/// slice; the slot exists so a click can be saved while the app is still
/// logging in and replayed when the session becomes authenticated.
final notificationIntentProvider =
    NotifierProvider<NotificationIntentStore, NotificationTarget?>(
      NotificationIntentStore.new,
    );

class NotificationIntentStore extends Notifier<NotificationTarget?> {
  @override
  NotificationTarget? build() => null;

  /// Current stored target without touching the provider (used by the
  /// navigation layer before authentication).
  NotificationTarget? peek() => state;

  void save(NotificationTarget target) => state = target;

  void clear() => state = null;
}
