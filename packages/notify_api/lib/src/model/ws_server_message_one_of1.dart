//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:notify_api/src/model/ws_server_message_one_of1_instances_inner.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'ws_server_message_one_of1.g.dart';

/// WsServerMessageOneOf1
///
/// Properties:
/// * [instances]
/// * [type]
@BuiltValue()
abstract class WsServerMessageOneOf1
    implements Built<WsServerMessageOneOf1, WsServerMessageOneOf1Builder> {
  @BuiltValueField(wireName: r'instances')
  BuiltList<WsServerMessageOneOf1InstancesInner> get instances;

  @BuiltValueField(wireName: r'type')
  WsServerMessageOneOf1TypeEnum get type;
  // enum typeEnum {  instance_presence,  };

  WsServerMessageOneOf1._();

  factory WsServerMessageOneOf1([
    void updates(WsServerMessageOneOf1Builder b),
  ]) = _$WsServerMessageOneOf1;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(WsServerMessageOneOf1Builder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<WsServerMessageOneOf1> get serializer =>
      _$WsServerMessageOneOf1Serializer();
}

class _$WsServerMessageOneOf1Serializer
    implements PrimitiveSerializer<WsServerMessageOneOf1> {
  @override
  final Iterable<Type> types = const [
    WsServerMessageOneOf1,
    _$WsServerMessageOneOf1,
  ];

  @override
  final String wireName = r'WsServerMessageOneOf1';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    WsServerMessageOneOf1 object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'instances';
    yield serializers.serialize(
      object.instances,
      specifiedType: const FullType(BuiltList, [
        FullType(WsServerMessageOneOf1InstancesInner),
      ]),
    );
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(WsServerMessageOneOf1TypeEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    WsServerMessageOneOf1 object, {
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
    required WsServerMessageOneOf1Builder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'instances':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(BuiltList, [
                      FullType(WsServerMessageOneOf1InstancesInner),
                    ]),
                  )
                  as BuiltList<WsServerMessageOneOf1InstancesInner>;
          result.instances.replace(valueDes);
          break;
        case r'type':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      WsServerMessageOneOf1TypeEnum,
                    ),
                  )
                  as WsServerMessageOneOf1TypeEnum;
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
  WsServerMessageOneOf1 deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = WsServerMessageOneOf1Builder();
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

class WsServerMessageOneOf1TypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'instance_presence')
  static const WsServerMessageOneOf1TypeEnum instancePresence =
      _$wsServerMessageOneOf1TypeEnum_instancePresence;

  static Serializer<WsServerMessageOneOf1TypeEnum> get serializer =>
      _$wsServerMessageOneOf1TypeEnumSerializer;

  const WsServerMessageOneOf1TypeEnum._(String name) : super(name);

  static BuiltSet<WsServerMessageOneOf1TypeEnum> get values =>
      _$wsServerMessageOneOf1TypeEnumValues;
  static WsServerMessageOneOf1TypeEnum valueOf(String name) =>
      _$wsServerMessageOneOf1TypeEnumValueOf(name);
}
