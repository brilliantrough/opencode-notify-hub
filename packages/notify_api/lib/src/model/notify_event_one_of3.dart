//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:notify_api/src/model/notify_event_one_of3_payload.dart';
import 'package:notify_api/src/model/notify_event_one_of_source.dart';
import 'package:notify_api/src/model/notify_event_one_of_session.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'notify_event_one_of3.g.dart';

/// NotifyEventOneOf3
///
/// Properties:
/// * [eventId]
/// * [occurredAt]
/// * [payload]
/// * [session]
/// * [source_]
/// * [type]
@BuiltValue()
abstract class NotifyEventOneOf3
    implements Built<NotifyEventOneOf3, NotifyEventOneOf3Builder> {
  @BuiltValueField(wireName: r'eventId')
  String get eventId;

  @BuiltValueField(wireName: r'occurredAt')
  DateTime get occurredAt;

  @BuiltValueField(wireName: r'payload')
  NotifyEventOneOf3Payload get payload;

  @BuiltValueField(wireName: r'session')
  NotifyEventOneOfSession get session;

  @BuiltValueField(wireName: r'source')
  NotifyEventOneOfSource get source_;

  @BuiltValueField(wireName: r'type')
  NotifyEventOneOf3TypeEnum get type;
  // enum typeEnum {  terminal,  };

  NotifyEventOneOf3._();

  factory NotifyEventOneOf3([void updates(NotifyEventOneOf3Builder b)]) =
      _$NotifyEventOneOf3;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(NotifyEventOneOf3Builder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<NotifyEventOneOf3> get serializer =>
      _$NotifyEventOneOf3Serializer();
}

class _$NotifyEventOneOf3Serializer
    implements PrimitiveSerializer<NotifyEventOneOf3> {
  @override
  final Iterable<Type> types = const [NotifyEventOneOf3, _$NotifyEventOneOf3];

  @override
  final String wireName = r'NotifyEventOneOf3';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    NotifyEventOneOf3 object, {
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
      specifiedType: const FullType(NotifyEventOneOf3Payload),
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
      specifiedType: const FullType(NotifyEventOneOf3TypeEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    NotifyEventOneOf3 object, {
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
    required NotifyEventOneOf3Builder result,
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
                    specifiedType: const FullType(NotifyEventOneOf3Payload),
                  )
                  as NotifyEventOneOf3Payload;
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
                    specifiedType: const FullType(NotifyEventOneOf3TypeEnum),
                  )
                  as NotifyEventOneOf3TypeEnum;
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
  NotifyEventOneOf3 deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = NotifyEventOneOf3Builder();
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

class NotifyEventOneOf3TypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'terminal')
  static const NotifyEventOneOf3TypeEnum terminal =
      _$notifyEventOneOf3TypeEnum_terminal;

  static Serializer<NotifyEventOneOf3TypeEnum> get serializer =>
      _$notifyEventOneOf3TypeEnumSerializer;

  const NotifyEventOneOf3TypeEnum._(String name) : super(name);

  static BuiltSet<NotifyEventOneOf3TypeEnum> get values =>
      _$notifyEventOneOf3TypeEnumValues;
  static NotifyEventOneOf3TypeEnum valueOf(String name) =>
      _$notifyEventOneOf3TypeEnumValueOf(name);
}
