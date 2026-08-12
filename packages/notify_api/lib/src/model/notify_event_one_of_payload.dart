//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'notify_event_one_of_payload.g.dart';

/// NotifyEventOneOfPayload
///
/// Properties:
/// * [elapsedSeconds]
/// * [status]
@BuiltValue()
abstract class NotifyEventOneOfPayload
    implements Built<NotifyEventOneOfPayload, NotifyEventOneOfPayloadBuilder> {
  @BuiltValueField(wireName: r'elapsedSeconds')
  int get elapsedSeconds;

  @BuiltValueField(wireName: r'status')
  NotifyEventOneOfPayloadStatusEnum get status;
  // enum statusEnum {  busy,  retry,  };

  NotifyEventOneOfPayload._();

  factory NotifyEventOneOfPayload([
    void updates(NotifyEventOneOfPayloadBuilder b),
  ]) = _$NotifyEventOneOfPayload;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(NotifyEventOneOfPayloadBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<NotifyEventOneOfPayload> get serializer =>
      _$NotifyEventOneOfPayloadSerializer();
}

class _$NotifyEventOneOfPayloadSerializer
    implements PrimitiveSerializer<NotifyEventOneOfPayload> {
  @override
  final Iterable<Type> types = const [
    NotifyEventOneOfPayload,
    _$NotifyEventOneOfPayload,
  ];

  @override
  final String wireName = r'NotifyEventOneOfPayload';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    NotifyEventOneOfPayload object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'elapsedSeconds';
    yield serializers.serialize(
      object.elapsedSeconds,
      specifiedType: const FullType(int),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(NotifyEventOneOfPayloadStatusEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    NotifyEventOneOfPayload object, {
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
    required NotifyEventOneOfPayloadBuilder result,
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
        case r'status':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      NotifyEventOneOfPayloadStatusEnum,
                    ),
                  )
                  as NotifyEventOneOfPayloadStatusEnum;
          result.status = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  NotifyEventOneOfPayload deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = NotifyEventOneOfPayloadBuilder();
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

class NotifyEventOneOfPayloadStatusEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'busy')
  static const NotifyEventOneOfPayloadStatusEnum busy =
      _$notifyEventOneOfPayloadStatusEnum_busy;
  @BuiltValueEnumConst(wireName: r'retry')
  static const NotifyEventOneOfPayloadStatusEnum retry =
      _$notifyEventOneOfPayloadStatusEnum_retry;

  static Serializer<NotifyEventOneOfPayloadStatusEnum> get serializer =>
      _$notifyEventOneOfPayloadStatusEnumSerializer;

  const NotifyEventOneOfPayloadStatusEnum._(String name) : super(name);

  static BuiltSet<NotifyEventOneOfPayloadStatusEnum> get values =>
      _$notifyEventOneOfPayloadStatusEnumValues;
  static NotifyEventOneOfPayloadStatusEnum valueOf(String name) =>
      _$notifyEventOneOfPayloadStatusEnumValueOf(name);
}
