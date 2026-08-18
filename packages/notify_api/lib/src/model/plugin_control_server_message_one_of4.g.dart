// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_control_server_message_one_of4.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const PluginControlServerMessageOneOf4TypeEnum
_$pluginControlServerMessageOneOf4TypeEnum_sessionPromptCommand =
    const PluginControlServerMessageOneOf4TypeEnum._('sessionPromptCommand');

PluginControlServerMessageOneOf4TypeEnum
_$pluginControlServerMessageOneOf4TypeEnumValueOf(String name) {
  switch (name) {
    case 'sessionPromptCommand':
      return _$pluginControlServerMessageOneOf4TypeEnum_sessionPromptCommand;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PluginControlServerMessageOneOf4TypeEnum>
_$pluginControlServerMessageOneOf4TypeEnumValues =
    BuiltSet<PluginControlServerMessageOneOf4TypeEnum>(
      const <PluginControlServerMessageOneOf4TypeEnum>[
        _$pluginControlServerMessageOneOf4TypeEnum_sessionPromptCommand,
      ],
    );

Serializer<PluginControlServerMessageOneOf4TypeEnum>
_$pluginControlServerMessageOneOf4TypeEnumSerializer =
    _$PluginControlServerMessageOneOf4TypeEnumSerializer();

class _$PluginControlServerMessageOneOf4TypeEnumSerializer
    implements PrimitiveSerializer<PluginControlServerMessageOneOf4TypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'sessionPromptCommand': 'session_prompt_command',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'session_prompt_command': 'sessionPromptCommand',
  };

  @override
  final Iterable<Type> types = const <Type>[
    PluginControlServerMessageOneOf4TypeEnum,
  ];
  @override
  final String wireName = 'PluginControlServerMessageOneOf4TypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    PluginControlServerMessageOneOf4TypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  PluginControlServerMessageOneOf4TypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => PluginControlServerMessageOneOf4TypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$PluginControlServerMessageOneOf4
    extends PluginControlServerMessageOneOf4 {
  @override
  final String commandId;
  @override
  final String sessionID;
  @override
  final String text;
  @override
  final PluginControlServerMessageOneOf4TypeEnum type;

  factory _$PluginControlServerMessageOneOf4([
    void Function(PluginControlServerMessageOneOf4Builder)? updates,
  ]) => (PluginControlServerMessageOneOf4Builder()..update(updates))._build();

  _$PluginControlServerMessageOneOf4._({
    required this.commandId,
    required this.sessionID,
    required this.text,
    required this.type,
  }) : super._();
  @override
  PluginControlServerMessageOneOf4 rebuild(
    void Function(PluginControlServerMessageOneOf4Builder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PluginControlServerMessageOneOf4Builder toBuilder() =>
      PluginControlServerMessageOneOf4Builder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PluginControlServerMessageOneOf4 &&
        commandId == other.commandId &&
        sessionID == other.sessionID &&
        text == other.text &&
        type == other.type;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, commandId.hashCode);
    _$hash = $jc(_$hash, sessionID.hashCode);
    _$hash = $jc(_$hash, text.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PluginControlServerMessageOneOf4')
          ..add('commandId', commandId)
          ..add('sessionID', sessionID)
          ..add('text', text)
          ..add('type', type))
        .toString();
  }
}

class PluginControlServerMessageOneOf4Builder
    implements
        Builder<
          PluginControlServerMessageOneOf4,
          PluginControlServerMessageOneOf4Builder
        > {
  _$PluginControlServerMessageOneOf4? _$v;

  String? _commandId;
  String? get commandId => _$this._commandId;
  set commandId(String? commandId) => _$this._commandId = commandId;

  String? _sessionID;
  String? get sessionID => _$this._sessionID;
  set sessionID(String? sessionID) => _$this._sessionID = sessionID;

  String? _text;
  String? get text => _$this._text;
  set text(String? text) => _$this._text = text;

  PluginControlServerMessageOneOf4TypeEnum? _type;
  PluginControlServerMessageOneOf4TypeEnum? get type => _$this._type;
  set type(PluginControlServerMessageOneOf4TypeEnum? type) =>
      _$this._type = type;

  PluginControlServerMessageOneOf4Builder() {
    PluginControlServerMessageOneOf4._defaults(this);
  }

  PluginControlServerMessageOneOf4Builder get _$this {
    final $v = _$v;
    if ($v != null) {
      _commandId = $v.commandId;
      _sessionID = $v.sessionID;
      _text = $v.text;
      _type = $v.type;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PluginControlServerMessageOneOf4 other) {
    _$v = other as _$PluginControlServerMessageOneOf4;
  }

  @override
  void update(void Function(PluginControlServerMessageOneOf4Builder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PluginControlServerMessageOneOf4 build() => _build();

  _$PluginControlServerMessageOneOf4 _build() {
    final _$result =
        _$v ??
        _$PluginControlServerMessageOneOf4._(
          commandId: BuiltValueNullFieldError.checkNotNull(
            commandId,
            r'PluginControlServerMessageOneOf4',
            'commandId',
          ),
          sessionID: BuiltValueNullFieldError.checkNotNull(
            sessionID,
            r'PluginControlServerMessageOneOf4',
            'sessionID',
          ),
          text: BuiltValueNullFieldError.checkNotNull(
            text,
            r'PluginControlServerMessageOneOf4',
            'text',
          ),
          type: BuiltValueNullFieldError.checkNotNull(
            type,
            r'PluginControlServerMessageOneOf4',
            'type',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
