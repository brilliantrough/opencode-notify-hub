//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'plugin_control_server_message_one_of2.g.dart';

/// PluginControlServerMessageOneOf2
///
/// Properties:
/// * [answers]
/// * [commandId]
/// * [requestId]
/// * [sessionID]
/// * [type]
@BuiltValue()
abstract class PluginControlServerMessageOneOf2
    implements
        Built<
          PluginControlServerMessageOneOf2,
          PluginControlServerMessageOneOf2Builder
        > {
  @BuiltValueField(wireName: r'answers')
  BuiltList<BuiltList<String>> get answers;

  @BuiltValueField(wireName: r'commandId')
  String get commandId;

  @BuiltValueField(wireName: r'requestId')
  String get requestId;

  @BuiltValueField(wireName: r'sessionID')
  String get sessionID;

  @BuiltValueField(wireName: r'type')
  PluginControlServerMessageOneOf2TypeEnum get type;
  // enum typeEnum {  question_answer_command,  };

  PluginControlServerMessageOneOf2._();

  factory PluginControlServerMessageOneOf2([
    void updates(PluginControlServerMessageOneOf2Builder b),
  ]) = _$PluginControlServerMessageOneOf2;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PluginControlServerMessageOneOf2Builder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PluginControlServerMessageOneOf2> get serializer =>
      _$PluginControlServerMessageOneOf2Serializer();
}

class _$PluginControlServerMessageOneOf2Serializer
    implements PrimitiveSerializer<PluginControlServerMessageOneOf2> {
  @override
  final Iterable<Type> types = const [
    PluginControlServerMessageOneOf2,
    _$PluginControlServerMessageOneOf2,
  ];

  @override
  final String wireName = r'PluginControlServerMessageOneOf2';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PluginControlServerMessageOneOf2 object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'answers';
    yield serializers.serialize(
      object.answers,
      specifiedType: const FullType(BuiltList, [
        FullType(BuiltList, [FullType(String)]),
      ]),
    );
    yield r'commandId';
    yield serializers.serialize(
      object.commandId,
      specifiedType: const FullType(String),
    );
    yield r'requestId';
    yield serializers.serialize(
      object.requestId,
      specifiedType: const FullType(String),
    );
    yield r'sessionID';
    yield serializers.serialize(
      object.sessionID,
      specifiedType: const FullType(String),
    );
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(PluginControlServerMessageOneOf2TypeEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PluginControlServerMessageOneOf2 object, {
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
    required PluginControlServerMessageOneOf2Builder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'answers':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(BuiltList, [
                      FullType(BuiltList, [FullType(String)]),
                    ]),
                  )
                  as BuiltList<BuiltList<String>>;
          result.answers.replace(valueDes);
          break;
        case r'commandId':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.commandId = valueDes;
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
        case r'sessionID':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.sessionID = valueDes;
          break;
        case r'type':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      PluginControlServerMessageOneOf2TypeEnum,
                    ),
                  )
                  as PluginControlServerMessageOneOf2TypeEnum;
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
  PluginControlServerMessageOneOf2 deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PluginControlServerMessageOneOf2Builder();
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

class PluginControlServerMessageOneOf2TypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'question_answer_command')
  static const PluginControlServerMessageOneOf2TypeEnum questionAnswerCommand =
      _$pluginControlServerMessageOneOf2TypeEnum_questionAnswerCommand;

  static Serializer<PluginControlServerMessageOneOf2TypeEnum> get serializer =>
      _$pluginControlServerMessageOneOf2TypeEnumSerializer;

  const PluginControlServerMessageOneOf2TypeEnum._(String name) : super(name);

  static BuiltSet<PluginControlServerMessageOneOf2TypeEnum> get values =>
      _$pluginControlServerMessageOneOf2TypeEnumValues;
  static PluginControlServerMessageOneOf2TypeEnum valueOf(String name) =>
      _$pluginControlServerMessageOneOf2TypeEnumValueOf(name);
}
