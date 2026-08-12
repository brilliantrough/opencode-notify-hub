//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'verify_email_body.g.dart';

/// VerifyEmailBody
///
/// Properties:
/// * [code] - Eight-character high-entropy alphanumeric code delivered over SMTP.
/// * [email]
@BuiltValue()
abstract class VerifyEmailBody
    implements Built<VerifyEmailBody, VerifyEmailBodyBuilder> {
  /// Eight-character high-entropy alphanumeric code delivered over SMTP.
  @BuiltValueField(wireName: r'code')
  String get code;

  @BuiltValueField(wireName: r'email')
  String get email;

  VerifyEmailBody._();

  factory VerifyEmailBody([void updates(VerifyEmailBodyBuilder b)]) =
      _$VerifyEmailBody;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(VerifyEmailBodyBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<VerifyEmailBody> get serializer =>
      _$VerifyEmailBodySerializer();
}

class _$VerifyEmailBodySerializer
    implements PrimitiveSerializer<VerifyEmailBody> {
  @override
  final Iterable<Type> types = const [VerifyEmailBody, _$VerifyEmailBody];

  @override
  final String wireName = r'VerifyEmailBody';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    VerifyEmailBody object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'code';
    yield serializers.serialize(
      object.code,
      specifiedType: const FullType(String),
    );
    yield r'email';
    yield serializers.serialize(
      object.email,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    VerifyEmailBody object, {
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
    required VerifyEmailBodyBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'code':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.code = valueDes;
          break;
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
  VerifyEmailBody deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = VerifyEmailBodyBuilder();
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
