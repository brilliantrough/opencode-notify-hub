// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notify_event_one_of_payload.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const NotifyEventOneOfPayloadStatusEnum
_$notifyEventOneOfPayloadStatusEnum_busy =
    const NotifyEventOneOfPayloadStatusEnum._('busy');
const NotifyEventOneOfPayloadStatusEnum
_$notifyEventOneOfPayloadStatusEnum_retry =
    const NotifyEventOneOfPayloadStatusEnum._('retry');

NotifyEventOneOfPayloadStatusEnum _$notifyEventOneOfPayloadStatusEnumValueOf(
  String name,
) {
  switch (name) {
    case 'busy':
      return _$notifyEventOneOfPayloadStatusEnum_busy;
    case 'retry':
      return _$notifyEventOneOfPayloadStatusEnum_retry;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<NotifyEventOneOfPayloadStatusEnum>
_$notifyEventOneOfPayloadStatusEnumValues =
    BuiltSet<NotifyEventOneOfPayloadStatusEnum>(
      const <NotifyEventOneOfPayloadStatusEnum>[
        _$notifyEventOneOfPayloadStatusEnum_busy,
        _$notifyEventOneOfPayloadStatusEnum_retry,
      ],
    );

Serializer<NotifyEventOneOfPayloadStatusEnum>
_$notifyEventOneOfPayloadStatusEnumSerializer =
    _$NotifyEventOneOfPayloadStatusEnumSerializer();

class _$NotifyEventOneOfPayloadStatusEnumSerializer
    implements PrimitiveSerializer<NotifyEventOneOfPayloadStatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'busy': 'busy',
    'retry': 'retry',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'busy': 'busy',
    'retry': 'retry',
  };

  @override
  final Iterable<Type> types = const <Type>[NotifyEventOneOfPayloadStatusEnum];
  @override
  final String wireName = 'NotifyEventOneOfPayloadStatusEnum';

  @override
  Object serialize(
    Serializers serializers,
    NotifyEventOneOfPayloadStatusEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  NotifyEventOneOfPayloadStatusEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => NotifyEventOneOfPayloadStatusEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$NotifyEventOneOfPayload extends NotifyEventOneOfPayload {
  @override
  final int elapsedSeconds;
  @override
  final NotifyEventOneOfPayloadStatusEnum status;

  factory _$NotifyEventOneOfPayload([
    void Function(NotifyEventOneOfPayloadBuilder)? updates,
  ]) => (NotifyEventOneOfPayloadBuilder()..update(updates))._build();

  _$NotifyEventOneOfPayload._({
    required this.elapsedSeconds,
    required this.status,
  }) : super._();
  @override
  NotifyEventOneOfPayload rebuild(
    void Function(NotifyEventOneOfPayloadBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  NotifyEventOneOfPayloadBuilder toBuilder() =>
      NotifyEventOneOfPayloadBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NotifyEventOneOfPayload &&
        elapsedSeconds == other.elapsedSeconds &&
        status == other.status;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, elapsedSeconds.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'NotifyEventOneOfPayload')
          ..add('elapsedSeconds', elapsedSeconds)
          ..add('status', status))
        .toString();
  }
}

class NotifyEventOneOfPayloadBuilder
    implements
        Builder<NotifyEventOneOfPayload, NotifyEventOneOfPayloadBuilder> {
  _$NotifyEventOneOfPayload? _$v;

  int? _elapsedSeconds;
  int? get elapsedSeconds => _$this._elapsedSeconds;
  set elapsedSeconds(int? elapsedSeconds) =>
      _$this._elapsedSeconds = elapsedSeconds;

  NotifyEventOneOfPayloadStatusEnum? _status;
  NotifyEventOneOfPayloadStatusEnum? get status => _$this._status;
  set status(NotifyEventOneOfPayloadStatusEnum? status) =>
      _$this._status = status;

  NotifyEventOneOfPayloadBuilder() {
    NotifyEventOneOfPayload._defaults(this);
  }

  NotifyEventOneOfPayloadBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _elapsedSeconds = $v.elapsedSeconds;
      _status = $v.status;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(NotifyEventOneOfPayload other) {
    _$v = other as _$NotifyEventOneOfPayload;
  }

  @override
  void update(void Function(NotifyEventOneOfPayloadBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  NotifyEventOneOfPayload build() => _build();

  _$NotifyEventOneOfPayload _build() {
    final _$result =
        _$v ??
        _$NotifyEventOneOfPayload._(
          elapsedSeconds: BuiltValueNullFieldError.checkNotNull(
            elapsedSeconds,
            r'NotifyEventOneOfPayload',
            'elapsedSeconds',
          ),
          status: BuiltValueNullFieldError.checkNotNull(
            status,
            r'NotifyEventOneOfPayload',
            'status',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
