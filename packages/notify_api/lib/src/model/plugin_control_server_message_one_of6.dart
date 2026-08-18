//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'plugin_control_server_message_one_of6.g.dart';

/// PluginControlServerMessageOneOf6
///
/// Properties:
/// * [tunnelId]
/// * [type]
@BuiltValue()
abstract class PluginControlServerMessageOneOf6
    implements
        Built<
          PluginControlServerMessageOneOf6,
          PluginControlServerMessageOneOf6Builder
        > {
  @BuiltValueField(wireName: r'tunnelId')
  String get tunnelId;

  @BuiltValueField(wireName: r'type')
  PluginControlServerMessageOneOf6TypeEnum get type;
  // enum typeEnum {  webui_tunnel_close,  };

  PluginControlServerMessageOneOf6._();

  factory PluginControlServerMessageOneOf6([
    void updates(PluginControlServerMessageOneOf6Builder b),
  ]) = _$PluginControlServerMessageOneOf6;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PluginControlServerMessageOneOf6Builder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PluginControlServerMessageOneOf6> get serializer =>
      _$PluginControlServerMessageOneOf6Serializer();
}

class _$PluginControlServerMessageOneOf6Serializer
    implements PrimitiveSerializer<PluginControlServerMessageOneOf6> {
  @override
  final Iterable<Type> types = const [
    PluginControlServerMessageOneOf6,
    _$PluginControlServerMessageOneOf6,
  ];

  @override
  final String wireName = r'PluginControlServerMessageOneOf6';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PluginControlServerMessageOneOf6 object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'tunnelId';
    yield serializers.serialize(
      object.tunnelId,
      specifiedType: const FullType(String),
    );
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(PluginControlServerMessageOneOf6TypeEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PluginControlServerMessageOneOf6 object, {
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
    required PluginControlServerMessageOneOf6Builder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
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
                      PluginControlServerMessageOneOf6TypeEnum,
                    ),
                  )
                  as PluginControlServerMessageOneOf6TypeEnum;
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
  PluginControlServerMessageOneOf6 deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PluginControlServerMessageOneOf6Builder();
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

class PluginControlServerMessageOneOf6TypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'webui_tunnel_close')
  static const PluginControlServerMessageOneOf6TypeEnum webuiTunnelClose =
      _$pluginControlServerMessageOneOf6TypeEnum_webuiTunnelClose;

  static Serializer<PluginControlServerMessageOneOf6TypeEnum> get serializer =>
      _$pluginControlServerMessageOneOf6TypeEnumSerializer;

  const PluginControlServerMessageOneOf6TypeEnum._(String name) : super(name);

  static BuiltSet<PluginControlServerMessageOneOf6TypeEnum> get values =>
      _$pluginControlServerMessageOneOf6TypeEnumValues;
  static PluginControlServerMessageOneOf6TypeEnum valueOf(String name) =>
      _$pluginControlServerMessageOneOf6TypeEnumValueOf(name);
}
