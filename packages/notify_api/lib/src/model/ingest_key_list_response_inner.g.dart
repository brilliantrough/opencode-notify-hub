// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ingest_key_list_response_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$IngestKeyListResponseInner extends IngestKeyListResponseInner {
  @override
  final DateTime createdAt;
  @override
  final String id;
  @override
  final DateTime? lastUsedAt;
  @override
  final String name;

  factory _$IngestKeyListResponseInner([
    void Function(IngestKeyListResponseInnerBuilder)? updates,
  ]) => (IngestKeyListResponseInnerBuilder()..update(updates))._build();

  _$IngestKeyListResponseInner._({
    required this.createdAt,
    required this.id,
    this.lastUsedAt,
    required this.name,
  }) : super._();
  @override
  IngestKeyListResponseInner rebuild(
    void Function(IngestKeyListResponseInnerBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  IngestKeyListResponseInnerBuilder toBuilder() =>
      IngestKeyListResponseInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is IngestKeyListResponseInner &&
        createdAt == other.createdAt &&
        id == other.id &&
        lastUsedAt == other.lastUsedAt &&
        name == other.name;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, lastUsedAt.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'IngestKeyListResponseInner')
          ..add('createdAt', createdAt)
          ..add('id', id)
          ..add('lastUsedAt', lastUsedAt)
          ..add('name', name))
        .toString();
  }
}

class IngestKeyListResponseInnerBuilder
    implements
        Builder<IngestKeyListResponseInner, IngestKeyListResponseInnerBuilder> {
  _$IngestKeyListResponseInner? _$v;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  DateTime? _lastUsedAt;
  DateTime? get lastUsedAt => _$this._lastUsedAt;
  set lastUsedAt(DateTime? lastUsedAt) => _$this._lastUsedAt = lastUsedAt;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  IngestKeyListResponseInnerBuilder() {
    IngestKeyListResponseInner._defaults(this);
  }

  IngestKeyListResponseInnerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _createdAt = $v.createdAt;
      _id = $v.id;
      _lastUsedAt = $v.lastUsedAt;
      _name = $v.name;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(IngestKeyListResponseInner other) {
    _$v = other as _$IngestKeyListResponseInner;
  }

  @override
  void update(void Function(IngestKeyListResponseInnerBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  IngestKeyListResponseInner build() => _build();

  _$IngestKeyListResponseInner _build() {
    final _$result =
        _$v ??
        _$IngestKeyListResponseInner._(
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'IngestKeyListResponseInner',
            'createdAt',
          ),
          id: BuiltValueNullFieldError.checkNotNull(
            id,
            r'IngestKeyListResponseInner',
            'id',
          ),
          lastUsedAt: lastUsedAt,
          name: BuiltValueNullFieldError.checkNotNull(
            name,
            r'IngestKeyListResponseInner',
            'name',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
