import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';

/// Where OpenCode auto-discovers the plugin bundle.
const pluginInstallPath = '~/.config/opencode/plugins/session-notify.js';

/// Static setup guide for the OpenCode session-notify plugin: install path,
/// gateway configuration, ingest key instructions, and the restart note.
/// Values that must be typed elsewhere carry copy buttons.
class PluginSetupPage extends ConsumerWidget {
  const PluginSetupPage({super.key});

  /// Key of the copy button for the plugin install path.
  static const Key copyPathKey = ValueKey('copy-plugin-path');

  /// Key of the copy button for the environment-variable example.
  static const Key copyEnvKey = ValueKey('copy-env-example');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gatewayUrl = ref.watch(appConfigProvider).gatewayHttpBase;
    final envExample =
        'export NOTIFY_GATEWAY_URL=$gatewayUrl\n'
        'export NOTIFY_INGEST_KEY=keyId.secret';
    return Scaffold(
      appBar: AppBar(title: const Text('插件安装')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _StepTitle('1. 安装插件文件'),
          const Text('将构建产物 session-notify.js 复制到 OpenCode 插件目录：'),
          _CopyRow(value: pluginInstallPath, copyKey: copyPathKey),
          const SizedBox(height: 16),
          const _StepTitle('2. 配置环境变量'),
          const Text('在启动 OpenCode 的环境中设置以下变量：'),
          const SizedBox(height: 8),
          Text(envExample),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: copyEnvKey,
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('复制'),
              onPressed: () => _copy(context, envExample),
            ),
          ),
          const SizedBox(height: 8),
          const Text('NOTIFY_GATEWAY_URL 为本客户端连接的网关地址；'
              'NOTIFY_INGEST_KEY 为「密钥」页创建的接入密钥（keyId.secret），'
              '仅在创建时显示一次，请妥善保存。'),
          const SizedBox(height: 16),
          const _StepTitle('3. 重启 OpenCode'),
          const Text('插件在 OpenCode 启动时加载：安装文件或修改环境变量后，'
              '需退出并重启 OpenCode 才能生效。'),
        ],
      ),
    );
  }

  static Future<void> _copy(BuildContext context, String value) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: value));
    messenger.showSnackBar(const SnackBar(content: Text('已复制')));
  }
}

class _StepTitle extends StatelessWidget {
  const _StepTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _CopyRow extends StatelessWidget {
  const _CopyRow({required this.value, required this.copyKey});

  final String value;
  final Key copyKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(value),
        ),
        IconButton(
          key: copyKey,
          icon: const Icon(Icons.copy, size: 16),
          tooltip: '复制',
          onPressed: () => PluginSetupPage._copy(context, value),
        ),
      ],
    );
  }
}
