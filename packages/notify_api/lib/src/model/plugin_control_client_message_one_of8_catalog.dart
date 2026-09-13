//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:notify_api/src/model/plugin_control_client_message_one_of8_catalog_sessions_inner.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'plugin_control_client_message_one_of8_catalog.g.dart';

/// PluginControlClientMessageOneOf8Catalog
///
/// Properties:
/// * [hasMore]
/// * [sessions]
@BuiltValue()
abstract class PluginControlClientMessageOneOf8Catalog
    implements
        Built<
          PluginControlClientMessageOneOf8Catalog,
          PluginControlClientMessageOneOf8CatalogBuilder
        > {
  @BuiltValueField(wireName: r'hasMore')
  bool get hasMore;

  @BuiltValueField(wireName: r'sessions')
  BuiltList<PluginControlClientMessageOneOf8CatalogSessionsInner> get sessions;

  PluginControlClientMessageOneOf8Catalog._();

  factory PluginControlClientMessageOneOf8Catalog([
    void updates(PluginControlClientMessageOneOf8CatalogBuilder b),
  ]) = _$PluginControlClientMessageOneOf8Catalog;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PluginControlClientMessageOneOf8CatalogBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PluginControlClientMessageOneOf8Catalog> get serializer =>
      _$PluginControlClientMessageOneOf8CatalogSerializer();
}

class _$PluginControlClientMessageOneOf8CatalogSerializer
    implements PrimitiveSerializer<PluginControlClientMessageOneOf8Catalog> {
  @override
  final Iterable<Type> types = const [
    PluginControlClientMessageOneOf8Catalog,
    _$PluginControlClientMessageOneOf8Catalog,
  ];

  @override
  final String wireName = r'PluginControlClientMessageOneOf8Catalog';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PluginControlClientMessageOneOf8Catalog object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'hasMore';
    yield serializers.serialize(
      object.hasMore,
      specifiedType: const FullType(bool),
    );
    yield r'sessions';
    yield serializers.serialize(
      object.sessions,
      specifiedType: const FullType(BuiltList, [
        FullType(PluginControlClientMessageOneOf8CatalogSessionsInner),
      ]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PluginControlClientMessageOneOf8Catalog object, {
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
    required PluginControlClientMessageOneOf8CatalogBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'hasMore':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(bool),
                  )
                  as bool;
          result.hasMore = valueDes;
          break;
        case r'sessions':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(BuiltList, [
                      FullType(
                        PluginControlClientMessageOneOf8CatalogSessionsInner,
                      ),
                    ]),
                  )
                  as BuiltList<
                    PluginControlClientMessageOneOf8CatalogSessionsInner
                  >;
          result.sessions.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PluginControlClientMessageOneOf8Catalog deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PluginControlClientMessageOneOf8CatalogBuilder();
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
