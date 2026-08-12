//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:notify_api/src/model/notify_event_one_of_source.dart';
import 'package:notify_api/src/model/notify_event_one_of1_payload.dart';
import 'package:notify_api/src/model/notify_event_one_of_session.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'notify_event_one_of1.g.dart';

/// NotifyEventOneOf1
///
/// Properties:
/// * [eventId]
/// * [occurredAt]
/// * [payload]
/// * [session]
/// * [source_]
/// * [type]
@BuiltValue()
abstract class NotifyEventOneOf1
    implements Built<NotifyEventOneOf1, NotifyEventOneOf1Builder> {
  @BuiltValueField(wireName: r'eventId')
  String get eventId;

  @BuiltValueField(wireName: r'occurredAt')
  DateTime get occurredAt;

  @BuiltValueField(wireName: r'payload')
  NotifyEventOneOf1Payload get payload;

  @BuiltValueField(wireName: r'session')
  NotifyEventOneOfSession get session;

  @BuiltValueField(wireName: r'source')
  NotifyEventOneOfSource get source_;

  @BuiltValueField(wireName: r'type')
  NotifyEventOneOf1TypeEnum get type;
  // enum typeEnum {  action_required,  };

  NotifyEventOneOf1._();

  factory NotifyEventOneOf1([void updates(NotifyEventOneOf1Builder b)]) =
      _$NotifyEventOneOf1;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(NotifyEventOneOf1Builder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<NotifyEventOneOf1> get serializer =>
      _$NotifyEventOneOf1Serializer();
}

class _$NotifyEventOneOf1Serializer
    implements PrimitiveSerializer<NotifyEventOneOf1> {
  @override
  final Iterable<Type> types = const [NotifyEventOneOf1, _$NotifyEventOneOf1];

  @override
  final String wireName = r'NotifyEventOneOf1';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    NotifyEventOneOf1 object, {
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
      specifiedType: const FullType(NotifyEventOneOf1Payload),
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
      specifiedType: const FullType(NotifyEventOneOf1TypeEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    NotifyEventOneOf1 object, {
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
    required NotifyEventOneOf1Builder result,
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
                    specifiedType: const FullType(NotifyEventOneOf1Payload),
                  )
                  as NotifyEventOneOf1Payload;
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
                    specifiedType: const FullType(NotifyEventOneOf1TypeEnum),
                  )
                  as NotifyEventOneOf1TypeEnum;
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
  NotifyEventOneOf1 deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = NotifyEventOneOf1Builder();
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

class NotifyEventOneOf1TypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'action_required')
  static const NotifyEventOneOf1TypeEnum actionRequired =
      _$notifyEventOneOf1TypeEnum_actionRequired;

  static Serializer<NotifyEventOneOf1TypeEnum> get serializer =>
      _$notifyEventOneOf1TypeEnumSerializer;

  const NotifyEventOneOf1TypeEnum._(String name) : super(name);

  static BuiltSet<NotifyEventOneOf1TypeEnum> get values =>
      _$notifyEventOneOf1TypeEnumValues;
  static NotifyEventOneOf1TypeEnum valueOf(String name) =>
      _$notifyEventOneOf1TypeEnumValueOf(name);
}
