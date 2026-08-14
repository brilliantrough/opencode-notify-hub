// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ws_server_message_one_of_event.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const WsServerMessageOneOfEventTypeEnum
_$wsServerMessageOneOfEventTypeEnum_heartbeat =
    const WsServerMessageOneOfEventTypeEnum._('heartbeat');
const WsServerMessageOneOfEventTypeEnum
_$wsServerMessageOneOfEventTypeEnum_actionRequired =
    const WsServerMessageOneOfEventTypeEnum._('actionRequired');
const WsServerMessageOneOfEventTypeEnum
_$wsServerMessageOneOfEventTypeEnum_actionResolved =
    const WsServerMessageOneOfEventTypeEnum._('actionResolved');
const WsServerMessageOneOfEventTypeEnum
_$wsServerMessageOneOfEventTypeEnum_terminal =
    const WsServerMessageOneOfEventTypeEnum._('terminal');

WsServerMessageOneOfEventTypeEnum _$wsServerMessageOneOfEventTypeEnumValueOf(
  String name,
) {
  switch (name) {
    case 'heartbeat':
      return _$wsServerMessageOneOfEventTypeEnum_heartbeat;
    case 'actionRequired':
      return _$wsServerMessageOneOfEventTypeEnum_actionRequired;
    case 'actionResolved':
      return _$wsServerMessageOneOfEventTypeEnum_actionResolved;
    case 'terminal':
      return _$wsServerMessageOneOfEventTypeEnum_terminal;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<WsServerMessageOneOfEventTypeEnum>
_$wsServerMessageOneOfEventTypeEnumValues =
    BuiltSet<WsServerMessageOneOfEventTypeEnum>(
      const <WsServerMessageOneOfEventTypeEnum>[
        _$wsServerMessageOneOfEventTypeEnum_heartbeat,
        _$wsServerMessageOneOfEventTypeEnum_actionRequired,
        _$wsServerMessageOneOfEventTypeEnum_actionResolved,
        _$wsServerMessageOneOfEventTypeEnum_terminal,
      ],
    );

Serializer<WsServerMessageOneOfEventTypeEnum>
_$wsServerMessageOneOfEventTypeEnumSerializer =
    _$WsServerMessageOneOfEventTypeEnumSerializer();

class _$WsServerMessageOneOfEventTypeEnumSerializer
    implements PrimitiveSerializer<WsServerMessageOneOfEventTypeEnum> {
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
  final Iterable<Type> types = const <Type>[WsServerMessageOneOfEventTypeEnum];
  @override
  final String wireName = 'WsServerMessageOneOfEventTypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    WsServerMessageOneOfEventTypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  WsServerMessageOneOfEventTypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => WsServerMessageOneOfEventTypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$WsServerMessageOneOfEvent extends WsServerMessageOneOfEvent {
  @override
  final OneOf oneOf;

  factory _$WsServerMessageOneOfEvent([
    void Function(WsServerMessageOneOfEventBuilder)? updates,
  ]) => (WsServerMessageOneOfEventBuilder()..update(updates))._build();

  _$WsServerMessageOneOfEvent._({required this.oneOf}) : super._();
  @override
  WsServerMessageOneOfEvent rebuild(
    void Function(WsServerMessageOneOfEventBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  WsServerMessageOneOfEventBuilder toBuilder() =>
      WsServerMessageOneOfEventBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is WsServerMessageOneOfEvent && oneOf == other.oneOf;
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
      r'WsServerMessageOneOfEvent',
    )..add('oneOf', oneOf)).toString();
  }
}

class WsServerMessageOneOfEventBuilder
    implements
        Builder<WsServerMessageOneOfEvent, WsServerMessageOneOfEventBuilder> {
  _$WsServerMessageOneOfEvent? _$v;

  OneOf? _oneOf;
  OneOf? get oneOf => _$this._oneOf;
  set oneOf(OneOf? oneOf) => _$this._oneOf = oneOf;

  WsServerMessageOneOfEventBuilder() {
    WsServerMessageOneOfEvent._defaults(this);
  }

  WsServerMessageOneOfEventBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _oneOf = $v.oneOf;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(WsServerMessageOneOfEvent other) {
    _$v = other as _$WsServerMessageOneOfEvent;
  }

  @override
  void update(void Function(WsServerMessageOneOfEventBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  WsServerMessageOneOfEvent build() => _build();

  _$WsServerMessageOneOfEvent _build() {
    final _$result =
        _$v ??
        _$WsServerMessageOneOfEvent._(
          oneOf: BuiltValueNullFieldError.checkNotNull(
            oneOf,
            r'WsServerMessageOneOfEvent',
            'oneOf',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
