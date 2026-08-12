// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_list_response_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const DeviceListResponseInnerPlatformEnum
_$deviceListResponseInnerPlatformEnum_windows =
    const DeviceListResponseInnerPlatformEnum._('windows');
const DeviceListResponseInnerPlatformEnum
_$deviceListResponseInnerPlatformEnum_linux =
    const DeviceListResponseInnerPlatformEnum._('linux');
const DeviceListResponseInnerPlatformEnum
_$deviceListResponseInnerPlatformEnum_android =
    const DeviceListResponseInnerPlatformEnum._('android');

DeviceListResponseInnerPlatformEnum
_$deviceListResponseInnerPlatformEnumValueOf(String name) {
  switch (name) {
    case 'windows':
      return _$deviceListResponseInnerPlatformEnum_windows;
    case 'linux':
      return _$deviceListResponseInnerPlatformEnum_linux;
    case 'android':
      return _$deviceListResponseInnerPlatformEnum_android;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<DeviceListResponseInnerPlatformEnum>
_$deviceListResponseInnerPlatformEnumValues =
    BuiltSet<DeviceListResponseInnerPlatformEnum>(
      const <DeviceListResponseInnerPlatformEnum>[
        _$deviceListResponseInnerPlatformEnum_windows,
        _$deviceListResponseInnerPlatformEnum_linux,
        _$deviceListResponseInnerPlatformEnum_android,
      ],
    );

Serializer<DeviceListResponseInnerPlatformEnum>
_$deviceListResponseInnerPlatformEnumSerializer =
    _$DeviceListResponseInnerPlatformEnumSerializer();

class _$DeviceListResponseInnerPlatformEnumSerializer
    implements PrimitiveSerializer<DeviceListResponseInnerPlatformEnum> {
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
  final Iterable<Type> types = const <Type>[
    DeviceListResponseInnerPlatformEnum,
  ];
  @override
  final String wireName = 'DeviceListResponseInnerPlatformEnum';

  @override
  Object serialize(
    Serializers serializers,
    DeviceListResponseInnerPlatformEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  DeviceListResponseInnerPlatformEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => DeviceListResponseInnerPlatformEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$DeviceListResponseInner extends DeviceListResponseInner {
  @override
  final bool enabled;
  @override
  final String? fcmToken;
  @override
  final String id;
  @override
  final String name;
  @override
  final DeviceListResponseInnerPlatformEnum platform;
  @override
  final bool soundEnabled;

  factory _$DeviceListResponseInner([
    void Function(DeviceListResponseInnerBuilder)? updates,
  ]) => (DeviceListResponseInnerBuilder()..update(updates))._build();

  _$DeviceListResponseInner._({
    required this.enabled,
    this.fcmToken,
    required this.id,
    required this.name,
    required this.platform,
    required this.soundEnabled,
  }) : super._();
  @override
  DeviceListResponseInner rebuild(
    void Function(DeviceListResponseInnerBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  DeviceListResponseInnerBuilder toBuilder() =>
      DeviceListResponseInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DeviceListResponseInner &&
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
    return (newBuiltValueToStringHelper(r'DeviceListResponseInner')
          ..add('enabled', enabled)
          ..add('fcmToken', fcmToken)
          ..add('id', id)
          ..add('name', name)
          ..add('platform', platform)
          ..add('soundEnabled', soundEnabled))
        .toString();
  }
}

class DeviceListResponseInnerBuilder
    implements
        Builder<DeviceListResponseInner, DeviceListResponseInnerBuilder> {
  _$DeviceListResponseInner? _$v;

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

  DeviceListResponseInnerPlatformEnum? _platform;
  DeviceListResponseInnerPlatformEnum? get platform => _$this._platform;
  set platform(DeviceListResponseInnerPlatformEnum? platform) =>
      _$this._platform = platform;

  bool? _soundEnabled;
  bool? get soundEnabled => _$this._soundEnabled;
  set soundEnabled(bool? soundEnabled) => _$this._soundEnabled = soundEnabled;

  DeviceListResponseInnerBuilder() {
    DeviceListResponseInner._defaults(this);
  }

  DeviceListResponseInnerBuilder get _$this {
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
  void replace(DeviceListResponseInner other) {
    _$v = other as _$DeviceListResponseInner;
  }

  @override
  void update(void Function(DeviceListResponseInnerBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DeviceListResponseInner build() => _build();

  _$DeviceListResponseInner _build() {
    final _$result =
        _$v ??
        _$DeviceListResponseInner._(
          enabled: BuiltValueNullFieldError.checkNotNull(
            enabled,
            r'DeviceListResponseInner',
            'enabled',
          ),
          fcmToken: fcmToken,
          id: BuiltValueNullFieldError.checkNotNull(
            id,
            r'DeviceListResponseInner',
            'id',
          ),
          name: BuiltValueNullFieldError.checkNotNull(
            name,
            r'DeviceListResponseInner',
            'name',
          ),
          platform: BuiltValueNullFieldError.checkNotNull(
            platform,
            r'DeviceListResponseInner',
            'platform',
          ),
          soundEnabled: BuiltValueNullFieldError.checkNotNull(
            soundEnabled,
            r'DeviceListResponseInner',
            'soundEnabled',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
