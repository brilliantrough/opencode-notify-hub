//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'plugin_control_client_message_one_of5.g.dart';

/// PluginControlClientMessageOneOf5
///
/// Properties:
/// * [headers]
/// * [requestId]
/// * [status]
/// * [tunnelId]
/// * [type]
@BuiltValue()
abstract class PluginControlClientMessageOneOf5
    implements
        Built<
          PluginControlClientMessageOneOf5,
          PluginControlClientMessageOneOf5Builder
        > {
  @BuiltValueField(wireName: r'headers')
  BuiltMap<String, BuiltList<String>> get headers;

  @BuiltValueField(wireName: r'requestId')
  String get requestId;

  @BuiltValueField(wireName: r'status')
  int get status;

  @BuiltValueField(wireName: r'tunnelId')
  String get tunnelId;

  @BuiltValueField(wireName: r'type')
  PluginControlClientMessageOneOf5TypeEnum get type;
  // enum typeEnum {  webui_http_response_start,  };

  PluginControlClientMessageOneOf5._();

  factory PluginControlClientMessageOneOf5([
    void updates(PluginControlClientMessageOneOf5Builder b),
  ]) = _$PluginControlClientMessageOneOf5;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PluginControlClientMessageOneOf5Builder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PluginControlClientMessageOneOf5> get serializer =>
      _$PluginControlClientMessageOneOf5Serializer();
}

class _$PluginControlClientMessageOneOf5Serializer
    implements PrimitiveSerializer<PluginControlClientMessageOneOf5> {
  @override
  final Iterable<Type> types = const [
    PluginControlClientMessageOneOf5,
    _$PluginControlClientMessageOneOf5,
  ];

  @override
  final String wireName = r'PluginControlClientMessageOneOf5';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PluginControlClientMessageOneOf5 object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'headers';
    yield serializers.serialize(
      object.headers,
      specifiedType: const FullType(BuiltMap, [
        FullType(String),
        FullType(BuiltList, [FullType(String)]),
      ]),
    );
    yield r'requestId';
    yield serializers.serialize(
      object.requestId,
      specifiedType: const FullType(String),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(int),
    );
    yield r'tunnelId';
    yield serializers.serialize(
      object.tunnelId,
      specifiedType: const FullType(String),
    );
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(PluginControlClientMessageOneOf5TypeEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PluginControlClientMessageOneOf5 object, {
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
    required PluginControlClientMessageOneOf5Builder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'headers':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(BuiltMap, [
                      FullType(String),
                      FullType(BuiltList, [FullType(String)]),
                    ]),
                  )
                  as BuiltMap<String, BuiltList<String>>;
          result.headers.replace(valueDes);
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
        case r'status':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(int))
                  as int;
          result.status = valueDes;
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
                      PluginControlClientMessageOneOf5TypeEnum,
                    ),
                  )
                  as PluginControlClientMessageOneOf5TypeEnum;
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
  PluginControlClientMessageOneOf5 deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PluginControlClientMessageOneOf5Builder();
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

class PluginControlClientMessageOneOf5TypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'webui_http_response_start')
  static const PluginControlClientMessageOneOf5TypeEnum webuiHttpResponseStart =
      _$pluginControlClientMessageOneOf5TypeEnum_webuiHttpResponseStart;

  static Serializer<PluginControlClientMessageOneOf5TypeEnum> get serializer =>
      _$pluginControlClientMessageOneOf5TypeEnumSerializer;

  const PluginControlClientMessageOneOf5TypeEnum._(String name) : super(name);

  static BuiltSet<PluginControlClientMessageOneOf5TypeEnum> get values =>
      _$pluginControlClientMessageOneOf5TypeEnumValues;
  static PluginControlClientMessageOneOf5TypeEnum valueOf(String name) =>
      _$pluginControlClientMessageOneOf5TypeEnumValueOf(name);
}
