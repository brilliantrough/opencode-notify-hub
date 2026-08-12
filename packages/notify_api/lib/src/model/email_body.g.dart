// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'email_body.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$EmailBody extends EmailBody {
  @override
  final String email;

  factory _$EmailBody([void Function(EmailBodyBuilder)? updates]) =>
      (EmailBodyBuilder()..update(updates))._build();

  _$EmailBody._({required this.email}) : super._();
  @override
  EmailBody rebuild(void Function(EmailBodyBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  EmailBodyBuilder toBuilder() => EmailBodyBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is EmailBody && email == other.email;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, email.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'EmailBody',
    )..add('email', email)).toString();
  }
}

class EmailBodyBuilder implements Builder<EmailBody, EmailBodyBuilder> {
  _$EmailBody? _$v;

  String? _email;
  String? get email => _$this._email;
  set email(String? email) => _$this._email = email;

  EmailBodyBuilder() {
    EmailBody._defaults(this);
  }

  EmailBodyBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _email = $v.email;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(EmailBody other) {
    _$v = other as _$EmailBody;
  }

  @override
  void update(void Function(EmailBodyBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  EmailBody build() => _build();

  _$EmailBody _build() {
    final _$result =
        _$v ??
        _$EmailBody._(
          email: BuiltValueNullFieldError.checkNotNull(
            email,
            r'EmailBody',
            'email',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
