//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'notify_event_one_of3_payload.g.dart';

/// NotifyEventOneOf3Payload
///
/// Properties:
/// * [elapsedSeconds]
/// * [outcome]
/// * [summary]
@BuiltValue()
abstract class NotifyEventOneOf3Payload
    implements
        Built<NotifyEventOneOf3Payload, NotifyEventOneOf3PayloadBuilder> {
  @BuiltValueField(wireName: r'elapsedSeconds')
  int get elapsedSeconds;

  @BuiltValueField(wireName: r'outcome')
  NotifyEventOneOf3PayloadOutcomeEnum get outcome;
  // enum outcomeEnum {  completed,  failed,  stopped,  };

  @BuiltValueField(wireName: r'summary')
  String? get summary;

  NotifyEventOneOf3Payload._();

  factory NotifyEventOneOf3Payload([
    void updates(NotifyEventOneOf3PayloadBuilder b),
  ]) = _$NotifyEventOneOf3Payload;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(NotifyEventOneOf3PayloadBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<NotifyEventOneOf3Payload> get serializer =>
      _$NotifyEventOneOf3PayloadSerializer();
}

class _$NotifyEventOneOf3PayloadSerializer
    implements PrimitiveSerializer<NotifyEventOneOf3Payload> {
  @override
  final Iterable<Type> types = const [
    NotifyEventOneOf3Payload,
    _$NotifyEventOneOf3Payload,
  ];

  @override
  final String wireName = r'NotifyEventOneOf3Payload';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    NotifyEventOneOf3Payload object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'elapsedSeconds';
    yield serializers.serialize(
      object.elapsedSeconds,
      specifiedType: const FullType(int),
    );
    yield r'outcome';
    yield serializers.serialize(
      object.outcome,
      specifiedType: const FullType(NotifyEventOneOf3PayloadOutcomeEnum),
    );
    if (object.summary != null) {
      yield r'summary';
      yield serializers.serialize(
        object.summary,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    NotifyEventOneOf3Payload object, {
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
    required NotifyEventOneOf3PayloadBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'elapsedSeconds':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(int))
                  as int;
          result.elapsedSeconds = valueDes;
          break;
        case r'outcome':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      NotifyEventOneOf3PayloadOutcomeEnum,
                    ),
                  )
                  as NotifyEventOneOf3PayloadOutcomeEnum;
          result.outcome = valueDes;
          break;
        case r'summary':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.summary = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  NotifyEventOneOf3Payload deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = NotifyEventOneOf3PayloadBuilder();
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

class NotifyEventOneOf3PayloadOutcomeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'completed')
  static const NotifyEventOneOf3PayloadOutcomeEnum completed =
      _$notifyEventOneOf3PayloadOutcomeEnum_completed;
  @BuiltValueEnumConst(wireName: r'failed')
  static const NotifyEventOneOf3PayloadOutcomeEnum failed =
      _$notifyEventOneOf3PayloadOutcomeEnum_failed;
  @BuiltValueEnumConst(wireName: r'stopped')
  static const NotifyEventOneOf3PayloadOutcomeEnum stopped =
      _$notifyEventOneOf3PayloadOutcomeEnum_stopped;

  static Serializer<NotifyEventOneOf3PayloadOutcomeEnum> get serializer =>
      _$notifyEventOneOf3PayloadOutcomeEnumSerializer;

  const NotifyEventOneOf3PayloadOutcomeEnum._(String name) : super(name);

  static BuiltSet<NotifyEventOneOf3PayloadOutcomeEnum> get values =>
      _$notifyEventOneOf3PayloadOutcomeEnumValues;
  static NotifyEventOneOf3PayloadOutcomeEnum valueOf(String name) =>
      _$notifyEventOneOf3PayloadOutcomeEnumValueOf(name);
}
