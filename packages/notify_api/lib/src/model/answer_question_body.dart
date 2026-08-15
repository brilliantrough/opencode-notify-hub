//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'answer_question_body.g.dart';

/// AnswerQuestionBody
///
/// Properties:
/// * [answers]
/// * [commandId]
@BuiltValue()
abstract class AnswerQuestionBody
    implements Built<AnswerQuestionBody, AnswerQuestionBodyBuilder> {
  @BuiltValueField(wireName: r'answers')
  BuiltList<BuiltList<String>> get answers;

  @BuiltValueField(wireName: r'commandId')
  String get commandId;

  AnswerQuestionBody._();

  factory AnswerQuestionBody([void updates(AnswerQuestionBodyBuilder b)]) =
      _$AnswerQuestionBody;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AnswerQuestionBodyBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AnswerQuestionBody> get serializer =>
      _$AnswerQuestionBodySerializer();
}

class _$AnswerQuestionBodySerializer
    implements PrimitiveSerializer<AnswerQuestionBody> {
  @override
  final Iterable<Type> types = const [AnswerQuestionBody, _$AnswerQuestionBody];

  @override
  final String wireName = r'AnswerQuestionBody';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AnswerQuestionBody object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'answers';
    yield serializers.serialize(
      object.answers,
      specifiedType: const FullType(BuiltList, [
        FullType(BuiltList, [FullType(String)]),
      ]),
    );
    yield r'commandId';
    yield serializers.serialize(
      object.commandId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    AnswerQuestionBody object, {
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
    required AnswerQuestionBodyBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'answers':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(BuiltList, [
                      FullType(BuiltList, [FullType(String)]),
                    ]),
                  )
                  as BuiltList<BuiltList<String>>;
          result.answers.replace(valueDes);
          break;
        case r'commandId':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.commandId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AnswerQuestionBody deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AnswerQuestionBodyBuilder();
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
