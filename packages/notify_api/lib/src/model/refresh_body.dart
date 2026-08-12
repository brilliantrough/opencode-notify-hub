//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'refresh_body.g.dart';

/// RefreshBody
///
/// Properties:
/// * [refreshToken]
@BuiltValue()
abstract class RefreshBody implements Built<RefreshBody, RefreshBodyBuilder> {
  @BuiltValueField(wireName: r'refreshToken')
  String get refreshToken;

  RefreshBody._();

  factory RefreshBody([void updates(RefreshBodyBuilder b)]) = _$RefreshBody;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RefreshBodyBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RefreshBody> get serializer => _$RefreshBodySerializer();
}

class _$RefreshBodySerializer implements PrimitiveSerializer<RefreshBody> {
  @override
  final Iterable<Type> types = const [RefreshBody, _$RefreshBody];

  @override
  final String wireName = r'RefreshBody';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RefreshBody object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'refreshToken';
    yield serializers.serialize(
      object.refreshToken,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    RefreshBody object, {
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
    required RefreshBodyBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'refreshToken':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.refreshToken = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  RefreshBody deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RefreshBodyBuilder();
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
