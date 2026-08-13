import 'dart:async';
import 'dart:io';

import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../devices/device_identity.dart';

/// Tray context-menu item keys.
abstract final class TrayMenuKeys {
  /// Shows and focuses the main window.
  static const String showWindow = 'show_window';

  /// Toggles notification pause (checkbox item).
  static const String pauseNotifications = 'pause_notifications';

  /// Quits the application.
  static const String quit = 'quit';
}

/// Builds the tray context menu: 打开窗口, 暂停通知 (checkbox reflecting
/// [paused]), a separator, and 退出.
///
/// Pure and synchronous so it is unit-testable without a desktop
/// environment. Clicking the pause checkbox flips its own `checked` flag
/// (which lets `tray_manager` detect the change and re-apply the menu) and
/// reports the new value through [onSetPaused].
Menu buildTrayMenu({
  required bool paused,
  required void Function() onShowWindow,
  required void Function(bool paused) onSetPaused,
  required void Function() onQuit,
}) {
  return Menu(
    items: [
      MenuItem(
        key: TrayMenuKeys.showWindow,
        label: '打开窗口',
        onClick: (_) => onShowWindow(),
      ),
      MenuItem.checkbox(
        key: TrayMenuKeys.pauseNotifications,
        label: '暂停通知',
        checked: paused,
        onClick: (item) {
          final next = !(item.checked ?? false);
          item.checked = next;
          onSetPaused(next);
        },
      ),
      MenuItem.separator(),
      MenuItem(key: TrayMenuKeys.quit, label: '退出', onClick: (_) => onQuit()),
    ],
  );
}

/// Desktop system-tray integration: tray icon with a context menu and
/// close-to-tray window behavior.
///
/// Desktop-only: [init] is a no-op unless [isDesktop] (default: derived from
/// [currentPlatform]) reports Linux or Windows, so constructing the
/// controller on Android never touches the tray/window platform channels.
///
/// The controller owns no settings state; it reads the paused flag through
/// [readPaused] and reports changes through [writePaused], keeping the
/// `SettingsController` the single source of truth.
class TrayController with TrayListener, WindowListener {
  TrayController({
    required bool Function() readPaused,
    required Future<void> Function(bool paused) writePaused,
    Future<void> Function()? showWindow,
    Future<void> Function()? quit,
    bool Function()? isDesktop,
    bool Function()? isLinux,
  }) : _readPaused = readPaused,
       _writePaused = writePaused,
       _showWindow = showWindow ?? _defaultShowWindow,
       _quit = quit ?? _defaultQuit,
       _isDesktop = isDesktop ?? _defaultIsDesktop,
       _isLinux = isLinux ?? (() => Platform.isLinux);

  final bool Function() _readPaused;
  final Future<void> Function(bool paused) _writePaused;
  final Future<void> Function() _showWindow;
  final Future<void> Function() _quit;
  final bool Function() _isDesktop;
  final bool Function() _isLinux;

  static bool _defaultIsDesktop() {
    final platform = currentPlatform();
    return platform == ClientPlatform.linux ||
        platform == ClientPlatform.windows;
  }

  static Future<void> _defaultShowWindow() async {
    await windowManager.restore();
    await windowManager.show();
    await windowManager.focus();
  }

  static Future<void> _defaultQuit() async {
    await windowManager.setPreventClose(false);
    await trayManager.destroy();
    await windowManager.destroy();
  }

  /// Asset path of the tray icon for the current desktop platform.
  static String trayIconAsset() => Platform.isWindows
      ? 'windows/runner/resources/app_icon.ico'
      : 'assets/tray/icon.png';

  /// Installs the tray icon/menu and close-to-tray behavior. No-op off
  /// desktop.
  Future<void> init() async {
    if (!_isDesktop()) {
      return;
    }
    await windowManager.setPreventClose(true);
    windowManager.addListener(this);
    trayManager.addListener(this);
    await trayManager.setIcon(trayIconAsset());
    await refreshMenu();
    // tray_manager 0.5.3 does not implement setToolTip on Linux.
    if (!_isLinux()) {
      await trayManager.setToolTip('opencode-notify');
    }
  }

  /// Rebuilds and re-applies the tray context menu from current settings.
  Future<void> refreshMenu() {
    return trayManager.setContextMenu(
      buildTrayMenu(
        paused: _readPaused(),
        onShowWindow: () => unawaited(_showWindow()),
        onSetPaused: (paused) => unawaited(_writePaused(paused)),
        onQuit: () => unawaited(_quit()),
      ),
    );
  }

  /// Removes listeners. Call on app shutdown.
  void dispose() {
    windowManager.removeListener(this);
    trayManager.removeListener(this);
  }

  /// Close-to-tray: with `setPreventClose(true)` the close request lands
  /// here; the window hides instead of exiting.
  @override
  void onWindowClose() {
    unawaited(windowManager.hide());
  }

  @override
  void onTrayIconMouseUp() {
    if (_isLinux()) {
      unawaited(_showWindow());
    }
  }

  /// tray_manager 0.5.3 emits this callback for a Windows left-button release.
  @override
  void onTrayIconMouseDown() {
    if (!_isLinux()) {
      unawaited(_showWindow());
    }
  }

  /// Windows requires the Dart side to explicitly display the native menu.
  @override
  void onTrayIconRightMouseDown() {
    if (!_isLinux()) {
      unawaited(trayManager.popUpContextMenu());
    }
  }
}
