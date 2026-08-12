//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'register_device_body.g.dart';

/// RegisterDeviceBody
///
/// Properties:
/// * [enabled]
/// * [fcmToken]
/// * [name]
/// * [platform]
/// * [soundEnabled]
@BuiltValue()
abstract class RegisterDeviceBody
    implements Built<RegisterDeviceBody, RegisterDeviceBodyBuilder> {
  @BuiltValueField(wireName: r'enabled')
  bool? get enabled;

  @BuiltValueField(wireName: r'fcmToken')
  String? get fcmToken;

  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'platform')
  RegisterDeviceBodyPlatformEnum get platform;
  // enum platformEnum {  windows,  linux,  android,  };

  @BuiltValueField(wireName: r'soundEnabled')
  bool? get soundEnabled;

  RegisterDeviceBody._();

  factory RegisterDeviceBody([void updates(RegisterDeviceBodyBuilder b)]) =
      _$RegisterDeviceBody;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RegisterDeviceBodyBuilder b) => b
    ..enabled = true
    ..soundEnabled = true;

  @BuiltValueSerializer(custom: true)
  static Serializer<RegisterDeviceBody> get serializer =>
      _$RegisterDeviceBodySerializer();
}

class _$RegisterDeviceBodySerializer
    implements PrimitiveSerializer<RegisterDeviceBody> {
  @override
  final Iterable<Type> types = const [RegisterDeviceBody, _$RegisterDeviceBody];

  @override
  final String wireName = r'RegisterDeviceBody';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RegisterDeviceBody object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.enabled != null) {
      yield r'enabled';
      yield serializers.serialize(
        object.enabled,
        specifiedType: const FullType(bool),
      );
    }
    if (object.fcmToken != null) {
      yield r'fcmToken';
      yield serializers.serialize(
        object.fcmToken,
        specifiedType: const FullType(String),
      );
    }
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
    yield r'platform';
    yield serializers.serialize(
      object.platform,
      specifiedType: const FullType(RegisterDeviceBodyPlatformEnum),
    );
    if (object.soundEnabled != null) {
      yield r'soundEnabled';
      yield serializers.serialize(
        object.soundEnabled,
        specifiedType: const FullType(bool),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    RegisterDeviceBody object, {
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
    required RegisterDeviceBodyBuilder result,
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
                      RegisterDeviceBodyPlatformEnum,
                    ),
                  )
                  as RegisterDeviceBodyPlatformEnum;
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
  RegisterDeviceBody deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RegisterDeviceBodyBuilder();
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

class RegisterDeviceBodyPlatformEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'windows')
  static const RegisterDeviceBodyPlatformEnum windows =
      _$registerDeviceBodyPlatformEnum_windows;
  @BuiltValueEnumConst(wireName: r'linux')
  static const RegisterDeviceBodyPlatformEnum linux =
      _$registerDeviceBodyPlatformEnum_linux;
  @BuiltValueEnumConst(wireName: r'android')
  static const RegisterDeviceBodyPlatformEnum android =
      _$registerDeviceBodyPlatformEnum_android;

  static Serializer<RegisterDeviceBodyPlatformEnum> get serializer =>
      _$registerDeviceBodyPlatformEnumSerializer;

  const RegisterDeviceBodyPlatformEnum._(String name) : super(name);

  static BuiltSet<RegisterDeviceBodyPlatformEnum> get values =>
      _$registerDeviceBodyPlatformEnumValues;
  static RegisterDeviceBodyPlatformEnum valueOf(String name) =>
      _$registerDeviceBodyPlatformEnumValueOf(name);
}
