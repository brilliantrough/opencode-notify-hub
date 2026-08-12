// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_ingest_key_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreateIngestKeyResponse extends CreateIngestKeyResponse {
  @override
  final DateTime createdAt;
  @override
  final String id;
  @override
  final String name;
  @override
  final String secret;

  factory _$CreateIngestKeyResponse([
    void Function(CreateIngestKeyResponseBuilder)? updates,
  ]) => (CreateIngestKeyResponseBuilder()..update(updates))._build();

  _$CreateIngestKeyResponse._({
    required this.createdAt,
    required this.id,
    required this.name,
    required this.secret,
  }) : super._();
  @override
  CreateIngestKeyResponse rebuild(
    void Function(CreateIngestKeyResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CreateIngestKeyResponseBuilder toBuilder() =>
      CreateIngestKeyResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateIngestKeyResponse &&
        createdAt == other.createdAt &&
        id == other.id &&
        name == other.name &&
        secret == other.secret;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, secret.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreateIngestKeyResponse')
          ..add('createdAt', createdAt)
          ..add('id', id)
          ..add('name', name)
          ..add('secret', secret))
        .toString();
  }
}

class CreateIngestKeyResponseBuilder
    implements
        Builder<CreateIngestKeyResponse, CreateIngestKeyResponseBuilder> {
  _$CreateIngestKeyResponse? _$v;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _secret;
  String? get secret => _$this._secret;
  set secret(String? secret) => _$this._secret = secret;

  CreateIngestKeyResponseBuilder() {
    CreateIngestKeyResponse._defaults(this);
  }

  CreateIngestKeyResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _createdAt = $v.createdAt;
      _id = $v.id;
      _name = $v.name;
      _secret = $v.secret;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateIngestKeyResponse other) {
    _$v = other as _$CreateIngestKeyResponse;
  }

  @override
  void update(void Function(CreateIngestKeyResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateIngestKeyResponse build() => _build();

  _$CreateIngestKeyResponse _build() {
    final _$result =
        _$v ??
        _$CreateIngestKeyResponse._(
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'CreateIngestKeyResponse',
            'createdAt',
          ),
          id: BuiltValueNullFieldError.checkNotNull(
            id,
            r'CreateIngestKeyResponse',
            'id',
          ),
          name: BuiltValueNullFieldError.checkNotNull(
            name,
            r'CreateIngestKeyResponse',
            'name',
          ),
          secret: BuiltValueNullFieldError.checkNotNull(
            secret,
            r'CreateIngestKeyResponse',
            'secret',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
