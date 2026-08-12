// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notify_event_one_of1.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const NotifyEventOneOf1TypeEnum _$notifyEventOneOf1TypeEnum_actionRequired =
    const NotifyEventOneOf1TypeEnum._('actionRequired');

NotifyEventOneOf1TypeEnum _$notifyEventOneOf1TypeEnumValueOf(String name) {
  switch (name) {
    case 'actionRequired':
      return _$notifyEventOneOf1TypeEnum_actionRequired;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<NotifyEventOneOf1TypeEnum> _$notifyEventOneOf1TypeEnumValues =
    BuiltSet<NotifyEventOneOf1TypeEnum>(const <NotifyEventOneOf1TypeEnum>[
      _$notifyEventOneOf1TypeEnum_actionRequired,
    ]);

Serializer<NotifyEventOneOf1TypeEnum> _$notifyEventOneOf1TypeEnumSerializer =
    _$NotifyEventOneOf1TypeEnumSerializer();

class _$NotifyEventOneOf1TypeEnumSerializer
    implements PrimitiveSerializer<NotifyEventOneOf1TypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'actionRequired': 'action_required',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'action_required': 'actionRequired',
  };

  @override
  final Iterable<Type> types = const <Type>[NotifyEventOneOf1TypeEnum];
  @override
  final String wireName = 'NotifyEventOneOf1TypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    NotifyEventOneOf1TypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  NotifyEventOneOf1TypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => NotifyEventOneOf1TypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$NotifyEventOneOf1 extends NotifyEventOneOf1 {
  @override
  final String eventId;
  @override
  final DateTime occurredAt;
  @override
  final NotifyEventOneOf1Payload payload;
  @override
  final NotifyEventOneOfSession session;
  @override
  final NotifyEventOneOfSource source_;
  @override
  final NotifyEventOneOf1TypeEnum type;

  factory _$NotifyEventOneOf1([
    void Function(NotifyEventOneOf1Builder)? updates,
  ]) => (NotifyEventOneOf1Builder()..update(updates))._build();

  _$NotifyEventOneOf1._({
    required this.eventId,
    required this.occurredAt,
    required this.payload,
    required this.session,
    required this.source_,
    required this.type,
  }) : super._();
  @override
  NotifyEventOneOf1 rebuild(void Function(NotifyEventOneOf1Builder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  NotifyEventOneOf1Builder toBuilder() =>
      NotifyEventOneOf1Builder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NotifyEventOneOf1 &&
        eventId == other.eventId &&
        occurredAt == other.occurredAt &&
        payload == other.payload &&
        session == other.session &&
        source_ == other.source_ &&
        type == other.type;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, eventId.hashCode);
    _$hash = $jc(_$hash, occurredAt.hashCode);
    _$hash = $jc(_$hash, payload.hashCode);
    _$hash = $jc(_$hash, session.hashCode);
    _$hash = $jc(_$hash, source_.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'NotifyEventOneOf1')
          ..add('eventId', eventId)
          ..add('occurredAt', occurredAt)
          ..add('payload', payload)
          ..add('session', session)
          ..add('source_', source_)
          ..add('type', type))
        .toString();
  }
}

class NotifyEventOneOf1Builder
    implements Builder<NotifyEventOneOf1, NotifyEventOneOf1Builder> {
  _$NotifyEventOneOf1? _$v;

  String? _eventId;
  String? get eventId => _$this._eventId;
  set eventId(String? eventId) => _$this._eventId = eventId;

  DateTime? _occurredAt;
  DateTime? get occurredAt => _$this._occurredAt;
  set occurredAt(DateTime? occurredAt) => _$this._occurredAt = occurredAt;

  NotifyEventOneOf1PayloadBuilder? _payload;
  NotifyEventOneOf1PayloadBuilder get payload =>
      _$this._payload ??= NotifyEventOneOf1PayloadBuilder();
  set payload(NotifyEventOneOf1PayloadBuilder? payload) =>
      _$this._payload = payload;

  NotifyEventOneOfSessionBuilder? _session;
  NotifyEventOneOfSessionBuilder get session =>
      _$this._session ??= NotifyEventOneOfSessionBuilder();
  set session(NotifyEventOneOfSessionBuilder? session) =>
      _$this._session = session;

  NotifyEventOneOfSourceBuilder? _source_;
  NotifyEventOneOfSourceBuilder get source_ =>
      _$this._source_ ??= NotifyEventOneOfSourceBuilder();
  set source_(NotifyEventOneOfSourceBuilder? source_) =>
      _$this._source_ = source_;

  NotifyEventOneOf1TypeEnum? _type;
  NotifyEventOneOf1TypeEnum? get type => _$this._type;
  set type(NotifyEventOneOf1TypeEnum? type) => _$this._type = type;

  NotifyEventOneOf1Builder() {
    NotifyEventOneOf1._defaults(this);
  }

  NotifyEventOneOf1Builder get _$this {
    final $v = _$v;
    if ($v != null) {
      _eventId = $v.eventId;
      _occurredAt = $v.occurredAt;
      _payload = $v.payload.toBuilder();
      _session = $v.session.toBuilder();
      _source_ = $v.source_.toBuilder();
      _type = $v.type;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(NotifyEventOneOf1 other) {
    _$v = other as _$NotifyEventOneOf1;
  }

  @override
  void update(void Function(NotifyEventOneOf1Builder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  NotifyEventOneOf1 build() => _build();

  _$NotifyEventOneOf1 _build() {
    _$NotifyEventOneOf1 _$result;
    try {
      _$result =
          _$v ??
          _$NotifyEventOneOf1._(
            eventId: BuiltValueNullFieldError.checkNotNull(
              eventId,
              r'NotifyEventOneOf1',
              'eventId',
            ),
            occurredAt: BuiltValueNullFieldError.checkNotNull(
              occurredAt,
              r'NotifyEventOneOf1',
              'occurredAt',
            ),
            payload: payload.build(),
            session: session.build(),
            source_: source_.build(),
            type: BuiltValueNullFieldError.checkNotNull(
              type,
              r'NotifyEventOneOf1',
              'type',
            ),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'payload';
        payload.build();
        _$failedField = 'session';
        session.build();
        _$failedField = 'source_';
        source_.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'NotifyEventOneOf1',
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
