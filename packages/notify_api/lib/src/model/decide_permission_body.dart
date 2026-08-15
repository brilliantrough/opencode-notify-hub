//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'decide_permission_body.g.dart';

/// DecidePermissionBody
///
/// Properties:
/// * [commandId]
/// * [decision]
@BuiltValue()
abstract class DecidePermissionBody
    implements Built<DecidePermissionBody, DecidePermissionBodyBuilder> {
  @BuiltValueField(wireName: r'commandId')
  String get commandId;

  @BuiltValueField(wireName: r'decision')
  DecidePermissionBodyDecisionEnum get decision;
  // enum decisionEnum {  once,  reject,  always,  };

  DecidePermissionBody._();

  factory DecidePermissionBody([void updates(DecidePermissionBodyBuilder b)]) =
      _$DecidePermissionBody;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DecidePermissionBodyBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DecidePermissionBody> get serializer =>
      _$DecidePermissionBodySerializer();
}

class _$DecidePermissionBodySerializer
    implements PrimitiveSerializer<DecidePermissionBody> {
  @override
  final Iterable<Type> types = const [
    DecidePermissionBody,
    _$DecidePermissionBody,
  ];

  @override
  final String wireName = r'DecidePermissionBody';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DecidePermissionBody object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'commandId';
    yield serializers.serialize(
      object.commandId,
      specifiedType: const FullType(String),
    );
    yield r'decision';
    yield serializers.serialize(
      object.decision,
      specifiedType: const FullType(DecidePermissionBodyDecisionEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DecidePermissionBody object, {
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
    required DecidePermissionBodyBuilder result,
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
        case r'decision':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      DecidePermissionBodyDecisionEnum,
                    ),
                  )
                  as DecidePermissionBodyDecisionEnum;
          result.decision = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DecidePermissionBody deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DecidePermissionBodyBuilder();
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

class DecidePermissionBodyDecisionEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'once')
  static const DecidePermissionBodyDecisionEnum once =
      _$decidePermissionBodyDecisionEnum_once;
  @BuiltValueEnumConst(wireName: r'reject')
  static const DecidePermissionBodyDecisionEnum reject =
      _$decidePermissionBodyDecisionEnum_reject;
  @BuiltValueEnumConst(wireName: r'always')
  static const DecidePermissionBodyDecisionEnum always =
      _$decidePermissionBodyDecisionEnum_always;

  static Serializer<DecidePermissionBodyDecisionEnum> get serializer =>
      _$decidePermissionBodyDecisionEnumSerializer;

  const DecidePermissionBodyDecisionEnum._(String name) : super(name);

  static BuiltSet<DecidePermissionBodyDecisionEnum> get values =>
      _$decidePermissionBodyDecisionEnumValues;
  static DecidePermissionBodyDecisionEnum valueOf(String name) =>
      _$decidePermissionBodyDecisionEnumValueOf(name);
}
