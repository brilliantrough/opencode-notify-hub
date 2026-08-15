//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'permission_command_result.g.dart';

/// PermissionCommandResult
///
/// Properties:
/// * [commandId]
/// * [status]
@BuiltValue()
abstract class PermissionCommandResult
    implements Built<PermissionCommandResult, PermissionCommandResultBuilder> {
  @BuiltValueField(wireName: r'commandId')
  String get commandId;

  @BuiltValueField(wireName: r'status')
  PermissionCommandResultStatusEnum get status;
  // enum statusEnum {  confirmed,  stale,  upstream_error,  result_unknown,  };

  PermissionCommandResult._();

  factory PermissionCommandResult([
    void updates(PermissionCommandResultBuilder b),
  ]) = _$PermissionCommandResult;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PermissionCommandResultBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PermissionCommandResult> get serializer =>
      _$PermissionCommandResultSerializer();
}

class _$PermissionCommandResultSerializer
    implements PrimitiveSerializer<PermissionCommandResult> {
  @override
  final Iterable<Type> types = const [
    PermissionCommandResult,
    _$PermissionCommandResult,
  ];

  @override
  final String wireName = r'PermissionCommandResult';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PermissionCommandResult object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'commandId';
    yield serializers.serialize(
      object.commandId,
      specifiedType: const FullType(String),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(PermissionCommandResultStatusEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PermissionCommandResult object, {
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
    required PermissionCommandResultBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'commandId':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.commandId = valueDes;
          break;
        case r'status':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      PermissionCommandResultStatusEnum,
                    ),
                  )
                  as PermissionCommandResultStatusEnum;
          result.status = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PermissionCommandResult deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PermissionCommandResultBuilder();
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

class PermissionCommandResultStatusEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'confirmed')
  static const PermissionCommandResultStatusEnum confirmed =
      _$permissionCommandResultStatusEnum_confirmed;
  @BuiltValueEnumConst(wireName: r'stale')
  static const PermissionCommandResultStatusEnum stale =
      _$permissionCommandResultStatusEnum_stale;
  @BuiltValueEnumConst(wireName: r'upstream_error')
  static const PermissionCommandResultStatusEnum upstreamError =
      _$permissionCommandResultStatusEnum_upstreamError;
  @BuiltValueEnumConst(wireName: r'result_unknown')
  static const PermissionCommandResultStatusEnum resultUnknown =
      _$permissionCommandResultStatusEnum_resultUnknown;

  static Serializer<PermissionCommandResultStatusEnum> get serializer =>
      _$permissionCommandResultStatusEnumSerializer;

  const PermissionCommandResultStatusEnum._(String name) : super(name);

  static BuiltSet<PermissionCommandResultStatusEnum> get values =>
      _$permissionCommandResultStatusEnumValues;
  static PermissionCommandResultStatusEnum valueOf(String name) =>
      _$permissionCommandResultStatusEnumValueOf(name);
}
