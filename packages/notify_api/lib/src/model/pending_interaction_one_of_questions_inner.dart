//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:notify_api/src/model/pending_interaction_one_of_questions_inner_options_inner.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'pending_interaction_one_of_questions_inner.g.dart';

/// PendingInteractionOneOfQuestionsInner
///
/// Properties:
/// * [custom]
/// * [header]
/// * [multiple]
/// * [options]
/// * [question]
@BuiltValue()
abstract class PendingInteractionOneOfQuestionsInner
    implements
        Built<
          PendingInteractionOneOfQuestionsInner,
          PendingInteractionOneOfQuestionsInnerBuilder
        > {
  @BuiltValueField(wireName: r'custom')
  bool get custom;

  @BuiltValueField(wireName: r'header')
  String get header;

  @BuiltValueField(wireName: r'multiple')
  bool get multiple;

  @BuiltValueField(wireName: r'options')
  BuiltList<PendingInteractionOneOfQuestionsInnerOptionsInner> get options;

  @BuiltValueField(wireName: r'question')
  String get question;

  PendingInteractionOneOfQuestionsInner._();

  factory PendingInteractionOneOfQuestionsInner([
    void updates(PendingInteractionOneOfQuestionsInnerBuilder b),
  ]) = _$PendingInteractionOneOfQuestionsInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PendingInteractionOneOfQuestionsInnerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PendingInteractionOneOfQuestionsInner> get serializer =>
      _$PendingInteractionOneOfQuestionsInnerSerializer();
}

class _$PendingInteractionOneOfQuestionsInnerSerializer
    implements PrimitiveSerializer<PendingInteractionOneOfQuestionsInner> {
  @override
  final Iterable<Type> types = const [
    PendingInteractionOneOfQuestionsInner,
    _$PendingInteractionOneOfQuestionsInner,
  ];

  @override
  final String wireName = r'PendingInteractionOneOfQuestionsInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PendingInteractionOneOfQuestionsInner object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'custom';
    yield serializers.serialize(
      object.custom,
      specifiedType: const FullType(bool),
    );
    yield r'header';
    yield serializers.serialize(
      object.header,
      specifiedType: const FullType(String),
    );
    yield r'multiple';
    yield serializers.serialize(
      object.multiple,
      specifiedType: const FullType(bool),
    );
    yield r'options';
    yield serializers.serialize(
      object.options,
      specifiedType: const FullType(BuiltList, [
        FullType(PendingInteractionOneOfQuestionsInnerOptionsInner),
      ]),
    );
    yield r'question';
    yield serializers.serialize(
      object.question,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PendingInteractionOneOfQuestionsInner object, {
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
    required PendingInteractionOneOfQuestionsInnerBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'custom':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(bool),
                  )
                  as bool;
          result.custom = valueDes;
          break;
        case r'header':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.header = valueDes;
          break;
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
                        PendingInteractionOneOfQuestionsInnerOptionsInner,
                      ),
                    ]),
                  )
                  as BuiltList<
                    PendingInteractionOneOfQuestionsInnerOptionsInner
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
  PendingInteractionOneOfQuestionsInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PendingInteractionOneOfQuestionsInnerBuilder();
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
