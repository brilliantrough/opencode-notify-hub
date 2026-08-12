// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_body.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$RegisterBody extends RegisterBody {
  @override
  final String email;
  @override
  final String password;

  factory _$RegisterBody([void Function(RegisterBodyBuilder)? updates]) =>
      (RegisterBodyBuilder()..update(updates))._build();

  _$RegisterBody._({required this.email, required this.password}) : super._();
  @override
  RegisterBody rebuild(void Function(RegisterBodyBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RegisterBodyBuilder toBuilder() => RegisterBodyBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RegisterBody &&
        email == other.email &&
        password == other.password;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, email.hashCode);
    _$hash = $jc(_$hash, password.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RegisterBody')
          ..add('email', email)
          ..add('password', password))
        .toString();
  }
}

class RegisterBodyBuilder
    implements Builder<RegisterBody, RegisterBodyBuilder> {
  _$RegisterBody? _$v;

  String? _email;
  String? get email => _$this._email;
  set email(String? email) => _$this._email = email;

  String? _password;
  String? get password => _$this._password;
  set password(String? password) => _$this._password = password;

  RegisterBodyBuilder() {
    RegisterBody._defaults(this);
  }

  RegisterBodyBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _email = $v.email;
      _password = $v.password;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RegisterBody other) {
    _$v = other as _$RegisterBody;
  }

  @override
  void update(void Function(RegisterBodyBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RegisterBody build() => _build();

  _$RegisterBody _build() {
    final _$result =
        _$v ??
        _$RegisterBody._(
          email: BuiltValueNullFieldError.checkNotNull(
            email,
            r'RegisterBody',
            'email',
          ),
          password: BuiltValueNullFieldError.checkNotNull(
            password,
            r'RegisterBody',
            'password',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
