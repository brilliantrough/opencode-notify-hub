//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'email_body.g.dart';

/// EmailBody
///
/// Properties:
/// * [email]
@BuiltValue()
abstract class EmailBody implements Built<EmailBody, EmailBodyBuilder> {
  @BuiltValueField(wireName: r'email')
  String get email;

  EmailBody._();

  factory EmailBody([void updates(EmailBodyBuilder b)]) = _$EmailBody;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(EmailBodyBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<EmailBody> get serializer => _$EmailBodySerializer();
}

class _$EmailBodySerializer implements PrimitiveSerializer<EmailBody> {
  @override
  final Iterable<Type> types = const [EmailBody, _$EmailBody];

  @override
  final String wireName = r'EmailBody';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    EmailBody object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'email';
    yield serializers.serialize(
      object.email,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    EmailBody object, {
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
    required EmailBodyBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'email':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.email = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  EmailBody deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = EmailBodyBuilder();
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
