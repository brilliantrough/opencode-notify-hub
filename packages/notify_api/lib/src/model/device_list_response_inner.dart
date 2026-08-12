//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'device_list_response_inner.g.dart';

/// DeviceListResponseInner
///
/// Properties:
/// * [enabled]
/// * [fcmToken]
/// * [id]
/// * [name]
/// * [platform]
/// * [soundEnabled]
@BuiltValue()
abstract class DeviceListResponseInner
    implements Built<DeviceListResponseInner, DeviceListResponseInnerBuilder> {
  @BuiltValueField(wireName: r'enabled')
  bool get enabled;

  @BuiltValueField(wireName: r'fcmToken')
  String? get fcmToken;

  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'platform')
  DeviceListResponseInnerPlatformEnum get platform;
  // enum platformEnum {  windows,  linux,  android,  };

  @BuiltValueField(wireName: r'soundEnabled')
  bool get soundEnabled;

  DeviceListResponseInner._();

  factory DeviceListResponseInner([
    void updates(DeviceListResponseInnerBuilder b),
  ]) = _$DeviceListResponseInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DeviceListResponseInnerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DeviceListResponseInner> get serializer =>
      _$DeviceListResponseInnerSerializer();
}

class _$DeviceListResponseInnerSerializer
    implements PrimitiveSerializer<DeviceListResponseInner> {
  @override
  final Iterable<Type> types = const [
    DeviceListResponseInner,
    _$DeviceListResponseInner,
  ];

  @override
  final String wireName = r'DeviceListResponseInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DeviceListResponseInner object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'enabled';
    yield serializers.serialize(
      object.enabled,
      specifiedType: const FullType(bool),
    );
    if (object.fcmToken != null) {
      yield r'fcmToken';
      yield serializers.serialize(
        object.fcmToken,
        specifiedType: const FullType(String),
      );
    }
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
    yield r'platform';
    yield serializers.serialize(
      object.platform,
      specifiedType: const FullType(DeviceListResponseInnerPlatformEnum),
    );
    yield r'soundEnabled';
    yield serializers.serialize(
      object.soundEnabled,
      specifiedType: const FullType(bool),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DeviceListResponseInner object, {
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
    required DeviceListResponseInnerBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'enabled':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(bool),
                  )
                  as bool;
          result.enabled = valueDes;
          break;
        case r'fcmToken':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.fcmToken = valueDes;
          break;
        case r'id':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.id = valueDes;
          break;
        case r'name':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.name = valueDes;
          break;
        case r'platform':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      DeviceListResponseInnerPlatformEnum,
                    ),
                  )
                  as DeviceListResponseInnerPlatformEnum;
          result.platform = valueDes;
          break;
        case r'soundEnabled':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(bool),
                  )
                  as bool;
          result.soundEnabled = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DeviceListResponseInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DeviceListResponseInnerBuilder();
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

class DeviceListResponseInnerPlatformEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'windows')
  static const DeviceListResponseInnerPlatformEnum windows =
      _$deviceListResponseInnerPlatformEnum_windows;
  @BuiltValueEnumConst(wireName: r'linux')
  static const DeviceListResponseInnerPlatformEnum linux =
      _$deviceListResponseInnerPlatformEnum_linux;
  @BuiltValueEnumConst(wireName: r'android')
  static const DeviceListResponseInnerPlatformEnum android =
      _$deviceListResponseInnerPlatformEnum_android;

  static Serializer<DeviceListResponseInnerPlatformEnum> get serializer =>
      _$deviceListResponseInnerPlatformEnumSerializer;

  const DeviceListResponseInnerPlatformEnum._(String name) : super(name);

  static BuiltSet<DeviceListResponseInnerPlatformEnum> get values =>
      _$deviceListResponseInnerPlatformEnumValues;
  static DeviceListResponseInnerPlatformEnum valueOf(String name) =>
      _$deviceListResponseInnerPlatformEnumValueOf(name);
}
