// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_interaction_one_of_questions_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PendingInteractionOneOfQuestionsInner
    extends PendingInteractionOneOfQuestionsInner {
  @override
  final bool custom;
  @override
  final String header;
  @override
  final bool multiple;
  @override
  final BuiltList<PendingInteractionOneOfQuestionsInnerOptionsInner> options;
  @override
  final String question;

  factory _$PendingInteractionOneOfQuestionsInner([
    void Function(PendingInteractionOneOfQuestionsInnerBuilder)? updates,
  ]) => (PendingInteractionOneOfQuestionsInnerBuilder()..update(updates))
      ._build();

  _$PendingInteractionOneOfQuestionsInner._({
    required this.custom,
    required this.header,
    required this.multiple,
    required this.options,
    required this.question,
  }) : super._();
  @override
  PendingInteractionOneOfQuestionsInner rebuild(
    void Function(PendingInteractionOneOfQuestionsInnerBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PendingInteractionOneOfQuestionsInnerBuilder toBuilder() =>
      PendingInteractionOneOfQuestionsInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PendingInteractionOneOfQuestionsInner &&
        custom == other.custom &&
        header == other.header &&
        multiple == other.multiple &&
        options == other.options &&
        question == other.question;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, custom.hashCode);
    _$hash = $jc(_$hash, header.hashCode);
    _$hash = $jc(_$hash, multiple.hashCode);
    _$hash = $jc(_$hash, options.hashCode);
    _$hash = $jc(_$hash, question.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
            r'PendingInteractionOneOfQuestionsInner',
          )
          ..add('custom', custom)
          ..add('header', header)
          ..add('multiple', multiple)
          ..add('options', options)
          ..add('question', question))
        .toString();
  }
}

class PendingInteractionOneOfQuestionsInnerBuilder
    implements
        Builder<
          PendingInteractionOneOfQuestionsInner,
          PendingInteractionOneOfQuestionsInnerBuilder
        > {
  _$PendingInteractionOneOfQuestionsInner? _$v;

  bool? _custom;
  bool? get custom => _$this._custom;
  set custom(bool? custom) => _$this._custom = custom;

  String? _header;
  String? get header => _$this._header;
  set header(String? header) => _$this._header = header;

  bool? _multiple;
  bool? get multiple => _$this._multiple;
  set multiple(bool? multiple) => _$this._multiple = multiple;

  ListBuilder<PendingInteractionOneOfQuestionsInnerOptionsInner>? _options;
  ListBuilder<PendingInteractionOneOfQuestionsInnerOptionsInner> get options =>
      _$this._options ??=
          ListBuilder<PendingInteractionOneOfQuestionsInnerOptionsInner>();
  set options(
    ListBuilder<PendingInteractionOneOfQuestionsInnerOptionsInner>? options,
  ) => _$this._options = options;

  String? _question;
  String? get question => _$this._question;
  set question(String? question) => _$this._question = question;

  PendingInteractionOneOfQuestionsInnerBuilder() {
    PendingInteractionOneOfQuestionsInner._defaults(this);
  }

  PendingInteractionOneOfQuestionsInnerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _custom = $v.custom;
      _header = $v.header;
      _multiple = $v.multiple;
      _options = $v.options.toBuilder();
      _question = $v.question;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PendingInteractionOneOfQuestionsInner other) {
    _$v = other as _$PendingInteractionOneOfQuestionsInner;
  }

  @override
  void update(
    void Function(PendingInteractionOneOfQuestionsInnerBuilder)? updates,
  ) {
    if (updates != null) updates(this);
  }

  @override
  PendingInteractionOneOfQuestionsInner build() => _build();

  _$PendingInteractionOneOfQuestionsInner _build() {
    _$PendingInteractionOneOfQuestionsInner _$result;
    try {
      _$result =
          _$v ??
          _$PendingInteractionOneOfQuestionsInner._(
            custom: BuiltValueNullFieldError.checkNotNull(
              custom,
              r'PendingInteractionOneOfQuestionsInner',
              'custom',
            ),
            header: BuiltValueNullFieldError.checkNotNull(
              header,
              r'PendingInteractionOneOfQuestionsInner',
              'header',
            ),
            multiple: BuiltValueNullFieldError.checkNotNull(
              multiple,
              r'PendingInteractionOneOfQuestionsInner',
              'multiple',
            ),
            options: options.build(),
            question: BuiltValueNullFieldError.checkNotNull(
              question,
              r'PendingInteractionOneOfQuestionsInner',
              'question',
            ),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'options';
        options.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'PendingInteractionOneOfQuestionsInner',
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
