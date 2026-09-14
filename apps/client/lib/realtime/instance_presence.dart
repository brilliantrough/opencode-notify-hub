import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notify_api/notify_api.dart';

import '../auth/auth_controller.dart';
import '../auth/auth_state.dart';
import '../config/server_config.dart';
import '../devices/devices_controller.dart' show sharedPreferencesProvider;

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
    this.webUiAvailable = false,
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
      webUiAvailable: json['webUiAvailable'] == true,
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
  final bool webUiAvailable;
  bool get canOpen =>
      state == InstancePresenceState.controllable && webUiAvailable;

  Map<String, Object?> toJson() => {
    'instanceId': instanceId,
    'machine': machine,
    'project': project,
    'directory': directory,
    'openCodeVersion': openCodeVersion,
    'protocolVersion': protocolVersion,
    'state': state.name,
    'lastSeenAt': lastSeenAt.toIso8601String(),
    'webUiAvailable': webUiAvailable,
  };

  OpenCodeInstancePresence asOffline() => OpenCodeInstancePresence(
    instanceId: instanceId,
    machine: machine,
    project: project,
    directory: directory,
    openCodeVersion: openCodeVersion,
    protocolVersion: protocolVersion,
    state: InstancePresenceState.offline,
    lastSeenAt: lastSeenAt,
    webUiAvailable: webUiAvailable,
  );
}

final instancePresencesProvider =
    NotifierProvider<InstancePresences, Map<String, OpenCodeInstancePresence>>(
      InstancePresences.new,
    );

final instancesApiProvider = Provider<InstancesApi>(
  (ref) => ref.watch(apiClientProvider).notifyApi.getInstancesApi(),
);

class InstancePresences
    extends Notifier<Map<String, OpenCodeInstancePresence>> {
  String? _storageKey;
  int _epoch = 0;
  int _revision = 0;
  Future<void> _writes = Future.value();
  bool _loaded = false;

  @override
  Map<String, OpenCodeInstancePresence> build() {
    final epoch = ++_epoch;
    _loaded = false;
    final auth = ref.watch(authControllerProvider);
    final gateway = ref.watch(appConfigProvider).gatewayHttpBase;
    _storageKey = auth is Authenticated
        ? 'instance_history_v1:${jsonEncode([gateway, auth.email.toLowerCase()])}'
        : null;
    if (_storageKey != null) unawaited(Future(() => _load(epoch)));
    return const {};
  }

  Future<void> _load(int epoch) async {
    final key = _storageKey;
    if (epoch != _epoch || key == null || !ref.mounted) return;
    try {
      final prefs = await ref.read(sharedPreferencesProvider);
      if (epoch != _epoch || !ref.mounted) return;
      final raw = prefs.getString(key);
      if (raw != null) {
        final cached = <String, OpenCodeInstancePresence>{};
        for (final item in jsonDecode(raw) as List) {
          final presence = OpenCodeInstancePresence.parse(
            Map<String, dynamic>.from(item as Map),
          );
          cached[presence.instanceId] = presence.asOffline();
        }
        state = {...cached, ...state};
      }
    } catch (_) {
      /* Live snapshots remain usable without the local cache. */
    }
    if (epoch != _epoch || !ref.mounted) return;
    _loaded = true;
    await _save().catchError((Object _) {});
  }

  Future<void> _save() async {
    final key = _storageKey;
    if (key == null || !_loaded) return;
    final raw = jsonEncode(state.values.map((i) => i.toJson()).toList());
    final prefs = ref.read(sharedPreferencesProvider);
    final write = _writes.then((_) async {
      if (!await (await prefs).setString(key, raw)) {
        throw StateError('History write failed');
      }
    });
    _writes = write.catchError((Object _) {});
    await write;
  }

  void replaceAll(List<OpenCodeInstancePresence> instances) {
    _revision++;
    state = {
      for (final instance in state.values)
        instance.instanceId: instance.asOffline(),
      for (final instance in instances)
        if (instance.state != InstancePresenceState.offline)
          instance.instanceId: instance,
    };
    unawaited(_save().catchError((Object _) {}));
  }

  Future<void> refresh() async {
    final epoch = _epoch;
    final revision = _revision;
    final response = await ref
        .read(apiClientProvider)
        .dio
        .get<Map<String, dynamic>>('/v1/instances');
    final items = (response.data!['instances'] as List)
        .map(
          (item) => OpenCodeInstancePresence.parse(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
    if (ref.mounted && epoch == _epoch && revision == _revision) {
      replaceAll(items);
    }
  }

  Future<void> forgetOffline(String instanceId) async {
    final item = state[instanceId];
    final epoch = _epoch;
    if (item?.state == InstancePresenceState.offline) {
      state = Map.of(state)..remove(instanceId);
      try {
        await _save();
      } catch (_) {
        if (ref.mounted && epoch == _epoch) {
          state = {instanceId: item!, ...state};
        }
        rethrow;
      }
    }
  }
}
