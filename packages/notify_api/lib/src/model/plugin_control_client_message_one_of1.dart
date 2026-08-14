//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:notify_api/src/model/pending_snapshot_interactions_inner.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'plugin_control_client_message_one_of1.g.dart';

/// PluginControlClientMessageOneOf1
///
/// Properties:
/// * [instanceId]
/// * [interactions]
/// * [requestId]
/// * [type]
@BuiltValue()
abstract class PluginControlClientMessageOneOf1
    implements
        Built<
          PluginControlClientMessageOneOf1,
          PluginControlClientMessageOneOf1Builder
        > {
  @BuiltValueField(wireName: r'instanceId')
  String get instanceId;

  @BuiltValueField(wireName: r'interactions')
  BuiltList<PendingSnapshotInteractionsInner> get interactions;

  @BuiltValueField(wireName: r'requestId')
  String get requestId;

  @BuiltValueField(wireName: r'type')
  PluginControlClientMessageOneOf1TypeEnum get type;
  // enum typeEnum {  pending_snapshot_response,  };

  PluginControlClientMessageOneOf1._();

  factory PluginControlClientMessageOneOf1([
    void updates(PluginControlClientMessageOneOf1Builder b),
  ]) = _$PluginControlClientMessageOneOf1;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PluginControlClientMessageOneOf1Builder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PluginControlClientMessageOneOf1> get serializer =>
      _$PluginControlClientMessageOneOf1Serializer();
}

class _$PluginControlClientMessageOneOf1Serializer
    implements PrimitiveSerializer<PluginControlClientMessageOneOf1> {
  @override
  final Iterable<Type> types = const [
    PluginControlClientMessageOneOf1,
    _$PluginControlClientMessageOneOf1,
  ];

  @override
  final String wireName = r'PluginControlClientMessageOneOf1';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PluginControlClientMessageOneOf1 object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'instanceId';
    yield serializers.serialize(
      object.instanceId,
      specifiedType: const FullType(String),
    );
    yield r'interactions';
    yield serializers.serialize(
      object.interactions,
      specifiedType: const FullType(BuiltList, [
        FullType(PendingSnapshotInteractionsInner),
      ]),
    );
    yield r'requestId';
    yield serializers.serialize(
      object.requestId,
      specifiedType: const FullType(String),
    );
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(PluginControlClientMessageOneOf1TypeEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PluginControlClientMessageOneOf1 object, {
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
    required PluginControlClientMessageOneOf1Builder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'instanceId':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.instanceId = valueDes;
          break;
        case r'interactions':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(BuiltList, [
                      FullType(PendingSnapshotInteractionsInner),
                    ]),
                  )
                  as BuiltList<PendingSnapshotInteractionsInner>;
          result.interactions.replace(valueDes);
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
                      PluginControlClientMessageOneOf1TypeEnum,
                    ),
                  )
                  as PluginControlClientMessageOneOf1TypeEnum;
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
  PluginControlClientMessageOneOf1 deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PluginControlClientMessageOneOf1Builder();
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

class PluginControlClientMessageOneOf1TypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'pending_snapshot_response')
  static const PluginControlClientMessageOneOf1TypeEnum
  pendingSnapshotResponse =
      _$pluginControlClientMessageOneOf1TypeEnum_pendingSnapshotResponse;

  static Serializer<PluginControlClientMessageOneOf1TypeEnum> get serializer =>
      _$pluginControlClientMessageOneOf1TypeEnumSerializer;

  const PluginControlClientMessageOneOf1TypeEnum._(String name) : super(name);

  static BuiltSet<PluginControlClientMessageOneOf1TypeEnum> get values =>
      _$pluginControlClientMessageOneOf1TypeEnumValues;
  static PluginControlClientMessageOneOf1TypeEnum valueOf(String name) =>
      _$pluginControlClientMessageOneOf1TypeEnumValueOf(name);
}
