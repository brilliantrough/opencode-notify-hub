//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:notify_api/src/model/notify_event_one_of1_payload_one_of2_provider_action.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'notify_event_one_of1_payload_one_of2.g.dart';

/// NotifyEventOneOf1PayloadOneOf2
///
/// Properties:
/// * [kind]
/// * [providerAction]
/// * [requestId]
@BuiltValue()
abstract class NotifyEventOneOf1PayloadOneOf2
    implements
        Built<
          NotifyEventOneOf1PayloadOneOf2,
          NotifyEventOneOf1PayloadOneOf2Builder
        > {
  @BuiltValueField(wireName: r'kind')
  NotifyEventOneOf1PayloadOneOf2KindEnum get kind;
  // enum kindEnum {  provider_action,  };

  @BuiltValueField(wireName: r'providerAction')
  NotifyEventOneOf1PayloadOneOf2ProviderAction get providerAction;

  @BuiltValueField(wireName: r'requestId')
  String get requestId;

  NotifyEventOneOf1PayloadOneOf2._();

  factory NotifyEventOneOf1PayloadOneOf2([
    void updates(NotifyEventOneOf1PayloadOneOf2Builder b),
  ]) = _$NotifyEventOneOf1PayloadOneOf2;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(NotifyEventOneOf1PayloadOneOf2Builder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<NotifyEventOneOf1PayloadOneOf2> get serializer =>
      _$NotifyEventOneOf1PayloadOneOf2Serializer();
}

class _$NotifyEventOneOf1PayloadOneOf2Serializer
    implements PrimitiveSerializer<NotifyEventOneOf1PayloadOneOf2> {
  @override
  final Iterable<Type> types = const [
    NotifyEventOneOf1PayloadOneOf2,
    _$NotifyEventOneOf1PayloadOneOf2,
  ];

  @override
  final String wireName = r'NotifyEventOneOf1PayloadOneOf2';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    NotifyEventOneOf1PayloadOneOf2 object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'kind';
    yield serializers.serialize(
      object.kind,
      specifiedType: const FullType(NotifyEventOneOf1PayloadOneOf2KindEnum),
    );
    yield r'providerAction';
    yield serializers.serialize(
      object.providerAction,
      specifiedType: const FullType(
        NotifyEventOneOf1PayloadOneOf2ProviderAction,
      ),
    );
    yield r'requestId';
    yield serializers.serialize(
      object.requestId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    NotifyEventOneOf1PayloadOneOf2 object, {
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
    required NotifyEventOneOf1PayloadOneOf2Builder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'kind':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      NotifyEventOneOf1PayloadOneOf2KindEnum,
                    ),
                  )
                  as NotifyEventOneOf1PayloadOneOf2KindEnum;
          result.kind = valueDes;
          break;
        case r'providerAction':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      NotifyEventOneOf1PayloadOneOf2ProviderAction,
                    ),
                  )
                  as NotifyEventOneOf1PayloadOneOf2ProviderAction;
          result.providerAction.replace(valueDes);
          break;
        case r'requestId':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.requestId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  NotifyEventOneOf1PayloadOneOf2 deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = NotifyEventOneOf1PayloadOneOf2Builder();
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

class NotifyEventOneOf1PayloadOneOf2KindEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'provider_action')
  static const NotifyEventOneOf1PayloadOneOf2KindEnum providerAction =
      _$notifyEventOneOf1PayloadOneOf2KindEnum_providerAction;

  static Serializer<NotifyEventOneOf1PayloadOneOf2KindEnum> get serializer =>
      _$notifyEventOneOf1PayloadOneOf2KindEnumSerializer;

  const NotifyEventOneOf1PayloadOneOf2KindEnum._(String name) : super(name);

  static BuiltSet<NotifyEventOneOf1PayloadOneOf2KindEnum> get values =>
      _$notifyEventOneOf1PayloadOneOf2KindEnumValues;
  static NotifyEventOneOf1PayloadOneOf2KindEnum valueOf(String name) =>
      _$notifyEventOneOf1PayloadOneOf2KindEnumValueOf(name);
}
