// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notify_event.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const NotifyEventTypeEnum _$notifyEventTypeEnum_heartbeat =
    const NotifyEventTypeEnum._('heartbeat');
const NotifyEventTypeEnum _$notifyEventTypeEnum_actionRequired =
    const NotifyEventTypeEnum._('actionRequired');
const NotifyEventTypeEnum _$notifyEventTypeEnum_actionResolved =
    const NotifyEventTypeEnum._('actionResolved');
const NotifyEventTypeEnum _$notifyEventTypeEnum_terminal =
    const NotifyEventTypeEnum._('terminal');

NotifyEventTypeEnum _$notifyEventTypeEnumValueOf(String name) {
  switch (name) {
    case 'heartbeat':
      return _$notifyEventTypeEnum_heartbeat;
    case 'actionRequired':
      return _$notifyEventTypeEnum_actionRequired;
    case 'actionResolved':
      return _$notifyEventTypeEnum_actionResolved;
    case 'terminal':
      return _$notifyEventTypeEnum_terminal;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<NotifyEventTypeEnum> _$notifyEventTypeEnumValues =
    BuiltSet<NotifyEventTypeEnum>(const <NotifyEventTypeEnum>[
      _$notifyEventTypeEnum_heartbeat,
      _$notifyEventTypeEnum_actionRequired,
      _$notifyEventTypeEnum_actionResolved,
      _$notifyEventTypeEnum_terminal,
    ]);

Serializer<NotifyEventTypeEnum> _$notifyEventTypeEnumSerializer =
    _$NotifyEventTypeEnumSerializer();

class _$NotifyEventTypeEnumSerializer
    implements PrimitiveSerializer<NotifyEventTypeEnum> {
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
  final Iterable<Type> types = const <Type>[NotifyEventTypeEnum];
  @override
  final String wireName = 'NotifyEventTypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    NotifyEventTypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  NotifyEventTypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => NotifyEventTypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$NotifyEvent extends NotifyEvent {
  @override
  final OneOf oneOf;

  factory _$NotifyEvent([void Function(NotifyEventBuilder)? updates]) =>
      (NotifyEventBuilder()..update(updates))._build();

  _$NotifyEvent._({required this.oneOf}) : super._();
  @override
  NotifyEvent rebuild(void Function(NotifyEventBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  NotifyEventBuilder toBuilder() => NotifyEventBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NotifyEvent && oneOf == other.oneOf;
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
      r'NotifyEvent',
    )..add('oneOf', oneOf)).toString();
  }
}

class NotifyEventBuilder implements Builder<NotifyEvent, NotifyEventBuilder> {
  _$NotifyEvent? _$v;

  OneOf? _oneOf;
  OneOf? get oneOf => _$this._oneOf;
  set oneOf(OneOf? oneOf) => _$this._oneOf = oneOf;

  NotifyEventBuilder() {
    NotifyEvent._defaults(this);
  }

  NotifyEventBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _oneOf = $v.oneOf;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(NotifyEvent other) {
    _$v = other as _$NotifyEvent;
  }

  @override
  void update(void Function(NotifyEventBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  NotifyEvent build() => _build();

  _$NotifyEvent _build() {
    final _$result =
        _$v ??
        _$NotifyEvent._(
          oneOf: BuiltValueNullFieldError.checkNotNull(
            oneOf,
            r'NotifyEvent',
            'oneOf',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
