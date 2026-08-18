import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../config/server_config.dart';
import '../devices/device_identity.dart';
import '../notifications/alert_sound.dart';
import '../notifications/custom_sound_store.dart';
import '../notifications/sound_player.dart';
import '../settings/settings_controller.dart';
import 'server_settings_dialog.dart';

/// Whether the current platform supports OS autostart (desktop only:
/// Linux/Windows). Overridable in tests.
final desktopSettingsSupportedProvider = Provider<bool>(
  (ref) => _isDesktopPlatform(),
);

bool _isDesktopPlatform() {
  try {
    final platform = currentPlatform();
    return platform == ClientPlatform.linux ||
        platform == ClientPlatform.windows;
  } on UnsupportedError {
    return false;
  }
}

/// Settings page: alert sound, notification pause, and OS autostart toggles.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  /// Key of the alert-sound switch.
  static const Key soundSwitchKey = ValueKey('settings-sound-switch');
  static const Key alertSoundPickerKey = ValueKey(
    'settings-alert-sound-picker',
  );
  static const Key alertSoundDialogKey = ValueKey(
    'settings-alert-sound-dialog',
  );
  static const Key importSoundKey = ValueKey('settings-import-sound');

  static Key soundOptionKey(String id) => ValueKey('settings-sound-option-$id');

  static Key soundPreviewKey(String id) =>
      ValueKey('settings-sound-preview-$id');

  /// Key of the pause-notifications switch.
  static const Key pauseSwitchKey = ValueKey('settings-pause-switch');

  /// Key of the launch-at-startup switch.
  static const Key autostartSwitchKey = ValueKey('settings-autostart-switch');

  static const Key textScaleSliderKey = ValueKey('settings-text-scale-slider');
  static const Key textScaleDecreaseKey = ValueKey(
    'settings-text-scale-decrease',
  );
  static const Key textScaleIncreaseKey = ValueKey(
    'settings-text-scale-increase',
  );
  static const Key textScaleResetKey = ValueKey('settings-text-scale-reset');
  static const Key logoutKey = ValueKey('settings-logout');
  static const Key confirmLogoutKey = ValueKey('settings-confirm-logout');
  static const Key serverKey = ValueKey('settings-server');

  Future<void> _previewSound(
    BuildContext context,
    WidgetRef ref,
    AlertSound sound,
  ) async {
    try {
      await ref.read(soundPreviewPlayerProvider).play(sound);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('无法播放这个提示音')));
      }
    }
  }

  Future<void> _importSound(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(settingsControllerProvider.notifier).importCustomSound();
    } on CustomSoundImportException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('导入提示音失败')));
      }
    }
  }

  Future<void> _showAlertSoundPicker(BuildContext context, WidgetRef ref) =>
      showDialog<void>(
        context: context,
        builder: (dialogContext) => Consumer(
          builder: (context, dialogRef, _) {
            final settings = dialogRef.watch(settingsControllerProvider);
            final sounds = <AlertSound>[
              ...bundledAlertSounds,
              if (settings.customSound != null) settings.customSound!,
            ];
            return AlertDialog(
              key: alertSoundDialogKey,
              title: const Text('选择提示音'),
              content: SizedBox(
                width: 440,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 430),
                  child: SingleChildScrollView(
                    child: RadioGroup<String>(
                      groupValue: settings.alertSoundId,
                      onChanged: (id) {
                        if (id != null) {
                          unawaited(
                            dialogRef
                                .read(settingsControllerProvider.notifier)
                                .setAlertSound(id),
                          );
                        }
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final sound in sounds)
                            RadioListTile<String>(
                              key: soundOptionKey(sound.id),
                              value: sound.id,
                              controlAffinity: ListTileControlAffinity.leading,
                              title: Text(sound.displayName),
                              subtitle: Text(
                                sound is BundledAlertSound
                                    ? sound.sourceName
                                    : '本机自定义',
                              ),
                              secondary: IconButton(
                                key: soundPreviewKey(sound.id),
                                tooltip: '试听 ${sound.displayName}',
                                onPressed: () => unawaited(
                                  _previewSound(context, dialogRef, sound),
                                ),
                                icon: const Icon(Icons.play_arrow),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton.icon(
                  key: importSoundKey,
                  onPressed: () => unawaited(_importSound(context, dialogRef)),
                  icon: const Icon(Icons.upload_file),
                  label: Text(
                    settings.customSound == null ? '导入音频' : '替换自定义音频',
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('完成'),
                ),
              ],
            );
          },
        ),
      );

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认退出登录？'),
        content: const Text('将清除此设备上保存的登录状态。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton.icon(
            key: confirmLogoutKey,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.logout),
            label: const Text('退出登录'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final desktopSettingsSupported = ref.watch(
      desktopSettingsSupportedProvider,
    );
    final server = ref.watch(serverConfigProvider).gatewayHttpBase;
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          ListTile(
            key: serverKey,
            leading: const Icon(Icons.dns_outlined),
            title: const Text('服务器'),
            subtitle: Text(
              server,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showServerSettingsDialog(context),
          ),
          const Divider(height: 1),
          SwitchListTile(
            key: soundSwitchKey,
            title: const Text('提示声音'),
            subtitle: const Text('通知弹出时播放提示音'),
            value: settings.soundEnabled,
            onChanged: controller.setSoundEnabled,
          ),
          if (desktopSettingsSupported)
            ListTile(
              key: alertSoundPickerKey,
              enabled: settings.soundEnabled,
              leading: const Icon(Icons.notifications_active_outlined),
              title: const Text('提示音'),
              subtitle: Text(settings.alertSound.displayName),
              trailing: const Icon(Icons.chevron_right),
              onTap: settings.soundEnabled
                  ? () => _showAlertSoundPicker(context, ref)
                  : null,
            ),
          SwitchListTile(
            key: pauseSwitchKey,
            title: const Text('暂停通知'),
            subtitle: const Text('暂停弹出通知（仍会记录到历史）'),
            value: settings.paused,
            onChanged: controller.setPaused,
          ),
          // OS autostart only exists on desktop platforms.
          if (desktopSettingsSupported)
            SwitchListTile(
              key: autostartSwitchKey,
              title: const Text('开机自启'),
              subtitle: const Text('登录系统后自动启动'),
              value: settings.launchAtStartup,
              onChanged: controller.setLaunchAtStartup,
            ),
          if (desktopSettingsSupported) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '字体缩放',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      Text('${(settings.textScale * 100).round()}%'),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        key: textScaleDecreaseKey,
                        tooltip: '缩小字体',
                        onPressed:
                            settings.textScale <=
                                SettingsController.minTextScale
                            ? null
                            : () => unawaited(controller.decreaseTextScale()),
                        icon: const Icon(Icons.remove),
                      ),
                      Expanded(
                        child: Slider(
                          key: textScaleSliderKey,
                          value: settings.textScale,
                          min: SettingsController.minTextScale,
                          max: SettingsController.maxTextScale,
                          divisions: 15,
                          onChanged: (value) =>
                              unawaited(controller.setTextScale(value)),
                        ),
                      ),
                      IconButton(
                        key: textScaleIncreaseKey,
                        tooltip: '放大字体',
                        onPressed:
                            settings.textScale >=
                                SettingsController.maxTextScale
                            ? null
                            : () => unawaited(controller.increaseTextScale()),
                        icon: const Icon(Icons.add),
                      ),
                      IconButton(
                        key: textScaleResetKey,
                        tooltip: '重置字体缩放',
                        onPressed: settings.textScale == 1
                            ? null
                            : () => unawaited(controller.resetTextScale()),
                        icon: const Icon(Icons.restart_alt),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const Divider(height: 1),
          ListTile(
            key: logoutKey,
            leading: const Icon(Icons.logout),
            title: const Text('退出登录'),
            subtitle: const Text('清除本机登录状态并切换账号'),
            onTap: () => _confirmLogout(context, ref),
          ),
        ],
      ),
    );
  }
}
