// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_interaction_one_of1.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const PendingInteractionOneOf1KindEnum
_$pendingInteractionOneOf1KindEnum_permission =
    const PendingInteractionOneOf1KindEnum._('permission');

PendingInteractionOneOf1KindEnum _$pendingInteractionOneOf1KindEnumValueOf(
  String name,
) {
  switch (name) {
    case 'permission':
      return _$pendingInteractionOneOf1KindEnum_permission;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PendingInteractionOneOf1KindEnum>
_$pendingInteractionOneOf1KindEnumValues =
    BuiltSet<PendingInteractionOneOf1KindEnum>(
      const <PendingInteractionOneOf1KindEnum>[
        _$pendingInteractionOneOf1KindEnum_permission,
      ],
    );

Serializer<PendingInteractionOneOf1KindEnum>
_$pendingInteractionOneOf1KindEnumSerializer =
    _$PendingInteractionOneOf1KindEnumSerializer();

class _$PendingInteractionOneOf1KindEnumSerializer
    implements PrimitiveSerializer<PendingInteractionOneOf1KindEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'permission': 'permission',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'permission': 'permission',
  };

  @override
  final Iterable<Type> types = const <Type>[PendingInteractionOneOf1KindEnum];
  @override
  final String wireName = 'PendingInteractionOneOf1KindEnum';

  @override
  Object serialize(
    Serializers serializers,
    PendingInteractionOneOf1KindEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  PendingInteractionOneOf1KindEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => PendingInteractionOneOf1KindEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$PendingInteractionOneOf1 extends PendingInteractionOneOf1 {
  @override
  final BuiltList<String> always;
  @override
  final String directory;
  @override
  final String instanceId;
  @override
  final PendingInteractionOneOf1KindEnum kind;
  @override
  final String machine;
  @override
  final JsonObject metadata;
  @override
  final DateTime occurredAt;
  @override
  final BuiltList<String> patterns;
  @override
  final String permission;
  @override
  final String project;
  @override
  final String requestId;
  @override
  final String sessionId;
  @override
  final String sessionTitle;
  @override
  final PendingInteractionOneOfTool? tool;

  factory _$PendingInteractionOneOf1([
    void Function(PendingInteractionOneOf1Builder)? updates,
  ]) => (PendingInteractionOneOf1Builder()..update(updates))._build();

  _$PendingInteractionOneOf1._({
    required this.always,
    required this.directory,
    required this.instanceId,
    required this.kind,
    required this.machine,
    required this.metadata,
    required this.occurredAt,
    required this.patterns,
    required this.permission,
    required this.project,
    required this.requestId,
    required this.sessionId,
    required this.sessionTitle,
    this.tool,
  }) : super._();
  @override
  PendingInteractionOneOf1 rebuild(
    void Function(PendingInteractionOneOf1Builder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PendingInteractionOneOf1Builder toBuilder() =>
      PendingInteractionOneOf1Builder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PendingInteractionOneOf1 &&
        always == other.always &&
        directory == other.directory &&
        instanceId == other.instanceId &&
        kind == other.kind &&
        machine == other.machine &&
        metadata == other.metadata &&
        occurredAt == other.occurredAt &&
        patterns == other.patterns &&
        permission == other.permission &&
        project == other.project &&
        requestId == other.requestId &&
        sessionId == other.sessionId &&
        sessionTitle == other.sessionTitle &&
        tool == other.tool;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, always.hashCode);
    _$hash = $jc(_$hash, directory.hashCode);
    _$hash = $jc(_$hash, instanceId.hashCode);
    _$hash = $jc(_$hash, kind.hashCode);
    _$hash = $jc(_$hash, machine.hashCode);
    _$hash = $jc(_$hash, metadata.hashCode);
    _$hash = $jc(_$hash, occurredAt.hashCode);
    _$hash = $jc(_$hash, patterns.hashCode);
    _$hash = $jc(_$hash, permission.hashCode);
    _$hash = $jc(_$hash, project.hashCode);
    _$hash = $jc(_$hash, requestId.hashCode);
    _$hash = $jc(_$hash, sessionId.hashCode);
    _$hash = $jc(_$hash, sessionTitle.hashCode);
    _$hash = $jc(_$hash, tool.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PendingInteractionOneOf1')
          ..add('always', always)
          ..add('directory', directory)
          ..add('instanceId', instanceId)
          ..add('kind', kind)
          ..add('machine', machine)
          ..add('metadata', metadata)
          ..add('occurredAt', occurredAt)
          ..add('patterns', patterns)
          ..add('permission', permission)
          ..add('project', project)
          ..add('requestId', requestId)
          ..add('sessionId', sessionId)
          ..add('sessionTitle', sessionTitle)
          ..add('tool', tool))
        .toString();
  }
}

class PendingInteractionOneOf1Builder
    implements
        Builder<PendingInteractionOneOf1, PendingInteractionOneOf1Builder> {
  _$PendingInteractionOneOf1? _$v;

  ListBuilder<String>? _always;
  ListBuilder<String> get always => _$this._always ??= ListBuilder<String>();
  set always(ListBuilder<String>? always) => _$this._always = always;

  String? _directory;
  String? get directory => _$this._directory;
  set directory(String? directory) => _$this._directory = directory;

  String? _instanceId;
  String? get instanceId => _$this._instanceId;
  set instanceId(String? instanceId) => _$this._instanceId = instanceId;

  PendingInteractionOneOf1KindEnum? _kind;
  PendingInteractionOneOf1KindEnum? get kind => _$this._kind;
  set kind(PendingInteractionOneOf1KindEnum? kind) => _$this._kind = kind;

  String? _machine;
  String? get machine => _$this._machine;
  set machine(String? machine) => _$this._machine = machine;

  JsonObject? _metadata;
  JsonObject? get metadata => _$this._metadata;
  set metadata(JsonObject? metadata) => _$this._metadata = metadata;

  DateTime? _occurredAt;
  DateTime? get occurredAt => _$this._occurredAt;
  set occurredAt(DateTime? occurredAt) => _$this._occurredAt = occurredAt;

  ListBuilder<String>? _patterns;
  ListBuilder<String> get patterns =>
      _$this._patterns ??= ListBuilder<String>();
  set patterns(ListBuilder<String>? patterns) => _$this._patterns = patterns;

  String? _permission;
  String? get permission => _$this._permission;
  set permission(String? permission) => _$this._permission = permission;

  String? _project;
  String? get project => _$this._project;
  set project(String? project) => _$this._project = project;

  String? _requestId;
  String? get requestId => _$this._requestId;
  set requestId(String? requestId) => _$this._requestId = requestId;

  String? _sessionId;
  String? get sessionId => _$this._sessionId;
  set sessionId(String? sessionId) => _$this._sessionId = sessionId;

  String? _sessionTitle;
  String? get sessionTitle => _$this._sessionTitle;
  set sessionTitle(String? sessionTitle) => _$this._sessionTitle = sessionTitle;

  PendingInteractionOneOfToolBuilder? _tool;
  PendingInteractionOneOfToolBuilder get tool =>
      _$this._tool ??= PendingInteractionOneOfToolBuilder();
  set tool(PendingInteractionOneOfToolBuilder? tool) => _$this._tool = tool;

  PendingInteractionOneOf1Builder() {
    PendingInteractionOneOf1._defaults(this);
  }

  PendingInteractionOneOf1Builder get _$this {
    final $v = _$v;
    if ($v != null) {
      _always = $v.always.toBuilder();
      _directory = $v.directory;
      _instanceId = $v.instanceId;
      _kind = $v.kind;
      _machine = $v.machine;
      _metadata = $v.metadata;
      _occurredAt = $v.occurredAt;
      _patterns = $v.patterns.toBuilder();
      _permission = $v.permission;
      _project = $v.project;
      _requestId = $v.requestId;
      _sessionId = $v.sessionId;
      _sessionTitle = $v.sessionTitle;
      _tool = $v.tool?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PendingInteractionOneOf1 other) {
    _$v = other as _$PendingInteractionOneOf1;
  }

  @override
  void update(void Function(PendingInteractionOneOf1Builder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PendingInteractionOneOf1 build() => _build();

  _$PendingInteractionOneOf1 _build() {
    _$PendingInteractionOneOf1 _$result;
    try {
      _$result =
          _$v ??
          _$PendingInteractionOneOf1._(
            always: always.build(),
            directory: BuiltValueNullFieldError.checkNotNull(
              directory,
              r'PendingInteractionOneOf1',
              'directory',
            ),
            instanceId: BuiltValueNullFieldError.checkNotNull(
              instanceId,
              r'PendingInteractionOneOf1',
              'instanceId',
            ),
            kind: BuiltValueNullFieldError.checkNotNull(
              kind,
              r'PendingInteractionOneOf1',
              'kind',
            ),
            machine: BuiltValueNullFieldError.checkNotNull(
              machine,
              r'PendingInteractionOneOf1',
              'machine',
            ),
            metadata: BuiltValueNullFieldError.checkNotNull(
              metadata,
              r'PendingInteractionOneOf1',
              'metadata',
            ),
            occurredAt: BuiltValueNullFieldError.checkNotNull(
              occurredAt,
              r'PendingInteractionOneOf1',
              'occurredAt',
            ),
            patterns: patterns.build(),
            permission: BuiltValueNullFieldError.checkNotNull(
              permission,
              r'PendingInteractionOneOf1',
              'permission',
            ),
            project: BuiltValueNullFieldError.checkNotNull(
              project,
              r'PendingInteractionOneOf1',
              'project',
            ),
            requestId: BuiltValueNullFieldError.checkNotNull(
              requestId,
              r'PendingInteractionOneOf1',
              'requestId',
            ),
            sessionId: BuiltValueNullFieldError.checkNotNull(
              sessionId,
              r'PendingInteractionOneOf1',
              'sessionId',
            ),
            sessionTitle: BuiltValueNullFieldError.checkNotNull(
              sessionTitle,
              r'PendingInteractionOneOf1',
              'sessionTitle',
            ),
            tool: _tool?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'always';
        always.build();

        _$failedField = 'patterns';
        patterns.build();

        _$failedField = 'tool';
        _tool?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'PendingInteractionOneOf1',
          _$failedField,
          e.toString(),
        );
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
