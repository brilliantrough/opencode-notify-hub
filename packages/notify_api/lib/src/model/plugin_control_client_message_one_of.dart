//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'plugin_control_client_message_one_of.g.dart';

/// PluginControlClientMessageOneOf
///
/// Properties:
/// * [directory]
/// * [instanceId]
/// * [machine]
/// * [openCodeVersion]
/// * [project]
/// * [protocolVersion]
/// * [type]
@BuiltValue()
abstract class PluginControlClientMessageOneOf
    implements
        Built<
          PluginControlClientMessageOneOf,
          PluginControlClientMessageOneOfBuilder
        > {
  @BuiltValueField(wireName: r'directory')
  String get directory;

  @BuiltValueField(wireName: r'instanceId')
  String get instanceId;

  @BuiltValueField(wireName: r'machine')
  String get machine;

  @BuiltValueField(wireName: r'openCodeVersion')
  String get openCodeVersion;

  @BuiltValueField(wireName: r'project')
  String get project;

  @BuiltValueField(wireName: r'protocolVersion')
  int get protocolVersion;

  @BuiltValueField(wireName: r'type')
  PluginControlClientMessageOneOfTypeEnum get type;
  // enum typeEnum {  register,  };

  PluginControlClientMessageOneOf._();

  factory PluginControlClientMessageOneOf([
    void updates(PluginControlClientMessageOneOfBuilder b),
  ]) = _$PluginControlClientMessageOneOf;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PluginControlClientMessageOneOfBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PluginControlClientMessageOneOf> get serializer =>
      _$PluginControlClientMessageOneOfSerializer();
}

class _$PluginControlClientMessageOneOfSerializer
    implements PrimitiveSerializer<PluginControlClientMessageOneOf> {
  @override
  final Iterable<Type> types = const [
    PluginControlClientMessageOneOf,
    _$PluginControlClientMessageOneOf,
  ];

  @override
  final String wireName = r'PluginControlClientMessageOneOf';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PluginControlClientMessageOneOf object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'directory';
    yield serializers.serialize(
      object.directory,
      specifiedType: const FullType(String),
    );
    yield r'instanceId';
    yield serializers.serialize(
      object.instanceId,
      specifiedType: const FullType(String),
    );
    yield r'machine';
    yield serializers.serialize(
      object.machine,
      specifiedType: const FullType(String),
    );
    yield r'openCodeVersion';
    yield serializers.serialize(
      object.openCodeVersion,
      specifiedType: const FullType(String),
    );
    yield r'project';
    yield serializers.serialize(
      object.project,
      specifiedType: const FullType(String),
    );
    yield r'protocolVersion';
    yield serializers.serialize(
      object.protocolVersion,
      specifiedType: const FullType(int),
    );
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(PluginControlClientMessageOneOfTypeEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PluginControlClientMessageOneOf object, {
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
    required PluginControlClientMessageOneOfBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'directory':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.directory = valueDes;
          break;
        case r'instanceId':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.instanceId = valueDes;
          break;
        case r'machine':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.machine = valueDes;
          break;
        case r'openCodeVersion':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.openCodeVersion = valueDes;
          break;
        case r'project':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.project = valueDes;
          break;
        case r'protocolVersion':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(int))
                  as int;
          result.protocolVersion = valueDes;
          break;
        case r'type':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      PluginControlClientMessageOneOfTypeEnum,
                    ),
                  )
                  as PluginControlClientMessageOneOfTypeEnum;
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
  PluginControlClientMessageOneOf deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PluginControlClientMessageOneOfBuilder();
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

class PluginControlClientMessageOneOfTypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'register')
  static const PluginControlClientMessageOneOfTypeEnum register =
      _$pluginControlClientMessageOneOfTypeEnum_register;

  static Serializer<PluginControlClientMessageOneOfTypeEnum> get serializer =>
      _$pluginControlClientMessageOneOfTypeEnumSerializer;

  const PluginControlClientMessageOneOfTypeEnum._(String name) : super(name);

  static BuiltSet<PluginControlClientMessageOneOfTypeEnum> get values =>
      _$pluginControlClientMessageOneOfTypeEnumValues;
  static PluginControlClientMessageOneOfTypeEnum valueOf(String name) =>
      _$pluginControlClientMessageOneOfTypeEnumValueOf(name);
}
