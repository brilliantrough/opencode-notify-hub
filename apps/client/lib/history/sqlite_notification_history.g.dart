// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sqlite_notification_history.dart';

// ignore_for_file: type=lint
class $HistoryRecordsTable extends HistoryRecords
    with TableInfo<$HistoryRecordsTable, StoredHistoryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HistoryRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receivedAtMicrosMeta = const VerificationMeta(
    'receivedAtMicros',
  );
  @override
  late final GeneratedColumn<int> receivedAtMicros = GeneratedColumn<int>(
    'received_at_micros',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredAtMicrosMeta = const VerificationMeta(
    'occurredAtMicros',
  );
  @override
  late final GeneratedColumn<int> occurredAtMicros = GeneratedColumn<int>(
    'occurred_at_micros',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _machineMeta = const VerificationMeta(
    'machine',
  );
  @override
  late final GeneratedColumn<String> machine = GeneratedColumn<String>(
    'machine',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _projectMeta = const VerificationMeta(
    'project',
  );
  @override
  late final GeneratedColumn<String> project = GeneratedColumn<String>(
    'project',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _directoryMeta = const VerificationMeta(
    'directory',
  );
  @override
  late final GeneratedColumn<String> directory = GeneratedColumn<String>(
    'directory',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _directoryNameMeta = const VerificationMeta(
    'directoryName',
  );
  @override
  late final GeneratedColumn<String> directoryName = GeneratedColumn<String>(
    'directory_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sessionTitleMeta = const VerificationMeta(
    'sessionTitle',
  );
  @override
  late final GeneratedColumn<String> sessionTitle = GeneratedColumn<String>(
    'session_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _requestIdMeta = const VerificationMeta(
    'requestId',
  );
  @override
  late final GeneratedColumn<String> requestId = GeneratedColumn<String>(
    'request_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    eventId,
    title,
    body,
    receivedAtMicros,
    occurredAtMicros,
    status,
    eventType,
    machine,
    project,
    directory,
    directoryName,
    sessionId,
    sessionTitle,
    requestId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'history_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredHistoryEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('received_at_micros')) {
      context.handle(
        _receivedAtMicrosMeta,
        receivedAtMicros.isAcceptableOrUnknown(
          data['received_at_micros']!,
          _receivedAtMicrosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_receivedAtMicrosMeta);
    }
    if (data.containsKey('occurred_at_micros')) {
      context.handle(
        _occurredAtMicrosMeta,
        occurredAtMicros.isAcceptableOrUnknown(
          data['occurred_at_micros']!,
          _occurredAtMicrosMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    }
    if (data.containsKey('machine')) {
      context.handle(
        _machineMeta,
        machine.isAcceptableOrUnknown(data['machine']!, _machineMeta),
      );
    }
    if (data.containsKey('project')) {
      context.handle(
        _projectMeta,
        project.isAcceptableOrUnknown(data['project']!, _projectMeta),
      );
    }
    if (data.containsKey('directory')) {
      context.handle(
        _directoryMeta,
        directory.isAcceptableOrUnknown(data['directory']!, _directoryMeta),
      );
    }
    if (data.containsKey('directory_name')) {
      context.handle(
        _directoryNameMeta,
        directoryName.isAcceptableOrUnknown(
          data['directory_name']!,
          _directoryNameMeta,
        ),
      );
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    }
    if (data.containsKey('session_title')) {
      context.handle(
        _sessionTitleMeta,
        sessionTitle.isAcceptableOrUnknown(
          data['session_title']!,
          _sessionTitleMeta,
        ),
      );
    }
    if (data.containsKey('request_id')) {
      context.handle(
        _requestIdMeta,
        requestId.isAcceptableOrUnknown(data['request_id']!, _requestIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {eventId};
  @override
  StoredHistoryEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredHistoryEntry(
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      receivedAtMicros: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}received_at_micros'],
      )!,
      occurredAtMicros: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}occurred_at_micros'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      ),
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      ),
      machine: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}machine'],
      ),
      project: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project'],
      ),
      directory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}directory'],
      ),
      directoryName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}directory_name'],
      ),
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      ),
      sessionTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_title'],
      ),
      requestId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}request_id'],
      ),
    );
  }

  @override
  $HistoryRecordsTable createAlias(String alias) {
    return $HistoryRecordsTable(attachedDatabase, alias);
  }
}

