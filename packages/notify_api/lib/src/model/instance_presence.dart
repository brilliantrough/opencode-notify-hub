//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'instance_presence.g.dart';

/// InstancePresence
///
/// Properties:
/// * [directory]
/// * [instanceId]
/// * [lastSeenAt]
/// * [machine]
/// * [openCodeVersion]
/// * [project]
/// * [protocolVersion]
/// * [state]
@BuiltValue()
abstract class InstancePresence
    implements Built<InstancePresence, InstancePresenceBuilder> {
  @BuiltValueField(wireName: r'directory')
  String get directory;

  @BuiltValueField(wireName: r'instanceId')
  String get instanceId;

  @BuiltValueField(wireName: r'lastSeenAt')
  DateTime get lastSeenAt;

  @BuiltValueField(wireName: r'machine')
  String get machine;

  @BuiltValueField(wireName: r'openCodeVersion')
  String get openCodeVersion;

  @BuiltValueField(wireName: r'project')
  String get project;

  @BuiltValueField(wireName: r'protocolVersion')
  int get protocolVersion;

  @BuiltValueField(wireName: r'state')
  InstancePresenceStateEnum get state;
  // enum stateEnum {  controllable,  conflicting,  incompatible,  offline,  };

  InstancePresence._();

  factory InstancePresence([void updates(InstancePresenceBuilder b)]) =
      _$InstancePresence;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(InstancePresenceBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<InstancePresence> get serializer =>
      _$InstancePresenceSerializer();
}

class _$InstancePresenceSerializer
    implements PrimitiveSerializer<InstancePresence> {
  @override
  final Iterable<Type> types = const [InstancePresence, _$InstancePresence];

  @override
  final String wireName = r'InstancePresence';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    InstancePresence object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
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
    yield r'lastSeenAt';
    yield serializers.serialize(
      object.lastSeenAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'machine';
    yield serializers.serialize(
      object.machine,
      specifiedType: const FullType(String),
    );
    yield r'openCodeVersion';
    yield serializers.serialize(
      object.openCodeVersion,
      specifiedType: const FullType(String),
    );
    yield r'project';
    yield serializers.serialize(
      object.project,
      specifiedType: const FullType(String),
    );
    yield r'protocolVersion';
    yield serializers.serialize(
      object.protocolVersion,
      specifiedType: const FullType(int),
    );
    yield r'state';
    yield serializers.serialize(
      object.state,
      specifiedType: const FullType(InstancePresenceStateEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    InstancePresence object, {
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
    required InstancePresenceBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
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
        case r'lastSeenAt':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(DateTime),
                  )
                  as DateTime;
          result.lastSeenAt = valueDes;
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
        case r'openCodeVersion':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.openCodeVersion = valueDes;
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
        case r'protocolVersion':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(int))
                  as int;
          result.protocolVersion = valueDes;
          break;
        case r'state':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(InstancePresenceStateEnum),
                  )
                  as InstancePresenceStateEnum;
          result.state = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  InstancePresence deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = InstancePresenceBuilder();
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

class InstancePresenceStateEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'controllable')
  static const InstancePresenceStateEnum controllable =
      _$instancePresenceStateEnum_controllable;
  @BuiltValueEnumConst(wireName: r'conflicting')
  static const InstancePresenceStateEnum conflicting =
      _$instancePresenceStateEnum_conflicting;
  @BuiltValueEnumConst(wireName: r'incompatible')
  static const InstancePresenceStateEnum incompatible =
      _$instancePresenceStateEnum_incompatible;
  @BuiltValueEnumConst(wireName: r'offline')
  static const InstancePresenceStateEnum offline =
      _$instancePresenceStateEnum_offline;

  static Serializer<InstancePresenceStateEnum> get serializer =>
      _$instancePresenceStateEnumSerializer;

  const InstancePresenceStateEnum._(String name) : super(name);

  static BuiltSet<InstancePresenceStateEnum> get values =>
      _$instancePresenceStateEnumValues;
  static InstancePresenceStateEnum valueOf(String name) =>
      _$instancePresenceStateEnumValueOf(name);
}
