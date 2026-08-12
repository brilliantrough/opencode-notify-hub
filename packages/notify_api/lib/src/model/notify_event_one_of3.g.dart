// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notify_event_one_of3.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const NotifyEventOneOf3TypeEnum _$notifyEventOneOf3TypeEnum_terminal =
    const NotifyEventOneOf3TypeEnum._('terminal');

NotifyEventOneOf3TypeEnum _$notifyEventOneOf3TypeEnumValueOf(String name) {
  switch (name) {
    case 'terminal':
      return _$notifyEventOneOf3TypeEnum_terminal;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<NotifyEventOneOf3TypeEnum> _$notifyEventOneOf3TypeEnumValues =
    BuiltSet<NotifyEventOneOf3TypeEnum>(const <NotifyEventOneOf3TypeEnum>[
      _$notifyEventOneOf3TypeEnum_terminal,
    ]);

Serializer<NotifyEventOneOf3TypeEnum> _$notifyEventOneOf3TypeEnumSerializer =
    _$NotifyEventOneOf3TypeEnumSerializer();

class _$NotifyEventOneOf3TypeEnumSerializer
    implements PrimitiveSerializer<NotifyEventOneOf3TypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'terminal': 'terminal',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'terminal': 'terminal',
  };

  @override
  final Iterable<Type> types = const <Type>[NotifyEventOneOf3TypeEnum];
  @override
  final String wireName = 'NotifyEventOneOf3TypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    NotifyEventOneOf3TypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  NotifyEventOneOf3TypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => NotifyEventOneOf3TypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$NotifyEventOneOf3 extends NotifyEventOneOf3 {
  @override
  final String eventId;
  @override
  final DateTime occurredAt;
  @override
  final NotifyEventOneOf3Payload payload;
  @override
  final NotifyEventOneOfSession session;
  @override
  final NotifyEventOneOfSource source_;
  @override
  final NotifyEventOneOf3TypeEnum type;

  factory _$NotifyEventOneOf3([
    void Function(NotifyEventOneOf3Builder)? updates,
  ]) => (NotifyEventOneOf3Builder()..update(updates))._build();

  _$NotifyEventOneOf3._({
    required this.eventId,
    required this.occurredAt,
    required this.payload,
    required this.session,
    required this.source_,
    required this.type,
  }) : super._();
  @override
  NotifyEventOneOf3 rebuild(void Function(NotifyEventOneOf3Builder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  NotifyEventOneOf3Builder toBuilder() =>
      NotifyEventOneOf3Builder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NotifyEventOneOf3 &&
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
    return (newBuiltValueToStringHelper(r'NotifyEventOneOf3')
          ..add('eventId', eventId)
          ..add('occurredAt', occurredAt)
          ..add('payload', payload)
          ..add('session', session)
          ..add('source_', source_)
          ..add('type', type))
        .toString();
  }
}

class NotifyEventOneOf3Builder
    implements Builder<NotifyEventOneOf3, NotifyEventOneOf3Builder> {
  _$NotifyEventOneOf3? _$v;

  String? _eventId;
  String? get eventId => _$this._eventId;
  set eventId(String? eventId) => _$this._eventId = eventId;

  DateTime? _occurredAt;
  DateTime? get occurredAt => _$this._occurredAt;
  set occurredAt(DateTime? occurredAt) => _$this._occurredAt = occurredAt;

  NotifyEventOneOf3PayloadBuilder? _payload;
  NotifyEventOneOf3PayloadBuilder get payload =>
      _$this._payload ??= NotifyEventOneOf3PayloadBuilder();
  set payload(NotifyEventOneOf3PayloadBuilder? payload) =>
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

  NotifyEventOneOf3TypeEnum? _type;
  NotifyEventOneOf3TypeEnum? get type => _$this._type;
  set type(NotifyEventOneOf3TypeEnum? type) => _$this._type = type;

  NotifyEventOneOf3Builder() {
    NotifyEventOneOf3._defaults(this);
  }

  NotifyEventOneOf3Builder get _$this {
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
  void replace(NotifyEventOneOf3 other) {
    _$v = other as _$NotifyEventOneOf3;
  }

  @override
  void update(void Function(NotifyEventOneOf3Builder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  NotifyEventOneOf3 build() => _build();

  _$NotifyEventOneOf3 _build() {
    _$NotifyEventOneOf3 _$result;
    try {
      _$result =
          _$v ??
          _$NotifyEventOneOf3._(
            eventId: BuiltValueNullFieldError.checkNotNull(
              eventId,
              r'NotifyEventOneOf3',
              'eventId',
            ),
            occurredAt: BuiltValueNullFieldError.checkNotNull(
              occurredAt,
              r'NotifyEventOneOf3',
              'occurredAt',
            ),
            payload: payload.build(),
            session: session.build(),
            source_: source_.build(),
            type: BuiltValueNullFieldError.checkNotNull(
              type,
              r'NotifyEventOneOf3',
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
          r'NotifyEventOneOf3',
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
