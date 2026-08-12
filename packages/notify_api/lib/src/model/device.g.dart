// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const DevicePlatformEnum _$devicePlatformEnum_windows =
    const DevicePlatformEnum._('windows');
const DevicePlatformEnum _$devicePlatformEnum_linux =
    const DevicePlatformEnum._('linux');
const DevicePlatformEnum _$devicePlatformEnum_android =
    const DevicePlatformEnum._('android');

DevicePlatformEnum _$devicePlatformEnumValueOf(String name) {
  switch (name) {
    case 'windows':
      return _$devicePlatformEnum_windows;
    case 'linux':
      return _$devicePlatformEnum_linux;
    case 'android':
      return _$devicePlatformEnum_android;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<DevicePlatformEnum> _$devicePlatformEnumValues =
    BuiltSet<DevicePlatformEnum>(const <DevicePlatformEnum>[
      _$devicePlatformEnum_windows,
      _$devicePlatformEnum_linux,
      _$devicePlatformEnum_android,
    ]);

Serializer<DevicePlatformEnum> _$devicePlatformEnumSerializer =
    _$DevicePlatformEnumSerializer();

class _$DevicePlatformEnumSerializer
    implements PrimitiveSerializer<DevicePlatformEnum> {
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
  final Iterable<Type> types = const <Type>[DevicePlatformEnum];
  @override
  final String wireName = 'DevicePlatformEnum';

  @override
  Object serialize(
    Serializers serializers,
    DevicePlatformEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  DevicePlatformEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => DevicePlatformEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$Device extends Device {
  @override
  final bool enabled;
  @override
  final String? fcmToken;
  @override
  final String id;
  @override
  final String name;
  @override
  final DevicePlatformEnum platform;
  @override
  final bool soundEnabled;

  factory _$Device([void Function(DeviceBuilder)? updates]) =>
      (DeviceBuilder()..update(updates))._build();

  _$Device._({
    required this.enabled,
    this.fcmToken,
    required this.id,
    required this.name,
    required this.platform,
    required this.soundEnabled,
  }) : super._();
  @override
  Device rebuild(void Function(DeviceBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DeviceBuilder toBuilder() => DeviceBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Device &&
        enabled == other.enabled &&
        fcmToken == other.fcmToken &&
        id == other.id &&
        name == other.name &&
        platform == other.platform &&
        soundEnabled == other.soundEnabled;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, enabled.hashCode);
    _$hash = $jc(_$hash, fcmToken.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, platform.hashCode);
    _$hash = $jc(_$hash, soundEnabled.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Device')
          ..add('enabled', enabled)
          ..add('fcmToken', fcmToken)
          ..add('id', id)
          ..add('name', name)
          ..add('platform', platform)
          ..add('soundEnabled', soundEnabled))
        .toString();
  }
}

class DeviceBuilder implements Builder<Device, DeviceBuilder> {
  _$Device? _$v;

  bool? _enabled;
  bool? get enabled => _$this._enabled;
  set enabled(bool? enabled) => _$this._enabled = enabled;

  String? _fcmToken;
  String? get fcmToken => _$this._fcmToken;
  set fcmToken(String? fcmToken) => _$this._fcmToken = fcmToken;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  DevicePlatformEnum? _platform;
  DevicePlatformEnum? get platform => _$this._platform;
  set platform(DevicePlatformEnum? platform) => _$this._platform = platform;

  bool? _soundEnabled;
  bool? get soundEnabled => _$this._soundEnabled;
  set soundEnabled(bool? soundEnabled) => _$this._soundEnabled = soundEnabled;

  DeviceBuilder() {
    Device._defaults(this);
  }

  DeviceBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _enabled = $v.enabled;
      _fcmToken = $v.fcmToken;
      _id = $v.id;
      _name = $v.name;
      _platform = $v.platform;
      _soundEnabled = $v.soundEnabled;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Device other) {
    _$v = other as _$Device;
  }

  @override
  void update(void Function(DeviceBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Device build() => _build();

  _$Device _build() {
    final _$result =
        _$v ??
        _$Device._(
          enabled: BuiltValueNullFieldError.checkNotNull(
            enabled,
            r'Device',
            'enabled',
          ),
          fcmToken: fcmToken,
          id: BuiltValueNullFieldError.checkNotNull(id, r'Device', 'id'),
          name: BuiltValueNullFieldError.checkNotNull(name, r'Device', 'name'),
          platform: BuiltValueNullFieldError.checkNotNull(
            platform,
            r'Device',
            'platform',
          ),
          soundEnabled: BuiltValueNullFieldError.checkNotNull(
            soundEnabled,
            r'Device',
            'soundEnabled',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
