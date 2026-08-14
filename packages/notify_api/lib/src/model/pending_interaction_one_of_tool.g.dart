// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_interaction_one_of_tool.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PendingInteractionOneOfTool extends PendingInteractionOneOfTool {
  @override
  final String callId;
  @override
  final String messageId;

  factory _$PendingInteractionOneOfTool([
    void Function(PendingInteractionOneOfToolBuilder)? updates,
  ]) => (PendingInteractionOneOfToolBuilder()..update(updates))._build();

  _$PendingInteractionOneOfTool._({
    required this.callId,
    required this.messageId,
  }) : super._();
  @override
  PendingInteractionOneOfTool rebuild(
    void Function(PendingInteractionOneOfToolBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PendingInteractionOneOfToolBuilder toBuilder() =>
      PendingInteractionOneOfToolBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PendingInteractionOneOfTool &&
        callId == other.callId &&
        messageId == other.messageId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, callId.hashCode);
    _$hash = $jc(_$hash, messageId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PendingInteractionOneOfTool')
          ..add('callId', callId)
          ..add('messageId', messageId))
        .toString();
  }
}

class PendingInteractionOneOfToolBuilder
    implements
        Builder<
          PendingInteractionOneOfTool,
          PendingInteractionOneOfToolBuilder
        > {
  _$PendingInteractionOneOfTool? _$v;

  String? _callId;
  String? get callId => _$this._callId;
  set callId(String? callId) => _$this._callId = callId;

  String? _messageId;
  String? get messageId => _$this._messageId;
  set messageId(String? messageId) => _$this._messageId = messageId;

  PendingInteractionOneOfToolBuilder() {
    PendingInteractionOneOfTool._defaults(this);
  }

  PendingInteractionOneOfToolBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _callId = $v.callId;
      _messageId = $v.messageId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PendingInteractionOneOfTool other) {
    _$v = other as _$PendingInteractionOneOfTool;
  }

  @override
  void update(void Function(PendingInteractionOneOfToolBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PendingInteractionOneOfTool build() => _build();

  _$PendingInteractionOneOfTool _build() {
    final _$result =
        _$v ??
        _$PendingInteractionOneOfTool._(
          callId: BuiltValueNullFieldError.checkNotNull(
            callId,
            r'PendingInteractionOneOfTool',
            'callId',
          ),
          messageId: BuiltValueNullFieldError.checkNotNull(
            messageId,
            r'PendingInteractionOneOfTool',
            'messageId',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
