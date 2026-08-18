import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../auth/auth_state.dart';
import '../config/server_config.dart';
import '../history/notification_history.dart';
import '../notifications/notification_navigation.dart';
import '../notifications/notification_router.dart';
import '../notifications/notification_service.dart';
import '../settings/settings_controller.dart';
import 'active_sessions.dart';
import 'event_deduper.dart';
import 'instance_presence.dart';
import 'notify_event.dart';
import 'ws_client.dart';

final eventDeduperProvider = Provider<EventDeduper>((ref) => EventDeduper());

/// Whether the app UI is in the foreground for realtime purposes. Driven by
/// the bootstrap's `WidgetsBinding` lifecycle observer; defaults to `true`
/// (the app starts foregrounded, and tests never background it).
final appForegroundProvider = NotifierProvider<AppForegroundController, bool>(
  AppForegroundController.new,
);

/// Holds the foreground flag consumed by [realtimeControllerProvider].
class AppForegroundController extends Notifier<bool> {
  @override
  bool build() => true;

  /// Called by the bootstrap lifecycle observer on foreground transitions.
  void setForeground(bool foreground) => state = foreground;
}

/// The production history: persisted to shared_preferences so the router's
/// cross-restart dedupe (`history.contains`) sees events recorded by earlier
/// runs. Starts empty and hydrates in the background — see
/// [PrefsNotificationHistory.hydrating]. Overridden in tests.
final notificationHistoryProvider = Provider<NotificationHistory>(
  (ref) => PrefsNotificationHistory.hydrating(),
);

final notificationRouterProvider = Provider<NotificationRouter>(
  (ref) => NotificationRouter(
    service: ref.watch(notificationServiceProvider),
    activeSessions: ref.watch(activeSessionsProvider.notifier),
    deduper: ref.watch(eventDeduperProvider),
    history: ref.watch(notificationHistoryProvider),
    // The persisted settings controller is the single source of truth for
    // the alert toggles; the router consumes them as NotificationSettings.
    readSettings: () {
      final settings = ref.read(settingsControllerProvider);
      return NotificationSettings(
        paused: settings.paused,
        soundEnabled: settings.soundEnabled,
        alertSound: settings.alertSound,
      );
    },
    // Question/permission alerts deep-link into the focused request page via
    // the navigation layer; the target is built from the event there.
    onActionRequiredClick: ref
        .watch(notificationNavigationProvider)
        .onActionRequiredClick,
  ),
);

/// The gateway realtime client. Disposed (disconnected) with the container.
final wsClientProvider = Provider<WsClient>((ref) {
  final client = GatewayWsClient(
    config: ref.watch(appConfigProvider),
    tokenHolder: ref.watch(accessTokenHolderProvider),
    refresher: ref.watch(tokenRefresherProvider),
  );
  ref.onDispose(client.disconnect);
  return client;
});

/// Runs while the user is authenticated and the app is in the foreground:
/// wires the [WsClient] event stream into the [NotificationRouter]. Returns
/// `null` while unauthenticated — the auth state is watched before
/// [wsClientProvider], so no [GatewayWsClient] is built (and no socket
/// opened) without a session. Rebuilt on auth and foreground changes: the
/// old controller is stopped via [ProviderRef.onDispose], and a fresh one
/// replaces it, started only in the foreground — so backgrounding the app
/// disconnects the socket and foregrounding reconnects it.
final realtimeControllerProvider = Provider<RealtimeController?>((ref) {
  if (ref.watch(authControllerProvider) is! Authenticated) {
    return null;
  }
  final foreground = ref.watch(appForegroundProvider);
  final controller = RealtimeController(
    client: ref.watch(wsClientProvider),
    router: ref.watch(notificationRouterProvider),
    onInstancePresences: ref
        .watch(instancePresencesProvider.notifier)
        .replaceAll,
  );
  ref.onDispose(controller.stop);
  if (foreground) {
    controller.start();
  }
  return controller;
});

/// Owns the subscription from [WsClient.events] into
/// [NotificationRouter.handle] and the client's connect lifecycle.
///
/// [start]/[stop] are idempotent and may be interleaved freely; [start]
/// after [stop] re-subscribes and reconnects.
class RealtimeController {
  RealtimeController({
    required WsClient client,
    required NotificationRouter router,
    required void Function(List<OpenCodeInstancePresence>) onInstancePresences,
  }) : _client = client,
       _router = router,
       _onInstancePresences = onInstancePresences;

  final WsClient _client;
  final NotificationRouter _router;
  final void Function(List<OpenCodeInstancePresence>) _onInstancePresences;

  StreamSubscription<NotifyEvent>? _eventSubscription;
  StreamSubscription<List<OpenCodeInstancePresence>>? _presenceSubscription;

  bool get _started => _eventSubscription != null;

  /// Subscribes to the event stream and connects the client. No-op when
  /// already started.
  void start() {
    if (_started) {
      return;
    }
    _eventSubscription = _client.events.listen(_route);
    _presenceSubscription = _client.instancePresences.listen(
      _onInstancePresences,
    );
    _client.connect();
  }

  /// Routes one event, isolating failures: a throwing router (e.g. the
  /// platform notification service rejects the alert) is logged, never
  /// surfaced as an unhandled async error. Events that reached the router's
  /// history write stay recorded — the history write precedes the alert —
  /// so a platform failure only costs the popup, not the record.
  void _route(NotifyEvent event) {
    unawaited(() async {
      try {
        await _router.handle(event);
      } catch (error, stackTrace) {
        log(
          'failed to handle realtime event ${event.eventId}',
          name: 'RealtimeController',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }());
  }

  /// Cancels the subscription and disconnects the client. No-op when
  /// already stopped.
  void stop() {
    if (!_started) {
      return;
    }
    final eventSubscription = _eventSubscription!;
    final presenceSubscription = _presenceSubscription;
    _eventSubscription = null;
    _presenceSubscription = null;
    unawaited(eventSubscription.cancel());
    if (presenceSubscription != null) {
      unawaited(presenceSubscription.cancel());
    }
    _client.disconnect();
  }
}
