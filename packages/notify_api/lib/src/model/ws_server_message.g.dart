// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ws_server_message.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const WsServerMessageTypeEnum _$wsServerMessageTypeEnum_event =
    const WsServerMessageTypeEnum._('event');
const WsServerMessageTypeEnum _$wsServerMessageTypeEnum_instancePresence =
    const WsServerMessageTypeEnum._('instancePresence');

WsServerMessageTypeEnum _$wsServerMessageTypeEnumValueOf(String name) {
  switch (name) {
    case 'event':
      return _$wsServerMessageTypeEnum_event;
    case 'instancePresence':
      return _$wsServerMessageTypeEnum_instancePresence;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<WsServerMessageTypeEnum> _$wsServerMessageTypeEnumValues =
    BuiltSet<WsServerMessageTypeEnum>(const <WsServerMessageTypeEnum>[
      _$wsServerMessageTypeEnum_event,
      _$wsServerMessageTypeEnum_instancePresence,
    ]);

Serializer<WsServerMessageTypeEnum> _$wsServerMessageTypeEnumSerializer =
    _$WsServerMessageTypeEnumSerializer();

class _$WsServerMessageTypeEnumSerializer
    implements PrimitiveSerializer<WsServerMessageTypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'event': 'event',
    'instancePresence': 'instance_presence',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'event': 'event',
    'instance_presence': 'instancePresence',
  };

  @override
  final Iterable<Type> types = const <Type>[WsServerMessageTypeEnum];
  @override
  final String wireName = 'WsServerMessageTypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    WsServerMessageTypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  WsServerMessageTypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => WsServerMessageTypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$WsServerMessage extends WsServerMessage {
  @override
  final OneOf oneOf;

  factory _$WsServerMessage([void Function(WsServerMessageBuilder)? updates]) =>
      (WsServerMessageBuilder()..update(updates))._build();

  _$WsServerMessage._({required this.oneOf}) : super._();
  @override
  WsServerMessage rebuild(void Function(WsServerMessageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  WsServerMessageBuilder toBuilder() => WsServerMessageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is WsServerMessage && oneOf == other.oneOf;
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
      r'WsServerMessage',
    )..add('oneOf', oneOf)).toString();
  }
}

class WsServerMessageBuilder
    implements Builder<WsServerMessage, WsServerMessageBuilder> {
  _$WsServerMessage? _$v;

  OneOf? _oneOf;
  OneOf? get oneOf => _$this._oneOf;
  set oneOf(OneOf? oneOf) => _$this._oneOf = oneOf;

  WsServerMessageBuilder() {
    WsServerMessage._defaults(this);
  }

  WsServerMessageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _oneOf = $v.oneOf;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(WsServerMessage other) {
    _$v = other as _$WsServerMessage;
  }

  @override
  void update(void Function(WsServerMessageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  WsServerMessage build() => _build();

  _$WsServerMessage _build() {
    final _$result =
        _$v ??
        _$WsServerMessage._(
          oneOf: BuiltValueNullFieldError.checkNotNull(
            oneOf,
            r'WsServerMessage',
            'oneOf',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
