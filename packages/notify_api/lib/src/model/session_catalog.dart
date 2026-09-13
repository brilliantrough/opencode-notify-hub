//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:notify_api/src/model/plugin_control_client_message_one_of8_catalog_sessions_inner.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'session_catalog.g.dart';

/// SessionCatalog
///
/// Properties:
/// * [hasMore]
/// * [sessions]
@BuiltValue()
abstract class SessionCatalog
    implements Built<SessionCatalog, SessionCatalogBuilder> {
  @BuiltValueField(wireName: r'hasMore')
  bool get hasMore;

  @BuiltValueField(wireName: r'sessions')
  BuiltList<PluginControlClientMessageOneOf8CatalogSessionsInner> get sessions;

  SessionCatalog._();

  factory SessionCatalog([void updates(SessionCatalogBuilder b)]) =
      _$SessionCatalog;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SessionCatalogBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SessionCatalog> get serializer =>
      _$SessionCatalogSerializer();
}

class _$SessionCatalogSerializer
    implements PrimitiveSerializer<SessionCatalog> {
  @override
  final Iterable<Type> types = const [SessionCatalog, _$SessionCatalog];

  @override
  final String wireName = r'SessionCatalog';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SessionCatalog object, {
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
    SessionCatalog object, {
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
    required SessionCatalogBuilder result,
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
  SessionCatalog deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SessionCatalogBuilder();
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
