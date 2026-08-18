//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'send_prompt_body.g.dart';

/// SendPromptBody
///
/// Properties:
/// * [commandId]
/// * [text]
@BuiltValue()
abstract class SendPromptBody
    implements Built<SendPromptBody, SendPromptBodyBuilder> {
  @BuiltValueField(wireName: r'commandId')
  String get commandId;

  @BuiltValueField(wireName: r'text')
  String get text;

  SendPromptBody._();

  factory SendPromptBody([void updates(SendPromptBodyBuilder b)]) =
      _$SendPromptBody;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SendPromptBodyBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SendPromptBody> get serializer =>
      _$SendPromptBodySerializer();
}

class _$SendPromptBodySerializer
    implements PrimitiveSerializer<SendPromptBody> {
  @override
  final Iterable<Type> types = const [SendPromptBody, _$SendPromptBody];

  @override
  final String wireName = r'SendPromptBody';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SendPromptBody object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'commandId';
    yield serializers.serialize(
      object.commandId,
      specifiedType: const FullType(String),
    );
    yield r'text';
    yield serializers.serialize(
      object.text,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    SendPromptBody object, {
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
    required SendPromptBodyBuilder result,
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
        case r'text':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.text = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SendPromptBody deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SendPromptBodyBuilder();
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
