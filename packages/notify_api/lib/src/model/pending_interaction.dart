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

part 'pending_interaction.g.dart';

/// PendingInteraction
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
abstract class PendingInteraction
    implements Built<PendingInteraction, PendingInteractionBuilder> {
  /// One Of [PendingInteractionOneOf], [PendingInteractionOneOf1]
  OneOf get oneOf;

  PendingInteraction._();

  factory PendingInteraction([void updates(PendingInteractionBuilder b)]) =
      _$PendingInteraction;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PendingInteractionBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PendingInteraction> get serializer =>
      _$PendingInteractionSerializer();
}

class _$PendingInteractionSerializer
    implements PrimitiveSerializer<PendingInteraction> {
  @override
  final Iterable<Type> types = const [PendingInteraction, _$PendingInteraction];

  @override
  final String wireName = r'PendingInteraction';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PendingInteraction object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {}

  @override
  Object serialize(
    Serializers serializers,
    PendingInteraction object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final oneOf = object.oneOf;
    return serializers.serialize(
      oneOf.value,
      specifiedType: FullType(oneOf.valueType),
    )!;
  }

  @override
  PendingInteraction deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PendingInteractionBuilder();
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

class PendingInteractionKindEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'permission')
  static const PendingInteractionKindEnum permission =
      _$pendingInteractionKindEnum_permission;

  static Serializer<PendingInteractionKindEnum> get serializer =>
      _$pendingInteractionKindEnumSerializer;

  const PendingInteractionKindEnum._(String name) : super(name);

  static BuiltSet<PendingInteractionKindEnum> get values =>
      _$pendingInteractionKindEnumValues;
  static PendingInteractionKindEnum valueOf(String name) =>
      _$pendingInteractionKindEnumValueOf(name);
}
