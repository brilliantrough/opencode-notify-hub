// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_control_server_message_one_of.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const PluginControlServerMessageOneOfStateEnum
_$pluginControlServerMessageOneOfStateEnum_controllable =
    const PluginControlServerMessageOneOfStateEnum._('controllable');
const PluginControlServerMessageOneOfStateEnum
_$pluginControlServerMessageOneOfStateEnum_conflicting =
    const PluginControlServerMessageOneOfStateEnum._('conflicting');
const PluginControlServerMessageOneOfStateEnum
_$pluginControlServerMessageOneOfStateEnum_incompatible =
    const PluginControlServerMessageOneOfStateEnum._('incompatible');

PluginControlServerMessageOneOfStateEnum
_$pluginControlServerMessageOneOfStateEnumValueOf(String name) {
  switch (name) {
    case 'controllable':
      return _$pluginControlServerMessageOneOfStateEnum_controllable;
    case 'conflicting':
      return _$pluginControlServerMessageOneOfStateEnum_conflicting;
    case 'incompatible':
      return _$pluginControlServerMessageOneOfStateEnum_incompatible;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PluginControlServerMessageOneOfStateEnum>
_$pluginControlServerMessageOneOfStateEnumValues =
    BuiltSet<PluginControlServerMessageOneOfStateEnum>(
      const <PluginControlServerMessageOneOfStateEnum>[
        _$pluginControlServerMessageOneOfStateEnum_controllable,
        _$pluginControlServerMessageOneOfStateEnum_conflicting,
        _$pluginControlServerMessageOneOfStateEnum_incompatible,
      ],
    );

const PluginControlServerMessageOneOfTypeEnum
_$pluginControlServerMessageOneOfTypeEnum_registration =
    const PluginControlServerMessageOneOfTypeEnum._('registration');

PluginControlServerMessageOneOfTypeEnum
_$pluginControlServerMessageOneOfTypeEnumValueOf(String name) {
  switch (name) {
    case 'registration':
      return _$pluginControlServerMessageOneOfTypeEnum_registration;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PluginControlServerMessageOneOfTypeEnum>
_$pluginControlServerMessageOneOfTypeEnumValues =
    BuiltSet<PluginControlServerMessageOneOfTypeEnum>(
      const <PluginControlServerMessageOneOfTypeEnum>[
        _$pluginControlServerMessageOneOfTypeEnum_registration,
      ],
    );

Serializer<PluginControlServerMessageOneOfStateEnum>
_$pluginControlServerMessageOneOfStateEnumSerializer =
    _$PluginControlServerMessageOneOfStateEnumSerializer();
Serializer<PluginControlServerMessageOneOfTypeEnum>
_$pluginControlServerMessageOneOfTypeEnumSerializer =
    _$PluginControlServerMessageOneOfTypeEnumSerializer();

class _$PluginControlServerMessageOneOfStateEnumSerializer
    implements PrimitiveSerializer<PluginControlServerMessageOneOfStateEnum> {
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
    PluginControlServerMessageOneOfStateEnum,
  ];
  @override
  final String wireName = 'PluginControlServerMessageOneOfStateEnum';

  @override
  Object serialize(
    Serializers serializers,
    PluginControlServerMessageOneOfStateEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  PluginControlServerMessageOneOfStateEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => PluginControlServerMessageOneOfStateEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$PluginControlServerMessageOneOfTypeEnumSerializer
    implements PrimitiveSerializer<PluginControlServerMessageOneOfTypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'registration': 'registration',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'registration': 'registration',
  };

  @override
  final Iterable<Type> types = const <Type>[
    PluginControlServerMessageOneOfTypeEnum,
  ];
  @override
  final String wireName = 'PluginControlServerMessageOneOfTypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    PluginControlServerMessageOneOfTypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  PluginControlServerMessageOneOfTypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => PluginControlServerMessageOneOfTypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$PluginControlServerMessageOneOf
    extends PluginControlServerMessageOneOf {
  @override
  final String instanceId;
  @override
  final PluginControlServerMessageOneOfStateEnum state;
  @override
  final PluginControlServerMessageOneOfTypeEnum type;

  factory _$PluginControlServerMessageOneOf([
    void Function(PluginControlServerMessageOneOfBuilder)? updates,
  ]) => (PluginControlServerMessageOneOfBuilder()..update(updates))._build();

  _$PluginControlServerMessageOneOf._({
    required this.instanceId,
    required this.state,
    required this.type,
  }) : super._();
  @override
  PluginControlServerMessageOneOf rebuild(
    void Function(PluginControlServerMessageOneOfBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PluginControlServerMessageOneOfBuilder toBuilder() =>
      PluginControlServerMessageOneOfBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PluginControlServerMessageOneOf &&
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
    return (newBuiltValueToStringHelper(r'PluginControlServerMessageOneOf')
          ..add('instanceId', instanceId)
          ..add('state', state)
          ..add('type', type))
        .toString();
  }
}

class PluginControlServerMessageOneOfBuilder
    implements
        Builder<
          PluginControlServerMessageOneOf,
          PluginControlServerMessageOneOfBuilder
        > {
  _$PluginControlServerMessageOneOf? _$v;

  String? _instanceId;
  String? get instanceId => _$this._instanceId;
  set instanceId(String? instanceId) => _$this._instanceId = instanceId;

  PluginControlServerMessageOneOfStateEnum? _state;
  PluginControlServerMessageOneOfStateEnum? get state => _$this._state;
  set state(PluginControlServerMessageOneOfStateEnum? state) =>
      _$this._state = state;

  PluginControlServerMessageOneOfTypeEnum? _type;
  PluginControlServerMessageOneOfTypeEnum? get type => _$this._type;
  set type(PluginControlServerMessageOneOfTypeEnum? type) =>
      _$this._type = type;

  PluginControlServerMessageOneOfBuilder() {
    PluginControlServerMessageOneOf._defaults(this);
  }

  PluginControlServerMessageOneOfBuilder get _$this {
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
  void replace(PluginControlServerMessageOneOf other) {
    _$v = other as _$PluginControlServerMessageOneOf;
  }

  @override
  void update(void Function(PluginControlServerMessageOneOfBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PluginControlServerMessageOneOf build() => _build();

  _$PluginControlServerMessageOneOf _build() {
    final _$result =
        _$v ??
        _$PluginControlServerMessageOneOf._(
          instanceId: BuiltValueNullFieldError.checkNotNull(
            instanceId,
            r'PluginControlServerMessageOneOf',
            'instanceId',
          ),
          state: BuiltValueNullFieldError.checkNotNull(
            state,
            r'PluginControlServerMessageOneOf',
            'state',
          ),
          type: BuiltValueNullFieldError.checkNotNull(
            type,
            r'PluginControlServerMessageOneOf',
            'type',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
