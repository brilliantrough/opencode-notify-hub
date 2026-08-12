// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notify_event_one_of1_payload_one_of1.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const NotifyEventOneOf1PayloadOneOf1KindEnum
_$notifyEventOneOf1PayloadOneOf1KindEnum_permission =
    const NotifyEventOneOf1PayloadOneOf1KindEnum._('permission');

NotifyEventOneOf1PayloadOneOf1KindEnum
_$notifyEventOneOf1PayloadOneOf1KindEnumValueOf(String name) {
  switch (name) {
    case 'permission':
      return _$notifyEventOneOf1PayloadOneOf1KindEnum_permission;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<NotifyEventOneOf1PayloadOneOf1KindEnum>
_$notifyEventOneOf1PayloadOneOf1KindEnumValues =
    BuiltSet<NotifyEventOneOf1PayloadOneOf1KindEnum>(
      const <NotifyEventOneOf1PayloadOneOf1KindEnum>[
        _$notifyEventOneOf1PayloadOneOf1KindEnum_permission,
      ],
    );

Serializer<NotifyEventOneOf1PayloadOneOf1KindEnum>
_$notifyEventOneOf1PayloadOneOf1KindEnumSerializer =
    _$NotifyEventOneOf1PayloadOneOf1KindEnumSerializer();

class _$NotifyEventOneOf1PayloadOneOf1KindEnumSerializer
    implements PrimitiveSerializer<NotifyEventOneOf1PayloadOneOf1KindEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'permission': 'permission',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'permission': 'permission',
  };

  @override
  final Iterable<Type> types = const <Type>[
    NotifyEventOneOf1PayloadOneOf1KindEnum,
  ];
  @override
  final String wireName = 'NotifyEventOneOf1PayloadOneOf1KindEnum';

  @override
  Object serialize(
    Serializers serializers,
    NotifyEventOneOf1PayloadOneOf1KindEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  NotifyEventOneOf1PayloadOneOf1KindEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => NotifyEventOneOf1PayloadOneOf1KindEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$NotifyEventOneOf1PayloadOneOf1 extends NotifyEventOneOf1PayloadOneOf1 {
  @override
  final NotifyEventOneOf1PayloadOneOf1KindEnum kind;
  @override
  final NotifyEventOneOf1PayloadOneOf1Permission permission;
  @override
  final String requestId;

  factory _$NotifyEventOneOf1PayloadOneOf1([
    void Function(NotifyEventOneOf1PayloadOneOf1Builder)? updates,
  ]) => (NotifyEventOneOf1PayloadOneOf1Builder()..update(updates))._build();

  _$NotifyEventOneOf1PayloadOneOf1._({
    required this.kind,
    required this.permission,
    required this.requestId,
  }) : super._();
  @override
  NotifyEventOneOf1PayloadOneOf1 rebuild(
    void Function(NotifyEventOneOf1PayloadOneOf1Builder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  NotifyEventOneOf1PayloadOneOf1Builder toBuilder() =>
      NotifyEventOneOf1PayloadOneOf1Builder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NotifyEventOneOf1PayloadOneOf1 &&
        kind == other.kind &&
        permission == other.permission &&
        requestId == other.requestId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, kind.hashCode);
    _$hash = $jc(_$hash, permission.hashCode);
    _$hash = $jc(_$hash, requestId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'NotifyEventOneOf1PayloadOneOf1')
          ..add('kind', kind)
          ..add('permission', permission)
          ..add('requestId', requestId))
        .toString();
  }
}

class NotifyEventOneOf1PayloadOneOf1Builder
    implements
        Builder<
          NotifyEventOneOf1PayloadOneOf1,
          NotifyEventOneOf1PayloadOneOf1Builder
        > {
  _$NotifyEventOneOf1PayloadOneOf1? _$v;

  NotifyEventOneOf1PayloadOneOf1KindEnum? _kind;
  NotifyEventOneOf1PayloadOneOf1KindEnum? get kind => _$this._kind;
  set kind(NotifyEventOneOf1PayloadOneOf1KindEnum? kind) => _$this._kind = kind;

  NotifyEventOneOf1PayloadOneOf1PermissionBuilder? _permission;
  NotifyEventOneOf1PayloadOneOf1PermissionBuilder get permission =>
      _$this._permission ??= NotifyEventOneOf1PayloadOneOf1PermissionBuilder();
  set permission(NotifyEventOneOf1PayloadOneOf1PermissionBuilder? permission) =>
      _$this._permission = permission;

  String? _requestId;
  String? get requestId => _$this._requestId;
  set requestId(String? requestId) => _$this._requestId = requestId;

  NotifyEventOneOf1PayloadOneOf1Builder() {
    NotifyEventOneOf1PayloadOneOf1._defaults(this);
  }

  NotifyEventOneOf1PayloadOneOf1Builder get _$this {
    final $v = _$v;
    if ($v != null) {
      _kind = $v.kind;
      _permission = $v.permission.toBuilder();
      _requestId = $v.requestId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(NotifyEventOneOf1PayloadOneOf1 other) {
    _$v = other as _$NotifyEventOneOf1PayloadOneOf1;
  }

  @override
  void update(void Function(NotifyEventOneOf1PayloadOneOf1Builder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  NotifyEventOneOf1PayloadOneOf1 build() => _build();

  _$NotifyEventOneOf1PayloadOneOf1 _build() {
    _$NotifyEventOneOf1PayloadOneOf1 _$result;
    try {
      _$result =
          _$v ??
          _$NotifyEventOneOf1PayloadOneOf1._(
            kind: BuiltValueNullFieldError.checkNotNull(
              kind,
              r'NotifyEventOneOf1PayloadOneOf1',
              'kind',
            ),
            permission: permission.build(),
            requestId: BuiltValueNullFieldError.checkNotNull(
              requestId,
              r'NotifyEventOneOf1PayloadOneOf1',
              'requestId',
            ),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'permission';
        permission.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'NotifyEventOneOf1PayloadOneOf1',
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
