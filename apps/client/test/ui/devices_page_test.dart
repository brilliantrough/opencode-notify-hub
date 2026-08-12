import 'package:client/devices/devices_controller.dart';
import 'package:client/ui/devices_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notify_api/notify_api.dart';

/// Fake controller: canned device list, records toggle calls, no gateway.
class FakeDevicesController extends DevicesController {
  FakeDevicesController(this._initial);

  final List<Device> _initial;
  final List<({String id, bool enabled})> enabledCalls = [];
  final List<({String id, bool soundEnabled})> soundCalls = [];

  @override
  Future<List<Device>> build() async => _initial;

  @override
  Future<Device> setEnabled(String id, bool enabled) async {
    enabledCalls.add((id: id, enabled: enabled));
    return _patch(id, enabled: enabled);
  }

  @override
  Future<Device> setSoundEnabled(String id, bool soundEnabled) async {
    soundCalls.add((id: id, soundEnabled: soundEnabled));
    return _patch(id, soundEnabled: soundEnabled);
  }

  Future<Device> _patch(
    String id, {
    bool? enabled,
    bool? soundEnabled,
  }) async {
    final current = state.value!;
    late Device updated;
    final next = [
      for (final device in current)
        if (device.id == id)
          updated = device.rebuild(
            (b) => b
              ..enabled = enabled ?? device.enabled
              ..soundEnabled = soundEnabled ?? device.soundEnabled,
          )
        else
          device,
    ];
    state = AsyncData(next);
    return updated;
  }
}

void main() {
  Device device({
    required String id,
    required String name,
    bool enabled = true,
    bool soundEnabled = false,
    DevicePlatformEnum platform = DevicePlatformEnum.linux,
  }) => Device(
    (b) => b
      ..id = id
      ..name = name
      ..enabled = enabled
      ..soundEnabled = soundEnabled
      ..platform = platform,
  );

  late FakeDevicesController controller;

  Future<void> pumpDevices(WidgetTester tester, List<Device> devices) async {
    controller = FakeDevicesController(devices);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          devicesControllerProvider.overrideWith(() => controller),
        ],
        child: const MaterialApp(home: DevicesPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Switch switchOf(WidgetTester tester, Key key) =>
      tester.widget<Switch>(find.byKey(key));

  testWidgets('lists devices with name and platform', (tester) async {
    await pumpDevices(tester, [
      device(id: 'd1', name: '工作站', platform: DevicePlatformEnum.linux),
      device(id: 'd2', name: '手机', platform: DevicePlatformEnum.android),
    ]);

    expect(find.text('工作站'), findsOneWidget);
    expect(find.text('手机'), findsOneWidget);
    expect(find.text('linux'), findsOneWidget);
    expect(find.text('android'), findsOneWidget);
  });

  testWidgets('empty state when no devices are registered', (tester) async {
    await pumpDevices(tester, const []);
    expect(find.text('暂无设备'), findsOneWidget);
  });

  testWidgets('enable toggle calls setEnabled and updates the switch', (
    tester,
  ) async {
    await pumpDevices(tester, [device(id: 'd1', name: '工作站')]);

    expect(
      switchOf(tester, DevicesPage.enabledSwitchKey('d1')).value,
      isTrue,
    );

    await tester.tap(find.byKey(DevicesPage.enabledSwitchKey('d1')));
    await tester.pumpAndSettle();

    expect(controller.enabledCalls, [(id: 'd1', enabled: false)]);
    expect(
      switchOf(tester, DevicesPage.enabledSwitchKey('d1')).value,
      isFalse,
    );
  });

  testWidgets('sound toggle calls setSoundEnabled and updates the switch', (
    tester,
  ) async {
    await pumpDevices(tester, [device(id: 'd1', name: '工作站')]);

    expect(
      switchOf(tester, DevicesPage.soundSwitchKey('d1')).value,
      isFalse,
    );

    await tester.tap(find.byKey(DevicesPage.soundSwitchKey('d1')));
    await tester.pumpAndSettle();

    expect(controller.soundCalls, [(id: 'd1', soundEnabled: true)]);
    expect(
      switchOf(tester, DevicesPage.soundSwitchKey('d1')).value,
      isTrue,
    );
  });
}
