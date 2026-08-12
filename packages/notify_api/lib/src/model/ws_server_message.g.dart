// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ws_server_message.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const WsServerMessageTypeEnum _$wsServerMessageTypeEnum_event =
    const WsServerMessageTypeEnum._('event');

WsServerMessageTypeEnum _$wsServerMessageTypeEnumValueOf(String name) {
  switch (name) {
    case 'event':
      return _$wsServerMessageTypeEnum_event;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<WsServerMessageTypeEnum> _$wsServerMessageTypeEnumValues =
    BuiltSet<WsServerMessageTypeEnum>(const <WsServerMessageTypeEnum>[
      _$wsServerMessageTypeEnum_event,
    ]);

Serializer<WsServerMessageTypeEnum> _$wsServerMessageTypeEnumSerializer =
    _$WsServerMessageTypeEnumSerializer();

class _$WsServerMessageTypeEnumSerializer
    implements PrimitiveSerializer<WsServerMessageTypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'event': 'event',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'event': 'event',
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
  final WsServerMessageEvent event;
  @override
  final WsServerMessageTypeEnum type;

  factory _$WsServerMessage([void Function(WsServerMessageBuilder)? updates]) =>
      (WsServerMessageBuilder()..update(updates))._build();

  _$WsServerMessage._({required this.event, required this.type}) : super._();
  @override
  WsServerMessage rebuild(void Function(WsServerMessageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  WsServerMessageBuilder toBuilder() => WsServerMessageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is WsServerMessage &&
        event == other.event &&
        type == other.type;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, event.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'WsServerMessage')
          ..add('event', event)
          ..add('type', type))
        .toString();
  }
}

class WsServerMessageBuilder
    implements Builder<WsServerMessage, WsServerMessageBuilder> {
  _$WsServerMessage? _$v;

  WsServerMessageEventBuilder? _event;
  WsServerMessageEventBuilder get event =>
      _$this._event ??= WsServerMessageEventBuilder();
  set event(WsServerMessageEventBuilder? event) => _$this._event = event;

  WsServerMessageTypeEnum? _type;
  WsServerMessageTypeEnum? get type => _$this._type;
  set type(WsServerMessageTypeEnum? type) => _$this._type = type;

  WsServerMessageBuilder() {
    WsServerMessage._defaults(this);
  }

  WsServerMessageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _event = $v.event.toBuilder();
      _type = $v.type;
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
    _$WsServerMessage _$result;
    try {
      _$result =
          _$v ??
          _$WsServerMessage._(
            event: event.build(),
            type: BuiltValueNullFieldError.checkNotNull(
              type,
              r'WsServerMessage',
              'type',
            ),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'event';
        event.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'WsServerMessage',
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
