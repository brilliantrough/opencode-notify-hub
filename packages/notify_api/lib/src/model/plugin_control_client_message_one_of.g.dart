// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_control_client_message_one_of.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const PluginControlClientMessageOneOfTypeEnum
_$pluginControlClientMessageOneOfTypeEnum_register =
    const PluginControlClientMessageOneOfTypeEnum._('register');

PluginControlClientMessageOneOfTypeEnum
_$pluginControlClientMessageOneOfTypeEnumValueOf(String name) {
  switch (name) {
    case 'register':
      return _$pluginControlClientMessageOneOfTypeEnum_register;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PluginControlClientMessageOneOfTypeEnum>
_$pluginControlClientMessageOneOfTypeEnumValues =
    BuiltSet<PluginControlClientMessageOneOfTypeEnum>(
      const <PluginControlClientMessageOneOfTypeEnum>[
        _$pluginControlClientMessageOneOfTypeEnum_register,
      ],
    );

Serializer<PluginControlClientMessageOneOfTypeEnum>
_$pluginControlClientMessageOneOfTypeEnumSerializer =
    _$PluginControlClientMessageOneOfTypeEnumSerializer();

class _$PluginControlClientMessageOneOfTypeEnumSerializer
    implements PrimitiveSerializer<PluginControlClientMessageOneOfTypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'register': 'register',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'register': 'register',
  };

  @override
  final Iterable<Type> types = const <Type>[
    PluginControlClientMessageOneOfTypeEnum,
  ];
  @override
  final String wireName = 'PluginControlClientMessageOneOfTypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    PluginControlClientMessageOneOfTypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  PluginControlClientMessageOneOfTypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => PluginControlClientMessageOneOfTypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$PluginControlClientMessageOneOf
    extends PluginControlClientMessageOneOf {
  @override
  final String directory;
  @override
  final String instanceId;
  @override
  final String machine;
  @override
  final String openCodeVersion;
  @override
  final String project;
  @override
  final int protocolVersion;
  @override
  final PluginControlClientMessageOneOfTypeEnum type;

  factory _$PluginControlClientMessageOneOf([
    void Function(PluginControlClientMessageOneOfBuilder)? updates,
  ]) => (PluginControlClientMessageOneOfBuilder()..update(updates))._build();

  _$PluginControlClientMessageOneOf._({
    required this.directory,
    required this.instanceId,
    required this.machine,
    required this.openCodeVersion,
    required this.project,
    required this.protocolVersion,
    required this.type,
  }) : super._();
  @override
  PluginControlClientMessageOneOf rebuild(
    void Function(PluginControlClientMessageOneOfBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PluginControlClientMessageOneOfBuilder toBuilder() =>
      PluginControlClientMessageOneOfBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PluginControlClientMessageOneOf &&
        directory == other.directory &&
        instanceId == other.instanceId &&
        machine == other.machine &&
        openCodeVersion == other.openCodeVersion &&
        project == other.project &&
        protocolVersion == other.protocolVersion &&
        type == other.type;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, directory.hashCode);
    _$hash = $jc(_$hash, instanceId.hashCode);
    _$hash = $jc(_$hash, machine.hashCode);
    _$hash = $jc(_$hash, openCodeVersion.hashCode);
    _$hash = $jc(_$hash, project.hashCode);
    _$hash = $jc(_$hash, protocolVersion.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PluginControlClientMessageOneOf')
          ..add('directory', directory)
          ..add('instanceId', instanceId)
          ..add('machine', machine)
          ..add('openCodeVersion', openCodeVersion)
          ..add('project', project)
          ..add('protocolVersion', protocolVersion)
          ..add('type', type))
        .toString();
  }
}

class PluginControlClientMessageOneOfBuilder
    implements
        Builder<
          PluginControlClientMessageOneOf,
          PluginControlClientMessageOneOfBuilder
        > {
  _$PluginControlClientMessageOneOf? _$v;

  String? _directory;
  String? get directory => _$this._directory;
  set directory(String? directory) => _$this._directory = directory;

  String? _instanceId;
  String? get instanceId => _$this._instanceId;
  set instanceId(String? instanceId) => _$this._instanceId = instanceId;

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

  PluginControlClientMessageOneOfTypeEnum? _type;
  PluginControlClientMessageOneOfTypeEnum? get type => _$this._type;
  set type(PluginControlClientMessageOneOfTypeEnum? type) =>
      _$this._type = type;

  PluginControlClientMessageOneOfBuilder() {
    PluginControlClientMessageOneOf._defaults(this);
  }

  PluginControlClientMessageOneOfBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _directory = $v.directory;
      _instanceId = $v.instanceId;
      _machine = $v.machine;
      _openCodeVersion = $v.openCodeVersion;
      _project = $v.project;
      _protocolVersion = $v.protocolVersion;
      _type = $v.type;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PluginControlClientMessageOneOf other) {
    _$v = other as _$PluginControlClientMessageOneOf;
  }

  @override
  void update(void Function(PluginControlClientMessageOneOfBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PluginControlClientMessageOneOf build() => _build();

  _$PluginControlClientMessageOneOf _build() {
    final _$result =
        _$v ??
        _$PluginControlClientMessageOneOf._(
          directory: BuiltValueNullFieldError.checkNotNull(
            directory,
            r'PluginControlClientMessageOneOf',
            'directory',
          ),
          instanceId: BuiltValueNullFieldError.checkNotNull(
            instanceId,
            r'PluginControlClientMessageOneOf',
            'instanceId',
          ),
          machine: BuiltValueNullFieldError.checkNotNull(
            machine,
            r'PluginControlClientMessageOneOf',
            'machine',
          ),
          openCodeVersion: BuiltValueNullFieldError.checkNotNull(
            openCodeVersion,
            r'PluginControlClientMessageOneOf',
            'openCodeVersion',
          ),
          project: BuiltValueNullFieldError.checkNotNull(
            project,
            r'PluginControlClientMessageOneOf',
            'project',
          ),
          protocolVersion: BuiltValueNullFieldError.checkNotNull(
            protocolVersion,
            r'PluginControlClientMessageOneOf',
            'protocolVersion',
          ),
          type: BuiltValueNullFieldError.checkNotNull(
            type,
            r'PluginControlClientMessageOneOf',
            'type',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
