// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_control_server_message_one_of2.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const PluginControlServerMessageOneOf2TypeEnum
_$pluginControlServerMessageOneOf2TypeEnum_questionAnswerCommand =
    const PluginControlServerMessageOneOf2TypeEnum._('questionAnswerCommand');

PluginControlServerMessageOneOf2TypeEnum
_$pluginControlServerMessageOneOf2TypeEnumValueOf(String name) {
  switch (name) {
    case 'questionAnswerCommand':
      return _$pluginControlServerMessageOneOf2TypeEnum_questionAnswerCommand;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PluginControlServerMessageOneOf2TypeEnum>
_$pluginControlServerMessageOneOf2TypeEnumValues =
    BuiltSet<PluginControlServerMessageOneOf2TypeEnum>(
      const <PluginControlServerMessageOneOf2TypeEnum>[
        _$pluginControlServerMessageOneOf2TypeEnum_questionAnswerCommand,
      ],
    );

Serializer<PluginControlServerMessageOneOf2TypeEnum>
_$pluginControlServerMessageOneOf2TypeEnumSerializer =
    _$PluginControlServerMessageOneOf2TypeEnumSerializer();

class _$PluginControlServerMessageOneOf2TypeEnumSerializer
    implements PrimitiveSerializer<PluginControlServerMessageOneOf2TypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'questionAnswerCommand': 'question_answer_command',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'question_answer_command': 'questionAnswerCommand',
  };

  @override
  final Iterable<Type> types = const <Type>[
    PluginControlServerMessageOneOf2TypeEnum,
  ];
  @override
  final String wireName = 'PluginControlServerMessageOneOf2TypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    PluginControlServerMessageOneOf2TypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  PluginControlServerMessageOneOf2TypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => PluginControlServerMessageOneOf2TypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$PluginControlServerMessageOneOf2
    extends PluginControlServerMessageOneOf2 {
  @override
  final BuiltList<BuiltList<String>> answers;
  @override
  final String commandId;
  @override
  final String requestId;
  @override
  final String sessionID;
  @override
  final PluginControlServerMessageOneOf2TypeEnum type;

  factory _$PluginControlServerMessageOneOf2([
    void Function(PluginControlServerMessageOneOf2Builder)? updates,
  ]) => (PluginControlServerMessageOneOf2Builder()..update(updates))._build();

  _$PluginControlServerMessageOneOf2._({
    required this.answers,
    required this.commandId,
    required this.requestId,
    required this.sessionID,
    required this.type,
  }) : super._();
  @override
  PluginControlServerMessageOneOf2 rebuild(
    void Function(PluginControlServerMessageOneOf2Builder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PluginControlServerMessageOneOf2Builder toBuilder() =>
      PluginControlServerMessageOneOf2Builder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PluginControlServerMessageOneOf2 &&
        answers == other.answers &&
        commandId == other.commandId &&
        requestId == other.requestId &&
        sessionID == other.sessionID &&
        type == other.type;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, answers.hashCode);
    _$hash = $jc(_$hash, commandId.hashCode);
    _$hash = $jc(_$hash, requestId.hashCode);
    _$hash = $jc(_$hash, sessionID.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PluginControlServerMessageOneOf2')
          ..add('answers', answers)
          ..add('commandId', commandId)
          ..add('requestId', requestId)
          ..add('sessionID', sessionID)
          ..add('type', type))
        .toString();
  }
}

class PluginControlServerMessageOneOf2Builder
    implements
        Builder<
          PluginControlServerMessageOneOf2,
          PluginControlServerMessageOneOf2Builder
        > {
  _$PluginControlServerMessageOneOf2? _$v;

  ListBuilder<BuiltList<String>>? _answers;
  ListBuilder<BuiltList<String>> get answers =>
      _$this._answers ??= ListBuilder<BuiltList<String>>();
  set answers(ListBuilder<BuiltList<String>>? answers) =>
      _$this._answers = answers;

  String? _commandId;
  String? get commandId => _$this._commandId;
  set commandId(String? commandId) => _$this._commandId = commandId;

  String? _requestId;
  String? get requestId => _$this._requestId;
  set requestId(String? requestId) => _$this._requestId = requestId;

  String? _sessionID;
  String? get sessionID => _$this._sessionID;
  set sessionID(String? sessionID) => _$this._sessionID = sessionID;

  PluginControlServerMessageOneOf2TypeEnum? _type;
  PluginControlServerMessageOneOf2TypeEnum? get type => _$this._type;
  set type(PluginControlServerMessageOneOf2TypeEnum? type) =>
      _$this._type = type;

  PluginControlServerMessageOneOf2Builder() {
    PluginControlServerMessageOneOf2._defaults(this);
  }

  PluginControlServerMessageOneOf2Builder get _$this {
    final $v = _$v;
    if ($v != null) {
      _answers = $v.answers.toBuilder();
      _commandId = $v.commandId;
      _requestId = $v.requestId;
      _sessionID = $v.sessionID;
      _type = $v.type;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PluginControlServerMessageOneOf2 other) {
    _$v = other as _$PluginControlServerMessageOneOf2;
  }

  @override
  void update(void Function(PluginControlServerMessageOneOf2Builder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PluginControlServerMessageOneOf2 build() => _build();

  _$PluginControlServerMessageOneOf2 _build() {
    _$PluginControlServerMessageOneOf2 _$result;
    try {
      _$result =
          _$v ??
          _$PluginControlServerMessageOneOf2._(
            answers: answers.build(),
            commandId: BuiltValueNullFieldError.checkNotNull(
              commandId,
              r'PluginControlServerMessageOneOf2',
              'commandId',
            ),
            requestId: BuiltValueNullFieldError.checkNotNull(
              requestId,
              r'PluginControlServerMessageOneOf2',
              'requestId',
            ),
            sessionID: BuiltValueNullFieldError.checkNotNull(
              sessionID,
              r'PluginControlServerMessageOneOf2',
              'sessionID',
            ),
            type: BuiltValueNullFieldError.checkNotNull(
              type,
              r'PluginControlServerMessageOneOf2',
              'type',
            ),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'answers';
        answers.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'PluginControlServerMessageOneOf2',
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
