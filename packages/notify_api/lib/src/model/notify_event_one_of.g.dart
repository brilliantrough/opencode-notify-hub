// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notify_event_one_of.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const NotifyEventOneOfTypeEnum _$notifyEventOneOfTypeEnum_heartbeat =
    const NotifyEventOneOfTypeEnum._('heartbeat');

NotifyEventOneOfTypeEnum _$notifyEventOneOfTypeEnumValueOf(String name) {
  switch (name) {
    case 'heartbeat':
      return _$notifyEventOneOfTypeEnum_heartbeat;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<NotifyEventOneOfTypeEnum> _$notifyEventOneOfTypeEnumValues =
    BuiltSet<NotifyEventOneOfTypeEnum>(const <NotifyEventOneOfTypeEnum>[
      _$notifyEventOneOfTypeEnum_heartbeat,
    ]);

Serializer<NotifyEventOneOfTypeEnum> _$notifyEventOneOfTypeEnumSerializer =
    _$NotifyEventOneOfTypeEnumSerializer();

class _$NotifyEventOneOfTypeEnumSerializer
    implements PrimitiveSerializer<NotifyEventOneOfTypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'heartbeat': 'heartbeat',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'heartbeat': 'heartbeat',
  };

  @override
  final Iterable<Type> types = const <Type>[NotifyEventOneOfTypeEnum];
  @override
  final String wireName = 'NotifyEventOneOfTypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    NotifyEventOneOfTypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  NotifyEventOneOfTypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => NotifyEventOneOfTypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$NotifyEventOneOf extends NotifyEventOneOf {
  @override
  final String eventId;
  @override
  final DateTime occurredAt;
  @override
  final NotifyEventOneOfPayload payload;
  @override
  final NotifyEventOneOfSession session;
  @override
  final NotifyEventOneOfSource source_;
  @override
  final NotifyEventOneOfTypeEnum type;

  factory _$NotifyEventOneOf([
    void Function(NotifyEventOneOfBuilder)? updates,
  ]) => (NotifyEventOneOfBuilder()..update(updates))._build();

  _$NotifyEventOneOf._({
    required this.eventId,
    required this.occurredAt,
    required this.payload,
    required this.session,
    required this.source_,
    required this.type,
  }) : super._();
  @override
  NotifyEventOneOf rebuild(void Function(NotifyEventOneOfBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  NotifyEventOneOfBuilder toBuilder() =>
      NotifyEventOneOfBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NotifyEventOneOf &&
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
    return (newBuiltValueToStringHelper(r'NotifyEventOneOf')
          ..add('eventId', eventId)
          ..add('occurredAt', occurredAt)
          ..add('payload', payload)
          ..add('session', session)
          ..add('source_', source_)
          ..add('type', type))
        .toString();
  }
}

class NotifyEventOneOfBuilder
    implements Builder<NotifyEventOneOf, NotifyEventOneOfBuilder> {
  _$NotifyEventOneOf? _$v;

  String? _eventId;
  String? get eventId => _$this._eventId;
  set eventId(String? eventId) => _$this._eventId = eventId;

  DateTime? _occurredAt;
  DateTime? get occurredAt => _$this._occurredAt;
  set occurredAt(DateTime? occurredAt) => _$this._occurredAt = occurredAt;

  NotifyEventOneOfPayloadBuilder? _payload;
  NotifyEventOneOfPayloadBuilder get payload =>
      _$this._payload ??= NotifyEventOneOfPayloadBuilder();
  set payload(NotifyEventOneOfPayloadBuilder? payload) =>
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

  NotifyEventOneOfTypeEnum? _type;
  NotifyEventOneOfTypeEnum? get type => _$this._type;
  set type(NotifyEventOneOfTypeEnum? type) => _$this._type = type;

  NotifyEventOneOfBuilder() {
    NotifyEventOneOf._defaults(this);
  }

  NotifyEventOneOfBuilder get _$this {
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
  void replace(NotifyEventOneOf other) {
    _$v = other as _$NotifyEventOneOf;
  }

  @override
  void update(void Function(NotifyEventOneOfBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  NotifyEventOneOf build() => _build();

  _$NotifyEventOneOf _build() {
    _$NotifyEventOneOf _$result;
    try {
      _$result =
          _$v ??
          _$NotifyEventOneOf._(
            eventId: BuiltValueNullFieldError.checkNotNull(
              eventId,
              r'NotifyEventOneOf',
              'eventId',
            ),
            occurredAt: BuiltValueNullFieldError.checkNotNull(
              occurredAt,
              r'NotifyEventOneOf',
              'occurredAt',
            ),
            payload: payload.build(),
            session: session.build(),
            source_: source_.build(),
            type: BuiltValueNullFieldError.checkNotNull(
              type,
              r'NotifyEventOneOf',
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
          r'NotifyEventOneOf',
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
