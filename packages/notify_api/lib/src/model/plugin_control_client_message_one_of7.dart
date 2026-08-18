//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'plugin_control_client_message_one_of7.g.dart';

/// PluginControlClientMessageOneOf7
///
/// Properties:
/// * [requestId]
/// * [tunnelId]
/// * [type]
@BuiltValue()
abstract class PluginControlClientMessageOneOf7
    implements
        Built<
          PluginControlClientMessageOneOf7,
          PluginControlClientMessageOneOf7Builder
        > {
  @BuiltValueField(wireName: r'requestId')
  String get requestId;

  @BuiltValueField(wireName: r'tunnelId')
  String get tunnelId;

  @BuiltValueField(wireName: r'type')
  PluginControlClientMessageOneOf7TypeEnum get type;
  // enum typeEnum {  webui_http_response_end,  };

  PluginControlClientMessageOneOf7._();

  factory PluginControlClientMessageOneOf7([
    void updates(PluginControlClientMessageOneOf7Builder b),
  ]) = _$PluginControlClientMessageOneOf7;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PluginControlClientMessageOneOf7Builder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PluginControlClientMessageOneOf7> get serializer =>
      _$PluginControlClientMessageOneOf7Serializer();
}

class _$PluginControlClientMessageOneOf7Serializer
    implements PrimitiveSerializer<PluginControlClientMessageOneOf7> {
  @override
  final Iterable<Type> types = const [
    PluginControlClientMessageOneOf7,
    _$PluginControlClientMessageOneOf7,
  ];

  @override
  final String wireName = r'PluginControlClientMessageOneOf7';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PluginControlClientMessageOneOf7 object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'requestId';
    yield serializers.serialize(
      object.requestId,
      specifiedType: const FullType(String),
    );
    yield r'tunnelId';
    yield serializers.serialize(
      object.tunnelId,
      specifiedType: const FullType(String),
    );
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(PluginControlClientMessageOneOf7TypeEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PluginControlClientMessageOneOf7 object, {
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
    required PluginControlClientMessageOneOf7Builder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'requestId':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.requestId = valueDes;
          break;
        case r'tunnelId':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.tunnelId = valueDes;
          break;
        case r'type':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      PluginControlClientMessageOneOf7TypeEnum,
                    ),
                  )
                  as PluginControlClientMessageOneOf7TypeEnum;
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
  PluginControlClientMessageOneOf7 deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PluginControlClientMessageOneOf7Builder();
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

class PluginControlClientMessageOneOf7TypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'webui_http_response_end')
  static const PluginControlClientMessageOneOf7TypeEnum webuiHttpResponseEnd =
      _$pluginControlClientMessageOneOf7TypeEnum_webuiHttpResponseEnd;

  static Serializer<PluginControlClientMessageOneOf7TypeEnum> get serializer =>
      _$pluginControlClientMessageOneOf7TypeEnumSerializer;

  const PluginControlClientMessageOneOf7TypeEnum._(String name) : super(name);

  static BuiltSet<PluginControlClientMessageOneOf7TypeEnum> get values =>
      _$pluginControlClientMessageOneOf7TypeEnumValues;
  static PluginControlClientMessageOneOf7TypeEnum valueOf(String name) =>
      _$pluginControlClientMessageOneOf7TypeEnumValueOf(name);
}
