//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:notify_api/src/model/plugin_control_client_message_one_of1.dart';
import 'package:notify_api/src/model/pending_snapshot_interactions_inner.dart';
import 'package:notify_api/src/model/plugin_control_client_message_one_of2.dart';
import 'package:built_collection/built_collection.dart';
import 'package:notify_api/src/model/plugin_control_client_message_one_of.dart';
import 'package:notify_api/src/model/plugin_control_client_message_one_of3.dart';
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
/// * [commandId]
/// * [status]
@BuiltValue()
abstract class PluginControlClientMessage
    implements
        Built<PluginControlClientMessage, PluginControlClientMessageBuilder> {
  /// One Of [PluginControlClientMessageOneOf], [PluginControlClientMessageOneOf1], [PluginControlClientMessageOneOf2], [PluginControlClientMessageOneOf3]
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
      FullType(PluginControlClientMessageOneOf2),
      FullType(PluginControlClientMessageOneOf3),
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
  @BuiltValueEnumConst(wireName: r'question_answer_result')
  static const PluginControlClientMessageTypeEnum questionAnswerResult =
      _$pluginControlClientMessageTypeEnum_questionAnswerResult;
  @BuiltValueEnumConst(wireName: r'permission_decide_result')
  static const PluginControlClientMessageTypeEnum permissionDecideResult =
      _$pluginControlClientMessageTypeEnum_permissionDecideResult;

  static Serializer<PluginControlClientMessageTypeEnum> get serializer =>
      _$pluginControlClientMessageTypeEnumSerializer;

  const PluginControlClientMessageTypeEnum._(String name) : super(name);

  static BuiltSet<PluginControlClientMessageTypeEnum> get values =>
      _$pluginControlClientMessageTypeEnumValues;
  static PluginControlClientMessageTypeEnum valueOf(String name) =>
      _$pluginControlClientMessageTypeEnumValueOf(name);
}

class PluginControlClientMessageStatusEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'confirmed')
  static const PluginControlClientMessageStatusEnum confirmed =
      _$pluginControlClientMessageStatusEnum_confirmed;
  @BuiltValueEnumConst(wireName: r'stale')
  static const PluginControlClientMessageStatusEnum stale =
      _$pluginControlClientMessageStatusEnum_stale;
  @BuiltValueEnumConst(wireName: r'upstream_error')
  static const PluginControlClientMessageStatusEnum upstreamError =
      _$pluginControlClientMessageStatusEnum_upstreamError;
  @BuiltValueEnumConst(wireName: r'result_unknown')
  static const PluginControlClientMessageStatusEnum resultUnknown =
      _$pluginControlClientMessageStatusEnum_resultUnknown;

  static Serializer<PluginControlClientMessageStatusEnum> get serializer =>
      _$pluginControlClientMessageStatusEnumSerializer;

  const PluginControlClientMessageStatusEnum._(String name) : super(name);

  static BuiltSet<PluginControlClientMessageStatusEnum> get values =>
      _$pluginControlClientMessageStatusEnumValues;
  static PluginControlClientMessageStatusEnum valueOf(String name) =>
      _$pluginControlClientMessageStatusEnumValueOf(name);
}
