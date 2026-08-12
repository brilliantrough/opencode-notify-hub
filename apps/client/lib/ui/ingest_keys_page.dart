import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notify_api/notify_api.dart';

import '../ingest_keys/ingest_keys_controller.dart';

/// Lists the authenticated user's ingest keys and manages their lifecycle:
/// creation (with the one-time secret shown exactly once), refresh, and
/// revocation.
class IngestKeysPage extends ConsumerWidget {
  const IngestKeysPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keys = ref.watch(ingestKeysControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('接入密钥')),
      body: switch (keys) {
        AsyncData(:final value) =>
          value.isEmpty
              ? const Center(child: Text('暂无密钥'))
              : ListView(
                  children: [
                    for (final key in value)
                      ListTile(
                        key: ValueKey(key.id),
                        title: Text(key.name),
                        subtitle: Text(_subtitle(key)),
                        trailing: IconButton(
                          key: ValueKey('revoke-${key.id}'),
                          icon: const Icon(Icons.delete_outline),
                          tooltip: '撤销',
                          onPressed: () => _revoke(context, ref, key),
                        ),
                      ),
                  ],
                ),
        AsyncError(:final error) => Center(child: Text('加载失败: $error')),
        _ => const Center(child: CircularProgressIndicator()),
      },
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createKey(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('新建密钥'),
      ),
    );
  }

  static String _subtitle(IngestKey key) {
    final created = '创建于 ${key.createdAt.toLocal()}';
    final lastUsed = key.lastUsedAt;
    return lastUsed == null
        ? '$created · 从未使用'
        : '$created · 最近使用 ${lastUsed.toLocal()}';
  }

  Future<void> _revoke(
    BuildContext context,
    WidgetRef ref,
    IngestKey key,
  ) async {
    try {
      await ref.read(ingestKeysControllerProvider.notifier).revoke(key.id);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('撤销失败: $error')));
      }
    }
  }

  Future<void> _createKey(BuildContext context, WidgetRef ref) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const _CreateKeyDialog(),
    );
    if (name == null || name.isEmpty || !context.mounted) {
      return;
    }
    final CreateIngestKeyResponse created;
    try {
      created = await ref
          .read(ingestKeysControllerProvider.notifier)
          .create(name);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('创建失败: $error')));
      }
      return;
    }
    // The secret is shown exactly once, here in this dialog. It is not in
    // the controller state and is discarded when the dialog closes.
    if (context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (context) => _SecretDialog(secret: created.secret),
      );
    }
  }
}

class _CreateKeyDialog extends StatefulWidget {
  const _CreateKeyDialog();

  @override
  State<_CreateKeyDialog> createState() => _CreateKeyDialogState();
}

class _CreateKeyDialogState extends State<_CreateKeyDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新建密钥'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: '名称'),
        onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('创建'),
        ),
      ],
    );
  }
}

class _SecretDialog extends StatelessWidget {
  const _SecretDialog({required this.secret});

  final String secret;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('密钥已创建'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('密钥仅显示一次，请立即复制保存。'),
          const SizedBox(height: 12),
          SelectableText(
            secret,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ],
      ),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.copy),
          label: const Text('复制'),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: secret));
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('已复制')));
            }
          },
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}
