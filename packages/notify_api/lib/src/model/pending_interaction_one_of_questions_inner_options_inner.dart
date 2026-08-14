//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'pending_interaction_one_of_questions_inner_options_inner.g.dart';

/// PendingInteractionOneOfQuestionsInnerOptionsInner
///
/// Properties:
/// * [description]
/// * [label]
@BuiltValue()
abstract class PendingInteractionOneOfQuestionsInnerOptionsInner
    implements
        Built<
          PendingInteractionOneOfQuestionsInnerOptionsInner,
          PendingInteractionOneOfQuestionsInnerOptionsInnerBuilder
        > {
  @BuiltValueField(wireName: r'description')
  String get description;

  @BuiltValueField(wireName: r'label')
  String get label;

  PendingInteractionOneOfQuestionsInnerOptionsInner._();

  factory PendingInteractionOneOfQuestionsInnerOptionsInner([
    void updates(PendingInteractionOneOfQuestionsInnerOptionsInnerBuilder b),
  ]) = _$PendingInteractionOneOfQuestionsInnerOptionsInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(
    PendingInteractionOneOfQuestionsInnerOptionsInnerBuilder b,
  ) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PendingInteractionOneOfQuestionsInnerOptionsInner>
  get serializer =>
      _$PendingInteractionOneOfQuestionsInnerOptionsInnerSerializer();
}

class _$PendingInteractionOneOfQuestionsInnerOptionsInnerSerializer
    implements
        PrimitiveSerializer<PendingInteractionOneOfQuestionsInnerOptionsInner> {
  @override
  final Iterable<Type> types = const [
    PendingInteractionOneOfQuestionsInnerOptionsInner,
    _$PendingInteractionOneOfQuestionsInnerOptionsInner,
  ];

  @override
  final String wireName = r'PendingInteractionOneOfQuestionsInnerOptionsInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PendingInteractionOneOfQuestionsInnerOptionsInner object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'description';
    yield serializers.serialize(
      object.description,
      specifiedType: const FullType(String),
    );
    yield r'label';
    yield serializers.serialize(
      object.label,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PendingInteractionOneOfQuestionsInnerOptionsInner object, {
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
    required PendingInteractionOneOfQuestionsInnerOptionsInnerBuilder result,
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
  PendingInteractionOneOfQuestionsInnerOptionsInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PendingInteractionOneOfQuestionsInnerOptionsInnerBuilder();
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
