// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_device_body.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const RegisterDeviceBodyPlatformEnum _$registerDeviceBodyPlatformEnum_windows =
    const RegisterDeviceBodyPlatformEnum._('windows');
const RegisterDeviceBodyPlatformEnum _$registerDeviceBodyPlatformEnum_linux =
    const RegisterDeviceBodyPlatformEnum._('linux');
const RegisterDeviceBodyPlatformEnum _$registerDeviceBodyPlatformEnum_android =
    const RegisterDeviceBodyPlatformEnum._('android');

RegisterDeviceBodyPlatformEnum _$registerDeviceBodyPlatformEnumValueOf(
  String name,
) {
  switch (name) {
    case 'windows':
      return _$registerDeviceBodyPlatformEnum_windows;
    case 'linux':
      return _$registerDeviceBodyPlatformEnum_linux;
    case 'android':
      return _$registerDeviceBodyPlatformEnum_android;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<RegisterDeviceBodyPlatformEnum>
_$registerDeviceBodyPlatformEnumValues =
    BuiltSet<RegisterDeviceBodyPlatformEnum>(
      const <RegisterDeviceBodyPlatformEnum>[
        _$registerDeviceBodyPlatformEnum_windows,
        _$registerDeviceBodyPlatformEnum_linux,
        _$registerDeviceBodyPlatformEnum_android,
      ],
    );

Serializer<RegisterDeviceBodyPlatformEnum>
_$registerDeviceBodyPlatformEnumSerializer =
    _$RegisterDeviceBodyPlatformEnumSerializer();

class _$RegisterDeviceBodyPlatformEnumSerializer
    implements PrimitiveSerializer<RegisterDeviceBodyPlatformEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'windows': 'windows',
    'linux': 'linux',
    'android': 'android',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'windows': 'windows',
    'linux': 'linux',
    'android': 'android',
  };

  @override
  final Iterable<Type> types = const <Type>[RegisterDeviceBodyPlatformEnum];
  @override
  final String wireName = 'RegisterDeviceBodyPlatformEnum';

  @override
  Object serialize(
    Serializers serializers,
    RegisterDeviceBodyPlatformEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  RegisterDeviceBodyPlatformEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => RegisterDeviceBodyPlatformEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$RegisterDeviceBody extends RegisterDeviceBody {
  @override
  final bool? enabled;
  @override
  final String? fcmToken;
  @override
  final String name;
  @override
  final RegisterDeviceBodyPlatformEnum platform;
  @override
  final bool? soundEnabled;

  factory _$RegisterDeviceBody([
    void Function(RegisterDeviceBodyBuilder)? updates,
  ]) => (RegisterDeviceBodyBuilder()..update(updates))._build();

  _$RegisterDeviceBody._({
    this.enabled,
    this.fcmToken,
    required this.name,
    required this.platform,
    this.soundEnabled,
  }) : super._();
  @override
  RegisterDeviceBody rebuild(
    void Function(RegisterDeviceBodyBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  RegisterDeviceBodyBuilder toBuilder() =>
      RegisterDeviceBodyBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RegisterDeviceBody &&
        enabled == other.enabled &&
        fcmToken == other.fcmToken &&
        name == other.name &&
        platform == other.platform &&
        soundEnabled == other.soundEnabled;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, enabled.hashCode);
    _$hash = $jc(_$hash, fcmToken.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, platform.hashCode);
    _$hash = $jc(_$hash, soundEnabled.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RegisterDeviceBody')
          ..add('enabled', enabled)
          ..add('fcmToken', fcmToken)
          ..add('name', name)
          ..add('platform', platform)
          ..add('soundEnabled', soundEnabled))
        .toString();
  }
}

class RegisterDeviceBodyBuilder
    implements Builder<RegisterDeviceBody, RegisterDeviceBodyBuilder> {
  _$RegisterDeviceBody? _$v;

  bool? _enabled;
  bool? get enabled => _$this._enabled;
  set enabled(bool? enabled) => _$this._enabled = enabled;

  String? _fcmToken;
  String? get fcmToken => _$this._fcmToken;
  set fcmToken(String? fcmToken) => _$this._fcmToken = fcmToken;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  RegisterDeviceBodyPlatformEnum? _platform;
  RegisterDeviceBodyPlatformEnum? get platform => _$this._platform;
  set platform(RegisterDeviceBodyPlatformEnum? platform) =>
      _$this._platform = platform;

  bool? _soundEnabled;
  bool? get soundEnabled => _$this._soundEnabled;
  set soundEnabled(bool? soundEnabled) => _$this._soundEnabled = soundEnabled;

  RegisterDeviceBodyBuilder() {
    RegisterDeviceBody._defaults(this);
  }

  RegisterDeviceBodyBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _enabled = $v.enabled;
      _fcmToken = $v.fcmToken;
      _name = $v.name;
      _platform = $v.platform;
      _soundEnabled = $v.soundEnabled;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RegisterDeviceBody other) {
    _$v = other as _$RegisterDeviceBody;
  }

  @override
  void update(void Function(RegisterDeviceBodyBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RegisterDeviceBody build() => _build();

  _$RegisterDeviceBody _build() {
    final _$result =
        _$v ??
        _$RegisterDeviceBody._(
          enabled: enabled,
          fcmToken: fcmToken,
          name: BuiltValueNullFieldError.checkNotNull(
            name,
            r'RegisterDeviceBody',
            'name',
          ),
          platform: BuiltValueNullFieldError.checkNotNull(
            platform,
            r'RegisterDeviceBody',
            'platform',
          ),
          soundEnabled: soundEnabled,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
