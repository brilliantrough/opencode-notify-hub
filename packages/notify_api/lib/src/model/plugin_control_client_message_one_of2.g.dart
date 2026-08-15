// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_control_client_message_one_of2.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const PluginControlClientMessageOneOf2StatusEnum
_$pluginControlClientMessageOneOf2StatusEnum_confirmed =
    const PluginControlClientMessageOneOf2StatusEnum._('confirmed');
const PluginControlClientMessageOneOf2StatusEnum
_$pluginControlClientMessageOneOf2StatusEnum_stale =
    const PluginControlClientMessageOneOf2StatusEnum._('stale');
const PluginControlClientMessageOneOf2StatusEnum
_$pluginControlClientMessageOneOf2StatusEnum_upstreamError =
    const PluginControlClientMessageOneOf2StatusEnum._('upstreamError');
const PluginControlClientMessageOneOf2StatusEnum
_$pluginControlClientMessageOneOf2StatusEnum_resultUnknown =
    const PluginControlClientMessageOneOf2StatusEnum._('resultUnknown');

PluginControlClientMessageOneOf2StatusEnum
_$pluginControlClientMessageOneOf2StatusEnumValueOf(String name) {
  switch (name) {
    case 'confirmed':
      return _$pluginControlClientMessageOneOf2StatusEnum_confirmed;
    case 'stale':
      return _$pluginControlClientMessageOneOf2StatusEnum_stale;
    case 'upstreamError':
      return _$pluginControlClientMessageOneOf2StatusEnum_upstreamError;
    case 'resultUnknown':
      return _$pluginControlClientMessageOneOf2StatusEnum_resultUnknown;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PluginControlClientMessageOneOf2StatusEnum>
_$pluginControlClientMessageOneOf2StatusEnumValues =
    BuiltSet<PluginControlClientMessageOneOf2StatusEnum>(
      const <PluginControlClientMessageOneOf2StatusEnum>[
        _$pluginControlClientMessageOneOf2StatusEnum_confirmed,
        _$pluginControlClientMessageOneOf2StatusEnum_stale,
        _$pluginControlClientMessageOneOf2StatusEnum_upstreamError,
        _$pluginControlClientMessageOneOf2StatusEnum_resultUnknown,
      ],
    );

const PluginControlClientMessageOneOf2TypeEnum
_$pluginControlClientMessageOneOf2TypeEnum_questionAnswerResult =
    const PluginControlClientMessageOneOf2TypeEnum._('questionAnswerResult');

PluginControlClientMessageOneOf2TypeEnum
_$pluginControlClientMessageOneOf2TypeEnumValueOf(String name) {
  switch (name) {
    case 'questionAnswerResult':
      return _$pluginControlClientMessageOneOf2TypeEnum_questionAnswerResult;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PluginControlClientMessageOneOf2TypeEnum>
_$pluginControlClientMessageOneOf2TypeEnumValues =
    BuiltSet<PluginControlClientMessageOneOf2TypeEnum>(
      const <PluginControlClientMessageOneOf2TypeEnum>[
        _$pluginControlClientMessageOneOf2TypeEnum_questionAnswerResult,
      ],
    );

Serializer<PluginControlClientMessageOneOf2StatusEnum>
_$pluginControlClientMessageOneOf2StatusEnumSerializer =
    _$PluginControlClientMessageOneOf2StatusEnumSerializer();
Serializer<PluginControlClientMessageOneOf2TypeEnum>
_$pluginControlClientMessageOneOf2TypeEnumSerializer =
    _$PluginControlClientMessageOneOf2TypeEnumSerializer();

class _$PluginControlClientMessageOneOf2StatusEnumSerializer
    implements PrimitiveSerializer<PluginControlClientMessageOneOf2StatusEnum> {
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
    PluginControlClientMessageOneOf2StatusEnum,
  ];
  @override
  final String wireName = 'PluginControlClientMessageOneOf2StatusEnum';

  @override
  Object serialize(
    Serializers serializers,
    PluginControlClientMessageOneOf2StatusEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  PluginControlClientMessageOneOf2StatusEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => PluginControlClientMessageOneOf2StatusEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$PluginControlClientMessageOneOf2TypeEnumSerializer
    implements PrimitiveSerializer<PluginControlClientMessageOneOf2TypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'questionAnswerResult': 'question_answer_result',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'question_answer_result': 'questionAnswerResult',
  };

  @override
  final Iterable<Type> types = const <Type>[
    PluginControlClientMessageOneOf2TypeEnum,
  ];
  @override
  final String wireName = 'PluginControlClientMessageOneOf2TypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    PluginControlClientMessageOneOf2TypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  PluginControlClientMessageOneOf2TypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => PluginControlClientMessageOneOf2TypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$PluginControlClientMessageOneOf2
    extends PluginControlClientMessageOneOf2 {
  @override
  final String commandId;
  @override
  final String instanceId;
  @override
  final PluginControlClientMessageOneOf2StatusEnum status;
  @override
  final PluginControlClientMessageOneOf2TypeEnum type;

  factory _$PluginControlClientMessageOneOf2([
    void Function(PluginControlClientMessageOneOf2Builder)? updates,
  ]) => (PluginControlClientMessageOneOf2Builder()..update(updates))._build();

  _$PluginControlClientMessageOneOf2._({
    required this.commandId,
    required this.instanceId,
    required this.status,
    required this.type,
  }) : super._();
  @override
  PluginControlClientMessageOneOf2 rebuild(
    void Function(PluginControlClientMessageOneOf2Builder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PluginControlClientMessageOneOf2Builder toBuilder() =>
      PluginControlClientMessageOneOf2Builder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PluginControlClientMessageOneOf2 &&
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
    return (newBuiltValueToStringHelper(r'PluginControlClientMessageOneOf2')
          ..add('commandId', commandId)
          ..add('instanceId', instanceId)
          ..add('status', status)
          ..add('type', type))
        .toString();
  }
}

class PluginControlClientMessageOneOf2Builder
    implements
        Builder<
          PluginControlClientMessageOneOf2,
          PluginControlClientMessageOneOf2Builder
        > {
  _$PluginControlClientMessageOneOf2? _$v;

  String? _commandId;
  String? get commandId => _$this._commandId;
  set commandId(String? commandId) => _$this._commandId = commandId;

  String? _instanceId;
  String? get instanceId => _$this._instanceId;
  set instanceId(String? instanceId) => _$this._instanceId = instanceId;

  PluginControlClientMessageOneOf2StatusEnum? _status;
  PluginControlClientMessageOneOf2StatusEnum? get status => _$this._status;
  set status(PluginControlClientMessageOneOf2StatusEnum? status) =>
      _$this._status = status;

  PluginControlClientMessageOneOf2TypeEnum? _type;
  PluginControlClientMessageOneOf2TypeEnum? get type => _$this._type;
  set type(PluginControlClientMessageOneOf2TypeEnum? type) =>
      _$this._type = type;

  PluginControlClientMessageOneOf2Builder() {
    PluginControlClientMessageOneOf2._defaults(this);
  }

  PluginControlClientMessageOneOf2Builder get _$this {
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
  void replace(PluginControlClientMessageOneOf2 other) {
    _$v = other as _$PluginControlClientMessageOneOf2;
  }

  @override
  void update(void Function(PluginControlClientMessageOneOf2Builder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PluginControlClientMessageOneOf2 build() => _build();

  _$PluginControlClientMessageOneOf2 _build() {
    final _$result =
        _$v ??
        _$PluginControlClientMessageOneOf2._(
          commandId: BuiltValueNullFieldError.checkNotNull(
            commandId,
            r'PluginControlClientMessageOneOf2',
            'commandId',
          ),
          instanceId: BuiltValueNullFieldError.checkNotNull(
            instanceId,
            r'PluginControlClientMessageOneOf2',
            'instanceId',
          ),
          status: BuiltValueNullFieldError.checkNotNull(
            status,
            r'PluginControlClientMessageOneOf2',
            'status',
          ),
          type: BuiltValueNullFieldError.checkNotNull(
            type,
            r'PluginControlClientMessageOneOf2',
            'type',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
