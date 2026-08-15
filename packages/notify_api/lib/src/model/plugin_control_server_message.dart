//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:notify_api/src/model/plugin_control_server_message_one_of2.dart';
import 'package:built_collection/built_collection.dart';
import 'package:notify_api/src/model/plugin_control_server_message_one_of.dart';
import 'package:notify_api/src/model/plugin_control_server_message_one_of1.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:one_of/one_of.dart';

part 'plugin_control_server_message.g.dart';

/// PluginControlServerMessage
///
/// Properties:
/// * [instanceId]
/// * [state]
/// * [type]
/// * [requestId]
/// * [answers]
/// * [commandId]
@BuiltValue()
abstract class PluginControlServerMessage
    implements
        Built<PluginControlServerMessage, PluginControlServerMessageBuilder> {
  /// One Of [PluginControlServerMessageOneOf], [PluginControlServerMessageOneOf1], [PluginControlServerMessageOneOf2]
  OneOf get oneOf;

  PluginControlServerMessage._();

  factory PluginControlServerMessage([
    void updates(PluginControlServerMessageBuilder b),
  ]) = _$PluginControlServerMessage;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PluginControlServerMessageBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PluginControlServerMessage> get serializer =>
      _$PluginControlServerMessageSerializer();
}

class _$PluginControlServerMessageSerializer
    implements PrimitiveSerializer<PluginControlServerMessage> {
  @override
  final Iterable<Type> types = const [
    PluginControlServerMessage,
    _$PluginControlServerMessage,
  ];

  @override
  final String wireName = r'PluginControlServerMessage';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PluginControlServerMessage object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {}

  @override
  Object serialize(
    Serializers serializers,
    PluginControlServerMessage object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final oneOf = object.oneOf;
    return serializers.serialize(
      oneOf.value,
      specifiedType: FullType(oneOf.valueType),
    )!;
  }

  @override
  PluginControlServerMessage deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PluginControlServerMessageBuilder();
    Object? oneOfDataSrc;
    final targetType = const FullType(OneOf, [
      FullType(PluginControlServerMessageOneOf),
      FullType(PluginControlServerMessageOneOf1),
      FullType(PluginControlServerMessageOneOf2),
    ]);
    oneOfDataSrc = serialized;
    result.oneOf =
        serializers.deserialize(oneOfDataSrc, specifiedType: targetType)
            as OneOf;
    return result.build();
  }
}

class PluginControlServerMessageStateEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'controllable')
  static const PluginControlServerMessageStateEnum controllable =
      _$pluginControlServerMessageStateEnum_controllable;
  @BuiltValueEnumConst(wireName: r'conflicting')
  static const PluginControlServerMessageStateEnum conflicting =
      _$pluginControlServerMessageStateEnum_conflicting;
  @BuiltValueEnumConst(wireName: r'incompatible')
  static const PluginControlServerMessageStateEnum incompatible =
      _$pluginControlServerMessageStateEnum_incompatible;

  static Serializer<PluginControlServerMessageStateEnum> get serializer =>
      _$pluginControlServerMessageStateEnumSerializer;

  const PluginControlServerMessageStateEnum._(String name) : super(name);

  static BuiltSet<PluginControlServerMessageStateEnum> get values =>
      _$pluginControlServerMessageStateEnumValues;
  static PluginControlServerMessageStateEnum valueOf(String name) =>
      _$pluginControlServerMessageStateEnumValueOf(name);
}

class PluginControlServerMessageTypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'registration')
  static const PluginControlServerMessageTypeEnum registration =
      _$pluginControlServerMessageTypeEnum_registration;
  @BuiltValueEnumConst(wireName: r'pending_snapshot_request')
  static const PluginControlServerMessageTypeEnum pendingSnapshotRequest =
      _$pluginControlServerMessageTypeEnum_pendingSnapshotRequest;
  @BuiltValueEnumConst(wireName: r'question_answer_command')
  static const PluginControlServerMessageTypeEnum questionAnswerCommand =
      _$pluginControlServerMessageTypeEnum_questionAnswerCommand;

  static Serializer<PluginControlServerMessageTypeEnum> get serializer =>
      _$pluginControlServerMessageTypeEnumSerializer;

  const PluginControlServerMessageTypeEnum._(String name) : super(name);

  static BuiltSet<PluginControlServerMessageTypeEnum> get values =>
      _$pluginControlServerMessageTypeEnumValues;
  static PluginControlServerMessageTypeEnum valueOf(String name) =>
      _$pluginControlServerMessageTypeEnumValueOf(name);
}
