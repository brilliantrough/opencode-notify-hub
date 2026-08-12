//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'notify_event_one_of_session.g.dart';

/// NotifyEventOneOfSession
///
/// Properties:
/// * [id]
/// * [title]
@BuiltValue()
abstract class NotifyEventOneOfSession
    implements Built<NotifyEventOneOfSession, NotifyEventOneOfSessionBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'title')
  String get title;

  NotifyEventOneOfSession._();

  factory NotifyEventOneOfSession([
    void updates(NotifyEventOneOfSessionBuilder b),
  ]) = _$NotifyEventOneOfSession;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(NotifyEventOneOfSessionBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<NotifyEventOneOfSession> get serializer =>
      _$NotifyEventOneOfSessionSerializer();
}

class _$NotifyEventOneOfSessionSerializer
    implements PrimitiveSerializer<NotifyEventOneOfSession> {
  @override
  final Iterable<Type> types = const [
    NotifyEventOneOfSession,
    _$NotifyEventOneOfSession,
  ];

  @override
  final String wireName = r'NotifyEventOneOfSession';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    NotifyEventOneOfSession object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'title';
    yield serializers.serialize(
      object.title,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    NotifyEventOneOfSession object, {
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
    required NotifyEventOneOfSessionBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'id':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.id = valueDes;
          break;
        case r'title':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.title = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  NotifyEventOneOfSession deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = NotifyEventOneOfSessionBuilder();
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
