//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'plugin_control_server_message_one_of.g.dart';

/// PluginControlServerMessageOneOf
///
/// Properties:
/// * [instanceId]
/// * [state]
/// * [type]
@BuiltValue()
abstract class PluginControlServerMessageOneOf
    implements
        Built<
          PluginControlServerMessageOneOf,
          PluginControlServerMessageOneOfBuilder
        > {
  @BuiltValueField(wireName: r'instanceId')
  String get instanceId;

  @BuiltValueField(wireName: r'state')
  PluginControlServerMessageOneOfStateEnum get state;
  // enum stateEnum {  controllable,  conflicting,  incompatible,  };

  @BuiltValueField(wireName: r'type')
  PluginControlServerMessageOneOfTypeEnum get type;
  // enum typeEnum {  registration,  };

  PluginControlServerMessageOneOf._();

  factory PluginControlServerMessageOneOf([
    void updates(PluginControlServerMessageOneOfBuilder b),
  ]) = _$PluginControlServerMessageOneOf;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PluginControlServerMessageOneOfBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PluginControlServerMessageOneOf> get serializer =>
      _$PluginControlServerMessageOneOfSerializer();
}

class _$PluginControlServerMessageOneOfSerializer
    implements PrimitiveSerializer<PluginControlServerMessageOneOf> {
  @override
  final Iterable<Type> types = const [
    PluginControlServerMessageOneOf,
    _$PluginControlServerMessageOneOf,
  ];

  @override
  final String wireName = r'PluginControlServerMessageOneOf';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PluginControlServerMessageOneOf object, {
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
      specifiedType: const FullType(PluginControlServerMessageOneOfStateEnum),
    );
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(PluginControlServerMessageOneOfTypeEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PluginControlServerMessageOneOf object, {
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
    required PluginControlServerMessageOneOfBuilder result,
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
                      PluginControlServerMessageOneOfStateEnum,
                    ),
                  )
                  as PluginControlServerMessageOneOfStateEnum;
          result.state = valueDes;
          break;
        case r'type':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      PluginControlServerMessageOneOfTypeEnum,
                    ),
                  )
                  as PluginControlServerMessageOneOfTypeEnum;
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
  PluginControlServerMessageOneOf deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PluginControlServerMessageOneOfBuilder();
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

class PluginControlServerMessageOneOfStateEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'controllable')
  static const PluginControlServerMessageOneOfStateEnum controllable =
      _$pluginControlServerMessageOneOfStateEnum_controllable;
  @BuiltValueEnumConst(wireName: r'conflicting')
  static const PluginControlServerMessageOneOfStateEnum conflicting =
      _$pluginControlServerMessageOneOfStateEnum_conflicting;
  @BuiltValueEnumConst(wireName: r'incompatible')
  static const PluginControlServerMessageOneOfStateEnum incompatible =
      _$pluginControlServerMessageOneOfStateEnum_incompatible;

  static Serializer<PluginControlServerMessageOneOfStateEnum> get serializer =>
      _$pluginControlServerMessageOneOfStateEnumSerializer;

  const PluginControlServerMessageOneOfStateEnum._(String name) : super(name);

  static BuiltSet<PluginControlServerMessageOneOfStateEnum> get values =>
      _$pluginControlServerMessageOneOfStateEnumValues;
  static PluginControlServerMessageOneOfStateEnum valueOf(String name) =>
      _$pluginControlServerMessageOneOfStateEnumValueOf(name);
}

class PluginControlServerMessageOneOfTypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'registration')
  static const PluginControlServerMessageOneOfTypeEnum registration =
      _$pluginControlServerMessageOneOfTypeEnum_registration;

  static Serializer<PluginControlServerMessageOneOfTypeEnum> get serializer =>
      _$pluginControlServerMessageOneOfTypeEnumSerializer;

  const PluginControlServerMessageOneOfTypeEnum._(String name) : super(name);

  static BuiltSet<PluginControlServerMessageOneOfTypeEnum> get values =>
      _$pluginControlServerMessageOneOfTypeEnumValues;
  static PluginControlServerMessageOneOfTypeEnum valueOf(String name) =>
      _$pluginControlServerMessageOneOfTypeEnumValueOf(name);
}
