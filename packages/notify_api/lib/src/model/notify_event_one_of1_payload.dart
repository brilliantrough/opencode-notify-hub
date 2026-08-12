//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:notify_api/src/model/notify_event_one_of1_payload_one_of2.dart';
import 'package:notify_api/src/model/notify_event_one_of1_payload_one_of2_provider_action.dart';
import 'package:built_collection/built_collection.dart';
import 'package:notify_api/src/model/notify_event_one_of1_payload_one_of1.dart';
import 'package:notify_api/src/model/notify_event_one_of1_payload_one_of.dart';
import 'package:notify_api/src/model/notify_event_one_of1_payload_one_of_questions_inner.dart';
import 'package:notify_api/src/model/notify_event_one_of1_payload_one_of1_permission.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:one_of/one_of.dart';

part 'notify_event_one_of1_payload.g.dart';

/// NotifyEventOneOf1Payload
///
/// Properties:
/// * [kind]
/// * [questions]
/// * [requestId]
/// * [permission]
/// * [providerAction]
@BuiltValue()
abstract class NotifyEventOneOf1Payload
    implements
        Built<NotifyEventOneOf1Payload, NotifyEventOneOf1PayloadBuilder> {
  /// One Of [NotifyEventOneOf1PayloadOneOf], [NotifyEventOneOf1PayloadOneOf1], [NotifyEventOneOf1PayloadOneOf2]
  OneOf get oneOf;

  NotifyEventOneOf1Payload._();

  factory NotifyEventOneOf1Payload([
    void updates(NotifyEventOneOf1PayloadBuilder b),
  ]) = _$NotifyEventOneOf1Payload;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(NotifyEventOneOf1PayloadBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<NotifyEventOneOf1Payload> get serializer =>
      _$NotifyEventOneOf1PayloadSerializer();
}

class _$NotifyEventOneOf1PayloadSerializer
    implements PrimitiveSerializer<NotifyEventOneOf1Payload> {
  @override
  final Iterable<Type> types = const [
    NotifyEventOneOf1Payload,
    _$NotifyEventOneOf1Payload,
  ];

  @override
  final String wireName = r'NotifyEventOneOf1Payload';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    NotifyEventOneOf1Payload object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {}

  @override
  Object serialize(
    Serializers serializers,
    NotifyEventOneOf1Payload object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final oneOf = object.oneOf;
    return serializers.serialize(
      oneOf.value,
      specifiedType: FullType(oneOf.valueType),
    )!;
  }

  @override
  NotifyEventOneOf1Payload deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = NotifyEventOneOf1PayloadBuilder();
    Object? oneOfDataSrc;
    final targetType = const FullType(OneOf, [
      FullType(NotifyEventOneOf1PayloadOneOf),
      FullType(NotifyEventOneOf1PayloadOneOf1),
      FullType(NotifyEventOneOf1PayloadOneOf2),
    ]);
    oneOfDataSrc = serialized;
    result.oneOf =
        serializers.deserialize(oneOfDataSrc, specifiedType: targetType)
            as OneOf;
    return result.build();
  }
}

class NotifyEventOneOf1PayloadKindEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'provider_action')
  static const NotifyEventOneOf1PayloadKindEnum providerAction =
      _$notifyEventOneOf1PayloadKindEnum_providerAction;

  static Serializer<NotifyEventOneOf1PayloadKindEnum> get serializer =>
      _$notifyEventOneOf1PayloadKindEnumSerializer;

  const NotifyEventOneOf1PayloadKindEnum._(String name) : super(name);

  static BuiltSet<NotifyEventOneOf1PayloadKindEnum> get values =>
      _$notifyEventOneOf1PayloadKindEnumValues;
  static NotifyEventOneOf1PayloadKindEnum valueOf(String name) =>
      _$notifyEventOneOf1PayloadKindEnumValueOf(name);
}
