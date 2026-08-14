//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'pending_interaction_one_of_tool.g.dart';

/// PendingInteractionOneOfTool
///
/// Properties:
/// * [callId]
/// * [messageId]
@BuiltValue()
abstract class PendingInteractionOneOfTool
    implements
        Built<PendingInteractionOneOfTool, PendingInteractionOneOfToolBuilder> {
  @BuiltValueField(wireName: r'callId')
  String get callId;

  @BuiltValueField(wireName: r'messageId')
  String get messageId;

  PendingInteractionOneOfTool._();

  factory PendingInteractionOneOfTool([
    void updates(PendingInteractionOneOfToolBuilder b),
  ]) = _$PendingInteractionOneOfTool;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PendingInteractionOneOfToolBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PendingInteractionOneOfTool> get serializer =>
      _$PendingInteractionOneOfToolSerializer();
}

class _$PendingInteractionOneOfToolSerializer
    implements PrimitiveSerializer<PendingInteractionOneOfTool> {
  @override
  final Iterable<Type> types = const [
    PendingInteractionOneOfTool,
    _$PendingInteractionOneOfTool,
  ];

  @override
  final String wireName = r'PendingInteractionOneOfTool';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PendingInteractionOneOfTool object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'callId';
    yield serializers.serialize(
      object.callId,
      specifiedType: const FullType(String),
    );
    yield r'messageId';
    yield serializers.serialize(
      object.messageId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PendingInteractionOneOfTool object, {
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
    required PendingInteractionOneOfToolBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'callId':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.callId = valueDes;
          break;
        case r'messageId':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.messageId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PendingInteractionOneOfTool deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PendingInteractionOneOfToolBuilder();
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
