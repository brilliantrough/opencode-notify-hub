import 'package:client/notifications/android_notification_service.dart';
import 'package:client/notifications/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeLocalNotificationsClient implements LocalNotificationsClient {
  final List<AndroidNotificationChannel> createdChannels = [];
  final List<({int id, String? title, String? body, String? channelId})> shown =
      [];
  var initializeCalls = 0;
  var notificationsEnabled = true;
  var permissionRequests = 0;

  @override
  Future<void> initialize(InitializationSettings settings) async {
    initializeCalls++;
  }

  @override
  Future<void> createChannel(AndroidNotificationChannel channel) async {
    createdChannels.add(channel);
  }

  @override
  Future<void> show({
    required int id,
    String? title,
    String? body,
    NotificationDetails? details,
  }) async {
    shown.add((
      id: id,
      title: title,
      body: body,
      channelId: details?.android?.channelId,
    ));
  }

  @override
  Future<bool> areNotificationsEnabled() async => notificationsEnabled;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return true;
  }
}

NotifyRequest request({required bool playSound}) => NotifyRequest(
  eventId: 'evt-1',
  title: 'devbox · api · terminal',
  body: 'completed in 42s',
  playSound: playSound,
);

void main() {
  late FakeLocalNotificationsClient client;
  late AndroidNotificationService service;

  setUp(() {
    client = FakeLocalNotificationsClient();
    service = AndroidNotificationService(client: client);
  });

  group('AndroidNotificationService.init', () {
    test('initializes the plugin and creates both channels', () async {
      await service.init();

      expect(client.initializeCalls, 1);
      expect(
        client.createdChannels.map((c) => c.id),
        containsAll(['opencode_alerts', 'opencode_silent']),
      );
      final alerts = client.createdChannels
          .firstWhere((c) => c.id == 'opencode_alerts');
      final silent = client.createdChannels
          .firstWhere((c) => c.id == 'opencode_silent');
      expect(alerts.playSound, isTrue);
      expect(silent.playSound, isFalse);
    });
  });

  group('AndroidNotificationService.show', () {
    test('routes sound alerts to the opencode_alerts channel', () async {
      await service.show(request(playSound: true));

      expect(client.shown, hasLength(1));
      final shown = client.shown.single;
      expect(shown.title, 'devbox · api · terminal');
      expect(shown.body, 'completed in 42s');
      expect(shown.channelId, 'opencode_alerts');
    });

    test('routes silent alerts to the opencode_silent channel', () async {
      await service.show(request(playSound: false));

      expect(client.shown.single.channelId, 'opencode_silent');
    });
  });

  group('AndroidNotificationService permission', () {
    test('permissionGranted reflects areNotificationsEnabled', () async {
      expect(await service.permissionGranted(), isTrue);

      client.notificationsEnabled = false;
      expect(await service.permissionGranted(), isFalse);
    });

    test('openPermissionSettings re-requests the runtime permission',
        () async {
      await service.openPermissionSettings();

      expect(client.permissionRequests, 1);
    });
  });
}
