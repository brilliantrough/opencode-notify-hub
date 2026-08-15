// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_control_server_message.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const PluginControlServerMessageStateEnum
_$pluginControlServerMessageStateEnum_controllable =
    const PluginControlServerMessageStateEnum._('controllable');
const PluginControlServerMessageStateEnum
_$pluginControlServerMessageStateEnum_conflicting =
    const PluginControlServerMessageStateEnum._('conflicting');
const PluginControlServerMessageStateEnum
_$pluginControlServerMessageStateEnum_incompatible =
    const PluginControlServerMessageStateEnum._('incompatible');

PluginControlServerMessageStateEnum
_$pluginControlServerMessageStateEnumValueOf(String name) {
  switch (name) {
    case 'controllable':
      return _$pluginControlServerMessageStateEnum_controllable;
    case 'conflicting':
      return _$pluginControlServerMessageStateEnum_conflicting;
    case 'incompatible':
      return _$pluginControlServerMessageStateEnum_incompatible;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PluginControlServerMessageStateEnum>
_$pluginControlServerMessageStateEnumValues =
    BuiltSet<PluginControlServerMessageStateEnum>(
      const <PluginControlServerMessageStateEnum>[
        _$pluginControlServerMessageStateEnum_controllable,
        _$pluginControlServerMessageStateEnum_conflicting,
        _$pluginControlServerMessageStateEnum_incompatible,
      ],
    );

const PluginControlServerMessageTypeEnum
_$pluginControlServerMessageTypeEnum_registration =
    const PluginControlServerMessageTypeEnum._('registration');
const PluginControlServerMessageTypeEnum
_$pluginControlServerMessageTypeEnum_pendingSnapshotRequest =
    const PluginControlServerMessageTypeEnum._('pendingSnapshotRequest');
const PluginControlServerMessageTypeEnum
_$pluginControlServerMessageTypeEnum_questionAnswerCommand =
    const PluginControlServerMessageTypeEnum._('questionAnswerCommand');
const PluginControlServerMessageTypeEnum
_$pluginControlServerMessageTypeEnum_permissionDecideCommand =
    const PluginControlServerMessageTypeEnum._('permissionDecideCommand');

PluginControlServerMessageTypeEnum _$pluginControlServerMessageTypeEnumValueOf(
  String name,
) {
  switch (name) {
    case 'registration':
      return _$pluginControlServerMessageTypeEnum_registration;
    case 'pendingSnapshotRequest':
      return _$pluginControlServerMessageTypeEnum_pendingSnapshotRequest;
    case 'questionAnswerCommand':
      return _$pluginControlServerMessageTypeEnum_questionAnswerCommand;
    case 'permissionDecideCommand':
      return _$pluginControlServerMessageTypeEnum_permissionDecideCommand;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PluginControlServerMessageTypeEnum>
_$pluginControlServerMessageTypeEnumValues =
    BuiltSet<PluginControlServerMessageTypeEnum>(
      const <PluginControlServerMessageTypeEnum>[
        _$pluginControlServerMessageTypeEnum_registration,
        _$pluginControlServerMessageTypeEnum_pendingSnapshotRequest,
        _$pluginControlServerMessageTypeEnum_questionAnswerCommand,
        _$pluginControlServerMessageTypeEnum_permissionDecideCommand,
      ],
    );

const PluginControlServerMessageDecisionEnum
_$pluginControlServerMessageDecisionEnum_once =
    const PluginControlServerMessageDecisionEnum._('once');
const PluginControlServerMessageDecisionEnum
_$pluginControlServerMessageDecisionEnum_reject =
    const PluginControlServerMessageDecisionEnum._('reject');
const PluginControlServerMessageDecisionEnum
_$pluginControlServerMessageDecisionEnum_always =
    const PluginControlServerMessageDecisionEnum._('always');

PluginControlServerMessageDecisionEnum
_$pluginControlServerMessageDecisionEnumValueOf(String name) {
  switch (name) {
    case 'once':
      return _$pluginControlServerMessageDecisionEnum_once;
    case 'reject':
      return _$pluginControlServerMessageDecisionEnum_reject;
    case 'always':
      return _$pluginControlServerMessageDecisionEnum_always;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PluginControlServerMessageDecisionEnum>
_$pluginControlServerMessageDecisionEnumValues =
    BuiltSet<PluginControlServerMessageDecisionEnum>(
      const <PluginControlServerMessageDecisionEnum>[
        _$pluginControlServerMessageDecisionEnum_once,
        _$pluginControlServerMessageDecisionEnum_reject,
        _$pluginControlServerMessageDecisionEnum_always,
      ],
    );

Serializer<PluginControlServerMessageStateEnum>
_$pluginControlServerMessageStateEnumSerializer =
    _$PluginControlServerMessageStateEnumSerializer();
Serializer<PluginControlServerMessageTypeEnum>
_$pluginControlServerMessageTypeEnumSerializer =
    _$PluginControlServerMessageTypeEnumSerializer();
Serializer<PluginControlServerMessageDecisionEnum>
_$pluginControlServerMessageDecisionEnumSerializer =
    _$PluginControlServerMessageDecisionEnumSerializer();

class _$PluginControlServerMessageStateEnumSerializer
    implements PrimitiveSerializer<PluginControlServerMessageStateEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'controllable': 'controllable',
    'conflicting': 'conflicting',
    'incompatible': 'incompatible',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'controllable': 'controllable',
    'conflicting': 'conflicting',
    'incompatible': 'incompatible',
  };

  @override
  final Iterable<Type> types = const <Type>[
    PluginControlServerMessageStateEnum,
  ];
  @override
  final String wireName = 'PluginControlServerMessageStateEnum';

  @override
  Object serialize(
    Serializers serializers,
    PluginControlServerMessageStateEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  PluginControlServerMessageStateEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => PluginControlServerMessageStateEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$PluginControlServerMessageTypeEnumSerializer
    implements PrimitiveSerializer<PluginControlServerMessageTypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'registration': 'registration',
    'pendingSnapshotRequest': 'pending_snapshot_request',
    'questionAnswerCommand': 'question_answer_command',
    'permissionDecideCommand': 'permission_decide_command',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'registration': 'registration',
    'pending_snapshot_request': 'pendingSnapshotRequest',
    'question_answer_command': 'questionAnswerCommand',
    'permission_decide_command': 'permissionDecideCommand',
  };

  @override
  final Iterable<Type> types = const <Type>[PluginControlServerMessageTypeEnum];
  @override
  final String wireName = 'PluginControlServerMessageTypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    PluginControlServerMessageTypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  PluginControlServerMessageTypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => PluginControlServerMessageTypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$PluginControlServerMessageDecisionEnumSerializer
    implements PrimitiveSerializer<PluginControlServerMessageDecisionEnum> {
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
    PluginControlServerMessageDecisionEnum,
  ];
  @override
  final String wireName = 'PluginControlServerMessageDecisionEnum';

  @override
  Object serialize(
    Serializers serializers,
    PluginControlServerMessageDecisionEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  PluginControlServerMessageDecisionEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => PluginControlServerMessageDecisionEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$PluginControlServerMessage extends PluginControlServerMessage {
  @override
  final OneOf oneOf;

  factory _$PluginControlServerMessage([
    void Function(PluginControlServerMessageBuilder)? updates,
  ]) => (PluginControlServerMessageBuilder()..update(updates))._build();

  _$PluginControlServerMessage._({required this.oneOf}) : super._();
  @override
  PluginControlServerMessage rebuild(
    void Function(PluginControlServerMessageBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PluginControlServerMessageBuilder toBuilder() =>
      PluginControlServerMessageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PluginControlServerMessage && oneOf == other.oneOf;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, oneOf.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'PluginControlServerMessage',
    )..add('oneOf', oneOf)).toString();
  }
}

class PluginControlServerMessageBuilder
    implements
        Builder<PluginControlServerMessage, PluginControlServerMessageBuilder> {
  _$PluginControlServerMessage? _$v;

  OneOf? _oneOf;
  OneOf? get oneOf => _$this._oneOf;
  set oneOf(OneOf? oneOf) => _$this._oneOf = oneOf;

  PluginControlServerMessageBuilder() {
    PluginControlServerMessage._defaults(this);
  }

  PluginControlServerMessageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _oneOf = $v.oneOf;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PluginControlServerMessage other) {
    _$v = other as _$PluginControlServerMessage;
  }

  @override
  void update(void Function(PluginControlServerMessageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PluginControlServerMessage build() => _build();

  _$PluginControlServerMessage _build() {
    final _$result =
        _$v ??
        _$PluginControlServerMessage._(
          oneOf: BuiltValueNullFieldError.checkNotNull(
            oneOf,
            r'PluginControlServerMessage',
            'oneOf',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
