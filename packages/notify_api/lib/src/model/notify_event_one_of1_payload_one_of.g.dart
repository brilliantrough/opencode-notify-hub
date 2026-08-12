// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notify_event_one_of1_payload_one_of.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const NotifyEventOneOf1PayloadOneOfKindEnum
_$notifyEventOneOf1PayloadOneOfKindEnum_question =
    const NotifyEventOneOf1PayloadOneOfKindEnum._('question');

NotifyEventOneOf1PayloadOneOfKindEnum
_$notifyEventOneOf1PayloadOneOfKindEnumValueOf(String name) {
  switch (name) {
    case 'question':
      return _$notifyEventOneOf1PayloadOneOfKindEnum_question;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<NotifyEventOneOf1PayloadOneOfKindEnum>
_$notifyEventOneOf1PayloadOneOfKindEnumValues =
    BuiltSet<NotifyEventOneOf1PayloadOneOfKindEnum>(
      const <NotifyEventOneOf1PayloadOneOfKindEnum>[
        _$notifyEventOneOf1PayloadOneOfKindEnum_question,
      ],
    );

Serializer<NotifyEventOneOf1PayloadOneOfKindEnum>
_$notifyEventOneOf1PayloadOneOfKindEnumSerializer =
    _$NotifyEventOneOf1PayloadOneOfKindEnumSerializer();

class _$NotifyEventOneOf1PayloadOneOfKindEnumSerializer
    implements PrimitiveSerializer<NotifyEventOneOf1PayloadOneOfKindEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'question': 'question',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'question': 'question',
  };

  @override
  final Iterable<Type> types = const <Type>[
    NotifyEventOneOf1PayloadOneOfKindEnum,
  ];
  @override
  final String wireName = 'NotifyEventOneOf1PayloadOneOfKindEnum';

  @override
  Object serialize(
    Serializers serializers,
    NotifyEventOneOf1PayloadOneOfKindEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  NotifyEventOneOf1PayloadOneOfKindEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => NotifyEventOneOf1PayloadOneOfKindEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$NotifyEventOneOf1PayloadOneOf extends NotifyEventOneOf1PayloadOneOf {
  @override
  final NotifyEventOneOf1PayloadOneOfKindEnum kind;
  @override
  final BuiltList<NotifyEventOneOf1PayloadOneOfQuestionsInner> questions;
  @override
  final String requestId;

  factory _$NotifyEventOneOf1PayloadOneOf([
    void Function(NotifyEventOneOf1PayloadOneOfBuilder)? updates,
  ]) => (NotifyEventOneOf1PayloadOneOfBuilder()..update(updates))._build();

  _$NotifyEventOneOf1PayloadOneOf._({
    required this.kind,
    required this.questions,
    required this.requestId,
  }) : super._();
  @override
  NotifyEventOneOf1PayloadOneOf rebuild(
    void Function(NotifyEventOneOf1PayloadOneOfBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  NotifyEventOneOf1PayloadOneOfBuilder toBuilder() =>
      NotifyEventOneOf1PayloadOneOfBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NotifyEventOneOf1PayloadOneOf &&
        kind == other.kind &&
        questions == other.questions &&
        requestId == other.requestId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, kind.hashCode);
    _$hash = $jc(_$hash, questions.hashCode);
    _$hash = $jc(_$hash, requestId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'NotifyEventOneOf1PayloadOneOf')
          ..add('kind', kind)
          ..add('questions', questions)
          ..add('requestId', requestId))
        .toString();
  }
}

class NotifyEventOneOf1PayloadOneOfBuilder
    implements
        Builder<
          NotifyEventOneOf1PayloadOneOf,
          NotifyEventOneOf1PayloadOneOfBuilder
        > {
  _$NotifyEventOneOf1PayloadOneOf? _$v;

  NotifyEventOneOf1PayloadOneOfKindEnum? _kind;
  NotifyEventOneOf1PayloadOneOfKindEnum? get kind => _$this._kind;
  set kind(NotifyEventOneOf1PayloadOneOfKindEnum? kind) => _$this._kind = kind;

  ListBuilder<NotifyEventOneOf1PayloadOneOfQuestionsInner>? _questions;
  ListBuilder<NotifyEventOneOf1PayloadOneOfQuestionsInner> get questions =>
      _$this._questions ??=
          ListBuilder<NotifyEventOneOf1PayloadOneOfQuestionsInner>();
  set questions(
    ListBuilder<NotifyEventOneOf1PayloadOneOfQuestionsInner>? questions,
  ) => _$this._questions = questions;

  String? _requestId;
  String? get requestId => _$this._requestId;
  set requestId(String? requestId) => _$this._requestId = requestId;

  NotifyEventOneOf1PayloadOneOfBuilder() {
    NotifyEventOneOf1PayloadOneOf._defaults(this);
  }

  NotifyEventOneOf1PayloadOneOfBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _kind = $v.kind;
      _questions = $v.questions.toBuilder();
      _requestId = $v.requestId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(NotifyEventOneOf1PayloadOneOf other) {
    _$v = other as _$NotifyEventOneOf1PayloadOneOf;
  }

  @override
  void update(void Function(NotifyEventOneOf1PayloadOneOfBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  NotifyEventOneOf1PayloadOneOf build() => _build();

  _$NotifyEventOneOf1PayloadOneOf _build() {
    _$NotifyEventOneOf1PayloadOneOf _$result;
    try {
      _$result =
          _$v ??
          _$NotifyEventOneOf1PayloadOneOf._(
            kind: BuiltValueNullFieldError.checkNotNull(
              kind,
              r'NotifyEventOneOf1PayloadOneOf',
              'kind',
            ),
            questions: questions.build(),
            requestId: BuiltValueNullFieldError.checkNotNull(
              requestId,
              r'NotifyEventOneOf1PayloadOneOf',
              'requestId',
            ),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'questions';
        questions.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'NotifyEventOneOf1PayloadOneOf',
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
