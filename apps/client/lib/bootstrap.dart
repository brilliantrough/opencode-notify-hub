import 'dart:async';
import 'dart:developer' show log;
import 'dart:ui' show AppExitResponse;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:window_manager/window_manager.dart';

import 'auth/auth_controller.dart';
import 'auth/auth_state.dart';
import 'devices/device_identity.dart';
import 'devices/devices_controller.dart';
import 'fcm/fcm_service.dart';
import 'firebase_options.dart';
import 'notifications/android_notification_service.dart';
import 'notifications/desktop_notification_service.dart';
import 'notifications/notification_service.dart';
import 'realtime/realtime_controller.dart';
import 'settings/settings_controller.dart';
import 'tray/tray_controller.dart';

/// Whether Firebase/FCM was initialized during bootstrap and foreground FCM
/// handling is available. `false` by default; [AppBootstrap.initialize]
/// overrides it to `true` on Android after a successful Firebase init.
final fcmAvailableProvider = Provider<bool>((ref) => false);

/// The desktop system-tray controller, fed by the settings controller (the
/// single source of truth for the paused flag). Disposed with the container.
/// Only read on desktop platforms; constructing it elsewhere is harmless
/// because [TrayController.init] is a no-op off desktop.
final trayControllerProvider = Provider<TrayController>((ref) {
  final controller = TrayController(
    readPaused: () => ref.read(settingsControllerProvider).paused,
    writePaused: (paused) =>
        ref.read(settingsControllerProvider.notifier).setPaused(paused),
  );
  ref.onDispose(controller.dispose);
  return controller;
});

/// Platform startup wiring, prepared before `runApp` and attached to the
/// app's [ProviderContainer].
///
/// [initialize] performs the async, platform-specific setup:
/// - desktop (Windows/Linux): `windowManager` plus the
///   [DesktopNotificationService] (tray init happens in [attach], once the
///   container exists);
/// - Android: Firebase (skipped gracefully when `firebase_options.dart`
///   still holds placeholder values or initialization fails) plus the
///   [AndroidNotificationService].
///
/// The resulting [overrides] bind the real [notificationServiceProvider]
/// implementation, so they must be passed to the `ProviderContainer`
/// constructor — that guarantees the override is in place before
/// `realtimeControllerProvider` (which transitively watches it) is first
/// read.
class AppBootstrap {
  AppBootstrap._({
    required this.overrides,
    required ClientPlatform platform,
    required bool initDesktopWindowing,
  }) : _platform = platform,
       _initDesktopWindowing = initDesktopWindowing;

  /// Provider overrides that must seed the root `ProviderContainer`.
  final List<Override> overrides;

  final ClientPlatform _platform;
  final bool _initDesktopWindowing;

  ProviderContainer? _container;
  _AppLifecycleObserver? _lifecycleObserver;
  final List<void Function()> _subscriptionClosers = [];

  bool get _isDesktop =>
      _platform == ClientPlatform.windows || _platform == ClientPlatform.linux;

  /// Initializes platform services and returns the bootstrap bundle.
  ///
  /// [notificationService] injects a custom service (tests); when omitted
  /// the platform implementation is constructed and initialized here.
  /// [initDesktopWindowing] can be disabled by tests to skip `windowManager`
  /// and tray setup. [extraOverrides] are appended to [overrides] last, so
  /// callers can replace any default binding.
  static Future<AppBootstrap> initialize({
    ClientPlatform? platform,
    NotificationService? notificationService,
    bool initDesktopWindowing = true,
    List<Override> extraOverrides = const [],
  }) async {
    final resolvedPlatform = platform ?? currentPlatform();
    final overrides = <Override>[];

    final NotificationService service;
    switch (resolvedPlatform) {
      case ClientPlatform.windows || ClientPlatform.linux:
        if (initDesktopWindowing) {
          await windowManager.ensureInitialized();
        }
        service = notificationService ?? DesktopNotificationService();
      case ClientPlatform.android:
        final firebaseReady = await _tryInitializeFirebase();
        if (firebaseReady) {
          overrides.add(fcmAvailableProvider.overrideWithValue(true));
        }
        service = notificationService ?? AndroidNotificationService();
    }
    await service.init();
    overrides.add(notificationServiceProvider.overrideWithValue(service));
    overrides.addAll(extraOverrides);

    return AppBootstrap._(
      overrides: overrides,
      platform: resolvedPlatform,
      initDesktopWindowing: initDesktopWindowing,
    );
  }

