import 'dart:async';
import 'dart:developer' show log;

import 'notification_history.dart';

/// Keeps notifications flowing when the local database cannot be opened or
/// temporarily becomes unavailable. The fallback is intentionally process-local
/// and never replaces the SQLite file.
class ResilientNotificationHistory implements NotificationHistory {
  ResilientNotificationHistory({
    required NotificationHistory primary,
    required InMemoryNotificationHistory fallback,
  }) : _primary = primary,
       _fallback = fallback,
       _active = primary {
    _activeChanges = _active.changes.listen(_changes.add);
  }

  final NotificationHistory _primary;
  final InMemoryNotificationHistory _fallback;
  NotificationHistory _active;
  final StreamController<void> _changes = StreamController.broadcast(
    sync: true,
  );
  late StreamSubscription<void> _activeChanges;
  Future<void>? _fallbackActivation;
  bool _closed = false;

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<bool> contains(String eventId) =>
      _run((history) => history.contains(eventId));

  @override
  Future<void> add(HistoryEntry entry) => _run((history) => history.add(entry));

  @override
  Future<HistoryBatch> loadPage({required int offset, required int limit}) =>
      _run((history) => history.loadPage(offset: offset, limit: limit));

  Future<T> _run<T>(
    Future<T> Function(NotificationHistory history) action,
  ) async {
    final active = _active;
    try {
      return await action(active);
    } catch (error, stackTrace) {
      if (!identical(active, _primary) || _closed) rethrow;
      log(
        'local SQLite history unavailable; using in-memory history',
        name: 'NotificationHistory',
        error: error,
        stackTrace: stackTrace,
      );
      final activation = _fallbackActivation ??= _activateFallback();
      await activation;
      return action(_active);
    }
  }

  Future<void> _activateFallback() async {
    await _activeChanges.cancel();
    await _primary.close();
    _active = _fallback;
    _activeChanges = _active.changes.listen(_changes.add);
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    final activation = _fallbackActivation;
    if (activation != null) await activation;
    await _activeChanges.cancel();
    await _changes.close();
    if (identical(_active, _primary)) {
      await _primary.close();
    } else {
      await _fallback.close();
    }
  }
}
