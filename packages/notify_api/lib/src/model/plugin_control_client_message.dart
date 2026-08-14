//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:notify_api/src/model/plugin_control_client_message_one_of1.dart';
import 'package:notify_api/src/model/pending_snapshot_interactions_inner.dart';
import 'package:built_collection/built_collection.dart';
import 'package:notify_api/src/model/plugin_control_client_message_one_of.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:one_of/one_of.dart';

part 'plugin_control_client_message.g.dart';

/// PluginControlClientMessage
///
/// Properties:
/// * [directory]
/// * [instanceId]
/// * [machine]
/// * [openCodeVersion]
/// * [project]
/// * [protocolVersion]
/// * [type]
/// * [interactions]
/// * [requestId]
@BuiltValue()
abstract class PluginControlClientMessage
    implements
        Built<PluginControlClientMessage, PluginControlClientMessageBuilder> {
  /// One Of [PluginControlClientMessageOneOf], [PluginControlClientMessageOneOf1]
  OneOf get oneOf;

  PluginControlClientMessage._();

  factory PluginControlClientMessage([
    void updates(PluginControlClientMessageBuilder b),
  ]) = _$PluginControlClientMessage;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PluginControlClientMessageBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PluginControlClientMessage> get serializer =>
      _$PluginControlClientMessageSerializer();
}

class _$PluginControlClientMessageSerializer
    implements PrimitiveSerializer<PluginControlClientMessage> {
  @override
  final Iterable<Type> types = const [
    PluginControlClientMessage,
    _$PluginControlClientMessage,
  ];

  @override
  final String wireName = r'PluginControlClientMessage';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PluginControlClientMessage object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {}

  @override
  Object serialize(
    Serializers serializers,
    PluginControlClientMessage object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final oneOf = object.oneOf;
    return serializers.serialize(
      oneOf.value,
      specifiedType: FullType(oneOf.valueType),
    )!;
  }

  @override
  PluginControlClientMessage deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PluginControlClientMessageBuilder();
    Object? oneOfDataSrc;
    final targetType = const FullType(OneOf, [
      FullType(PluginControlClientMessageOneOf),
      FullType(PluginControlClientMessageOneOf1),
    ]);
    oneOfDataSrc = serialized;
    result.oneOf =
        serializers.deserialize(oneOfDataSrc, specifiedType: targetType)
            as OneOf;
    return result.build();
  }
}

class PluginControlClientMessageTypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'register')
  static const PluginControlClientMessageTypeEnum register =
      _$pluginControlClientMessageTypeEnum_register;
  @BuiltValueEnumConst(wireName: r'pending_snapshot_response')
  static const PluginControlClientMessageTypeEnum pendingSnapshotResponse =
      _$pluginControlClientMessageTypeEnum_pendingSnapshotResponse;

  static Serializer<PluginControlClientMessageTypeEnum> get serializer =>
      _$pluginControlClientMessageTypeEnumSerializer;

  const PluginControlClientMessageTypeEnum._(String name) : super(name);

  static BuiltSet<PluginControlClientMessageTypeEnum> get values =>
      _$pluginControlClientMessageTypeEnumValues;
  static PluginControlClientMessageTypeEnum valueOf(String name) =>
      _$pluginControlClientMessageTypeEnumValueOf(name);
}
