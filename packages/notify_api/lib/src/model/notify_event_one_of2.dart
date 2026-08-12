//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:notify_api/src/model/notify_event_one_of2_payload.dart';
import 'package:notify_api/src/model/notify_event_one_of_source.dart';
import 'package:notify_api/src/model/notify_event_one_of_session.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'notify_event_one_of2.g.dart';

/// NotifyEventOneOf2
///
/// Properties:
/// * [eventId]
/// * [occurredAt]
/// * [payload]
/// * [session]
/// * [source_]
/// * [type]
@BuiltValue()
abstract class NotifyEventOneOf2
    implements Built<NotifyEventOneOf2, NotifyEventOneOf2Builder> {
  @BuiltValueField(wireName: r'eventId')
  String get eventId;

  @BuiltValueField(wireName: r'occurredAt')
  DateTime get occurredAt;

  @BuiltValueField(wireName: r'payload')
  NotifyEventOneOf2Payload get payload;

  @BuiltValueField(wireName: r'session')
  NotifyEventOneOfSession get session;

  @BuiltValueField(wireName: r'source')
  NotifyEventOneOfSource get source_;

  @BuiltValueField(wireName: r'type')
  NotifyEventOneOf2TypeEnum get type;
  // enum typeEnum {  action_resolved,  };

  NotifyEventOneOf2._();

  factory NotifyEventOneOf2([void updates(NotifyEventOneOf2Builder b)]) =
      _$NotifyEventOneOf2;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(NotifyEventOneOf2Builder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<NotifyEventOneOf2> get serializer =>
      _$NotifyEventOneOf2Serializer();
}

class _$NotifyEventOneOf2Serializer
    implements PrimitiveSerializer<NotifyEventOneOf2> {
  @override
  final Iterable<Type> types = const [NotifyEventOneOf2, _$NotifyEventOneOf2];

  @override
  final String wireName = r'NotifyEventOneOf2';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    NotifyEventOneOf2 object, {
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
      specifiedType: const FullType(NotifyEventOneOf2Payload),
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
      specifiedType: const FullType(NotifyEventOneOf2TypeEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    NotifyEventOneOf2 object, {
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
    required NotifyEventOneOf2Builder result,
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
                    specifiedType: const FullType(NotifyEventOneOf2Payload),
                  )
                  as NotifyEventOneOf2Payload;
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
                    specifiedType: const FullType(NotifyEventOneOf2TypeEnum),
                  )
                  as NotifyEventOneOf2TypeEnum;
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
  NotifyEventOneOf2 deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = NotifyEventOneOf2Builder();
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

class NotifyEventOneOf2TypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'action_resolved')
  static const NotifyEventOneOf2TypeEnum actionResolved =
      _$notifyEventOneOf2TypeEnum_actionResolved;

  static Serializer<NotifyEventOneOf2TypeEnum> get serializer =>
      _$notifyEventOneOf2TypeEnumSerializer;

  const NotifyEventOneOf2TypeEnum._(String name) : super(name);

  static BuiltSet<NotifyEventOneOf2TypeEnum> get values =>
      _$notifyEventOneOf2TypeEnumValues;
  static NotifyEventOneOf2TypeEnum valueOf(String name) =>
      _$notifyEventOneOf2TypeEnumValueOf(name);
}
