//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'command_outcome.g.dart';

/// CommandOutcome
///
/// Properties:
/// * [commandId]
/// * [instanceId]
/// * [kind]
/// * [requestId]
/// * [status]
/// * [updatedAt]
@BuiltValue()
abstract class CommandOutcome
    implements Built<CommandOutcome, CommandOutcomeBuilder> {
  @BuiltValueField(wireName: r'commandId')
  String get commandId;

  @BuiltValueField(wireName: r'instanceId')
  String get instanceId;

  @BuiltValueField(wireName: r'kind')
  CommandOutcomeKindEnum get kind;
  // enum kindEnum {  question,  permission,  };

  @BuiltValueField(wireName: r'requestId')
  String get requestId;

  @BuiltValueField(wireName: r'status')
  CommandOutcomeStatusEnum get status;
  // enum statusEnum {  accepted,  confirmed,  stale,  upstream_error,  result_unknown,  };

  @BuiltValueField(wireName: r'updatedAt')
  DateTime get updatedAt;

  CommandOutcome._();

  factory CommandOutcome([void updates(CommandOutcomeBuilder b)]) =
      _$CommandOutcome;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CommandOutcomeBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CommandOutcome> get serializer =>
      _$CommandOutcomeSerializer();
}

class _$CommandOutcomeSerializer
    implements PrimitiveSerializer<CommandOutcome> {
  @override
  final Iterable<Type> types = const [CommandOutcome, _$CommandOutcome];

  @override
  final String wireName = r'CommandOutcome';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CommandOutcome object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'commandId';
    yield serializers.serialize(
      object.commandId,
      specifiedType: const FullType(String),
    );
    yield r'instanceId';
    yield serializers.serialize(
      object.instanceId,
      specifiedType: const FullType(String),
    );
    yield r'kind';
    yield serializers.serialize(
      object.kind,
      specifiedType: const FullType(CommandOutcomeKindEnum),
    );
    yield r'requestId';
    yield serializers.serialize(
      object.requestId,
      specifiedType: const FullType(String),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(CommandOutcomeStatusEnum),
    );
    yield r'updatedAt';
    yield serializers.serialize(
      object.updatedAt,
      specifiedType: const FullType(DateTime),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CommandOutcome object, {
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
    required CommandOutcomeBuilder result,
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
        case r'instanceId':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.instanceId = valueDes;
          break;
        case r'kind':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(CommandOutcomeKindEnum),
                  )
                  as CommandOutcomeKindEnum;
          result.kind = valueDes;
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
        case r'status':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(CommandOutcomeStatusEnum),
                  )
                  as CommandOutcomeStatusEnum;
          result.status = valueDes;
          break;
        case r'updatedAt':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(DateTime),
                  )
                  as DateTime;
          result.updatedAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CommandOutcome deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CommandOutcomeBuilder();
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

class CommandOutcomeKindEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'question')
  static const CommandOutcomeKindEnum question =
      _$commandOutcomeKindEnum_question;
  @BuiltValueEnumConst(wireName: r'permission')
  static const CommandOutcomeKindEnum permission =
      _$commandOutcomeKindEnum_permission;

  static Serializer<CommandOutcomeKindEnum> get serializer =>
      _$commandOutcomeKindEnumSerializer;

  const CommandOutcomeKindEnum._(String name) : super(name);

  static BuiltSet<CommandOutcomeKindEnum> get values =>
      _$commandOutcomeKindEnumValues;
  static CommandOutcomeKindEnum valueOf(String name) =>
      _$commandOutcomeKindEnumValueOf(name);
}

class CommandOutcomeStatusEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'accepted')
  static const CommandOutcomeStatusEnum accepted =
      _$commandOutcomeStatusEnum_accepted;
  @BuiltValueEnumConst(wireName: r'confirmed')
  static const CommandOutcomeStatusEnum confirmed =
      _$commandOutcomeStatusEnum_confirmed;
  @BuiltValueEnumConst(wireName: r'stale')
  static const CommandOutcomeStatusEnum stale =
      _$commandOutcomeStatusEnum_stale;
  @BuiltValueEnumConst(wireName: r'upstream_error')
  static const CommandOutcomeStatusEnum upstreamError =
      _$commandOutcomeStatusEnum_upstreamError;
  @BuiltValueEnumConst(wireName: r'result_unknown')
  static const CommandOutcomeStatusEnum resultUnknown =
      _$commandOutcomeStatusEnum_resultUnknown;

  static Serializer<CommandOutcomeStatusEnum> get serializer =>
      _$commandOutcomeStatusEnumSerializer;

  const CommandOutcomeStatusEnum._(String name) : super(name);

  static BuiltSet<CommandOutcomeStatusEnum> get values =>
      _$commandOutcomeStatusEnumValues;
  static CommandOutcomeStatusEnum valueOf(String name) =>
      _$commandOutcomeStatusEnumValueOf(name);
}
