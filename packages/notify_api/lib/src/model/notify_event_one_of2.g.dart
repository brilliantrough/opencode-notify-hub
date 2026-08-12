// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notify_event_one_of2.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const NotifyEventOneOf2TypeEnum _$notifyEventOneOf2TypeEnum_actionResolved =
    const NotifyEventOneOf2TypeEnum._('actionResolved');

NotifyEventOneOf2TypeEnum _$notifyEventOneOf2TypeEnumValueOf(String name) {
  switch (name) {
    case 'actionResolved':
      return _$notifyEventOneOf2TypeEnum_actionResolved;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<NotifyEventOneOf2TypeEnum> _$notifyEventOneOf2TypeEnumValues =
    BuiltSet<NotifyEventOneOf2TypeEnum>(const <NotifyEventOneOf2TypeEnum>[
      _$notifyEventOneOf2TypeEnum_actionResolved,
    ]);

Serializer<NotifyEventOneOf2TypeEnum> _$notifyEventOneOf2TypeEnumSerializer =
    _$NotifyEventOneOf2TypeEnumSerializer();

class _$NotifyEventOneOf2TypeEnumSerializer
    implements PrimitiveSerializer<NotifyEventOneOf2TypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'actionResolved': 'action_resolved',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'action_resolved': 'actionResolved',
  };

  @override
  final Iterable<Type> types = const <Type>[NotifyEventOneOf2TypeEnum];
  @override
  final String wireName = 'NotifyEventOneOf2TypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    NotifyEventOneOf2TypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  NotifyEventOneOf2TypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => NotifyEventOneOf2TypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$NotifyEventOneOf2 extends NotifyEventOneOf2 {
  @override
  final String eventId;
  @override
  final DateTime occurredAt;
  @override
  final NotifyEventOneOf2Payload payload;
  @override
  final NotifyEventOneOfSession session;
  @override
  final NotifyEventOneOfSource source_;
  @override
  final NotifyEventOneOf2TypeEnum type;

  factory _$NotifyEventOneOf2([
    void Function(NotifyEventOneOf2Builder)? updates,
  ]) => (NotifyEventOneOf2Builder()..update(updates))._build();

  _$NotifyEventOneOf2._({
    required this.eventId,
    required this.occurredAt,
    required this.payload,
    required this.session,
    required this.source_,
    required this.type,
  }) : super._();
  @override
  NotifyEventOneOf2 rebuild(void Function(NotifyEventOneOf2Builder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  NotifyEventOneOf2Builder toBuilder() =>
      NotifyEventOneOf2Builder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NotifyEventOneOf2 &&
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
    return (newBuiltValueToStringHelper(r'NotifyEventOneOf2')
          ..add('eventId', eventId)
          ..add('occurredAt', occurredAt)
          ..add('payload', payload)
          ..add('session', session)
          ..add('source_', source_)
          ..add('type', type))
        .toString();
  }
}

class NotifyEventOneOf2Builder
    implements Builder<NotifyEventOneOf2, NotifyEventOneOf2Builder> {
  _$NotifyEventOneOf2? _$v;

  String? _eventId;
  String? get eventId => _$this._eventId;
  set eventId(String? eventId) => _$this._eventId = eventId;

  DateTime? _occurredAt;
  DateTime? get occurredAt => _$this._occurredAt;
  set occurredAt(DateTime? occurredAt) => _$this._occurredAt = occurredAt;

  NotifyEventOneOf2PayloadBuilder? _payload;
  NotifyEventOneOf2PayloadBuilder get payload =>
      _$this._payload ??= NotifyEventOneOf2PayloadBuilder();
  set payload(NotifyEventOneOf2PayloadBuilder? payload) =>
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

  NotifyEventOneOf2TypeEnum? _type;
  NotifyEventOneOf2TypeEnum? get type => _$this._type;
  set type(NotifyEventOneOf2TypeEnum? type) => _$this._type = type;

  NotifyEventOneOf2Builder() {
    NotifyEventOneOf2._defaults(this);
  }

  NotifyEventOneOf2Builder get _$this {
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
  void replace(NotifyEventOneOf2 other) {
    _$v = other as _$NotifyEventOneOf2;
  }

  @override
  void update(void Function(NotifyEventOneOf2Builder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  NotifyEventOneOf2 build() => _build();

  _$NotifyEventOneOf2 _build() {
    _$NotifyEventOneOf2 _$result;
    try {
      _$result =
          _$v ??
          _$NotifyEventOneOf2._(
            eventId: BuiltValueNullFieldError.checkNotNull(
              eventId,
              r'NotifyEventOneOf2',
              'eventId',
            ),
            occurredAt: BuiltValueNullFieldError.checkNotNull(
              occurredAt,
              r'NotifyEventOneOf2',
              'occurredAt',
            ),
            payload: payload.build(),
            session: session.build(),
            source_: source_.build(),
            type: BuiltValueNullFieldError.checkNotNull(
              type,
              r'NotifyEventOneOf2',
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
          r'NotifyEventOneOf2',
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
