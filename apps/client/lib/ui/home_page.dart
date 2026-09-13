import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../pending/pending_controller.dart';
import '../pending/pending_interaction.dart';
import '../realtime/active_sessions.dart';
import '../realtime/instance_presence.dart';
import '../realtime/realtime_controller.dart';
import '../realtime/ws_client.dart';
import '../sessions/webui_browser_controller.dart';
import '../sessions/session_catalog.dart';
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
    final catalog = ref.watch(sessionCatalogProvider);
    final remoteSessions = catalog.visible;
    final ordered =
        sessions.values
            .where(
              (s) =>
                  !catalog.sessions.values.any(
                    (r) =>
                        r.session.sessionId == s.sessionId &&
                        r.session.machine == s.machine &&
                        r.session.directory == s.directory,
                  ) &&
                  '${s.title} ${s.machine} ${s.project}'.toLowerCase().contains(
                    catalog.search.toLowerCase(),
                  ),
            )
            .toList()
          ..sort((a, b) => b.lastHeartbeatAt.compareTo(a.lastHeartbeatAt));
    final instanceGroups = _groupInstances(instances.values);
    return Scaffold(
      appBar: AppBar(
        title: const Text('首页'),
        actions: [
          IconButton(
            key: const ValueKey('pending-refresh'),
            tooltip: '刷新会话和待处理请求',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              unawaited(
                ref.read(pendingInteractionsProvider.notifier).refresh(),
              );
              unawaited(ref.read(sessionCatalogProvider.notifier).refresh());
            },
          ),
          if (webUi.status != WebUiBrowserStatus.idle)
            IconButton(
              key: const ValueKey('webui-tunnel-close'),
              tooltip: '关闭全部 WebUI 连接',
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
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: const _SessionSearchField(),
          ),
          if (catalog.loading)
            const LinearProgressIndicator(
              key: ValueKey('session-catalog-loading'),
            ),
          for (final error in catalog.errors.entries)
            ListTile(
              leading: const Icon(Icons.sync_problem_outlined),
              title: Text(instances[error.key]?.project ?? '会话同步'),
              subtitle: Text(error.value),
              trailing: IconButton(
                tooltip: '重试会话同步',
                icon: const Icon(Icons.refresh),
                onPressed: () => unawaited(
                  ref.read(sessionCatalogProvider.notifier).refresh(),
                ),
              ),
            ),
          for (final connection in webUi.connections.values)
            ListTile(
              dense: true,
              leading: const Icon(Icons.link),
              title: Text(
                '${instances[connection.instanceId]?.project ?? "OpenCode"} · ${connection.status == WebUiBrowserStatus.active ? "已连接" : "正在重连"}',
              ),
              subtitle: connection.localUri == null
                  ? null
                  : Text(connection.localUri!.origin),
              onTap: connection.localUri == null
                  ? null
                  : () async {
                      final error = await ref
                          .read(webUiBrowserControllerProvider.notifier)
                          .reopen(connection.instanceId);
                      if (error != null && context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(error)));
                      }
                    },
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (connection.localUri != null)
                    IconButton(
                      tooltip: '复制会话浏览器地址',
                      icon: const Icon(Icons.copy),
                      onPressed: () async {
                        try {
                          await Clipboard.setData(
                            ClipboardData(text: connection.localUri.toString()),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('地址已复制；需在本机保持 Notify 运行'),
                              ),
                            );
                          }
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('复制失败，请重试')),
                            );
                          }
                        }
                      },
                    ),
                  IconButton(
                    tooltip: '关闭此实例的 WebUI 连接',
                    icon: const Icon(Icons.link_off),
                    onPressed: () => unawaited(
                      ref
                          .read(webUiBrowserControllerProvider.notifier)
                          .close(connection.instanceId),
                    ),
                  ),
                ],
              ),
            ),
          if (pending.isLoading && interactions.isEmpty)
            const LinearProgressIndicator(key: ValueKey('pending-loading')),
          if (pending.hasError && interactions.isEmpty)
            ListTile(
              key: const ValueKey('pending-error'),
              leading: const Icon(Icons.sync_problem_outlined),
              title: const Text('待处理请求同步失败'),
              trailing: IconButton(
                tooltip: '重试',
                icon: const Icon(Icons.refresh),
                onPressed: () => unawaited(
                  ref.read(pendingInteractionsProvider.notifier).refresh(),
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
          for (final pinned in [true, false]) ...[
            if (remoteSessions.any((s) => s.pinned == pinned))
              _SectionHeader(pinned ? '固定会话' : '最近会话（含空闲）'),
            for (final item in remoteSessions.where((s) => s.pinned == pinned))
              _SessionTile(
                session: item.session.copyWith(
                  pendingRequestIds: {
                    for (final interaction in interactions)
                      if (interaction.instanceId == item.instanceId &&
                          interaction.sessionId == item.session.sessionId)
                        interaction.requestId,
                  },
                ),
                target:
                    item.verified &&
                        instances[item.instanceId]?.state ==
                            InstancePresenceState.controllable
                    ? instances[item.instanceId]
                    : null,
                webUi: webUi,
                pinned: item.pinned,
                statusLabel:
                    instances[item.instanceId]?.state !=
                        InstancePresenceState.controllable
                    ? '离线 / 等待实例同步'
                    : switch (item.status) {
                        'busy' => '运行中',
                        'retry' => '重试中',
                        'idle' => '空闲',
                        'missing' => '会话已删除或归档',
                        _ => '状态待确认',
                      },
                onPin: () async {
                  final error = await ref
                      .read(sessionCatalogProvider.notifier)
                      .togglePin(item);
                  if (error != null && context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(error)));
                  }
                },
                onOpenWebUi: (session, target) => _openWebUi(
                  context,
                  ref,
                  target.instanceId,
                  directory: session.directory,
                  sessionId: session.sessionId,
                ),
              ),
          ],
          if (remoteSessions.isEmpty &&
              ordered.isEmpty &&
              interactions.isEmpty &&
              offline.isEmpty &&
              !catalog.loading)
            const ListTile(
              title: Text('暂无匹配会话'),
              subtitle: Text('可以清空搜索或刷新列表，空闲会话也会自动同步'),
            ),
          if (catalog.hasMore)
            TextButton(
              onPressed: catalog.loading || catalog.limit >= 200
                  ? null
                  : () => unawaited(
                      ref.read(sessionCatalogProvider.notifier).loadMore(),
                    ),
              child: Text(
                catalog.limit >= 200 ? '已显示最近 200 条，请搜索更早的会话' : '加载更多会话',
              ),
            ),
          if (ordered.isNotEmpty) const _SectionHeader('实时会话'),
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
          if (instances.isNotEmpty) ...[
            const Divider(height: 24),
            const _SectionHeader('OpenCode 实例'),
            for (final group in instanceGroups)
              _MachineInstanceGroup(
                key: ValueKey(
                  'machine-group-${group.machine.trim().toLowerCase()}',
                ),
                group: group,
                webUi: webUi,
                onOpenWebUi: (target) => _openInstance(context, ref, target),
                onDelete: (instance) => _forgetInstance(context, ref, instance),
                onClearOffline: () => _clearOfflineGroup(context, ref, group),
              ),
          ],
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
    if (error == null && sessionId != null && ref.context.mounted) {
      await ref
          .read(sessionCatalogProvider.notifier)
          .markOpened(instanceId, sessionId);
    }
  }

  Future<void> _openInstance(
    BuildContext context,
    WidgetRef ref,
    OpenCodeInstancePresence instance,
  ) async {
    final controller = ref.read(sessionCatalogProvider.notifier);
    if (controller.preferred(instance) == null) await controller.refresh();
    if (!context.mounted) return;
    final preferred = controller.preferred(instance);
    await _openWebUi(
      context,
      ref,
      instance.instanceId,
      directory: instance.directory,
      sessionId: preferred?.session.sessionId,
    );
  }

  Future<void> _forgetInstance(
    BuildContext context,
    WidgetRef ref,
    OpenCodeInstancePresence instance,
  ) async {
    try {
      await ref
          .read(instancePresencesProvider.notifier)
          .forgetOffline(instance.instanceId);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_instanceRemovalError(error))));
      }
    }
  }

  Future<void> _clearOfflineGroup(
    BuildContext context,
    WidgetRef ref,
    _InstanceMachineGroup group,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('清除 ${group.machine} 的离线实例？'),
        content: Text('将从首页移除 ${group.offline.length} 个离线实例。它们重新连接后会再次出现。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('清除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    var failures = 0;
    Object? firstError;
    for (final instance in group.offline) {
      try {
        await ref
            .read(instancePresencesProvider.notifier)
            .forgetOffline(instance.instanceId);
      } catch (error) {
        failures += 1;
        firstError ??= error;
        if (_gatewayErrorMessage(error) == 'Route not found') break;
      }
    }
    if (failures > 0 && context.mounted) {
      final message = _gatewayErrorMessage(firstError!) == 'Route not found'
          ? _instanceRemovalError(firstError)
          : '$failures 个实例未能删除，请刷新后重试';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

String _instanceRemovalError(Object error) {
  if (error is DioException) {
    if (error.response?.statusCode == 404) {
      return _gatewayErrorMessage(error) == 'Route not found'
          ? '当前服务器尚未部署离线实例清理接口'
          : '该实例已不存在，请刷新后重试';
    }
    if (error.response?.statusCode == 409) {
      return '该实例已重新上线，无法删除';
    }
  }
  return '删除离线实例失败，请刷新后重试';
}

String? _gatewayErrorMessage(Object error) {
  if (error is! DioException) return null;
  final data = error.response?.data;
  if (data is! Map<Object?, Object?>) return null;
  final detail = data['error'];
  if (detail is! Map<Object?, Object?>) return null;
  return detail['message'] as String?;
}

class _InstanceMachineGroup {
  const _InstanceMachineGroup({required this.machine, required this.instances});

  final String machine;
  final List<OpenCodeInstancePresence> instances;

  int get activeCount => instances
      .where((instance) => instance.state != InstancePresenceState.offline)
      .length;

  List<OpenCodeInstancePresence> get offline => instances
      .where((instance) => instance.state == InstancePresenceState.offline)
      .toList(growable: false);
}

List<_InstanceMachineGroup> _groupInstances(
  Iterable<OpenCodeInstancePresence> instances,
) {
  final grouped = <String, List<OpenCodeInstancePresence>>{};
  for (final instance in instances) {
    final key = instance.machine.trim().toLowerCase();
    grouped.putIfAbsent(key, () => []).add(instance);
  }
  final groups = [
    for (final entries in grouped.values)
      _InstanceMachineGroup(machine: entries.first.machine, instances: entries),
  ];
  for (final group in groups) {
    group.instances.sort((left, right) {
      final byState = _presenceOrder(
        left.state,
      ).compareTo(_presenceOrder(right.state));
      if (byState != 0) return byState;
      final bySeen = right.lastSeenAt.compareTo(left.lastSeenAt);
      if (bySeen != 0) return bySeen;
      return left.project.toLowerCase().compareTo(right.project.toLowerCase());
    });
  }
  groups.sort((left, right) {
    final byActive = right.activeCount.compareTo(left.activeCount);
    if (byActive != 0) return byActive;
    return left.machine.toLowerCase().compareTo(right.machine.toLowerCase());
  });
  return groups;
}

int _presenceOrder(InstancePresenceState state) => switch (state) {
  InstancePresenceState.controllable => 0,
  InstancePresenceState.conflicting => 1,
  InstancePresenceState.incompatible => 2,
  InstancePresenceState.offline => 3,
};

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

class _MachineInstanceGroup extends StatefulWidget {
  const _MachineInstanceGroup({
    super.key,
    required this.group,
    required this.webUi,
    required this.onOpenWebUi,
    required this.onDelete,
    required this.onClearOffline,
  });

  final _InstanceMachineGroup group;
  final WebUiBrowserState webUi;
  final void Function(OpenCodeInstancePresence target) onOpenWebUi;
  final Future<void> Function(OpenCodeInstancePresence target) onDelete;
  final Future<void> Function() onClearOffline;

  @override
  State<_MachineInstanceGroup> createState() => _MachineInstanceGroupState();
}

class _MachineInstanceGroupState extends State<_MachineInstanceGroup> {
  bool _clearing = false;
  bool _expanded = true;
  final ExpansibleController _expansion = ExpansibleController();

  @override
  void dispose() {
    _expansion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    return ExpansionTile(
      key: ValueKey('machine-${group.machine.toLowerCase()}'),
      controller: _expansion,
      initiallyExpanded: true,
      onExpansionChanged: (expanded) => setState(() => _expanded = expanded),
      title: Text(group.machine),
      subtitle: Text('${group.activeCount} 在线 / ${group.instances.length} 个实例'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (group.offline.isNotEmpty)
            IconButton(
              key: ValueKey('clear-offline-${group.machine.toLowerCase()}'),
              tooltip: '清除此机器的离线实例',
              icon: _clearing
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_sweep_outlined),
              onPressed: _clearing
                  ? null
                  : () async {
                      setState(() => _clearing = true);
                      await widget.onClearOffline();
                      if (mounted) setState(() => _clearing = false);
                    },
            ),
          IconButton(
            tooltip: _expanded ? '折叠机器实例' : '展开机器实例',
            icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
            onPressed: () =>
                _expanded ? _expansion.collapse() : _expansion.expand(),
          ),
        ],
      ),
      children: [
        for (final instance in group.instances)
          _InstanceTile(
            instance: instance,
            webUi: widget.webUi,
            onOpenWebUi: widget.onOpenWebUi,
            onDelete: widget.onDelete,
          ),
      ],
    );
  }
}

class _InstanceTile extends StatefulWidget {
  const _InstanceTile({
    required this.instance,
    required this.webUi,
    required this.onOpenWebUi,
    required this.onDelete,
  });

  final OpenCodeInstancePresence instance;
  final WebUiBrowserState webUi;
  final void Function(OpenCodeInstancePresence target) onOpenWebUi;
  final Future<void> Function(OpenCodeInstancePresence target) onDelete;

  @override
  State<_InstanceTile> createState() => _InstanceTileState();
}

class _InstanceTileState extends State<_InstanceTile> {
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    final instance = widget.instance;
    final webUi = widget.webUi;
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
    final webUiOpening = webUi.openingFor(instance.instanceId);
    final webUiActive = webUi.activeFor(instance.instanceId);
    return ListTile(
      key: ValueKey('instance-${instance.instanceId}'),
      leading: Icon(icon),
      title: Text(instance.project),
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
              tooltip: webUiActive ? '继续此实例的上次会话' : '打开上次会话或最近会话',
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
              onPressed: webUiOpening
                  ? null
                  : () => widget.onOpenWebUi(instance),
            ),
          if (instance.state == InstancePresenceState.offline)
            IconButton(
              key: ValueKey('delete-instance-${instance.instanceId}'),
              tooltip: '删除离线实例',
              icon: _deleting
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
              onPressed: _deleting
                  ? null
                  : () async {
                      setState(() => _deleting = true);
                      await widget.onDelete(instance);
                      if (mounted) setState(() => _deleting = false);
                    },
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

class _SessionSearchField extends ConsumerStatefulWidget {
  const _SessionSearchField();
  @override
  ConsumerState<_SessionSearchField> createState() =>
      _SessionSearchFieldState();
}

class _SessionSearchFieldState extends ConsumerState<_SessionSearchField> {
  late final TextEditingController _text = TextEditingController(
    text: ref.read(sessionCatalogProvider).search,
  );
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(
      sessionCatalogProvider.select((state) => state.search),
    );
    ref.listen(sessionCatalogProvider.select((state) => state.search), (
      _,
      next,
    ) {
      if (_text.text.trim() != next) _text.text = next;
    });
    return TextField(
      key: const ValueKey('session-search'),
      controller: _text,
      maxLength: 200,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: '搜索会话、项目或机器',
        counterText: '',
        border: const OutlineInputBorder(),
        suffixIcon: query.isEmpty
            ? null
            : IconButton(
                key: const ValueKey('clear-session-search'),
                tooltip: '清空搜索',
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _text.clear();
                  ref.read(sessionCatalogProvider.notifier).search('');
                },
              ),
      ),
      onChanged: ref.read(sessionCatalogProvider.notifier).search,
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.target,
    required this.webUi,
    required this.onOpenWebUi,
    this.pinned,
    this.statusLabel,
    this.onPin,
  });

  final ActiveSession session;
  final bool? pinned;
  final String? statusLabel;
  final VoidCallback? onPin;
  final OpenCodeInstancePresence? target;
  final WebUiBrowserState webUi;
  final void Function(ActiveSession session, OpenCodeInstancePresence target)
  onOpenWebUi;

  @override
  Widget build(BuildContext context) {
    final pending = session.pendingRequestIds;
    final targetId = target?.instanceId;
    final webUiOpening = targetId != null && webUi.openingFor(targetId);
    final webUiActive = targetId != null && webUi.activeFor(targetId);
    final actions = <Widget>[
      if (onPin != null)
        IconButton(
          tooltip: pinned == true ? '取消固定' : '固定会话',
          icon: Icon(pinned == true ? Icons.star : Icons.star_border),
          onPressed: onPin,
        ),
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
              builder: (_) =>
                  SessionPromptPage(session: session, target: target!),
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
                  webUiActive ? Icons.open_in_browser : Icons.language_outlined,
                ),
          onPressed: webUiOpening ? null : () => onOpenWebUi(session, target!),
        ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked =
            constraints.maxWidth < 560 ||
            MediaQuery.textScalerOf(context).scale(14) > 21;
        final subtitle = Text(
          statusLabel == null
              ? '${session.title} · ${_elapsedText()}'
              : '${session.machine} · ${session.project}\n${pending.isNotEmpty ? "等待输入" : statusLabel} · ${_elapsedText()}',
        );
        return ListTile(
          key: ValueKey('session-${session.sessionId}'),
          title: Text(
            statusLabel == null
                ? '${session.machine} · ${session.project}'
                : session.title,
          ),
          subtitle: stacked && actions.isNotEmpty
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    subtitle,
                    Wrap(
                      spacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: actions,
                    ),
                  ],
                )
              : subtitle,
          trailing: stacked || actions.isEmpty
              ? null
              : Row(mainAxisSize: MainAxisSize.min, children: actions),
        );
      },
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
