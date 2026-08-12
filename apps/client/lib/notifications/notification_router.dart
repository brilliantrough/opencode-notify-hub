import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../history/notification_history.dart';
import '../realtime/active_sessions.dart';
import '../realtime/event_deduper.dart';
import '../realtime/notify_event.dart';
import 'notification_service.dart';
import 'notification_text.dart';

final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsController, NotificationSettings>(
      NotificationSettingsController.new,
    );

/// User-facing alert toggles consulted by the [NotificationRouter] on every
/// alertable event.
///
/// [paused] suppresses the popup entirely (history is still recorded);
/// [soundEnabled] only controls whether the shown alert plays a sound.
class NotificationSettings {
  const NotificationSettings({this.paused = false, this.soundEnabled = true});

  final bool paused;
  final bool soundEnabled;

  NotificationSettings copyWith({bool? paused, bool? soundEnabled}) =>
      NotificationSettings(
        paused: paused ?? this.paused,
        soundEnabled: soundEnabled ?? this.soundEnabled,
      );
}

class NotificationSettingsController extends Notifier<NotificationSettings> {
  @override
  NotificationSettings build() => const NotificationSettings();

  void setPaused(bool paused) => state = state.copyWith(paused: paused);

  void setSoundEnabled(bool soundEnabled) =>
      state = state.copyWith(soundEnabled: soundEnabled);
}

/// Single routing point for every realtime [NotifyEvent], regardless of
/// transport (WebSocket or foreground FCM).
///
/// One switch over the event type decides the effect; all dependencies are
/// injected so this class stays free of platform checks:
///
/// - duplicate event IDs (WS + FCM double delivery, reconnect replays) are
///   fully ignored — checked against both the in-memory [EventDeduper] and
///   the persisted [NotificationHistory], so an event recorded before an app
///   restart is never alerted twice;
/// - `heartbeat` only refreshes [ActiveSessions] — never history, popup, or
///   sound;
/// - `action_required` records the pending request, appends to history, and
///   alerts;
/// - `terminal` ends the session, appends to history, and alerts;
/// - `action_resolved` clears the pending request silently (no history, no
///   popup).
///
/// When settings are paused, history is still recorded but no alert is
/// shown; when sound is disabled the alert shows with
/// [NotifyRequest.playSound] `false`.
class NotificationRouter {
  NotificationRouter({
    required NotificationService service,
    required ActiveSessions activeSessions,
    required EventDeduper deduper,
    required NotificationHistory history,
    required NotificationSettings Function() readSettings,
    DateTime Function()? now,
  }) : _service = service,
       _activeSessions = activeSessions,
       _deduper = deduper,
       _history = history,
       _readSettings = readSettings,
       _now = now ?? DateTime.now;

  final NotificationService _service;
  final ActiveSessions _activeSessions;
  final EventDeduper _deduper;
  final NotificationHistory _history;
  final NotificationSettings Function() _readSettings;
  final DateTime Function() _now;

  Future<void> handle(NotifyEvent event) async {
    if (_deduper.isDuplicate(event.eventId) ||
        _history.contains(event.eventId)) {
      return;
    }
    switch (event.type) {
      case NotifyEventType.heartbeat:
        _activeSessions.upsertHeartbeat(event);
      case NotifyEventType.actionRequired:
        _activeSessions.addPending(event);
        await _recordAndAlert(event);
      case NotifyEventType.terminal:
        _activeSessions.markTerminal(event.sessionId);
        await _recordAndAlert(event);
      case NotifyEventType.actionResolved:
        final requestId = event.requestId;
        if (requestId != null) {
          _activeSessions.clearPending(event.sessionId, requestId);
        }
    }
  }

  Future<void> _recordAndAlert(NotifyEvent event) async {
    final title = buildNotificationTitle(event);
    final body = buildNotificationBody(event);
    _history.add(
      HistoryEntry(
        eventId: event.eventId,
        title: title,
        body: body,
        receivedAt: _now(),
      ),
    );
    final settings = _readSettings();
    if (settings.paused) {
      return;
    }
    await _service.show(
      NotifyRequest(
        eventId: event.eventId,
        title: title,
        body: body,
        playSound: settings.soundEnabled,
      ),
    );
  }
}
