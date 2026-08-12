// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const HealthStatusStatusEnum _$healthStatusStatusEnum_ok =
    const HealthStatusStatusEnum._('ok');

HealthStatusStatusEnum _$healthStatusStatusEnumValueOf(String name) {
  switch (name) {
    case 'ok':
      return _$healthStatusStatusEnum_ok;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<HealthStatusStatusEnum> _$healthStatusStatusEnumValues =
    BuiltSet<HealthStatusStatusEnum>(const <HealthStatusStatusEnum>[
      _$healthStatusStatusEnum_ok,
    ]);

Serializer<HealthStatusStatusEnum> _$healthStatusStatusEnumSerializer =
    _$HealthStatusStatusEnumSerializer();

class _$HealthStatusStatusEnumSerializer
    implements PrimitiveSerializer<HealthStatusStatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{'ok': 'ok'};
  static const Map<Object, String> _fromWire = const <Object, String>{
    'ok': 'ok',
  };

  @override
  final Iterable<Type> types = const <Type>[HealthStatusStatusEnum];
  @override
  final String wireName = 'HealthStatusStatusEnum';

  @override
  Object serialize(
    Serializers serializers,
    HealthStatusStatusEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  HealthStatusStatusEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => HealthStatusStatusEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$HealthStatus extends HealthStatus {
  @override
  final HealthStatusStatusEnum status;

  factory _$HealthStatus([void Function(HealthStatusBuilder)? updates]) =>
      (HealthStatusBuilder()..update(updates))._build();

  _$HealthStatus._({required this.status}) : super._();
  @override
  HealthStatus rebuild(void Function(HealthStatusBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  HealthStatusBuilder toBuilder() => HealthStatusBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is HealthStatus && status == other.status;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'HealthStatus',
    )..add('status', status)).toString();
  }
}

class HealthStatusBuilder
    implements Builder<HealthStatus, HealthStatusBuilder> {
  _$HealthStatus? _$v;

  HealthStatusStatusEnum? _status;
  HealthStatusStatusEnum? get status => _$this._status;
  set status(HealthStatusStatusEnum? status) => _$this._status = status;

  HealthStatusBuilder() {
    HealthStatus._defaults(this);
  }

  HealthStatusBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _status = $v.status;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(HealthStatus other) {
    _$v = other as _$HealthStatus;
  }

  @override
  void update(void Function(HealthStatusBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  HealthStatus build() => _build();

  _$HealthStatus _build() {
    final _$result =
        _$v ??
        _$HealthStatus._(
          status: BuiltValueNullFieldError.checkNotNull(
            status,
            r'HealthStatus',
            'status',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
