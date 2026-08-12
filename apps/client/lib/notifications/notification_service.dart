import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Platform notification service. Must be overridden per platform
/// (Android local notifications + FCM, desktop notifier, ...); the default
/// throws so an unbound platform surfaces loudly instead of silently
/// dropping alerts.
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => throw UnimplementedError(
    'notificationServiceProvider must be overridden per platform',
  ),
);

/// One alert to present to the user.
///
/// [playSound] is `false` when the device settings disabled notification
/// sounds; the platform service maps it to its silent channel.
class NotifyRequest {
  const NotifyRequest({
    required this.eventId,
    required this.title,
    required this.body,
    required this.playSound,
  });

  final String eventId;
  final String title;
  final String body;
  final bool playSound;

  @override
  bool operator ==(Object other) =>
      other is NotifyRequest &&
      other.eventId == eventId &&
      other.title == title &&
      other.body == body &&
      other.playSound == playSound;

  @override
  int get hashCode => Object.hash(eventId, title, body, playSound);

  @override
  String toString() =>
      'NotifyRequest($eventId, $title, playSound: $playSound)';
}

/// Abstraction over the platform's notification surface, so the
/// `NotificationRouter` stays free of platform checks.
abstract class NotificationService {
  /// Initializes channels/plugins. Idempotent.
  Future<void> init();

  /// Presents [request] to the user.
  Future<void> show(NotifyRequest request);

  /// Whether the app currently holds the platform notification permission.
  Future<bool> permissionGranted();

  /// Opens the platform settings screen where the user can grant the
  /// notification permission.
  Future<void> openPermissionSettings();
}
