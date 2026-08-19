import 'dart:async';

/// One rendered notification and its bounded local routing context.
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
  if (value is! String) return null;
  return DateTime.tryParse(value);
}

class HistoryBatch {
  const HistoryBatch({required this.entries, required this.totalCount});

  final List<HistoryEntry> entries;
  final int totalCount;
}

/// Device-local append-only notification history.
abstract interface class NotificationHistory {
  /// Emits after this adapter inserts a new unique event.
  Stream<void> get changes;

  Future<bool> contains(String eventId);

  Future<void> add(HistoryEntry entry);

  Future<HistoryBatch> loadPage({required int offset, required int limit});

  Future<void> close();
}

/// Test adapter with the same retention and paging semantics as SQLite.
class InMemoryNotificationHistory implements NotificationHistory {
  InMemoryNotificationHistory({this.capacity = 10000}) {
    if (capacity <= 0) {
      throw ArgumentError.value(capacity, 'capacity', 'must be positive');
    }
  }

  final int capacity;
  final List<HistoryEntry> _entries = [];
  final StreamController<void> _changes = StreamController.broadcast(
    sync: true,
  );

  List<HistoryEntry> get entries => List.unmodifiable(_entries);

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<bool> contains(String eventId) async =>
      _entries.any((entry) => entry.eventId == eventId);

  @override
  Future<void> add(HistoryEntry entry) async {
    if (_entries.any((candidate) => candidate.eventId == entry.eventId)) {
      return;
    }
    _entries.insert(0, entry);
    if (_entries.length > capacity) {
      _entries.removeRange(capacity, _entries.length);
    }
    _changes.add(null);
  }

  @override
  Future<HistoryBatch> loadPage({
    required int offset,
    required int limit,
  }) async {
    if (offset < 0 || limit <= 0) {
      throw ArgumentError('offset must be non-negative and limit positive');
    }
    final start = offset.clamp(0, _entries.length);
    final end = (start + limit).clamp(start, _entries.length);
    return HistoryBatch(
      entries: List.unmodifiable(_entries.sublist(start, end)),
      totalCount: _entries.length,
    );
  }

  @override
  Future<void> close() => _changes.close();
}
