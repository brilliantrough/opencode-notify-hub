import 'dart:async';

import 'package:client/devices/devices_controller.dart';
import 'package:client/keepalive/keep_alive.dart';
import 'package:client/notifications/alert_sound.dart';
import 'package:client/notifications/custom_sound_store.dart';
import 'package:client/settings/settings_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockStartupToggle extends Mock implements StartupToggle {}

class MockCustomSoundStore extends Mock implements CustomSoundStore {}

class FakeKeepAlive extends KeepAliveBridge {
  // All channel-touching methods are overridden; the real channel is never
  // reached.
  var startCalls = 0;
  var stopCalls = 0;
  var rejectNext = false;

  @override
  Future<bool> start() async {
    if (rejectNext) {
      rejectNext = false;
      return false;
    }
    startCalls++;
    return true;
  }

  @override
  Future<bool> stop() async {
    if (rejectNext) {
      rejectNext = false;
      return false;
    }
    stopCalls++;
    return true;
  }
}

Future<ProviderContainer> _createContainer({
  Map<String, Object> initialValues = const {},
  StartupToggle? startupToggle,
  CustomSoundStore? customSoundStore,
  KeepAliveBridge? keepAlive,
  bool resetStore = true,
}) async {
  // Only reset the mock store when simulating a fresh device; a "restart"
  // container reuses the store written by the previous one.
  if (resetStore) {
    SharedPreferences.setMockInitialValues(initialValues);
  }
  final prefs = await SharedPreferences.getInstance();
  final toggle = startupToggle ?? MockStartupToggle();
  if (startupToggle == null && toggle is MockStartupToggle) {
    when(
      () => toggle.isEnabled(),
    ).thenThrow(StateError('OS integration unavailable in unit tests'));
    when(() => toggle.setEnabled(any())).thenAnswer((_) async {});
  }
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(Future.value(prefs)),
      startupToggleProvider.overrideWithValue(toggle),
      if (keepAlive != null) keepAliveProvider.overrideWithValue(keepAlive),
      if (customSoundStore != null)
        customSoundStoreProvider.overrideWithValue(customSoundStore),
    ],
  );
  addTearDown(container.dispose);
  // Trigger build and let the async hydration microtask complete.
  await container.read(settingsControllerProvider.notifier).hydrated;
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsController', () {
    test('defaults when nothing was stored', () async {
      final container = await _createContainer();

      final state = container.read(settingsControllerProvider);

      expect(state.soundEnabled, isTrue);
      expect(state.alertSoundId, softChimeAlertSound.id);
      expect(state.alertSound, softChimeAlertSound);
      expect(state.customSound, isNull);
      expect(state.paused, isFalse);
      expect(state.launchAtStartup, isFalse);
      expect(state.textScale, 1);
      expect(state.keepAliveEnabled, isTrue);
    });

    test('loads persisted values', () async {
      final container = await _createContainer(
        initialValues: {
          SettingsController.soundEnabledKey: false,
          SettingsController.alertSoundIdKey: bundledAlertSounds[2].id,
          SettingsController.pausedKey: true,
          SettingsController.launchAtStartupKey: true,
          SettingsController.textScaleKey: 1.25,
          SettingsController.keepAliveEnabledKey: false,
        },
      );

      final state = container.read(settingsControllerProvider);

      expect(state.soundEnabled, isFalse);
      expect(state.alertSound, bundledAlertSounds[2]);
      expect(state.paused, isTrue);
      expect(state.launchAtStartup, isTrue);
      expect(state.textScale, 1.25);
      expect(state.keepAliveEnabled, isFalse);
    });

    test(
      'setSoundEnabled updates state and persists across a restart',
      () async {
        final first = await _createContainer();

        await first
            .read(settingsControllerProvider.notifier)
            .setSoundEnabled(false);
        expect(first.read(settingsControllerProvider).soundEnabled, isFalse);

        final second = await _createContainer(resetStore: false);
        expect(second.read(settingsControllerProvider).soundEnabled, isFalse);
      },
    );

    test('setAlertSound persists the bundled selection', () async {
      final first = await _createContainer();

      await first
          .read(settingsControllerProvider.notifier)
          .setAlertSound(bundledAlertSounds[3].id);

      expect(
        first.read(settingsControllerProvider).alertSound,
        bundledAlertSounds[3],
      );
      final second = await _createContainer(resetStore: false);
      expect(
        second.read(settingsControllerProvider).alertSound,
        bundledAlertSounds[3],
      );
    });

    test('imports, selects, and persists a custom sound', () async {
      final store = MockCustomSoundStore();
      const custom = CustomAlertSound(
        displayName: 'Quiet Ping',
        localPath: '/support/custom.wav',
      );
      when(() => store.importSound()).thenAnswer((_) async => custom);
      final first = await _createContainer(customSoundStore: store);

      final imported = await first
          .read(settingsControllerProvider.notifier)
          .importCustomSound();

      expect(imported, isTrue);
      expect(first.read(settingsControllerProvider).alertSound, custom);
      final second = await _createContainer(resetStore: false);
      expect(second.read(settingsControllerProvider).alertSound, custom);
    });

    test('cancelled custom import leaves the selection unchanged', () async {
      final store = MockCustomSoundStore();
      when(() => store.importSound()).thenAnswer((_) async => null);
      final container = await _createContainer(customSoundStore: store);

      expect(
        await container
            .read(settingsControllerProvider.notifier)
            .importCustomSound(),
        isFalse,
      );
      expect(
        container.read(settingsControllerProvider).alertSound,
        softChimeAlertSound,
      );
    });

    test('setPaused updates state and persists across a restart', () async {
      final first = await _createContainer();

      await first.read(settingsControllerProvider.notifier).setPaused(true);
      expect(first.read(settingsControllerProvider).paused, isTrue);

      final second = await _createContainer(resetStore: false);
      expect(second.read(settingsControllerProvider).paused, isTrue);
    });

    test('text scale updates, clamps, and persists across a restart', () async {
      final first = await _createContainer();
      final controller = first.read(settingsControllerProvider.notifier);

      await controller.setTextScale(1.2);
      expect(first.read(settingsControllerProvider).textScale, 1.2);

      await controller.setTextScale(9);
      expect(
        first.read(settingsControllerProvider).textScale,
        SettingsController.maxTextScale,
      );

      await controller.resetTextScale();
      await controller.decreaseTextScale();
      expect(first.read(settingsControllerProvider).textScale, 0.9);

      final second = await _createContainer(resetStore: false);
      expect(second.read(settingsControllerProvider).textScale, 0.9);
    });

    test(
      'relative text scaling waits for hydration before reading state',
      () async {
        SharedPreferences.setMockInitialValues({
          SettingsController.textScaleKey: 1.2,
        });
        final prefs = await SharedPreferences.getInstance();
        final gate = Completer<SharedPreferences>();
        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(gate.future),
            startupToggleProvider.overrideWithValue(MockStartupToggle()),
          ],
        );
        addTearDown(container.dispose);
        final notifier = container.read(settingsControllerProvider.notifier);

        final increased = notifier.increaseTextScale();
        gate.complete(prefs);
        await increased;

        expect(container.read(settingsControllerProvider).textScale, 1.3);
        expect(prefs.getDouble(SettingsController.textScaleKey), 1.3);
      },
    );

    test('setLaunchAtStartup calls the startup toggle and persists', () async {
      final toggle = MockStartupToggle();
      when(() => toggle.setEnabled(any())).thenAnswer((_) async {});
      final first = await _createContainer(startupToggle: toggle);

      await first
          .read(settingsControllerProvider.notifier)
          .setLaunchAtStartup(true);

      expect(first.read(settingsControllerProvider).launchAtStartup, isTrue);
      verify(() => toggle.setEnabled(true)).called(1);

      await first
          .read(settingsControllerProvider.notifier)
          .setLaunchAtStartup(false);

      expect(first.read(settingsControllerProvider).launchAtStartup, isFalse);
      verify(() => toggle.setEnabled(false)).called(1);
    });

    test('hydrates launch-at-startup from the current OS state', () async {
      final toggle = MockStartupToggle();
      when(() => toggle.isEnabled()).thenAnswer((_) async => true);
      when(() => toggle.setEnabled(any())).thenAnswer((_) async {});

      final container = await _createContainer(startupToggle: toggle);

      expect(
        container.read(settingsControllerProvider).launchAtStartup,
        isTrue,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(SettingsController.launchAtStartupKey), isTrue);
    });

    test('quotes Windows startup paths containing spaces', () {
      expect(
        LaunchAtStartupToggle.startupPath(
          r'C:\Program Files\OpenCode Notify\client.exe',
          windows: true,
        ),
        r'"C:\Program Files\OpenCode Notify\client.exe"',
      );
      expect(
        LaunchAtStartupToggle.startupPath(
          '/opt/opencode/client',
          windows: false,
        ),
        '/opt/opencode/client',
      );
      expect(
        LaunchAtStartupToggle.startupPath(
          r'D:\Linewrite\client.exe',
          windows: true,
        ),
        r'D:\Linewrite\client.exe',
      );
    });

    test('setLaunchAtStartup persists the final value', () async {
      final first = await _createContainer();
      await first
          .read(settingsControllerProvider.notifier)
          .setLaunchAtStartup(true);

      final second = await _createContainer(resetStore: false);
      expect(second.read(settingsControllerProvider).launchAtStartup, isTrue);
    });

    group('setKeepAliveEnabled', () {
      test('stops the service, persists, and restores it back', () async {
        final keepAlive = FakeKeepAlive();
        final first = await _createContainer(keepAlive: keepAlive);

        await first
            .read(settingsControllerProvider.notifier)
            .setKeepAliveEnabled(false);
        expect(
          first.read(settingsControllerProvider).keepAliveEnabled,
          isFalse,
        );
        expect(keepAlive.stopCalls, 1);

        await first
            .read(settingsControllerProvider.notifier)
            .setKeepAliveEnabled(true);
        expect(
          first.read(settingsControllerProvider).keepAliveEnabled,
          isTrue,
        );
        expect(keepAlive.startCalls, 1);

        final second = await _createContainer(resetStore: false);
        expect(
          second.read(settingsControllerProvider).keepAliveEnabled,
          isTrue,
        );
      });

      test('reverts state and storage when the platform rejects the change',
          () async {
        final keepAlive = FakeKeepAlive()..rejectNext = true;
        final container = await _createContainer(keepAlive: keepAlive);

        await container
            .read(settingsControllerProvider.notifier)
            .setKeepAliveEnabled(false);

        expect(
          container.read(settingsControllerProvider).keepAliveEnabled,
          isTrue,
        );
        final second = await _createContainer(resetStore: false);
        expect(
          second.read(settingsControllerProvider).keepAliveEnabled,
          isTrue,
        );
      });
    });

    test(
      'a toggle made while hydration is pending wins over the stored value',
      () async {
        SharedPreferences.setMockInitialValues({
          SettingsController.pausedKey: false,
        });
        final prefs = await SharedPreferences.getInstance();
        final gate = Completer<SharedPreferences>();
        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(gate.future),
            startupToggleProvider.overrideWithValue(MockStartupToggle()),
          ],
        );
        addTearDown(container.dispose);
        final notifier = container.read(settingsControllerProvider.notifier);

        // Hydration is still pending (gate not completed); queue the toggle.
        final toggled = notifier.setPaused(true);
        // Let the stored (stale) value land.
        gate.complete(prefs);
        await toggled;

        expect(container.read(settingsControllerProvider).paused, isTrue);
        expect(prefs.getBool(SettingsController.pausedKey), isTrue);
      },
    );

    test(
      'a failing startup toggle reverts state and persisted value',
      () async {
        final toggle = MockStartupToggle();
        final container = await _createContainer(startupToggle: toggle);
        // Re-stub after container creation so this overrides the helper's
        // default success stub (the latest mocktail stub wins).
        when(
          () => toggle.setEnabled(any()),
        ).thenThrow(StateError('OS integration unavailable'));

        await expectLater(
          container
              .read(settingsControllerProvider.notifier)
              .setLaunchAtStartup(true),
          throwsStateError,
        );

        expect(
          container.read(settingsControllerProvider).launchAtStartup,
          isFalse,
        );
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool(SettingsController.launchAtStartupKey), isFalse);
      },
    );

    test('hydration failure keeps the defaults', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(
            Future<SharedPreferences>.error(StateError('no plugin binding')),
          ),
          startupToggleProvider.overrideWithValue(MockStartupToggle()),
        ],
      );
      addTearDown(container.dispose);

      container.read(settingsControllerProvider);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(settingsControllerProvider), const SettingsState());
    });

    test('SettingsState value equality and copyWith', () {
      const a = SettingsState();
      expect(a, const SettingsState(soundEnabled: true));
      expect(a.copyWith(paused: true).paused, isTrue);
      expect(a.copyWith(paused: true).soundEnabled, isTrue);
      expect(
        a.copyWith(alertSoundId: bundledAlertSounds[1].id).alertSoundId,
        bundledAlertSounds[1].id,
      );
      expect(a.copyWith(launchAtStartup: true).launchAtStartup, isTrue);
      expect(a.copyWith(textScale: 1.2).textScale, 1.2);
      expect(a.copyWith(paused: true), isNot(a));
    });
  });
}
