import 'package:client/devices/devices_controller.dart';
import 'package:client/settings/settings_controller.dart';
import 'package:client/ui/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockStartupToggle extends Mock implements StartupToggle {}

Future<ProviderContainer> _pumpSettingsPage(
  WidgetTester tester, {
  Map<String, Object> initialValues = const {},
  StartupToggle? startupToggle,
  bool? autostartSupported,
}) async {
  SharedPreferences.setMockInitialValues(initialValues);
  final prefs = await SharedPreferences.getInstance();
  final toggle = startupToggle ?? MockStartupToggle();
  if (toggle is MockStartupToggle) {
    when(() => toggle.setEnabled(any())).thenAnswer((_) async {});
  }
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(Future.value(prefs)),
      startupToggleProvider.overrideWithValue(toggle),
      if (autostartSupported != null)
        desktopSettingsSupportedProvider.overrideWithValue(autostartSupported),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: SettingsPage()),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Finder _switchOf(Key key) =>
    find.descendant(of: find.byKey(key), matching: find.byType(Switch));

void main() {
  testWidgets('shows sound / pause / autostart switches with defaults', (
    tester,
  ) async {
    await _pumpSettingsPage(tester);

    expect(find.text('提示声音'), findsOneWidget);
    expect(find.text('暂停通知'), findsOneWidget);
    expect(find.text('开机自启'), findsOneWidget);
    expect(find.text('字体缩放'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);

    final Switch sound = tester.widget(_switchOf(SettingsPage.soundSwitchKey));
    final Switch pause = tester.widget(_switchOf(SettingsPage.pauseSwitchKey));
    final Switch autostart = tester.widget(
      _switchOf(SettingsPage.autostartSwitchKey),
    );
    expect(sound.value, isTrue);
    expect(pause.value, isFalse);
    expect(autostart.value, isFalse);
  });

  testWidgets('switch values reflect persisted settings', (tester) async {
    await _pumpSettingsPage(
      tester,
      initialValues: {
        SettingsController.soundEnabledKey: false,
        SettingsController.pausedKey: true,
      },
    );

    final Switch sound = tester.widget(_switchOf(SettingsPage.soundSwitchKey));
    final Switch pause = tester.widget(_switchOf(SettingsPage.pauseSwitchKey));
    expect(sound.value, isFalse);
    expect(pause.value, isTrue);
  });

  testWidgets('tapping 暂停通知 updates state and persists', (tester) async {
    final container = await _pumpSettingsPage(tester);

    await tester.tap(find.byKey(SettingsPage.pauseSwitchKey));
    await tester.pumpAndSettle();

    expect(container.read(settingsControllerProvider).paused, isTrue);
    final Switch pause = tester.widget(_switchOf(SettingsPage.pauseSwitchKey));
    expect(pause.value, isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(SettingsController.pausedKey), isTrue);
  });

  testWidgets('tapping 提示声音 disables sound and persists', (tester) async {
    final container = await _pumpSettingsPage(tester);

    await tester.tap(find.byKey(SettingsPage.soundSwitchKey));
    await tester.pumpAndSettle();

    expect(container.read(settingsControllerProvider).soundEnabled, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(SettingsController.soundEnabledKey), isFalse);
  });

  testWidgets('font scale controls update and reset the persisted value', (
    tester,
  ) async {
    final container = await _pumpSettingsPage(tester);

    await tester.tap(find.byKey(SettingsPage.textScaleIncreaseKey));
    await tester.pumpAndSettle();
    expect(container.read(settingsControllerProvider).textScale, 1.1);
    expect(find.text('110%'), findsOneWidget);

    await tester.tap(find.byKey(SettingsPage.textScaleResetKey));
    await tester.pumpAndSettle();
    expect(container.read(settingsControllerProvider).textScale, 1);
    expect(find.text('100%'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getDouble(SettingsController.textScaleKey), 1);
  });

  testWidgets('开机自启 is hidden off desktop', (tester) async {
    await _pumpSettingsPage(tester, autostartSupported: false);

    expect(find.text('提示声音'), findsOneWidget);
    expect(find.text('暂停通知'), findsOneWidget);
    expect(find.text('开机自启'), findsNothing);
    expect(find.byKey(SettingsPage.autostartSwitchKey), findsNothing);
    expect(find.byKey(SettingsPage.textScaleSliderKey), findsNothing);
  });

  testWidgets('开机自启 is shown on desktop', (tester) async {
    await _pumpSettingsPage(tester, autostartSupported: true);

    expect(find.byKey(SettingsPage.autostartSwitchKey), findsOneWidget);
  });

  testWidgets('tapping 开机自启 enables autostart via the startup toggle', (
    tester,
  ) async {
    final toggle = MockStartupToggle();
    when(() => toggle.setEnabled(any())).thenAnswer((_) async {});
    final container = await _pumpSettingsPage(tester, startupToggle: toggle);

    await tester.tap(find.byKey(SettingsPage.autostartSwitchKey));
    await tester.pumpAndSettle();

    expect(container.read(settingsControllerProvider).launchAtStartup, isTrue);
    verify(() => toggle.setEnabled(true)).called(1);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(SettingsController.launchAtStartupKey), isTrue);
  });
}
