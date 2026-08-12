// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verify_email_body.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$VerifyEmailBody extends VerifyEmailBody {
  @override
  final String code;
  @override
  final String email;

  factory _$VerifyEmailBody([void Function(VerifyEmailBodyBuilder)? updates]) =>
      (VerifyEmailBodyBuilder()..update(updates))._build();

  _$VerifyEmailBody._({required this.code, required this.email}) : super._();
  @override
  VerifyEmailBody rebuild(void Function(VerifyEmailBodyBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  VerifyEmailBodyBuilder toBuilder() => VerifyEmailBodyBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is VerifyEmailBody &&
        code == other.code &&
        email == other.email;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, code.hashCode);
    _$hash = $jc(_$hash, email.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'VerifyEmailBody')
          ..add('code', code)
          ..add('email', email))
        .toString();
  }
}

class VerifyEmailBodyBuilder
    implements Builder<VerifyEmailBody, VerifyEmailBodyBuilder> {
  _$VerifyEmailBody? _$v;

  String? _code;
  String? get code => _$this._code;
  set code(String? code) => _$this._code = code;

  String? _email;
  String? get email => _$this._email;
  set email(String? email) => _$this._email = email;

  VerifyEmailBodyBuilder() {
    VerifyEmailBody._defaults(this);
  }

  VerifyEmailBodyBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _code = $v.code;
      _email = $v.email;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(VerifyEmailBody other) {
    _$v = other as _$VerifyEmailBody;
  }

  @override
  void update(void Function(VerifyEmailBodyBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  VerifyEmailBody build() => _build();

  _$VerifyEmailBody _build() {
    final _$result =
        _$v ??
        _$VerifyEmailBody._(
          code: BuiltValueNullFieldError.checkNotNull(
            code,
            r'VerifyEmailBody',
            'code',
          ),
          email: BuiltValueNullFieldError.checkNotNull(
            email,
            r'VerifyEmailBody',
            'email',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
