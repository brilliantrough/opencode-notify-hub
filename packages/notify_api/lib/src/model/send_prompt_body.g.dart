// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'send_prompt_body.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SendPromptBody extends SendPromptBody {
  @override
  final String commandId;
  @override
  final String text;

  factory _$SendPromptBody([void Function(SendPromptBodyBuilder)? updates]) =>
      (SendPromptBodyBuilder()..update(updates))._build();

  _$SendPromptBody._({required this.commandId, required this.text}) : super._();
  @override
  SendPromptBody rebuild(void Function(SendPromptBodyBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SendPromptBodyBuilder toBuilder() => SendPromptBodyBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SendPromptBody &&
        commandId == other.commandId &&
        text == other.text;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, commandId.hashCode);
    _$hash = $jc(_$hash, text.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SendPromptBody')
          ..add('commandId', commandId)
          ..add('text', text))
        .toString();
  }
}

class SendPromptBodyBuilder
    implements Builder<SendPromptBody, SendPromptBodyBuilder> {
  _$SendPromptBody? _$v;

  String? _commandId;
  String? get commandId => _$this._commandId;
  set commandId(String? commandId) => _$this._commandId = commandId;

  String? _text;
  String? get text => _$this._text;
  set text(String? text) => _$this._text = text;

  SendPromptBodyBuilder() {
    SendPromptBody._defaults(this);
  }

  SendPromptBodyBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _commandId = $v.commandId;
      _text = $v.text;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SendPromptBody other) {
    _$v = other as _$SendPromptBody;
  }

  @override
  void update(void Function(SendPromptBodyBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SendPromptBody build() => _build();

  _$SendPromptBody _build() {
    final _$result =
        _$v ??
        _$SendPromptBody._(
          commandId: BuiltValueNullFieldError.checkNotNull(
            commandId,
            r'SendPromptBody',
            'commandId',
          ),
          text: BuiltValueNullFieldError.checkNotNull(
            text,
            r'SendPromptBody',
            'text',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
