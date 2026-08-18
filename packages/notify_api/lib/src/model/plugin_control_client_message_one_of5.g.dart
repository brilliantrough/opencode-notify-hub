// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_control_client_message_one_of5.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const PluginControlClientMessageOneOf5TypeEnum
_$pluginControlClientMessageOneOf5TypeEnum_webuiHttpResponseStart =
    const PluginControlClientMessageOneOf5TypeEnum._('webuiHttpResponseStart');

PluginControlClientMessageOneOf5TypeEnum
_$pluginControlClientMessageOneOf5TypeEnumValueOf(String name) {
  switch (name) {
    case 'webuiHttpResponseStart':
      return _$pluginControlClientMessageOneOf5TypeEnum_webuiHttpResponseStart;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PluginControlClientMessageOneOf5TypeEnum>
_$pluginControlClientMessageOneOf5TypeEnumValues =
    BuiltSet<PluginControlClientMessageOneOf5TypeEnum>(
      const <PluginControlClientMessageOneOf5TypeEnum>[
        _$pluginControlClientMessageOneOf5TypeEnum_webuiHttpResponseStart,
      ],
    );

Serializer<PluginControlClientMessageOneOf5TypeEnum>
_$pluginControlClientMessageOneOf5TypeEnumSerializer =
    _$PluginControlClientMessageOneOf5TypeEnumSerializer();

class _$PluginControlClientMessageOneOf5TypeEnumSerializer
    implements PrimitiveSerializer<PluginControlClientMessageOneOf5TypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'webuiHttpResponseStart': 'webui_http_response_start',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'webui_http_response_start': 'webuiHttpResponseStart',
  };

  @override
  final Iterable<Type> types = const <Type>[
    PluginControlClientMessageOneOf5TypeEnum,
  ];
  @override
  final String wireName = 'PluginControlClientMessageOneOf5TypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    PluginControlClientMessageOneOf5TypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  PluginControlClientMessageOneOf5TypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => PluginControlClientMessageOneOf5TypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$PluginControlClientMessageOneOf5
    extends PluginControlClientMessageOneOf5 {
  @override
  final BuiltMap<String, BuiltList<String>> headers;
  @override
  final String requestId;
  @override
  final int status;
  @override
  final String tunnelId;
  @override
  final PluginControlClientMessageOneOf5TypeEnum type;

  factory _$PluginControlClientMessageOneOf5([
    void Function(PluginControlClientMessageOneOf5Builder)? updates,
  ]) => (PluginControlClientMessageOneOf5Builder()..update(updates))._build();

  _$PluginControlClientMessageOneOf5._({
    required this.headers,
    required this.requestId,
    required this.status,
    required this.tunnelId,
    required this.type,
  }) : super._();
  @override
  PluginControlClientMessageOneOf5 rebuild(
    void Function(PluginControlClientMessageOneOf5Builder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PluginControlClientMessageOneOf5Builder toBuilder() =>
      PluginControlClientMessageOneOf5Builder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PluginControlClientMessageOneOf5 &&
        headers == other.headers &&
        requestId == other.requestId &&
        status == other.status &&
        tunnelId == other.tunnelId &&
        type == other.type;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, headers.hashCode);
    _$hash = $jc(_$hash, requestId.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, tunnelId.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PluginControlClientMessageOneOf5')
          ..add('headers', headers)
          ..add('requestId', requestId)
          ..add('status', status)
          ..add('tunnelId', tunnelId)
          ..add('type', type))
        .toString();
  }
}

class PluginControlClientMessageOneOf5Builder
    implements
        Builder<
          PluginControlClientMessageOneOf5,
          PluginControlClientMessageOneOf5Builder
        > {
  _$PluginControlClientMessageOneOf5? _$v;

  MapBuilder<String, BuiltList<String>>? _headers;
  MapBuilder<String, BuiltList<String>> get headers =>
      _$this._headers ??= MapBuilder<String, BuiltList<String>>();
  set headers(MapBuilder<String, BuiltList<String>>? headers) =>
      _$this._headers = headers;

  String? _requestId;
  String? get requestId => _$this._requestId;
  set requestId(String? requestId) => _$this._requestId = requestId;

  int? _status;
  int? get status => _$this._status;
  set status(int? status) => _$this._status = status;

  String? _tunnelId;
  String? get tunnelId => _$this._tunnelId;
  set tunnelId(String? tunnelId) => _$this._tunnelId = tunnelId;

  PluginControlClientMessageOneOf5TypeEnum? _type;
  PluginControlClientMessageOneOf5TypeEnum? get type => _$this._type;
  set type(PluginControlClientMessageOneOf5TypeEnum? type) =>
      _$this._type = type;

  PluginControlClientMessageOneOf5Builder() {
    PluginControlClientMessageOneOf5._defaults(this);
  }

  PluginControlClientMessageOneOf5Builder get _$this {
    final $v = _$v;
    if ($v != null) {
      _headers = $v.headers.toBuilder();
      _requestId = $v.requestId;
      _status = $v.status;
      _tunnelId = $v.tunnelId;
      _type = $v.type;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PluginControlClientMessageOneOf5 other) {
    _$v = other as _$PluginControlClientMessageOneOf5;
  }

  @override
  void update(void Function(PluginControlClientMessageOneOf5Builder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PluginControlClientMessageOneOf5 build() => _build();

  _$PluginControlClientMessageOneOf5 _build() {
    _$PluginControlClientMessageOneOf5 _$result;
    try {
      _$result =
          _$v ??
          _$PluginControlClientMessageOneOf5._(
            headers: headers.build(),
            requestId: BuiltValueNullFieldError.checkNotNull(
              requestId,
              r'PluginControlClientMessageOneOf5',
              'requestId',
            ),
            status: BuiltValueNullFieldError.checkNotNull(
              status,
              r'PluginControlClientMessageOneOf5',
              'status',
            ),
            tunnelId: BuiltValueNullFieldError.checkNotNull(
              tunnelId,
              r'PluginControlClientMessageOneOf5',
              'tunnelId',
            ),
            type: BuiltValueNullFieldError.checkNotNull(
              type,
              r'PluginControlClientMessageOneOf5',
              'type',
            ),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'headers';
        headers.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'PluginControlClientMessageOneOf5',
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
