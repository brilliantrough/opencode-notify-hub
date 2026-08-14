//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:notify_api/src/model/ws_server_message_one_of_event.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'ws_server_message_one_of.g.dart';

/// WsServerMessageOneOf
///
/// Properties:
/// * [event]
/// * [type]
@BuiltValue()
abstract class WsServerMessageOneOf
    implements Built<WsServerMessageOneOf, WsServerMessageOneOfBuilder> {
  @BuiltValueField(wireName: r'event')
  WsServerMessageOneOfEvent get event;

  @BuiltValueField(wireName: r'type')
  WsServerMessageOneOfTypeEnum get type;
  // enum typeEnum {  event,  };

  WsServerMessageOneOf._();

  factory WsServerMessageOneOf([void updates(WsServerMessageOneOfBuilder b)]) =
      _$WsServerMessageOneOf;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(WsServerMessageOneOfBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<WsServerMessageOneOf> get serializer =>
      _$WsServerMessageOneOfSerializer();
}

class _$WsServerMessageOneOfSerializer
    implements PrimitiveSerializer<WsServerMessageOneOf> {
  @override
  final Iterable<Type> types = const [
    WsServerMessageOneOf,
    _$WsServerMessageOneOf,
  ];

  @override
  final String wireName = r'WsServerMessageOneOf';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    WsServerMessageOneOf object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'event';
    yield serializers.serialize(
      object.event,
      specifiedType: const FullType(WsServerMessageOneOfEvent),
    );
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(WsServerMessageOneOfTypeEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    WsServerMessageOneOf object, {
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
    required WsServerMessageOneOfBuilder result,
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
                    specifiedType: const FullType(WsServerMessageOneOfEvent),
                  )
                  as WsServerMessageOneOfEvent;
          result.event.replace(valueDes);
          break;
        case r'type':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(WsServerMessageOneOfTypeEnum),
                  )
                  as WsServerMessageOneOfTypeEnum;
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
  WsServerMessageOneOf deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = WsServerMessageOneOfBuilder();
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

class WsServerMessageOneOfTypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'event')
  static const WsServerMessageOneOfTypeEnum event =
      _$wsServerMessageOneOfTypeEnum_event;

  static Serializer<WsServerMessageOneOfTypeEnum> get serializer =>
      _$wsServerMessageOneOfTypeEnumSerializer;

  const WsServerMessageOneOfTypeEnum._(String name) : super(name);

  static BuiltSet<WsServerMessageOneOfTypeEnum> get values =>
      _$wsServerMessageOneOfTypeEnumValues;
  static WsServerMessageOneOfTypeEnum valueOf(String name) =>
      _$wsServerMessageOneOfTypeEnumValueOf(name);
}
