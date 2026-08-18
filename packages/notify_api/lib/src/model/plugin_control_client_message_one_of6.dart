//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'plugin_control_client_message_one_of6.g.dart';

/// PluginControlClientMessageOneOf6
///
/// Properties:
/// * [body]
/// * [requestId]
/// * [tunnelId]
/// * [type]
@BuiltValue()
abstract class PluginControlClientMessageOneOf6
    implements
        Built<
          PluginControlClientMessageOneOf6,
          PluginControlClientMessageOneOf6Builder
        > {
  @BuiltValueField(wireName: r'body')
  String get body;

  @BuiltValueField(wireName: r'requestId')
  String get requestId;

  @BuiltValueField(wireName: r'tunnelId')
  String get tunnelId;

  @BuiltValueField(wireName: r'type')
  PluginControlClientMessageOneOf6TypeEnum get type;
  // enum typeEnum {  webui_http_response_chunk,  };

  PluginControlClientMessageOneOf6._();

  factory PluginControlClientMessageOneOf6([
    void updates(PluginControlClientMessageOneOf6Builder b),
  ]) = _$PluginControlClientMessageOneOf6;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PluginControlClientMessageOneOf6Builder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PluginControlClientMessageOneOf6> get serializer =>
      _$PluginControlClientMessageOneOf6Serializer();
}

class _$PluginControlClientMessageOneOf6Serializer
    implements PrimitiveSerializer<PluginControlClientMessageOneOf6> {
  @override
  final Iterable<Type> types = const [
    PluginControlClientMessageOneOf6,
    _$PluginControlClientMessageOneOf6,
  ];

  @override
  final String wireName = r'PluginControlClientMessageOneOf6';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PluginControlClientMessageOneOf6 object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'body';
    yield serializers.serialize(
      object.body,
      specifiedType: const FullType(String),
    );
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
      specifiedType: const FullType(PluginControlClientMessageOneOf6TypeEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PluginControlClientMessageOneOf6 object, {
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
    required PluginControlClientMessageOneOf6Builder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'body':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.body = valueDes;
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
                      PluginControlClientMessageOneOf6TypeEnum,
                    ),
                  )
                  as PluginControlClientMessageOneOf6TypeEnum;
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
  PluginControlClientMessageOneOf6 deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PluginControlClientMessageOneOf6Builder();
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

class PluginControlClientMessageOneOf6TypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'webui_http_response_chunk')
  static const PluginControlClientMessageOneOf6TypeEnum webuiHttpResponseChunk =
      _$pluginControlClientMessageOneOf6TypeEnum_webuiHttpResponseChunk;

  static Serializer<PluginControlClientMessageOneOf6TypeEnum> get serializer =>
      _$pluginControlClientMessageOneOf6TypeEnumSerializer;

  const PluginControlClientMessageOneOf6TypeEnum._(String name) : super(name);

  static BuiltSet<PluginControlClientMessageOneOf6TypeEnum> get values =>
      _$pluginControlClientMessageOneOf6TypeEnumValues;
  static PluginControlClientMessageOneOf6TypeEnum valueOf(String name) =>
      _$pluginControlClientMessageOneOf6TypeEnumValueOf(name);
}
