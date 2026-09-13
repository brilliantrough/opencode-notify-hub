//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'plugin_control_server_message_one_of7_query.g.dart';

/// PluginControlServerMessageOneOf7Query
///
/// Properties:
/// * [limit]
/// * [search]
/// * [sessionIds]
@BuiltValue()
abstract class PluginControlServerMessageOneOf7Query
    implements
        Built<
          PluginControlServerMessageOneOf7Query,
          PluginControlServerMessageOneOf7QueryBuilder
        > {
  @BuiltValueField(wireName: r'limit')
  int? get limit;

  @BuiltValueField(wireName: r'search')
  String? get search;

  @BuiltValueField(wireName: r'sessionIds')
  String? get sessionIds;

  PluginControlServerMessageOneOf7Query._();

  factory PluginControlServerMessageOneOf7Query([
    void updates(PluginControlServerMessageOneOf7QueryBuilder b),
  ]) = _$PluginControlServerMessageOneOf7Query;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PluginControlServerMessageOneOf7QueryBuilder b) =>
      b..limit = 50;

  @BuiltValueSerializer(custom: true)
  static Serializer<PluginControlServerMessageOneOf7Query> get serializer =>
      _$PluginControlServerMessageOneOf7QuerySerializer();
}

class _$PluginControlServerMessageOneOf7QuerySerializer
    implements PrimitiveSerializer<PluginControlServerMessageOneOf7Query> {
  @override
  final Iterable<Type> types = const [
    PluginControlServerMessageOneOf7Query,
    _$PluginControlServerMessageOneOf7Query,
  ];

  @override
  final String wireName = r'PluginControlServerMessageOneOf7Query';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PluginControlServerMessageOneOf7Query object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.limit != null) {
      yield r'limit';
      yield serializers.serialize(
        object.limit,
        specifiedType: const FullType(int),
      );
    }
    if (object.search != null) {
      yield r'search';
      yield serializers.serialize(
        object.search,
        specifiedType: const FullType(String),
      );
    }
    if (object.sessionIds != null) {
      yield r'sessionIds';
      yield serializers.serialize(
        object.sessionIds,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    PluginControlServerMessageOneOf7Query object, {
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
    required PluginControlServerMessageOneOf7QueryBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'limit':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(int))
                  as int;
          result.limit = valueDes;
          break;
        case r'search':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.search = valueDes;
          break;
        case r'sessionIds':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.sessionIds = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PluginControlServerMessageOneOf7Query deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PluginControlServerMessageOneOf7QueryBuilder();
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
