import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/server_config.dart';
import '../config/server_switcher.dart';

Future<bool?> showServerSettingsDialog(BuildContext context) =>
    showDialog<bool>(
      context: context,
      builder: (_) => const ServerSettingsDialog(),
    );

class ServerSettingsDialog extends ConsumerStatefulWidget {
  const ServerSettingsDialog({super.key});

  static const addressFieldKey = ValueKey('server-settings-address');
  static const saveKey = ValueKey('server-settings-save');

  @override
  ConsumerState<ServerSettingsDialog> createState() =>
      _ServerSettingsDialogState();
}

class _ServerSettingsDialogState extends ConsumerState<ServerSettingsDialog> {
  late final TextEditingController _addressController;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(
      text: ref.read(serverConfigProvider).gatewayHttpBase,
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final changed = await ref
          .read(serverSwitcherProvider)
          .switchTo(_addressController.text);
      if (mounted) {
        Navigator.of(context).pop(changed);
      }
    } on FormatException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = '无法保存服务器配置');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('服务器设置'),
    content: SizedBox(
      width: 420,
      child: TextField(
        key: ServerSettingsDialog.addressFieldKey,
        controller: _addressController,
        enabled: !_saving,
        autofocus: true,
        keyboardType: TextInputType.url,
        decoration: InputDecoration(
          labelText: '服务器地址',
          helperText: '使用 HTTPS；本机调试可以使用 HTTP',
          errorText: _error,
        ),
        onSubmitted: _saving ? null : (_) => _save(),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.of(context).pop(false),
        child: const Text('取消'),
      ),
      FilledButton.icon(
        key: ServerSettingsDialog.saveKey,
        onPressed: _saving ? null : _save,
        icon: _saving
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.swap_horiz),
        label: const Text('切换服务器'),
      ),
    ],
  );
}
