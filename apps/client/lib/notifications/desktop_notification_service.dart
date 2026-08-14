import 'package:local_notifier/local_notifier.dart';
import 'package:window_manager/window_manager.dart';

import 'notification_service.dart';
import 'sound_player.dart';

/// Abstraction over the OS notification popup so the service stays testable
/// without the `local_notifier` platform channel.
abstract class DesktopNotifier {
  /// Presents a popup notification; [onClick] fires when the user clicks it.
  Future<void> show({
    required String title,
    required String body,
    void Function()? onClick,
  });
}

/// [DesktopNotifier] backed by `local_notifier`.
class LocalNotifierAdapter implements DesktopNotifier {
  @override
  Future<void> show({
    required String title,
    required String body,
    void Function()? onClick,
  }) {
    final notification = LocalNotification(title: title, body: body);
    notification.onClick = onClick;
    return notification.show();
  }
}

/// Desktop [NotificationService] (Linux/Windows) backed by `local_notifier`.
///
/// Alerts are presented through the injectable [DesktopNotifier]; clicking a
/// notification brings the app window to the front (default:
/// `windowManager.show` + `focus`). When [NotifyRequest.playSound] is true
/// the bundled alert sound plays via [SoundPlayer].
///
/// Desktop platforms require no runtime notification permission, so
/// [permissionGranted] is always true and [openPermissionSettings] is a
/// no-op.
class DesktopNotificationService implements NotificationService {
  DesktopNotificationService({
    DesktopNotifier? notifier,
    SoundPlayer? soundPlayer,
    Future<void> Function()? bringWindowToFront,
  }) : _notifier = notifier ?? LocalNotifierAdapter(),
       _soundPlayer = soundPlayer ?? SoundPlayer(),
       _bringWindowToFront =
           bringWindowToFront ?? _defaultBringWindowToFront;

  final DesktopNotifier _notifier;
  final SoundPlayer _soundPlayer;
  final Future<void> Function() _bringWindowToFront;

  static Future<void> _defaultBringWindowToFront() async {
    await windowManager.show();
    await windowManager.focus();
  }

  @override
  Future<void> init() => localNotifier.setup(appName: 'opencode-notify');

  @override
  Future<void> show(NotifyRequest request) async {
    await _notifier.show(
      title: request.title,
      body: request.body,
      onClick: () => _bringWindowToFront(),
    );
    if (request.playSound) {
      await _soundPlayer.playAlert();
    }
  }

  @override
  Future<bool> permissionGranted() async => true;

  @override
  Future<void> openPermissionSettings() async {}
}
