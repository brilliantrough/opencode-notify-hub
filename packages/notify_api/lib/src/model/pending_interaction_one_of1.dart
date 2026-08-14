//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:notify_api/src/model/pending_interaction_one_of_tool.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'pending_interaction_one_of1.g.dart';

/// PendingInteractionOneOf1
///
/// Properties:
/// * [always]
/// * [directory]
/// * [instanceId]
/// * [kind]
/// * [machine]
/// * [metadata]
/// * [occurredAt]
/// * [patterns]
/// * [permission]
/// * [project]
/// * [requestId]
/// * [sessionId]
/// * [sessionTitle]
/// * [tool]
@BuiltValue()
abstract class PendingInteractionOneOf1
    implements
        Built<PendingInteractionOneOf1, PendingInteractionOneOf1Builder> {
  @BuiltValueField(wireName: r'always')
  BuiltList<String> get always;

  @BuiltValueField(wireName: r'directory')
  String get directory;

  @BuiltValueField(wireName: r'instanceId')
  String get instanceId;

  @BuiltValueField(wireName: r'kind')
  PendingInteractionOneOf1KindEnum get kind;
  // enum kindEnum {  permission,  };

  @BuiltValueField(wireName: r'machine')
  String get machine;

  @BuiltValueField(wireName: r'metadata')
  JsonObject get metadata;

  @BuiltValueField(wireName: r'occurredAt')
  DateTime get occurredAt;

  @BuiltValueField(wireName: r'patterns')
  BuiltList<String> get patterns;

  @BuiltValueField(wireName: r'permission')
  String get permission;

  @BuiltValueField(wireName: r'project')
  String get project;

  @BuiltValueField(wireName: r'requestId')
  String get requestId;

  @BuiltValueField(wireName: r'sessionId')
  String get sessionId;

  @BuiltValueField(wireName: r'sessionTitle')
  String get sessionTitle;

  @BuiltValueField(wireName: r'tool')
  PendingInteractionOneOfTool? get tool;

  PendingInteractionOneOf1._();

  factory PendingInteractionOneOf1([
    void updates(PendingInteractionOneOf1Builder b),
  ]) = _$PendingInteractionOneOf1;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PendingInteractionOneOf1Builder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PendingInteractionOneOf1> get serializer =>
      _$PendingInteractionOneOf1Serializer();
}

class _$PendingInteractionOneOf1Serializer
    implements PrimitiveSerializer<PendingInteractionOneOf1> {
  @override
  final Iterable<Type> types = const [
    PendingInteractionOneOf1,
    _$PendingInteractionOneOf1,
  ];

  @override
  final String wireName = r'PendingInteractionOneOf1';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PendingInteractionOneOf1 object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'always';
    yield serializers.serialize(
      object.always,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
    yield r'directory';
    yield serializers.serialize(
      object.directory,
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
      specifiedType: const FullType(PendingInteractionOneOf1KindEnum),
    );
    yield r'machine';
    yield serializers.serialize(
      object.machine,
      specifiedType: const FullType(String),
    );
    yield r'metadata';
    yield serializers.serialize(
      object.metadata,
      specifiedType: const FullType(JsonObject),
    );
    yield r'occurredAt';
    yield serializers.serialize(
      object.occurredAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'patterns';
    yield serializers.serialize(
      object.patterns,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
    yield r'permission';
    yield serializers.serialize(
      object.permission,
      specifiedType: const FullType(String),
    );
    yield r'project';
    yield serializers.serialize(
      object.project,
      specifiedType: const FullType(String),
    );
    yield r'requestId';
    yield serializers.serialize(
      object.requestId,
      specifiedType: const FullType(String),
    );
    yield r'sessionId';
    yield serializers.serialize(
      object.sessionId,
      specifiedType: const FullType(String),
    );
    yield r'sessionTitle';
    yield serializers.serialize(
      object.sessionTitle,
      specifiedType: const FullType(String),
    );
    if (object.tool != null) {
      yield r'tool';
      yield serializers.serialize(
        object.tool,
        specifiedType: const FullType(PendingInteractionOneOfTool),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    PendingInteractionOneOf1 object, {
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
    required PendingInteractionOneOf1Builder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'always':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(BuiltList, [
                      FullType(String),
                    ]),
                  )
                  as BuiltList<String>;
          result.always.replace(valueDes);
          break;
        case r'directory':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.directory = valueDes;
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
                    specifiedType: const FullType(
                      PendingInteractionOneOf1KindEnum,
                    ),
                  )
                  as PendingInteractionOneOf1KindEnum;
          result.kind = valueDes;
          break;
        case r'machine':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.machine = valueDes;
          break;
        case r'metadata':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(JsonObject),
                  )
                  as JsonObject;
          result.metadata = valueDes;
          break;
        case r'occurredAt':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(DateTime),
                  )
                  as DateTime;
          result.occurredAt = valueDes;
          break;
        case r'patterns':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(BuiltList, [
                      FullType(String),
                    ]),
                  )
                  as BuiltList<String>;
          result.patterns.replace(valueDes);
          break;
        case r'permission':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.permission = valueDes;
          break;
        case r'project':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.project = valueDes;
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
        case r'sessionId':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.sessionId = valueDes;
          break;
        case r'sessionTitle':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.sessionTitle = valueDes;
          break;
        case r'tool':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(PendingInteractionOneOfTool),
                  )
                  as PendingInteractionOneOfTool;
          result.tool.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PendingInteractionOneOf1 deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PendingInteractionOneOf1Builder();
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

class PendingInteractionOneOf1KindEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'permission')
  static const PendingInteractionOneOf1KindEnum permission =
      _$pendingInteractionOneOf1KindEnum_permission;

  static Serializer<PendingInteractionOneOf1KindEnum> get serializer =>
      _$pendingInteractionOneOf1KindEnumSerializer;

  const PendingInteractionOneOf1KindEnum._(String name) : super(name);

  static BuiltSet<PendingInteractionOneOf1KindEnum> get values =>
      _$pendingInteractionOneOf1KindEnumValues;
  static PendingInteractionOneOf1KindEnum valueOf(String name) =>
      _$pendingInteractionOneOf1KindEnumValueOf(name);
}
