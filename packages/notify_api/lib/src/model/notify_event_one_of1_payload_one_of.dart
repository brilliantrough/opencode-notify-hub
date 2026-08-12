//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:notify_api/src/model/notify_event_one_of1_payload_one_of_questions_inner.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'notify_event_one_of1_payload_one_of.g.dart';

/// NotifyEventOneOf1PayloadOneOf
///
/// Properties:
/// * [kind]
/// * [questions]
/// * [requestId]
@BuiltValue()
abstract class NotifyEventOneOf1PayloadOneOf
    implements
        Built<
          NotifyEventOneOf1PayloadOneOf,
          NotifyEventOneOf1PayloadOneOfBuilder
        > {
  @BuiltValueField(wireName: r'kind')
  NotifyEventOneOf1PayloadOneOfKindEnum get kind;
  // enum kindEnum {  question,  };

  @BuiltValueField(wireName: r'questions')
  BuiltList<NotifyEventOneOf1PayloadOneOfQuestionsInner> get questions;

  @BuiltValueField(wireName: r'requestId')
  String get requestId;

  NotifyEventOneOf1PayloadOneOf._();

  factory NotifyEventOneOf1PayloadOneOf([
    void updates(NotifyEventOneOf1PayloadOneOfBuilder b),
  ]) = _$NotifyEventOneOf1PayloadOneOf;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(NotifyEventOneOf1PayloadOneOfBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<NotifyEventOneOf1PayloadOneOf> get serializer =>
      _$NotifyEventOneOf1PayloadOneOfSerializer();
}

class _$NotifyEventOneOf1PayloadOneOfSerializer
    implements PrimitiveSerializer<NotifyEventOneOf1PayloadOneOf> {
  @override
  final Iterable<Type> types = const [
    NotifyEventOneOf1PayloadOneOf,
    _$NotifyEventOneOf1PayloadOneOf,
  ];

  @override
  final String wireName = r'NotifyEventOneOf1PayloadOneOf';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    NotifyEventOneOf1PayloadOneOf object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'kind';
    yield serializers.serialize(
      object.kind,
      specifiedType: const FullType(NotifyEventOneOf1PayloadOneOfKindEnum),
    );
    yield r'questions';
    yield serializers.serialize(
      object.questions,
      specifiedType: const FullType(BuiltList, [
        FullType(NotifyEventOneOf1PayloadOneOfQuestionsInner),
      ]),
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
    NotifyEventOneOf1PayloadOneOf object, {
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
    required NotifyEventOneOf1PayloadOneOfBuilder result,
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
                      NotifyEventOneOf1PayloadOneOfKindEnum,
                    ),
                  )
                  as NotifyEventOneOf1PayloadOneOfKindEnum;
          result.kind = valueDes;
          break;
        case r'questions':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(BuiltList, [
                      FullType(NotifyEventOneOf1PayloadOneOfQuestionsInner),
                    ]),
                  )
                  as BuiltList<NotifyEventOneOf1PayloadOneOfQuestionsInner>;
          result.questions.replace(valueDes);
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
  NotifyEventOneOf1PayloadOneOf deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = NotifyEventOneOf1PayloadOneOfBuilder();
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

class NotifyEventOneOf1PayloadOneOfKindEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'question')
  static const NotifyEventOneOf1PayloadOneOfKindEnum question =
      _$notifyEventOneOf1PayloadOneOfKindEnum_question;

  static Serializer<NotifyEventOneOf1PayloadOneOfKindEnum> get serializer =>
      _$notifyEventOneOf1PayloadOneOfKindEnumSerializer;

  const NotifyEventOneOf1PayloadOneOfKindEnum._(String name) : super(name);

  static BuiltSet<NotifyEventOneOf1PayloadOneOfKindEnum> get values =>
      _$notifyEventOneOf1PayloadOneOfKindEnumValues;
  static NotifyEventOneOf1PayloadOneOfKindEnum valueOf(String name) =>
      _$notifyEventOneOf1PayloadOneOfKindEnumValueOf(name);
}
