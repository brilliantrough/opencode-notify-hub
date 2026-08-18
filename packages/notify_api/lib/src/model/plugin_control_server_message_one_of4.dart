//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'plugin_control_server_message_one_of4.g.dart';

/// PluginControlServerMessageOneOf4
///
/// Properties:
/// * [commandId]
/// * [sessionID]
/// * [text]
/// * [type]
@BuiltValue()
abstract class PluginControlServerMessageOneOf4
    implements
        Built<
          PluginControlServerMessageOneOf4,
          PluginControlServerMessageOneOf4Builder
        > {
  @BuiltValueField(wireName: r'commandId')
  String get commandId;

  @BuiltValueField(wireName: r'sessionID')
  String get sessionID;

  @BuiltValueField(wireName: r'text')
  String get text;

  @BuiltValueField(wireName: r'type')
  PluginControlServerMessageOneOf4TypeEnum get type;
  // enum typeEnum {  session_prompt_command,  };

  PluginControlServerMessageOneOf4._();

  factory PluginControlServerMessageOneOf4([
    void updates(PluginControlServerMessageOneOf4Builder b),
  ]) = _$PluginControlServerMessageOneOf4;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PluginControlServerMessageOneOf4Builder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PluginControlServerMessageOneOf4> get serializer =>
      _$PluginControlServerMessageOneOf4Serializer();
}

class _$PluginControlServerMessageOneOf4Serializer
    implements PrimitiveSerializer<PluginControlServerMessageOneOf4> {
  @override
  final Iterable<Type> types = const [
    PluginControlServerMessageOneOf4,
    _$PluginControlServerMessageOneOf4,
  ];

  @override
  final String wireName = r'PluginControlServerMessageOneOf4';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PluginControlServerMessageOneOf4 object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'commandId';
    yield serializers.serialize(
      object.commandId,
      specifiedType: const FullType(String),
    );
    yield r'sessionID';
    yield serializers.serialize(
      object.sessionID,
      specifiedType: const FullType(String),
    );
    yield r'text';
    yield serializers.serialize(
      object.text,
      specifiedType: const FullType(String),
    );
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(PluginControlServerMessageOneOf4TypeEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PluginControlServerMessageOneOf4 object, {
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
    required PluginControlServerMessageOneOf4Builder result,
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
        case r'sessionID':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.sessionID = valueDes;
          break;
        case r'text':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.text = valueDes;
          break;
        case r'type':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      PluginControlServerMessageOneOf4TypeEnum,
                    ),
                  )
                  as PluginControlServerMessageOneOf4TypeEnum;
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
  PluginControlServerMessageOneOf4 deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PluginControlServerMessageOneOf4Builder();
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

class PluginControlServerMessageOneOf4TypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'session_prompt_command')
  static const PluginControlServerMessageOneOf4TypeEnum sessionPromptCommand =
      _$pluginControlServerMessageOneOf4TypeEnum_sessionPromptCommand;

  static Serializer<PluginControlServerMessageOneOf4TypeEnum> get serializer =>
      _$pluginControlServerMessageOneOf4TypeEnumSerializer;

  const PluginControlServerMessageOneOf4TypeEnum._(String name) : super(name);

  static BuiltSet<PluginControlServerMessageOneOf4TypeEnum> get values =>
      _$pluginControlServerMessageOneOf4TypeEnumValues;
  static PluginControlServerMessageOneOf4TypeEnum valueOf(String name) =>
      _$pluginControlServerMessageOneOf4TypeEnumValueOf(name);
}
