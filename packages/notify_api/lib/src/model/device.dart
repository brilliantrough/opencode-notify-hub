//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'device.g.dart';

/// Device
///
/// Properties:
/// * [enabled]
/// * [fcmToken]
/// * [id]
/// * [name]
/// * [platform]
/// * [soundEnabled]
@BuiltValue()
abstract class Device implements Built<Device, DeviceBuilder> {
  @BuiltValueField(wireName: r'enabled')
  bool get enabled;

  @BuiltValueField(wireName: r'fcmToken')
  String? get fcmToken;

  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'platform')
  DevicePlatformEnum get platform;
  // enum platformEnum {  windows,  linux,  android,  };

  @BuiltValueField(wireName: r'soundEnabled')
  bool get soundEnabled;

  Device._();

  factory Device([void updates(DeviceBuilder b)]) = _$Device;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DeviceBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Device> get serializer => _$DeviceSerializer();
}

class _$DeviceSerializer implements PrimitiveSerializer<Device> {
  @override
  final Iterable<Type> types = const [Device, _$Device];

  @override
  final String wireName = r'Device';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Device object, {
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
      specifiedType: const FullType(DevicePlatformEnum),
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
    Device object, {
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
    required DeviceBuilder result,
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
                    specifiedType: const FullType(DevicePlatformEnum),
                  )
                  as DevicePlatformEnum;
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
  Device deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DeviceBuilder();
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

class DevicePlatformEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'windows')
  static const DevicePlatformEnum windows = _$devicePlatformEnum_windows;
  @BuiltValueEnumConst(wireName: r'linux')
  static const DevicePlatformEnum linux = _$devicePlatformEnum_linux;
  @BuiltValueEnumConst(wireName: r'android')
  static const DevicePlatformEnum android = _$devicePlatformEnum_android;

  static Serializer<DevicePlatformEnum> get serializer =>
      _$devicePlatformEnumSerializer;

  const DevicePlatformEnum._(String name) : super(name);

  static BuiltSet<DevicePlatformEnum> get values => _$devicePlatformEnumValues;
  static DevicePlatformEnum valueOf(String name) =>
      _$devicePlatformEnumValueOf(name);
}
