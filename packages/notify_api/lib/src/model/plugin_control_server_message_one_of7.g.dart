// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_control_server_message_one_of7.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const PluginControlServerMessageOneOf7TypeEnum
_$pluginControlServerMessageOneOf7TypeEnum_sessionCatalogRequest =
    const PluginControlServerMessageOneOf7TypeEnum._('sessionCatalogRequest');

PluginControlServerMessageOneOf7TypeEnum
_$pluginControlServerMessageOneOf7TypeEnumValueOf(String name) {
  switch (name) {
    case 'sessionCatalogRequest':
      return _$pluginControlServerMessageOneOf7TypeEnum_sessionCatalogRequest;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PluginControlServerMessageOneOf7TypeEnum>
_$pluginControlServerMessageOneOf7TypeEnumValues =
    BuiltSet<PluginControlServerMessageOneOf7TypeEnum>(
      const <PluginControlServerMessageOneOf7TypeEnum>[
        _$pluginControlServerMessageOneOf7TypeEnum_sessionCatalogRequest,
      ],
    );

Serializer<PluginControlServerMessageOneOf7TypeEnum>
_$pluginControlServerMessageOneOf7TypeEnumSerializer =
    _$PluginControlServerMessageOneOf7TypeEnumSerializer();

class _$PluginControlServerMessageOneOf7TypeEnumSerializer
    implements PrimitiveSerializer<PluginControlServerMessageOneOf7TypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'sessionCatalogRequest': 'session_catalog_request',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'session_catalog_request': 'sessionCatalogRequest',
  };

  @override
  final Iterable<Type> types = const <Type>[
    PluginControlServerMessageOneOf7TypeEnum,
  ];
  @override
  final String wireName = 'PluginControlServerMessageOneOf7TypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    PluginControlServerMessageOneOf7TypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  PluginControlServerMessageOneOf7TypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => PluginControlServerMessageOneOf7TypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$PluginControlServerMessageOneOf7
    extends PluginControlServerMessageOneOf7 {
  @override
  final PluginControlServerMessageOneOf7Query query;
  @override
  final String requestId;
  @override
  final PluginControlServerMessageOneOf7TypeEnum type;

  factory _$PluginControlServerMessageOneOf7([
    void Function(PluginControlServerMessageOneOf7Builder)? updates,
  ]) => (PluginControlServerMessageOneOf7Builder()..update(updates))._build();

  _$PluginControlServerMessageOneOf7._({
    required this.query,
    required this.requestId,
    required this.type,
  }) : super._();
  @override
  PluginControlServerMessageOneOf7 rebuild(
    void Function(PluginControlServerMessageOneOf7Builder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PluginControlServerMessageOneOf7Builder toBuilder() =>
      PluginControlServerMessageOneOf7Builder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PluginControlServerMessageOneOf7 &&
        query == other.query &&
        requestId == other.requestId &&
        type == other.type;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, query.hashCode);
    _$hash = $jc(_$hash, requestId.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PluginControlServerMessageOneOf7')
          ..add('query', query)
          ..add('requestId', requestId)
          ..add('type', type))
        .toString();
  }
}

class PluginControlServerMessageOneOf7Builder
    implements
        Builder<
          PluginControlServerMessageOneOf7,
          PluginControlServerMessageOneOf7Builder
        > {
  _$PluginControlServerMessageOneOf7? _$v;

  PluginControlServerMessageOneOf7QueryBuilder? _query;
  PluginControlServerMessageOneOf7QueryBuilder get query =>
      _$this._query ??= PluginControlServerMessageOneOf7QueryBuilder();
  set query(PluginControlServerMessageOneOf7QueryBuilder? query) =>
      _$this._query = query;

  String? _requestId;
  String? get requestId => _$this._requestId;
  set requestId(String? requestId) => _$this._requestId = requestId;

  PluginControlServerMessageOneOf7TypeEnum? _type;
  PluginControlServerMessageOneOf7TypeEnum? get type => _$this._type;
  set type(PluginControlServerMessageOneOf7TypeEnum? type) =>
      _$this._type = type;

  PluginControlServerMessageOneOf7Builder() {
    PluginControlServerMessageOneOf7._defaults(this);
  }

  PluginControlServerMessageOneOf7Builder get _$this {
    final $v = _$v;
    if ($v != null) {
      _query = $v.query.toBuilder();
      _requestId = $v.requestId;
      _type = $v.type;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PluginControlServerMessageOneOf7 other) {
    _$v = other as _$PluginControlServerMessageOneOf7;
  }

  @override
  void update(void Function(PluginControlServerMessageOneOf7Builder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PluginControlServerMessageOneOf7 build() => _build();

  _$PluginControlServerMessageOneOf7 _build() {
    _$PluginControlServerMessageOneOf7 _$result;
    try {
      _$result =
          _$v ??
          _$PluginControlServerMessageOneOf7._(
            query: query.build(),
            requestId: BuiltValueNullFieldError.checkNotNull(
              requestId,
              r'PluginControlServerMessageOneOf7',
              'requestId',
            ),
            type: BuiltValueNullFieldError.checkNotNull(
              type,
              r'PluginControlServerMessageOneOf7',
              'type',
            ),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'query';
        query.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'PluginControlServerMessageOneOf7',
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
