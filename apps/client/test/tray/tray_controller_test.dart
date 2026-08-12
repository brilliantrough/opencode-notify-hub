import 'package:client/tray/tray_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tray_manager/tray_manager.dart';

Menu _menu({
  bool paused = false,
  void Function()? onShowWindow,
  void Function(bool)? onSetPaused,
  void Function()? onQuit,
}) => buildTrayMenu(
  paused: paused,
  onShowWindow: onShowWindow ?? () {},
  onSetPaused: onSetPaused ?? (_) {},
  onQuit: onQuit ?? () {},
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('buildTrayMenu', () {
    test('contains 打开窗口 / 暂停通知 / separator / 退出', () {
      final menu = _menu();

      final items = menu.items!;
      expect(items, hasLength(4));
      expect(items[0].label, '打开窗口');
      expect(items[1].label, '暂停通知');
      expect(items[2].type, 'separator');
      expect(items[3].label, '退出');
      expect(items.map((i) => i.key), [
        TrayMenuKeys.showWindow,
        TrayMenuKeys.pauseNotifications,
        null,
        TrayMenuKeys.quit,
      ]);
    });

    test('pause checkbox reflects the paused state', () {
      expect(
        _menu(
          paused: false,
        ).getMenuItem(TrayMenuKeys.pauseNotifications)!.checked,
        isFalse,
      );
      expect(
        _menu(
          paused: true,
        ).getMenuItem(TrayMenuKeys.pauseNotifications)!.checked,
        isTrue,
      );
    });

    test('clicking pause toggles the checkbox and reports the new value', () {
      bool? reported;
      final menu = _menu(paused: false, onSetPaused: (v) => reported = v);

      final pause = menu.getMenuItem(TrayMenuKeys.pauseNotifications)!;
      pause.onClick!(pause);

      expect(reported, isTrue);
      expect(pause.checked, isTrue);
    });

    test('clicking 打开窗口 and 退出 invoke their callbacks', () {
      var shown = 0;
      var quit = 0;
      final menu = _menu(onShowWindow: () => shown++, onQuit: () => quit++);

      menu.getMenuItem(TrayMenuKeys.showWindow)!.onClick!(
        menu.getMenuItem(TrayMenuKeys.showWindow)!,
      );
      menu.getMenuItem(TrayMenuKeys.quit)!.onClick!(
        menu.getMenuItem(TrayMenuKeys.quit)!,
      );

      expect(shown, 1);
      expect(quit, 1);
    });
  });

  group('TrayController', () {
    const trayChannel = MethodChannel('tray_manager');
    const windowChannel = MethodChannel('window_manager');

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(trayChannel, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(windowChannel, null);
    });

    test(
      'init is a no-op off desktop (no platform channels touched)',
      () async {
        final controller = TrayController(
          readPaused: () => false,
          writePaused: (_) async {},
          isDesktop: () => false,
        );

        // Would throw a MissingPluginException if any channel call leaked.
        await controller.init();
      },
    );

    test(
      'Linux init exports the menu without calling unsupported tooltip',
      () async {
        final calls = <String>[];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(trayChannel, (call) async {
              calls.add(call.method);
              if (call.method == 'setToolTip') {
                throw MissingPluginException();
              }
              return true;
            });
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(windowChannel, (_) async => true);
        final controller = TrayController(
          readPaused: () => false,
          writePaused: (_) async {},
          isDesktop: () => true,
          isLinux: () => true,
        );

        await controller.init();

        expect(calls, ['setIcon', 'setContextMenu']);
        controller.dispose();
      },
    );

    test('opening the tray window restores, shows, and focuses it', () async {
      final windowCalls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(trayChannel, (_) async => true);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(windowChannel, (call) async {
            windowCalls.add(call.method);
            if (call.method == 'isMinimized') {
              return false;
            }
            return true;
          });
      final controller = TrayController(
        readPaused: () => false,
        writePaused: (_) async {},
        isDesktop: () => true,
        isLinux: () => true,
      );
      await controller.init();
      windowCalls.clear();

      controller.onTrayIconMouseUp();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(windowCalls, ['restore', 'isMinimized', 'show', 'focus']);
      controller.dispose();
    });
  });
}
