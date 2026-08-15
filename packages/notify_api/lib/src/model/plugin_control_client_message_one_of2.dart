//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'plugin_control_client_message_one_of2.g.dart';

/// PluginControlClientMessageOneOf2
///
/// Properties:
/// * [commandId]
/// * [instanceId]
/// * [status]
/// * [type]
@BuiltValue()
abstract class PluginControlClientMessageOneOf2
    implements
        Built<
          PluginControlClientMessageOneOf2,
          PluginControlClientMessageOneOf2Builder
        > {
  @BuiltValueField(wireName: r'commandId')
  String get commandId;

  @BuiltValueField(wireName: r'instanceId')
  String get instanceId;

  @BuiltValueField(wireName: r'status')
  PluginControlClientMessageOneOf2StatusEnum get status;
  // enum statusEnum {  confirmed,  stale,  upstream_error,  result_unknown,  };

  @BuiltValueField(wireName: r'type')
  PluginControlClientMessageOneOf2TypeEnum get type;
  // enum typeEnum {  question_answer_result,  };

  PluginControlClientMessageOneOf2._();

  factory PluginControlClientMessageOneOf2([
    void updates(PluginControlClientMessageOneOf2Builder b),
  ]) = _$PluginControlClientMessageOneOf2;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PluginControlClientMessageOneOf2Builder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PluginControlClientMessageOneOf2> get serializer =>
      _$PluginControlClientMessageOneOf2Serializer();
}

class _$PluginControlClientMessageOneOf2Serializer
    implements PrimitiveSerializer<PluginControlClientMessageOneOf2> {
  @override
  final Iterable<Type> types = const [
    PluginControlClientMessageOneOf2,
    _$PluginControlClientMessageOneOf2,
  ];

  @override
  final String wireName = r'PluginControlClientMessageOneOf2';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PluginControlClientMessageOneOf2 object, {
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
      specifiedType: const FullType(PluginControlClientMessageOneOf2StatusEnum),
    );
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(PluginControlClientMessageOneOf2TypeEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PluginControlClientMessageOneOf2 object, {
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
    required PluginControlClientMessageOneOf2Builder result,
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
                      PluginControlClientMessageOneOf2StatusEnum,
                    ),
                  )
                  as PluginControlClientMessageOneOf2StatusEnum;
          result.status = valueDes;
          break;
        case r'type':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      PluginControlClientMessageOneOf2TypeEnum,
                    ),
                  )
                  as PluginControlClientMessageOneOf2TypeEnum;
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
  PluginControlClientMessageOneOf2 deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PluginControlClientMessageOneOf2Builder();
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

class PluginControlClientMessageOneOf2StatusEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'confirmed')
  static const PluginControlClientMessageOneOf2StatusEnum confirmed =
      _$pluginControlClientMessageOneOf2StatusEnum_confirmed;
  @BuiltValueEnumConst(wireName: r'stale')
  static const PluginControlClientMessageOneOf2StatusEnum stale =
      _$pluginControlClientMessageOneOf2StatusEnum_stale;
  @BuiltValueEnumConst(wireName: r'upstream_error')
  static const PluginControlClientMessageOneOf2StatusEnum upstreamError =
      _$pluginControlClientMessageOneOf2StatusEnum_upstreamError;
  @BuiltValueEnumConst(wireName: r'result_unknown')
  static const PluginControlClientMessageOneOf2StatusEnum resultUnknown =
      _$pluginControlClientMessageOneOf2StatusEnum_resultUnknown;

  static Serializer<PluginControlClientMessageOneOf2StatusEnum>
  get serializer => _$pluginControlClientMessageOneOf2StatusEnumSerializer;

  const PluginControlClientMessageOneOf2StatusEnum._(String name) : super(name);

  static BuiltSet<PluginControlClientMessageOneOf2StatusEnum> get values =>
      _$pluginControlClientMessageOneOf2StatusEnumValues;
  static PluginControlClientMessageOneOf2StatusEnum valueOf(String name) =>
      _$pluginControlClientMessageOneOf2StatusEnumValueOf(name);
}

class PluginControlClientMessageOneOf2TypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'question_answer_result')
  static const PluginControlClientMessageOneOf2TypeEnum questionAnswerResult =
      _$pluginControlClientMessageOneOf2TypeEnum_questionAnswerResult;

  static Serializer<PluginControlClientMessageOneOf2TypeEnum> get serializer =>
      _$pluginControlClientMessageOneOf2TypeEnumSerializer;

  const PluginControlClientMessageOneOf2TypeEnum._(String name) : super(name);

  static BuiltSet<PluginControlClientMessageOneOf2TypeEnum> get values =>
      _$pluginControlClientMessageOneOf2TypeEnumValues;
  static PluginControlClientMessageOneOf2TypeEnum valueOf(String name) =>
      _$pluginControlClientMessageOneOf2TypeEnumValueOf(name);
}
