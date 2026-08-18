import '../realtime/active_sessions.dart';
import '../realtime/instance_presence.dart';

/// Finds the one registered Plugin instance that owns an active Session's
/// source directory. A prompt is hidden when the target is ambiguous or not
/// currently controllable; it is never guessed from a machine label alone.
OpenCodeInstancePresence? sessionControlTarget(
  ActiveSession session,
  Iterable<OpenCodeInstancePresence> instances,
) {
  final candidates = instances.where(
    (instance) =>
        instance.state == InstancePresenceState.controllable &&
        instance.machine == session.machine &&
        (session.directory.isEmpty ||
            instance.directory == session.directory) &&
        (session.directory.isNotEmpty || instance.project == session.project),
  );
  final list = candidates.toList(growable: false);
  return list.length == 1 ? list.single : null;
}
