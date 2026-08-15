// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_snapshot.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PendingSnapshot extends PendingSnapshot {
  @override
  final DateTime generatedAt;
  @override
  final BuiltList<PendingSnapshotInteractionsInner> interactions;
  @override
  final BuiltList<String>? queriedInstanceIds;

  factory _$PendingSnapshot([void Function(PendingSnapshotBuilder)? updates]) =>
      (PendingSnapshotBuilder()..update(updates))._build();

  _$PendingSnapshot._({
    required this.generatedAt,
    required this.interactions,
    this.queriedInstanceIds,
  }) : super._();
  @override
  PendingSnapshot rebuild(void Function(PendingSnapshotBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PendingSnapshotBuilder toBuilder() => PendingSnapshotBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PendingSnapshot &&
        generatedAt == other.generatedAt &&
        interactions == other.interactions &&
        queriedInstanceIds == other.queriedInstanceIds;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, generatedAt.hashCode);
    _$hash = $jc(_$hash, interactions.hashCode);
    _$hash = $jc(_$hash, queriedInstanceIds.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PendingSnapshot')
          ..add('generatedAt', generatedAt)
          ..add('interactions', interactions)
          ..add('queriedInstanceIds', queriedInstanceIds))
        .toString();
  }
}

class PendingSnapshotBuilder
    implements Builder<PendingSnapshot, PendingSnapshotBuilder> {
  _$PendingSnapshot? _$v;

  DateTime? _generatedAt;
  DateTime? get generatedAt => _$this._generatedAt;
  set generatedAt(DateTime? generatedAt) => _$this._generatedAt = generatedAt;

  ListBuilder<PendingSnapshotInteractionsInner>? _interactions;
  ListBuilder<PendingSnapshotInteractionsInner> get interactions =>
      _$this._interactions ??= ListBuilder<PendingSnapshotInteractionsInner>();
  set interactions(
    ListBuilder<PendingSnapshotInteractionsInner>? interactions,
  ) => _$this._interactions = interactions;

  ListBuilder<String>? _queriedInstanceIds;
  ListBuilder<String> get queriedInstanceIds =>
      _$this._queriedInstanceIds ??= ListBuilder<String>();
  set queriedInstanceIds(ListBuilder<String>? queriedInstanceIds) =>
      _$this._queriedInstanceIds = queriedInstanceIds;

  PendingSnapshotBuilder() {
    PendingSnapshot._defaults(this);
  }

  PendingSnapshotBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _generatedAt = $v.generatedAt;
      _interactions = $v.interactions.toBuilder();
      _queriedInstanceIds = $v.queriedInstanceIds?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PendingSnapshot other) {
    _$v = other as _$PendingSnapshot;
  }

  @override
  void update(void Function(PendingSnapshotBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PendingSnapshot build() => _build();

  _$PendingSnapshot _build() {
    _$PendingSnapshot _$result;
    try {
      _$result =
          _$v ??
          _$PendingSnapshot._(
            generatedAt: BuiltValueNullFieldError.checkNotNull(
              generatedAt,
              r'PendingSnapshot',
              'generatedAt',
            ),
            interactions: interactions.build(),
            queriedInstanceIds: _queriedInstanceIds?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'interactions';
        interactions.build();
        _$failedField = 'queriedInstanceIds';
        _queriedInstanceIds?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'PendingSnapshot',
          _$failedField,
          e.toString(),
        );
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
