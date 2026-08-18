import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../pending/pending_controller.dart';
import '../pending/pending_interaction.dart';
import '../realtime/active_sessions.dart';
import '../realtime/instance_presence.dart';
import '../realtime/realtime_controller.dart';
import '../realtime/ws_client.dart';
import '../sessions/webui_browser_controller.dart';
import 'pending_interaction_page.dart';
import 'session_prompt_page.dart';
import '../sessions/session_target.dart';

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
    final pending = ref.watch(pendingInteractionsProvider);
    final interactions = pending.value ?? const <PendingInteraction>[];
    final offline = ref.watch(offlineLastKnownProvider);
    final webUi = ref.watch(webUiBrowserControllerProvider);
    final ordered = sessions.values.toList()
      ..sort((a, b) => b.lastHeartbeatAt.compareTo(a.lastHeartbeatAt));
    return Scaffold(
      appBar: AppBar(
        title: const Text('首页'),
        actions: [
          IconButton(
            key: const ValueKey('pending-refresh'),
            tooltip: '刷新待处理请求',
            icon: const Icon(Icons.refresh),
            onPressed: () => unawaited(
              ref.read(pendingInteractionsProvider.notifier).refresh(),
            ),
          ),
          if (webUi.status != WebUiBrowserStatus.idle)
            IconButton(
              key: const ValueKey('webui-tunnel-close'),
              tooltip: '关闭 OpenCode WebUI 临时连接',
              icon: const Icon(Icons.link_off_outlined),
              onPressed: () => unawaited(
                ref.read(webUiBrowserControllerProvider.notifier).close(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: WsStatusChip(status: status),
          ),
        ],
      ),
      body:
          ordered.isEmpty &&
              instances.isEmpty &&
              interactions.isEmpty &&
              offline.isEmpty &&
              !pending.isLoading &&
              !pending.hasError
          ? const Center(child: Text('暂无会话'))
          : ListView(
              children: [
                if (pending.isLoading && interactions.isEmpty)
                  const LinearProgressIndicator(
                    key: ValueKey('pending-loading'),
                  ),
                if (pending.hasError && interactions.isEmpty)
                  ListTile(
                    key: const ValueKey('pending-error'),
                    leading: const Icon(Icons.sync_problem_outlined),
                    title: const Text('待处理请求同步失败'),
                    trailing: IconButton(
                      tooltip: '重试',
                      icon: const Icon(Icons.refresh),
                      onPressed: () => unawaited(
                        ref
                            .read(pendingInteractionsProvider.notifier)
                            .refresh(),
                      ),
                    ),
                  ),
                if (interactions.isNotEmpty) ...[
                  const _SectionHeader('待处理请求'),
                  for (final interaction in interactions)
                    _PendingTile(interaction: interaction),
                ],
                if (offline.isNotEmpty) ...[
                  const _SectionHeader('离线请求（只读）'),
                  for (final item in offline) _OfflineTile(item: item),
                ],
                if ((interactions.isNotEmpty || offline.isNotEmpty) &&
                    (instances.isNotEmpty || ordered.isNotEmpty))
                  const Divider(height: 24),
                if (instances.isNotEmpty) ...[
                  const _SectionHeader('OpenCode 实例'),
                  for (final instance in instances.values)
                    _InstanceTile(
                      instance: instance,
                      webUi: webUi,
                      onOpenWebUi: (target) =>
                          _openWebUi(context, ref, target.instanceId),
                    ),
                ],
                if (ordered.isNotEmpty && instances.isNotEmpty)
                  const Divider(height: 24),
                if (ordered.isNotEmpty) const _SectionHeader('会话'),
                for (final session in ordered)
                  _SessionTile(
                    session: session,
                    target: sessionControlTarget(session, instances.values),
                    webUi: webUi,
                    onOpenWebUi: (session, target) => _openWebUi(
                      context,
                      ref,
                      target.instanceId,
                      directory: session.directory,
                      sessionId: session.sessionId,
                    ),
                  ),
              ],
            ),
    );
  }

  Future<void> _openWebUi(
    BuildContext context,
    WidgetRef ref,
    String instanceId, {
    String? directory,
    String? sessionId,
  }) async {
    final error = await ref
        .read(webUiBrowserControllerProvider.notifier)
        .open(instanceId, directory: directory, sessionId: sessionId);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }
}

class _PendingTile extends StatelessWidget {
  const _PendingTile({required this.interaction});

  final PendingInteraction interaction;

  @override
  Widget build(BuildContext context) {
    final isQuestion = interaction is PendingQuestion;
    return ListTile(
      key: ValueKey(
        'interaction-${interaction.instanceId}-${interaction.requestId}',
      ),
      leading: Icon(isQuestion ? Icons.help_outline : Icons.shield_outlined),
      title: Text('${interaction.machine} · ${interaction.project}'),
      subtitle: Text(
        '${interaction.sessionTitle.isEmpty ? interaction.sessionId : interaction.sessionTitle} · ${_waitingText(interaction.occurredAt)}',
      ),
      trailing: Chip(
        label: Text(isQuestion ? '待回答' : '待授权'),
        visualDensity: VisualDensity.compact,
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PendingInteractionPage(interaction: interaction),
        ),
      ),
    );
  }
}

