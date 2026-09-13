import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ingest_keys/ingest_keys_controller.dart';
import 'key_setup_dialog.dart';

class IngestKeysPage extends ConsumerStatefulWidget {
  const IngestKeysPage({super.key});
  @override
  ConsumerState<IngestKeysPage> createState() => _IngestKeysPageState();
}

class _IngestKeysPageState extends ConsumerState<IngestKeysPage> {
  bool _creating = false;
  bool _refreshing = false;
  final _revoking = <String>{};

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      await ref.read(ingestKeysControllerProvider.notifier).list();
    } catch (_) {
      _message('刷新失败，请检查连接后重试');
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _revoke(IngestKey key) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('撤销「${key.name}」？'),
        content: const Text('使用此密钥的 OpenCode 实例将停止接入，需要换用其他密钥。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('撤销密钥'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _revoking.add(key.id));
    try {
      await ref.read(ingestKeysControllerProvider.notifier).revoke(key.id);
      _message('密钥已撤销');
    } catch (_) {
      _message('撤销失败，请重试');
    } finally {
      if (mounted) setState(() => _revoking.remove(key.id));
    }
  }

  Future<void> _create() async {
    if (_creating) return;
    setState(() => _creating = true);
    try {
      final name = await showDialog<String>(
        context: context,
        builder: (_) => const _CreateKeyDialog(),
      );
      if (name == null || !mounted) return;
      final created = await ref
          .read(ingestKeysControllerProvider.notifier)
          .create(name);
      if (!mounted) return;
      await showKeySetupDialog(
        context,
        IngestKey(
          id: created.id,
          name: created.name,
          createdAt: created.createdAt,
        ),
        createdSecret: created.secret,
      );
    } catch (_) {
      _message('未能完成密钥创建，请刷新列表查看结果');
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keys = ref.watch(ingestKeysControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('接入密钥'),
        actions: [
          IconButton(
            key: const ValueKey('refresh-ingest-keys'),
            tooltip: '刷新',
            icon: const Icon(Icons.refresh),
            onPressed: _refreshing ? null : _refresh,
          ),
        ],
      ),
      body: switch (keys) {
        AsyncData(:final value) => RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 88),
            children: [
              if (_refreshing) const LinearProgressIndicator(),
              if (value.isEmpty)
                const ListTile(
                  title: Text('暂无密钥'),
                  subtitle: Text('新建一条密钥，即可复制服务器配置命令'),
                ),
              for (final key in value)
                ListTile(
                  key: ValueKey(key.id),
                  leading: const Icon(Icons.key_outlined),
                  title: Text(key.name),
                  subtitle: Text(
                    '创建于 ${_date(key.createdAt)} · ${key.lastUsedAt == null ? "从未使用" : "最近使用 ${_date(key.lastUsedAt!)}"}\n点按查看密钥或导出配置',
                  ),
                  onTap: _revoking.contains(key.id)
                      ? null
                      : () => showKeySetupDialog(context, key),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        key: ValueKey('configure-${key.id}'),
                        tooltip: '查看密钥 / 导出配置',
                        icon: const Icon(Icons.terminal),
                        onPressed: _revoking.contains(key.id)
                            ? null
                            : () => showKeySetupDialog(context, key),
                      ),
                      IconButton(
                        key: ValueKey('revoke-${key.id}'),
                        tooltip: '撤销',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: _revoking.contains(key.id)
                            ? null
                            : () => _revoke(key),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        AsyncError() => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('无法加载密钥'),
              TextButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
              ),
            ],
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _creating ? null : _create,
        icon: const Icon(Icons.add),
        label: Text(_creating ? '正在创建…' : '新建密钥'),
      ),
    );
  }

  String _date(DateTime date) => date.toLocal().toString().substring(0, 16);
}

class _CreateKeyDialog extends StatefulWidget {
  const _CreateKeyDialog();
  @override
  State<_CreateKeyDialog> createState() => _CreateKeyDialogState();
}

class _CreateKeyDialogState extends State<_CreateKeyDialog> {
  final _name = TextEditingController();
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (_name.text.trim().isNotEmpty && _name.text.trim().length <= 64) {
      Navigator.pop(context, _name.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('新建密钥'),
    content: TextField(
      controller: _name,
      autofocus: true,
      maxLength: 64,
      decoration: const InputDecoration(labelText: '名称', hintText: '例如 阿里云开发机'),
      onChanged: (_) => setState(() {}),
      onSubmitted: (_) => _submit(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('取消'),
      ),
      FilledButton(
        onPressed: _name.text.trim().isEmpty ? null : _submit,
        child: const Text('创建'),
      ),
    ],
  );
}
