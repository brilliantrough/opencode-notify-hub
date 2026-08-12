//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_ingest_key_body.g.dart';

/// CreateIngestKeyBody
///
/// Properties:
/// * [name]
@BuiltValue()
abstract class CreateIngestKeyBody
    implements Built<CreateIngestKeyBody, CreateIngestKeyBodyBuilder> {
  @BuiltValueField(wireName: r'name')
  String get name;

  CreateIngestKeyBody._();

  factory CreateIngestKeyBody([void updates(CreateIngestKeyBodyBuilder b)]) =
      _$CreateIngestKeyBody;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateIngestKeyBodyBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateIngestKeyBody> get serializer =>
      _$CreateIngestKeyBodySerializer();
}

class _$CreateIngestKeyBodySerializer
    implements PrimitiveSerializer<CreateIngestKeyBody> {
  @override
  final Iterable<Type> types = const [
    CreateIngestKeyBody,
    _$CreateIngestKeyBody,
  ];

  @override
  final String wireName = r'CreateIngestKeyBody';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateIngestKeyBody object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateIngestKeyBody object, {
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
    required CreateIngestKeyBodyBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'name':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.name = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CreateIngestKeyBody deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateIngestKeyBodyBuilder();
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
