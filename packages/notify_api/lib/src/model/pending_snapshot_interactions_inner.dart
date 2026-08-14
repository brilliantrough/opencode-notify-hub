//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:notify_api/src/model/pending_interaction_one_of_questions_inner.dart';
import 'package:notify_api/src/model/pending_interaction_one_of_tool.dart';
import 'package:built_collection/built_collection.dart';
import 'package:notify_api/src/model/pending_interaction_one_of.dart';
import 'package:notify_api/src/model/pending_interaction_one_of1.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:one_of/one_of.dart';

part 'pending_snapshot_interactions_inner.g.dart';

/// PendingSnapshotInteractionsInner
///
/// Properties:
/// * [directory]
/// * [instanceId]
/// * [kind]
/// * [machine]
/// * [occurredAt]
/// * [project]
/// * [questions]
/// * [requestId]
/// * [sessionId]
/// * [sessionTitle]
/// * [tool]
/// * [always]
/// * [metadata]
/// * [patterns]
/// * [permission]
@BuiltValue()
abstract class PendingSnapshotInteractionsInner
    implements
        Built<
          PendingSnapshotInteractionsInner,
          PendingSnapshotInteractionsInnerBuilder
        > {
  /// One Of [PendingInteractionOneOf], [PendingInteractionOneOf1]
  OneOf get oneOf;

  PendingSnapshotInteractionsInner._();

  factory PendingSnapshotInteractionsInner([
    void updates(PendingSnapshotInteractionsInnerBuilder b),
  ]) = _$PendingSnapshotInteractionsInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PendingSnapshotInteractionsInnerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PendingSnapshotInteractionsInner> get serializer =>
      _$PendingSnapshotInteractionsInnerSerializer();
}

class _$PendingSnapshotInteractionsInnerSerializer
    implements PrimitiveSerializer<PendingSnapshotInteractionsInner> {
  @override
  final Iterable<Type> types = const [
    PendingSnapshotInteractionsInner,
    _$PendingSnapshotInteractionsInner,
  ];

  @override
  final String wireName = r'PendingSnapshotInteractionsInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PendingSnapshotInteractionsInner object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {}

  @override
  Object serialize(
    Serializers serializers,
    PendingSnapshotInteractionsInner object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final oneOf = object.oneOf;
    return serializers.serialize(
      oneOf.value,
      specifiedType: FullType(oneOf.valueType),
    )!;
  }

  @override
  PendingSnapshotInteractionsInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PendingSnapshotInteractionsInnerBuilder();
    Object? oneOfDataSrc;
    final targetType = const FullType(OneOf, [
      FullType(PendingInteractionOneOf),
      FullType(PendingInteractionOneOf1),
    ]);
    oneOfDataSrc = serialized;
    result.oneOf =
        serializers.deserialize(oneOfDataSrc, specifiedType: targetType)
            as OneOf;
    return result.build();
  }
}

class PendingSnapshotInteractionsInnerKindEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'permission')
  static const PendingSnapshotInteractionsInnerKindEnum permission =
      _$pendingSnapshotInteractionsInnerKindEnum_permission;

  static Serializer<PendingSnapshotInteractionsInnerKindEnum> get serializer =>
      _$pendingSnapshotInteractionsInnerKindEnumSerializer;

  const PendingSnapshotInteractionsInnerKindEnum._(String name) : super(name);

  static BuiltSet<PendingSnapshotInteractionsInnerKindEnum> get values =>
      _$pendingSnapshotInteractionsInnerKindEnumValues;
  static PendingSnapshotInteractionsInnerKindEnum valueOf(String name) =>
      _$pendingSnapshotInteractionsInnerKindEnumValueOf(name);
}
