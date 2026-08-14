// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ws_server_message_one_of1.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const WsServerMessageOneOf1TypeEnum
_$wsServerMessageOneOf1TypeEnum_instancePresence =
    const WsServerMessageOneOf1TypeEnum._('instancePresence');

WsServerMessageOneOf1TypeEnum _$wsServerMessageOneOf1TypeEnumValueOf(
  String name,
) {
  switch (name) {
    case 'instancePresence':
      return _$wsServerMessageOneOf1TypeEnum_instancePresence;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<WsServerMessageOneOf1TypeEnum>
_$wsServerMessageOneOf1TypeEnumValues = BuiltSet<WsServerMessageOneOf1TypeEnum>(
  const <WsServerMessageOneOf1TypeEnum>[
    _$wsServerMessageOneOf1TypeEnum_instancePresence,
  ],
);

Serializer<WsServerMessageOneOf1TypeEnum>
_$wsServerMessageOneOf1TypeEnumSerializer =
    _$WsServerMessageOneOf1TypeEnumSerializer();

class _$WsServerMessageOneOf1TypeEnumSerializer
    implements PrimitiveSerializer<WsServerMessageOneOf1TypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'instancePresence': 'instance_presence',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'instance_presence': 'instancePresence',
  };

  @override
  final Iterable<Type> types = const <Type>[WsServerMessageOneOf1TypeEnum];
  @override
  final String wireName = 'WsServerMessageOneOf1TypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    WsServerMessageOneOf1TypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  WsServerMessageOneOf1TypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => WsServerMessageOneOf1TypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$WsServerMessageOneOf1 extends WsServerMessageOneOf1 {
  @override
  final BuiltList<WsServerMessageOneOf1InstancesInner> instances;
  @override
  final WsServerMessageOneOf1TypeEnum type;

  factory _$WsServerMessageOneOf1([
    void Function(WsServerMessageOneOf1Builder)? updates,
  ]) => (WsServerMessageOneOf1Builder()..update(updates))._build();

  _$WsServerMessageOneOf1._({required this.instances, required this.type})
    : super._();
  @override
  WsServerMessageOneOf1 rebuild(
    void Function(WsServerMessageOneOf1Builder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  WsServerMessageOneOf1Builder toBuilder() =>
      WsServerMessageOneOf1Builder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is WsServerMessageOneOf1 &&
        instances == other.instances &&
        type == other.type;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, instances.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'WsServerMessageOneOf1')
          ..add('instances', instances)
          ..add('type', type))
        .toString();
  }
}

class WsServerMessageOneOf1Builder
    implements Builder<WsServerMessageOneOf1, WsServerMessageOneOf1Builder> {
  _$WsServerMessageOneOf1? _$v;

  ListBuilder<WsServerMessageOneOf1InstancesInner>? _instances;
  ListBuilder<WsServerMessageOneOf1InstancesInner> get instances =>
      _$this._instances ??= ListBuilder<WsServerMessageOneOf1InstancesInner>();
  set instances(ListBuilder<WsServerMessageOneOf1InstancesInner>? instances) =>
      _$this._instances = instances;

  WsServerMessageOneOf1TypeEnum? _type;
  WsServerMessageOneOf1TypeEnum? get type => _$this._type;
  set type(WsServerMessageOneOf1TypeEnum? type) => _$this._type = type;

  WsServerMessageOneOf1Builder() {
    WsServerMessageOneOf1._defaults(this);
  }

  WsServerMessageOneOf1Builder get _$this {
    final $v = _$v;
    if ($v != null) {
      _instances = $v.instances.toBuilder();
      _type = $v.type;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(WsServerMessageOneOf1 other) {
    _$v = other as _$WsServerMessageOneOf1;
  }

  @override
  void update(void Function(WsServerMessageOneOf1Builder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  WsServerMessageOneOf1 build() => _build();

  _$WsServerMessageOneOf1 _build() {
    _$WsServerMessageOneOf1 _$result;
    try {
      _$result =
          _$v ??
          _$WsServerMessageOneOf1._(
            instances: instances.build(),
            type: BuiltValueNullFieldError.checkNotNull(
              type,
              r'WsServerMessageOneOf1',
              'type',
            ),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'instances';
        instances.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'WsServerMessageOneOf1',
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
