//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:notify_api/src/model/ws_server_message_one_of.dart';
import 'package:notify_api/src/model/ws_server_message_one_of1_instances_inner.dart';
import 'package:built_collection/built_collection.dart';
import 'package:notify_api/src/model/ws_server_message_one_of_event.dart';
import 'package:notify_api/src/model/ws_server_message_one_of1.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:one_of/one_of.dart';

part 'ws_server_message.g.dart';

/// WsServerMessage
///
/// Properties:
/// * [event]
/// * [type]
/// * [instances]
@BuiltValue()
abstract class WsServerMessage
    implements Built<WsServerMessage, WsServerMessageBuilder> {
  /// One Of [WsServerMessageOneOf], [WsServerMessageOneOf1]
  OneOf get oneOf;

  WsServerMessage._();

  factory WsServerMessage([void updates(WsServerMessageBuilder b)]) =
      _$WsServerMessage;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(WsServerMessageBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<WsServerMessage> get serializer =>
      _$WsServerMessageSerializer();
}

class _$WsServerMessageSerializer
    implements PrimitiveSerializer<WsServerMessage> {
  @override
  final Iterable<Type> types = const [WsServerMessage, _$WsServerMessage];

  @override
  final String wireName = r'WsServerMessage';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    WsServerMessage object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {}

  @override
  Object serialize(
    Serializers serializers,
    WsServerMessage object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final oneOf = object.oneOf;
    return serializers.serialize(
      oneOf.value,
      specifiedType: FullType(oneOf.valueType),
    )!;
  }

  @override
  WsServerMessage deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = WsServerMessageBuilder();
    Object? oneOfDataSrc;
    final targetType = const FullType(OneOf, [
      FullType(WsServerMessageOneOf),
      FullType(WsServerMessageOneOf1),
    ]);
    oneOfDataSrc = serialized;
    result.oneOf =
        serializers.deserialize(oneOfDataSrc, specifiedType: targetType)
            as OneOf;
    return result.build();
  }
}

class WsServerMessageTypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'event')
  static const WsServerMessageTypeEnum event = _$wsServerMessageTypeEnum_event;
  @BuiltValueEnumConst(wireName: r'instance_presence')
  static const WsServerMessageTypeEnum instancePresence =
      _$wsServerMessageTypeEnum_instancePresence;

  static Serializer<WsServerMessageTypeEnum> get serializer =>
      _$wsServerMessageTypeEnumSerializer;

  const WsServerMessageTypeEnum._(String name) : super(name);

  static BuiltSet<WsServerMessageTypeEnum> get values =>
      _$wsServerMessageTypeEnumValues;
  static WsServerMessageTypeEnum valueOf(String name) =>
      _$wsServerMessageTypeEnumValueOf(name);
}
