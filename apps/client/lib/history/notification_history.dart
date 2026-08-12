import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// One recorded notification in the device-local history.
///
/// History stores only the rendered notification (event ID, title, body) and
/// the local receive time — never the raw gateway payload.
class HistoryEntry {
  const HistoryEntry({
    required this.eventId,
    required this.title,
    required this.body,
    required this.receivedAt,
  });

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
    eventId: json['eventId'] as String,
    title: json['title'] as String,
    body: json['body'] as String,
    receivedAt: DateTime.parse(json['receivedAt'] as String),
  );

  final String eventId;
  final String title;
  final String body;
  final DateTime receivedAt;

  Map<String, dynamic> toJson() => {
    'eventId': eventId,
    'title': title,
    'body': body,
    'receivedAt': receivedAt.toIso8601String(),
  };
}

/// Append-only store of shown (or pause-suppressed) notifications.
abstract class NotificationHistory {
  /// Newest-first view of the recorded entries.
  List<HistoryEntry> get entries;

  /// Whether an entry with [eventId] has been recorded. Synchronous over the
  /// currently loaded view — a still-hydrating persistent history may briefly
  /// report `false` for entries not yet loaded from disk.
  bool contains(String eventId);

  /// Records [entry].
  void add(HistoryEntry entry);
}

/// Bounded in-memory [NotificationHistory] keeping the newest [capacity]
/// entries.
class InMemoryNotificationHistory implements NotificationHistory {
  InMemoryNotificationHistory({this.capacity = 50}) {
    if (capacity <= 0) {
      throw ArgumentError.value(capacity, 'capacity', 'must be positive');
    }
  }

  /// Maximum number of entries kept before the oldest is dropped.
  final int capacity;

  final List<HistoryEntry> _entries = [];

  @override
  List<HistoryEntry> get entries => List.unmodifiable(_entries);

  @override
  bool contains(String eventId) => _entries.any((e) => e.eventId == eventId);

  @override
  void add(HistoryEntry entry) {
    _entries.insert(0, entry);
    if (_entries.length > capacity) {
      _entries.removeLast();
    }
  }
}

/// [NotificationHistory] persisted to `shared_preferences` so recorded
/// notifications survive app restarts.
///
/// Entries are stored as a JSON list under [storageKey], newest first, capped
/// at [capacity]. A missing or corrupt stored value loads as an empty history
/// and is overwritten by the next [add].
class PrefsNotificationHistory implements NotificationHistory {
  PrefsNotificationHistory._(
    this._prefs,
    this._entries, {
    this.capacity = defaultCapacity,
  }) : _persistReady = true;

  PrefsNotificationHistory._hydrating({required this.capacity})
    : _entries = [];

  /// Creates a history that starts empty and hydrates from disk in the
  /// background, so synchronous provider graphs can use the persistent
  /// history without an async bootstrap.
  ///
  /// Entries added before hydration completes are newer than anything stored:
  /// they stay in front and stored duplicates of their event IDs are dropped.
  /// [add] awaits hydration before persisting, so nothing is lost. When the
  /// store is unreadable (e.g. no plugin binding in tests) the history keeps
  /// working in-memory only.
  factory PrefsNotificationHistory.hydrating({
    int capacity = defaultCapacity,
  }) {
    if (capacity <= 0) {
      throw ArgumentError.value(capacity, 'capacity', 'must be positive');
    }
    final history = PrefsNotificationHistory._hydrating(capacity: capacity);
    history._hydration = history._hydrate();
    return history;
  }

  /// Shared-preferences key holding the JSON-encoded entry list.
  static const String storageKey = 'notification_history_v1';

  /// Default maximum number of entries kept before the oldest is dropped.
  static const int defaultCapacity = 50;

  /// Maximum number of entries kept before the oldest is dropped.
  final int capacity;

  late final SharedPreferences _prefs;
  final List<HistoryEntry> _entries;

  bool _persistReady = false;
  Future<void>? _hydration;

  /// Completes when the initial disk load has finished (or failed). Always
  /// completes immediately for histories created via [load].
  Future<void> get ready => _hydration ?? Future.value();

  Future<void> _hydrate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = _readEntries(prefs);
      _prefs = prefs;
      final seen = _entries.map((e) => e.eventId).toSet();
      _entries.addAll(stored.where((e) => !seen.contains(e.eventId)));
      while (_entries.length > capacity) {
        _entries.removeLast();
      }
      _persistReady = true;
    } catch (_) {
      // Unreadable store (no plugin binding, ...): in-memory only.
    }
  }

  /// Loads the persisted history, returning an empty history when nothing was
  /// stored or the stored value is not a valid JSON entry list.
  static Future<PrefsNotificationHistory> load({int capacity = defaultCapacity}) async {
    if (capacity <= 0) {
      throw ArgumentError.value(capacity, 'capacity', 'must be positive');
    }
    final prefs = await SharedPreferences.getInstance();
    return PrefsNotificationHistory._(
      prefs,
      _readEntries(prefs),
      capacity: capacity,
    );
  }

  static List<HistoryEntry> _readEntries(SharedPreferences prefs) {
    try {
      final raw = prefs.getString(storageKey);
      if (raw == null) return [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return [
        for (final item in decoded)
          if (item is Map<String, dynamic>) HistoryEntry.fromJson(item),
      ];
    } catch (_) {
      // Corrupt or partially malformed payload: start from an empty history.
      return [];
    }
  }

  @override
  List<HistoryEntry> get entries => List.unmodifiable(_entries);

  /// Whether an entry with [eventId] has been recorded.
  @override
  bool contains(String eventId) => _entries.any((e) => e.eventId == eventId);

  /// Records [entry] newest-first, truncates to [capacity], and persists the
  /// result (once the store is ready — see [hydrating]).
  @override
  Future<void> add(HistoryEntry entry) async {
    _entries.insert(0, entry);
    if (_entries.length > capacity) {
      _entries.removeLast();
    }
    await _hydration;
    if (_persistReady) {
      await _persist();
    }
  }

  Future<void> _persist() {
    final json = jsonEncode([for (final entry in _entries) entry.toJson()]);
    return _prefs.setString(storageKey, json);
  }
}
