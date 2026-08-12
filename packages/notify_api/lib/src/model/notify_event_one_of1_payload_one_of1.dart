//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:notify_api/src/model/notify_event_one_of1_payload_one_of1_permission.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'notify_event_one_of1_payload_one_of1.g.dart';

/// NotifyEventOneOf1PayloadOneOf1
///
/// Properties:
/// * [kind]
/// * [permission]
/// * [requestId]
@BuiltValue()
abstract class NotifyEventOneOf1PayloadOneOf1
    implements
        Built<
          NotifyEventOneOf1PayloadOneOf1,
          NotifyEventOneOf1PayloadOneOf1Builder
        > {
  @BuiltValueField(wireName: r'kind')
  NotifyEventOneOf1PayloadOneOf1KindEnum get kind;
  // enum kindEnum {  permission,  };

  @BuiltValueField(wireName: r'permission')
  NotifyEventOneOf1PayloadOneOf1Permission get permission;

  @BuiltValueField(wireName: r'requestId')
  String get requestId;

  NotifyEventOneOf1PayloadOneOf1._();

  factory NotifyEventOneOf1PayloadOneOf1([
    void updates(NotifyEventOneOf1PayloadOneOf1Builder b),
  ]) = _$NotifyEventOneOf1PayloadOneOf1;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(NotifyEventOneOf1PayloadOneOf1Builder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<NotifyEventOneOf1PayloadOneOf1> get serializer =>
      _$NotifyEventOneOf1PayloadOneOf1Serializer();
}

class _$NotifyEventOneOf1PayloadOneOf1Serializer
    implements PrimitiveSerializer<NotifyEventOneOf1PayloadOneOf1> {
  @override
  final Iterable<Type> types = const [
    NotifyEventOneOf1PayloadOneOf1,
    _$NotifyEventOneOf1PayloadOneOf1,
  ];

  @override
  final String wireName = r'NotifyEventOneOf1PayloadOneOf1';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    NotifyEventOneOf1PayloadOneOf1 object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'kind';
    yield serializers.serialize(
      object.kind,
      specifiedType: const FullType(NotifyEventOneOf1PayloadOneOf1KindEnum),
    );
    yield r'permission';
    yield serializers.serialize(
      object.permission,
      specifiedType: const FullType(NotifyEventOneOf1PayloadOneOf1Permission),
    );
    yield r'requestId';
    yield serializers.serialize(
      object.requestId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    NotifyEventOneOf1PayloadOneOf1 object, {
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
    required NotifyEventOneOf1PayloadOneOf1Builder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'kind':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      NotifyEventOneOf1PayloadOneOf1KindEnum,
                    ),
                  )
                  as NotifyEventOneOf1PayloadOneOf1KindEnum;
          result.kind = valueDes;
          break;
        case r'permission':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      NotifyEventOneOf1PayloadOneOf1Permission,
                    ),
                  )
                  as NotifyEventOneOf1PayloadOneOf1Permission;
          result.permission.replace(valueDes);
          break;
        case r'requestId':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.requestId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  NotifyEventOneOf1PayloadOneOf1 deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = NotifyEventOneOf1PayloadOneOf1Builder();
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

class NotifyEventOneOf1PayloadOneOf1KindEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'permission')
  static const NotifyEventOneOf1PayloadOneOf1KindEnum permission =
      _$notifyEventOneOf1PayloadOneOf1KindEnum_permission;

  static Serializer<NotifyEventOneOf1PayloadOneOf1KindEnum> get serializer =>
      _$notifyEventOneOf1PayloadOneOf1KindEnumSerializer;

  const NotifyEventOneOf1PayloadOneOf1KindEnum._(String name) : super(name);

  static BuiltSet<NotifyEventOneOf1PayloadOneOf1KindEnum> get values =>
      _$notifyEventOneOf1PayloadOneOf1KindEnumValues;
  static NotifyEventOneOf1PayloadOneOf1KindEnum valueOf(String name) =>
      _$notifyEventOneOf1PayloadOneOf1KindEnumValueOf(name);
}
