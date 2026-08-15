import 'package:client/notifications/desktop_notification_service.dart';
import 'package:client/notifications/notification_service.dart';
import 'package:client/notifications/sound_player.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSoundPlayer extends Mock implements SoundPlayer {}

class ShownNotification {
  ShownNotification({required this.title, required this.body, this.onClick});

  final String title;
  final String body;
  final void Function()? onClick;
}

class FakeDesktopNotifier implements DesktopNotifier {
  final List<ShownNotification> shown = [];

  @override
  Future<void> show({
    required String title,
    required String body,
    void Function()? onClick,
  }) async {
    shown.add(ShownNotification(title: title, body: body, onClick: onClick));
  }
}

NotifyRequest _request({bool playSound = true}) => NotifyRequest(
  eventId: 'evt-1',
  title: '构建完成',
  body: '会话 abc 已结束',
  playSound: playSound,
);

void main() {
  group('DesktopNotificationService', () {
    late FakeDesktopNotifier notifier;
    late MockSoundPlayer soundPlayer;

    setUp(() {
      notifier = FakeDesktopNotifier();
      soundPlayer = MockSoundPlayer();
      when(() => soundPlayer.playAlert()).thenAnswer((_) async {});
    });

    DesktopNotificationService service({
      Future<void> Function()? bringWindowToFront,
    }) => DesktopNotificationService(
      notifier: notifier,
      soundPlayer: soundPlayer,
      bringWindowToFront: bringWindowToFront ?? () async {},
    );

    test('show presents the notification title and body', () async {
      await service().show(_request());

      expect(notifier.shown, hasLength(1));
      expect(notifier.shown.single.title, '构建完成');
      expect(notifier.shown.single.body, '会话 abc 已结束');
    });

    test('show plays the alert sound when playSound is true', () async {
      await service().show(_request(playSound: true));

      verify(() => soundPlayer.playAlert()).called(1);
    });

    test('show stays silent when playSound is false', () async {
      await service().show(_request(playSound: false));

      verifyNever(() => soundPlayer.playAlert());
      expect(notifier.shown, hasLength(1));
    });

    test('clicking the notification brings the window to the front', () async {
      var broughtToFront = 0;
      await service(
        bringWindowToFront: () async => broughtToFront++,
      ).show(_request());

      expect(notifier.shown.single.onClick, isNotNull);
      notifier.shown.single.onClick!();
      await Future<void>.delayed(Duration.zero);

      expect(broughtToFront, 1);
    });

    test('clicking composes bring-to-front then the request onClick', () async {
      final order = <String>[];
      var requestClicks = 0;
      await service(bringWindowToFront: () async => order.add('front')).show(
        NotifyRequest(
          eventId: 'evt-click',
          title: '需要回答',
          body: 'Which database?',
          playSound: false,
          onClick: () {
            order.add('click');
            requestClicks++;
          },
        ),
      );

      notifier.shown.single.onClick!();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(order, ['front', 'click']);
      expect(requestClicks, 1);
    });

    test(
      'a failing window manager never swallows the deep-link click',
      () async {
        var clicks = 0;
        await service(
          bringWindowToFront: () async => throw StateError('wm gone'),
        ).show(
          NotifyRequest(
            eventId: 'evt-click',
            title: '需要回答',
            body: 'Which database?',
            playSound: false,
            onClick: () => clicks++,
          ),
        );

        notifier.shown.single.onClick!();
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        expect(clicks, 1);
      },
    );

    test('desktop requires no runtime notification permission', () async {
      expect(await service().permissionGranted(), isTrue);
    });
  });
}
