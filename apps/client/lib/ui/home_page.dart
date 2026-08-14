import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../realtime/active_sessions.dart';
import '../realtime/instance_presence.dart';
import '../realtime/realtime_controller.dart';
import '../realtime/ws_client.dart';

/// Live socket status for the dashboard chip. Drives (and therefore starts)
/// the [realtimeControllerProvider] while authenticated; `disconnected`
/// otherwise. Overridden in tests.
final wsStatusProvider = StreamProvider<WsStatus>((ref) {
  if (ref.watch(realtimeControllerProvider) == null) {
    return Stream.value(WsStatus.disconnected);
  }
  return ref.watch(wsClientProvider).status;
});

/// Operational dashboard: gateway connection status plus the live agent
/// sessions with their pending-action counts.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(wsStatusProvider).value ?? WsStatus.disconnected;
    final sessions = ref.watch(activeSessionsProvider);
    final instances = ref.watch(instancePresencesProvider);
    final ordered = sessions.values.toList()
      ..sort((a, b) => b.lastHeartbeatAt.compareTo(a.lastHeartbeatAt));
    return Scaffold(
      appBar: AppBar(
        title: const Text('首页'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: WsStatusChip(status: status),
          ),
        ],
      ),
      body: ordered.isEmpty && instances.isEmpty
          ? const Center(child: Text('暂无活动会话'))
          : ListView(
              children: [
                if (instances.isNotEmpty) ...[
                  const _SectionHeader('OpenCode 实例'),
                  for (final instance in instances.values)
                    _InstanceTile(instance: instance),
                ],
                if (ordered.isNotEmpty && instances.isNotEmpty)
                  const Divider(height: 24),
                if (ordered.isNotEmpty) const _SectionHeader('活动会话'),
                for (final session in ordered) _SessionTile(session: session),
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: Text(label, style: Theme.of(context).textTheme.titleSmall),
  );
}

class _InstanceTile extends StatelessWidget {
  const _InstanceTile({required this.instance});

  final OpenCodeInstancePresence instance;

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (instance.state) {
      InstancePresenceState.controllable => (
        '可远程操作',
        Icons.cloud_done_outlined,
      ),
      InstancePresenceState.conflicting => (
        '项目冲突',
        Icons.warning_amber_outlined,
      ),
      InstancePresenceState.incompatible => ('版本不兼容', Icons.block_outlined),
      InstancePresenceState.offline => ('离线', Icons.cloud_off_outlined),
    };
    final detail = instance.state == InstancePresenceState.offline
        ? '${instance.openCodeVersion} · ${_elapsedText(instance.lastSeenAt)}'
        : 'OpenCode ${instance.openCodeVersion}';
    return ListTile(
      key: ValueKey('instance-${instance.instanceId}'),
      leading: Icon(icon),
      title: Text('${instance.machine} · ${instance.project}'),
      subtitle: Text(detail),
      trailing: Chip(label: Text(label), visualDensity: VisualDensity.compact),
    );
  }
}

String _elapsedText(DateTime then) {
  final elapsed = DateTime.now().difference(then);
  if (elapsed.inSeconds < 60) return '刚刚在线';
  if (elapsed.inMinutes < 60) return '${elapsed.inMinutes}分钟前在线';
  return '${elapsed.inHours}小时前在线';
}

/// Gateway connection status chip: 已连接 / 连接中 / 未连接.
class WsStatusChip extends StatelessWidget {
  const WsStatusChip({super.key, required this.status});

  /// The status to display.
  final WsStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (status) {
      WsStatus.connected => ('已连接', Icons.cloud_done_outlined),
      WsStatus.connecting => ('连接中', Icons.cloud_sync_outlined),
      WsStatus.disconnected => ('未连接', Icons.cloud_off_outlined),
    };
    return Chip(
      key: const ValueKey('ws-status-chip'),
      avatar: Icon(icon, size: 16),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});

  final ActiveSession session;

  @override
  Widget build(BuildContext context) {
    final pending = session.pendingRequestIds;
    return ListTile(
      key: ValueKey('session-${session.sessionId}'),
      title: Text('${session.machine} · ${session.project}'),
      subtitle: Text('${session.title} · ${_elapsedText()}'),
      trailing: pending.isEmpty
          ? null
          : Badge(
              key: ValueKey('pending-${session.sessionId}'),
              label: Text('${pending.length}'),
              child: const Icon(Icons.notification_important_outlined),
            ),
    );
  }

  String _elapsedText() {
    final elapsed = DateTime.now().difference(session.lastHeartbeatAt);
    if (elapsed.inSeconds < 60) {
      return '刚刚活跃';
    }
    if (elapsed.inMinutes < 60) {
      return '${elapsed.inMinutes}分钟前活跃';
    }
    return '${elapsed.inHours}小时前活跃';
  }
}
