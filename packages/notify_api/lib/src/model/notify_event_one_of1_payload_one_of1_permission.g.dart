// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notify_event_one_of1_payload_one_of1_permission.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$NotifyEventOneOf1PayloadOneOf1Permission
    extends NotifyEventOneOf1PayloadOneOf1Permission {
  @override
  final String permission;
  @override
  final String summary;

  factory _$NotifyEventOneOf1PayloadOneOf1Permission([
    void Function(NotifyEventOneOf1PayloadOneOf1PermissionBuilder)? updates,
  ]) => (NotifyEventOneOf1PayloadOneOf1PermissionBuilder()..update(updates))
      ._build();

  _$NotifyEventOneOf1PayloadOneOf1Permission._({
    required this.permission,
    required this.summary,
  }) : super._();
  @override
  NotifyEventOneOf1PayloadOneOf1Permission rebuild(
    void Function(NotifyEventOneOf1PayloadOneOf1PermissionBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  NotifyEventOneOf1PayloadOneOf1PermissionBuilder toBuilder() =>
      NotifyEventOneOf1PayloadOneOf1PermissionBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NotifyEventOneOf1PayloadOneOf1Permission &&
        permission == other.permission &&
        summary == other.summary;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, permission.hashCode);
    _$hash = $jc(_$hash, summary.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
            r'NotifyEventOneOf1PayloadOneOf1Permission',
          )
          ..add('permission', permission)
          ..add('summary', summary))
        .toString();
  }
}

class NotifyEventOneOf1PayloadOneOf1PermissionBuilder
    implements
        Builder<
          NotifyEventOneOf1PayloadOneOf1Permission,
          NotifyEventOneOf1PayloadOneOf1PermissionBuilder
        > {
  _$NotifyEventOneOf1PayloadOneOf1Permission? _$v;

  String? _permission;
  String? get permission => _$this._permission;
  set permission(String? permission) => _$this._permission = permission;

  String? _summary;
  String? get summary => _$this._summary;
  set summary(String? summary) => _$this._summary = summary;

  NotifyEventOneOf1PayloadOneOf1PermissionBuilder() {
    NotifyEventOneOf1PayloadOneOf1Permission._defaults(this);
  }

  NotifyEventOneOf1PayloadOneOf1PermissionBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _permission = $v.permission;
      _summary = $v.summary;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(NotifyEventOneOf1PayloadOneOf1Permission other) {
    _$v = other as _$NotifyEventOneOf1PayloadOneOf1Permission;
  }

  @override
  void update(
    void Function(NotifyEventOneOf1PayloadOneOf1PermissionBuilder)? updates,
  ) {
    if (updates != null) updates(this);
  }

  @override
  NotifyEventOneOf1PayloadOneOf1Permission build() => _build();

  _$NotifyEventOneOf1PayloadOneOf1Permission _build() {
    final _$result =
        _$v ??
        _$NotifyEventOneOf1PayloadOneOf1Permission._(
          permission: BuiltValueNullFieldError.checkNotNull(
            permission,
            r'NotifyEventOneOf1PayloadOneOf1Permission',
            'permission',
          ),
          summary: BuiltValueNullFieldError.checkNotNull(
            summary,
            r'NotifyEventOneOf1PayloadOneOf1Permission',
            'summary',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
