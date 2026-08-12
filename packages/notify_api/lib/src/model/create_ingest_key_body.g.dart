// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_ingest_key_body.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreateIngestKeyBody extends CreateIngestKeyBody {
  @override
  final String name;

  factory _$CreateIngestKeyBody([
    void Function(CreateIngestKeyBodyBuilder)? updates,
  ]) => (CreateIngestKeyBodyBuilder()..update(updates))._build();

  _$CreateIngestKeyBody._({required this.name}) : super._();
  @override
  CreateIngestKeyBody rebuild(
    void Function(CreateIngestKeyBodyBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CreateIngestKeyBodyBuilder toBuilder() =>
      CreateIngestKeyBodyBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateIngestKeyBody && name == other.name;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'CreateIngestKeyBody',
    )..add('name', name)).toString();
  }
}

class CreateIngestKeyBodyBuilder
    implements Builder<CreateIngestKeyBody, CreateIngestKeyBodyBuilder> {
  _$CreateIngestKeyBody? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  CreateIngestKeyBodyBuilder() {
    CreateIngestKeyBody._defaults(this);
  }

  CreateIngestKeyBodyBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateIngestKeyBody other) {
    _$v = other as _$CreateIngestKeyBody;
  }

  @override
  void update(void Function(CreateIngestKeyBodyBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateIngestKeyBody build() => _build();

  _$CreateIngestKeyBody _build() {
    final _$result =
        _$v ??
        _$CreateIngestKeyBody._(
          name: BuiltValueNullFieldError.checkNotNull(
            name,
            r'CreateIngestKeyBody',
            'name',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
