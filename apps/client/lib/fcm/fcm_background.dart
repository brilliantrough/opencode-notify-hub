import 'dart:async';
import 'dart:convert';
import 'dart:developer' show log;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../firebase_options.dart';
import '../history/notification_history.dart';
import '../history/sqlite_notification_history.dart';
import '../notifications/notification_text.dart';
import '../realtime/notify_event.dart';

/// Top-level FCM background message handler, registered via
/// `FirebaseMessaging.onBackgroundMessage` in `FcmService.init`.
///
/// Runs in its own isolate when the app is backgrounded or terminated, so it
/// must initialize Firebase itself and can only share state through
/// persistence — the in-memory `EventDeduper`/`ActiveSessions` of the
/// foreground isolate are unreachable here.
///
/// The notification popup itself is rendered by the system from the FCM
/// `notification` payload; this handler only keeps the persisted
/// notification history consistent for data messages.
@pragma('vm:entry-point')
Future<void> fcmBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final history = SqliteNotificationHistory.openDefault();
  try {
    await processBackgroundMessageData(message.data, history);
  } catch (error, stackTrace) {
    log(
      'failed to record background FCM history',
      name: 'FcmBackground',
      error: error,
      stackTrace: stackTrace,
    );
  } finally {
    await history.close();
  }
}

/// Maps an FCM data payload to a [NotifyEvent].
///
/// The gateway sends the serialized event envelope as the `event` data value
/// (FCM data values are strings), so it must be JSON-decoded before parsing.
/// Returns `null` for missing, non-string, or malformed payloads — a push
/// that fails to parse must never crash the background isolate.
NotifyEvent? parseFcmEventData(Map<String, dynamic> data) {
  final raw = data['event'];
  if (raw is! String) {
    return null;
  }
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    return NotifyEvent.parse(decoded);
  } on FormatException {
    return null;
  }
}

/// Runs asynchronous actions one at a time, in call order.
///
/// A failing action propagates its error to its own caller but never jams
/// the queue: the next action still runs.
class ActionQueue {
  Future<void> _tail = Future.value();

  /// Enqueues [action] behind all previously enqueued actions and returns
  /// its result.
  Future<T> run<T>(Future<T> Function() action) {
    final previous = _tail;
    final completer = Completer<void>();
    _tail = completer.future;
    return previous.then((_) => action()).whenComplete(completer.complete);
  }
}

/// Serializes [processBackgroundMessageData] calls within an isolate: the
/// history check-then-record is only race-free when messages don't
/// interleave, and FCM may invoke the background handler for a second
/// message while the first is still awaiting its SQLite write.
final _backgroundQueue = ActionQueue();

/// Records one background FCM data payload in the persisted [history].
///
/// Serialized per isolate via an [ActionQueue]; concurrent calls are
/// processed one at a time, in arrival order.
///
/// - malformed payloads are ignored;
/// - `heartbeat` and `action_resolved` are skipped entirely (they never
///   produce history entries or popups — see `NotificationRouter`);
/// - an event already present in [history] (dedupe against FCM/WS double
///   delivery and re-deliveries) is skipped;
/// - `action_required` and `terminal` are recorded with the rendered
///   notification title/body.
Future<void> processBackgroundMessageData(
  Map<String, dynamic> data,
  NotificationHistory history, {
  DateTime Function()? now,
}) => _backgroundQueue.run(
  () => _processBackgroundMessageData(data, history, now: now),
);

Future<void> _processBackgroundMessageData(
  Map<String, dynamic> data,
  NotificationHistory history, {
  DateTime Function()? now,
}) async {
  final event = parseFcmEventData(data);
  if (event == null) {
    return;
  }
  if (event.type == NotifyEventType.heartbeat ||
      event.type == NotifyEventType.actionResolved) {
    return;
  }
  if (await history.contains(event.eventId)) {
    return;
  }
  await history.add(
    buildHistoryEntry(event, receivedAt: (now ?? DateTime.now)()),
  );
}
