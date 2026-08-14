// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_control_server_message.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const PluginControlServerMessageStateEnum
_$pluginControlServerMessageStateEnum_controllable =
    const PluginControlServerMessageStateEnum._('controllable');
const PluginControlServerMessageStateEnum
_$pluginControlServerMessageStateEnum_conflicting =
    const PluginControlServerMessageStateEnum._('conflicting');
const PluginControlServerMessageStateEnum
_$pluginControlServerMessageStateEnum_incompatible =
    const PluginControlServerMessageStateEnum._('incompatible');

PluginControlServerMessageStateEnum
_$pluginControlServerMessageStateEnumValueOf(String name) {
  switch (name) {
    case 'controllable':
      return _$pluginControlServerMessageStateEnum_controllable;
    case 'conflicting':
      return _$pluginControlServerMessageStateEnum_conflicting;
    case 'incompatible':
      return _$pluginControlServerMessageStateEnum_incompatible;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PluginControlServerMessageStateEnum>
_$pluginControlServerMessageStateEnumValues =
    BuiltSet<PluginControlServerMessageStateEnum>(
      const <PluginControlServerMessageStateEnum>[
        _$pluginControlServerMessageStateEnum_controllable,
        _$pluginControlServerMessageStateEnum_conflicting,
        _$pluginControlServerMessageStateEnum_incompatible,
      ],
    );

const PluginControlServerMessageTypeEnum
_$pluginControlServerMessageTypeEnum_registration =
    const PluginControlServerMessageTypeEnum._('registration');

PluginControlServerMessageTypeEnum _$pluginControlServerMessageTypeEnumValueOf(
  String name,
) {
  switch (name) {
    case 'registration':
      return _$pluginControlServerMessageTypeEnum_registration;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PluginControlServerMessageTypeEnum>
_$pluginControlServerMessageTypeEnumValues =
    BuiltSet<PluginControlServerMessageTypeEnum>(
      const <PluginControlServerMessageTypeEnum>[
        _$pluginControlServerMessageTypeEnum_registration,
      ],
    );

Serializer<PluginControlServerMessageStateEnum>
_$pluginControlServerMessageStateEnumSerializer =
    _$PluginControlServerMessageStateEnumSerializer();
Serializer<PluginControlServerMessageTypeEnum>
_$pluginControlServerMessageTypeEnumSerializer =
    _$PluginControlServerMessageTypeEnumSerializer();

class _$PluginControlServerMessageStateEnumSerializer
    implements PrimitiveSerializer<PluginControlServerMessageStateEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'controllable': 'controllable',
    'conflicting': 'conflicting',
    'incompatible': 'incompatible',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'controllable': 'controllable',
    'conflicting': 'conflicting',
    'incompatible': 'incompatible',
  };

  @override
  final Iterable<Type> types = const <Type>[
    PluginControlServerMessageStateEnum,
  ];
  @override
  final String wireName = 'PluginControlServerMessageStateEnum';

  @override
  Object serialize(
    Serializers serializers,
    PluginControlServerMessageStateEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  PluginControlServerMessageStateEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => PluginControlServerMessageStateEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$PluginControlServerMessageTypeEnumSerializer
    implements PrimitiveSerializer<PluginControlServerMessageTypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'registration': 'registration',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'registration': 'registration',
  };

  @override
  final Iterable<Type> types = const <Type>[PluginControlServerMessageTypeEnum];
  @override
  final String wireName = 'PluginControlServerMessageTypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    PluginControlServerMessageTypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  PluginControlServerMessageTypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => PluginControlServerMessageTypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$PluginControlServerMessage extends PluginControlServerMessage {
  @override
  final String instanceId;
  @override
  final PluginControlServerMessageStateEnum state;
  @override
  final PluginControlServerMessageTypeEnum type;

  factory _$PluginControlServerMessage([
    void Function(PluginControlServerMessageBuilder)? updates,
  ]) => (PluginControlServerMessageBuilder()..update(updates))._build();

  _$PluginControlServerMessage._({
    required this.instanceId,
    required this.state,
    required this.type,
  }) : super._();
  @override
  PluginControlServerMessage rebuild(
    void Function(PluginControlServerMessageBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PluginControlServerMessageBuilder toBuilder() =>
      PluginControlServerMessageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PluginControlServerMessage &&
        instanceId == other.instanceId &&
        state == other.state &&
        type == other.type;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, instanceId.hashCode);
    _$hash = $jc(_$hash, state.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PluginControlServerMessage')
          ..add('instanceId', instanceId)
          ..add('state', state)
          ..add('type', type))
        .toString();
  }
}

class PluginControlServerMessageBuilder
    implements
        Builder<PluginControlServerMessage, PluginControlServerMessageBuilder> {
  _$PluginControlServerMessage? _$v;

  String? _instanceId;
  String? get instanceId => _$this._instanceId;
  set instanceId(String? instanceId) => _$this._instanceId = instanceId;

  PluginControlServerMessageStateEnum? _state;
  PluginControlServerMessageStateEnum? get state => _$this._state;
  set state(PluginControlServerMessageStateEnum? state) =>
      _$this._state = state;

  PluginControlServerMessageTypeEnum? _type;
  PluginControlServerMessageTypeEnum? get type => _$this._type;
  set type(PluginControlServerMessageTypeEnum? type) => _$this._type = type;

  PluginControlServerMessageBuilder() {
    PluginControlServerMessage._defaults(this);
  }

  PluginControlServerMessageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _instanceId = $v.instanceId;
      _state = $v.state;
      _type = $v.type;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PluginControlServerMessage other) {
    _$v = other as _$PluginControlServerMessage;
  }

  @override
  void update(void Function(PluginControlServerMessageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PluginControlServerMessage build() => _build();

  _$PluginControlServerMessage _build() {
    final _$result =
        _$v ??
        _$PluginControlServerMessage._(
          instanceId: BuiltValueNullFieldError.checkNotNull(
            instanceId,
            r'PluginControlServerMessage',
            'instanceId',
          ),
          state: BuiltValueNullFieldError.checkNotNull(
            state,
            r'PluginControlServerMessage',
            'state',
          ),
          type: BuiltValueNullFieldError.checkNotNull(
            type,
            r'PluginControlServerMessage',
            'type',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
