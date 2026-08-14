// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_interaction.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const PendingInteractionKindEnum _$pendingInteractionKindEnum_permission =
    const PendingInteractionKindEnum._('permission');

PendingInteractionKindEnum _$pendingInteractionKindEnumValueOf(String name) {
  switch (name) {
    case 'permission':
      return _$pendingInteractionKindEnum_permission;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PendingInteractionKindEnum> _$pendingInteractionKindEnumValues =
    BuiltSet<PendingInteractionKindEnum>(const <PendingInteractionKindEnum>[
      _$pendingInteractionKindEnum_permission,
    ]);

Serializer<PendingInteractionKindEnum> _$pendingInteractionKindEnumSerializer =
    _$PendingInteractionKindEnumSerializer();

class _$PendingInteractionKindEnumSerializer
    implements PrimitiveSerializer<PendingInteractionKindEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'permission': 'permission',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'permission': 'permission',
  };

  @override
  final Iterable<Type> types = const <Type>[PendingInteractionKindEnum];
  @override
  final String wireName = 'PendingInteractionKindEnum';

  @override
  Object serialize(
    Serializers serializers,
    PendingInteractionKindEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  PendingInteractionKindEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => PendingInteractionKindEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$PendingInteraction extends PendingInteraction {
  @override
  final OneOf oneOf;

  factory _$PendingInteraction([
    void Function(PendingInteractionBuilder)? updates,
  ]) => (PendingInteractionBuilder()..update(updates))._build();

  _$PendingInteraction._({required this.oneOf}) : super._();
  @override
  PendingInteraction rebuild(
    void Function(PendingInteractionBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PendingInteractionBuilder toBuilder() =>
      PendingInteractionBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PendingInteraction && oneOf == other.oneOf;
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
      r'PendingInteraction',
    )..add('oneOf', oneOf)).toString();
  }
}

class PendingInteractionBuilder
    implements Builder<PendingInteraction, PendingInteractionBuilder> {
  _$PendingInteraction? _$v;

  OneOf? _oneOf;
  OneOf? get oneOf => _$this._oneOf;
  set oneOf(OneOf? oneOf) => _$this._oneOf = oneOf;

  PendingInteractionBuilder() {
    PendingInteraction._defaults(this);
  }

  PendingInteractionBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _oneOf = $v.oneOf;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PendingInteraction other) {
    _$v = other as _$PendingInteraction;
  }

  @override
  void update(void Function(PendingInteractionBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PendingInteraction build() => _build();

  _$PendingInteraction _build() {
    final _$result =
        _$v ??
        _$PendingInteraction._(
          oneOf: BuiltValueNullFieldError.checkNotNull(
            oneOf,
            r'PendingInteraction',
            'oneOf',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
