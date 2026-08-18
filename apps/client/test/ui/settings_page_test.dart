import 'package:client/auth/auth_controller.dart';
import 'package:client/auth/auth_state.dart';
import 'package:client/config/server_config.dart';
import 'package:client/devices/devices_controller.dart';
import 'package:client/notifications/alert_sound.dart';
import 'package:client/notifications/custom_sound_store.dart';
import 'package:client/notifications/sound_player.dart';
import 'package:client/settings/settings_controller.dart';
import 'package:client/ui/settings_page.dart';
import 'package:client/ui/server_settings_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_auth_controller.dart';

class MockStartupToggle extends Mock implements StartupToggle {}

class MockCustomSoundStore extends Mock implements CustomSoundStore {}

class MockSoundPlayer extends Mock implements SoundPlayer {}

Future<ProviderContainer> _pumpSettingsPage(
  WidgetTester tester, {
  Map<String, Object> initialValues = const {},
  StartupToggle? startupToggle,
  CustomSoundStore? customSoundStore,
  SoundPlayer? soundPlayer,
  bool? autostartSupported,
  FakeAuthController? authController,
  ServerConfigStore? serverConfigStore,
}) async {
  SharedPreferences.setMockInitialValues(initialValues);
  final prefs = await SharedPreferences.getInstance();
  final toggle = startupToggle ?? MockStartupToggle();
  if (toggle is MockStartupToggle) {
    when(
      () => toggle.isEnabled(),
    ).thenThrow(StateError('OS integration unavailable in widget tests'));
    when(() => toggle.setEnabled(any())).thenAnswer((_) async {});
  }
  final soundStore = customSoundStore ?? MockCustomSoundStore();
  if (customSoundStore == null && soundStore is MockCustomSoundStore) {
    when(() => soundStore.importSound()).thenAnswer((_) async => null);
  }
  final previewPlayer = soundPlayer ?? MockSoundPlayer();
  if (soundPlayer == null && previewPlayer is MockSoundPlayer) {
    when(() => previewPlayer.play(any())).thenAnswer((_) async {});
  }
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(Future.value(prefs)),
      startupToggleProvider.overrideWithValue(toggle),
      customSoundStoreProvider.overrideWithValue(soundStore),
      soundPreviewPlayerProvider.overrideWithValue(previewPlayer),
      authControllerProvider.overrideWith(
        () =>
            authController ??
            FakeAuthController(
              const Authenticated(
                accessToken: 'access-token',
                email: 'user@example.com',
              ),
            ),
      ),
      if (serverConfigStore != null)
        serverConfigStoreProvider.overrideWithValue(serverConfigStore),
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
  setUpAll(() => registerFallbackValue(softChimeAlertSound));

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

  testWidgets('confirmed logout clears the current session', (tester) async {
    final auth = FakeAuthController(
      const Authenticated(
        accessToken: 'access-token',
        email: 'test@example.com',
      ),
    );
    await _pumpSettingsPage(tester, authController: auth);

    await tester.tap(find.byKey(SettingsPage.logoutKey));
    await tester.pumpAndSettle();
    expect(find.text('确认退出登录？'), findsOneWidget);

    await tester.tap(find.byKey(SettingsPage.confirmLogoutKey));
    await tester.pumpAndSettle();

    expect(auth.logoutCalls, 1);
  });

  testWidgets('switching server logs out and persists the new origin', (
    tester,
  ) async {
    final auth = FakeAuthController(
      const Authenticated(
        accessToken: 'access-token',
        email: 'test@example.com',
      ),
    );
    final store = MemoryServerConfigStore('https://old.example.com');
    await _pumpSettingsPage(
      tester,
      authController: auth,
      serverConfigStore: store,
    );

    expect(find.text('https://old.example.com'), findsOneWidget);
    await tester.tap(find.byKey(SettingsPage.serverKey));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(ServerSettingsDialog.addressFieldKey),
      'new.example.com',
    );
    await tester.tap(find.byKey(ServerSettingsDialog.saveKey));
    await tester.pumpAndSettle();

    expect(auth.logoutCalls, 1);
    expect(store.read(), 'https://new.example.com');
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

  testWidgets('selects and previews a bundled desktop sound', (tester) async {
    final preview = MockSoundPlayer();
    when(() => preview.play(any())).thenAnswer((_) async {});
    final container = await _pumpSettingsPage(tester, soundPlayer: preview);
    final selected = bundledAlertSounds[2];

    await tester.tap(find.byKey(SettingsPage.alertSoundPickerKey));
    await tester.pumpAndSettle();

    expect(find.byKey(SettingsPage.alertSoundDialogKey), findsOneWidget);
    expect(
      find.byKey(SettingsPage.soundOptionKey(selected.id)),
      findsOneWidget,
    );
    await tester.ensureVisible(
      find.byKey(SettingsPage.soundPreviewKey(selected.id)),
    );
    await tester.tap(find.byKey(SettingsPage.soundPreviewKey(selected.id)));
    await tester.pumpAndSettle();
    verify(() => preview.play(selected)).called(1);

    await tester.tap(find.byKey(SettingsPage.soundOptionKey(selected.id)));
    await tester.pumpAndSettle();
    expect(container.read(settingsControllerProvider).alertSound, selected);
  });

  testWidgets('sound picker keeps its actions visible in a short window', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await _pumpSettingsPage(tester);

    await tester.tap(find.byKey(SettingsPage.alertSoundPickerKey));
    await tester.pumpAndSettle();

    expect(find.text('完成'), findsOneWidget);
    expect(
      tester.getRect(find.byKey(SettingsPage.importSoundKey)).bottom,
      lessThanOrEqualTo(450),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('imports and selects a custom desktop sound', (tester) async {
    final store = MockCustomSoundStore();
    const custom = CustomAlertSound(
      displayName: 'My Chime',
      localPath: '/support/custom.wav',
    );
    when(() => store.importSound()).thenAnswer((_) async => custom);
    final container = await _pumpSettingsPage(tester, customSoundStore: store);

    await tester.tap(find.byKey(SettingsPage.alertSoundPickerKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SettingsPage.importSoundKey));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(SettingsPage.soundOptionKey(customAlertSoundId)),
        matching: find.text('My Chime'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(SettingsPage.soundOptionKey(customAlertSoundId)),
      findsOneWidget,
    );
    expect(container.read(settingsControllerProvider).alertSound, custom);
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
    expect(find.byKey(SettingsPage.alertSoundPickerKey), findsNothing);
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
