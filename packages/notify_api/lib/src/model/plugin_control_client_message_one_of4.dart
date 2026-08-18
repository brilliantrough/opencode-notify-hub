//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'plugin_control_client_message_one_of4.g.dart';

/// PluginControlClientMessageOneOf4
///
/// Properties:
/// * [commandId]
/// * [instanceId]
/// * [status]
/// * [type]
@BuiltValue()
abstract class PluginControlClientMessageOneOf4
    implements
        Built<
          PluginControlClientMessageOneOf4,
          PluginControlClientMessageOneOf4Builder
        > {
  @BuiltValueField(wireName: r'commandId')
  String get commandId;

  @BuiltValueField(wireName: r'instanceId')
  String get instanceId;

  @BuiltValueField(wireName: r'status')
  PluginControlClientMessageOneOf4StatusEnum get status;
  // enum statusEnum {  confirmed,  upstream_error,  result_unknown,  };

  @BuiltValueField(wireName: r'type')
  PluginControlClientMessageOneOf4TypeEnum get type;
  // enum typeEnum {  session_prompt_result,  };

  PluginControlClientMessageOneOf4._();

  factory PluginControlClientMessageOneOf4([
    void updates(PluginControlClientMessageOneOf4Builder b),
  ]) = _$PluginControlClientMessageOneOf4;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PluginControlClientMessageOneOf4Builder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PluginControlClientMessageOneOf4> get serializer =>
      _$PluginControlClientMessageOneOf4Serializer();
}

class _$PluginControlClientMessageOneOf4Serializer
    implements PrimitiveSerializer<PluginControlClientMessageOneOf4> {
  @override
  final Iterable<Type> types = const [
    PluginControlClientMessageOneOf4,
    _$PluginControlClientMessageOneOf4,
  ];

  @override
  final String wireName = r'PluginControlClientMessageOneOf4';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PluginControlClientMessageOneOf4 object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'commandId';
    yield serializers.serialize(
      object.commandId,
      specifiedType: const FullType(String),
    );
    yield r'instanceId';
    yield serializers.serialize(
      object.instanceId,
      specifiedType: const FullType(String),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(PluginControlClientMessageOneOf4StatusEnum),
    );
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(PluginControlClientMessageOneOf4TypeEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PluginControlClientMessageOneOf4 object, {
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
    required PluginControlClientMessageOneOf4Builder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'commandId':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.commandId = valueDes;
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
        case r'status':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      PluginControlClientMessageOneOf4StatusEnum,
                    ),
                  )
                  as PluginControlClientMessageOneOf4StatusEnum;
          result.status = valueDes;
          break;
        case r'type':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      PluginControlClientMessageOneOf4TypeEnum,
                    ),
                  )
                  as PluginControlClientMessageOneOf4TypeEnum;
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
  PluginControlClientMessageOneOf4 deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PluginControlClientMessageOneOf4Builder();
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

class PluginControlClientMessageOneOf4StatusEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'confirmed')
  static const PluginControlClientMessageOneOf4StatusEnum confirmed =
      _$pluginControlClientMessageOneOf4StatusEnum_confirmed;
  @BuiltValueEnumConst(wireName: r'upstream_error')
  static const PluginControlClientMessageOneOf4StatusEnum upstreamError =
      _$pluginControlClientMessageOneOf4StatusEnum_upstreamError;
  @BuiltValueEnumConst(wireName: r'result_unknown')
  static const PluginControlClientMessageOneOf4StatusEnum resultUnknown =
      _$pluginControlClientMessageOneOf4StatusEnum_resultUnknown;

  static Serializer<PluginControlClientMessageOneOf4StatusEnum>
  get serializer => _$pluginControlClientMessageOneOf4StatusEnumSerializer;

  const PluginControlClientMessageOneOf4StatusEnum._(String name) : super(name);

  static BuiltSet<PluginControlClientMessageOneOf4StatusEnum> get values =>
      _$pluginControlClientMessageOneOf4StatusEnumValues;
  static PluginControlClientMessageOneOf4StatusEnum valueOf(String name) =>
      _$pluginControlClientMessageOneOf4StatusEnumValueOf(name);
}

class PluginControlClientMessageOneOf4TypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'session_prompt_result')
  static const PluginControlClientMessageOneOf4TypeEnum sessionPromptResult =
      _$pluginControlClientMessageOneOf4TypeEnum_sessionPromptResult;

  static Serializer<PluginControlClientMessageOneOf4TypeEnum> get serializer =>
      _$pluginControlClientMessageOneOf4TypeEnumSerializer;

  const PluginControlClientMessageOneOf4TypeEnum._(String name) : super(name);

  static BuiltSet<PluginControlClientMessageOneOf4TypeEnum> get values =>
      _$pluginControlClientMessageOneOf4TypeEnumValues;
  static PluginControlClientMessageOneOf4TypeEnum valueOf(String name) =>
      _$pluginControlClientMessageOneOf4TypeEnumValueOf(name);
}
