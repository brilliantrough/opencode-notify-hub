//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:notify_api/src/model/notify_event_one_of1_payload_one_of_questions_inner_options_inner.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'notify_event_one_of1_payload_one_of_questions_inner.g.dart';

/// NotifyEventOneOf1PayloadOneOfQuestionsInner
///
/// Properties:
/// * [multiple]
/// * [options]
/// * [question]
@BuiltValue()
abstract class NotifyEventOneOf1PayloadOneOfQuestionsInner
    implements
        Built<
          NotifyEventOneOf1PayloadOneOfQuestionsInner,
          NotifyEventOneOf1PayloadOneOfQuestionsInnerBuilder
        > {
  @BuiltValueField(wireName: r'multiple')
  bool? get multiple;

  @BuiltValueField(wireName: r'options')
  BuiltList<NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInner>?
  get options;

  @BuiltValueField(wireName: r'question')
  String get question;

  NotifyEventOneOf1PayloadOneOfQuestionsInner._();

  factory NotifyEventOneOf1PayloadOneOfQuestionsInner([
    void updates(NotifyEventOneOf1PayloadOneOfQuestionsInnerBuilder b),
  ]) = _$NotifyEventOneOf1PayloadOneOfQuestionsInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(NotifyEventOneOf1PayloadOneOfQuestionsInnerBuilder b) =>
      b;

  @BuiltValueSerializer(custom: true)
  static Serializer<NotifyEventOneOf1PayloadOneOfQuestionsInner>
  get serializer => _$NotifyEventOneOf1PayloadOneOfQuestionsInnerSerializer();
}

class _$NotifyEventOneOf1PayloadOneOfQuestionsInnerSerializer
    implements
        PrimitiveSerializer<NotifyEventOneOf1PayloadOneOfQuestionsInner> {
  @override
  final Iterable<Type> types = const [
    NotifyEventOneOf1PayloadOneOfQuestionsInner,
    _$NotifyEventOneOf1PayloadOneOfQuestionsInner,
  ];

  @override
  final String wireName = r'NotifyEventOneOf1PayloadOneOfQuestionsInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    NotifyEventOneOf1PayloadOneOfQuestionsInner object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.multiple != null) {
      yield r'multiple';
      yield serializers.serialize(
        object.multiple,
        specifiedType: const FullType(bool),
      );
    }
    if (object.options != null) {
      yield r'options';
      yield serializers.serialize(
        object.options,
        specifiedType: const FullType(BuiltList, [
          FullType(NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInner),
        ]),
      );
    }
    yield r'question';
    yield serializers.serialize(
      object.question,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    NotifyEventOneOf1PayloadOneOfQuestionsInner object, {
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
    required NotifyEventOneOf1PayloadOneOfQuestionsInnerBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'multiple':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(bool),
                  )
                  as bool;
          result.multiple = valueDes;
          break;
        case r'options':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(BuiltList, [
                      FullType(
                        NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInner,
                      ),
                    ]),
                  )
                  as BuiltList<
                    NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInner
                  >;
          result.options.replace(valueDes);
          break;
        case r'question':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.question = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  NotifyEventOneOf1PayloadOneOfQuestionsInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = NotifyEventOneOf1PayloadOneOfQuestionsInnerBuilder();
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
