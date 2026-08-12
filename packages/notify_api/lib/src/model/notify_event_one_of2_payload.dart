//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'notify_event_one_of2_payload.g.dart';

/// NotifyEventOneOf2Payload
///
/// Properties:
/// * [kind]
/// * [requestId]
@BuiltValue()
abstract class NotifyEventOneOf2Payload
    implements
        Built<NotifyEventOneOf2Payload, NotifyEventOneOf2PayloadBuilder> {
  @BuiltValueField(wireName: r'kind')
  NotifyEventOneOf2PayloadKindEnum get kind;
  // enum kindEnum {  question,  permission,  };

  @BuiltValueField(wireName: r'requestId')
  String get requestId;

  NotifyEventOneOf2Payload._();

  factory NotifyEventOneOf2Payload([
    void updates(NotifyEventOneOf2PayloadBuilder b),
  ]) = _$NotifyEventOneOf2Payload;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(NotifyEventOneOf2PayloadBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<NotifyEventOneOf2Payload> get serializer =>
      _$NotifyEventOneOf2PayloadSerializer();
}

class _$NotifyEventOneOf2PayloadSerializer
    implements PrimitiveSerializer<NotifyEventOneOf2Payload> {
  @override
  final Iterable<Type> types = const [
    NotifyEventOneOf2Payload,
    _$NotifyEventOneOf2Payload,
  ];

  @override
  final String wireName = r'NotifyEventOneOf2Payload';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    NotifyEventOneOf2Payload object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'kind';
    yield serializers.serialize(
      object.kind,
      specifiedType: const FullType(NotifyEventOneOf2PayloadKindEnum),
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
    NotifyEventOneOf2Payload object, {
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
    required NotifyEventOneOf2PayloadBuilder result,
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
                      NotifyEventOneOf2PayloadKindEnum,
                    ),
                  )
                  as NotifyEventOneOf2PayloadKindEnum;
          result.kind = valueDes;
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
  NotifyEventOneOf2Payload deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = NotifyEventOneOf2PayloadBuilder();
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

class NotifyEventOneOf2PayloadKindEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'question')
  static const NotifyEventOneOf2PayloadKindEnum question =
      _$notifyEventOneOf2PayloadKindEnum_question;
  @BuiltValueEnumConst(wireName: r'permission')
  static const NotifyEventOneOf2PayloadKindEnum permission =
      _$notifyEventOneOf2PayloadKindEnum_permission;

  static Serializer<NotifyEventOneOf2PayloadKindEnum> get serializer =>
      _$notifyEventOneOf2PayloadKindEnumSerializer;

  const NotifyEventOneOf2PayloadKindEnum._(String name) : super(name);

  static BuiltSet<NotifyEventOneOf2PayloadKindEnum> get values =>
      _$notifyEventOneOf2PayloadKindEnumValues;
  static NotifyEventOneOf2PayloadKindEnum valueOf(String name) =>
      _$notifyEventOneOf2PayloadKindEnumValueOf(name);
}
