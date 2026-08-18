//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'plugin_control_server_message_one_of5.g.dart';

/// PluginControlServerMessageOneOf5
///
/// Properties:
/// * [body]
/// * [headers]
/// * [method]
/// * [path]
/// * [requestId]
/// * [tunnelId]
/// * [type]
@BuiltValue()
abstract class PluginControlServerMessageOneOf5
    implements
        Built<
          PluginControlServerMessageOneOf5,
          PluginControlServerMessageOneOf5Builder
        > {
  @BuiltValueField(wireName: r'body')
  String? get body;

  @BuiltValueField(wireName: r'headers')
  BuiltMap<String, BuiltList<String>> get headers;

  @BuiltValueField(wireName: r'method')
  String get method;

  @BuiltValueField(wireName: r'path')
  String get path;

  @BuiltValueField(wireName: r'requestId')
  String get requestId;

  @BuiltValueField(wireName: r'tunnelId')
  String get tunnelId;

  @BuiltValueField(wireName: r'type')
  PluginControlServerMessageOneOf5TypeEnum get type;
  // enum typeEnum {  webui_http_request,  };

  PluginControlServerMessageOneOf5._();

  factory PluginControlServerMessageOneOf5([
    void updates(PluginControlServerMessageOneOf5Builder b),
  ]) = _$PluginControlServerMessageOneOf5;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PluginControlServerMessageOneOf5Builder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PluginControlServerMessageOneOf5> get serializer =>
      _$PluginControlServerMessageOneOf5Serializer();
}

class _$PluginControlServerMessageOneOf5Serializer
    implements PrimitiveSerializer<PluginControlServerMessageOneOf5> {
  @override
  final Iterable<Type> types = const [
    PluginControlServerMessageOneOf5,
    _$PluginControlServerMessageOneOf5,
  ];

  @override
  final String wireName = r'PluginControlServerMessageOneOf5';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PluginControlServerMessageOneOf5 object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.body != null) {
      yield r'body';
      yield serializers.serialize(
        object.body,
        specifiedType: const FullType(String),
      );
    }
    yield r'headers';
    yield serializers.serialize(
      object.headers,
      specifiedType: const FullType(BuiltMap, [
        FullType(String),
        FullType(BuiltList, [FullType(String)]),
      ]),
    );
    yield r'method';
    yield serializers.serialize(
      object.method,
      specifiedType: const FullType(String),
    );
    yield r'path';
    yield serializers.serialize(
      object.path,
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
      specifiedType: const FullType(PluginControlServerMessageOneOf5TypeEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PluginControlServerMessageOneOf5 object, {
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
    required PluginControlServerMessageOneOf5Builder result,
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
        case r'method':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.method = valueDes;
          break;
        case r'path':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.path = valueDes;
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
                      PluginControlServerMessageOneOf5TypeEnum,
                    ),
                  )
                  as PluginControlServerMessageOneOf5TypeEnum;
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
  PluginControlServerMessageOneOf5 deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PluginControlServerMessageOneOf5Builder();
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

class PluginControlServerMessageOneOf5TypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'webui_http_request')
  static const PluginControlServerMessageOneOf5TypeEnum webuiHttpRequest =
      _$pluginControlServerMessageOneOf5TypeEnum_webuiHttpRequest;

  static Serializer<PluginControlServerMessageOneOf5TypeEnum> get serializer =>
      _$pluginControlServerMessageOneOf5TypeEnumSerializer;

  const PluginControlServerMessageOneOf5TypeEnum._(String name) : super(name);

  static BuiltSet<PluginControlServerMessageOneOf5TypeEnum> get values =>
      _$pluginControlServerMessageOneOf5TypeEnumValues;
  static PluginControlServerMessageOneOf5TypeEnum valueOf(String name) =>
      _$pluginControlServerMessageOneOf5TypeEnumValueOf(name);
}
