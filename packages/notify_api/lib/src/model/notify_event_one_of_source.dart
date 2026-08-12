//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'notify_event_one_of_source.g.dart';

/// NotifyEventOneOfSource
///
/// Properties:
/// * [directory]
/// * [machine]
/// * [project]
@BuiltValue()
abstract class NotifyEventOneOfSource
    implements Built<NotifyEventOneOfSource, NotifyEventOneOfSourceBuilder> {
  @BuiltValueField(wireName: r'directory')
  String get directory;

  @BuiltValueField(wireName: r'machine')
  String get machine;

  @BuiltValueField(wireName: r'project')
  String get project;

  NotifyEventOneOfSource._();

  factory NotifyEventOneOfSource([
    void updates(NotifyEventOneOfSourceBuilder b),
  ]) = _$NotifyEventOneOfSource;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(NotifyEventOneOfSourceBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<NotifyEventOneOfSource> get serializer =>
      _$NotifyEventOneOfSourceSerializer();
}

class _$NotifyEventOneOfSourceSerializer
    implements PrimitiveSerializer<NotifyEventOneOfSource> {
  @override
  final Iterable<Type> types = const [
    NotifyEventOneOfSource,
    _$NotifyEventOneOfSource,
  ];

  @override
  final String wireName = r'NotifyEventOneOfSource';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    NotifyEventOneOfSource object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'directory';
    yield serializers.serialize(
      object.directory,
      specifiedType: const FullType(String),
    );
    yield r'machine';
    yield serializers.serialize(
      object.machine,
      specifiedType: const FullType(String),
    );
    yield r'project';
    yield serializers.serialize(
      object.project,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    NotifyEventOneOfSource object, {
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
    required NotifyEventOneOfSourceBuilder result,
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
        case r'machine':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.machine = valueDes;
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  NotifyEventOneOfSource deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = NotifyEventOneOfSourceBuilder();
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
