// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'refresh_body.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$RefreshBody extends RefreshBody {
  @override
  final String refreshToken;

  factory _$RefreshBody([void Function(RefreshBodyBuilder)? updates]) =>
      (RefreshBodyBuilder()..update(updates))._build();

  _$RefreshBody._({required this.refreshToken}) : super._();
  @override
  RefreshBody rebuild(void Function(RefreshBodyBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RefreshBodyBuilder toBuilder() => RefreshBodyBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RefreshBody && refreshToken == other.refreshToken;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, refreshToken.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'RefreshBody',
    )..add('refreshToken', refreshToken)).toString();
  }
}

class RefreshBodyBuilder implements Builder<RefreshBody, RefreshBodyBuilder> {
  _$RefreshBody? _$v;

  String? _refreshToken;
  String? get refreshToken => _$this._refreshToken;
  set refreshToken(String? refreshToken) => _$this._refreshToken = refreshToken;

  RefreshBodyBuilder() {
    RefreshBody._defaults(this);
  }

  RefreshBodyBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _refreshToken = $v.refreshToken;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RefreshBody other) {
    _$v = other as _$RefreshBody;
  }

  @override
  void update(void Function(RefreshBodyBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RefreshBody build() => _build();

  _$RefreshBody _build() {
    final _$result =
        _$v ??
        _$RefreshBody._(
          refreshToken: BuiltValueNullFieldError.checkNotNull(
            refreshToken,
            r'RefreshBody',
            'refreshToken',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
