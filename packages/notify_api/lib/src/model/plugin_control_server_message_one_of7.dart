//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:notify_api/src/model/plugin_control_server_message_one_of7_query.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'plugin_control_server_message_one_of7.g.dart';

/// PluginControlServerMessageOneOf7
///
/// Properties:
/// * [query]
/// * [requestId]
/// * [type]
@BuiltValue()
abstract class PluginControlServerMessageOneOf7
    implements
        Built<
          PluginControlServerMessageOneOf7,
          PluginControlServerMessageOneOf7Builder
        > {
  @BuiltValueField(wireName: r'query')
  PluginControlServerMessageOneOf7Query get query;

  @BuiltValueField(wireName: r'requestId')
  String get requestId;

  @BuiltValueField(wireName: r'type')
  PluginControlServerMessageOneOf7TypeEnum get type;
  // enum typeEnum {  session_catalog_request,  };

  PluginControlServerMessageOneOf7._();

  factory PluginControlServerMessageOneOf7([
    void updates(PluginControlServerMessageOneOf7Builder b),
  ]) = _$PluginControlServerMessageOneOf7;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PluginControlServerMessageOneOf7Builder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PluginControlServerMessageOneOf7> get serializer =>
      _$PluginControlServerMessageOneOf7Serializer();
}

class _$PluginControlServerMessageOneOf7Serializer
    implements PrimitiveSerializer<PluginControlServerMessageOneOf7> {
  @override
  final Iterable<Type> types = const [
    PluginControlServerMessageOneOf7,
    _$PluginControlServerMessageOneOf7,
  ];

  @override
  final String wireName = r'PluginControlServerMessageOneOf7';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PluginControlServerMessageOneOf7 object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'query';
    yield serializers.serialize(
      object.query,
      specifiedType: const FullType(PluginControlServerMessageOneOf7Query),
    );
    yield r'requestId';
    yield serializers.serialize(
      object.requestId,
      specifiedType: const FullType(String),
    );
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(PluginControlServerMessageOneOf7TypeEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PluginControlServerMessageOneOf7 object, {
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
    required PluginControlServerMessageOneOf7Builder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'query':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      PluginControlServerMessageOneOf7Query,
                    ),
                  )
                  as PluginControlServerMessageOneOf7Query;
          result.query.replace(valueDes);
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
        case r'type':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      PluginControlServerMessageOneOf7TypeEnum,
                    ),
                  )
                  as PluginControlServerMessageOneOf7TypeEnum;
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
  PluginControlServerMessageOneOf7 deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PluginControlServerMessageOneOf7Builder();
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

class PluginControlServerMessageOneOf7TypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'session_catalog_request')
  static const PluginControlServerMessageOneOf7TypeEnum sessionCatalogRequest =
      _$pluginControlServerMessageOneOf7TypeEnum_sessionCatalogRequest;

  static Serializer<PluginControlServerMessageOneOf7TypeEnum> get serializer =>
      _$pluginControlServerMessageOneOf7TypeEnumSerializer;

  const PluginControlServerMessageOneOf7TypeEnum._(String name) : super(name);

  static BuiltSet<PluginControlServerMessageOneOf7TypeEnum> get values =>
      _$pluginControlServerMessageOneOf7TypeEnumValues;
  static PluginControlServerMessageOneOf7TypeEnum valueOf(String name) =>
      _$pluginControlServerMessageOneOf7TypeEnumValueOf(name);
}
