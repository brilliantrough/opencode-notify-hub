// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_control_client_message.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const PluginControlClientMessageTypeEnum
_$pluginControlClientMessageTypeEnum_register =
    const PluginControlClientMessageTypeEnum._('register');

PluginControlClientMessageTypeEnum _$pluginControlClientMessageTypeEnumValueOf(
  String name,
) {
  switch (name) {
    case 'register':
      return _$pluginControlClientMessageTypeEnum_register;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PluginControlClientMessageTypeEnum>
_$pluginControlClientMessageTypeEnumValues =
    BuiltSet<PluginControlClientMessageTypeEnum>(
      const <PluginControlClientMessageTypeEnum>[
        _$pluginControlClientMessageTypeEnum_register,
      ],
    );

Serializer<PluginControlClientMessageTypeEnum>
_$pluginControlClientMessageTypeEnumSerializer =
    _$PluginControlClientMessageTypeEnumSerializer();

class _$PluginControlClientMessageTypeEnumSerializer
    implements PrimitiveSerializer<PluginControlClientMessageTypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'register': 'register',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'register': 'register',
  };

  @override
  final Iterable<Type> types = const <Type>[PluginControlClientMessageTypeEnum];
  @override
  final String wireName = 'PluginControlClientMessageTypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    PluginControlClientMessageTypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  PluginControlClientMessageTypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => PluginControlClientMessageTypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$PluginControlClientMessage extends PluginControlClientMessage {
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
  final PluginControlClientMessageTypeEnum type;

  factory _$PluginControlClientMessage([
    void Function(PluginControlClientMessageBuilder)? updates,
  ]) => (PluginControlClientMessageBuilder()..update(updates))._build();

  _$PluginControlClientMessage._({
    required this.directory,
    required this.instanceId,
    required this.machine,
    required this.openCodeVersion,
    required this.project,
    required this.protocolVersion,
    required this.type,
  }) : super._();
  @override
  PluginControlClientMessage rebuild(
    void Function(PluginControlClientMessageBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PluginControlClientMessageBuilder toBuilder() =>
      PluginControlClientMessageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PluginControlClientMessage &&
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
    return (newBuiltValueToStringHelper(r'PluginControlClientMessage')
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

class PluginControlClientMessageBuilder
    implements
        Builder<PluginControlClientMessage, PluginControlClientMessageBuilder> {
  _$PluginControlClientMessage? _$v;

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

  PluginControlClientMessageTypeEnum? _type;
  PluginControlClientMessageTypeEnum? get type => _$this._type;
  set type(PluginControlClientMessageTypeEnum? type) => _$this._type = type;

  PluginControlClientMessageBuilder() {
    PluginControlClientMessage._defaults(this);
  }

  PluginControlClientMessageBuilder get _$this {
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
  void replace(PluginControlClientMessage other) {
    _$v = other as _$PluginControlClientMessage;
  }

  @override
  void update(void Function(PluginControlClientMessageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PluginControlClientMessage build() => _build();

  _$PluginControlClientMessage _build() {
    final _$result =
        _$v ??
        _$PluginControlClientMessage._(
          directory: BuiltValueNullFieldError.checkNotNull(
            directory,
            r'PluginControlClientMessage',
            'directory',
          ),
          instanceId: BuiltValueNullFieldError.checkNotNull(
            instanceId,
            r'PluginControlClientMessage',
            'instanceId',
          ),
          machine: BuiltValueNullFieldError.checkNotNull(
            machine,
            r'PluginControlClientMessage',
            'machine',
          ),
          openCodeVersion: BuiltValueNullFieldError.checkNotNull(
            openCodeVersion,
            r'PluginControlClientMessage',
            'openCodeVersion',
          ),
          project: BuiltValueNullFieldError.checkNotNull(
            project,
            r'PluginControlClientMessage',
            'project',
          ),
          protocolVersion: BuiltValueNullFieldError.checkNotNull(
            protocolVersion,
            r'PluginControlClientMessage',
            'protocolVersion',
          ),
          type: BuiltValueNullFieldError.checkNotNull(
            type,
            r'PluginControlClientMessage',
            'type',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
