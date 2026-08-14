// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ws_server_message_one_of.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const WsServerMessageOneOfTypeEnum _$wsServerMessageOneOfTypeEnum_event =
    const WsServerMessageOneOfTypeEnum._('event');

WsServerMessageOneOfTypeEnum _$wsServerMessageOneOfTypeEnumValueOf(
  String name,
) {
  switch (name) {
    case 'event':
      return _$wsServerMessageOneOfTypeEnum_event;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<WsServerMessageOneOfTypeEnum>
_$wsServerMessageOneOfTypeEnumValues = BuiltSet<WsServerMessageOneOfTypeEnum>(
  const <WsServerMessageOneOfTypeEnum>[_$wsServerMessageOneOfTypeEnum_event],
);

Serializer<WsServerMessageOneOfTypeEnum>
_$wsServerMessageOneOfTypeEnumSerializer =
    _$WsServerMessageOneOfTypeEnumSerializer();

class _$WsServerMessageOneOfTypeEnumSerializer
    implements PrimitiveSerializer<WsServerMessageOneOfTypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'event': 'event',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'event': 'event',
  };

  @override
  final Iterable<Type> types = const <Type>[WsServerMessageOneOfTypeEnum];
  @override
  final String wireName = 'WsServerMessageOneOfTypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    WsServerMessageOneOfTypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  WsServerMessageOneOfTypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => WsServerMessageOneOfTypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$WsServerMessageOneOf extends WsServerMessageOneOf {
  @override
  final WsServerMessageOneOfEvent event;
  @override
  final WsServerMessageOneOfTypeEnum type;

  factory _$WsServerMessageOneOf([
    void Function(WsServerMessageOneOfBuilder)? updates,
  ]) => (WsServerMessageOneOfBuilder()..update(updates))._build();

  _$WsServerMessageOneOf._({required this.event, required this.type})
    : super._();
  @override
  WsServerMessageOneOf rebuild(
    void Function(WsServerMessageOneOfBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  WsServerMessageOneOfBuilder toBuilder() =>
      WsServerMessageOneOfBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is WsServerMessageOneOf &&
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
    return (newBuiltValueToStringHelper(r'WsServerMessageOneOf')
          ..add('event', event)
          ..add('type', type))
        .toString();
  }
}

class WsServerMessageOneOfBuilder
    implements Builder<WsServerMessageOneOf, WsServerMessageOneOfBuilder> {
  _$WsServerMessageOneOf? _$v;

  WsServerMessageOneOfEventBuilder? _event;
  WsServerMessageOneOfEventBuilder get event =>
      _$this._event ??= WsServerMessageOneOfEventBuilder();
  set event(WsServerMessageOneOfEventBuilder? event) => _$this._event = event;

  WsServerMessageOneOfTypeEnum? _type;
  WsServerMessageOneOfTypeEnum? get type => _$this._type;
  set type(WsServerMessageOneOfTypeEnum? type) => _$this._type = type;

  WsServerMessageOneOfBuilder() {
    WsServerMessageOneOf._defaults(this);
  }

  WsServerMessageOneOfBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _event = $v.event.toBuilder();
      _type = $v.type;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(WsServerMessageOneOf other) {
    _$v = other as _$WsServerMessageOneOf;
  }

  @override
  void update(void Function(WsServerMessageOneOfBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  WsServerMessageOneOf build() => _build();

  _$WsServerMessageOneOf _build() {
    _$WsServerMessageOneOf _$result;
    try {
      _$result =
          _$v ??
          _$WsServerMessageOneOf._(
            event: event.build(),
            type: BuiltValueNullFieldError.checkNotNull(
              type,
              r'WsServerMessageOneOf',
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
          r'WsServerMessageOneOf',
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
