//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'plugin_control_client_message_one_of3.g.dart';

/// PluginControlClientMessageOneOf3
///
/// Properties:
/// * [commandId]
/// * [instanceId]
/// * [status]
/// * [type]
@BuiltValue()
abstract class PluginControlClientMessageOneOf3
    implements
        Built<
          PluginControlClientMessageOneOf3,
          PluginControlClientMessageOneOf3Builder
        > {
  @BuiltValueField(wireName: r'commandId')
  String get commandId;

  @BuiltValueField(wireName: r'instanceId')
  String get instanceId;

  @BuiltValueField(wireName: r'status')
  PluginControlClientMessageOneOf3StatusEnum get status;
  // enum statusEnum {  confirmed,  stale,  upstream_error,  result_unknown,  };

  @BuiltValueField(wireName: r'type')
  PluginControlClientMessageOneOf3TypeEnum get type;
  // enum typeEnum {  permission_decide_result,  };

  PluginControlClientMessageOneOf3._();

  factory PluginControlClientMessageOneOf3([
    void updates(PluginControlClientMessageOneOf3Builder b),
  ]) = _$PluginControlClientMessageOneOf3;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PluginControlClientMessageOneOf3Builder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PluginControlClientMessageOneOf3> get serializer =>
      _$PluginControlClientMessageOneOf3Serializer();
}

class _$PluginControlClientMessageOneOf3Serializer
    implements PrimitiveSerializer<PluginControlClientMessageOneOf3> {
  @override
  final Iterable<Type> types = const [
    PluginControlClientMessageOneOf3,
    _$PluginControlClientMessageOneOf3,
  ];

  @override
  final String wireName = r'PluginControlClientMessageOneOf3';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PluginControlClientMessageOneOf3 object, {
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
      specifiedType: const FullType(PluginControlClientMessageOneOf3StatusEnum),
    );
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(PluginControlClientMessageOneOf3TypeEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PluginControlClientMessageOneOf3 object, {
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
    required PluginControlClientMessageOneOf3Builder result,
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
                      PluginControlClientMessageOneOf3StatusEnum,
                    ),
                  )
                  as PluginControlClientMessageOneOf3StatusEnum;
          result.status = valueDes;
          break;
        case r'type':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      PluginControlClientMessageOneOf3TypeEnum,
                    ),
                  )
                  as PluginControlClientMessageOneOf3TypeEnum;
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
  PluginControlClientMessageOneOf3 deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PluginControlClientMessageOneOf3Builder();
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

class PluginControlClientMessageOneOf3StatusEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'confirmed')
  static const PluginControlClientMessageOneOf3StatusEnum confirmed =
      _$pluginControlClientMessageOneOf3StatusEnum_confirmed;
  @BuiltValueEnumConst(wireName: r'stale')
  static const PluginControlClientMessageOneOf3StatusEnum stale =
      _$pluginControlClientMessageOneOf3StatusEnum_stale;
  @BuiltValueEnumConst(wireName: r'upstream_error')
  static const PluginControlClientMessageOneOf3StatusEnum upstreamError =
      _$pluginControlClientMessageOneOf3StatusEnum_upstreamError;
  @BuiltValueEnumConst(wireName: r'result_unknown')
  static const PluginControlClientMessageOneOf3StatusEnum resultUnknown =
      _$pluginControlClientMessageOneOf3StatusEnum_resultUnknown;

  static Serializer<PluginControlClientMessageOneOf3StatusEnum>
  get serializer => _$pluginControlClientMessageOneOf3StatusEnumSerializer;

  const PluginControlClientMessageOneOf3StatusEnum._(String name) : super(name);

  static BuiltSet<PluginControlClientMessageOneOf3StatusEnum> get values =>
      _$pluginControlClientMessageOneOf3StatusEnumValues;
  static PluginControlClientMessageOneOf3StatusEnum valueOf(String name) =>
      _$pluginControlClientMessageOneOf3StatusEnumValueOf(name);
}

class PluginControlClientMessageOneOf3TypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'permission_decide_result')
  static const PluginControlClientMessageOneOf3TypeEnum permissionDecideResult =
      _$pluginControlClientMessageOneOf3TypeEnum_permissionDecideResult;

  static Serializer<PluginControlClientMessageOneOf3TypeEnum> get serializer =>
      _$pluginControlClientMessageOneOf3TypeEnumSerializer;

  const PluginControlClientMessageOneOf3TypeEnum._(String name) : super(name);

  static BuiltSet<PluginControlClientMessageOneOf3TypeEnum> get values =>
      _$pluginControlClientMessageOneOf3TypeEnumValues;
  static PluginControlClientMessageOneOf3TypeEnum valueOf(String name) =>
      _$pluginControlClientMessageOneOf3TypeEnumValueOf(name);
}
