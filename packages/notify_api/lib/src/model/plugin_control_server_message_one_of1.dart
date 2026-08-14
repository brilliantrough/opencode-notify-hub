//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'plugin_control_server_message_one_of1.g.dart';

/// PluginControlServerMessageOneOf1
///
/// Properties:
/// * [requestId]
/// * [type]
@BuiltValue()
abstract class PluginControlServerMessageOneOf1
    implements
        Built<
          PluginControlServerMessageOneOf1,
          PluginControlServerMessageOneOf1Builder
        > {
  @BuiltValueField(wireName: r'requestId')
  String get requestId;

  @BuiltValueField(wireName: r'type')
  PluginControlServerMessageOneOf1TypeEnum get type;
  // enum typeEnum {  pending_snapshot_request,  };

  PluginControlServerMessageOneOf1._();

  factory PluginControlServerMessageOneOf1([
    void updates(PluginControlServerMessageOneOf1Builder b),
  ]) = _$PluginControlServerMessageOneOf1;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PluginControlServerMessageOneOf1Builder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PluginControlServerMessageOneOf1> get serializer =>
      _$PluginControlServerMessageOneOf1Serializer();
}

class _$PluginControlServerMessageOneOf1Serializer
    implements PrimitiveSerializer<PluginControlServerMessageOneOf1> {
  @override
  final Iterable<Type> types = const [
    PluginControlServerMessageOneOf1,
    _$PluginControlServerMessageOneOf1,
  ];

  @override
  final String wireName = r'PluginControlServerMessageOneOf1';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PluginControlServerMessageOneOf1 object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'requestId';
    yield serializers.serialize(
      object.requestId,
      specifiedType: const FullType(String),
    );
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(PluginControlServerMessageOneOf1TypeEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PluginControlServerMessageOneOf1 object, {
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
    required PluginControlServerMessageOneOf1Builder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
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
                      PluginControlServerMessageOneOf1TypeEnum,
                    ),
                  )
                  as PluginControlServerMessageOneOf1TypeEnum;
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
  PluginControlServerMessageOneOf1 deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PluginControlServerMessageOneOf1Builder();
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

class PluginControlServerMessageOneOf1TypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'pending_snapshot_request')
  static const PluginControlServerMessageOneOf1TypeEnum pendingSnapshotRequest =
      _$pluginControlServerMessageOneOf1TypeEnum_pendingSnapshotRequest;

  static Serializer<PluginControlServerMessageOneOf1TypeEnum> get serializer =>
      _$pluginControlServerMessageOneOf1TypeEnumSerializer;

  const PluginControlServerMessageOneOf1TypeEnum._(String name) : super(name);

  static BuiltSet<PluginControlServerMessageOneOf1TypeEnum> get values =>
      _$pluginControlServerMessageOneOf1TypeEnumValues;
  static PluginControlServerMessageOneOf1TypeEnum valueOf(String name) =>
      _$pluginControlServerMessageOneOf1TypeEnumValueOf(name);
}
