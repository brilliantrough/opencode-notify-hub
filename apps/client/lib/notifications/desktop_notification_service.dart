import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:local_notifier/local_notifier.dart';
import 'package:path/path.dart' as path;
import 'package:win_toast/win_toast.dart' as windows;
import 'package:window_manager/window_manager.dart';

import 'notification_service.dart';
import 'sound_player.dart';

/// Abstraction over the OS notification popup so the service stays testable
/// without invoking platform channels.
abstract class DesktopNotifier {
  Future<void> init();

  /// Presents a popup notification; [onClick] fires when the user clicks it.
  Future<void> show({
    required String identifier,
    required String title,
    required String body,
    void Function()? onClick,
  });
}

/// [DesktopNotifier] backed by `local_notifier`.
class LocalNotifierAdapter implements DesktopNotifier {
  @override
  Future<void> init() => localNotifier.setup(appName: 'opencode-notify');

  @override
  Future<void> show({
    required String identifier,
    required String title,
    required String body,
    void Function()? onClick,
  }) {
    final notification = LocalNotification(
      identifier: identifier,
      title: title,
      body: body,
    );
    notification.onClick = onClick;
    return notification.show();
  }
}

/// Windows toast adapter with a COM activator for Notification Center clicks.
class WindowsDesktopNotifier implements DesktopNotifier {
  WindowsDesktopNotifier({
    windows.WinToast? toast,
    DesktopNotifier? fallback,
    String? iconPath,
  }) : _toast = toast ?? windows.WinToast.instance(),
       _iconPath = iconPath ?? _defaultIconPath(),
       _fallback = fallback ?? LocalNotifierAdapter();

  // Packaged apps require this; WinToast derives a CLSID for portable EXEs.
  static const _packagedActivatorClsid = 'a7b13c08-dcf4-47d2-a074-0e203f6ef4bd';
  static const _group = 'opencode-notify';
  static const _maxCallbacks = 100;

  final windows.WinToast _toast;
  final String _iconPath;
  final DesktopNotifier _fallback;
  final LinkedHashMap<String, void Function()> _callbacks = LinkedHashMap();
  bool _useFallback = false;

  @override
  Future<void> init() async {
    _toast.setActivatedCallback(_onActivated);
    final initialized = await _toast.initialize(
      aumId: 'dev.opencodenotify.client',
      displayName: 'OpenCode Notify',
      iconPath: _iconPath,
      clsid: _packagedActivatorClsid,
    );
    if (!initialized) {
      _useFallback = true;
      await _fallback.init();
    }
  }

  @override
  Future<void> show({
    required String identifier,
    required String title,
    required String body,
    void Function()? onClick,
  }) async {
    if (_useFallback) {
      return _fallback.show(
        identifier: identifier,
        title: title,
        body: body,
        onClick: onClick,
      );
    }

    if (onClick != null) {
      if (_callbacks.length >= _maxCallbacks) {
        _callbacks.remove(_callbacks.keys.first);
      }
      _callbacks[identifier] = onClick;
    }

    try {
      await _toast.showToast(
        toast: windows.Toast(
          launch: identifier,
          children: [
            windows.ToastChildVisual(
              binding: windows.ToastVisualBinding(
                children: [
                  windows.ToastVisualBindingChildText(text: title, id: 1),
                  windows.ToastVisualBindingChildText(text: body, id: 2),
                ],
              ),
            ),
            windows.ToastChildAudio(silent: true),
          ],
        ),
        tag: identifier,
        group: _group,
      );
    } catch (_) {
      _callbacks.remove(identifier);
      rethrow;
    }
  }

  void _onActivated(windows.ActivatedEvent event) {
    _callbacks.remove(event.argument)?.call();
  }

  static String _defaultIconPath() => path.join(
    path.dirname(Platform.resolvedExecutable),
    'data',
    'flutter_assets',
    'assets',
    'tray',
    'icon.png',
  );
}

/// Desktop [NotificationService] for Linux and Windows notification backends.
///
/// Alerts are presented through the injectable [DesktopNotifier]; clicking a
/// notification brings the app window to the front (default:
/// `windowManager.show` + `focus`). When [NotifyRequest.playSound] is true
/// the selected alert sound plays via [SoundPlayer].
///
/// Desktop platforms require no runtime notification permission, so
/// [permissionGranted] is always true and [openPermissionSettings] is a
/// no-op.
class DesktopNotificationService implements NotificationService {
  DesktopNotificationService({
    DesktopNotifier? notifier,
    SoundPlayer? soundPlayer,
    Future<void> Function()? bringWindowToFront,
  }) : _notifier =
           notifier ??
           (Platform.isWindows
               ? WindowsDesktopNotifier()
               : LocalNotifierAdapter()),
       _soundPlayer = soundPlayer ?? SoundPlayer(),
       _bringWindowToFront = bringWindowToFront ?? _defaultBringWindowToFront;

  final DesktopNotifier _notifier;
  final SoundPlayer _soundPlayer;
  final Future<void> Function() _bringWindowToFront;
  Future<void>? _initialization;

  static Future<void> _defaultBringWindowToFront() async {
    await windowManager.show();
    await windowManager.focus();
  }

  @override
  Future<void> init() => _initialization ??= _notifier.init();

  @override
  Future<void> show(NotifyRequest request) async {
    await _notifier.show(
      identifier: request.eventId,
      title: request.title,
      body: request.body,
      onClick: () {
        // Bring the app window to the front first, then hand the click to
        // the router's deep-link handler so the target opens on top. A
        // failing window manager must never swallow the deep link.
        unawaited(() async {
          try {
            await _bringWindowToFront();
          } on Object {
            // Window activation is best-effort; the deep link still runs.
          }
          request.onClick?.call();
        }());
      },
    );
    if (request.playSound) {
      await _soundPlayer.play(request.alertSound);
    }
  }

  @override
  Future<bool> permissionGranted() async => true;

  @override
  Future<void> openPermissionSettings() async {}
}
