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

part 'ws_server_message_event.g.dart';

/// WsServerMessageEvent
///
/// Properties:
/// * [eventId]
/// * [occurredAt]
/// * [payload]
/// * [session]
/// * [source_]
/// * [type]
@BuiltValue()
abstract class WsServerMessageEvent
    implements Built<WsServerMessageEvent, WsServerMessageEventBuilder> {
  /// One Of [NotifyEventOneOf], [NotifyEventOneOf1], [NotifyEventOneOf2], [NotifyEventOneOf3]
  OneOf get oneOf;

  WsServerMessageEvent._();

  factory WsServerMessageEvent([void updates(WsServerMessageEventBuilder b)]) =
      _$WsServerMessageEvent;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(WsServerMessageEventBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<WsServerMessageEvent> get serializer =>
      _$WsServerMessageEventSerializer();
}

class _$WsServerMessageEventSerializer
    implements PrimitiveSerializer<WsServerMessageEvent> {
  @override
  final Iterable<Type> types = const [
    WsServerMessageEvent,
    _$WsServerMessageEvent,
  ];

  @override
  final String wireName = r'WsServerMessageEvent';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    WsServerMessageEvent object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {}

  @override
  Object serialize(
    Serializers serializers,
    WsServerMessageEvent object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final oneOf = object.oneOf;
    return serializers.serialize(
      oneOf.value,
      specifiedType: FullType(oneOf.valueType),
    )!;
  }

  @override
  WsServerMessageEvent deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = WsServerMessageEventBuilder();
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

class WsServerMessageEventTypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'heartbeat')
  static const WsServerMessageEventTypeEnum heartbeat =
      _$wsServerMessageEventTypeEnum_heartbeat;
  @BuiltValueEnumConst(wireName: r'action_required')
  static const WsServerMessageEventTypeEnum actionRequired =
      _$wsServerMessageEventTypeEnum_actionRequired;
  @BuiltValueEnumConst(wireName: r'action_resolved')
  static const WsServerMessageEventTypeEnum actionResolved =
      _$wsServerMessageEventTypeEnum_actionResolved;
  @BuiltValueEnumConst(wireName: r'terminal')
  static const WsServerMessageEventTypeEnum terminal =
      _$wsServerMessageEventTypeEnum_terminal;

  static Serializer<WsServerMessageEventTypeEnum> get serializer =>
      _$wsServerMessageEventTypeEnumSerializer;

  const WsServerMessageEventTypeEnum._(String name) : super(name);

  static BuiltSet<WsServerMessageEventTypeEnum> get values =>
      _$wsServerMessageEventTypeEnumValues;
  static WsServerMessageEventTypeEnum valueOf(String name) =>
      _$wsServerMessageEventTypeEnumValueOf(name);
}
