// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notify_event_one_of1_payload_one_of_questions_inner_options_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInner
    extends NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInner {
  @override
  final String? description;
  @override
  final String label;

  factory _$NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInner([
    void Function(
      NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInnerBuilder,
    )?
    updates,
  ]) =>
      (NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInnerBuilder()
            ..update(updates))
          ._build();

  _$NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInner._({
    this.description,
    required this.label,
  }) : super._();
  @override
  NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInner rebuild(
    void Function(
      NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInnerBuilder,
    )
    updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInnerBuilder toBuilder() =>
      NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInnerBuilder()
        ..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInner &&
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
            r'NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInner',
          )
          ..add('description', description)
          ..add('label', label))
        .toString();
  }
}

class NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInnerBuilder
    implements
        Builder<
          NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInner,
          NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInnerBuilder
        > {
  _$NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInner? _$v;

  String? _description;
  String? get description => _$this._description;
  set description(String? description) => _$this._description = description;

  String? _label;
  String? get label => _$this._label;
  set label(String? label) => _$this._label = label;

  NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInnerBuilder() {
    NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInner._defaults(this);
  }

  NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInnerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _description = $v.description;
      _label = $v.label;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInner other) {
    _$v = other as _$NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInner;
  }

  @override
  void update(
    void Function(
      NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInnerBuilder,
    )?
    updates,
  ) {
    if (updates != null) updates(this);
  }

  @override
  NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInner build() => _build();

  _$NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInner _build() {
    final _$result =
        _$v ??
        _$NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInner._(
          description: description,
          label: BuiltValueNullFieldError.checkNotNull(
            label,
            r'NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInner',
            'label',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
