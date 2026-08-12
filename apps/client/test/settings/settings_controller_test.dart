import 'dart:async';

import 'package:client/devices/devices_controller.dart';
import 'package:client/settings/settings_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockStartupToggle extends Mock implements StartupToggle {}

Future<ProviderContainer> _createContainer({
  Map<String, Object> initialValues = const {},
  StartupToggle? startupToggle,
  bool resetStore = true,
}) async {
  // Only reset the mock store when simulating a fresh device; a "restart"
  // container reuses the store written by the previous one.
  if (resetStore) {
    SharedPreferences.setMockInitialValues(initialValues);
  }
  final prefs = await SharedPreferences.getInstance();
  final toggle = startupToggle ?? MockStartupToggle();
  if (toggle is MockStartupToggle) {
    when(() => toggle.setEnabled(any())).thenAnswer((_) async {});
  }
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(Future.value(prefs)),
      startupToggleProvider.overrideWithValue(toggle),
    ],
  );
  addTearDown(container.dispose);
  // Trigger build and let the async hydration microtask complete.
  container.read(settingsControllerProvider);
  await Future<void>.delayed(Duration.zero);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsController', () {
    test('defaults when nothing was stored', () async {
      final container = await _createContainer();

      final state = container.read(settingsControllerProvider);

      expect(state.soundEnabled, isTrue);
      expect(state.paused, isFalse);
      expect(state.launchAtStartup, isFalse);
      expect(state.textScale, 1);
    });

    test('loads persisted values', () async {
      final container = await _createContainer(
        initialValues: {
          SettingsController.soundEnabledKey: false,
          SettingsController.pausedKey: true,
          SettingsController.launchAtStartupKey: true,
          SettingsController.textScaleKey: 1.25,
        },
      );

      final state = container.read(settingsControllerProvider);

      expect(state.soundEnabled, isFalse);
      expect(state.paused, isTrue);
      expect(state.launchAtStartup, isTrue);
      expect(state.textScale, 1.25);
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

    test('setLaunchAtStartup persists the final value', () async {
      final first = await _createContainer();
      await first
          .read(settingsControllerProvider.notifier)
          .setLaunchAtStartup(true);

      final second = await _createContainer(resetStore: false);
      expect(second.read(settingsControllerProvider).launchAtStartup, isTrue);
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
      expect(a.copyWith(launchAtStartup: true).launchAtStartup, isTrue);
      expect(a.copyWith(textScale: 1.2).textScale, 1.2);
      expect(a.copyWith(paused: true), isNot(a));
    });
  });
}
