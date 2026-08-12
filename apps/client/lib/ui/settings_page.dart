import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../devices/device_identity.dart';
import '../settings/settings_controller.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final desktopSettingsSupported = ref.watch(
      desktopSettingsSupportedProvider,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          SwitchListTile(
            key: soundSwitchKey,
            title: const Text('提示声音'),
            subtitle: const Text('通知弹出时播放提示音'),
            value: settings.soundEnabled,
            onChanged: controller.setSoundEnabled,
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
        ],
      ),
    );
  }
}
