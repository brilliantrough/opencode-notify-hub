// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question_command_result.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const QuestionCommandResultStatusEnum
_$questionCommandResultStatusEnum_confirmed =
    const QuestionCommandResultStatusEnum._('confirmed');
const QuestionCommandResultStatusEnum _$questionCommandResultStatusEnum_stale =
    const QuestionCommandResultStatusEnum._('stale');
const QuestionCommandResultStatusEnum
_$questionCommandResultStatusEnum_upstreamError =
    const QuestionCommandResultStatusEnum._('upstreamError');
const QuestionCommandResultStatusEnum
_$questionCommandResultStatusEnum_resultUnknown =
    const QuestionCommandResultStatusEnum._('resultUnknown');

QuestionCommandResultStatusEnum _$questionCommandResultStatusEnumValueOf(
  String name,
) {
  switch (name) {
    case 'confirmed':
      return _$questionCommandResultStatusEnum_confirmed;
    case 'stale':
      return _$questionCommandResultStatusEnum_stale;
    case 'upstreamError':
      return _$questionCommandResultStatusEnum_upstreamError;
    case 'resultUnknown':
      return _$questionCommandResultStatusEnum_resultUnknown;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<QuestionCommandResultStatusEnum>
_$questionCommandResultStatusEnumValues =
    BuiltSet<QuestionCommandResultStatusEnum>(
      const <QuestionCommandResultStatusEnum>[
        _$questionCommandResultStatusEnum_confirmed,
        _$questionCommandResultStatusEnum_stale,
        _$questionCommandResultStatusEnum_upstreamError,
        _$questionCommandResultStatusEnum_resultUnknown,
      ],
    );

Serializer<QuestionCommandResultStatusEnum>
_$questionCommandResultStatusEnumSerializer =
    _$QuestionCommandResultStatusEnumSerializer();

class _$QuestionCommandResultStatusEnumSerializer
    implements PrimitiveSerializer<QuestionCommandResultStatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'confirmed': 'confirmed',
    'stale': 'stale',
    'upstreamError': 'upstream_error',
    'resultUnknown': 'result_unknown',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'confirmed': 'confirmed',
    'stale': 'stale',
    'upstream_error': 'upstreamError',
    'result_unknown': 'resultUnknown',
  };

  @override
  final Iterable<Type> types = const <Type>[QuestionCommandResultStatusEnum];
  @override
  final String wireName = 'QuestionCommandResultStatusEnum';

  @override
  Object serialize(
    Serializers serializers,
    QuestionCommandResultStatusEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  QuestionCommandResultStatusEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => QuestionCommandResultStatusEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$QuestionCommandResult extends QuestionCommandResult {
  @override
  final String commandId;
  @override
  final QuestionCommandResultStatusEnum status;

  factory _$QuestionCommandResult([
    void Function(QuestionCommandResultBuilder)? updates,
  ]) => (QuestionCommandResultBuilder()..update(updates))._build();

  _$QuestionCommandResult._({required this.commandId, required this.status})
    : super._();
  @override
  QuestionCommandResult rebuild(
    void Function(QuestionCommandResultBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  QuestionCommandResultBuilder toBuilder() =>
      QuestionCommandResultBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is QuestionCommandResult &&
        commandId == other.commandId &&
        status == other.status;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, commandId.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'QuestionCommandResult')
          ..add('commandId', commandId)
          ..add('status', status))
        .toString();
  }
}

class QuestionCommandResultBuilder
    implements Builder<QuestionCommandResult, QuestionCommandResultBuilder> {
  _$QuestionCommandResult? _$v;

  String? _commandId;
  String? get commandId => _$this._commandId;
  set commandId(String? commandId) => _$this._commandId = commandId;

  QuestionCommandResultStatusEnum? _status;
  QuestionCommandResultStatusEnum? get status => _$this._status;
  set status(QuestionCommandResultStatusEnum? status) =>
      _$this._status = status;

  QuestionCommandResultBuilder() {
    QuestionCommandResult._defaults(this);
  }

  QuestionCommandResultBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _commandId = $v.commandId;
      _status = $v.status;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(QuestionCommandResult other) {
    _$v = other as _$QuestionCommandResult;
  }

  @override
  void update(void Function(QuestionCommandResultBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  QuestionCommandResult build() => _build();

  _$QuestionCommandResult _build() {
    final _$result =
        _$v ??
        _$QuestionCommandResult._(
          commandId: BuiltValueNullFieldError.checkNotNull(
            commandId,
            r'QuestionCommandResult',
            'commandId',
          ),
          status: BuiltValueNullFieldError.checkNotNull(
            status,
            r'QuestionCommandResult',
            'status',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
