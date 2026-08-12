//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'notify_event_one_of1_payload_one_of_questions_inner_options_inner.g.dart';

/// NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInner
///
/// Properties:
/// * [description]
/// * [label]
@BuiltValue()
abstract class NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInner
    implements
        Built<
          NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInner,
          NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInnerBuilder
        > {
  @BuiltValueField(wireName: r'description')
  String? get description;

  @BuiltValueField(wireName: r'label')
  String get label;

  NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInner._();

  factory NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInner([
    void updates(
      NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInnerBuilder b,
    ),
  ]) = _$NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(
    NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInnerBuilder b,
  ) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInner>
  get serializer =>
      _$NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInnerSerializer();
}

class _$NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInnerSerializer
    implements
        PrimitiveSerializer<
          NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInner
        > {
  @override
  final Iterable<Type> types = const [
    NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInner,
    _$NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInner,
  ];

  @override
  final String wireName =
      r'NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInner object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.description != null) {
      yield r'description';
      yield serializers.serialize(
        object.description,
        specifiedType: const FullType(String),
      );
    }
    yield r'label';
    yield serializers.serialize(
      object.label,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInner object, {
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
    required NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInnerBuilder
    result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'description':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.description = valueDes;
          break;
        case r'label':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.label = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result =
        NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInnerBuilder();
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
