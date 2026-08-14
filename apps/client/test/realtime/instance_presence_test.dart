import 'package:client/realtime/instance_presence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> presenceJson({String state = 'controllable'}) => {
  'instanceId': '6f0d91b0-93e4-43a9-9449-0bed03e651aa',
  'machine': 'devbox',
  'project': 'notify',
  'directory': '/work/notify',
  'openCodeVersion': '1.18.18',
  'protocolVersion': 1,
  'state': state,
  'lastSeenAt': '2026-08-14T09:00:00.000Z',
};

void main() {
  test('parses every server presence state', () {
    expect(
      ['controllable', 'conflicting', 'incompatible', 'offline'].map(
        (state) =>
            OpenCodeInstancePresence.parse(presenceJson(state: state)).state,
      ),
      InstancePresenceState.values,
    );
  });

  test('rejects malformed timestamps and unknown states', () {
    expect(
      () => OpenCodeInstancePresence.parse({
        ...presenceJson(),
        'state': 'online',
      }),
      throwsFormatException,
    );
    expect(
      () => OpenCodeInstancePresence.parse({
        ...presenceJson(),
        'lastSeenAt': 'yesterday',
      }),
      throwsFormatException,
    );
  });

  test('replaces the authoritative snapshot by instance id', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final first = OpenCodeInstancePresence.parse(presenceJson());
    final offline = OpenCodeInstancePresence.parse(
      presenceJson(state: 'offline'),
    );

    container.read(instancePresencesProvider.notifier).replaceAll([first]);
    expect(
      container.read(instancePresencesProvider)[first.instanceId]?.state,
      InstancePresenceState.controllable,
    );
    container.read(instancePresencesProvider.notifier).replaceAll([offline]);
    expect(
      container.read(instancePresencesProvider)[first.instanceId]?.state,
      InstancePresenceState.offline,
    );
  });
}
