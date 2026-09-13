//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'plugin_control_server_message_one_of8.g.dart';

/// PluginControlServerMessageOneOf8
///
/// Properties:
/// * [requestId]
/// * [tunnelId]
/// * [type]
@BuiltValue()
abstract class PluginControlServerMessageOneOf8
    implements
        Built<
          PluginControlServerMessageOneOf8,
          PluginControlServerMessageOneOf8Builder
        > {
  @BuiltValueField(wireName: r'requestId')
  String get requestId;

  @BuiltValueField(wireName: r'tunnelId')
  String get tunnelId;

  @BuiltValueField(wireName: r'type')
  PluginControlServerMessageOneOf8TypeEnum get type;
  // enum typeEnum {  webui_http_cancel,  };

  PluginControlServerMessageOneOf8._();

  factory PluginControlServerMessageOneOf8([
    void updates(PluginControlServerMessageOneOf8Builder b),
  ]) = _$PluginControlServerMessageOneOf8;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PluginControlServerMessageOneOf8Builder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PluginControlServerMessageOneOf8> get serializer =>
      _$PluginControlServerMessageOneOf8Serializer();
}

class _$PluginControlServerMessageOneOf8Serializer
    implements PrimitiveSerializer<PluginControlServerMessageOneOf8> {
  @override
  final Iterable<Type> types = const [
    PluginControlServerMessageOneOf8,
    _$PluginControlServerMessageOneOf8,
  ];

  @override
  final String wireName = r'PluginControlServerMessageOneOf8';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PluginControlServerMessageOneOf8 object, {
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
      specifiedType: const FullType(PluginControlServerMessageOneOf8TypeEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PluginControlServerMessageOneOf8 object, {
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
    required PluginControlServerMessageOneOf8Builder result,
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
                      PluginControlServerMessageOneOf8TypeEnum,
                    ),
                  )
                  as PluginControlServerMessageOneOf8TypeEnum;
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
  PluginControlServerMessageOneOf8 deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PluginControlServerMessageOneOf8Builder();
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

class PluginControlServerMessageOneOf8TypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'webui_http_cancel')
  static const PluginControlServerMessageOneOf8TypeEnum webuiHttpCancel =
      _$pluginControlServerMessageOneOf8TypeEnum_webuiHttpCancel;

  static Serializer<PluginControlServerMessageOneOf8TypeEnum> get serializer =>
      _$pluginControlServerMessageOneOf8TypeEnumSerializer;

  const PluginControlServerMessageOneOf8TypeEnum._(String name) : super(name);

  static BuiltSet<PluginControlServerMessageOneOf8TypeEnum> get values =>
      _$pluginControlServerMessageOneOf8TypeEnumValues;
  static PluginControlServerMessageOneOf8TypeEnum valueOf(String name) =>
      _$pluginControlServerMessageOneOf8TypeEnumValueOf(name);
}
