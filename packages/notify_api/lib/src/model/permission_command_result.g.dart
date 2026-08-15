// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'permission_command_result.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const PermissionCommandResultStatusEnum
_$permissionCommandResultStatusEnum_confirmed =
    const PermissionCommandResultStatusEnum._('confirmed');
const PermissionCommandResultStatusEnum
_$permissionCommandResultStatusEnum_stale =
    const PermissionCommandResultStatusEnum._('stale');
const PermissionCommandResultStatusEnum
_$permissionCommandResultStatusEnum_upstreamError =
    const PermissionCommandResultStatusEnum._('upstreamError');
const PermissionCommandResultStatusEnum
_$permissionCommandResultStatusEnum_resultUnknown =
    const PermissionCommandResultStatusEnum._('resultUnknown');

PermissionCommandResultStatusEnum _$permissionCommandResultStatusEnumValueOf(
  String name,
) {
  switch (name) {
    case 'confirmed':
      return _$permissionCommandResultStatusEnum_confirmed;
    case 'stale':
      return _$permissionCommandResultStatusEnum_stale;
    case 'upstreamError':
      return _$permissionCommandResultStatusEnum_upstreamError;
    case 'resultUnknown':
      return _$permissionCommandResultStatusEnum_resultUnknown;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PermissionCommandResultStatusEnum>
_$permissionCommandResultStatusEnumValues =
    BuiltSet<PermissionCommandResultStatusEnum>(
      const <PermissionCommandResultStatusEnum>[
        _$permissionCommandResultStatusEnum_confirmed,
        _$permissionCommandResultStatusEnum_stale,
        _$permissionCommandResultStatusEnum_upstreamError,
        _$permissionCommandResultStatusEnum_resultUnknown,
      ],
    );

Serializer<PermissionCommandResultStatusEnum>
_$permissionCommandResultStatusEnumSerializer =
    _$PermissionCommandResultStatusEnumSerializer();

class _$PermissionCommandResultStatusEnumSerializer
    implements PrimitiveSerializer<PermissionCommandResultStatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'confirmed': 'confirmed',
    'stale': 'stale',
    'upstreamError': 'upstream_error',
    'resultUnknown': 'result_unknown',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'confirmed': 'confirmed',
    'stale': 'stale',
    'upstream_error': 'upstreamError',
    'result_unknown': 'resultUnknown',
  };

  @override
  final Iterable<Type> types = const <Type>[PermissionCommandResultStatusEnum];
  @override
  final String wireName = 'PermissionCommandResultStatusEnum';

  @override
  Object serialize(
    Serializers serializers,
    PermissionCommandResultStatusEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  PermissionCommandResultStatusEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => PermissionCommandResultStatusEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$PermissionCommandResult extends PermissionCommandResult {
  @override
  final String commandId;
  @override
  final PermissionCommandResultStatusEnum status;

  factory _$PermissionCommandResult([
    void Function(PermissionCommandResultBuilder)? updates,
  ]) => (PermissionCommandResultBuilder()..update(updates))._build();

  _$PermissionCommandResult._({required this.commandId, required this.status})
    : super._();
  @override
  PermissionCommandResult rebuild(
    void Function(PermissionCommandResultBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PermissionCommandResultBuilder toBuilder() =>
      PermissionCommandResultBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PermissionCommandResult &&
        commandId == other.commandId &&
        status == other.status;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, commandId.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PermissionCommandResult')
          ..add('commandId', commandId)
          ..add('status', status))
        .toString();
  }
}

class PermissionCommandResultBuilder
    implements
        Builder<PermissionCommandResult, PermissionCommandResultBuilder> {
  _$PermissionCommandResult? _$v;

  String? _commandId;
  String? get commandId => _$this._commandId;
  set commandId(String? commandId) => _$this._commandId = commandId;

  PermissionCommandResultStatusEnum? _status;
  PermissionCommandResultStatusEnum? get status => _$this._status;
  set status(PermissionCommandResultStatusEnum? status) =>
      _$this._status = status;

  PermissionCommandResultBuilder() {
    PermissionCommandResult._defaults(this);
  }

  PermissionCommandResultBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _commandId = $v.commandId;
      _status = $v.status;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PermissionCommandResult other) {
    _$v = other as _$PermissionCommandResult;
  }

  @override
  void update(void Function(PermissionCommandResultBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PermissionCommandResult build() => _build();

  _$PermissionCommandResult _build() {
    final _$result =
        _$v ??
        _$PermissionCommandResult._(
          commandId: BuiltValueNullFieldError.checkNotNull(
            commandId,
            r'PermissionCommandResult',
            'commandId',
          ),
          status: BuiltValueNullFieldError.checkNotNull(
            status,
            r'PermissionCommandResult',
            'status',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
