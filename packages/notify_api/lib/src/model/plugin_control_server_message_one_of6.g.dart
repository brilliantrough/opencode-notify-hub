// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_control_server_message_one_of6.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const PluginControlServerMessageOneOf6TypeEnum
_$pluginControlServerMessageOneOf6TypeEnum_webuiTunnelClose =
    const PluginControlServerMessageOneOf6TypeEnum._('webuiTunnelClose');

PluginControlServerMessageOneOf6TypeEnum
_$pluginControlServerMessageOneOf6TypeEnumValueOf(String name) {
  switch (name) {
    case 'webuiTunnelClose':
      return _$pluginControlServerMessageOneOf6TypeEnum_webuiTunnelClose;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PluginControlServerMessageOneOf6TypeEnum>
_$pluginControlServerMessageOneOf6TypeEnumValues =
    BuiltSet<PluginControlServerMessageOneOf6TypeEnum>(
      const <PluginControlServerMessageOneOf6TypeEnum>[
        _$pluginControlServerMessageOneOf6TypeEnum_webuiTunnelClose,
      ],
    );

Serializer<PluginControlServerMessageOneOf6TypeEnum>
_$pluginControlServerMessageOneOf6TypeEnumSerializer =
    _$PluginControlServerMessageOneOf6TypeEnumSerializer();

class _$PluginControlServerMessageOneOf6TypeEnumSerializer
    implements PrimitiveSerializer<PluginControlServerMessageOneOf6TypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'webuiTunnelClose': 'webui_tunnel_close',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'webui_tunnel_close': 'webuiTunnelClose',
  };

  @override
  final Iterable<Type> types = const <Type>[
    PluginControlServerMessageOneOf6TypeEnum,
  ];
  @override
  final String wireName = 'PluginControlServerMessageOneOf6TypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    PluginControlServerMessageOneOf6TypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  PluginControlServerMessageOneOf6TypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => PluginControlServerMessageOneOf6TypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$PluginControlServerMessageOneOf6
    extends PluginControlServerMessageOneOf6 {
  @override
  final String tunnelId;
  @override
  final PluginControlServerMessageOneOf6TypeEnum type;

  factory _$PluginControlServerMessageOneOf6([
    void Function(PluginControlServerMessageOneOf6Builder)? updates,
  ]) => (PluginControlServerMessageOneOf6Builder()..update(updates))._build();

  _$PluginControlServerMessageOneOf6._({
    required this.tunnelId,
    required this.type,
  }) : super._();
  @override
  PluginControlServerMessageOneOf6 rebuild(
    void Function(PluginControlServerMessageOneOf6Builder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PluginControlServerMessageOneOf6Builder toBuilder() =>
      PluginControlServerMessageOneOf6Builder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PluginControlServerMessageOneOf6 &&
        tunnelId == other.tunnelId &&
        type == other.type;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, tunnelId.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PluginControlServerMessageOneOf6')
          ..add('tunnelId', tunnelId)
          ..add('type', type))
        .toString();
  }
}

class PluginControlServerMessageOneOf6Builder
    implements
        Builder<
          PluginControlServerMessageOneOf6,
          PluginControlServerMessageOneOf6Builder
        > {
  _$PluginControlServerMessageOneOf6? _$v;

  String? _tunnelId;
  String? get tunnelId => _$this._tunnelId;
  set tunnelId(String? tunnelId) => _$this._tunnelId = tunnelId;

  PluginControlServerMessageOneOf6TypeEnum? _type;
  PluginControlServerMessageOneOf6TypeEnum? get type => _$this._type;
  set type(PluginControlServerMessageOneOf6TypeEnum? type) =>
      _$this._type = type;

  PluginControlServerMessageOneOf6Builder() {
    PluginControlServerMessageOneOf6._defaults(this);
  }

  PluginControlServerMessageOneOf6Builder get _$this {
    final $v = _$v;
    if ($v != null) {
      _tunnelId = $v.tunnelId;
      _type = $v.type;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PluginControlServerMessageOneOf6 other) {
    _$v = other as _$PluginControlServerMessageOneOf6;
  }

  @override
  void update(void Function(PluginControlServerMessageOneOf6Builder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PluginControlServerMessageOneOf6 build() => _build();

  _$PluginControlServerMessageOneOf6 _build() {
    final _$result =
        _$v ??
        _$PluginControlServerMessageOneOf6._(
          tunnelId: BuiltValueNullFieldError.checkNotNull(
            tunnelId,
            r'PluginControlServerMessageOneOf6',
            'tunnelId',
          ),
          type: BuiltValueNullFieldError.checkNotNull(
            type,
            r'PluginControlServerMessageOneOf6',
            'type',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
