import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/server_config.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_state.dart';
import '../ingest_keys/ingest_keys_controller.dart';
import '../ingest_keys/local_key_secrets.dart';
import '../ingest_keys/plugin_environment.dart';

Future<void> showKeySetupDialog(
  BuildContext context,
  IngestKey key, {
  String? createdSecret,
}) => showDialog<void>(
  context: context,
  builder: (_) => _KeySetupDialog(keyInfo: key, createdSecret: createdSecret),
);

class _KeySetupDialog extends ConsumerStatefulWidget {
  const _KeySetupDialog({required this.keyInfo, this.createdSecret});
  final IngestKey keyInfo;
  final String? createdSecret;
  @override
  ConsumerState<_KeySetupDialog> createState() => _KeySetupDialogState();
}

class _KeySetupDialogState extends ConsumerState<_KeySetupDialog> {
  final _machine = TextEditingController();
  final _import = TextEditingController();
  PluginShell _shell = PluginShell.bash;
  bool _visible = false;
  bool _saving = false;
  bool _editing = false;
  String? _error;
  late final LocalKeySecrets _store;

  @override
  void initState() {
    super.initState();
    _store = ref.read(localKeySecretsProvider);
  }

  @override
  void dispose() {
    _machine.dispose();
    _import.dispose();
    super.dispose();
  }

  Future<void> _copy(String text, String message) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (_) {
      if (mounted) setState(() => _error = '复制失败，可展开内容后手动选择复制');
    }
  }

  Future<void> _save(String secret, {bool imported = false}) async {
    if (imported &&
        !RegExp(r'^[A-Za-z0-9_-]{12}\.[A-Za-z0-9_-]{43}$').hasMatch(secret)) {
      setState(() => _error = '请输入完整的 keyId.secret 密钥，不包含 export 或引号');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _store.save(widget.keyInfo.id, secret);
      if (!mounted) return;
      ref.invalidate(localKeySecretProvider(widget.keyInfo.id));
      _import.clear();
      setState(() => _editing = false);
    } catch (_) {
      if (mounted) setState(() => _error = '密钥未能保存到本机；仍可复制本次创建的密钥，或重试保存');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    if (auth is! Authenticated ||
        ref.watch(localKeySecretsProvider).scope != _store.scope) {
      return AlertDialog(
        title: const Text('账号已切换'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      );
    }
    final local = ref.watch(localKeySecretProvider(widget.keyInfo.id));
    final secret = _editing ? null : local.value ?? widget.createdSecret;
    final gateway = ref.watch(appConfigProvider).gatewayHttpBase;
    final environment = pluginEnvironment(
      gateway: gateway,
      credential: secret ?? 'keyId.secret',
      machine: _machine.text,
      shell: _shell,
    );
    return AlertDialog(
      scrollable: true,
      title: Text('${widget.keyInfo.name} · 密钥与配置'),
      content: SizedBox(
        width: 560,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (local.isLoading) const LinearProgressIndicator(),
            if (secret != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      local.value != null
                          ? '已保存在本机，可重复查看和复制'
                          : '本次创建的密钥尚未保存到本机',
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('reveal-key'),
                    tooltip: _visible ? '隐藏密钥' : '显示密钥',
                    icon: Icon(
                      _visible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () => setState(() => _visible = !_visible),
                  ),
                ],
              ),
              if (_visible) SelectableText(secret),
              Wrap(
                spacing: 8,
                children: [
                  TextButton.icon(
                    key: const ValueKey('copy-key'),
                    onPressed: () => _copy(secret, '密钥已复制'),
                    icon: const Icon(Icons.copy),
                    label: const Text('复制密钥'),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _editing = true),
                    child: const Text('重新录入'),
                  ),
                  if (local.value == null && !local.isLoading)
                    TextButton(
                      onPressed: _saving ? null : () => _save(secret),
                      child: const Text('重试保存到本机'),
                    ),
                ],
              ),
            ] else if (!local.isLoading) ...[
              Text(
                local.hasError
                    ? '暂时无法读取本机密钥，可以重试或补录已有密钥。'
                    : '这台设备没有保存此密钥。粘贴这条密钥原先保存的完整值，即可反复查看和导出。',
              ),
              TextField(
                key: const ValueKey('import-key'),
                controller: _import,
                obscureText: !_visible,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(
                  labelText: '已有密钥（keyId.secret）',
                ),
              ),
              Wrap(
                children: [
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => _save(_import.text.trim(), imported: true),
                    child: const Text('保存到本机'),
                  ),
                  if (local.hasError)
                    TextButton(
                      onPressed: () => ref.invalidate(
                        localKeySecretProvider(widget.keyInfo.id),
                      ),
                      child: const Text('重试读取'),
                    ),
                ],
              ),
            ],
            const Divider(),
            const Text('服务器环境变量'),
            const SizedBox(height: 8),
            DropdownButtonFormField<PluginShell>(
              isExpanded: true,
              initialValue: _shell,
              decoration: const InputDecoration(labelText: '目标服务器 Shell'),
              items: const [
                DropdownMenuItem(
                  value: PluginShell.bash,
                  child: Text('Bash / Zsh · export'),
                ),
                DropdownMenuItem(
                  value: PluginShell.powershell,
                  child: Text(r'PowerShell · $env:'),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _shell = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('notify-machine'),
              controller: _machine,
              maxLength: 128,
              decoration: const InputDecoration(
                labelText: 'NOTIFY_MACHINE · 服务器名称',
                hintText: '例如 aliyun-dev；留空导出 YOUR_MACHINE_NAME',
              ),
              onChanged: (_) => setState(() {}),
            ),
            SelectableText(
              _visible
                  ? environment
                  : pluginEnvironment(
                      gateway: gateway,
                      credential: secret == null
                          ? 'keyId.secret'
                          : '••••••（复制时包含完整密钥）',
                      machine: _machine.text,
                      shell: _shell,
                    ),
            ),
            const SizedBox(height: 12),
            const Text('在服务器终端粘贴，补齐机器名，再从同一终端启动或重启 OpenCode。变量只对该终端及其子进程生效。'),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
        FilledButton.icon(
          key: const ValueKey('copy-key-env'),
          onPressed: secret == null
              ? null
              : () => _copy(
                  pluginEnvironment(
                    gateway: gateway,
                    credential: secret,
                    machine: _machine.text,
                    shell: _shell,
                  ),
                  _machine.text.trim().isEmpty
                      ? '配置已复制，请替换 YOUR_MACHINE_NAME'
                      : '配置已复制',
                ),
          icon: const Icon(Icons.terminal),
          label: const Text('复制完整配置'),
        ),
      ],
    );
  }
}
