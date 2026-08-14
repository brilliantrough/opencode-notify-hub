//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'plugin_control_server_message.g.dart';

/// PluginControlServerMessage
///
/// Properties:
/// * [instanceId]
/// * [state]
/// * [type]
@BuiltValue()
abstract class PluginControlServerMessage
    implements
        Built<PluginControlServerMessage, PluginControlServerMessageBuilder> {
  @BuiltValueField(wireName: r'instanceId')
  String get instanceId;

  @BuiltValueField(wireName: r'state')
  PluginControlServerMessageStateEnum get state;
  // enum stateEnum {  controllable,  conflicting,  incompatible,  };

  @BuiltValueField(wireName: r'type')
  PluginControlServerMessageTypeEnum get type;
  // enum typeEnum {  registration,  };

  PluginControlServerMessage._();

  factory PluginControlServerMessage([
    void updates(PluginControlServerMessageBuilder b),
  ]) = _$PluginControlServerMessage;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PluginControlServerMessageBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PluginControlServerMessage> get serializer =>
      _$PluginControlServerMessageSerializer();
}

class _$PluginControlServerMessageSerializer
    implements PrimitiveSerializer<PluginControlServerMessage> {
  @override
  final Iterable<Type> types = const [
    PluginControlServerMessage,
    _$PluginControlServerMessage,
  ];

  @override
  final String wireName = r'PluginControlServerMessage';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PluginControlServerMessage object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'instanceId';
    yield serializers.serialize(
      object.instanceId,
      specifiedType: const FullType(String),
    );
    yield r'state';
    yield serializers.serialize(
      object.state,
      specifiedType: const FullType(PluginControlServerMessageStateEnum),
    );
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(PluginControlServerMessageTypeEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PluginControlServerMessage object, {
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
    required PluginControlServerMessageBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'instanceId':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.instanceId = valueDes;
          break;
        case r'state':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      PluginControlServerMessageStateEnum,
                    ),
                  )
                  as PluginControlServerMessageStateEnum;
          result.state = valueDes;
          break;
        case r'type':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      PluginControlServerMessageTypeEnum,
                    ),
                  )
                  as PluginControlServerMessageTypeEnum;
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
  PluginControlServerMessage deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PluginControlServerMessageBuilder();
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

class PluginControlServerMessageStateEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'controllable')
  static const PluginControlServerMessageStateEnum controllable =
      _$pluginControlServerMessageStateEnum_controllable;
  @BuiltValueEnumConst(wireName: r'conflicting')
  static const PluginControlServerMessageStateEnum conflicting =
      _$pluginControlServerMessageStateEnum_conflicting;
  @BuiltValueEnumConst(wireName: r'incompatible')
  static const PluginControlServerMessageStateEnum incompatible =
      _$pluginControlServerMessageStateEnum_incompatible;

  static Serializer<PluginControlServerMessageStateEnum> get serializer =>
      _$pluginControlServerMessageStateEnumSerializer;

  const PluginControlServerMessageStateEnum._(String name) : super(name);

  static BuiltSet<PluginControlServerMessageStateEnum> get values =>
      _$pluginControlServerMessageStateEnumValues;
  static PluginControlServerMessageStateEnum valueOf(String name) =>
      _$pluginControlServerMessageStateEnumValueOf(name);
}

class PluginControlServerMessageTypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'registration')
  static const PluginControlServerMessageTypeEnum registration =
      _$pluginControlServerMessageTypeEnum_registration;

  static Serializer<PluginControlServerMessageTypeEnum> get serializer =>
      _$pluginControlServerMessageTypeEnumSerializer;

  const PluginControlServerMessageTypeEnum._(String name) : super(name);

  static BuiltSet<PluginControlServerMessageTypeEnum> get values =>
      _$pluginControlServerMessageTypeEnumValues;
  static PluginControlServerMessageTypeEnum valueOf(String name) =>
      _$pluginControlServerMessageTypeEnumValueOf(name);
}
