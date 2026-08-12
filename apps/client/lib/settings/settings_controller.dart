import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../devices/devices_controller.dart' show sharedPreferencesProvider;

/// Applies (or removes) the OS login-item / autostart entry.
///
/// Abstracted so tests can mock it: the real implementation touches the
/// `launch_at_startup` platform channel, which is unavailable in unit tests.
abstract class StartupToggle {
  /// Enables or disables launching the app at OS startup.
  Future<void> setEnabled(bool enabled);
}

/// [StartupToggle] backed by the `launch_at_startup` plugin.
///
/// `setup` is performed lazily on first use so importing this class (and
/// constructing the provider graph) never touches platform channels.
class LaunchAtStartupToggle implements StartupToggle {
  bool _setupDone = false;

  void _ensureSetup() {
    if (_setupDone) {
      return;
    }
    launchAtStartup.setup(
      appName: 'opencode-notify',
      appPath: Platform.resolvedExecutable,
    );
    _setupDone = true;
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    _ensureSetup();
    if (enabled) {
      await launchAtStartup.enable();
    } else {
      await launchAtStartup.disable();
    }
  }
}

/// How the OS autostart entry is applied. Overridden in tests with a mock.
final startupToggleProvider = Provider<StartupToggle>(
  (ref) => LaunchAtStartupToggle(),
);

/// The user-facing settings surface.
final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(SettingsController.new);

/// Persisted user settings for alerts and desktop integration.
///
/// [soundEnabled] controls whether shown alerts play the bundled alert
/// sound; [paused] suppresses alert popups entirely (history is still
/// recorded); [launchAtStartup] mirrors the OS autostart entry; [textScale]
/// controls desktop text size independently from GTK accessibility scaling.
class SettingsState {
  const SettingsState({
    this.soundEnabled = true,
    this.paused = false,
    this.launchAtStartup = false,
    this.textScale = 1,
  });

  final bool soundEnabled;
  final bool paused;
  final bool launchAtStartup;
  final double textScale;

  SettingsState copyWith({
    bool? soundEnabled,
    bool? paused,
    bool? launchAtStartup,
    double? textScale,
  }) => SettingsState(
    soundEnabled: soundEnabled ?? this.soundEnabled,
    paused: paused ?? this.paused,
    launchAtStartup: launchAtStartup ?? this.launchAtStartup,
    textScale: textScale ?? this.textScale,
  );

  @override
  bool operator ==(Object other) =>
      other is SettingsState &&
      other.soundEnabled == soundEnabled &&
      other.paused == paused &&
      other.launchAtStartup == launchAtStartup &&
      other.textScale == textScale;

  @override
  int get hashCode =>
      Object.hash(soundEnabled, paused, launchAtStartup, textScale);

  @override
  String toString() =>
      'SettingsState(soundEnabled: $soundEnabled, paused: $paused, '
      'launchAtStartup: $launchAtStartup, textScale: $textScale)';
}

/// Riverpod controller for [SettingsState], persisted to
/// `shared_preferences`.
///
/// Preferences load asynchronously (the shared `sharedPreferencesProvider`
/// yields a `Future<SharedPreferences>`), so [build] returns defaults and
/// hydrates state once the handle resolves; every setter awaits the same
/// handle before writing.
class SettingsController extends Notifier<SettingsState> {
  /// Shared-preferences key for [SettingsState.soundEnabled].
  static const String soundEnabledKey = 'settings_sound_enabled_v1';

  /// Shared-preferences key for [SettingsState.paused].
  static const String pausedKey = 'settings_paused_v1';

  /// Shared-preferences key for [SettingsState.launchAtStartup].
  static const String launchAtStartupKey = 'settings_launch_at_startup_v1';

  /// Shared-preferences key for [SettingsState.textScale].
  static const String textScaleKey = 'settings_text_scale_v1';

  static const double minTextScale = 0.75;
  static const double maxTextScale = 1.5;
  static const double textScaleStep = 0.1;

  bool _disposed = false;

  /// Completes once the persisted values have been applied to [state] (or
  /// hydration failed and defaults were kept). Setters await it so a toggle
  /// made while hydration is still pending is applied *after* the stored
  /// values and is never overwritten by them. Completes normally even on
  /// hydration failure so setters never hang.
  final Completer<void> _hydrated = Completer<void>();

  Future<SharedPreferences> get _prefs => ref.read(sharedPreferencesProvider);

  @override
  SettingsState build() {
    ref.onDispose(() => _disposed = true);
    unawaited(_hydrate());
    return const SettingsState();
  }

  Future<void> _hydrate() async {
    try {
      final SharedPreferences prefs;
      try {
        prefs = await _prefs;
      } catch (_) {
        // Preferences unavailable (e.g. no plugin binding in this
        // environment): keep the defaults.
        return;
      }
      if (_disposed) {
        return;
      }
      state = SettingsState(
        soundEnabled: prefs.getBool(soundEnabledKey) ?? true,
        paused: prefs.getBool(pausedKey) ?? false,
        launchAtStartup: prefs.getBool(launchAtStartupKey) ?? false,
        textScale: normalizeTextScale(prefs.getDouble(textScaleKey) ?? 1),
      );
    } finally {
      if (!_hydrated.isCompleted) {
        _hydrated.complete();
      }
    }
  }

  /// Enables or disables the alert sound and persists the choice.
  Future<void> setSoundEnabled(bool soundEnabled) async {
    await _hydrated.future;
    state = state.copyWith(soundEnabled: soundEnabled);
    await (await _prefs).setBool(soundEnabledKey, soundEnabled);
  }

  /// Pauses or resumes alert popups and persists the choice.
  Future<void> setPaused(bool paused) async {
    await _hydrated.future;
    state = state.copyWith(paused: paused);
    await (await _prefs).setBool(pausedKey, paused);
  }

  /// Sets the desktop application's text scale and persists the choice.
  Future<void> setTextScale(double textScale) async {
    await _hydrated.future;
    await _persistTextScale(textScale);
  }

  Future<void> _persistTextScale(double textScale) async {
    final normalized = normalizeTextScale(textScale);
    state = state.copyWith(textScale: normalized);
    await (await _prefs).setDouble(textScaleKey, normalized);
  }

  Future<void> increaseTextScale() async {
    await _hydrated.future;
    await _persistTextScale(state.textScale + textScaleStep);
  }

  Future<void> decreaseTextScale() async {
    await _hydrated.future;
    await _persistTextScale(state.textScale - textScaleStep);
  }

  Future<void> resetTextScale() => setTextScale(1);

  static double normalizeTextScale(double value) {
    final clamped = value.clamp(minTextScale, maxTextScale);
    return (clamped * 100).round() / 100;
  }

  /// Enables or disables OS autostart and persists the choice.
  ///
  /// The OS entry is applied through the injected [StartupToggle]. When
  /// applying it fails, both [state] and the persisted value are reverted so
  /// they stay consistent with the OS, and the error is rethrown.
  Future<void> setLaunchAtStartup(bool launchAtStartupEnabled) async {
    await _hydrated.future;
    final previous = state.launchAtStartup;
    state = state.copyWith(launchAtStartup: launchAtStartupEnabled);
    final prefs = await _prefs;
    await prefs.setBool(launchAtStartupKey, launchAtStartupEnabled);
    try {
      await ref.read(startupToggleProvider).setEnabled(launchAtStartupEnabled);
    } catch (_) {
      state = state.copyWith(launchAtStartup: previous);
      await prefs.setBool(launchAtStartupKey, previous);
      rethrow;
    }
  }
}
