import 'dart:io';

import 'package:client/notifications/alert_sound.dart';
import 'package:client/notifications/desktop_notification_service.dart';
import 'package:client/notifications/notification_service.dart';
import 'package:client/notifications/sound_player.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:win_toast/win_toast.dart';

class MockSoundPlayer extends Mock implements SoundPlayer {}

class MockWinToast extends Mock implements WinToast {}

class ShownNotification {
  ShownNotification({
    required this.identifier,
    required this.title,
    required this.body,
    this.onClick,
  });

  final String identifier;
  final String title;
  final String body;
  final void Function()? onClick;
}

class FakeDesktopNotifier implements DesktopNotifier {
  final List<ShownNotification> shown = [];
  int initCalls = 0;
  Future<void> Function()? onInit;

  @override
  Future<void> init() async {
    initCalls++;
    await onInit?.call();
  }

  @override
  Future<void> show({
    required String identifier,
    required String title,
    required String body,
    void Function()? onClick,
  }) async {
    shown.add(
      ShownNotification(
        identifier: identifier,
        title: title,
        body: body,
        onClick: onClick,
      ),
    );
  }
}

NotifyRequest _request({
  bool playSound = true,
  AlertSound alertSound = softChimeAlertSound,
}) => NotifyRequest(
  eventId: 'evt-1',
  title: '构建完成',
  body: '会话 abc 已结束',
  playSound: playSound,
  alertSound: alertSound,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(Toast());
    registerFallbackValue(softChimeAlertSound);
  });

  group('DesktopNotificationService', () {
    late FakeDesktopNotifier notifier;
    late MockSoundPlayer soundPlayer;

    setUp(() {
      notifier = FakeDesktopNotifier();
      soundPlayer = MockSoundPlayer();
      when(() => soundPlayer.play(any())).thenAnswer((_) async {});
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
      expect(notifier.shown.single.identifier, 'evt-1');
      expect(notifier.shown.single.title, '构建完成');
      expect(notifier.shown.single.body, '会话 abc 已结束');
    });

    test('initializes the notifier once', () async {
      final notificationService = service();

      await notificationService.init();
      await notificationService.init();

      expect(notifier.initCalls, 1);
    });

    test('show plays the alert sound when playSound is true', () async {
      await service().show(_request(playSound: true));

      verify(() => soundPlayer.play(softChimeAlertSound)).called(1);
    });

    test('show plays the selected alert sound', () async {
      final selected = bundledAlertSounds[2];

      await service().show(_request(alertSound: selected));

      verify(() => soundPlayer.play(selected)).called(1);
    });

    test('show stays silent when playSound is false', () async {
      await service().show(_request(playSound: false));

      verifyNever(() => soundPlayer.play(any()));
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

    test('Windows notification clicks show and focus the window', () async {
      if (!Platform.isWindows) return;
      const channel = MethodChannel('window_manager');
      final calls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call.method);
            if (call.method == 'isMinimized') return false;
            return true;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );

      await DesktopNotificationService(
        notifier: notifier,
        soundPlayer: soundPlayer,
      ).show(_request(playSound: false));
      notifier.shown.single.onClick!();
      await pumpEventQueue();

      expect(calls, ['isMinimized', 'show', 'focus']);
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

  group('WindowsDesktopNotifier', () {
    late MockWinToast toast;
    late ToastActivatedCallback activated;

    setUp(() {
      toast = MockWinToast();
      when(() => toast.setActivatedCallback(any())).thenAnswer((invocation) {
        activated =
            invocation.positionalArguments.single as ToastActivatedCallback;
      });
      when(
        () => toast.initialize(
          aumId: any(named: 'aumId'),
          displayName: any(named: 'displayName'),
          iconPath: any(named: 'iconPath'),
          clsid: any(named: 'clsid'),
        ),
      ).thenAnswer((_) async => true);
      when(
        () => toast.showToast(
          toast: any(named: 'toast'),
          tag: any(named: 'tag'),
          group: any(named: 'group'),
        ),
      ).thenAnswer((_) async {});
    });

    test('initializes the portable COM activator identity', () async {
      final notifier = WindowsDesktopNotifier(
        toast: toast,
        iconPath: r'C:\portable\data\flutter_assets\assets\tray\icon.png',
      );

      await notifier.init();

      verify(
        () => toast.initialize(
          aumId: 'dev.opencodenotify.client',
          displayName: 'OpenCode Notify',
          iconPath: r'C:\portable\data\flutter_assets\assets\tray\icon.png',
          clsid: any(named: 'clsid'),
        ),
      ).called(1);
    });

    test('resolves the toast icon from the portable bundle', () async {
      final notifier = WindowsDesktopNotifier(toast: toast);

      await notifier.init();

      verify(
        () => toast.initialize(
          aumId: 'dev.opencodenotify.client',
          displayName: 'OpenCode Notify',
          iconPath: path.join(
            path.dirname(Platform.resolvedExecutable),
            'data',
            'flutter_assets',
            'assets',
            'tray',
            'icon.png',
          ),
          clsid: any(named: 'clsid'),
        ),
      ).called(1);
    });

    test('falls back when COM activation is unavailable', () async {
      when(
        () => toast.initialize(
          aumId: any(named: 'aumId'),
          displayName: any(named: 'displayName'),
          iconPath: any(named: 'iconPath'),
          clsid: any(named: 'clsid'),
        ),
      ).thenAnswer((_) async => false);
      final fallback = FakeDesktopNotifier();
      final notifier = WindowsDesktopNotifier(toast: toast, fallback: fallback);

      await notifier.init();
      await notifier.show(
        identifier: 'evt-fallback',
        title: 'Fallback',
        body: 'Still visible',
      );

      expect(fallback.initCalls, 1);
      expect(fallback.shown.single.identifier, 'evt-fallback');
      verifyNever(
        () => toast.showToast(
          toast: any(named: 'toast'),
          tag: any(named: 'tag'),
          group: any(named: 'group'),
        ),
      );
    });

    test(
      'uses the event id as the activation argument and dispatches once',
      () async {
        var clicks = 0;
        final notifier = WindowsDesktopNotifier(toast: toast);
        await notifier.init();

        await notifier.show(
          identifier: 'evt-click',
          title: 'A < B',
          body: 'Ready & waiting',
          onClick: () => clicks++,
        );

        final shown =
            verify(
                  () => toast.showToast(
                    toast: captureAny(named: 'toast'),
                    tag: 'evt-click',
                    group: 'opencode-notify',
                  ),
                ).captured.single
                as Toast;
        expect(shown.toXmlString(), contains('launch="evt-click"'));
        expect(shown.toXmlString(), contains('A &lt; B'));
        expect(shown.toXmlString(), contains('Ready &amp; waiting'));
        expect(shown.toXmlString(), contains('<audio silent="true"/>'));

        activated(ActivatedEvent(argument: 'evt-click', userInput: const {}));
        activated(ActivatedEvent(argument: 'evt-click', userInput: const {}));
        expect(clicks, 1);
      },
    );

    test('falls back when showing the primary toast fails', () async {
      var clicks = 0;
      final fallback = FakeDesktopNotifier();
      final notifier = WindowsDesktopNotifier(toast: toast, fallback: fallback);
      await notifier.init();
      when(
        () => toast.showToast(
          toast: any(named: 'toast'),
          tag: any(named: 'tag'),
          group: any(named: 'group'),
        ),
      ).thenAnswer((_) async => throw StateError('show failed'));

      await notifier.show(
        identifier: 'evt-failed',
        title: 'Fallback',
        body: 'Still shown',
        onClick: () => clicks++,
      );

      expect(fallback.initCalls, 1);
      expect(fallback.shown.single.identifier, 'evt-failed');
      fallback.shown.single.onClick!();
      activated(ActivatedEvent(argument: 'evt-failed', userInput: const {}));
      expect(clicks, 1);

      await notifier.show(
        identifier: 'evt-next',
        title: 'Fallback again',
        body: 'Still shown',
      );
      expect(fallback.initCalls, 1);
      expect(fallback.shown, hasLength(2));
    });

    test('retries fallback initialization after a transient failure', () async {
      final fallback = FakeDesktopNotifier();
      var attempts = 0;
      fallback.onInit = () async {
        attempts++;
        if (attempts == 1) throw StateError('fallback unavailable');
      };
      final notifier = WindowsDesktopNotifier(toast: toast, fallback: fallback);
      await notifier.init();
      when(
        () => toast.showToast(
          toast: any(named: 'toast'),
          tag: any(named: 'tag'),
          group: any(named: 'group'),
        ),
      ).thenAnswer((_) async => throw StateError('show failed'));

      await expectLater(
        notifier.show(
          identifier: 'evt-retry-1',
          title: 'Retry',
          body: 'First attempt',
        ),
        throwsStateError,
      );
      await notifier.show(
        identifier: 'evt-retry-2',
        title: 'Retry',
        body: 'Second attempt',
      );

      expect(fallback.initCalls, 2);
      expect(fallback.shown.single.identifier, 'evt-retry-2');
    });
  });
}
