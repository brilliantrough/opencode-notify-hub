// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_control_client_message_one_of4.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const PluginControlClientMessageOneOf4StatusEnum
_$pluginControlClientMessageOneOf4StatusEnum_confirmed =
    const PluginControlClientMessageOneOf4StatusEnum._('confirmed');
const PluginControlClientMessageOneOf4StatusEnum
_$pluginControlClientMessageOneOf4StatusEnum_upstreamError =
    const PluginControlClientMessageOneOf4StatusEnum._('upstreamError');
const PluginControlClientMessageOneOf4StatusEnum
_$pluginControlClientMessageOneOf4StatusEnum_resultUnknown =
    const PluginControlClientMessageOneOf4StatusEnum._('resultUnknown');

PluginControlClientMessageOneOf4StatusEnum
_$pluginControlClientMessageOneOf4StatusEnumValueOf(String name) {
  switch (name) {
    case 'confirmed':
      return _$pluginControlClientMessageOneOf4StatusEnum_confirmed;
    case 'upstreamError':
      return _$pluginControlClientMessageOneOf4StatusEnum_upstreamError;
    case 'resultUnknown':
      return _$pluginControlClientMessageOneOf4StatusEnum_resultUnknown;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PluginControlClientMessageOneOf4StatusEnum>
_$pluginControlClientMessageOneOf4StatusEnumValues =
    BuiltSet<PluginControlClientMessageOneOf4StatusEnum>(
      const <PluginControlClientMessageOneOf4StatusEnum>[
        _$pluginControlClientMessageOneOf4StatusEnum_confirmed,
        _$pluginControlClientMessageOneOf4StatusEnum_upstreamError,
        _$pluginControlClientMessageOneOf4StatusEnum_resultUnknown,
      ],
    );

const PluginControlClientMessageOneOf4TypeEnum
_$pluginControlClientMessageOneOf4TypeEnum_sessionPromptResult =
    const PluginControlClientMessageOneOf4TypeEnum._('sessionPromptResult');

PluginControlClientMessageOneOf4TypeEnum
_$pluginControlClientMessageOneOf4TypeEnumValueOf(String name) {
  switch (name) {
    case 'sessionPromptResult':
      return _$pluginControlClientMessageOneOf4TypeEnum_sessionPromptResult;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PluginControlClientMessageOneOf4TypeEnum>
_$pluginControlClientMessageOneOf4TypeEnumValues =
    BuiltSet<PluginControlClientMessageOneOf4TypeEnum>(
      const <PluginControlClientMessageOneOf4TypeEnum>[
        _$pluginControlClientMessageOneOf4TypeEnum_sessionPromptResult,
      ],
    );

Serializer<PluginControlClientMessageOneOf4StatusEnum>
_$pluginControlClientMessageOneOf4StatusEnumSerializer =
    _$PluginControlClientMessageOneOf4StatusEnumSerializer();
Serializer<PluginControlClientMessageOneOf4TypeEnum>
_$pluginControlClientMessageOneOf4TypeEnumSerializer =
    _$PluginControlClientMessageOneOf4TypeEnumSerializer();

class _$PluginControlClientMessageOneOf4StatusEnumSerializer
    implements PrimitiveSerializer<PluginControlClientMessageOneOf4StatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'confirmed': 'confirmed',
    'upstreamError': 'upstream_error',
    'resultUnknown': 'result_unknown',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'confirmed': 'confirmed',
    'upstream_error': 'upstreamError',
    'result_unknown': 'resultUnknown',
  };

  @override
  final Iterable<Type> types = const <Type>[
    PluginControlClientMessageOneOf4StatusEnum,
  ];
  @override
  final String wireName = 'PluginControlClientMessageOneOf4StatusEnum';

  @override
  Object serialize(
    Serializers serializers,
    PluginControlClientMessageOneOf4StatusEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  PluginControlClientMessageOneOf4StatusEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => PluginControlClientMessageOneOf4StatusEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$PluginControlClientMessageOneOf4TypeEnumSerializer
    implements PrimitiveSerializer<PluginControlClientMessageOneOf4TypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'sessionPromptResult': 'session_prompt_result',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'session_prompt_result': 'sessionPromptResult',
  };

  @override
  final Iterable<Type> types = const <Type>[
    PluginControlClientMessageOneOf4TypeEnum,
  ];
  @override
  final String wireName = 'PluginControlClientMessageOneOf4TypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    PluginControlClientMessageOneOf4TypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  PluginControlClientMessageOneOf4TypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => PluginControlClientMessageOneOf4TypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$PluginControlClientMessageOneOf4
    extends PluginControlClientMessageOneOf4 {
  @override
  final String commandId;
  @override
  final String instanceId;
  @override
  final PluginControlClientMessageOneOf4StatusEnum status;
  @override
  final PluginControlClientMessageOneOf4TypeEnum type;

  factory _$PluginControlClientMessageOneOf4([
    void Function(PluginControlClientMessageOneOf4Builder)? updates,
  ]) => (PluginControlClientMessageOneOf4Builder()..update(updates))._build();

  _$PluginControlClientMessageOneOf4._({
    required this.commandId,
    required this.instanceId,
    required this.status,
    required this.type,
  }) : super._();
  @override
  PluginControlClientMessageOneOf4 rebuild(
    void Function(PluginControlClientMessageOneOf4Builder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PluginControlClientMessageOneOf4Builder toBuilder() =>
      PluginControlClientMessageOneOf4Builder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PluginControlClientMessageOneOf4 &&
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
    return (newBuiltValueToStringHelper(r'PluginControlClientMessageOneOf4')
          ..add('commandId', commandId)
          ..add('instanceId', instanceId)
          ..add('status', status)
          ..add('type', type))
        .toString();
  }
}

class PluginControlClientMessageOneOf4Builder
    implements
        Builder<
          PluginControlClientMessageOneOf4,
          PluginControlClientMessageOneOf4Builder
        > {
  _$PluginControlClientMessageOneOf4? _$v;

  String? _commandId;
  String? get commandId => _$this._commandId;
  set commandId(String? commandId) => _$this._commandId = commandId;

  String? _instanceId;
  String? get instanceId => _$this._instanceId;
  set instanceId(String? instanceId) => _$this._instanceId = instanceId;

  PluginControlClientMessageOneOf4StatusEnum? _status;
  PluginControlClientMessageOneOf4StatusEnum? get status => _$this._status;
  set status(PluginControlClientMessageOneOf4StatusEnum? status) =>
      _$this._status = status;

  PluginControlClientMessageOneOf4TypeEnum? _type;
  PluginControlClientMessageOneOf4TypeEnum? get type => _$this._type;
  set type(PluginControlClientMessageOneOf4TypeEnum? type) =>
      _$this._type = type;

  PluginControlClientMessageOneOf4Builder() {
    PluginControlClientMessageOneOf4._defaults(this);
  }

  PluginControlClientMessageOneOf4Builder get _$this {
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
  void replace(PluginControlClientMessageOneOf4 other) {
    _$v = other as _$PluginControlClientMessageOneOf4;
  }

  @override
  void update(void Function(PluginControlClientMessageOneOf4Builder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PluginControlClientMessageOneOf4 build() => _build();

  _$PluginControlClientMessageOneOf4 _build() {
    final _$result =
        _$v ??
        _$PluginControlClientMessageOneOf4._(
          commandId: BuiltValueNullFieldError.checkNotNull(
            commandId,
            r'PluginControlClientMessageOneOf4',
            'commandId',
          ),
          instanceId: BuiltValueNullFieldError.checkNotNull(
            instanceId,
            r'PluginControlClientMessageOneOf4',
            'instanceId',
          ),
          status: BuiltValueNullFieldError.checkNotNull(
            status,
            r'PluginControlClientMessageOneOf4',
            'status',
          ),
          type: BuiltValueNullFieldError.checkNotNull(
            type,
            r'PluginControlClientMessageOneOf4',
            'type',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
