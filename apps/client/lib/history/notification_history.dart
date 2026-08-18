import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// One recorded notification in the device-local history.
///
/// History stores the rendered notification plus bounded routing context used
/// by the local history table. It never stores the complete raw gateway event.
class HistoryEntry {
  const HistoryEntry({
    required this.eventId,
    required this.title,
    required this.body,
    required this.receivedAt,
    this.occurredAt,
    this.status,
    this.eventType,
    this.machine,
    this.project,
    this.directory,
    this.directoryName,
    this.sessionId,
    this.sessionTitle,
    this.requestId,
  });

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
    eventId: json['eventId'] as String,
    title: json['title'] as String,
    body: json['body'] as String,
    receivedAt: DateTime.parse(json['receivedAt'] as String),
    occurredAt: _optionalDateTime(json['occurredAt']),
    status: _optionalString(json['status']),
    eventType: _optionalString(json['eventType']),
    machine: _optionalString(json['machine']),
    project: _optionalString(json['project']),
    directory: _optionalString(json['directory']),
    directoryName: _optionalString(json['directoryName']),
    sessionId: _optionalString(json['sessionId']),
    sessionTitle: _optionalString(json['sessionTitle']),
    requestId: _optionalString(json['requestId']),
  );

  final String eventId;
  final String title;
  final String body;
  final DateTime receivedAt;
  final DateTime? occurredAt;
  final String? status;
  final String? eventType;
  final String? machine;
  final String? project;
  final String? directory;
  final String? directoryName;
  final String? sessionId;
  final String? sessionTitle;
  final String? requestId;

  Map<String, dynamic> toJson() => {
    'eventId': eventId,
    'title': title,
    'body': body,
    'receivedAt': receivedAt.toIso8601String(),
    if (occurredAt != null) 'occurredAt': occurredAt!.toIso8601String(),
    if (status != null) 'status': status,
    if (eventType != null) 'eventType': eventType,
    if (machine != null) 'machine': machine,
    if (project != null) 'project': project,
    if (directory != null) 'directory': directory,
    if (directoryName != null) 'directoryName': directoryName,
    if (sessionId != null) 'sessionId': sessionId,
    if (sessionTitle != null) 'sessionTitle': sessionTitle,
    if (requestId != null) 'requestId': requestId,
  };
}

String? _optionalString(Object? value) => value is String ? value : null;

DateTime? _optionalDateTime(Object? value) {
  if (value is! String) {
    return null;
  }
  return DateTime.tryParse(value);
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

  PrefsNotificationHistory._hydrating({required this.capacity}) : _entries = [];

  /// Creates a history that starts empty and hydrates from disk in the
  /// background, so synchronous provider graphs can use the persistent
  /// history without an async bootstrap.
  ///
  /// Entries added before hydration completes are newer than anything stored:
  /// they stay in front and stored duplicates of their event IDs are dropped.
  /// [add] awaits hydration before persisting, so nothing is lost. When the
  /// store is unreadable (e.g. no plugin binding in tests) the history keeps
  /// working in-memory only.
  factory PrefsNotificationHistory.hydrating({int capacity = defaultCapacity}) {
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
  static Future<PrefsNotificationHistory> load({
    int capacity = defaultCapacity,
  }) async {
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
