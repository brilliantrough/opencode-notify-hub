//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'ingest_key_list_response_inner.g.dart';

/// IngestKeyListResponseInner
///
/// Properties:
/// * [createdAt]
/// * [id]
/// * [lastUsedAt]
/// * [name]
@BuiltValue()
abstract class IngestKeyListResponseInner
    implements
        Built<IngestKeyListResponseInner, IngestKeyListResponseInnerBuilder> {
  @BuiltValueField(wireName: r'createdAt')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'lastUsedAt')
  DateTime? get lastUsedAt;

  @BuiltValueField(wireName: r'name')
  String get name;

  IngestKeyListResponseInner._();

  factory IngestKeyListResponseInner([
    void updates(IngestKeyListResponseInnerBuilder b),
  ]) = _$IngestKeyListResponseInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(IngestKeyListResponseInnerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<IngestKeyListResponseInner> get serializer =>
      _$IngestKeyListResponseInnerSerializer();
}

class _$IngestKeyListResponseInnerSerializer
    implements PrimitiveSerializer<IngestKeyListResponseInner> {
  @override
  final Iterable<Type> types = const [
    IngestKeyListResponseInner,
    _$IngestKeyListResponseInner,
  ];

  @override
  final String wireName = r'IngestKeyListResponseInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    IngestKeyListResponseInner object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'createdAt';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    if (object.lastUsedAt != null) {
      yield r'lastUsedAt';
      yield serializers.serialize(
        object.lastUsedAt,
        specifiedType: const FullType(DateTime),
      );
    }
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    IngestKeyListResponseInner object, {
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
    required IngestKeyListResponseInnerBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'createdAt':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(DateTime),
                  )
                  as DateTime;
          result.createdAt = valueDes;
          break;
        case r'id':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.id = valueDes;
          break;
        case r'lastUsedAt':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(DateTime),
                  )
                  as DateTime;
          result.lastUsedAt = valueDes;
          break;
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
  IngestKeyListResponseInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = IngestKeyListResponseInnerBuilder();
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
