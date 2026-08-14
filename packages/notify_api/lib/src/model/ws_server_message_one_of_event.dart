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

part 'ws_server_message_one_of_event.g.dart';

/// WsServerMessageOneOfEvent
///
/// Properties:
/// * [eventId]
/// * [occurredAt]
/// * [payload]
/// * [session]
/// * [source_]
/// * [type]
@BuiltValue()
abstract class WsServerMessageOneOfEvent
    implements
        Built<WsServerMessageOneOfEvent, WsServerMessageOneOfEventBuilder> {
  /// One Of [NotifyEventOneOf], [NotifyEventOneOf1], [NotifyEventOneOf2], [NotifyEventOneOf3]
  OneOf get oneOf;

  WsServerMessageOneOfEvent._();

  factory WsServerMessageOneOfEvent([
    void updates(WsServerMessageOneOfEventBuilder b),
  ]) = _$WsServerMessageOneOfEvent;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(WsServerMessageOneOfEventBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<WsServerMessageOneOfEvent> get serializer =>
      _$WsServerMessageOneOfEventSerializer();
}

class _$WsServerMessageOneOfEventSerializer
    implements PrimitiveSerializer<WsServerMessageOneOfEvent> {
  @override
  final Iterable<Type> types = const [
    WsServerMessageOneOfEvent,
    _$WsServerMessageOneOfEvent,
  ];

  @override
  final String wireName = r'WsServerMessageOneOfEvent';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    WsServerMessageOneOfEvent object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {}

  @override
  Object serialize(
    Serializers serializers,
    WsServerMessageOneOfEvent object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final oneOf = object.oneOf;
    return serializers.serialize(
      oneOf.value,
      specifiedType: FullType(oneOf.valueType),
    )!;
  }

  @override
  WsServerMessageOneOfEvent deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = WsServerMessageOneOfEventBuilder();
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

class WsServerMessageOneOfEventTypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'heartbeat')
  static const WsServerMessageOneOfEventTypeEnum heartbeat =
      _$wsServerMessageOneOfEventTypeEnum_heartbeat;
  @BuiltValueEnumConst(wireName: r'action_required')
  static const WsServerMessageOneOfEventTypeEnum actionRequired =
      _$wsServerMessageOneOfEventTypeEnum_actionRequired;
  @BuiltValueEnumConst(wireName: r'action_resolved')
  static const WsServerMessageOneOfEventTypeEnum actionResolved =
      _$wsServerMessageOneOfEventTypeEnum_actionResolved;
  @BuiltValueEnumConst(wireName: r'terminal')
  static const WsServerMessageOneOfEventTypeEnum terminal =
      _$wsServerMessageOneOfEventTypeEnum_terminal;

  static Serializer<WsServerMessageOneOfEventTypeEnum> get serializer =>
      _$wsServerMessageOneOfEventTypeEnumSerializer;

  const WsServerMessageOneOfEventTypeEnum._(String name) : super(name);

  static BuiltSet<WsServerMessageOneOfEventTypeEnum> get values =>
      _$wsServerMessageOneOfEventTypeEnumValues;
  static WsServerMessageOneOfEventTypeEnum valueOf(String name) =>
      _$wsServerMessageOneOfEventTypeEnumValueOf(name);
}
