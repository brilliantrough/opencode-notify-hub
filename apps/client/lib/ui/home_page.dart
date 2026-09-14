import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../pending/pending_controller.dart';
import '../pending/pending_interaction.dart';
import '../realtime/instance_presence.dart';
import '../realtime/realtime_controller.dart';
import '../realtime/ws_client.dart';
import '../sessions/session_catalog.dart';
import '../sessions/session_target.dart';
import '../sessions/webui_browser_controller.dart';
import 'pending_interaction_page.dart';
import 'session_prompt_page.dart';

final wsStatusProvider = StreamProvider<WsStatus>((ref) {
  if (ref.watch(realtimeControllerProvider) == null) {
    return Stream.value(WsStatus.disconnected);
  }
  return ref.watch(wsClientProvider).status;
});

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _search = TextEditingController();
  bool _history = false;
  bool _refreshing = false;
  int _shown = 20;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _save(Future<String?> operation) async {
    final error = await operation;
    if (error != null) _message(error);
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      await ref.read(instancePresencesProvider.notifier).refresh();
    } catch (_) {
      _message('获取在线入口失败，请检查 Gateway 连接后重试');
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _open(
    OpenCodeInstancePresence instance, [
    RemoteSession? session,
  ]) async {
    final error = await ref
        .read(webUiBrowserControllerProvider.notifier)
        .open(
          instance.instanceId,
          directory: instance.directory,
          sessionId: session?.session.sessionId,
        );
    if (!mounted) return;
    if (error != null) {
      _message(error);
    } else if (session != null) {
      await ref
          .read(sessionCatalogProvider.notifier)
          .markOpened(instance.instanceId, session.session.sessionId);
    }
  }

  Future<void> _forget(OpenCodeInstancePresence instance) async {
    try {
      await ref
          .read(instancePresencesProvider.notifier)
          .forgetOffline(instance.instanceId);
    } catch (_) {
      _message('本机历史删除未能保存，请重试');
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(wsStatusProvider).value ?? WsStatus.disconnected;
    final instances = ref.watch(instancePresencesProvider);
    final catalog = ref.watch(sessionCatalogProvider);
    final webUi = ref.watch(webUiBrowserControllerProvider);
    final pending = ref.watch(pendingInteractionsProvider);
    final interactions = (pending.value ?? const <PendingInteraction>[])
        .where(
          (item) =>
              instances[item.instanceId]?.state ==
              InstancePresenceState.controllable,
        )
        .toList();
    final offlineRequests = ref.watch(offlineLastKnownProvider);
    final query = _search.text.trim().toLowerCase();
    bool matches(String text) => text.toLowerCase().contains(query);
    final entries =
        instances.values
            .where(
              (i) =>
                  (_history
                      ? i.state == InstancePresenceState.offline
                      : i.state != InstancePresenceState.offline) &&
                  matches('${i.machine} ${i.project} ${i.directory}'),
            )
            .toList()
          ..sort((a, b) {
            final followed = (catalog.isFollowed(b) ? 1 : 0).compareTo(
              catalog.isFollowed(a) ? 1 : 0,
            );
            return followed != 0
                ? followed
                : '${a.machine} ${a.project}'.compareTo(
                    '${b.machine} ${b.project}',
                  );
          });
    // History includes previously hidden records so every local item can be deleted.
    final sessions =
        catalog.sessions.values
            .where(
              (s) =>
                  !catalog.deletedSessions.contains(s.key) &&
                  matches(
                    '${s.session.title} ${s.session.machine} ${s.session.project} ${s.session.directory}',
                  ),
            )
            .toList()
          ..sort((a, b) {
            if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
            return (b.openedAt ?? b.session.lastHeartbeatAt).compareTo(
              a.openedAt ?? a.session.lastHeartbeatAt,
            );
          });
    return Scaffold(
      appBar: AppBar(
        title: const Text('首页'),
        actions: [
          IconButton(
            key: const ValueKey('presence-refresh'),
            tooltip: '刷新在线入口',
            onPressed: _refreshing ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
          if (webUi.connections.isNotEmpty)
            IconButton(
              tooltip: '关闭全部 WebUI 连接',
              icon: const Icon(Icons.link_off),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  label: Text('在线入口'),
                  icon: Icon(Icons.dns_outlined),
                ),
                ButtonSegment(
                  value: true,
                  label: Text('本机历史'),
                  icon: Icon(Icons.history),
                ),
              ],
              selected: {_history},
              onSelectionChanged: (values) {
                FocusScope.of(context).unfocus();
                setState(() {
                  _history = values.single;
                  _shown = 20;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              key: const ValueKey('session-search'),
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
              onChanged: (_) => setState(() => _shown = 20),
              decoration: InputDecoration(
                hintText: _history ? '搜索本机会话、项目或机器' : '搜索项目或机器',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: '清空搜索',
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() {
                          _search.clear();
                          _shown = 20;
                        }),
                      ),
              ),
            ),
          ),
          if (_refreshing) const LinearProgressIndicator(),
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                if (!_history) ...[
                  if (interactions.isNotEmpty || pending.hasError)
                    ListTile(
                      title: Text(pending.hasError ? '待处理请求暂不可用' : '待处理请求'),
                      trailing: IconButton(
                        tooltip: '刷新待处理请求',
                        icon: const Icon(Icons.refresh),
                        onPressed: () => unawaited(
                          ref
                              .read(pendingInteractionsProvider.notifier)
                              .refresh(),
                        ),
                      ),
                    ),
                  for (final item in interactions) _requestTile(item),
                  if (webUi.connections.isNotEmpty)
                    ExpansionTile(
                      title: Text('浏览器连接 · ${webUi.connections.length}'),
                      children: [
                        for (final connection in webUi.connections.values)
                          _LocalConnectionTile(
                            instanceId: connection.instanceId,
                            title:
                                instances[connection.instanceId]?.project ??
                                'OpenCode',
                            uri: connection.localUri,
                            reconnecting:
                                connection.status != WebUiBrowserStatus.active,
                          ),
                      ],
                    ),
                  if (entries.isEmpty)
                    ListTile(
                      title: const Text('暂无在线入口'),
                      subtitle: Text(
                        status == WsStatus.connected
                            ? '服务器 Plugin 连接 Gateway 后会自动出现'
                            : '正在等待 Gateway 连接；历史记录可在“本机历史”查看',
                      ),
                    ),
                  for (final entry in entries.take(_shown))
                    _entryTile(entry, catalog, webUi),
                  if (entries.length > _shown) _more('显示更多在线入口'),
                  if (sessions.any((s) => s.pinned))
                    ExpansionTile(
                      title: const Text('固定会话快捷入口'),
                      children: [
                        for (final session in sessions.where((s) => s.pinned))
                          _sessionTile(session, instances, webUi),
                      ],
                    ),
                ] else ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('仅保存本机记录；删除不会删除服务器会话或其他客户端的数据。'),
                  ),
                  if (offlineRequests.isNotEmpty)
                    ExpansionTile(
                      title: Text('离线请求（只读） · ${offlineRequests.length}'),
                      children: [
                        for (final item in offlineRequests)
                          _requestTile(item.interaction, offline: item),
                      ],
                    ),
                  if (entries.isNotEmpty) const _SectionHeader('离线入口'),
                  for (final entry in entries.take(_shown))
                    _entryTile(entry, catalog, webUi),
                  if (sessions.isNotEmpty) const _SectionHeader('固定与历史会话'),
                  for (final session in sessions.take(_shown))
                    _sessionTile(session, instances, webUi),
                  if (entries.length > _shown || sessions.length > _shown)
                    _more('显示更多历史记录'),
                  if (entries.isEmpty &&
                      sessions.isEmpty &&
                      offlineRequests.isEmpty)
                    const ListTile(title: Text('暂无本机历史')),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _more(String label) => TextButton(
    onPressed: () => setState(() => _shown += 20),
    child: Text(label),
  );

  Widget _entryTile(
    OpenCodeInstancePresence instance,
    SessionCatalogState catalog,
    WebUiBrowserState webUi,
  ) {
    final label = switch (instance.state) {
      InstancePresenceState.controllable =>
        instance.webUiAvailable ? '在线' : '在线 · 仅通知',
      InstancePresenceState.conflicting => '在线 · 项目冲突',
      InstancePresenceState.incompatible => '在线 · Plugin 协议不兼容',
      InstancePresenceState.offline => '离线',
    };
    final version = instance.openCodeVersion == 'unknown'
        ? ''
        : ' · OpenCode ${instance.openCodeVersion}';
    return ListTile(
      key: ValueKey('instance-${instance.instanceId}'),
      title: Text('${instance.machine} · ${instance.project}'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label$version'),
          Text(
            instance.directory,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              if (instance.canOpen)
                FilledButton.tonalIcon(
                  key: ValueKey('webui-instance-${instance.instanceId}'),
                  onPressed: webUi.openingFor(instance.instanceId)
                      ? null
                      : () => _open(instance),
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text('打开'),
                ),
              if (instance.state != InstancePresenceState.offline)
                IconButton(
                  tooltip: catalog.isFollowed(instance) ? '取消关注' : '关注此入口',
                  icon: Icon(
                    catalog.isFollowed(instance)
                        ? Icons.star
                        : Icons.star_outline,
                  ),
                  onPressed: () => _save(
                    ref
                        .read(sessionCatalogProvider.notifier)
                        .toggleFollow(instance),
                  ),
                ),
              if (instance.state == InstancePresenceState.offline)
                IconButton(
                  key: ValueKey('delete-instance-${instance.instanceId}'),
                  tooltip: '删除本机离线入口记录',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _forget(instance),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sessionTile(
    RemoteSession item,
    Map<String, OpenCodeInstancePresence> instances,
    WebUiBrowserState webUi,
  ) {
    final session = item.session;
    final target = sessionControlTarget(session, instances.values);
    return ListTile(
      key: ValueKey('session-${session.sessionId}'),
      title: Text(session.title.isEmpty ? session.sessionId : session.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${session.machine} · ${session.project} · ${target == null ? "离线记录" : "历史快捷入口"}',
          ),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (target?.canOpen == true)
                TextButton.icon(
                  onPressed: webUi.openingFor(target!.instanceId)
                      ? null
                      : () => _open(target, item),
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text('打开会话'),
                ),
              if (target?.canOpen == true)
                IconButton(
                  tooltip: '发送到 OpenCode',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          SessionPromptPage(session: session, target: target!),
                    ),
                  ),
                ),
              IconButton(
                tooltip: item.pinned ? '取消固定' : '固定会话',
                icon: Icon(item.pinned ? Icons.star : Icons.star_outline),
                onPressed: () => _save(
                  ref.read(sessionCatalogProvider.notifier).togglePin(item),
                ),
              ),
              IconButton(
                tooltip: '删除本机会话记录',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _save(
                  ref.read(sessionCatalogProvider.notifier).deleteSession(item),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _requestTile(
    PendingInteraction item, {
    OfflinePendingInteraction? offline,
  }) => ListTile(
    key: ValueKey(
      '${offline == null ? "interaction" : "offline"}-${item.instanceId}-${item.requestId}',
    ),
    leading: Icon(
      item is PendingQuestion ? Icons.help_outline : Icons.shield_outlined,
    ),
    title: Text('${item.machine} · ${item.project}'),
    subtitle: Text(
      '${item.sessionTitle.isEmpty ? item.sessionId : item.sessionTitle} · ${item is PendingQuestion ? "待回答" : "待授权"}',
    ),
    trailing: offline == null
        ? null
        : IconButton(
            tooltip: '删除本机离线请求记录',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => ref
                .read(pendingInteractionsProvider.notifier)
                .forgetOffline(item),
          ),
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PendingInteractionPage(
          interaction: item,
          readOnly: offline != null,
          lastSeenAt: offline?.lastSeenAt,
        ),
      ),
    ),
  );
}

class _LocalConnectionTile extends ConsumerWidget {
  const _LocalConnectionTile({
    required this.instanceId,
    required this.title,
    required this.uri,
    required this.reconnecting,
  });
  final String instanceId;
  final String title;
  final Uri? uri;
  final bool reconnecting;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ListTile(
    title: Text('$title · ${reconnecting ? "正在重连" : "已连接"}'),
    subtitle: Text(uri?.origin ?? ''),
    onTap: uri == null
        ? null
        : () async {
            final error = await ref
                .read(webUiBrowserControllerProvider.notifier)
                .reopen(instanceId);
            if (error != null && context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(error)));
            }
          },
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (uri != null)
          IconButton(
            tooltip: '复制浏览器地址',
            icon: const Icon(Icons.copy),
            onPressed: () async {
              try {
                await Clipboard.setData(ClipboardData(text: uri.toString()));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('地址已复制；需在本机保持 Notify 运行')),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('复制失败，请重试')));
                }
              }
            },
          ),
        IconButton(
          tooltip: '关闭此 WebUI 连接',
          icon: const Icon(Icons.link_off),
          onPressed: () => unawaited(
            ref.read(webUiBrowserControllerProvider.notifier).close(instanceId),
          ),
        ),
      ],
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: Text(title, style: Theme.of(context).textTheme.titleSmall),
  );
}

class WsStatusChip extends StatelessWidget {
  const WsStatusChip({super.key, required this.status});
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
