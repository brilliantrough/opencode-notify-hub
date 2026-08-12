//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:notify_api/src/model/notify_event_one_of_payload.dart';
import 'package:built_collection/built_collection.dart';
import 'package:notify_api/src/model/notify_event_one_of_source.dart';
import 'package:notify_api/src/model/notify_event_one_of_session.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'notify_event_one_of.g.dart';

/// NotifyEventOneOf
///
/// Properties:
/// * [eventId]
/// * [occurredAt]
/// * [payload]
/// * [session]
/// * [source_]
/// * [type]
@BuiltValue()
abstract class NotifyEventOneOf
    implements Built<NotifyEventOneOf, NotifyEventOneOfBuilder> {
  @BuiltValueField(wireName: r'eventId')
  String get eventId;

  @BuiltValueField(wireName: r'occurredAt')
  DateTime get occurredAt;

  @BuiltValueField(wireName: r'payload')
  NotifyEventOneOfPayload get payload;

  @BuiltValueField(wireName: r'session')
  NotifyEventOneOfSession get session;

  @BuiltValueField(wireName: r'source')
  NotifyEventOneOfSource get source_;

  @BuiltValueField(wireName: r'type')
  NotifyEventOneOfTypeEnum get type;
  // enum typeEnum {  heartbeat,  };

  NotifyEventOneOf._();

  factory NotifyEventOneOf([void updates(NotifyEventOneOfBuilder b)]) =
      _$NotifyEventOneOf;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(NotifyEventOneOfBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<NotifyEventOneOf> get serializer =>
      _$NotifyEventOneOfSerializer();
}

class _$NotifyEventOneOfSerializer
    implements PrimitiveSerializer<NotifyEventOneOf> {
  @override
  final Iterable<Type> types = const [NotifyEventOneOf, _$NotifyEventOneOf];

  @override
  final String wireName = r'NotifyEventOneOf';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    NotifyEventOneOf object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'eventId';
    yield serializers.serialize(
      object.eventId,
      specifiedType: const FullType(String),
    );
    yield r'occurredAt';
    yield serializers.serialize(
      object.occurredAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'payload';
    yield serializers.serialize(
      object.payload,
      specifiedType: const FullType(NotifyEventOneOfPayload),
    );
    yield r'session';
    yield serializers.serialize(
      object.session,
      specifiedType: const FullType(NotifyEventOneOfSession),
    );
    yield r'source';
    yield serializers.serialize(
      object.source_,
      specifiedType: const FullType(NotifyEventOneOfSource),
    );
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(NotifyEventOneOfTypeEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    NotifyEventOneOf object, {
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
    required NotifyEventOneOfBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'eventId':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.eventId = valueDes;
          break;
        case r'occurredAt':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(DateTime),
                  )
                  as DateTime;
          result.occurredAt = valueDes;
          break;
        case r'payload':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(NotifyEventOneOfPayload),
                  )
                  as NotifyEventOneOfPayload;
          result.payload.replace(valueDes);
          break;
        case r'session':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(NotifyEventOneOfSession),
                  )
                  as NotifyEventOneOfSession;
          result.session.replace(valueDes);
          break;
        case r'source':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(NotifyEventOneOfSource),
                  )
                  as NotifyEventOneOfSource;
          result.source_.replace(valueDes);
          break;
        case r'type':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(NotifyEventOneOfTypeEnum),
                  )
                  as NotifyEventOneOfTypeEnum;
          result.type = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  NotifyEventOneOf deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = NotifyEventOneOfBuilder();
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

class NotifyEventOneOfTypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'heartbeat')
  static const NotifyEventOneOfTypeEnum heartbeat =
      _$notifyEventOneOfTypeEnum_heartbeat;

  static Serializer<NotifyEventOneOfTypeEnum> get serializer =>
      _$notifyEventOneOfTypeEnumSerializer;

  const NotifyEventOneOfTypeEnum._(String name) : super(name);

  static BuiltSet<NotifyEventOneOfTypeEnum> get values =>
      _$notifyEventOneOfTypeEnumValues;
  static NotifyEventOneOfTypeEnum valueOf(String name) =>
      _$notifyEventOneOfTypeEnumValueOf(name);
}
