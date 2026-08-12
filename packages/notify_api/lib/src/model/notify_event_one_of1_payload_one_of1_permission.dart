//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'notify_event_one_of1_payload_one_of1_permission.g.dart';

/// NotifyEventOneOf1PayloadOneOf1Permission
///
/// Properties:
/// * [permission]
/// * [summary]
@BuiltValue()
abstract class NotifyEventOneOf1PayloadOneOf1Permission
    implements
        Built<
          NotifyEventOneOf1PayloadOneOf1Permission,
          NotifyEventOneOf1PayloadOneOf1PermissionBuilder
        > {
  @BuiltValueField(wireName: r'permission')
  String get permission;

  @BuiltValueField(wireName: r'summary')
  String get summary;

  NotifyEventOneOf1PayloadOneOf1Permission._();

  factory NotifyEventOneOf1PayloadOneOf1Permission([
    void updates(NotifyEventOneOf1PayloadOneOf1PermissionBuilder b),
  ]) = _$NotifyEventOneOf1PayloadOneOf1Permission;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(NotifyEventOneOf1PayloadOneOf1PermissionBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<NotifyEventOneOf1PayloadOneOf1Permission> get serializer =>
      _$NotifyEventOneOf1PayloadOneOf1PermissionSerializer();
}

class _$NotifyEventOneOf1PayloadOneOf1PermissionSerializer
    implements PrimitiveSerializer<NotifyEventOneOf1PayloadOneOf1Permission> {
  @override
  final Iterable<Type> types = const [
    NotifyEventOneOf1PayloadOneOf1Permission,
    _$NotifyEventOneOf1PayloadOneOf1Permission,
  ];

  @override
  final String wireName = r'NotifyEventOneOf1PayloadOneOf1Permission';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    NotifyEventOneOf1PayloadOneOf1Permission object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'permission';
    yield serializers.serialize(
      object.permission,
      specifiedType: const FullType(String),
    );
    yield r'summary';
    yield serializers.serialize(
      object.summary,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    NotifyEventOneOf1PayloadOneOf1Permission object, {
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
    required NotifyEventOneOf1PayloadOneOf1PermissionBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'permission':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.permission = valueDes;
          break;
        case r'summary':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.summary = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  NotifyEventOneOf1PayloadOneOf1Permission deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = NotifyEventOneOf1PayloadOneOf1PermissionBuilder();
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
