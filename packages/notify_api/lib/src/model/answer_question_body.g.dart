// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'answer_question_body.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AnswerQuestionBody extends AnswerQuestionBody {
  @override
  final BuiltList<BuiltList<String>> answers;
  @override
  final String commandId;

  factory _$AnswerQuestionBody([
    void Function(AnswerQuestionBodyBuilder)? updates,
  ]) => (AnswerQuestionBodyBuilder()..update(updates))._build();

  _$AnswerQuestionBody._({required this.answers, required this.commandId})
    : super._();
  @override
  AnswerQuestionBody rebuild(
    void Function(AnswerQuestionBodyBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  AnswerQuestionBodyBuilder toBuilder() =>
      AnswerQuestionBodyBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AnswerQuestionBody &&
        answers == other.answers &&
        commandId == other.commandId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, answers.hashCode);
    _$hash = $jc(_$hash, commandId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AnswerQuestionBody')
          ..add('answers', answers)
          ..add('commandId', commandId))
        .toString();
  }
}

class AnswerQuestionBodyBuilder
    implements Builder<AnswerQuestionBody, AnswerQuestionBodyBuilder> {
  _$AnswerQuestionBody? _$v;

  ListBuilder<BuiltList<String>>? _answers;
  ListBuilder<BuiltList<String>> get answers =>
      _$this._answers ??= ListBuilder<BuiltList<String>>();
  set answers(ListBuilder<BuiltList<String>>? answers) =>
      _$this._answers = answers;

  String? _commandId;
  String? get commandId => _$this._commandId;
  set commandId(String? commandId) => _$this._commandId = commandId;

  AnswerQuestionBodyBuilder() {
    AnswerQuestionBody._defaults(this);
  }

  AnswerQuestionBodyBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _answers = $v.answers.toBuilder();
      _commandId = $v.commandId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AnswerQuestionBody other) {
    _$v = other as _$AnswerQuestionBody;
  }

  @override
  void update(void Function(AnswerQuestionBodyBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AnswerQuestionBody build() => _build();

  _$AnswerQuestionBody _build() {
    _$AnswerQuestionBody _$result;
    try {
      _$result =
          _$v ??
          _$AnswerQuestionBody._(
            answers: answers.build(),
            commandId: BuiltValueNullFieldError.checkNotNull(
              commandId,
              r'AnswerQuestionBody',
              'commandId',
            ),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'answers';
        answers.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'AnswerQuestionBody',
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
