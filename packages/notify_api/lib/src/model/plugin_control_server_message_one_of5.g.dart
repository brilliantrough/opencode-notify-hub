// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_control_server_message_one_of5.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const PluginControlServerMessageOneOf5TypeEnum
_$pluginControlServerMessageOneOf5TypeEnum_webuiHttpRequest =
    const PluginControlServerMessageOneOf5TypeEnum._('webuiHttpRequest');

PluginControlServerMessageOneOf5TypeEnum
_$pluginControlServerMessageOneOf5TypeEnumValueOf(String name) {
  switch (name) {
    case 'webuiHttpRequest':
      return _$pluginControlServerMessageOneOf5TypeEnum_webuiHttpRequest;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PluginControlServerMessageOneOf5TypeEnum>
_$pluginControlServerMessageOneOf5TypeEnumValues =
    BuiltSet<PluginControlServerMessageOneOf5TypeEnum>(
      const <PluginControlServerMessageOneOf5TypeEnum>[
        _$pluginControlServerMessageOneOf5TypeEnum_webuiHttpRequest,
      ],
    );

Serializer<PluginControlServerMessageOneOf5TypeEnum>
_$pluginControlServerMessageOneOf5TypeEnumSerializer =
    _$PluginControlServerMessageOneOf5TypeEnumSerializer();

class _$PluginControlServerMessageOneOf5TypeEnumSerializer
    implements PrimitiveSerializer<PluginControlServerMessageOneOf5TypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'webuiHttpRequest': 'webui_http_request',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'webui_http_request': 'webuiHttpRequest',
  };

  @override
  final Iterable<Type> types = const <Type>[
    PluginControlServerMessageOneOf5TypeEnum,
  ];
  @override
  final String wireName = 'PluginControlServerMessageOneOf5TypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    PluginControlServerMessageOneOf5TypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  PluginControlServerMessageOneOf5TypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => PluginControlServerMessageOneOf5TypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$PluginControlServerMessageOneOf5
    extends PluginControlServerMessageOneOf5 {
  @override
  final String? body;
  @override
  final BuiltMap<String, BuiltList<String>> headers;
  @override
  final String method;
  @override
  final String path;
  @override
  final String requestId;
  @override
  final String tunnelId;
  @override
  final PluginControlServerMessageOneOf5TypeEnum type;

  factory _$PluginControlServerMessageOneOf5([
    void Function(PluginControlServerMessageOneOf5Builder)? updates,
  ]) => (PluginControlServerMessageOneOf5Builder()..update(updates))._build();

  _$PluginControlServerMessageOneOf5._({
    this.body,
    required this.headers,
    required this.method,
    required this.path,
    required this.requestId,
    required this.tunnelId,
    required this.type,
  }) : super._();
  @override
  PluginControlServerMessageOneOf5 rebuild(
    void Function(PluginControlServerMessageOneOf5Builder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PluginControlServerMessageOneOf5Builder toBuilder() =>
      PluginControlServerMessageOneOf5Builder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PluginControlServerMessageOneOf5 &&
        body == other.body &&
        headers == other.headers &&
        method == other.method &&
        path == other.path &&
        requestId == other.requestId &&
        tunnelId == other.tunnelId &&
        type == other.type;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, body.hashCode);
    _$hash = $jc(_$hash, headers.hashCode);
    _$hash = $jc(_$hash, method.hashCode);
    _$hash = $jc(_$hash, path.hashCode);
    _$hash = $jc(_$hash, requestId.hashCode);
    _$hash = $jc(_$hash, tunnelId.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PluginControlServerMessageOneOf5')
          ..add('body', body)
          ..add('headers', headers)
          ..add('method', method)
          ..add('path', path)
          ..add('requestId', requestId)
          ..add('tunnelId', tunnelId)
          ..add('type', type))
        .toString();
  }
}

class PluginControlServerMessageOneOf5Builder
    implements
        Builder<
          PluginControlServerMessageOneOf5,
          PluginControlServerMessageOneOf5Builder
        > {
  _$PluginControlServerMessageOneOf5? _$v;

  String? _body;
  String? get body => _$this._body;
  set body(String? body) => _$this._body = body;

  MapBuilder<String, BuiltList<String>>? _headers;
  MapBuilder<String, BuiltList<String>> get headers =>
      _$this._headers ??= MapBuilder<String, BuiltList<String>>();
  set headers(MapBuilder<String, BuiltList<String>>? headers) =>
      _$this._headers = headers;

  String? _method;
  String? get method => _$this._method;
  set method(String? method) => _$this._method = method;

  String? _path;
  String? get path => _$this._path;
  set path(String? path) => _$this._path = path;

  String? _requestId;
  String? get requestId => _$this._requestId;
  set requestId(String? requestId) => _$this._requestId = requestId;

  String? _tunnelId;
  String? get tunnelId => _$this._tunnelId;
  set tunnelId(String? tunnelId) => _$this._tunnelId = tunnelId;

  PluginControlServerMessageOneOf5TypeEnum? _type;
  PluginControlServerMessageOneOf5TypeEnum? get type => _$this._type;
  set type(PluginControlServerMessageOneOf5TypeEnum? type) =>
      _$this._type = type;

  PluginControlServerMessageOneOf5Builder() {
    PluginControlServerMessageOneOf5._defaults(this);
  }

  PluginControlServerMessageOneOf5Builder get _$this {
    final $v = _$v;
    if ($v != null) {
      _body = $v.body;
      _headers = $v.headers.toBuilder();
      _method = $v.method;
      _path = $v.path;
      _requestId = $v.requestId;
      _tunnelId = $v.tunnelId;
      _type = $v.type;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PluginControlServerMessageOneOf5 other) {
    _$v = other as _$PluginControlServerMessageOneOf5;
  }

  @override
  void update(void Function(PluginControlServerMessageOneOf5Builder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PluginControlServerMessageOneOf5 build() => _build();

  _$PluginControlServerMessageOneOf5 _build() {
    _$PluginControlServerMessageOneOf5 _$result;
    try {
      _$result =
          _$v ??
          _$PluginControlServerMessageOneOf5._(
            body: body,
            headers: headers.build(),
            method: BuiltValueNullFieldError.checkNotNull(
              method,
              r'PluginControlServerMessageOneOf5',
              'method',
            ),
            path: BuiltValueNullFieldError.checkNotNull(
              path,
              r'PluginControlServerMessageOneOf5',
              'path',
            ),
            requestId: BuiltValueNullFieldError.checkNotNull(
              requestId,
              r'PluginControlServerMessageOneOf5',
              'requestId',
            ),
            tunnelId: BuiltValueNullFieldError.checkNotNull(
              tunnelId,
              r'PluginControlServerMessageOneOf5',
              'tunnelId',
            ),
            type: BuiltValueNullFieldError.checkNotNull(
              type,
              r'PluginControlServerMessageOneOf5',
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
          r'PluginControlServerMessageOneOf5',
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
