// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_interaction_one_of_questions_inner_options_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PendingInteractionOneOfQuestionsInnerOptionsInner
    extends PendingInteractionOneOfQuestionsInnerOptionsInner {
  @override
  final String description;
  @override
  final String label;

  factory _$PendingInteractionOneOfQuestionsInnerOptionsInner([
    void Function(PendingInteractionOneOfQuestionsInnerOptionsInnerBuilder)?
    updates,
  ]) =>
      (PendingInteractionOneOfQuestionsInnerOptionsInnerBuilder()
            ..update(updates))
          ._build();

  _$PendingInteractionOneOfQuestionsInnerOptionsInner._({
    required this.description,
    required this.label,
  }) : super._();
  @override
  PendingInteractionOneOfQuestionsInnerOptionsInner rebuild(
    void Function(PendingInteractionOneOfQuestionsInnerOptionsInnerBuilder)
    updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PendingInteractionOneOfQuestionsInnerOptionsInnerBuilder toBuilder() =>
      PendingInteractionOneOfQuestionsInnerOptionsInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PendingInteractionOneOfQuestionsInnerOptionsInner &&
        description == other.description &&
        label == other.label;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, label.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
            r'PendingInteractionOneOfQuestionsInnerOptionsInner',
          )
          ..add('description', description)
          ..add('label', label))
        .toString();
  }
}

class PendingInteractionOneOfQuestionsInnerOptionsInnerBuilder
    implements
        Builder<
          PendingInteractionOneOfQuestionsInnerOptionsInner,
          PendingInteractionOneOfQuestionsInnerOptionsInnerBuilder
        > {
  _$PendingInteractionOneOfQuestionsInnerOptionsInner? _$v;

  String? _description;
  String? get description => _$this._description;
  set description(String? description) => _$this._description = description;

  String? _label;
  String? get label => _$this._label;
  set label(String? label) => _$this._label = label;

  PendingInteractionOneOfQuestionsInnerOptionsInnerBuilder() {
    PendingInteractionOneOfQuestionsInnerOptionsInner._defaults(this);
  }

  PendingInteractionOneOfQuestionsInnerOptionsInnerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _description = $v.description;
      _label = $v.label;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PendingInteractionOneOfQuestionsInnerOptionsInner other) {
    _$v = other as _$PendingInteractionOneOfQuestionsInnerOptionsInner;
  }

  @override
  void update(
    void Function(PendingInteractionOneOfQuestionsInnerOptionsInnerBuilder)?
    updates,
  ) {
    if (updates != null) updates(this);
  }

  @override
  PendingInteractionOneOfQuestionsInnerOptionsInner build() => _build();

  _$PendingInteractionOneOfQuestionsInnerOptionsInner _build() {
    final _$result =
        _$v ??
        _$PendingInteractionOneOfQuestionsInnerOptionsInner._(
          description: BuiltValueNullFieldError.checkNotNull(
            description,
            r'PendingInteractionOneOfQuestionsInnerOptionsInner',
            'description',
          ),
          label: BuiltValueNullFieldError.checkNotNull(
            label,
            r'PendingInteractionOneOfQuestionsInnerOptionsInner',
            'label',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
