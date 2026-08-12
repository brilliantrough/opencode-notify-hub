//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'patch_device_body.g.dart';

/// PatchDeviceBody
///
/// Properties:
/// * [enabled]
/// * [fcmToken]
/// * [name]
/// * [soundEnabled]
@BuiltValue()
abstract class PatchDeviceBody
    implements Built<PatchDeviceBody, PatchDeviceBodyBuilder> {
  @BuiltValueField(wireName: r'enabled')
  bool? get enabled;

  @BuiltValueField(wireName: r'fcmToken')
  String? get fcmToken;

  @BuiltValueField(wireName: r'name')
  String? get name;

  @BuiltValueField(wireName: r'soundEnabled')
  bool? get soundEnabled;

  PatchDeviceBody._();

  factory PatchDeviceBody([void updates(PatchDeviceBodyBuilder b)]) =
      _$PatchDeviceBody;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PatchDeviceBodyBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PatchDeviceBody> get serializer =>
      _$PatchDeviceBodySerializer();
}

class _$PatchDeviceBodySerializer
    implements PrimitiveSerializer<PatchDeviceBody> {
  @override
  final Iterable<Type> types = const [PatchDeviceBody, _$PatchDeviceBody];

  @override
  final String wireName = r'PatchDeviceBody';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PatchDeviceBody object, {
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
    if (object.name != null) {
      yield r'name';
      yield serializers.serialize(
        object.name,
        specifiedType: const FullType(String),
      );
    }
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
    PatchDeviceBody object, {
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
    required PatchDeviceBodyBuilder result,
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
  PatchDeviceBody deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PatchDeviceBodyBuilder();
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
