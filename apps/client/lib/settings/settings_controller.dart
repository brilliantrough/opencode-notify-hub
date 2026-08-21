import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../keepalive/keep_alive.dart';

import '../devices/devices_controller.dart' show sharedPreferencesProvider;
import '../notifications/alert_sound.dart';
import '../notifications/custom_sound_store.dart';

/// Applies (or removes) the OS login-item / autostart entry.
///
/// Abstracted so tests can mock it: the real implementation touches the
/// `launch_at_startup` platform channel, which is unavailable in unit tests.
abstract class StartupToggle {
  /// Reads the current OS autostart state.
  Future<bool> isEnabled();

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
      appPath: startupPath(Platform.resolvedExecutable),
    );
    _setupDone = true;
  }

  /// Formats an executable path for the Windows Run registry value.
  static String startupPath(String executablePath, {bool? windows}) {
    if (!(windows ?? Platform.isWindows)) {
      return executablePath;
    }
    final sanitized = executablePath.replaceAll('"', '');
    return sanitized.contains(RegExp(r'\s')) ? '"$sanitized"' : sanitized;
  }

  @override
  Future<bool> isEnabled() async {
    _ensureSetup();
    return launchAtStartup.isEnabled();
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
    this.alertSoundId = 'soft_chime',
    this.customSound,
    this.paused = false,
    this.launchAtStartup = false,
    this.textScale = 1,
    this.keepAliveEnabled = true,
  });

  final bool soundEnabled;
  final String alertSoundId;
  final CustomAlertSound? customSound;
  final bool paused;
  final bool launchAtStartup;
  final double textScale;

  /// Android: keep the process alive with a foreground service so the
  /// realtime socket survives backgrounding. Defaults to enabled — the
  /// maintainer's devices have no reachable push service.
  final bool keepAliveEnabled;

  AlertSound get alertSound => resolveAlertSound(alertSoundId, customSound);

  SettingsState copyWith({
    bool? soundEnabled,
    String? alertSoundId,
    CustomAlertSound? customSound,
    bool? paused,
    bool? launchAtStartup,
    double? textScale,
    bool? keepAliveEnabled,
  }) => SettingsState(
    soundEnabled: soundEnabled ?? this.soundEnabled,
    alertSoundId: alertSoundId ?? this.alertSoundId,
    customSound: customSound ?? this.customSound,
    paused: paused ?? this.paused,
    launchAtStartup: launchAtStartup ?? this.launchAtStartup,
    textScale: textScale ?? this.textScale,
    keepAliveEnabled: keepAliveEnabled ?? this.keepAliveEnabled,
  );

  @override
  bool operator ==(Object other) =>
      other is SettingsState &&
      other.soundEnabled == soundEnabled &&
      other.alertSoundId == alertSoundId &&
      other.customSound == customSound &&
      other.paused == paused &&
      other.launchAtStartup == launchAtStartup &&
      other.textScale == textScale &&
      other.keepAliveEnabled == keepAliveEnabled;

  @override
  int get hashCode => Object.hash(
    soundEnabled,
    alertSoundId,
    customSound,
    paused,
    launchAtStartup,
    textScale,
    keepAliveEnabled,
  );

  @override
  String toString() =>
      'SettingsState(soundEnabled: $soundEnabled, '
      'alertSoundId: $alertSoundId, paused: $paused, '
      'launchAtStartup: $launchAtStartup, keepAliveEnabled: '
      '$keepAliveEnabled, textScale: $textScale)';
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

  static const String alertSoundIdKey = 'settings_alert_sound_id_v1';
  static const String customSoundPathKey = 'settings_custom_sound_path_v1';
  static const String customSoundNameKey = 'settings_custom_sound_name_v1';

  /// Shared-preferences key for [SettingsState.paused].
  static const String pausedKey = 'settings_paused_v1';

  /// Shared-preferences key for [SettingsState.launchAtStartup].
  static const String launchAtStartupKey = 'settings_launch_at_startup_v1';

  /// Shared-preferences key for [SettingsState.textScale].
  static const String textScaleKey = 'settings_text_scale_v1';

  /// Shared-preferences key for [SettingsState.keepAliveEnabled].
  static const String keepAliveEnabledKey = 'settings_keep_alive_enabled_v1';

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

  /// Completes when persisted and OS-backed settings have been loaded.
  Future<void> get hydrated => _hydrated.future;

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
      var launchAtStartupEnabled = prefs.getBool(launchAtStartupKey) ?? false;
      try {
        launchAtStartupEnabled = await ref
            .read(startupToggleProvider)
            .isEnabled();
        await prefs.setBool(launchAtStartupKey, launchAtStartupEnabled);
      } catch (_) {
        // Keep the persisted state if the OS integration is unavailable.
      }
      if (_disposed) {
        return;
      }
      final customPath = prefs.getString(customSoundPathKey);
      final customName = prefs.getString(customSoundNameKey);
      final customSound = customPath == null || customName == null
          ? null
          : CustomAlertSound(displayName: customName, localPath: customPath);
      var alertSoundId =
          prefs.getString(alertSoundIdKey) ?? softChimeAlertSound.id;
      if (!isBundledAlertSoundId(alertSoundId) &&
          !(alertSoundId == customAlertSoundId && customSound != null)) {
        alertSoundId = softChimeAlertSound.id;
      }
      state = SettingsState(
        soundEnabled: prefs.getBool(soundEnabledKey) ?? true,
        alertSoundId: alertSoundId,
        customSound: customSound,
        paused: prefs.getBool(pausedKey) ?? false,
        launchAtStartup: launchAtStartupEnabled,
        textScale: normalizeTextScale(prefs.getDouble(textScaleKey) ?? 1),
        keepAliveEnabled: prefs.getBool(keepAliveEnabledKey) ?? true,
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

  Future<void> setAlertSound(String alertSoundId) async {
    await _hydrated.future;
    if (!isBundledAlertSoundId(alertSoundId) &&
        !(alertSoundId == customAlertSoundId && state.customSound != null)) {
      throw ArgumentError.value(alertSoundId, 'alertSoundId');
    }
    state = state.copyWith(alertSoundId: alertSoundId);
    await (await _prefs).setString(alertSoundIdKey, alertSoundId);
  }

  /// Imports one custom sound, replaces any previously imported file, and
  /// selects it. Returns `false` when the native picker is cancelled.
  Future<bool> importCustomSound() async {
    await _hydrated.future;
    final customSound = await ref.read(customSoundStoreProvider).importSound();
    if (customSound == null) {
      return false;
    }
    state = state.copyWith(
      alertSoundId: customAlertSoundId,
      customSound: customSound,
    );
    final prefs = await _prefs;
    await Future.wait([
      prefs.setString(alertSoundIdKey, customAlertSoundId),
      prefs.setString(customSoundPathKey, customSound.localPath),
      prefs.setString(customSoundNameKey, customSound.displayName),
    ]);
    return true;
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

  /// Enables or disables the Android keep-alive foreground service and
  /// persists the choice.
  ///
  /// The OS service is applied through [keepAliveProvider]. When the platform
  /// rejects the transition, both [state] and the persisted value revert so
  /// they stay consistent with what is actually running.
  Future<void> setKeepAliveEnabled(bool enabled) async {
    await _hydrated.future;
    final previous = state.keepAliveEnabled;
    state = state.copyWith(keepAliveEnabled: enabled);
    final prefs = await _prefs;
    await prefs.setBool(keepAliveEnabledKey, enabled);
    final applied = enabled
        ? await ref.read(keepAliveProvider).start()
        : await ref.read(keepAliveProvider).stop();
    if (!applied) {
      state = state.copyWith(keepAliveEnabled: previous);
      await prefs.setBool(keepAliveEnabledKey, previous);
    }
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
