// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_control_server_message_one_of3.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const PluginControlServerMessageOneOf3DecisionEnum
_$pluginControlServerMessageOneOf3DecisionEnum_once =
    const PluginControlServerMessageOneOf3DecisionEnum._('once');
const PluginControlServerMessageOneOf3DecisionEnum
_$pluginControlServerMessageOneOf3DecisionEnum_reject =
    const PluginControlServerMessageOneOf3DecisionEnum._('reject');
const PluginControlServerMessageOneOf3DecisionEnum
_$pluginControlServerMessageOneOf3DecisionEnum_always =
    const PluginControlServerMessageOneOf3DecisionEnum._('always');

PluginControlServerMessageOneOf3DecisionEnum
_$pluginControlServerMessageOneOf3DecisionEnumValueOf(String name) {
  switch (name) {
    case 'once':
      return _$pluginControlServerMessageOneOf3DecisionEnum_once;
    case 'reject':
      return _$pluginControlServerMessageOneOf3DecisionEnum_reject;
    case 'always':
      return _$pluginControlServerMessageOneOf3DecisionEnum_always;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PluginControlServerMessageOneOf3DecisionEnum>
_$pluginControlServerMessageOneOf3DecisionEnumValues =
    BuiltSet<PluginControlServerMessageOneOf3DecisionEnum>(
      const <PluginControlServerMessageOneOf3DecisionEnum>[
        _$pluginControlServerMessageOneOf3DecisionEnum_once,
        _$pluginControlServerMessageOneOf3DecisionEnum_reject,
        _$pluginControlServerMessageOneOf3DecisionEnum_always,
      ],
    );

const PluginControlServerMessageOneOf3TypeEnum
_$pluginControlServerMessageOneOf3TypeEnum_permissionDecideCommand =
    const PluginControlServerMessageOneOf3TypeEnum._('permissionDecideCommand');

PluginControlServerMessageOneOf3TypeEnum
_$pluginControlServerMessageOneOf3TypeEnumValueOf(String name) {
  switch (name) {
    case 'permissionDecideCommand':
      return _$pluginControlServerMessageOneOf3TypeEnum_permissionDecideCommand;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PluginControlServerMessageOneOf3TypeEnum>
_$pluginControlServerMessageOneOf3TypeEnumValues =
    BuiltSet<PluginControlServerMessageOneOf3TypeEnum>(
      const <PluginControlServerMessageOneOf3TypeEnum>[
        _$pluginControlServerMessageOneOf3TypeEnum_permissionDecideCommand,
      ],
    );

Serializer<PluginControlServerMessageOneOf3DecisionEnum>
_$pluginControlServerMessageOneOf3DecisionEnumSerializer =
    _$PluginControlServerMessageOneOf3DecisionEnumSerializer();
Serializer<PluginControlServerMessageOneOf3TypeEnum>
_$pluginControlServerMessageOneOf3TypeEnumSerializer =
    _$PluginControlServerMessageOneOf3TypeEnumSerializer();

class _$PluginControlServerMessageOneOf3DecisionEnumSerializer
    implements
        PrimitiveSerializer<PluginControlServerMessageOneOf3DecisionEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'once': 'once',
    'reject': 'reject',
    'always': 'always',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'once': 'once',
    'reject': 'reject',
    'always': 'always',
  };

  @override
  final Iterable<Type> types = const <Type>[
    PluginControlServerMessageOneOf3DecisionEnum,
  ];
  @override
  final String wireName = 'PluginControlServerMessageOneOf3DecisionEnum';

  @override
  Object serialize(
    Serializers serializers,
    PluginControlServerMessageOneOf3DecisionEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  PluginControlServerMessageOneOf3DecisionEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => PluginControlServerMessageOneOf3DecisionEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$PluginControlServerMessageOneOf3TypeEnumSerializer
    implements PrimitiveSerializer<PluginControlServerMessageOneOf3TypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'permissionDecideCommand': 'permission_decide_command',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'permission_decide_command': 'permissionDecideCommand',
  };

  @override
  final Iterable<Type> types = const <Type>[
    PluginControlServerMessageOneOf3TypeEnum,
  ];
  @override
  final String wireName = 'PluginControlServerMessageOneOf3TypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    PluginControlServerMessageOneOf3TypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  PluginControlServerMessageOneOf3TypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => PluginControlServerMessageOneOf3TypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$PluginControlServerMessageOneOf3
    extends PluginControlServerMessageOneOf3 {
  @override
  final String commandId;
  @override
  final PluginControlServerMessageOneOf3DecisionEnum decision;
  @override
  final String requestId;
  @override
  final String sessionID;
  @override
  final PluginControlServerMessageOneOf3TypeEnum type;

  factory _$PluginControlServerMessageOneOf3([
    void Function(PluginControlServerMessageOneOf3Builder)? updates,
  ]) => (PluginControlServerMessageOneOf3Builder()..update(updates))._build();

  _$PluginControlServerMessageOneOf3._({
    required this.commandId,
    required this.decision,
    required this.requestId,
    required this.sessionID,
    required this.type,
  }) : super._();
  @override
  PluginControlServerMessageOneOf3 rebuild(
    void Function(PluginControlServerMessageOneOf3Builder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PluginControlServerMessageOneOf3Builder toBuilder() =>
      PluginControlServerMessageOneOf3Builder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PluginControlServerMessageOneOf3 &&
        commandId == other.commandId &&
        decision == other.decision &&
        requestId == other.requestId &&
        sessionID == other.sessionID &&
        type == other.type;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, commandId.hashCode);
    _$hash = $jc(_$hash, decision.hashCode);
    _$hash = $jc(_$hash, requestId.hashCode);
    _$hash = $jc(_$hash, sessionID.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PluginControlServerMessageOneOf3')
          ..add('commandId', commandId)
          ..add('decision', decision)
          ..add('requestId', requestId)
          ..add('sessionID', sessionID)
          ..add('type', type))
        .toString();
  }
}

class PluginControlServerMessageOneOf3Builder
    implements
        Builder<
          PluginControlServerMessageOneOf3,
          PluginControlServerMessageOneOf3Builder
        > {
  _$PluginControlServerMessageOneOf3? _$v;

  String? _commandId;
  String? get commandId => _$this._commandId;
  set commandId(String? commandId) => _$this._commandId = commandId;

  PluginControlServerMessageOneOf3DecisionEnum? _decision;
  PluginControlServerMessageOneOf3DecisionEnum? get decision =>
      _$this._decision;
  set decision(PluginControlServerMessageOneOf3DecisionEnum? decision) =>
      _$this._decision = decision;

  String? _requestId;
  String? get requestId => _$this._requestId;
  set requestId(String? requestId) => _$this._requestId = requestId;

  String? _sessionID;
  String? get sessionID => _$this._sessionID;
  set sessionID(String? sessionID) => _$this._sessionID = sessionID;

  PluginControlServerMessageOneOf3TypeEnum? _type;
  PluginControlServerMessageOneOf3TypeEnum? get type => _$this._type;
  set type(PluginControlServerMessageOneOf3TypeEnum? type) =>
      _$this._type = type;

  PluginControlServerMessageOneOf3Builder() {
    PluginControlServerMessageOneOf3._defaults(this);
  }

  PluginControlServerMessageOneOf3Builder get _$this {
    final $v = _$v;
    if ($v != null) {
      _commandId = $v.commandId;
      _decision = $v.decision;
      _requestId = $v.requestId;
      _sessionID = $v.sessionID;
      _type = $v.type;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PluginControlServerMessageOneOf3 other) {
    _$v = other as _$PluginControlServerMessageOneOf3;
  }

  @override
  void update(void Function(PluginControlServerMessageOneOf3Builder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PluginControlServerMessageOneOf3 build() => _build();

  _$PluginControlServerMessageOneOf3 _build() {
    final _$result =
        _$v ??
        _$PluginControlServerMessageOneOf3._(
          commandId: BuiltValueNullFieldError.checkNotNull(
            commandId,
            r'PluginControlServerMessageOneOf3',
            'commandId',
          ),
          decision: BuiltValueNullFieldError.checkNotNull(
            decision,
            r'PluginControlServerMessageOneOf3',
            'decision',
          ),
          requestId: BuiltValueNullFieldError.checkNotNull(
            requestId,
            r'PluginControlServerMessageOneOf3',
            'requestId',
          ),
          sessionID: BuiltValueNullFieldError.checkNotNull(
            sessionID,
            r'PluginControlServerMessageOneOf3',
            'sessionID',
          ),
          type: BuiltValueNullFieldError.checkNotNull(
            type,
            r'PluginControlServerMessageOneOf3',
            'type',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
