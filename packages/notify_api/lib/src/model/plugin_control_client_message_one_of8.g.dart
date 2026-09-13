// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_control_client_message_one_of8.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const PluginControlClientMessageOneOf8StatusEnum
_$pluginControlClientMessageOneOf8StatusEnum_ready =
    const PluginControlClientMessageOneOf8StatusEnum._('ready');
const PluginControlClientMessageOneOf8StatusEnum
_$pluginControlClientMessageOneOf8StatusEnum_error =
    const PluginControlClientMessageOneOf8StatusEnum._('error');
const PluginControlClientMessageOneOf8StatusEnum
_$pluginControlClientMessageOneOf8StatusEnum_unsupported =
    const PluginControlClientMessageOneOf8StatusEnum._('unsupported');

PluginControlClientMessageOneOf8StatusEnum
_$pluginControlClientMessageOneOf8StatusEnumValueOf(String name) {
  switch (name) {
    case 'ready':
      return _$pluginControlClientMessageOneOf8StatusEnum_ready;
    case 'error':
      return _$pluginControlClientMessageOneOf8StatusEnum_error;
    case 'unsupported':
      return _$pluginControlClientMessageOneOf8StatusEnum_unsupported;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PluginControlClientMessageOneOf8StatusEnum>
_$pluginControlClientMessageOneOf8StatusEnumValues =
    BuiltSet<PluginControlClientMessageOneOf8StatusEnum>(
      const <PluginControlClientMessageOneOf8StatusEnum>[
        _$pluginControlClientMessageOneOf8StatusEnum_ready,
        _$pluginControlClientMessageOneOf8StatusEnum_error,
        _$pluginControlClientMessageOneOf8StatusEnum_unsupported,
      ],
    );

const PluginControlClientMessageOneOf8TypeEnum
_$pluginControlClientMessageOneOf8TypeEnum_sessionCatalogResponse =
    const PluginControlClientMessageOneOf8TypeEnum._('sessionCatalogResponse');

PluginControlClientMessageOneOf8TypeEnum
_$pluginControlClientMessageOneOf8TypeEnumValueOf(String name) {
  switch (name) {
    case 'sessionCatalogResponse':
      return _$pluginControlClientMessageOneOf8TypeEnum_sessionCatalogResponse;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PluginControlClientMessageOneOf8TypeEnum>
_$pluginControlClientMessageOneOf8TypeEnumValues =
    BuiltSet<PluginControlClientMessageOneOf8TypeEnum>(
      const <PluginControlClientMessageOneOf8TypeEnum>[
        _$pluginControlClientMessageOneOf8TypeEnum_sessionCatalogResponse,
      ],
    );

Serializer<PluginControlClientMessageOneOf8StatusEnum>
_$pluginControlClientMessageOneOf8StatusEnumSerializer =
    _$PluginControlClientMessageOneOf8StatusEnumSerializer();
Serializer<PluginControlClientMessageOneOf8TypeEnum>
_$pluginControlClientMessageOneOf8TypeEnumSerializer =
    _$PluginControlClientMessageOneOf8TypeEnumSerializer();

class _$PluginControlClientMessageOneOf8StatusEnumSerializer
    implements PrimitiveSerializer<PluginControlClientMessageOneOf8StatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'ready': 'ready',
    'error': 'error',
    'unsupported': 'unsupported',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'ready': 'ready',
    'error': 'error',
    'unsupported': 'unsupported',
  };

  @override
  final Iterable<Type> types = const <Type>[
    PluginControlClientMessageOneOf8StatusEnum,
  ];
  @override
  final String wireName = 'PluginControlClientMessageOneOf8StatusEnum';

  @override
  Object serialize(
    Serializers serializers,
    PluginControlClientMessageOneOf8StatusEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  PluginControlClientMessageOneOf8StatusEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => PluginControlClientMessageOneOf8StatusEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$PluginControlClientMessageOneOf8TypeEnumSerializer
    implements PrimitiveSerializer<PluginControlClientMessageOneOf8TypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'sessionCatalogResponse': 'session_catalog_response',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'session_catalog_response': 'sessionCatalogResponse',
  };

  @override
  final Iterable<Type> types = const <Type>[
    PluginControlClientMessageOneOf8TypeEnum,
  ];
  @override
  final String wireName = 'PluginControlClientMessageOneOf8TypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    PluginControlClientMessageOneOf8TypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  PluginControlClientMessageOneOf8TypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => PluginControlClientMessageOneOf8TypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$PluginControlClientMessageOneOf8
    extends PluginControlClientMessageOneOf8 {
  @override
  final PluginControlClientMessageOneOf8Catalog? catalog;
  @override
  final String instanceId;
  @override
  final String requestId;
  @override
  final PluginControlClientMessageOneOf8StatusEnum status;
  @override
  final PluginControlClientMessageOneOf8TypeEnum type;

  factory _$PluginControlClientMessageOneOf8([
    void Function(PluginControlClientMessageOneOf8Builder)? updates,
  ]) => (PluginControlClientMessageOneOf8Builder()..update(updates))._build();

  _$PluginControlClientMessageOneOf8._({
    this.catalog,
    required this.instanceId,
    required this.requestId,
    required this.status,
    required this.type,
  }) : super._();
  @override
  PluginControlClientMessageOneOf8 rebuild(
    void Function(PluginControlClientMessageOneOf8Builder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PluginControlClientMessageOneOf8Builder toBuilder() =>
      PluginControlClientMessageOneOf8Builder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PluginControlClientMessageOneOf8 &&
        catalog == other.catalog &&
        instanceId == other.instanceId &&
        requestId == other.requestId &&
        status == other.status &&
        type == other.type;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, catalog.hashCode);
    _$hash = $jc(_$hash, instanceId.hashCode);
    _$hash = $jc(_$hash, requestId.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PluginControlClientMessageOneOf8')
          ..add('catalog', catalog)
          ..add('instanceId', instanceId)
          ..add('requestId', requestId)
          ..add('status', status)
          ..add('type', type))
        .toString();
  }
}

class PluginControlClientMessageOneOf8Builder
    implements
        Builder<
          PluginControlClientMessageOneOf8,
          PluginControlClientMessageOneOf8Builder
        > {
  _$PluginControlClientMessageOneOf8? _$v;

  PluginControlClientMessageOneOf8CatalogBuilder? _catalog;
  PluginControlClientMessageOneOf8CatalogBuilder get catalog =>
      _$this._catalog ??= PluginControlClientMessageOneOf8CatalogBuilder();
  set catalog(PluginControlClientMessageOneOf8CatalogBuilder? catalog) =>
      _$this._catalog = catalog;

  String? _instanceId;
  String? get instanceId => _$this._instanceId;
  set instanceId(String? instanceId) => _$this._instanceId = instanceId;

  String? _requestId;
  String? get requestId => _$this._requestId;
  set requestId(String? requestId) => _$this._requestId = requestId;

  PluginControlClientMessageOneOf8StatusEnum? _status;
  PluginControlClientMessageOneOf8StatusEnum? get status => _$this._status;
  set status(PluginControlClientMessageOneOf8StatusEnum? status) =>
      _$this._status = status;

  PluginControlClientMessageOneOf8TypeEnum? _type;
  PluginControlClientMessageOneOf8TypeEnum? get type => _$this._type;
  set type(PluginControlClientMessageOneOf8TypeEnum? type) =>
      _$this._type = type;

  PluginControlClientMessageOneOf8Builder() {
    PluginControlClientMessageOneOf8._defaults(this);
  }

  PluginControlClientMessageOneOf8Builder get _$this {
    final $v = _$v;
    if ($v != null) {
      _catalog = $v.catalog?.toBuilder();
      _instanceId = $v.instanceId;
      _requestId = $v.requestId;
      _status = $v.status;
      _type = $v.type;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PluginControlClientMessageOneOf8 other) {
    _$v = other as _$PluginControlClientMessageOneOf8;
  }

  @override
  void update(void Function(PluginControlClientMessageOneOf8Builder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PluginControlClientMessageOneOf8 build() => _build();

  _$PluginControlClientMessageOneOf8 _build() {
    _$PluginControlClientMessageOneOf8 _$result;
    try {
      _$result =
          _$v ??
          _$PluginControlClientMessageOneOf8._(
            catalog: _catalog?.build(),
            instanceId: BuiltValueNullFieldError.checkNotNull(
              instanceId,
              r'PluginControlClientMessageOneOf8',
              'instanceId',
            ),
            requestId: BuiltValueNullFieldError.checkNotNull(
              requestId,
              r'PluginControlClientMessageOneOf8',
              'requestId',
            ),
            status: BuiltValueNullFieldError.checkNotNull(
              status,
              r'PluginControlClientMessageOneOf8',
              'status',
            ),
            type: BuiltValueNullFieldError.checkNotNull(
              type,
              r'PluginControlClientMessageOneOf8',
              'type',
            ),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'catalog';
        _catalog?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'PluginControlClientMessageOneOf8',
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
