//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:notify_api/src/model/pending_interaction_one_of_questions_inner.dart';
import 'package:notify_api/src/model/pending_interaction_one_of_tool.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'pending_interaction_one_of.g.dart';

/// PendingInteractionOneOf
///
/// Properties:
/// * [directory]
/// * [instanceId]
/// * [kind]
/// * [machine]
/// * [occurredAt]
/// * [project]
/// * [questions]
/// * [requestId]
/// * [sessionId]
/// * [sessionTitle]
/// * [tool]
@BuiltValue()
abstract class PendingInteractionOneOf
    implements Built<PendingInteractionOneOf, PendingInteractionOneOfBuilder> {
  @BuiltValueField(wireName: r'directory')
  String get directory;

  @BuiltValueField(wireName: r'instanceId')
  String get instanceId;

  @BuiltValueField(wireName: r'kind')
  PendingInteractionOneOfKindEnum get kind;
  // enum kindEnum {  question,  };

  @BuiltValueField(wireName: r'machine')
  String get machine;

  @BuiltValueField(wireName: r'occurredAt')
  DateTime get occurredAt;

  @BuiltValueField(wireName: r'project')
  String get project;

  @BuiltValueField(wireName: r'questions')
  BuiltList<PendingInteractionOneOfQuestionsInner> get questions;

  @BuiltValueField(wireName: r'requestId')
  String get requestId;

  @BuiltValueField(wireName: r'sessionId')
  String get sessionId;

  @BuiltValueField(wireName: r'sessionTitle')
  String get sessionTitle;

  @BuiltValueField(wireName: r'tool')
  PendingInteractionOneOfTool? get tool;

  PendingInteractionOneOf._();

  factory PendingInteractionOneOf([
    void updates(PendingInteractionOneOfBuilder b),
  ]) = _$PendingInteractionOneOf;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PendingInteractionOneOfBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PendingInteractionOneOf> get serializer =>
      _$PendingInteractionOneOfSerializer();
}

class _$PendingInteractionOneOfSerializer
    implements PrimitiveSerializer<PendingInteractionOneOf> {
  @override
  final Iterable<Type> types = const [
    PendingInteractionOneOf,
    _$PendingInteractionOneOf,
  ];

  @override
  final String wireName = r'PendingInteractionOneOf';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PendingInteractionOneOf object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'directory';
    yield serializers.serialize(
      object.directory,
      specifiedType: const FullType(String),
    );
    yield r'instanceId';
    yield serializers.serialize(
      object.instanceId,
      specifiedType: const FullType(String),
    );
    yield r'kind';
    yield serializers.serialize(
      object.kind,
      specifiedType: const FullType(PendingInteractionOneOfKindEnum),
    );
    yield r'machine';
    yield serializers.serialize(
      object.machine,
      specifiedType: const FullType(String),
    );
    yield r'occurredAt';
    yield serializers.serialize(
      object.occurredAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'project';
    yield serializers.serialize(
      object.project,
      specifiedType: const FullType(String),
    );
    yield r'questions';
    yield serializers.serialize(
      object.questions,
      specifiedType: const FullType(BuiltList, [
        FullType(PendingInteractionOneOfQuestionsInner),
      ]),
    );
    yield r'requestId';
    yield serializers.serialize(
      object.requestId,
      specifiedType: const FullType(String),
    );
    yield r'sessionId';
    yield serializers.serialize(
      object.sessionId,
      specifiedType: const FullType(String),
    );
    yield r'sessionTitle';
    yield serializers.serialize(
      object.sessionTitle,
      specifiedType: const FullType(String),
    );
    if (object.tool != null) {
      yield r'tool';
      yield serializers.serialize(
        object.tool,
        specifiedType: const FullType(PendingInteractionOneOfTool),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    PendingInteractionOneOf object, {
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
    required PendingInteractionOneOfBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'directory':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.directory = valueDes;
          break;
        case r'instanceId':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.instanceId = valueDes;
          break;
        case r'kind':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      PendingInteractionOneOfKindEnum,
                    ),
                  )
                  as PendingInteractionOneOfKindEnum;
          result.kind = valueDes;
          break;
        case r'machine':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.machine = valueDes;
          break;
        case r'occurredAt':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(DateTime),
                  )
                  as DateTime;
          result.occurredAt = valueDes;
          break;
        case r'project':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.project = valueDes;
          break;
        case r'questions':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(BuiltList, [
                      FullType(PendingInteractionOneOfQuestionsInner),
                    ]),
                  )
                  as BuiltList<PendingInteractionOneOfQuestionsInner>;
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
        case r'sessionId':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.sessionId = valueDes;
          break;
        case r'sessionTitle':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.sessionTitle = valueDes;
          break;
        case r'tool':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(PendingInteractionOneOfTool),
                  )
                  as PendingInteractionOneOfTool;
          result.tool.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PendingInteractionOneOf deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PendingInteractionOneOfBuilder();
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

class PendingInteractionOneOfKindEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'question')
  static const PendingInteractionOneOfKindEnum question =
      _$pendingInteractionOneOfKindEnum_question;

  static Serializer<PendingInteractionOneOfKindEnum> get serializer =>
      _$pendingInteractionOneOfKindEnumSerializer;

  const PendingInteractionOneOfKindEnum._(String name) : super(name);

  static BuiltSet<PendingInteractionOneOfKindEnum> get values =>
      _$pendingInteractionOneOfKindEnumValues;
  static PendingInteractionOneOfKindEnum valueOf(String name) =>
      _$pendingInteractionOneOfKindEnumValueOf(name);
}