String _waitingText(DateTime occurredAt) {
  final elapsed = DateTime.now().difference(occurredAt);
  if (elapsed.inSeconds < 60) return '等待不到1分钟';
  if (elapsed.inMinutes < 60) return '等待${elapsed.inMinutes}分钟';
  return '等待${elapsed.inHours}小时';
}

class _OfflineTile extends StatelessWidget {
  const _OfflineTile({required this.item});

  final OfflinePendingInteraction item;

  @override
  Widget build(BuildContext context) {
    final interaction = item.interaction;
    final isQuestion = interaction is PendingQuestion;
    return ListTile(
      key: ValueKey(
        'offline-${interaction.instanceId}-${interaction.requestId}',
      ),
      leading: Icon(isQuestion ? Icons.help_outline : Icons.shield_outlined),
      title: Text('${interaction.machine} · ${interaction.project}'),
      subtitle: Text(
        '${interaction.sessionTitle.isEmpty ? interaction.sessionId : interaction.sessionTitle} · ${_elapsedText(item.lastSeenAt)}',
      ),
      trailing: Chip(
        label: Text(isQuestion ? '待回答' : '待授权'),
        visualDensity: VisualDensity.compact,
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PendingInteractionPage(
            interaction: interaction,
            readOnly: true,
            lastSeenAt: item.lastSeenAt,
          ),
        ),
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
  const _InstanceTile({
    required this.instance,
    required this.webUi,
    required this.onOpenWebUi,
  });

  final OpenCodeInstancePresence instance;
  final WebUiBrowserState webUi;
  final void Function(OpenCodeInstancePresence target) onOpenWebUi;

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
    final webUiOpening =
        webUi.status == WebUiBrowserStatus.opening &&
        webUi.instanceId == instance.instanceId;
    final webUiActive = webUi.activeFor(instance.instanceId);
    return ListTile(
      key: ValueKey('instance-${instance.instanceId}'),
      leading: Icon(icon),
      title: Text('${instance.machine} · ${instance.project}'),
      subtitle: Text(
        '$detail\n${instance.directory}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (instance.state == InstancePresenceState.controllable)
            IconButton(
              key: ValueKey('webui-instance-${instance.instanceId}'),
              tooltip: webUiActive
                  ? '在浏览器中重新打开 OpenCode WebUI 仪表盘'
                  : '在浏览器中打开 OpenCode WebUI 仪表盘',
              icon: webUiOpening
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      webUiActive
                          ? Icons.open_in_browser
                          : Icons.language_outlined,
                    ),
              onPressed: webUi.status == WebUiBrowserStatus.opening
                  ? null
                  : () => onOpenWebUi(instance),
            ),
          Chip(label: Text(label), visualDensity: VisualDensity.compact),
        ],
      ),
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
  const _SessionTile({
    required this.session,
    required this.target,
    required this.webUi,
    required this.onOpenWebUi,
  });

  final ActiveSession session;
  final OpenCodeInstancePresence? target;
  final WebUiBrowserState webUi;
  final void Function(ActiveSession session, OpenCodeInstancePresence target)
  onOpenWebUi;

  @override
  Widget build(BuildContext context) {
    final pending = session.pendingRequestIds;
    final targetId = target?.instanceId;
    final webUiOpening =
        webUi.status == WebUiBrowserStatus.opening &&
        webUi.instanceId == targetId;
    final webUiActive = targetId != null && webUi.activeFor(targetId);
    return ListTile(
      key: ValueKey('session-${session.sessionId}'),
      title: Text('${session.machine} · ${session.project}'),
      subtitle: Text('${session.title} · ${_elapsedText()}'),
      trailing: target == null && pending.isEmpty
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (pending.isNotEmpty)
                  Badge(
                    key: ValueKey('pending-${session.sessionId}'),
                    label: Text('${pending.length}'),
                    child: const Icon(Icons.notification_important_outlined),
                  ),
                if (target != null)
                  IconButton(
                    key: ValueKey('prompt-${session.sessionId}'),
                    tooltip: '发送到 OpenCode',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SessionPromptPage(
                          session: session,
                          target: target!,
                        ),
                      ),
                    ),
                  ),
                if (target != null)
                  IconButton(
                    key: ValueKey('webui-${session.sessionId}'),
                    tooltip: webUiActive ? '在浏览器中重新打开此会话' : '在浏览器中打开此会话',
                    icon: webUiOpening
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            webUiActive
                                ? Icons.open_in_browser
                                : Icons.language_outlined,
                          ),
                    onPressed: webUi.status == WebUiBrowserStatus.opening
                        ? null
                        : () => onOpenWebUi(session, target!),
                  ),
              ],
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
