//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'ws_server_message_one_of1_instances_inner.g.dart';

/// WsServerMessageOneOf1InstancesInner
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
abstract class WsServerMessageOneOf1InstancesInner
    implements
        Built<
          WsServerMessageOneOf1InstancesInner,
          WsServerMessageOneOf1InstancesInnerBuilder
        > {
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
  WsServerMessageOneOf1InstancesInnerStateEnum get state;
  // enum stateEnum {  controllable,  conflicting,  incompatible,  offline,  };

  WsServerMessageOneOf1InstancesInner._();

  factory WsServerMessageOneOf1InstancesInner([
    void updates(WsServerMessageOneOf1InstancesInnerBuilder b),
  ]) = _$WsServerMessageOneOf1InstancesInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(WsServerMessageOneOf1InstancesInnerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<WsServerMessageOneOf1InstancesInner> get serializer =>
      _$WsServerMessageOneOf1InstancesInnerSerializer();
}

class _$WsServerMessageOneOf1InstancesInnerSerializer
    implements PrimitiveSerializer<WsServerMessageOneOf1InstancesInner> {
  @override
  final Iterable<Type> types = const [
    WsServerMessageOneOf1InstancesInner,
    _$WsServerMessageOneOf1InstancesInner,
  ];

  @override
  final String wireName = r'WsServerMessageOneOf1InstancesInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    WsServerMessageOneOf1InstancesInner object, {
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
      specifiedType: const FullType(
        WsServerMessageOneOf1InstancesInnerStateEnum,
      ),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    WsServerMessageOneOf1InstancesInner object, {
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
    required WsServerMessageOneOf1InstancesInnerBuilder result,
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
                    specifiedType: const FullType(
                      WsServerMessageOneOf1InstancesInnerStateEnum,
                    ),
                  )
                  as WsServerMessageOneOf1InstancesInnerStateEnum;
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
  WsServerMessageOneOf1InstancesInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = WsServerMessageOneOf1InstancesInnerBuilder();
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

class WsServerMessageOneOf1InstancesInnerStateEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'controllable')
  static const WsServerMessageOneOf1InstancesInnerStateEnum controllable =
      _$wsServerMessageOneOf1InstancesInnerStateEnum_controllable;
  @BuiltValueEnumConst(wireName: r'conflicting')
  static const WsServerMessageOneOf1InstancesInnerStateEnum conflicting =
      _$wsServerMessageOneOf1InstancesInnerStateEnum_conflicting;
  @BuiltValueEnumConst(wireName: r'incompatible')
  static const WsServerMessageOneOf1InstancesInnerStateEnum incompatible =
      _$wsServerMessageOneOf1InstancesInnerStateEnum_incompatible;
  @BuiltValueEnumConst(wireName: r'offline')
  static const WsServerMessageOneOf1InstancesInnerStateEnum offline =
      _$wsServerMessageOneOf1InstancesInnerStateEnum_offline;

  static Serializer<WsServerMessageOneOf1InstancesInnerStateEnum>
  get serializer => _$wsServerMessageOneOf1InstancesInnerStateEnumSerializer;

  const WsServerMessageOneOf1InstancesInnerStateEnum._(String name)
    : super(name);

  static BuiltSet<WsServerMessageOneOf1InstancesInnerStateEnum> get values =>
      _$wsServerMessageOneOf1InstancesInnerStateEnumValues;
  static WsServerMessageOneOf1InstancesInnerStateEnum valueOf(String name) =>
      _$wsServerMessageOneOf1InstancesInnerStateEnumValueOf(name);
}
