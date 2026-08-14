// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ws_server_message_one_of1_instances_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const WsServerMessageOneOf1InstancesInnerStateEnum
_$wsServerMessageOneOf1InstancesInnerStateEnum_controllable =
    const WsServerMessageOneOf1InstancesInnerStateEnum._('controllable');
const WsServerMessageOneOf1InstancesInnerStateEnum
_$wsServerMessageOneOf1InstancesInnerStateEnum_conflicting =
    const WsServerMessageOneOf1InstancesInnerStateEnum._('conflicting');
const WsServerMessageOneOf1InstancesInnerStateEnum
_$wsServerMessageOneOf1InstancesInnerStateEnum_incompatible =
    const WsServerMessageOneOf1InstancesInnerStateEnum._('incompatible');
const WsServerMessageOneOf1InstancesInnerStateEnum
_$wsServerMessageOneOf1InstancesInnerStateEnum_offline =
    const WsServerMessageOneOf1InstancesInnerStateEnum._('offline');

WsServerMessageOneOf1InstancesInnerStateEnum
_$wsServerMessageOneOf1InstancesInnerStateEnumValueOf(String name) {
  switch (name) {
    case 'controllable':
      return _$wsServerMessageOneOf1InstancesInnerStateEnum_controllable;
    case 'conflicting':
      return _$wsServerMessageOneOf1InstancesInnerStateEnum_conflicting;
    case 'incompatible':
      return _$wsServerMessageOneOf1InstancesInnerStateEnum_incompatible;
    case 'offline':
      return _$wsServerMessageOneOf1InstancesInnerStateEnum_offline;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<WsServerMessageOneOf1InstancesInnerStateEnum>
_$wsServerMessageOneOf1InstancesInnerStateEnumValues =
    BuiltSet<WsServerMessageOneOf1InstancesInnerStateEnum>(
      const <WsServerMessageOneOf1InstancesInnerStateEnum>[
        _$wsServerMessageOneOf1InstancesInnerStateEnum_controllable,
        _$wsServerMessageOneOf1InstancesInnerStateEnum_conflicting,
        _$wsServerMessageOneOf1InstancesInnerStateEnum_incompatible,
        _$wsServerMessageOneOf1InstancesInnerStateEnum_offline,
      ],
    );

Serializer<WsServerMessageOneOf1InstancesInnerStateEnum>
_$wsServerMessageOneOf1InstancesInnerStateEnumSerializer =
    _$WsServerMessageOneOf1InstancesInnerStateEnumSerializer();

class _$WsServerMessageOneOf1InstancesInnerStateEnumSerializer
    implements
        PrimitiveSerializer<WsServerMessageOneOf1InstancesInnerStateEnum> {
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
  final Iterable<Type> types = const <Type>[
    WsServerMessageOneOf1InstancesInnerStateEnum,
  ];
  @override
  final String wireName = 'WsServerMessageOneOf1InstancesInnerStateEnum';

  @override
  Object serialize(
    Serializers serializers,
    WsServerMessageOneOf1InstancesInnerStateEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  WsServerMessageOneOf1InstancesInnerStateEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => WsServerMessageOneOf1InstancesInnerStateEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$WsServerMessageOneOf1InstancesInner
    extends WsServerMessageOneOf1InstancesInner {
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
  final WsServerMessageOneOf1InstancesInnerStateEnum state;

  factory _$WsServerMessageOneOf1InstancesInner([
    void Function(WsServerMessageOneOf1InstancesInnerBuilder)? updates,
  ]) =>
      (WsServerMessageOneOf1InstancesInnerBuilder()..update(updates))._build();

  _$WsServerMessageOneOf1InstancesInner._({
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
  WsServerMessageOneOf1InstancesInner rebuild(
    void Function(WsServerMessageOneOf1InstancesInnerBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  WsServerMessageOneOf1InstancesInnerBuilder toBuilder() =>
      WsServerMessageOneOf1InstancesInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is WsServerMessageOneOf1InstancesInner &&
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
    return (newBuiltValueToStringHelper(r'WsServerMessageOneOf1InstancesInner')
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

class WsServerMessageOneOf1InstancesInnerBuilder
    implements
        Builder<
          WsServerMessageOneOf1InstancesInner,
          WsServerMessageOneOf1InstancesInnerBuilder
        > {
  _$WsServerMessageOneOf1InstancesInner? _$v;

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

  WsServerMessageOneOf1InstancesInnerStateEnum? _state;
  WsServerMessageOneOf1InstancesInnerStateEnum? get state => _$this._state;
  set state(WsServerMessageOneOf1InstancesInnerStateEnum? state) =>
      _$this._state = state;

  WsServerMessageOneOf1InstancesInnerBuilder() {
    WsServerMessageOneOf1InstancesInner._defaults(this);
  }

  WsServerMessageOneOf1InstancesInnerBuilder get _$this {
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
  void replace(WsServerMessageOneOf1InstancesInner other) {
    _$v = other as _$WsServerMessageOneOf1InstancesInner;
  }

  @override
  void update(
    void Function(WsServerMessageOneOf1InstancesInnerBuilder)? updates,
  ) {
    if (updates != null) updates(this);
  }

  @override
  WsServerMessageOneOf1InstancesInner build() => _build();

  _$WsServerMessageOneOf1InstancesInner _build() {
    final _$result =
        _$v ??
        _$WsServerMessageOneOf1InstancesInner._(
          directory: BuiltValueNullFieldError.checkNotNull(
            directory,
            r'WsServerMessageOneOf1InstancesInner',
            'directory',
          ),
          instanceId: BuiltValueNullFieldError.checkNotNull(
            instanceId,
            r'WsServerMessageOneOf1InstancesInner',
            'instanceId',
          ),
          lastSeenAt: BuiltValueNullFieldError.checkNotNull(
            lastSeenAt,
            r'WsServerMessageOneOf1InstancesInner',
            'lastSeenAt',
          ),
          machine: BuiltValueNullFieldError.checkNotNull(
            machine,
            r'WsServerMessageOneOf1InstancesInner',
            'machine',
          ),
          openCodeVersion: BuiltValueNullFieldError.checkNotNull(
            openCodeVersion,
            r'WsServerMessageOneOf1InstancesInner',
            'openCodeVersion',
          ),
          project: BuiltValueNullFieldError.checkNotNull(
            project,
            r'WsServerMessageOneOf1InstancesInner',
            'project',
          ),
          protocolVersion: BuiltValueNullFieldError.checkNotNull(
            protocolVersion,
            r'WsServerMessageOneOf1InstancesInner',
            'protocolVersion',
          ),
          state: BuiltValueNullFieldError.checkNotNull(
            state,
            r'WsServerMessageOneOf1InstancesInner',
            'state',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
