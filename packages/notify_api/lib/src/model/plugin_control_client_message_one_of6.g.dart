// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_control_client_message_one_of6.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const PluginControlClientMessageOneOf6TypeEnum
_$pluginControlClientMessageOneOf6TypeEnum_webuiHttpResponseChunk =
    const PluginControlClientMessageOneOf6TypeEnum._('webuiHttpResponseChunk');

PluginControlClientMessageOneOf6TypeEnum
_$pluginControlClientMessageOneOf6TypeEnumValueOf(String name) {
  switch (name) {
    case 'webuiHttpResponseChunk':
      return _$pluginControlClientMessageOneOf6TypeEnum_webuiHttpResponseChunk;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PluginControlClientMessageOneOf6TypeEnum>
_$pluginControlClientMessageOneOf6TypeEnumValues =
    BuiltSet<PluginControlClientMessageOneOf6TypeEnum>(
      const <PluginControlClientMessageOneOf6TypeEnum>[
        _$pluginControlClientMessageOneOf6TypeEnum_webuiHttpResponseChunk,
      ],
    );

Serializer<PluginControlClientMessageOneOf6TypeEnum>
_$pluginControlClientMessageOneOf6TypeEnumSerializer =
    _$PluginControlClientMessageOneOf6TypeEnumSerializer();

class _$PluginControlClientMessageOneOf6TypeEnumSerializer
    implements PrimitiveSerializer<PluginControlClientMessageOneOf6TypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'webuiHttpResponseChunk': 'webui_http_response_chunk',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'webui_http_response_chunk': 'webuiHttpResponseChunk',
  };

  @override
  final Iterable<Type> types = const <Type>[
    PluginControlClientMessageOneOf6TypeEnum,
  ];
  @override
  final String wireName = 'PluginControlClientMessageOneOf6TypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    PluginControlClientMessageOneOf6TypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  PluginControlClientMessageOneOf6TypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => PluginControlClientMessageOneOf6TypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$PluginControlClientMessageOneOf6
    extends PluginControlClientMessageOneOf6 {
  @override
  final String body;
  @override
  final String requestId;
  @override
  final String tunnelId;
  @override
  final PluginControlClientMessageOneOf6TypeEnum type;

  factory _$PluginControlClientMessageOneOf6([
    void Function(PluginControlClientMessageOneOf6Builder)? updates,
  ]) => (PluginControlClientMessageOneOf6Builder()..update(updates))._build();

  _$PluginControlClientMessageOneOf6._({
    required this.body,
    required this.requestId,
    required this.tunnelId,
    required this.type,
  }) : super._();
  @override
  PluginControlClientMessageOneOf6 rebuild(
    void Function(PluginControlClientMessageOneOf6Builder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PluginControlClientMessageOneOf6Builder toBuilder() =>
      PluginControlClientMessageOneOf6Builder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PluginControlClientMessageOneOf6 &&
        body == other.body &&
        requestId == other.requestId &&
        tunnelId == other.tunnelId &&
        type == other.type;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, body.hashCode);
    _$hash = $jc(_$hash, requestId.hashCode);
    _$hash = $jc(_$hash, tunnelId.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PluginControlClientMessageOneOf6')
          ..add('body', body)
          ..add('requestId', requestId)
          ..add('tunnelId', tunnelId)
          ..add('type', type))
        .toString();
  }
}

class PluginControlClientMessageOneOf6Builder
    implements
        Builder<
          PluginControlClientMessageOneOf6,
          PluginControlClientMessageOneOf6Builder
        > {
  _$PluginControlClientMessageOneOf6? _$v;

  String? _body;
  String? get body => _$this._body;
  set body(String? body) => _$this._body = body;

  String? _requestId;
  String? get requestId => _$this._requestId;
  set requestId(String? requestId) => _$this._requestId = requestId;

  String? _tunnelId;
  String? get tunnelId => _$this._tunnelId;
  set tunnelId(String? tunnelId) => _$this._tunnelId = tunnelId;

  PluginControlClientMessageOneOf6TypeEnum? _type;
  PluginControlClientMessageOneOf6TypeEnum? get type => _$this._type;
  set type(PluginControlClientMessageOneOf6TypeEnum? type) =>
      _$this._type = type;

  PluginControlClientMessageOneOf6Builder() {
    PluginControlClientMessageOneOf6._defaults(this);
  }

  PluginControlClientMessageOneOf6Builder get _$this {
    final $v = _$v;
    if ($v != null) {
      _body = $v.body;
      _requestId = $v.requestId;
      _tunnelId = $v.tunnelId;
      _type = $v.type;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PluginControlClientMessageOneOf6 other) {
    _$v = other as _$PluginControlClientMessageOneOf6;
  }

  @override
  void update(void Function(PluginControlClientMessageOneOf6Builder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PluginControlClientMessageOneOf6 build() => _build();

  _$PluginControlClientMessageOneOf6 _build() {
    final _$result =
        _$v ??
        _$PluginControlClientMessageOneOf6._(
          body: BuiltValueNullFieldError.checkNotNull(
            body,
            r'PluginControlClientMessageOneOf6',
            'body',
          ),
          requestId: BuiltValueNullFieldError.checkNotNull(
            requestId,
            r'PluginControlClientMessageOneOf6',
            'requestId',
          ),
          tunnelId: BuiltValueNullFieldError.checkNotNull(
            tunnelId,
            r'PluginControlClientMessageOneOf6',
            'tunnelId',
          ),
          type: BuiltValueNullFieldError.checkNotNull(
            type,
            r'PluginControlClientMessageOneOf6',
            'type',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
