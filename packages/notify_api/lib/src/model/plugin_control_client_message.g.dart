// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_control_client_message.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const PluginControlClientMessageTypeEnum
_$pluginControlClientMessageTypeEnum_register =
    const PluginControlClientMessageTypeEnum._('register');
const PluginControlClientMessageTypeEnum
_$pluginControlClientMessageTypeEnum_pendingSnapshotResponse =
    const PluginControlClientMessageTypeEnum._('pendingSnapshotResponse');
const PluginControlClientMessageTypeEnum
_$pluginControlClientMessageTypeEnum_questionAnswerResult =
    const PluginControlClientMessageTypeEnum._('questionAnswerResult');
const PluginControlClientMessageTypeEnum
_$pluginControlClientMessageTypeEnum_permissionDecideResult =
    const PluginControlClientMessageTypeEnum._('permissionDecideResult');
const PluginControlClientMessageTypeEnum
_$pluginControlClientMessageTypeEnum_sessionPromptResult =
    const PluginControlClientMessageTypeEnum._('sessionPromptResult');
const PluginControlClientMessageTypeEnum
_$pluginControlClientMessageTypeEnum_webuiHttpResponseStart =
    const PluginControlClientMessageTypeEnum._('webuiHttpResponseStart');
const PluginControlClientMessageTypeEnum
_$pluginControlClientMessageTypeEnum_webuiHttpResponseChunk =
    const PluginControlClientMessageTypeEnum._('webuiHttpResponseChunk');
const PluginControlClientMessageTypeEnum
_$pluginControlClientMessageTypeEnum_webuiHttpResponseEnd =
    const PluginControlClientMessageTypeEnum._('webuiHttpResponseEnd');

PluginControlClientMessageTypeEnum _$pluginControlClientMessageTypeEnumValueOf(
  String name,
) {
  switch (name) {
    case 'register':
      return _$pluginControlClientMessageTypeEnum_register;
    case 'pendingSnapshotResponse':
      return _$pluginControlClientMessageTypeEnum_pendingSnapshotResponse;
    case 'questionAnswerResult':
      return _$pluginControlClientMessageTypeEnum_questionAnswerResult;
    case 'permissionDecideResult':
      return _$pluginControlClientMessageTypeEnum_permissionDecideResult;
    case 'sessionPromptResult':
      return _$pluginControlClientMessageTypeEnum_sessionPromptResult;
    case 'webuiHttpResponseStart':
      return _$pluginControlClientMessageTypeEnum_webuiHttpResponseStart;
    case 'webuiHttpResponseChunk':
      return _$pluginControlClientMessageTypeEnum_webuiHttpResponseChunk;
    case 'webuiHttpResponseEnd':
      return _$pluginControlClientMessageTypeEnum_webuiHttpResponseEnd;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PluginControlClientMessageTypeEnum>
_$pluginControlClientMessageTypeEnumValues =
    BuiltSet<PluginControlClientMessageTypeEnum>(
      const <PluginControlClientMessageTypeEnum>[
        _$pluginControlClientMessageTypeEnum_register,
        _$pluginControlClientMessageTypeEnum_pendingSnapshotResponse,
        _$pluginControlClientMessageTypeEnum_questionAnswerResult,
        _$pluginControlClientMessageTypeEnum_permissionDecideResult,
        _$pluginControlClientMessageTypeEnum_sessionPromptResult,
        _$pluginControlClientMessageTypeEnum_webuiHttpResponseStart,
        _$pluginControlClientMessageTypeEnum_webuiHttpResponseChunk,
        _$pluginControlClientMessageTypeEnum_webuiHttpResponseEnd,
      ],
    );

Serializer<PluginControlClientMessageTypeEnum>
_$pluginControlClientMessageTypeEnumSerializer =
    _$PluginControlClientMessageTypeEnumSerializer();

class _$PluginControlClientMessageTypeEnumSerializer
    implements PrimitiveSerializer<PluginControlClientMessageTypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'register': 'register',
    'pendingSnapshotResponse': 'pending_snapshot_response',
    'questionAnswerResult': 'question_answer_result',
    'permissionDecideResult': 'permission_decide_result',
    'sessionPromptResult': 'session_prompt_result',
    'webuiHttpResponseStart': 'webui_http_response_start',
    'webuiHttpResponseChunk': 'webui_http_response_chunk',
    'webuiHttpResponseEnd': 'webui_http_response_end',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'register': 'register',
    'pending_snapshot_response': 'pendingSnapshotResponse',
    'question_answer_result': 'questionAnswerResult',
    'permission_decide_result': 'permissionDecideResult',
    'session_prompt_result': 'sessionPromptResult',
    'webui_http_response_start': 'webuiHttpResponseStart',
    'webui_http_response_chunk': 'webuiHttpResponseChunk',
    'webui_http_response_end': 'webuiHttpResponseEnd',
  };

  @override
  final Iterable<Type> types = const <Type>[PluginControlClientMessageTypeEnum];
  @override
  final String wireName = 'PluginControlClientMessageTypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    PluginControlClientMessageTypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  PluginControlClientMessageTypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => PluginControlClientMessageTypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$PluginControlClientMessage extends PluginControlClientMessage {
  @override
  final OneOf oneOf;

  factory _$PluginControlClientMessage([
    void Function(PluginControlClientMessageBuilder)? updates,
  ]) => (PluginControlClientMessageBuilder()..update(updates))._build();

  _$PluginControlClientMessage._({required this.oneOf}) : super._();
  @override
  PluginControlClientMessage rebuild(
    void Function(PluginControlClientMessageBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PluginControlClientMessageBuilder toBuilder() =>
      PluginControlClientMessageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PluginControlClientMessage && oneOf == other.oneOf;
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
      r'PluginControlClientMessage',
    )..add('oneOf', oneOf)).toString();
  }
}

class PluginControlClientMessageBuilder
    implements
        Builder<PluginControlClientMessage, PluginControlClientMessageBuilder> {
  _$PluginControlClientMessage? _$v;

  OneOf? _oneOf;
  OneOf? get oneOf => _$this._oneOf;
  set oneOf(OneOf? oneOf) => _$this._oneOf = oneOf;

  PluginControlClientMessageBuilder() {
    PluginControlClientMessage._defaults(this);
  }

  PluginControlClientMessageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _oneOf = $v.oneOf;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PluginControlClientMessage other) {
    _$v = other as _$PluginControlClientMessage;
  }

  @override
  void update(void Function(PluginControlClientMessageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PluginControlClientMessage build() => _build();

  _$PluginControlClientMessage _build() {
    final _$result =
        _$v ??
        _$PluginControlClientMessage._(
          oneOf: BuiltValueNullFieldError.checkNotNull(
            oneOf,
            r'PluginControlClientMessage',
            'oneOf',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
