// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'instance_presence.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const InstancePresenceStateEnum _$instancePresenceStateEnum_controllable =
    const InstancePresenceStateEnum._('controllable');
const InstancePresenceStateEnum _$instancePresenceStateEnum_conflicting =
    const InstancePresenceStateEnum._('conflicting');
const InstancePresenceStateEnum _$instancePresenceStateEnum_incompatible =
    const InstancePresenceStateEnum._('incompatible');
const InstancePresenceStateEnum _$instancePresenceStateEnum_offline =
    const InstancePresenceStateEnum._('offline');

InstancePresenceStateEnum _$instancePresenceStateEnumValueOf(String name) {
  switch (name) {
    case 'controllable':
      return _$instancePresenceStateEnum_controllable;
    case 'conflicting':
      return _$instancePresenceStateEnum_conflicting;
    case 'incompatible':
      return _$instancePresenceStateEnum_incompatible;
    case 'offline':
      return _$instancePresenceStateEnum_offline;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<InstancePresenceStateEnum> _$instancePresenceStateEnumValues =
    BuiltSet<InstancePresenceStateEnum>(const <InstancePresenceStateEnum>[
      _$instancePresenceStateEnum_controllable,
      _$instancePresenceStateEnum_conflicting,
      _$instancePresenceStateEnum_incompatible,
      _$instancePresenceStateEnum_offline,
    ]);

Serializer<InstancePresenceStateEnum> _$instancePresenceStateEnumSerializer =
    _$InstancePresenceStateEnumSerializer();

class _$InstancePresenceStateEnumSerializer
    implements PrimitiveSerializer<InstancePresenceStateEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'controllable': 'controllable',
    'conflicting': 'conflicting',
    'incompatible': 'incompatible',
    'offline': 'offline',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'controllable': 'controllable',
    'conflicting': 'conflicting',
    'incompatible': 'incompatible',
    'offline': 'offline',
  };

  @override
  final Iterable<Type> types = const <Type>[InstancePresenceStateEnum];
  @override
  final String wireName = 'InstancePresenceStateEnum';

  @override
  Object serialize(
    Serializers serializers,
    InstancePresenceStateEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  InstancePresenceStateEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => InstancePresenceStateEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$InstancePresence extends InstancePresence {
  @override
  final String directory;
  @override
  final String instanceId;
  @override
  final DateTime lastSeenAt;
  @override
  final String machine;
  @override
  final String openCodeVersion;
  @override
  final String project;
  @override
  final int protocolVersion;
  @override
  final InstancePresenceStateEnum state;

  factory _$InstancePresence([
    void Function(InstancePresenceBuilder)? updates,
  ]) => (InstancePresenceBuilder()..update(updates))._build();

  _$InstancePresence._({
    required this.directory,
    required this.instanceId,
    required this.lastSeenAt,
    required this.machine,
    required this.openCodeVersion,
    required this.project,
    required this.protocolVersion,
    required this.state,
  }) : super._();
  @override
  InstancePresence rebuild(void Function(InstancePresenceBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  InstancePresenceBuilder toBuilder() =>
      InstancePresenceBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is InstancePresence &&
        directory == other.directory &&
        instanceId == other.instanceId &&
        lastSeenAt == other.lastSeenAt &&
        machine == other.machine &&
        openCodeVersion == other.openCodeVersion &&
        project == other.project &&
        protocolVersion == other.protocolVersion &&
        state == other.state;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, directory.hashCode);
    _$hash = $jc(_$hash, instanceId.hashCode);
    _$hash = $jc(_$hash, lastSeenAt.hashCode);
    _$hash = $jc(_$hash, machine.hashCode);
    _$hash = $jc(_$hash, openCodeVersion.hashCode);
    _$hash = $jc(_$hash, project.hashCode);
    _$hash = $jc(_$hash, protocolVersion.hashCode);
    _$hash = $jc(_$hash, state.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'InstancePresence')
          ..add('directory', directory)
          ..add('instanceId', instanceId)
          ..add('lastSeenAt', lastSeenAt)
          ..add('machine', machine)
          ..add('openCodeVersion', openCodeVersion)
          ..add('project', project)
          ..add('protocolVersion', protocolVersion)
          ..add('state', state))
        .toString();
  }
}

class InstancePresenceBuilder
    implements Builder<InstancePresence, InstancePresenceBuilder> {
  _$InstancePresence? _$v;

  String? _directory;
  String? get directory => _$this._directory;
  set directory(String? directory) => _$this._directory = directory;

  String? _instanceId;
  String? get instanceId => _$this._instanceId;
  set instanceId(String? instanceId) => _$this._instanceId = instanceId;

  DateTime? _lastSeenAt;
  DateTime? get lastSeenAt => _$this._lastSeenAt;
  set lastSeenAt(DateTime? lastSeenAt) => _$this._lastSeenAt = lastSeenAt;

  String? _machine;
  String? get machine => _$this._machine;
  set machine(String? machine) => _$this._machine = machine;

  String? _openCodeVersion;
  String? get openCodeVersion => _$this._openCodeVersion;
  set openCodeVersion(String? openCodeVersion) =>
      _$this._openCodeVersion = openCodeVersion;

  String? _project;
  String? get project => _$this._project;
  set project(String? project) => _$this._project = project;

  int? _protocolVersion;
  int? get protocolVersion => _$this._protocolVersion;
  set protocolVersion(int? protocolVersion) =>
      _$this._protocolVersion = protocolVersion;

  InstancePresenceStateEnum? _state;
  InstancePresenceStateEnum? get state => _$this._state;
  set state(InstancePresenceStateEnum? state) => _$this._state = state;

  InstancePresenceBuilder() {
    InstancePresence._defaults(this);
  }

  InstancePresenceBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _directory = $v.directory;
      _instanceId = $v.instanceId;
      _lastSeenAt = $v.lastSeenAt;
      _machine = $v.machine;
      _openCodeVersion = $v.openCodeVersion;
      _project = $v.project;
      _protocolVersion = $v.protocolVersion;
      _state = $v.state;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(InstancePresence other) {
    _$v = other as _$InstancePresence;
  }

  @override
  void update(void Function(InstancePresenceBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  InstancePresence build() => _build();

  _$InstancePresence _build() {
    final _$result =
        _$v ??
        _$InstancePresence._(
          directory: BuiltValueNullFieldError.checkNotNull(
            directory,
            r'InstancePresence',
            'directory',
          ),
          instanceId: BuiltValueNullFieldError.checkNotNull(
            instanceId,
            r'InstancePresence',
            'instanceId',
          ),
          lastSeenAt: BuiltValueNullFieldError.checkNotNull(
            lastSeenAt,
            r'InstancePresence',
            'lastSeenAt',
          ),
          machine: BuiltValueNullFieldError.checkNotNull(
            machine,
            r'InstancePresence',
            'machine',
          ),
          openCodeVersion: BuiltValueNullFieldError.checkNotNull(
            openCodeVersion,
            r'InstancePresence',
            'openCodeVersion',
          ),
          project: BuiltValueNullFieldError.checkNotNull(
            project,
            r'InstancePresence',
            'project',
          ),
          protocolVersion: BuiltValueNullFieldError.checkNotNull(
            protocolVersion,
            r'InstancePresence',
            'protocolVersion',
          ),
          state: BuiltValueNullFieldError.checkNotNull(
            state,
            r'InstancePresence',
            'state',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
