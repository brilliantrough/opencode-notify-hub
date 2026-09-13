// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_control_server_message_one_of8.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const PluginControlServerMessageOneOf8TypeEnum
_$pluginControlServerMessageOneOf8TypeEnum_webuiHttpCancel =
    const PluginControlServerMessageOneOf8TypeEnum._('webuiHttpCancel');

PluginControlServerMessageOneOf8TypeEnum
_$pluginControlServerMessageOneOf8TypeEnumValueOf(String name) {
  switch (name) {
    case 'webuiHttpCancel':
      return _$pluginControlServerMessageOneOf8TypeEnum_webuiHttpCancel;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PluginControlServerMessageOneOf8TypeEnum>
_$pluginControlServerMessageOneOf8TypeEnumValues =
    BuiltSet<PluginControlServerMessageOneOf8TypeEnum>(
      const <PluginControlServerMessageOneOf8TypeEnum>[
        _$pluginControlServerMessageOneOf8TypeEnum_webuiHttpCancel,
      ],
    );

Serializer<PluginControlServerMessageOneOf8TypeEnum>
_$pluginControlServerMessageOneOf8TypeEnumSerializer =
    _$PluginControlServerMessageOneOf8TypeEnumSerializer();

class _$PluginControlServerMessageOneOf8TypeEnumSerializer
    implements PrimitiveSerializer<PluginControlServerMessageOneOf8TypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'webuiHttpCancel': 'webui_http_cancel',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'webui_http_cancel': 'webuiHttpCancel',
  };

  @override
  final Iterable<Type> types = const <Type>[
    PluginControlServerMessageOneOf8TypeEnum,
  ];
  @override
  final String wireName = 'PluginControlServerMessageOneOf8TypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    PluginControlServerMessageOneOf8TypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  PluginControlServerMessageOneOf8TypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => PluginControlServerMessageOneOf8TypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$PluginControlServerMessageOneOf8
    extends PluginControlServerMessageOneOf8 {
  @override
  final String requestId;
  @override
  final String tunnelId;
  @override
  final PluginControlServerMessageOneOf8TypeEnum type;

  factory _$PluginControlServerMessageOneOf8([
    void Function(PluginControlServerMessageOneOf8Builder)? updates,
  ]) => (PluginControlServerMessageOneOf8Builder()..update(updates))._build();

  _$PluginControlServerMessageOneOf8._({
    required this.requestId,
    required this.tunnelId,
    required this.type,
  }) : super._();
  @override
  PluginControlServerMessageOneOf8 rebuild(
    void Function(PluginControlServerMessageOneOf8Builder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PluginControlServerMessageOneOf8Builder toBuilder() =>
      PluginControlServerMessageOneOf8Builder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PluginControlServerMessageOneOf8 &&
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
    return (newBuiltValueToStringHelper(r'PluginControlServerMessageOneOf8')
          ..add('requestId', requestId)
          ..add('tunnelId', tunnelId)
          ..add('type', type))
        .toString();
  }
}

class PluginControlServerMessageOneOf8Builder
    implements
        Builder<
          PluginControlServerMessageOneOf8,
          PluginControlServerMessageOneOf8Builder
        > {
  _$PluginControlServerMessageOneOf8? _$v;

  String? _requestId;
  String? get requestId => _$this._requestId;
  set requestId(String? requestId) => _$this._requestId = requestId;

  String? _tunnelId;
  String? get tunnelId => _$this._tunnelId;
  set tunnelId(String? tunnelId) => _$this._tunnelId = tunnelId;

  PluginControlServerMessageOneOf8TypeEnum? _type;
  PluginControlServerMessageOneOf8TypeEnum? get type => _$this._type;
  set type(PluginControlServerMessageOneOf8TypeEnum? type) =>
      _$this._type = type;

  PluginControlServerMessageOneOf8Builder() {
    PluginControlServerMessageOneOf8._defaults(this);
  }

  PluginControlServerMessageOneOf8Builder get _$this {
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
  void replace(PluginControlServerMessageOneOf8 other) {
    _$v = other as _$PluginControlServerMessageOneOf8;
  }

  @override
  void update(void Function(PluginControlServerMessageOneOf8Builder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PluginControlServerMessageOneOf8 build() => _build();

  _$PluginControlServerMessageOneOf8 _build() {
    final _$result =
        _$v ??
        _$PluginControlServerMessageOneOf8._(
          requestId: BuiltValueNullFieldError.checkNotNull(
            requestId,
            r'PluginControlServerMessageOneOf8',
            'requestId',
          ),
          tunnelId: BuiltValueNullFieldError.checkNotNull(
            tunnelId,
            r'PluginControlServerMessageOneOf8',
            'tunnelId',
          ),
          type: BuiltValueNullFieldError.checkNotNull(
            type,
            r'PluginControlServerMessageOneOf8',
            'type',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
