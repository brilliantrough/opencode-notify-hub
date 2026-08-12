// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'error_response_error.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ErrorResponseError extends ErrorResponseError {
  @override
  final String code;
  @override
  final String message;

  factory _$ErrorResponseError([
    void Function(ErrorResponseErrorBuilder)? updates,
  ]) => (ErrorResponseErrorBuilder()..update(updates))._build();

  _$ErrorResponseError._({required this.code, required this.message})
    : super._();
  @override
  ErrorResponseError rebuild(
    void Function(ErrorResponseErrorBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  ErrorResponseErrorBuilder toBuilder() =>
      ErrorResponseErrorBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ErrorResponseError &&
        code == other.code &&
        message == other.message;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, code.hashCode);
    _$hash = $jc(_$hash, message.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ErrorResponseError')
          ..add('code', code)
          ..add('message', message))
        .toString();
  }
}

class ErrorResponseErrorBuilder
    implements Builder<ErrorResponseError, ErrorResponseErrorBuilder> {
  _$ErrorResponseError? _$v;

  String? _code;
  String? get code => _$this._code;
  set code(String? code) => _$this._code = code;

  String? _message;
  String? get message => _$this._message;
  set message(String? message) => _$this._message = message;

  ErrorResponseErrorBuilder() {
    ErrorResponseError._defaults(this);
  }

  ErrorResponseErrorBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _code = $v.code;
      _message = $v.message;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ErrorResponseError other) {
    _$v = other as _$ErrorResponseError;
  }

  @override
  void update(void Function(ErrorResponseErrorBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ErrorResponseError build() => _build();

  _$ErrorResponseError _build() {
    final _$result =
        _$v ??
        _$ErrorResponseError._(
          code: BuiltValueNullFieldError.checkNotNull(
            code,
            r'ErrorResponseError',
            'code',
          ),
          message: BuiltValueNullFieldError.checkNotNull(
            message,
            r'ErrorResponseError',
            'message',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
