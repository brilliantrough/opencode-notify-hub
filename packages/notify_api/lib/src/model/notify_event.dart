//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:notify_api/src/model/notify_event_one_of2.dart';
import 'package:notify_api/src/model/notify_event_one_of1.dart';
import 'package:notify_api/src/model/notify_event_one_of3_payload.dart';
import 'package:notify_api/src/model/notify_event_one_of_source.dart';
import 'package:notify_api/src/model/notify_event_one_of3.dart';
import 'package:notify_api/src/model/notify_event_one_of_session.dart';
import 'package:notify_api/src/model/notify_event_one_of.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:one_of/one_of.dart';

part 'notify_event.g.dart';

/// NotifyEvent
///
/// Properties:
/// * [eventId]
/// * [occurredAt]
/// * [payload]
/// * [session]
/// * [source_]
/// * [type]
@BuiltValue()
abstract class NotifyEvent implements Built<NotifyEvent, NotifyEventBuilder> {
  /// One Of [NotifyEventOneOf], [NotifyEventOneOf1], [NotifyEventOneOf2], [NotifyEventOneOf3]
  OneOf get oneOf;

  NotifyEvent._();

  factory NotifyEvent([void updates(NotifyEventBuilder b)]) = _$NotifyEvent;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(NotifyEventBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<NotifyEvent> get serializer => _$NotifyEventSerializer();
}

class _$NotifyEventSerializer implements PrimitiveSerializer<NotifyEvent> {
  @override
  final Iterable<Type> types = const [NotifyEvent, _$NotifyEvent];

  @override
  final String wireName = r'NotifyEvent';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    NotifyEvent object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {}

  @override
  Object serialize(
    Serializers serializers,
    NotifyEvent object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final oneOf = object.oneOf;
    return serializers.serialize(
      oneOf.value,
      specifiedType: FullType(oneOf.valueType),
    )!;
  }

  @override
  NotifyEvent deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = NotifyEventBuilder();
    Object? oneOfDataSrc;
    final targetType = const FullType(OneOf, [
      FullType(NotifyEventOneOf),
      FullType(NotifyEventOneOf1),
      FullType(NotifyEventOneOf2),
      FullType(NotifyEventOneOf3),
    ]);
    oneOfDataSrc = serialized;
    result.oneOf =
        serializers.deserialize(oneOfDataSrc, specifiedType: targetType)
            as OneOf;
    return result.build();
  }
}

class NotifyEventTypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'heartbeat')
  static const NotifyEventTypeEnum heartbeat = _$notifyEventTypeEnum_heartbeat;
  @BuiltValueEnumConst(wireName: r'action_required')
  static const NotifyEventTypeEnum actionRequired =
      _$notifyEventTypeEnum_actionRequired;
  @BuiltValueEnumConst(wireName: r'action_resolved')
  static const NotifyEventTypeEnum actionResolved =
      _$notifyEventTypeEnum_actionResolved;
  @BuiltValueEnumConst(wireName: r'terminal')
  static const NotifyEventTypeEnum terminal = _$notifyEventTypeEnum_terminal;

  static Serializer<NotifyEventTypeEnum> get serializer =>
      _$notifyEventTypeEnumSerializer;

  const NotifyEventTypeEnum._(String name) : super(name);

  static BuiltSet<NotifyEventTypeEnum> get values =>
      _$notifyEventTypeEnumValues;
  static NotifyEventTypeEnum valueOf(String name) =>
      _$notifyEventTypeEnumValueOf(name);
}
