//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:notify_api/src/model/ws_server_message_event.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'ws_server_message.g.dart';

/// WsServerMessage
///
/// Properties:
/// * [event]
/// * [type]
@BuiltValue()
abstract class WsServerMessage
    implements Built<WsServerMessage, WsServerMessageBuilder> {
  @BuiltValueField(wireName: r'event')
  WsServerMessageEvent get event;

  @BuiltValueField(wireName: r'type')
  WsServerMessageTypeEnum get type;
  // enum typeEnum {  event,  };

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
  }) sync* {
    yield r'event';
    yield serializers.serialize(
      object.event,
      specifiedType: const FullType(WsServerMessageEvent),
    );
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(WsServerMessageTypeEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    WsServerMessage object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(
      serializers,
      object,
      specifiedType: specifiedType,
    ).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required WsServerMessageBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'event':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(WsServerMessageEvent),
                  )
                  as WsServerMessageEvent;
          result.event.replace(valueDes);
          break;
        case r'type':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(WsServerMessageTypeEnum),
                  )
                  as WsServerMessageTypeEnum;
          result.type = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  WsServerMessage deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = WsServerMessageBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}

class WsServerMessageTypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'event')
  static const WsServerMessageTypeEnum event = _$wsServerMessageTypeEnum_event;

  static Serializer<WsServerMessageTypeEnum> get serializer =>
      _$wsServerMessageTypeEnumSerializer;

  const WsServerMessageTypeEnum._(String name) : super(name);

  static BuiltSet<WsServerMessageTypeEnum> get values =>
      _$wsServerMessageTypeEnumValues;
  static WsServerMessageTypeEnum valueOf(String name) =>
      _$wsServerMessageTypeEnumValueOf(name);
}
