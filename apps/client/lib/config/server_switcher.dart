import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../devices/devices_controller.dart';
import '../ingest_keys/ingest_keys_controller.dart';
import '../pending/pending_controller.dart';
import '../realtime/active_sessions.dart';
import '../realtime/instance_presence.dart';
import '../realtime/realtime_controller.dart';
import 'server_config.dart';

class ServerSwitcher {
  const ServerSwitcher({
    required this.readCurrent,
    required this.logout,
    required this.persist,
    required this.resetServerState,
  });

  final String Function() readCurrent;
  final Future<void> Function() logout;
  final Future<void> Function(String gatewayHttpBase) persist;
  final void Function() resetServerState;

  Future<bool> switchTo(String input) async {
    final next = ServerConfig.parse(input).gatewayHttpBase;
    if (next == readCurrent()) {
      return false;
    }
    await logout();
    await persist(next);
    resetServerState();
    return true;
  }
}

final serverSwitcherProvider = Provider<ServerSwitcher>(
  (ref) => ServerSwitcher(
    readCurrent: () => ref.read(serverConfigProvider).gatewayHttpBase,
    logout: () => ref.read(authControllerProvider.notifier).logout(),
    persist: (next) async {
      await ref.read(serverConfigProvider.notifier).setServer(next);
    },
    resetServerState: () {
      ref.invalidate(devicesControllerProvider);
      ref.invalidate(ingestKeysControllerProvider);
      ref.invalidate(pendingInteractionsProvider);
      ref.invalidate(questionSubmissionStatesProvider);
      ref.invalidate(permissionSubmissionStatesProvider);
      ref.invalidate(instancePresencesProvider);
      ref.invalidate(activeSessionsProvider);
      ref.invalidate(eventDeduperProvider);
    },
  ),
);
