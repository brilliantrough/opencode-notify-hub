import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_service.dart';

/// Abstraction over `FlutterLocalNotificationsPlugin` so
/// [AndroidNotificationService] stays unit-testable without the platform
/// channel.
abstract class LocalNotificationsClient {
  /// Initializes the plugin with [settings].
  Future<void> initialize(InitializationSettings settings);

  /// Creates (or updates) a notification channel. Idempotent per channel ID.
  Future<void> createChannel(AndroidNotificationChannel channel);

  /// Presents a notification.
  Future<void> show({
    required int id,
    String? title,
    String? body,
    NotificationDetails? details,
  });

  /// Whether notifications are currently enabled for the app.
  Future<bool> areNotificationsEnabled();

  /// Requests the runtime notification permission (Android 13+).
  Future<bool> requestPermission();
}

/// [LocalNotificationsClient] backed by `flutter_local_notifications`.
class FlutterLocalNotificationsClient implements LocalNotificationsClient {
  FlutterLocalNotificationsClient(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<void> initialize(InitializationSettings settings) =>
      _plugin.initialize(settings: settings);

  @override
  Future<void> createChannel(AndroidNotificationChannel channel) =>
      _android!.createNotificationChannel(channel);

  @override
  Future<void> show({
    required int id,
    String? title,
    String? body,
    NotificationDetails? details,
  }) => _plugin.show(id: id, title: title, body: body, notificationDetails: details);

  @override
  Future<bool> areNotificationsEnabled() async =>
      await _android!.areNotificationsEnabled() ?? false;

  @override
  Future<bool> requestPermission() async =>
      await _android!.requestNotificationsPermission() ?? false;
}

/// The Android notification channels used by this app.
///
/// Channel importance/sound flags are locked at first creation by the OS, so
/// both variants exist up front and [NotifyRequest.playSound] only selects
/// between them at show time.
abstract final class AndroidNotificationChannels {
  /// Heads-up channel with sound — the FCM default channel (see the
  /// `com.google.firebase.messaging.default_notification_channel_id`
  /// meta-data in AndroidManifest.xml).
  static const alerts = AndroidNotificationChannel(
    'opencode_alerts',
    'Alerts',
    description: 'Action-required and terminal run alerts.',
    importance: Importance.high,
    playSound: true,
  );

  /// Same alerts without sound, for devices with sounds disabled.
  static const silent = AndroidNotificationChannel(
    'opencode_silent',
    'Silent alerts',
    description: 'Action-required and terminal run alerts, without sound.',
    importance: Importance.high,
    playSound: false,
  );
}

/// Android [NotificationService] backed by `flutter_local_notifications`.
///
/// [show] routes the alert to [AndroidNotificationChannels.alerts] when
/// [NotifyRequest.playSound] is true and to
/// [AndroidNotificationChannels.silent] otherwise. The notification ID
/// derives from the event ID, so a re-shown event replaces its popup.
class AndroidNotificationService implements NotificationService {
  AndroidNotificationService({LocalNotificationsClient? client})
    : _client = client ?? FlutterLocalNotificationsClient(FlutterLocalNotificationsPlugin());

  final LocalNotificationsClient _client;

  @override
  Future<void> init() async {
    await _client.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    await _client.createChannel(AndroidNotificationChannels.alerts);
    await _client.createChannel(AndroidNotificationChannels.silent);
  }

  @override
  Future<void> show(NotifyRequest request) async {
    final channel = request.playSound
        ? AndroidNotificationChannels.alerts
        : AndroidNotificationChannels.silent;
    await _client.show(
      id: request.eventId.hashCode,
      title: request.title,
      body: request.body,
      details: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.high,
          priority: Priority.high,
          playSound: request.playSound,
        ),
      ),
    );
  }

  @override
  Future<bool> permissionGranted() => _client.areNotificationsEnabled();

  /// Re-requests the runtime permission — the closest available action
  /// without a dedicated settings-launch plugin. On Android 13+ this shows
  /// the system prompt; when the user permanently denied it, this is a no-op.
  @override
  Future<void> openPermissionSettings() => _client.requestPermission();
}
