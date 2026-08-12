// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notify_event_one_of1_payload_one_of_questions_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$NotifyEventOneOf1PayloadOneOfQuestionsInner
    extends NotifyEventOneOf1PayloadOneOfQuestionsInner {
  @override
  final bool? multiple;
  @override
  final BuiltList<NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInner>?
  options;
  @override
  final String question;

  factory _$NotifyEventOneOf1PayloadOneOfQuestionsInner([
    void Function(NotifyEventOneOf1PayloadOneOfQuestionsInnerBuilder)? updates,
  ]) => (NotifyEventOneOf1PayloadOneOfQuestionsInnerBuilder()..update(updates))
      ._build();

  _$NotifyEventOneOf1PayloadOneOfQuestionsInner._({
    this.multiple,
    this.options,
    required this.question,
  }) : super._();
  @override
  NotifyEventOneOf1PayloadOneOfQuestionsInner rebuild(
    void Function(NotifyEventOneOf1PayloadOneOfQuestionsInnerBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  NotifyEventOneOf1PayloadOneOfQuestionsInnerBuilder toBuilder() =>
      NotifyEventOneOf1PayloadOneOfQuestionsInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NotifyEventOneOf1PayloadOneOfQuestionsInner &&
        multiple == other.multiple &&
        options == other.options &&
        question == other.question;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, multiple.hashCode);
    _$hash = $jc(_$hash, options.hashCode);
    _$hash = $jc(_$hash, question.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
            r'NotifyEventOneOf1PayloadOneOfQuestionsInner',
          )
          ..add('multiple', multiple)
          ..add('options', options)
          ..add('question', question))
        .toString();
  }
}

class NotifyEventOneOf1PayloadOneOfQuestionsInnerBuilder
    implements
        Builder<
          NotifyEventOneOf1PayloadOneOfQuestionsInner,
          NotifyEventOneOf1PayloadOneOfQuestionsInnerBuilder
        > {
  _$NotifyEventOneOf1PayloadOneOfQuestionsInner? _$v;

  bool? _multiple;
  bool? get multiple => _$this._multiple;
  set multiple(bool? multiple) => _$this._multiple = multiple;

  ListBuilder<NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInner>?
  _options;
  ListBuilder<NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInner>
  get options => _$this._options ??=
      ListBuilder<NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInner>();
  set options(
    ListBuilder<NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInner>?
    options,
  ) => _$this._options = options;

  String? _question;
  String? get question => _$this._question;
  set question(String? question) => _$this._question = question;

  NotifyEventOneOf1PayloadOneOfQuestionsInnerBuilder() {
    NotifyEventOneOf1PayloadOneOfQuestionsInner._defaults(this);
  }

  NotifyEventOneOf1PayloadOneOfQuestionsInnerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _multiple = $v.multiple;
      _options = $v.options?.toBuilder();
      _question = $v.question;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(NotifyEventOneOf1PayloadOneOfQuestionsInner other) {
    _$v = other as _$NotifyEventOneOf1PayloadOneOfQuestionsInner;
  }

  @override
  void update(
    void Function(NotifyEventOneOf1PayloadOneOfQuestionsInnerBuilder)? updates,
  ) {
    if (updates != null) updates(this);
  }

  @override
  NotifyEventOneOf1PayloadOneOfQuestionsInner build() => _build();

  _$NotifyEventOneOf1PayloadOneOfQuestionsInner _build() {
    _$NotifyEventOneOf1PayloadOneOfQuestionsInner _$result;
    try {
      _$result =
          _$v ??
          _$NotifyEventOneOf1PayloadOneOfQuestionsInner._(
            multiple: multiple,
            options: _options?.build(),
            question: BuiltValueNullFieldError.checkNotNull(
              question,
              r'NotifyEventOneOf1PayloadOneOfQuestionsInner',
              'question',
            ),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'options';
        _options?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'NotifyEventOneOf1PayloadOneOfQuestionsInner',
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
