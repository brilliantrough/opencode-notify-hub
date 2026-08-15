// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_control_client_message_one_of3.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const PluginControlClientMessageOneOf3StatusEnum
_$pluginControlClientMessageOneOf3StatusEnum_confirmed =
    const PluginControlClientMessageOneOf3StatusEnum._('confirmed');
const PluginControlClientMessageOneOf3StatusEnum
_$pluginControlClientMessageOneOf3StatusEnum_stale =
    const PluginControlClientMessageOneOf3StatusEnum._('stale');
const PluginControlClientMessageOneOf3StatusEnum
_$pluginControlClientMessageOneOf3StatusEnum_upstreamError =
    const PluginControlClientMessageOneOf3StatusEnum._('upstreamError');
const PluginControlClientMessageOneOf3StatusEnum
_$pluginControlClientMessageOneOf3StatusEnum_resultUnknown =
    const PluginControlClientMessageOneOf3StatusEnum._('resultUnknown');

PluginControlClientMessageOneOf3StatusEnum
_$pluginControlClientMessageOneOf3StatusEnumValueOf(String name) {
  switch (name) {
    case 'confirmed':
      return _$pluginControlClientMessageOneOf3StatusEnum_confirmed;
    case 'stale':
      return _$pluginControlClientMessageOneOf3StatusEnum_stale;
    case 'upstreamError':
      return _$pluginControlClientMessageOneOf3StatusEnum_upstreamError;
    case 'resultUnknown':
      return _$pluginControlClientMessageOneOf3StatusEnum_resultUnknown;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PluginControlClientMessageOneOf3StatusEnum>
_$pluginControlClientMessageOneOf3StatusEnumValues =
    BuiltSet<PluginControlClientMessageOneOf3StatusEnum>(
      const <PluginControlClientMessageOneOf3StatusEnum>[
        _$pluginControlClientMessageOneOf3StatusEnum_confirmed,
        _$pluginControlClientMessageOneOf3StatusEnum_stale,
        _$pluginControlClientMessageOneOf3StatusEnum_upstreamError,
        _$pluginControlClientMessageOneOf3StatusEnum_resultUnknown,
      ],
    );

const PluginControlClientMessageOneOf3TypeEnum
_$pluginControlClientMessageOneOf3TypeEnum_permissionDecideResult =
    const PluginControlClientMessageOneOf3TypeEnum._('permissionDecideResult');

PluginControlClientMessageOneOf3TypeEnum
_$pluginControlClientMessageOneOf3TypeEnumValueOf(String name) {
  switch (name) {
    case 'permissionDecideResult':
      return _$pluginControlClientMessageOneOf3TypeEnum_permissionDecideResult;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PluginControlClientMessageOneOf3TypeEnum>
_$pluginControlClientMessageOneOf3TypeEnumValues =
    BuiltSet<PluginControlClientMessageOneOf3TypeEnum>(
      const <PluginControlClientMessageOneOf3TypeEnum>[
        _$pluginControlClientMessageOneOf3TypeEnum_permissionDecideResult,
      ],
    );

Serializer<PluginControlClientMessageOneOf3StatusEnum>
_$pluginControlClientMessageOneOf3StatusEnumSerializer =
    _$PluginControlClientMessageOneOf3StatusEnumSerializer();
Serializer<PluginControlClientMessageOneOf3TypeEnum>
_$pluginControlClientMessageOneOf3TypeEnumSerializer =
    _$PluginControlClientMessageOneOf3TypeEnumSerializer();

class _$PluginControlClientMessageOneOf3StatusEnumSerializer
    implements PrimitiveSerializer<PluginControlClientMessageOneOf3StatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'confirmed': 'confirmed',
    'stale': 'stale',
    'upstreamError': 'upstream_error',
    'resultUnknown': 'result_unknown',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'confirmed': 'confirmed',
    'stale': 'stale',
    'upstream_error': 'upstreamError',
    'result_unknown': 'resultUnknown',
  };

  @override
  final Iterable<Type> types = const <Type>[
    PluginControlClientMessageOneOf3StatusEnum,
  ];
  @override
  final String wireName = 'PluginControlClientMessageOneOf3StatusEnum';

  @override
  Object serialize(
    Serializers serializers,
    PluginControlClientMessageOneOf3StatusEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  PluginControlClientMessageOneOf3StatusEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => PluginControlClientMessageOneOf3StatusEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$PluginControlClientMessageOneOf3TypeEnumSerializer
    implements PrimitiveSerializer<PluginControlClientMessageOneOf3TypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'permissionDecideResult': 'permission_decide_result',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'permission_decide_result': 'permissionDecideResult',
  };

  @override
  final Iterable<Type> types = const <Type>[
    PluginControlClientMessageOneOf3TypeEnum,
  ];
  @override
  final String wireName = 'PluginControlClientMessageOneOf3TypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    PluginControlClientMessageOneOf3TypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  PluginControlClientMessageOneOf3TypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => PluginControlClientMessageOneOf3TypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$PluginControlClientMessageOneOf3
    extends PluginControlClientMessageOneOf3 {
  @override
  final String commandId;
  @override
  final String instanceId;
  @override
  final PluginControlClientMessageOneOf3StatusEnum status;
  @override
  final PluginControlClientMessageOneOf3TypeEnum type;

  factory _$PluginControlClientMessageOneOf3([
    void Function(PluginControlClientMessageOneOf3Builder)? updates,
  ]) => (PluginControlClientMessageOneOf3Builder()..update(updates))._build();

  _$PluginControlClientMessageOneOf3._({
    required this.commandId,
    required this.instanceId,
    required this.status,
    required this.type,
  }) : super._();
  @override
  PluginControlClientMessageOneOf3 rebuild(
    void Function(PluginControlClientMessageOneOf3Builder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PluginControlClientMessageOneOf3Builder toBuilder() =>
      PluginControlClientMessageOneOf3Builder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PluginControlClientMessageOneOf3 &&
        commandId == other.commandId &&
        instanceId == other.instanceId &&
        status == other.status &&
        type == other.type;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, commandId.hashCode);
    _$hash = $jc(_$hash, instanceId.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PluginControlClientMessageOneOf3')
          ..add('commandId', commandId)
          ..add('instanceId', instanceId)
          ..add('status', status)
          ..add('type', type))
        .toString();
  }
}

class PluginControlClientMessageOneOf3Builder
    implements
        Builder<
          PluginControlClientMessageOneOf3,
          PluginControlClientMessageOneOf3Builder
        > {
  _$PluginControlClientMessageOneOf3? _$v;

  String? _commandId;
  String? get commandId => _$this._commandId;
  set commandId(String? commandId) => _$this._commandId = commandId;

  String? _instanceId;
  String? get instanceId => _$this._instanceId;
  set instanceId(String? instanceId) => _$this._instanceId = instanceId;

  PluginControlClientMessageOneOf3StatusEnum? _status;
  PluginControlClientMessageOneOf3StatusEnum? get status => _$this._status;
  set status(PluginControlClientMessageOneOf3StatusEnum? status) =>
      _$this._status = status;

  PluginControlClientMessageOneOf3TypeEnum? _type;
  PluginControlClientMessageOneOf3TypeEnum? get type => _$this._type;
  set type(PluginControlClientMessageOneOf3TypeEnum? type) =>
      _$this._type = type;

  PluginControlClientMessageOneOf3Builder() {
    PluginControlClientMessageOneOf3._defaults(this);
  }

  PluginControlClientMessageOneOf3Builder get _$this {
    final $v = _$v;
    if ($v != null) {
      _commandId = $v.commandId;
      _instanceId = $v.instanceId;
      _status = $v.status;
      _type = $v.type;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PluginControlClientMessageOneOf3 other) {
    _$v = other as _$PluginControlClientMessageOneOf3;
  }

  @override
  void update(void Function(PluginControlClientMessageOneOf3Builder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PluginControlClientMessageOneOf3 build() => _build();

  _$PluginControlClientMessageOneOf3 _build() {
    final _$result =
        _$v ??
        _$PluginControlClientMessageOneOf3._(
          commandId: BuiltValueNullFieldError.checkNotNull(
            commandId,
            r'PluginControlClientMessageOneOf3',
            'commandId',
          ),
          instanceId: BuiltValueNullFieldError.checkNotNull(
            instanceId,
            r'PluginControlClientMessageOneOf3',
            'instanceId',
          ),
          status: BuiltValueNullFieldError.checkNotNull(
            status,
            r'PluginControlClientMessageOneOf3',
            'status',
          ),
          type: BuiltValueNullFieldError.checkNotNull(
            type,
            r'PluginControlClientMessageOneOf3',
            'type',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
