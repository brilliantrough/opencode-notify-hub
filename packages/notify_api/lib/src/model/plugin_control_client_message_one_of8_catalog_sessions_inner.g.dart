// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_control_client_message_one_of8_catalog_sessions_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const PluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum
_$pluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum_idle =
    const PluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum._(
      'idle',
    );
const PluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum
_$pluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum_busy =
    const PluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum._(
      'busy',
    );
const PluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum
_$pluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum_retry =
    const PluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum._(
      'retry',
    );
const PluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum
_$pluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum_unknown =
    const PluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum._(
      'unknown',
    );

PluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum
_$pluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnumValueOf(
  String name,
) {
  switch (name) {
    case 'idle':
      return _$pluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum_idle;
    case 'busy':
      return _$pluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum_busy;
    case 'retry':
      return _$pluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum_retry;
    case 'unknown':
      return _$pluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum_unknown;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum>
_$pluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnumValues =
    BuiltSet<
      PluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum
    >(const <PluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum>[
      _$pluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum_idle,
      _$pluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum_busy,
      _$pluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum_retry,
      _$pluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum_unknown,
    ]);

Serializer<PluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum>
_$pluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnumSerializer =
    _$PluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnumSerializer();

class _$PluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnumSerializer
    implements
        PrimitiveSerializer<
          PluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum
        > {
  static const Map<String, Object> _toWire = const <String, Object>{
    'idle': 'idle',
    'busy': 'busy',
    'retry': 'retry',
    'unknown': 'unknown',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'idle': 'idle',
    'busy': 'busy',
    'retry': 'retry',
    'unknown': 'unknown',
  };

  @override
  final Iterable<Type> types = const <Type>[
    PluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum,
  ];
  @override
  final String wireName =
      'PluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum';

  @override
  Object serialize(
    Serializers serializers,
    PluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  PluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => PluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$PluginControlClientMessageOneOf8CatalogSessionsInner
    extends PluginControlClientMessageOneOf8CatalogSessionsInner {
  @override
  final String directory;
  @override
  final String sessionId;
  @override
  final PluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum status;
  @override
  final String title;
  @override
  final DateTime updatedAt;

  factory _$PluginControlClientMessageOneOf8CatalogSessionsInner([
    void Function(PluginControlClientMessageOneOf8CatalogSessionsInnerBuilder)?
    updates,
  ]) =>
      (PluginControlClientMessageOneOf8CatalogSessionsInnerBuilder()
            ..update(updates))
          ._build();

  _$PluginControlClientMessageOneOf8CatalogSessionsInner._({
    required this.directory,
    required this.sessionId,
    required this.status,
    required this.title,
    required this.updatedAt,
  }) : super._();
  @override
  PluginControlClientMessageOneOf8CatalogSessionsInner rebuild(
    void Function(PluginControlClientMessageOneOf8CatalogSessionsInnerBuilder)
    updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PluginControlClientMessageOneOf8CatalogSessionsInnerBuilder toBuilder() =>
      PluginControlClientMessageOneOf8CatalogSessionsInnerBuilder()
        ..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PluginControlClientMessageOneOf8CatalogSessionsInner &&
        directory == other.directory &&
        sessionId == other.sessionId &&
        status == other.status &&
        title == other.title &&
        updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, directory.hashCode);
    _$hash = $jc(_$hash, sessionId.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
            r'PluginControlClientMessageOneOf8CatalogSessionsInner',
          )
          ..add('directory', directory)
          ..add('sessionId', sessionId)
          ..add('status', status)
          ..add('title', title)
          ..add('updatedAt', updatedAt))
        .toString();
  }
}

class PluginControlClientMessageOneOf8CatalogSessionsInnerBuilder
    implements
        Builder<
          PluginControlClientMessageOneOf8CatalogSessionsInner,
          PluginControlClientMessageOneOf8CatalogSessionsInnerBuilder
        > {
  _$PluginControlClientMessageOneOf8CatalogSessionsInner? _$v;

  String? _directory;
  String? get directory => _$this._directory;
  set directory(String? directory) => _$this._directory = directory;

  String? _sessionId;
  String? get sessionId => _$this._sessionId;
  set sessionId(String? sessionId) => _$this._sessionId = sessionId;

  PluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum? _status;
  PluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum? get status =>
      _$this._status;
  set status(
    PluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum? status,
  ) => _$this._status = status;

  String? _title;
  String? get title => _$this._title;
  set title(String? title) => _$this._title = title;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  PluginControlClientMessageOneOf8CatalogSessionsInnerBuilder() {
    PluginControlClientMessageOneOf8CatalogSessionsInner._defaults(this);
  }

  PluginControlClientMessageOneOf8CatalogSessionsInnerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _directory = $v.directory;
      _sessionId = $v.sessionId;
      _status = $v.status;
      _title = $v.title;
      _updatedAt = $v.updatedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PluginControlClientMessageOneOf8CatalogSessionsInner other) {
    _$v = other as _$PluginControlClientMessageOneOf8CatalogSessionsInner;
  }

  @override
  void update(
    void Function(PluginControlClientMessageOneOf8CatalogSessionsInnerBuilder)?
    updates,
  ) {
    if (updates != null) updates(this);
  }

  @override
  PluginControlClientMessageOneOf8CatalogSessionsInner build() => _build();

  _$PluginControlClientMessageOneOf8CatalogSessionsInner _build() {
    final _$result =
        _$v ??
        _$PluginControlClientMessageOneOf8CatalogSessionsInner._(
          directory: BuiltValueNullFieldError.checkNotNull(
            directory,
            r'PluginControlClientMessageOneOf8CatalogSessionsInner',
            'directory',
          ),
          sessionId: BuiltValueNullFieldError.checkNotNull(
            sessionId,
            r'PluginControlClientMessageOneOf8CatalogSessionsInner',
            'sessionId',
          ),
          status: BuiltValueNullFieldError.checkNotNull(
            status,
            r'PluginControlClientMessageOneOf8CatalogSessionsInner',
            'status',
          ),
          title: BuiltValueNullFieldError.checkNotNull(
            title,
            r'PluginControlClientMessageOneOf8CatalogSessionsInner',
            'title',
          ),
          updatedAt: BuiltValueNullFieldError.checkNotNull(
            updatedAt,
            r'PluginControlClientMessageOneOf8CatalogSessionsInner',
            'updatedAt',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
