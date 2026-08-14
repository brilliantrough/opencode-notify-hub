import 'package:flutter_riverpod/flutter_riverpod.dart';

enum InstancePresenceState { controllable, conflicting, incompatible, offline }

class OpenCodeInstancePresence {
  const OpenCodeInstancePresence({
    required this.instanceId,
    required this.machine,
    required this.project,
    required this.directory,
    required this.openCodeVersion,
    required this.protocolVersion,
    required this.state,
    required this.lastSeenAt,
  });

  factory OpenCodeInstancePresence.parse(Map<String, dynamic> json) {
    String requiredString(String key) {
      final value = json[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('invalid $key');
      }
      return value;
    }

    final protocolVersion = json['protocolVersion'];
    if (protocolVersion is! int || protocolVersion < 1) {
      throw const FormatException('invalid protocolVersion');
    }
    final state = switch (requiredString('state')) {
      'controllable' => InstancePresenceState.controllable,
      'conflicting' => InstancePresenceState.conflicting,
      'incompatible' => InstancePresenceState.incompatible,
      'offline' => InstancePresenceState.offline,
      _ => throw const FormatException('invalid state'),
    };
    final lastSeenText = requiredString('lastSeenAt');
    final lastSeenAt = DateTime.tryParse(lastSeenText);
    if (lastSeenAt == null ||
        (!lastSeenText.endsWith('Z') &&
            !RegExp(r'[+-]\d\d:\d\d$').hasMatch(lastSeenText))) {
      throw const FormatException('invalid lastSeenAt');
    }

    return OpenCodeInstancePresence(
      instanceId: requiredString('instanceId'),
      machine: requiredString('machine'),
      project: requiredString('project'),
      directory: requiredString('directory'),
      openCodeVersion: requiredString('openCodeVersion'),
      protocolVersion: protocolVersion,
      state: state,
      lastSeenAt: lastSeenAt.toUtc(),
    );
  }

  final String instanceId;
  final String machine;
  final String project;
  final String directory;
  final String openCodeVersion;
  final int protocolVersion;
  final InstancePresenceState state;
  final DateTime lastSeenAt;
}

final instancePresencesProvider =
    NotifierProvider<InstancePresences, Map<String, OpenCodeInstancePresence>>(
      InstancePresences.new,
    );

class InstancePresences
    extends Notifier<Map<String, OpenCodeInstancePresence>> {
  @override
  Map<String, OpenCodeInstancePresence> build() => const {};

  void replaceAll(List<OpenCodeInstancePresence> instances) {
    state = {for (final instance in instances) instance.instanceId: instance};
  }
}
