//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:notify_api/src/model/plugin_control_client_message_one_of8_catalog.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'plugin_control_client_message_one_of8.g.dart';

/// PluginControlClientMessageOneOf8
///
/// Properties:
/// * [catalog]
/// * [instanceId]
/// * [requestId]
/// * [status]
/// * [type]
@BuiltValue()
abstract class PluginControlClientMessageOneOf8
    implements
        Built<
          PluginControlClientMessageOneOf8,
          PluginControlClientMessageOneOf8Builder
        > {
  @BuiltValueField(wireName: r'catalog')
  PluginControlClientMessageOneOf8Catalog? get catalog;

  @BuiltValueField(wireName: r'instanceId')
  String get instanceId;

  @BuiltValueField(wireName: r'requestId')
  String get requestId;

  @BuiltValueField(wireName: r'status')
  PluginControlClientMessageOneOf8StatusEnum get status;
  // enum statusEnum {  ready,  error,  unsupported,  };

  @BuiltValueField(wireName: r'type')
  PluginControlClientMessageOneOf8TypeEnum get type;
  // enum typeEnum {  session_catalog_response,  };

  PluginControlClientMessageOneOf8._();

  factory PluginControlClientMessageOneOf8([
    void updates(PluginControlClientMessageOneOf8Builder b),
  ]) = _$PluginControlClientMessageOneOf8;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PluginControlClientMessageOneOf8Builder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PluginControlClientMessageOneOf8> get serializer =>
      _$PluginControlClientMessageOneOf8Serializer();
}

class _$PluginControlClientMessageOneOf8Serializer
    implements PrimitiveSerializer<PluginControlClientMessageOneOf8> {
  @override
  final Iterable<Type> types = const [
    PluginControlClientMessageOneOf8,
    _$PluginControlClientMessageOneOf8,
  ];

  @override
  final String wireName = r'PluginControlClientMessageOneOf8';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PluginControlClientMessageOneOf8 object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.catalog != null) {
      yield r'catalog';
      yield serializers.serialize(
        object.catalog,
        specifiedType: const FullType(PluginControlClientMessageOneOf8Catalog),
      );
    }
    yield r'instanceId';
    yield serializers.serialize(
      object.instanceId,
      specifiedType: const FullType(String),
    );
    yield r'requestId';
    yield serializers.serialize(
      object.requestId,
      specifiedType: const FullType(String),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(PluginControlClientMessageOneOf8StatusEnum),
    );
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(PluginControlClientMessageOneOf8TypeEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PluginControlClientMessageOneOf8 object, {
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
    required PluginControlClientMessageOneOf8Builder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'catalog':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      PluginControlClientMessageOneOf8Catalog,
                    ),
                  )
                  as PluginControlClientMessageOneOf8Catalog;
          result.catalog.replace(valueDes);
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
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      PluginControlClientMessageOneOf8StatusEnum,
                    ),
                  )
                  as PluginControlClientMessageOneOf8StatusEnum;
          result.status = valueDes;
          break;
        case r'type':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      PluginControlClientMessageOneOf8TypeEnum,
                    ),
                  )
                  as PluginControlClientMessageOneOf8TypeEnum;
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
  PluginControlClientMessageOneOf8 deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PluginControlClientMessageOneOf8Builder();
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

class PluginControlClientMessageOneOf8StatusEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'ready')
  static const PluginControlClientMessageOneOf8StatusEnum ready =
      _$pluginControlClientMessageOneOf8StatusEnum_ready;
  @BuiltValueEnumConst(wireName: r'error')
  static const PluginControlClientMessageOneOf8StatusEnum error =
      _$pluginControlClientMessageOneOf8StatusEnum_error;
  @BuiltValueEnumConst(wireName: r'unsupported')
  static const PluginControlClientMessageOneOf8StatusEnum unsupported =
      _$pluginControlClientMessageOneOf8StatusEnum_unsupported;

  static Serializer<PluginControlClientMessageOneOf8StatusEnum>
  get serializer => _$pluginControlClientMessageOneOf8StatusEnumSerializer;

  const PluginControlClientMessageOneOf8StatusEnum._(String name) : super(name);

  static BuiltSet<PluginControlClientMessageOneOf8StatusEnum> get values =>
      _$pluginControlClientMessageOneOf8StatusEnumValues;
  static PluginControlClientMessageOneOf8StatusEnum valueOf(String name) =>
      _$pluginControlClientMessageOneOf8StatusEnumValueOf(name);
}

class PluginControlClientMessageOneOf8TypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'session_catalog_response')
  static const PluginControlClientMessageOneOf8TypeEnum sessionCatalogResponse =
      _$pluginControlClientMessageOneOf8TypeEnum_sessionCatalogResponse;

  static Serializer<PluginControlClientMessageOneOf8TypeEnum> get serializer =>
      _$pluginControlClientMessageOneOf8TypeEnumSerializer;

  const PluginControlClientMessageOneOf8TypeEnum._(String name) : super(name);

  static BuiltSet<PluginControlClientMessageOneOf8TypeEnum> get values =>
      _$pluginControlClientMessageOneOf8TypeEnumValues;
  static PluginControlClientMessageOneOf8TypeEnum valueOf(String name) =>
      _$pluginControlClientMessageOneOf8TypeEnumValueOf(name);
}
