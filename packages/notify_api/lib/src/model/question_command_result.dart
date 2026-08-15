//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'question_command_result.g.dart';

/// QuestionCommandResult
///
/// Properties:
/// * [commandId]
/// * [status]
@BuiltValue()
abstract class QuestionCommandResult
    implements Built<QuestionCommandResult, QuestionCommandResultBuilder> {
  @BuiltValueField(wireName: r'commandId')
  String get commandId;

  @BuiltValueField(wireName: r'status')
  QuestionCommandResultStatusEnum get status;
  // enum statusEnum {  confirmed,  stale,  upstream_error,  result_unknown,  };

  QuestionCommandResult._();

  factory QuestionCommandResult([
    void updates(QuestionCommandResultBuilder b),
  ]) = _$QuestionCommandResult;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(QuestionCommandResultBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<QuestionCommandResult> get serializer =>
      _$QuestionCommandResultSerializer();
}

class _$QuestionCommandResultSerializer
    implements PrimitiveSerializer<QuestionCommandResult> {
  @override
  final Iterable<Type> types = const [
    QuestionCommandResult,
    _$QuestionCommandResult,
  ];

  @override
  final String wireName = r'QuestionCommandResult';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    QuestionCommandResult object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'commandId';
    yield serializers.serialize(
      object.commandId,
      specifiedType: const FullType(String),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(QuestionCommandResultStatusEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    QuestionCommandResult object, {
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
    required QuestionCommandResultBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'commandId':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.commandId = valueDes;
          break;
        case r'status':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      QuestionCommandResultStatusEnum,
                    ),
                  )
                  as QuestionCommandResultStatusEnum;
          result.status = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  QuestionCommandResult deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = QuestionCommandResultBuilder();
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

class QuestionCommandResultStatusEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'confirmed')
  static const QuestionCommandResultStatusEnum confirmed =
      _$questionCommandResultStatusEnum_confirmed;
  @BuiltValueEnumConst(wireName: r'stale')
  static const QuestionCommandResultStatusEnum stale =
      _$questionCommandResultStatusEnum_stale;
  @BuiltValueEnumConst(wireName: r'upstream_error')
  static const QuestionCommandResultStatusEnum upstreamError =
      _$questionCommandResultStatusEnum_upstreamError;
  @BuiltValueEnumConst(wireName: r'result_unknown')
  static const QuestionCommandResultStatusEnum resultUnknown =
      _$questionCommandResultStatusEnum_resultUnknown;

  static Serializer<QuestionCommandResultStatusEnum> get serializer =>
      _$questionCommandResultStatusEnumSerializer;

  const QuestionCommandResultStatusEnum._(String name) : super(name);

  static BuiltSet<QuestionCommandResultStatusEnum> get values =>
      _$questionCommandResultStatusEnumValues;
  static QuestionCommandResultStatusEnum valueOf(String name) =>
      _$questionCommandResultStatusEnumValueOf(name);
}
