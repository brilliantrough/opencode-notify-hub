//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'command_accepted.g.dart';

/// CommandAccepted
///
/// Properties:
/// * [commandId]
/// * [status]
@BuiltValue()
abstract class CommandAccepted
    implements Built<CommandAccepted, CommandAcceptedBuilder> {
  @BuiltValueField(wireName: r'commandId')
  String get commandId;

  @BuiltValueField(wireName: r'status')
  CommandAcceptedStatusEnum get status;
  // enum statusEnum {  accepted,  };

  CommandAccepted._();

  factory CommandAccepted([void updates(CommandAcceptedBuilder b)]) =
      _$CommandAccepted;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CommandAcceptedBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CommandAccepted> get serializer =>
      _$CommandAcceptedSerializer();
}

class _$CommandAcceptedSerializer
    implements PrimitiveSerializer<CommandAccepted> {
  @override
  final Iterable<Type> types = const [CommandAccepted, _$CommandAccepted];

  @override
  final String wireName = r'CommandAccepted';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CommandAccepted object, {
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
      specifiedType: const FullType(CommandAcceptedStatusEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CommandAccepted object, {
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
    required CommandAcceptedBuilder result,
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
                    specifiedType: const FullType(CommandAcceptedStatusEnum),
                  )
                  as CommandAcceptedStatusEnum;
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
  CommandAccepted deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CommandAcceptedBuilder();
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

class CommandAcceptedStatusEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'accepted')
  static const CommandAcceptedStatusEnum accepted =
      _$commandAcceptedStatusEnum_accepted;

  static Serializer<CommandAcceptedStatusEnum> get serializer =>
      _$commandAcceptedStatusEnumSerializer;

  const CommandAcceptedStatusEnum._(String name) : super(name);

  static BuiltSet<CommandAcceptedStatusEnum> get values =>
      _$commandAcceptedStatusEnumValues;
  static CommandAcceptedStatusEnum valueOf(String name) =>
      _$commandAcceptedStatusEnumValueOf(name);
}
