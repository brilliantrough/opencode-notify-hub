//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'plugin_control_client_message_one_of8_catalog_sessions_inner.g.dart';

/// PluginControlClientMessageOneOf8CatalogSessionsInner
///
/// Properties:
/// * [directory]
/// * [sessionId]
/// * [status]
/// * [title]
/// * [updatedAt]
@BuiltValue()
abstract class PluginControlClientMessageOneOf8CatalogSessionsInner
    implements
        Built<
          PluginControlClientMessageOneOf8CatalogSessionsInner,
          PluginControlClientMessageOneOf8CatalogSessionsInnerBuilder
        > {
  @BuiltValueField(wireName: r'directory')
  String get directory;

  @BuiltValueField(wireName: r'sessionId')
  String get sessionId;

  @BuiltValueField(wireName: r'status')
  PluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum get status;
  // enum statusEnum {  idle,  busy,  retry,  unknown,  };

  @BuiltValueField(wireName: r'title')
  String get title;

  @BuiltValueField(wireName: r'updatedAt')
  DateTime get updatedAt;

  PluginControlClientMessageOneOf8CatalogSessionsInner._();

  factory PluginControlClientMessageOneOf8CatalogSessionsInner([
    void updates(PluginControlClientMessageOneOf8CatalogSessionsInnerBuilder b),
  ]) = _$PluginControlClientMessageOneOf8CatalogSessionsInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(
    PluginControlClientMessageOneOf8CatalogSessionsInnerBuilder b,
  ) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PluginControlClientMessageOneOf8CatalogSessionsInner>
  get serializer =>
      _$PluginControlClientMessageOneOf8CatalogSessionsInnerSerializer();
}

class _$PluginControlClientMessageOneOf8CatalogSessionsInnerSerializer
    implements
        PrimitiveSerializer<
          PluginControlClientMessageOneOf8CatalogSessionsInner
        > {
  @override
  final Iterable<Type> types = const [
    PluginControlClientMessageOneOf8CatalogSessionsInner,
    _$PluginControlClientMessageOneOf8CatalogSessionsInner,
  ];

  @override
  final String wireName =
      r'PluginControlClientMessageOneOf8CatalogSessionsInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PluginControlClientMessageOneOf8CatalogSessionsInner object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'directory';
    yield serializers.serialize(
      object.directory,
      specifiedType: const FullType(String),
    );
    yield r'sessionId';
    yield serializers.serialize(
      object.sessionId,
      specifiedType: const FullType(String),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(
        PluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum,
      ),
    );
    yield r'title';
    yield serializers.serialize(
      object.title,
      specifiedType: const FullType(String),
    );
    yield r'updatedAt';
    yield serializers.serialize(
      object.updatedAt,
      specifiedType: const FullType(DateTime),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PluginControlClientMessageOneOf8CatalogSessionsInner object, {
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
    required PluginControlClientMessageOneOf8CatalogSessionsInnerBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'directory':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.directory = valueDes;
          break;
        case r'sessionId':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.sessionId = valueDes;
          break;
        case r'status':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      PluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum,
                    ),
                  )
                  as PluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum;
          result.status = valueDes;
          break;
        case r'title':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.title = valueDes;
          break;
        case r'updatedAt':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(DateTime),
                  )
                  as DateTime;
          result.updatedAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PluginControlClientMessageOneOf8CatalogSessionsInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result =
        PluginControlClientMessageOneOf8CatalogSessionsInnerBuilder();
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

class PluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum
    extends EnumClass {
  @BuiltValueEnumConst(wireName: r'idle')
  static const PluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum
  idle = _$pluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum_idle;
  @BuiltValueEnumConst(wireName: r'busy')
  static const PluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum
  busy = _$pluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum_busy;
  @BuiltValueEnumConst(wireName: r'retry')
  static const PluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum
  retry =
      _$pluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum_retry;
  @BuiltValueEnumConst(wireName: r'unknown')
  static const PluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum
  unknown =
      _$pluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum_unknown;

  static Serializer<
    PluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum
  >
  get serializer =>
      _$pluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnumSerializer;

  const PluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum._(
    String name,
  ) : super(name);

  static BuiltSet<
    PluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum
  >
  get values =>
      _$pluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnumValues;
  static PluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnum valueOf(
    String name,
  ) => _$pluginControlClientMessageOneOf8CatalogSessionsInnerStatusEnumValueOf(
    name,
  );
}
