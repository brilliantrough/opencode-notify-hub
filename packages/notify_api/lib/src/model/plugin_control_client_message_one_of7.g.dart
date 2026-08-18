// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_control_client_message_one_of7.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const PluginControlClientMessageOneOf7TypeEnum
_$pluginControlClientMessageOneOf7TypeEnum_webuiHttpResponseEnd =
    const PluginControlClientMessageOneOf7TypeEnum._('webuiHttpResponseEnd');

PluginControlClientMessageOneOf7TypeEnum
_$pluginControlClientMessageOneOf7TypeEnumValueOf(String name) {
  switch (name) {
    case 'webuiHttpResponseEnd':
      return _$pluginControlClientMessageOneOf7TypeEnum_webuiHttpResponseEnd;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PluginControlClientMessageOneOf7TypeEnum>
_$pluginControlClientMessageOneOf7TypeEnumValues =
    BuiltSet<PluginControlClientMessageOneOf7TypeEnum>(
      const <PluginControlClientMessageOneOf7TypeEnum>[
        _$pluginControlClientMessageOneOf7TypeEnum_webuiHttpResponseEnd,
      ],
    );

Serializer<PluginControlClientMessageOneOf7TypeEnum>
_$pluginControlClientMessageOneOf7TypeEnumSerializer =
    _$PluginControlClientMessageOneOf7TypeEnumSerializer();

class _$PluginControlClientMessageOneOf7TypeEnumSerializer
    implements PrimitiveSerializer<PluginControlClientMessageOneOf7TypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'webuiHttpResponseEnd': 'webui_http_response_end',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'webui_http_response_end': 'webuiHttpResponseEnd',
  };

  @override
  final Iterable<Type> types = const <Type>[
    PluginControlClientMessageOneOf7TypeEnum,
  ];
  @override
  final String wireName = 'PluginControlClientMessageOneOf7TypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    PluginControlClientMessageOneOf7TypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  PluginControlClientMessageOneOf7TypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => PluginControlClientMessageOneOf7TypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$PluginControlClientMessageOneOf7
    extends PluginControlClientMessageOneOf7 {
  @override
  final String requestId;
  @override
  final String tunnelId;
  @override
  final PluginControlClientMessageOneOf7TypeEnum type;

  factory _$PluginControlClientMessageOneOf7([
    void Function(PluginControlClientMessageOneOf7Builder)? updates,
  ]) => (PluginControlClientMessageOneOf7Builder()..update(updates))._build();

  _$PluginControlClientMessageOneOf7._({
    required this.requestId,
    required this.tunnelId,
    required this.type,
  }) : super._();
  @override
  PluginControlClientMessageOneOf7 rebuild(
    void Function(PluginControlClientMessageOneOf7Builder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PluginControlClientMessageOneOf7Builder toBuilder() =>
      PluginControlClientMessageOneOf7Builder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PluginControlClientMessageOneOf7 &&
        requestId == other.requestId &&
        tunnelId == other.tunnelId &&
        type == other.type;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, requestId.hashCode);
    _$hash = $jc(_$hash, tunnelId.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PluginControlClientMessageOneOf7')
          ..add('requestId', requestId)
          ..add('tunnelId', tunnelId)
          ..add('type', type))
        .toString();
  }
}

class PluginControlClientMessageOneOf7Builder
    implements
        Builder<
          PluginControlClientMessageOneOf7,
          PluginControlClientMessageOneOf7Builder
        > {
  _$PluginControlClientMessageOneOf7? _$v;

  String? _requestId;
  String? get requestId => _$this._requestId;
  set requestId(String? requestId) => _$this._requestId = requestId;

  String? _tunnelId;
  String? get tunnelId => _$this._tunnelId;
  set tunnelId(String? tunnelId) => _$this._tunnelId = tunnelId;

  PluginControlClientMessageOneOf7TypeEnum? _type;
  PluginControlClientMessageOneOf7TypeEnum? get type => _$this._type;
  set type(PluginControlClientMessageOneOf7TypeEnum? type) =>
      _$this._type = type;

  PluginControlClientMessageOneOf7Builder() {
    PluginControlClientMessageOneOf7._defaults(this);
  }

  PluginControlClientMessageOneOf7Builder get _$this {
    final $v = _$v;
    if ($v != null) {
      _requestId = $v.requestId;
      _tunnelId = $v.tunnelId;
      _type = $v.type;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PluginControlClientMessageOneOf7 other) {
    _$v = other as _$PluginControlClientMessageOneOf7;
  }

  @override
  void update(void Function(PluginControlClientMessageOneOf7Builder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PluginControlClientMessageOneOf7 build() => _build();

  _$PluginControlClientMessageOneOf7 _build() {
    final _$result =
        _$v ??
        _$PluginControlClientMessageOneOf7._(
          requestId: BuiltValueNullFieldError.checkNotNull(
            requestId,
            r'PluginControlClientMessageOneOf7',
            'requestId',
          ),
          tunnelId: BuiltValueNullFieldError.checkNotNull(
            tunnelId,
            r'PluginControlClientMessageOneOf7',
            'tunnelId',
          ),
          type: BuiltValueNullFieldError.checkNotNull(
            type,
            r'PluginControlClientMessageOneOf7',
            'type',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
