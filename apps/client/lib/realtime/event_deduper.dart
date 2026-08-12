import 'dart:collection';

/// Bounded in-memory deduper for realtime event IDs.
///
/// The gateway can deliver the same event over both the WebSocket and FCM
/// (or re-deliver after a reconnect), so consumers call [isDuplicate]
/// before acting on an event. IDs are kept in a [LinkedHashSet], which
/// preserves insertion order, so once [capacity] distinct IDs are tracked
/// each new ID evicts the oldest one.
class EventDeduper {
  EventDeduper({this.capacity = 500}) {
    if (capacity <= 0) {
      throw ArgumentError.value(capacity, 'capacity', 'must be positive');
    }
  }

  /// Maximum number of event IDs remembered before the oldest is evicted.
  final int capacity;

  final LinkedHashSet<String> _seen = LinkedHashSet<String>();

  /// Returns `true` when [eventId] was already seen (a duplicate), and
  /// records it when new. Recording a new ID beyond [capacity] evicts the
  /// oldest ID. A duplicate hit never refreshes the ID's position.
  bool isDuplicate(String eventId) {
    if (_seen.contains(eventId)) {
      return true;
    }
    if (_seen.length >= capacity) {
      _seen.remove(_seen.first);
    }
    _seen.add(eventId);
    return false;
  }
}
