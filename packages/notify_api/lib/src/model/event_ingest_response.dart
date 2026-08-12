//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'event_ingest_response.g.dart';

/// EventIngestResponse
///
/// Properties:
/// * [deduplicated] - True when this eventId was already ingested for this user.
/// * [eventId]
@BuiltValue()
abstract class EventIngestResponse
    implements Built<EventIngestResponse, EventIngestResponseBuilder> {
  /// True when this eventId was already ingested for this user.
  @BuiltValueField(wireName: r'deduplicated')
  bool get deduplicated;

  @BuiltValueField(wireName: r'eventId')
  String get eventId;

  EventIngestResponse._();

  factory EventIngestResponse([void updates(EventIngestResponseBuilder b)]) =
      _$EventIngestResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(EventIngestResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<EventIngestResponse> get serializer =>
      _$EventIngestResponseSerializer();
}

class _$EventIngestResponseSerializer
    implements PrimitiveSerializer<EventIngestResponse> {
  @override
  final Iterable<Type> types = const [
    EventIngestResponse,
    _$EventIngestResponse,
  ];

  @override
  final String wireName = r'EventIngestResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    EventIngestResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'deduplicated';
    yield serializers.serialize(
      object.deduplicated,
      specifiedType: const FullType(bool),
    );
    yield r'eventId';
    yield serializers.serialize(
      object.eventId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    EventIngestResponse object, {
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
    required EventIngestResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'deduplicated':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(bool),
                  )
                  as bool;
          result.deduplicated = valueDes;
          break;
        case r'eventId':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.eventId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  EventIngestResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = EventIngestResponseBuilder();
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
