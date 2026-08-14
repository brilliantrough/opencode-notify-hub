// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_snapshot_interactions_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const PendingSnapshotInteractionsInnerKindEnum
_$pendingSnapshotInteractionsInnerKindEnum_permission =
    const PendingSnapshotInteractionsInnerKindEnum._('permission');

PendingSnapshotInteractionsInnerKindEnum
_$pendingSnapshotInteractionsInnerKindEnumValueOf(String name) {
  switch (name) {
    case 'permission':
      return _$pendingSnapshotInteractionsInnerKindEnum_permission;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PendingSnapshotInteractionsInnerKindEnum>
_$pendingSnapshotInteractionsInnerKindEnumValues =
    BuiltSet<PendingSnapshotInteractionsInnerKindEnum>(
      const <PendingSnapshotInteractionsInnerKindEnum>[
        _$pendingSnapshotInteractionsInnerKindEnum_permission,
      ],
    );

Serializer<PendingSnapshotInteractionsInnerKindEnum>
_$pendingSnapshotInteractionsInnerKindEnumSerializer =
    _$PendingSnapshotInteractionsInnerKindEnumSerializer();

class _$PendingSnapshotInteractionsInnerKindEnumSerializer
    implements PrimitiveSerializer<PendingSnapshotInteractionsInnerKindEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'permission': 'permission',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'permission': 'permission',
  };

  @override
  final Iterable<Type> types = const <Type>[
    PendingSnapshotInteractionsInnerKindEnum,
  ];
  @override
  final String wireName = 'PendingSnapshotInteractionsInnerKindEnum';

  @override
  Object serialize(
    Serializers serializers,
    PendingSnapshotInteractionsInnerKindEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  PendingSnapshotInteractionsInnerKindEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => PendingSnapshotInteractionsInnerKindEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$PendingSnapshotInteractionsInner
    extends PendingSnapshotInteractionsInner {
  @override
  final OneOf oneOf;

  factory _$PendingSnapshotInteractionsInner([
    void Function(PendingSnapshotInteractionsInnerBuilder)? updates,
  ]) => (PendingSnapshotInteractionsInnerBuilder()..update(updates))._build();

  _$PendingSnapshotInteractionsInner._({required this.oneOf}) : super._();
  @override
  PendingSnapshotInteractionsInner rebuild(
    void Function(PendingSnapshotInteractionsInnerBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PendingSnapshotInteractionsInnerBuilder toBuilder() =>
      PendingSnapshotInteractionsInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PendingSnapshotInteractionsInner && oneOf == other.oneOf;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, oneOf.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'PendingSnapshotInteractionsInner',
    )..add('oneOf', oneOf)).toString();
  }
}

class PendingSnapshotInteractionsInnerBuilder
    implements
        Builder<
          PendingSnapshotInteractionsInner,
          PendingSnapshotInteractionsInnerBuilder
        > {
  _$PendingSnapshotInteractionsInner? _$v;

  OneOf? _oneOf;
  OneOf? get oneOf => _$this._oneOf;
  set oneOf(OneOf? oneOf) => _$this._oneOf = oneOf;

  PendingSnapshotInteractionsInnerBuilder() {
    PendingSnapshotInteractionsInner._defaults(this);
  }

  PendingSnapshotInteractionsInnerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _oneOf = $v.oneOf;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PendingSnapshotInteractionsInner other) {
    _$v = other as _$PendingSnapshotInteractionsInner;
  }

  @override
  void update(void Function(PendingSnapshotInteractionsInnerBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PendingSnapshotInteractionsInner build() => _build();

  _$PendingSnapshotInteractionsInner _build() {
    final _$result =
        _$v ??
        _$PendingSnapshotInteractionsInner._(
          oneOf: BuiltValueNullFieldError.checkNotNull(
            oneOf,
            r'PendingSnapshotInteractionsInner',
            'oneOf',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
