// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notify_event_one_of1_payload.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const NotifyEventOneOf1PayloadKindEnum
_$notifyEventOneOf1PayloadKindEnum_providerAction =
    const NotifyEventOneOf1PayloadKindEnum._('providerAction');

NotifyEventOneOf1PayloadKindEnum _$notifyEventOneOf1PayloadKindEnumValueOf(
  String name,
) {
  switch (name) {
    case 'providerAction':
      return _$notifyEventOneOf1PayloadKindEnum_providerAction;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<NotifyEventOneOf1PayloadKindEnum>
_$notifyEventOneOf1PayloadKindEnumValues =
    BuiltSet<NotifyEventOneOf1PayloadKindEnum>(
      const <NotifyEventOneOf1PayloadKindEnum>[
        _$notifyEventOneOf1PayloadKindEnum_providerAction,
      ],
    );

Serializer<NotifyEventOneOf1PayloadKindEnum>
_$notifyEventOneOf1PayloadKindEnumSerializer =
    _$NotifyEventOneOf1PayloadKindEnumSerializer();

class _$NotifyEventOneOf1PayloadKindEnumSerializer
    implements PrimitiveSerializer<NotifyEventOneOf1PayloadKindEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'providerAction': 'provider_action',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'provider_action': 'providerAction',
  };

  @override
  final Iterable<Type> types = const <Type>[NotifyEventOneOf1PayloadKindEnum];
  @override
  final String wireName = 'NotifyEventOneOf1PayloadKindEnum';

  @override
  Object serialize(
    Serializers serializers,
    NotifyEventOneOf1PayloadKindEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  NotifyEventOneOf1PayloadKindEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => NotifyEventOneOf1PayloadKindEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$NotifyEventOneOf1Payload extends NotifyEventOneOf1Payload {
  @override
  final OneOf oneOf;

  factory _$NotifyEventOneOf1Payload([
    void Function(NotifyEventOneOf1PayloadBuilder)? updates,
  ]) => (NotifyEventOneOf1PayloadBuilder()..update(updates))._build();

  _$NotifyEventOneOf1Payload._({required this.oneOf}) : super._();
  @override
  NotifyEventOneOf1Payload rebuild(
    void Function(NotifyEventOneOf1PayloadBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  NotifyEventOneOf1PayloadBuilder toBuilder() =>
      NotifyEventOneOf1PayloadBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NotifyEventOneOf1Payload && oneOf == other.oneOf;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, oneOf.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'NotifyEventOneOf1Payload',
    )..add('oneOf', oneOf)).toString();
  }
}

class NotifyEventOneOf1PayloadBuilder
    implements
        Builder<NotifyEventOneOf1Payload, NotifyEventOneOf1PayloadBuilder> {
  _$NotifyEventOneOf1Payload? _$v;

  OneOf? _oneOf;
  OneOf? get oneOf => _$this._oneOf;
  set oneOf(OneOf? oneOf) => _$this._oneOf = oneOf;

  NotifyEventOneOf1PayloadBuilder() {
    NotifyEventOneOf1Payload._defaults(this);
  }

  NotifyEventOneOf1PayloadBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _oneOf = $v.oneOf;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(NotifyEventOneOf1Payload other) {
    _$v = other as _$NotifyEventOneOf1Payload;
  }

  @override
  void update(void Function(NotifyEventOneOf1PayloadBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  NotifyEventOneOf1Payload build() => _build();

  _$NotifyEventOneOf1Payload _build() {
    final _$result =
        _$v ??
        _$NotifyEventOneOf1Payload._(
          oneOf: BuiltValueNullFieldError.checkNotNull(
            oneOf,
            r'NotifyEventOneOf1Payload',
            'oneOf',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
