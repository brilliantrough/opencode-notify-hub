//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'plugin_control_server_message_one_of3.g.dart';

/// PluginControlServerMessageOneOf3
///
/// Properties:
/// * [commandId]
/// * [decision]
/// * [requestId]
/// * [sessionID]
/// * [type]
@BuiltValue()
abstract class PluginControlServerMessageOneOf3
    implements
        Built<
          PluginControlServerMessageOneOf3,
          PluginControlServerMessageOneOf3Builder
        > {
  @BuiltValueField(wireName: r'commandId')
  String get commandId;

  @BuiltValueField(wireName: r'decision')
  PluginControlServerMessageOneOf3DecisionEnum get decision;
  // enum decisionEnum {  once,  reject,  always,  };

  @BuiltValueField(wireName: r'requestId')
  String get requestId;

  @BuiltValueField(wireName: r'sessionID')
  String get sessionID;

  @BuiltValueField(wireName: r'type')
  PluginControlServerMessageOneOf3TypeEnum get type;
  // enum typeEnum {  permission_decide_command,  };

  PluginControlServerMessageOneOf3._();

  factory PluginControlServerMessageOneOf3([
    void updates(PluginControlServerMessageOneOf3Builder b),
  ]) = _$PluginControlServerMessageOneOf3;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PluginControlServerMessageOneOf3Builder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PluginControlServerMessageOneOf3> get serializer =>
      _$PluginControlServerMessageOneOf3Serializer();
}

class _$PluginControlServerMessageOneOf3Serializer
    implements PrimitiveSerializer<PluginControlServerMessageOneOf3> {
  @override
  final Iterable<Type> types = const [
    PluginControlServerMessageOneOf3,
    _$PluginControlServerMessageOneOf3,
  ];

  @override
  final String wireName = r'PluginControlServerMessageOneOf3';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PluginControlServerMessageOneOf3 object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'commandId';
    yield serializers.serialize(
      object.commandId,
      specifiedType: const FullType(String),
    );
    yield r'decision';
    yield serializers.serialize(
      object.decision,
      specifiedType: const FullType(
        PluginControlServerMessageOneOf3DecisionEnum,
      ),
    );
    yield r'requestId';
    yield serializers.serialize(
      object.requestId,
      specifiedType: const FullType(String),
    );
    yield r'sessionID';
    yield serializers.serialize(
      object.sessionID,
      specifiedType: const FullType(String),
    );
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(PluginControlServerMessageOneOf3TypeEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PluginControlServerMessageOneOf3 object, {
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
    required PluginControlServerMessageOneOf3Builder result,
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
        case r'decision':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      PluginControlServerMessageOneOf3DecisionEnum,
                    ),
                  )
                  as PluginControlServerMessageOneOf3DecisionEnum;
          result.decision = valueDes;
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
        case r'sessionID':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.sessionID = valueDes;
          break;
        case r'type':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      PluginControlServerMessageOneOf3TypeEnum,
                    ),
                  )
                  as PluginControlServerMessageOneOf3TypeEnum;
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
  PluginControlServerMessageOneOf3 deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PluginControlServerMessageOneOf3Builder();
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

class PluginControlServerMessageOneOf3DecisionEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'once')
  static const PluginControlServerMessageOneOf3DecisionEnum once =
      _$pluginControlServerMessageOneOf3DecisionEnum_once;
  @BuiltValueEnumConst(wireName: r'reject')
  static const PluginControlServerMessageOneOf3DecisionEnum reject =
      _$pluginControlServerMessageOneOf3DecisionEnum_reject;
  @BuiltValueEnumConst(wireName: r'always')
  static const PluginControlServerMessageOneOf3DecisionEnum always =
      _$pluginControlServerMessageOneOf3DecisionEnum_always;

  static Serializer<PluginControlServerMessageOneOf3DecisionEnum>
  get serializer => _$pluginControlServerMessageOneOf3DecisionEnumSerializer;

  const PluginControlServerMessageOneOf3DecisionEnum._(String name)
    : super(name);

  static BuiltSet<PluginControlServerMessageOneOf3DecisionEnum> get values =>
      _$pluginControlServerMessageOneOf3DecisionEnumValues;
  static PluginControlServerMessageOneOf3DecisionEnum valueOf(String name) =>
      _$pluginControlServerMessageOneOf3DecisionEnumValueOf(name);
}

class PluginControlServerMessageOneOf3TypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'permission_decide_command')
  static const PluginControlServerMessageOneOf3TypeEnum
  permissionDecideCommand =
      _$pluginControlServerMessageOneOf3TypeEnum_permissionDecideCommand;

  static Serializer<PluginControlServerMessageOneOf3TypeEnum> get serializer =>
      _$pluginControlServerMessageOneOf3TypeEnumSerializer;

  const PluginControlServerMessageOneOf3TypeEnum._(String name) : super(name);

  static BuiltSet<PluginControlServerMessageOneOf3TypeEnum> get values =>
      _$pluginControlServerMessageOneOf3TypeEnumValues;
  static PluginControlServerMessageOneOf3TypeEnum valueOf(String name) =>
      _$pluginControlServerMessageOneOf3TypeEnumValueOf(name);
}