class StoredHistoryEntry extends DataClass
    implements Insertable<StoredHistoryEntry> {
  final String eventId;
  final String title;
  final String body;
  final int receivedAtMicros;
  final int? occurredAtMicros;
  final String? status;
  final String? eventType;
  final String? machine;
  final String? project;
  final String? directory;
  final String? directoryName;
  final String? sessionId;
  final String? sessionTitle;
  final String? requestId;
  const StoredHistoryEntry({
    required this.eventId,
    required this.title,
    required this.body,
    required this.receivedAtMicros,
    this.occurredAtMicros,
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
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['event_id'] = Variable<String>(eventId);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    map['received_at_micros'] = Variable<int>(receivedAtMicros);
    if (!nullToAbsent || occurredAtMicros != null) {
      map['occurred_at_micros'] = Variable<int>(occurredAtMicros);
    }
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<String>(status);
    }
    if (!nullToAbsent || eventType != null) {
      map['event_type'] = Variable<String>(eventType);
    }
    if (!nullToAbsent || machine != null) {
      map['machine'] = Variable<String>(machine);
    }
    if (!nullToAbsent || project != null) {
      map['project'] = Variable<String>(project);
    }
    if (!nullToAbsent || directory != null) {
      map['directory'] = Variable<String>(directory);
    }
    if (!nullToAbsent || directoryName != null) {
      map['directory_name'] = Variable<String>(directoryName);
    }
    if (!nullToAbsent || sessionId != null) {
      map['session_id'] = Variable<String>(sessionId);
    }
    if (!nullToAbsent || sessionTitle != null) {
      map['session_title'] = Variable<String>(sessionTitle);
    }
    if (!nullToAbsent || requestId != null) {
      map['request_id'] = Variable<String>(requestId);
    }
    return map;
  }

  HistoryRecordsCompanion toCompanion(bool nullToAbsent) {
    return HistoryRecordsCompanion(
      eventId: Value(eventId),
      title: Value(title),
      body: Value(body),
      receivedAtMicros: Value(receivedAtMicros),
      occurredAtMicros: occurredAtMicros == null && nullToAbsent
          ? const Value.absent()
          : Value(occurredAtMicros),
      status: status == null && nullToAbsent
          ? const Value.absent()
          : Value(status),
      eventType: eventType == null && nullToAbsent
          ? const Value.absent()
          : Value(eventType),
      machine: machine == null && nullToAbsent
          ? const Value.absent()
          : Value(machine),
      project: project == null && nullToAbsent
          ? const Value.absent()
          : Value(project),
      directory: directory == null && nullToAbsent
          ? const Value.absent()
          : Value(directory),
      directoryName: directoryName == null && nullToAbsent
          ? const Value.absent()
          : Value(directoryName),
      sessionId: sessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionId),
      sessionTitle: sessionTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionTitle),
      requestId: requestId == null && nullToAbsent
          ? const Value.absent()
          : Value(requestId),
    );
  }

  factory StoredHistoryEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredHistoryEntry(
      eventId: serializer.fromJson<String>(json['eventId']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      receivedAtMicros: serializer.fromJson<int>(json['receivedAtMicros']),
      occurredAtMicros: serializer.fromJson<int?>(json['occurredAtMicros']),
      status: serializer.fromJson<String?>(json['status']),
      eventType: serializer.fromJson<String?>(json['eventType']),
      machine: serializer.fromJson<String?>(json['machine']),
      project: serializer.fromJson<String?>(json['project']),
      directory: serializer.fromJson<String?>(json['directory']),
      directoryName: serializer.fromJson<String?>(json['directoryName']),
      sessionId: serializer.fromJson<String?>(json['sessionId']),
      sessionTitle: serializer.fromJson<String?>(json['sessionTitle']),
      requestId: serializer.fromJson<String?>(json['requestId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'eventId': serializer.toJson<String>(eventId),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'receivedAtMicros': serializer.toJson<int>(receivedAtMicros),
      'occurredAtMicros': serializer.toJson<int?>(occurredAtMicros),
      'status': serializer.toJson<String?>(status),
      'eventType': serializer.toJson<String?>(eventType),
      'machine': serializer.toJson<String?>(machine),
      'project': serializer.toJson<String?>(project),
      'directory': serializer.toJson<String?>(directory),
      'directoryName': serializer.toJson<String?>(directoryName),
      'sessionId': serializer.toJson<String?>(sessionId),
      'sessionTitle': serializer.toJson<String?>(sessionTitle),
      'requestId': serializer.toJson<String?>(requestId),
    };
  }

  StoredHistoryEntry copyWith({
    String? eventId,
    String? title,
    String? body,
    int? receivedAtMicros,
    Value<int?> occurredAtMicros = const Value.absent(),
    Value<String?> status = const Value.absent(),
    Value<String?> eventType = const Value.absent(),
    Value<String?> machine = const Value.absent(),
    Value<String?> project = const Value.absent(),
    Value<String?> directory = const Value.absent(),
    Value<String?> directoryName = const Value.absent(),
    Value<String?> sessionId = const Value.absent(),
    Value<String?> sessionTitle = const Value.absent(),
    Value<String?> requestId = const Value.absent(),
  }) => StoredHistoryEntry(
    eventId: eventId ?? this.eventId,
    title: title ?? this.title,
    body: body ?? this.body,
    receivedAtMicros: receivedAtMicros ?? this.receivedAtMicros,
    occurredAtMicros: occurredAtMicros.present
        ? occurredAtMicros.value
        : this.occurredAtMicros,
    status: status.present ? status.value : this.status,
    eventType: eventType.present ? eventType.value : this.eventType,
    machine: machine.present ? machine.value : this.machine,
    project: project.present ? project.value : this.project,
    directory: directory.present ? directory.value : this.directory,
    directoryName: directoryName.present
        ? directoryName.value
        : this.directoryName,
    sessionId: sessionId.present ? sessionId.value : this.sessionId,
    sessionTitle: sessionTitle.present ? sessionTitle.value : this.sessionTitle,
    requestId: requestId.present ? requestId.value : this.requestId,
  );
  StoredHistoryEntry copyWithCompanion(HistoryRecordsCompanion data) {
    return StoredHistoryEntry(
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      receivedAtMicros: data.receivedAtMicros.present
          ? data.receivedAtMicros.value
          : this.receivedAtMicros,
      occurredAtMicros: data.occurredAtMicros.present
          ? data.occurredAtMicros.value
          : this.occurredAtMicros,
      status: data.status.present ? data.status.value : this.status,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      machine: data.machine.present ? data.machine.value : this.machine,
      project: data.project.present ? data.project.value : this.project,
      directory: data.directory.present ? data.directory.value : this.directory,
      directoryName: data.directoryName.present
          ? data.directoryName.value
          : this.directoryName,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      sessionTitle: data.sessionTitle.present
          ? data.sessionTitle.value
          : this.sessionTitle,
      requestId: data.requestId.present ? data.requestId.value : this.requestId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredHistoryEntry(')
          ..write('eventId: $eventId, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('receivedAtMicros: $receivedAtMicros, ')
          ..write('occurredAtMicros: $occurredAtMicros, ')
          ..write('status: $status, ')
          ..write('eventType: $eventType, ')
          ..write('machine: $machine, ')
          ..write('project: $project, ')
          ..write('directory: $directory, ')
          ..write('directoryName: $directoryName, ')
          ..write('sessionId: $sessionId, ')
          ..write('sessionTitle: $sessionTitle, ')
          ..write('requestId: $requestId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    eventId,
    title,
    body,
    receivedAtMicros,
    occurredAtMicros,
    status,
    eventType,
    machine,
    project,
    directory,
    directoryName,
    sessionId,
    sessionTitle,
    requestId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredHistoryEntry &&
          other.eventId == this.eventId &&
          other.title == this.title &&
          other.body == this.body &&
          other.receivedAtMicros == this.receivedAtMicros &&
          other.occurredAtMicros == this.occurredAtMicros &&
          other.status == this.status &&
          other.eventType == this.eventType &&
          other.machine == this.machine &&
          other.project == this.project &&
          other.directory == this.directory &&
          other.directoryName == this.directoryName &&
          other.sessionId == this.sessionId &&
          other.sessionTitle == this.sessionTitle &&
          other.requestId == this.requestId);
}

class HistoryRecordsCompanion extends UpdateCompanion<StoredHistoryEntry> {
  final Value<String> eventId;
  final Value<String> title;
  final Value<String> body;
  final Value<int> receivedAtMicros;
  final Value<int?> occurredAtMicros;
  final Value<String?> status;
  final Value<String?> eventType;
  final Value<String?> machine;
  final Value<String?> project;
  final Value<String?> directory;
  final Value<String?> directoryName;
  final Value<String?> sessionId;
  final Value<String?> sessionTitle;
  final Value<String?> requestId;
  final Value<int> rowid;
  const HistoryRecordsCompanion({
    this.eventId = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.receivedAtMicros = const Value.absent(),
    this.occurredAtMicros = const Value.absent(),
    this.status = const Value.absent(),
    this.eventType = const Value.absent(),
    this.machine = const Value.absent(),
    this.project = const Value.absent(),
    this.directory = const Value.absent(),
    this.directoryName = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.sessionTitle = const Value.absent(),
    this.requestId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HistoryRecordsCompanion.insert({
    required String eventId,
    required String title,
    required String body,
    required int receivedAtMicros,
    this.occurredAtMicros = const Value.absent(),
    this.status = const Value.absent(),
    this.eventType = const Value.absent(),
    this.machine = const Value.absent(),
    this.project = const Value.absent(),
    this.directory = const Value.absent(),
    this.directoryName = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.sessionTitle = const Value.absent(),
    this.requestId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : eventId = Value(eventId),
       title = Value(title),
       body = Value(body),
       receivedAtMicros = Value(receivedAtMicros);
  static Insertable<StoredHistoryEntry> custom({
    Expression<String>? eventId,
    Expression<String>? title,
    Expression<String>? body,
    Expression<int>? receivedAtMicros,
    Expression<int>? occurredAtMicros,
    Expression<String>? status,
    Expression<String>? eventType,
    Expression<String>? machine,
    Expression<String>? project,
    Expression<String>? directory,
    Expression<String>? directoryName,
    Expression<String>? sessionId,
    Expression<String>? sessionTitle,
    Expression<String>? requestId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (eventId != null) 'event_id': eventId,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (receivedAtMicros != null) 'received_at_micros': receivedAtMicros,
      if (occurredAtMicros != null) 'occurred_at_micros': occurredAtMicros,
      if (status != null) 'status': status,
      if (eventType != null) 'event_type': eventType,
      if (machine != null) 'machine': machine,
      if (project != null) 'project': project,
      if (directory != null) 'directory': directory,
      if (directoryName != null) 'directory_name': directoryName,
      if (sessionId != null) 'session_id': sessionId,
      if (sessionTitle != null) 'session_title': sessionTitle,
      if (requestId != null) 'request_id': requestId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HistoryRecordsCompanion copyWith({
    Value<String>? eventId,
    Value<String>? title,
    Value<String>? body,
    Value<int>? receivedAtMicros,
    Value<int?>? occurredAtMicros,
    Value<String?>? status,
    Value<String?>? eventType,
    Value<String?>? machine,
    Value<String?>? project,
    Value<String?>? directory,
    Value<String?>? directoryName,
    Value<String?>? sessionId,
    Value<String?>? sessionTitle,
    Value<String?>? requestId,
    Value<int>? rowid,
  }) {
    return HistoryRecordsCompanion(
      eventId: eventId ?? this.eventId,
      title: title ?? this.title,
      body: body ?? this.body,
      receivedAtMicros: receivedAtMicros ?? this.receivedAtMicros,
      occurredAtMicros: occurredAtMicros ?? this.occurredAtMicros,
      status: status ?? this.status,
      eventType: eventType ?? this.eventType,
      machine: machine ?? this.machine,
      project: project ?? this.project,
      directory: directory ?? this.directory,
      directoryName: directoryName ?? this.directoryName,
      sessionId: sessionId ?? this.sessionId,
      sessionTitle: sessionTitle ?? this.sessionTitle,
      requestId: requestId ?? this.requestId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (receivedAtMicros.present) {
      map['received_at_micros'] = Variable<int>(receivedAtMicros.value);
    }
    if (occurredAtMicros.present) {
      map['occurred_at_micros'] = Variable<int>(occurredAtMicros.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (machine.present) {
      map['machine'] = Variable<String>(machine.value);
    }
    if (project.present) {
      map['project'] = Variable<String>(project.value);
    }
    if (directory.present) {
      map['directory'] = Variable<String>(directory.value);
    }
    if (directoryName.present) {
      map['directory_name'] = Variable<String>(directoryName.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (sessionTitle.present) {
      map['session_title'] = Variable<String>(sessionTitle.value);
    }
    if (requestId.present) {
      map['request_id'] = Variable<String>(requestId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HistoryRecordsCompanion(')
          ..write('eventId: $eventId, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('receivedAtMicros: $receivedAtMicros, ')
          ..write('occurredAtMicros: $occurredAtMicros, ')
          ..write('status: $status, ')
          ..write('eventType: $eventType, ')
          ..write('machine: $machine, ')
          ..write('project: $project, ')
          ..write('directory: $directory, ')
          ..write('directoryName: $directoryName, ')
          ..write('sessionId: $sessionId, ')
          ..write('sessionTitle: $sessionTitle, ')
          ..write('requestId: $requestId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$SqliteNotificationHistory extends GeneratedDatabase {
  _$SqliteNotificationHistory(QueryExecutor e) : super(e);
  $SqliteNotificationHistoryManager get managers =>
      $SqliteNotificationHistoryManager(this);
  late final $HistoryRecordsTable historyRecords = $HistoryRecordsTable(this);
  late final Index historyReceivedAtIdx = Index(
    'history_received_at_idx',
    'CREATE INDEX history_received_at_idx ON history_records (received_at_micros)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    historyRecords,
    historyReceivedAtIdx,
  ];
}

typedef $$HistoryRecordsTableCreateCompanionBuilder =
    HistoryRecordsCompanion Function({
      required String eventId,
      required String title,
      required String body,
      required int receivedAtMicros,
      Value<int?> occurredAtMicros,
      Value<String?> status,
      Value<String?> eventType,
      Value<String?> machine,
      Value<String?> project,
      Value<String?> directory,
      Value<String?> directoryName,
      Value<String?> sessionId,
      Value<String?> sessionTitle,
      Value<String?> requestId,
      Value<int> rowid,
    });
typedef $$HistoryRecordsTableUpdateCompanionBuilder =
    HistoryRecordsCompanion Function({
      Value<String> eventId,
      Value<String> title,
      Value<String> body,
      Value<int> receivedAtMicros,
      Value<int?> occurredAtMicros,
      Value<String?> status,
      Value<String?> eventType,
      Value<String?> machine,
      Value<String?> project,
      Value<String?> directory,
      Value<String?> directoryName,
      Value<String?> sessionId,
      Value<String?> sessionTitle,
      Value<String?> requestId,
      Value<int> rowid,
    });

class $$HistoryRecordsTableFilterComposer
    extends Composer<_$SqliteNotificationHistory, $HistoryRecordsTable> {
  $$HistoryRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get receivedAtMicros => $composableBuilder(
    column: $table.receivedAtMicros,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get occurredAtMicros => $composableBuilder(
    column: $table.occurredAtMicros,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get machine => $composableBuilder(
    column: $table.machine,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get project => $composableBuilder(
    column: $table.project,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get directory => $composableBuilder(
    column: $table.directory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get directoryName => $composableBuilder(
    column: $table.directoryName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionTitle => $composableBuilder(
    column: $table.sessionTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get requestId => $composableBuilder(
    column: $table.requestId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HistoryRecordsTableOrderingComposer
    extends Composer<_$SqliteNotificationHistory, $HistoryRecordsTable> {
  $$HistoryRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get receivedAtMicros => $composableBuilder(
    column: $table.receivedAtMicros,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get occurredAtMicros => $composableBuilder(
    column: $table.occurredAtMicros,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get machine => $composableBuilder(
    column: $table.machine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get project => $composableBuilder(
    column: $table.project,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get directory => $composableBuilder(
    column: $table.directory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get directoryName => $composableBuilder(
    column: $table.directoryName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionTitle => $composableBuilder(
    column: $table.sessionTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get requestId => $composableBuilder(
    column: $table.requestId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HistoryRecordsTableAnnotationComposer
    extends Composer<_$SqliteNotificationHistory, $HistoryRecordsTable> {
  $$HistoryRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<int> get receivedAtMicros => $composableBuilder(
    column: $table.receivedAtMicros,
    builder: (column) => column,
  );

  GeneratedColumn<int> get occurredAtMicros => $composableBuilder(
    column: $table.occurredAtMicros,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<String> get machine =>
      $composableBuilder(column: $table.machine, builder: (column) => column);

  GeneratedColumn<String> get project =>
      $composableBuilder(column: $table.project, builder: (column) => column);

  GeneratedColumn<String> get directory =>
      $composableBuilder(column: $table.directory, builder: (column) => column);

  GeneratedColumn<String> get directoryName => $composableBuilder(
    column: $table.directoryName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get sessionTitle => $composableBuilder(
    column: $table.sessionTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get requestId =>
      $composableBuilder(column: $table.requestId, builder: (column) => column);
}

class $$HistoryRecordsTableTableManager
    extends
        RootTableManager<
          _$SqliteNotificationHistory,
          $HistoryRecordsTable,
          StoredHistoryEntry,
          $$HistoryRecordsTableFilterComposer,
          $$HistoryRecordsTableOrderingComposer,
          $$HistoryRecordsTableAnnotationComposer,
          $$HistoryRecordsTableCreateCompanionBuilder,
          $$HistoryRecordsTableUpdateCompanionBuilder,
          (
            StoredHistoryEntry,
            BaseReferences<
              _$SqliteNotificationHistory,
              $HistoryRecordsTable,
              StoredHistoryEntry
            >,
          ),
          StoredHistoryEntry,
          PrefetchHooks Function()
        > {
  $$HistoryRecordsTableTableManager(
    _$SqliteNotificationHistory db,
    $HistoryRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HistoryRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HistoryRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HistoryRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> eventId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<int> receivedAtMicros = const Value.absent(),
                Value<int?> occurredAtMicros = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<String?> eventType = const Value.absent(),
                Value<String?> machine = const Value.absent(),
                Value<String?> project = const Value.absent(),
                Value<String?> directory = const Value.absent(),
                Value<String?> directoryName = const Value.absent(),
                Value<String?> sessionId = const Value.absent(),
                Value<String?> sessionTitle = const Value.absent(),
                Value<String?> requestId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HistoryRecordsCompanion(
                eventId: eventId,
                title: title,
                body: body,
                receivedAtMicros: receivedAtMicros,
                occurredAtMicros: occurredAtMicros,
                status: status,
                eventType: eventType,
                machine: machine,
                project: project,
                directory: directory,
                directoryName: directoryName,
                sessionId: sessionId,
                sessionTitle: sessionTitle,
                requestId: requestId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String eventId,
                required String title,
                required String body,
                required int receivedAtMicros,
                Value<int?> occurredAtMicros = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<String?> eventType = const Value.absent(),
                Value<String?> machine = const Value.absent(),
                Value<String?> project = const Value.absent(),
                Value<String?> directory = const Value.absent(),
                Value<String?> directoryName = const Value.absent(),
                Value<String?> sessionId = const Value.absent(),
                Value<String?> sessionTitle = const Value.absent(),
                Value<String?> requestId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HistoryRecordsCompanion.insert(
                eventId: eventId,
                title: title,
                body: body,
                receivedAtMicros: receivedAtMicros,
                occurredAtMicros: occurredAtMicros,
                status: status,
                eventType: eventType,
                machine: machine,
                project: project,
                directory: directory,
                directoryName: directoryName,
                sessionId: sessionId,
                sessionTitle: sessionTitle,
                requestId: requestId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HistoryRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$SqliteNotificationHistory,
      $HistoryRecordsTable,
      StoredHistoryEntry,
      $$HistoryRecordsTableFilterComposer,
      $$HistoryRecordsTableOrderingComposer,
      $$HistoryRecordsTableAnnotationComposer,
      $$HistoryRecordsTableCreateCompanionBuilder,
      $$HistoryRecordsTableUpdateCompanionBuilder,
      (
        StoredHistoryEntry,
        BaseReferences<
          _$SqliteNotificationHistory,
          $HistoryRecordsTable,
          StoredHistoryEntry
        >,
      ),
      StoredHistoryEntry,
      PrefetchHooks Function()
    >;

class $SqliteNotificationHistoryManager {
  final _$SqliteNotificationHistory _db;
  $SqliteNotificationHistoryManager(this._db);
  $$HistoryRecordsTableTableManager get historyRecords =>
      $$HistoryRecordsTableTableManager(_db, _db.historyRecords);
}
