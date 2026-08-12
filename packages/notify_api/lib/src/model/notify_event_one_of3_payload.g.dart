// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notify_event_one_of3_payload.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const NotifyEventOneOf3PayloadOutcomeEnum
_$notifyEventOneOf3PayloadOutcomeEnum_completed =
    const NotifyEventOneOf3PayloadOutcomeEnum._('completed');
const NotifyEventOneOf3PayloadOutcomeEnum
_$notifyEventOneOf3PayloadOutcomeEnum_failed =
    const NotifyEventOneOf3PayloadOutcomeEnum._('failed');
const NotifyEventOneOf3PayloadOutcomeEnum
_$notifyEventOneOf3PayloadOutcomeEnum_stopped =
    const NotifyEventOneOf3PayloadOutcomeEnum._('stopped');

NotifyEventOneOf3PayloadOutcomeEnum
_$notifyEventOneOf3PayloadOutcomeEnumValueOf(String name) {
  switch (name) {
    case 'completed':
      return _$notifyEventOneOf3PayloadOutcomeEnum_completed;
    case 'failed':
      return _$notifyEventOneOf3PayloadOutcomeEnum_failed;
    case 'stopped':
      return _$notifyEventOneOf3PayloadOutcomeEnum_stopped;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<NotifyEventOneOf3PayloadOutcomeEnum>
_$notifyEventOneOf3PayloadOutcomeEnumValues =
    BuiltSet<NotifyEventOneOf3PayloadOutcomeEnum>(
      const <NotifyEventOneOf3PayloadOutcomeEnum>[
        _$notifyEventOneOf3PayloadOutcomeEnum_completed,
        _$notifyEventOneOf3PayloadOutcomeEnum_failed,
        _$notifyEventOneOf3PayloadOutcomeEnum_stopped,
      ],
    );

Serializer<NotifyEventOneOf3PayloadOutcomeEnum>
_$notifyEventOneOf3PayloadOutcomeEnumSerializer =
    _$NotifyEventOneOf3PayloadOutcomeEnumSerializer();

class _$NotifyEventOneOf3PayloadOutcomeEnumSerializer
    implements PrimitiveSerializer<NotifyEventOneOf3PayloadOutcomeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'completed': 'completed',
    'failed': 'failed',
    'stopped': 'stopped',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'completed': 'completed',
    'failed': 'failed',
    'stopped': 'stopped',
  };

  @override
  final Iterable<Type> types = const <Type>[
    NotifyEventOneOf3PayloadOutcomeEnum,
  ];
  @override
  final String wireName = 'NotifyEventOneOf3PayloadOutcomeEnum';

  @override
  Object serialize(
    Serializers serializers,
    NotifyEventOneOf3PayloadOutcomeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  NotifyEventOneOf3PayloadOutcomeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => NotifyEventOneOf3PayloadOutcomeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$NotifyEventOneOf3Payload extends NotifyEventOneOf3Payload {
  @override
  final int elapsedSeconds;
  @override
  final NotifyEventOneOf3PayloadOutcomeEnum outcome;
  @override
  final String? summary;

  factory _$NotifyEventOneOf3Payload([
    void Function(NotifyEventOneOf3PayloadBuilder)? updates,
  ]) => (NotifyEventOneOf3PayloadBuilder()..update(updates))._build();

  _$NotifyEventOneOf3Payload._({
    required this.elapsedSeconds,
    required this.outcome,
    this.summary,
  }) : super._();
  @override
  NotifyEventOneOf3Payload rebuild(
    void Function(NotifyEventOneOf3PayloadBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  NotifyEventOneOf3PayloadBuilder toBuilder() =>
      NotifyEventOneOf3PayloadBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NotifyEventOneOf3Payload &&
        elapsedSeconds == other.elapsedSeconds &&
        outcome == other.outcome &&
        summary == other.summary;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, elapsedSeconds.hashCode);
    _$hash = $jc(_$hash, outcome.hashCode);
    _$hash = $jc(_$hash, summary.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'NotifyEventOneOf3Payload')
          ..add('elapsedSeconds', elapsedSeconds)
          ..add('outcome', outcome)
          ..add('summary', summary))
        .toString();
  }
}

class NotifyEventOneOf3PayloadBuilder
    implements
        Builder<NotifyEventOneOf3Payload, NotifyEventOneOf3PayloadBuilder> {
  _$NotifyEventOneOf3Payload? _$v;

  int? _elapsedSeconds;
  int? get elapsedSeconds => _$this._elapsedSeconds;
  set elapsedSeconds(int? elapsedSeconds) =>
      _$this._elapsedSeconds = elapsedSeconds;

  NotifyEventOneOf3PayloadOutcomeEnum? _outcome;
  NotifyEventOneOf3PayloadOutcomeEnum? get outcome => _$this._outcome;
  set outcome(NotifyEventOneOf3PayloadOutcomeEnum? outcome) =>
      _$this._outcome = outcome;

  String? _summary;
  String? get summary => _$this._summary;
  set summary(String? summary) => _$this._summary = summary;

  NotifyEventOneOf3PayloadBuilder() {
    NotifyEventOneOf3Payload._defaults(this);
  }

  NotifyEventOneOf3PayloadBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _elapsedSeconds = $v.elapsedSeconds;
      _outcome = $v.outcome;
      _summary = $v.summary;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(NotifyEventOneOf3Payload other) {
    _$v = other as _$NotifyEventOneOf3Payload;
  }

  @override
  void update(void Function(NotifyEventOneOf3PayloadBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  NotifyEventOneOf3Payload build() => _build();

  _$NotifyEventOneOf3Payload _build() {
    final _$result =
        _$v ??
        _$NotifyEventOneOf3Payload._(
          elapsedSeconds: BuiltValueNullFieldError.checkNotNull(
            elapsedSeconds,
            r'NotifyEventOneOf3Payload',
            'elapsedSeconds',
          ),
          outcome: BuiltValueNullFieldError.checkNotNull(
            outcome,
            r'NotifyEventOneOf3Payload',
            'outcome',
          ),
          summary: summary,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
