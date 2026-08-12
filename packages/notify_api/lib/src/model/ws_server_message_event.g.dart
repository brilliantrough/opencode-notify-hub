// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ws_server_message_event.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const WsServerMessageEventTypeEnum _$wsServerMessageEventTypeEnum_heartbeat =
    const WsServerMessageEventTypeEnum._('heartbeat');
const WsServerMessageEventTypeEnum
_$wsServerMessageEventTypeEnum_actionRequired =
    const WsServerMessageEventTypeEnum._('actionRequired');
const WsServerMessageEventTypeEnum
_$wsServerMessageEventTypeEnum_actionResolved =
    const WsServerMessageEventTypeEnum._('actionResolved');
const WsServerMessageEventTypeEnum _$wsServerMessageEventTypeEnum_terminal =
    const WsServerMessageEventTypeEnum._('terminal');

WsServerMessageEventTypeEnum _$wsServerMessageEventTypeEnumValueOf(
  String name,
) {
  switch (name) {
    case 'heartbeat':
      return _$wsServerMessageEventTypeEnum_heartbeat;
    case 'actionRequired':
      return _$wsServerMessageEventTypeEnum_actionRequired;
    case 'actionResolved':
      return _$wsServerMessageEventTypeEnum_actionResolved;
    case 'terminal':
      return _$wsServerMessageEventTypeEnum_terminal;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<WsServerMessageEventTypeEnum>
_$wsServerMessageEventTypeEnumValues =
    BuiltSet<WsServerMessageEventTypeEnum>(const <WsServerMessageEventTypeEnum>[
      _$wsServerMessageEventTypeEnum_heartbeat,
      _$wsServerMessageEventTypeEnum_actionRequired,
      _$wsServerMessageEventTypeEnum_actionResolved,
      _$wsServerMessageEventTypeEnum_terminal,
    ]);

Serializer<WsServerMessageEventTypeEnum>
_$wsServerMessageEventTypeEnumSerializer =
    _$WsServerMessageEventTypeEnumSerializer();

class _$WsServerMessageEventTypeEnumSerializer
    implements PrimitiveSerializer<WsServerMessageEventTypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'heartbeat': 'heartbeat',
    'actionRequired': 'action_required',
    'actionResolved': 'action_resolved',
    'terminal': 'terminal',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'heartbeat': 'heartbeat',
    'action_required': 'actionRequired',
    'action_resolved': 'actionResolved',
    'terminal': 'terminal',
  };

  @override
  final Iterable<Type> types = const <Type>[WsServerMessageEventTypeEnum];
  @override
  final String wireName = 'WsServerMessageEventTypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    WsServerMessageEventTypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  WsServerMessageEventTypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => WsServerMessageEventTypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$WsServerMessageEvent extends WsServerMessageEvent {
  @override
  final OneOf oneOf;

  factory _$WsServerMessageEvent([
    void Function(WsServerMessageEventBuilder)? updates,
  ]) => (WsServerMessageEventBuilder()..update(updates))._build();

  _$WsServerMessageEvent._({required this.oneOf}) : super._();
  @override
  WsServerMessageEvent rebuild(
    void Function(WsServerMessageEventBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  WsServerMessageEventBuilder toBuilder() =>
      WsServerMessageEventBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is WsServerMessageEvent && oneOf == other.oneOf;
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
      r'WsServerMessageEvent',
    )..add('oneOf', oneOf)).toString();
  }
}

class WsServerMessageEventBuilder
    implements Builder<WsServerMessageEvent, WsServerMessageEventBuilder> {
  _$WsServerMessageEvent? _$v;

  OneOf? _oneOf;
  OneOf? get oneOf => _$this._oneOf;
  set oneOf(OneOf? oneOf) => _$this._oneOf = oneOf;

  WsServerMessageEventBuilder() {
    WsServerMessageEvent._defaults(this);
  }

  WsServerMessageEventBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _oneOf = $v.oneOf;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(WsServerMessageEvent other) {
    _$v = other as _$WsServerMessageEvent;
  }

  @override
  void update(void Function(WsServerMessageEventBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  WsServerMessageEvent build() => _build();

  _$WsServerMessageEvent _build() {
    final _$result =
        _$v ??
        _$WsServerMessageEvent._(
          oneOf: BuiltValueNullFieldError.checkNotNull(
            oneOf,
            r'WsServerMessageEvent',
            'oneOf',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