  /// Attempts Firebase initialization for Android. Returns `false` — leaving
  /// FCM disabled — when `firebase_options.dart` still holds placeholder
  /// values (no real Firebase project configured yet) or initialization
  /// fails for any reason; the app then runs on WebSocket delivery only.
  static Future<bool> _tryInitializeFirebase() async {
    try {
      final options = DefaultFirebaseOptions.currentPlatform;
      if (options.apiKey.startsWith('PLACEHOLDER')) {
        log(
          'firebase_options.dart holds placeholder values; FCM disabled',
          name: 'AppBootstrap',
        );
        return false;
      }
      await Firebase.initializeApp(options: options);
      return true;
    } catch (error, stackTrace) {
      log(
        'Firebase initialization failed; FCM disabled',
        name: 'AppBootstrap',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Wires the running app to [container]: the app-lifecycle observer that
  /// gates the realtime connection on foreground, the auth listener that
  /// registers the current device (and initializes FCM on Android) on login,
  /// the tray icon/close-to-tray behavior on desktop, and the keep-alive
  /// subscription that drives the realtime controller.
  void attach(ProviderContainer container) {
    _container = container;

    _lifecycleObserver = _AppLifecycleObserver(
      isDesktop: _isDesktop,
      onForegroundChanged: (foreground) {
        // The container may already be disposed during shutdown.
        if (_container == null) {
          return;
        }
        container
            .read(appForegroundProvider.notifier)
            .setForeground(foreground);
      },
      onExitRequested: shutdown,
    );
    WidgetsBinding.instance.addObserver(_lifecycleObserver!);

    // Register the current device whenever a session becomes authenticated;
    // on Android with Firebase ready, initialize FCM once registration
    // completed so the token publish targets the registered device row.
    // On sign-out, tear FCM down so no further pushes are routed into the
    // logged-out session (and the gateway's token is invalidated).
    _subscriptionClosers.add(
      container
          .listen(
            authControllerProvider,
            fireImmediately: true,
            (previous, next) {
              if (next is Authenticated && previous is! Authenticated) {
                unawaited(_onLogin(container));
              }
              if (next is! Authenticated && previous is Authenticated) {
                unawaited(_onLogout(container));
              }
            },
          )
          .close,
    );

    // Keep the realtime controller alive independent of the widget tree and
    // react to auth/foreground changes even when no page watches it.
    _subscriptionClosers.add(
      container
          .listen(realtimeControllerProvider, fireImmediately: true, (_, _) {})
          .close,
    );

    if (_isDesktop && _initDesktopWindowing) {
      // Refresh the tray menu when the paused flag changes from the
      // settings page, so the checkbox always reflects current settings.
      _subscriptionClosers.add(
        container
            .listen(settingsControllerProvider, (_, _) {
              unawaited(_refreshTrayMenu(container));
            })
            .close,
      );
      unawaited(() async {
        try {
          await container.read(trayControllerProvider).init();
        } catch (error, stackTrace) {
          log(
            'tray initialization failed',
            name: 'AppBootstrap',
            error: error,
            stackTrace: stackTrace,
          );
        }
      }());
    }
  }

  Future<void> _onLogin(ProviderContainer container) async {
    try {
      await container
          .read(devicesControllerProvider.notifier)
          .registerCurrentDevice();
    } catch (error, stackTrace) {
      log(
        'device registration failed',
        name: 'AppBootstrap',
        error: error,
        stackTrace: stackTrace,
      );
      return;
    }
    // Registration awaited: the session may have been signed out (or the
    // bootstrap shut down) in flight — initializing FCM now would publish a
    // token for a dead session.
    if (_container == null ||
        container.read(authControllerProvider) is! Authenticated) {
      return;
    }
    if (!container.read(fcmAvailableProvider)) {
      return;
    }
    try {
      await container.read(fcmServiceProvider).init();
    } catch (error, stackTrace) {
      log(
        'FCM initialization failed',
        name: 'AppBootstrap',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Tears down FCM on sign-out (Android only, when Firebase initialized):
  /// cancels the message/token subscriptions and invalidates the
  /// registration token so the gateway stops pushing to this install.
  /// Failures are logged, never surfaced — sign-out has already completed.
  Future<void> _onLogout(ProviderContainer container) async {
    if (!container.read(fcmAvailableProvider)) {
      return;
    }
    try {
      await container.read(fcmServiceProvider).logout();
    } catch (error, stackTrace) {
      log(
        'FCM teardown on logout failed',
        name: 'AppBootstrap',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _refreshTrayMenu(ProviderContainer container) async {
    try {
      await container.read(trayControllerProvider).refreshMenu();
    } catch (error, stackTrace) {
      log(
        'tray menu refresh failed',
        name: 'AppBootstrap',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Detaches lifecycle wiring and disposes the container, which stops the
  /// realtime controller, disconnects the socket, and disposes the tray and
  /// FCM controllers via their `ref.onDispose` hooks. Idempotent.
  Future<void> shutdown() async {
    final observer = _lifecycleObserver;
    _lifecycleObserver = null;
    if (observer != null) {
      WidgetsBinding.instance.removeObserver(observer);
    }
    for (final close in _subscriptionClosers) {
      close();
    }
    _subscriptionClosers.clear();
    final container = _container;
    _container = null;
    container?.dispose();
  }
}

/// Maps an app lifecycle transition onto the realtime foreground flag.
///
/// Desktop keeps the socket connected in every lifecycle state while the
/// process runs. GTK reports `detached` when a window is hidden to the tray,
/// so treating it as offline would silently disable desktop notifications;
/// actual process exit is handled by [AppBootstrap.shutdown]. On Android,
/// `paused`/`hidden`/`detached` disconnect the socket and FCM takes over.
@visibleForTesting
bool realtimeForegroundFor(AppLifecycleState state, {required bool isDesktop}) =>
    isDesktop ||
    switch (state) {
      AppLifecycleState.resumed || AppLifecycleState.inactive => true,
      AppLifecycleState.paused ||
      AppLifecycleState.hidden ||
      AppLifecycleState.detached => false,
    };

/// Maps `WidgetsBinding` lifecycle transitions onto the realtime foreground
/// flag via [realtimeForegroundFor], and routes exit requests to shutdown.
class _AppLifecycleObserver extends WidgetsBindingObserver {
  _AppLifecycleObserver({
    required bool isDesktop,
    required void Function(bool foreground) onForegroundChanged,
    required Future<void> Function() onExitRequested,
  }) : _isDesktop = isDesktop,
       _onForegroundChanged = onForegroundChanged,
       _onExitRequested = onExitRequested;

  final bool _isDesktop;
  final void Function(bool foreground) _onForegroundChanged;
  final Future<void> Function() _onExitRequested;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _onForegroundChanged(realtimeForegroundFor(state, isDesktop: _isDesktop));
  }

  @override
  Future<AppExitResponse> didRequestAppExit() async {
    await _onExitRequested();
    return AppExitResponse.exit;
  }
}
