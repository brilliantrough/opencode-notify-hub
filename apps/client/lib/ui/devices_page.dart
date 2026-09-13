import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notify_api/notify_api.dart';

import '../devices/devices_controller.dart';

/// Registered devices with per-device notification and sound toggles.
class DevicesPage extends ConsumerWidget {
  const DevicesPage({super.key});

  /// Key of a device's enable-notifications switch.
  static Key enabledSwitchKey(String id) => ValueKey('enabled-$id');

  /// Key of a device's alert-sound switch.
  static Key soundSwitchKey(String id) => ValueKey('sound-$id');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(devicesControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('设备'),
        actions: [
          IconButton(
            tooltip: '刷新设备',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(devicesControllerProvider),
          ),
        ],
      ),
      body: switch (devices) {
        AsyncData(:final value) =>
          value.isEmpty
              ? const Center(child: Text('暂无设备'))
              : ListView(
                  children: [
                    for (final device in value) _DeviceTile(device: device),
                  ],
                ),
        AsyncError() => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('无法加载设备'),
              TextButton(
                onPressed: () => ref.invalidate(devicesControllerProvider),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _DeviceTile extends ConsumerWidget {
  const _DeviceTile({required this.device});

  final Device device;

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    var name = device.name;
    final next = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('重命名设备'),
          content: TextFormField(
            initialValue: name,
            autofocus: true,
            maxLength: 64,
            decoration: const InputDecoration(labelText: '设备名称'),
            onChanged: (value) => setState(() => name = value),
            onFieldSubmitted: (_) {
              if (name.trim().isNotEmpty) {
                Navigator.pop(dialogContext, name.trim());
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: name.trim().isEmpty
                  ? null
                  : () => Navigator.pop(dialogContext, name.trim()),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
    if (next == null || next == device.name || !context.mounted) return;
    await _toggle(
      context,
      ref,
      () =>
          ref.read(devicesControllerProvider.notifier).rename(device.id, next),
    );
  }

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    Future<Device> Function() action,
  ) async {
    try {
      await action();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('操作失败: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(devicesControllerProvider.notifier);
    return ListTile(
      key: ValueKey('device-${device.id}'),
      title: Text(device.name),
      subtitle: Text('${device.platform.name} · 点按重命名'),
      onTap: () => _rename(context, ref),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: '接收通知',
            child: Switch(
              key: DevicesPage.enabledSwitchKey(device.id),
              value: device.enabled,
              onChanged: (value) => _toggle(
                context,
                ref,
                () => notifier.setEnabled(device.id, value),
              ),
            ),
          ),
          Tooltip(
            message: '提示声音',
            child: Switch(
              key: DevicesPage.soundSwitchKey(device.id),
              value: device.soundEnabled,
              onChanged: (value) => _toggle(
                context,
                ref,
                () => notifier.setSoundEnabled(device.id, value),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
