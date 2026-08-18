import 'package:flutter_test/flutter_test.dart';

import 'package:client/realtime/active_sessions.dart';
import 'package:client/realtime/instance_presence.dart';
import 'package:client/sessions/session_target.dart';

void main() {
  final session = ActiveSession(
    sessionId: 'ses_1',
    machine: 'devbox',
    project: 'notify',
    directory: '/work/notify',
    title: 'Implement API',
    lastHeartbeatAt: DateTime.utc(2026, 8, 18),
    running: false,
  );

  OpenCodeInstancePresence instance({
    required String id,
    required InstancePresenceState state,
    String directory = '/work/notify',
  }) => OpenCodeInstancePresence(
    instanceId: id,
    machine: 'devbox',
    project: 'notify',
    directory: directory,
    openCodeVersion: '1.18.18',
    protocolVersion: 1,
    state: state,
    lastSeenAt: DateTime.utc(2026, 8, 18),
  );

  test('selects the unique controllable instance for a session', () {
    expect(
      sessionControlTarget(session, [
        instance(id: 'instance-1', state: InstancePresenceState.controllable),
      ])?.instanceId,
      'instance-1',
    );
  });

  test(
    'does not guess when the instance is offline, incompatible, or ambiguous',
    () {
      expect(
        sessionControlTarget(session, [
          instance(id: 'instance-1', state: InstancePresenceState.offline),
        ]),
        isNull,
      );
      expect(
        sessionControlTarget(session, [
          instance(id: 'instance-1', state: InstancePresenceState.controllable),
          instance(id: 'instance-2', state: InstancePresenceState.controllable),
        ]),
        isNull,
      );
    },
  );
}
