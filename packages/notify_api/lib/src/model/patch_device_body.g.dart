// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patch_device_body.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PatchDeviceBody extends PatchDeviceBody {
  @override
  final bool? enabled;
  @override
  final String? fcmToken;
  @override
  final String? name;
  @override
  final bool? soundEnabled;

  factory _$PatchDeviceBody([void Function(PatchDeviceBodyBuilder)? updates]) =>
      (PatchDeviceBodyBuilder()..update(updates))._build();

  _$PatchDeviceBody._({
    this.enabled,
    this.fcmToken,
    this.name,
    this.soundEnabled,
  }) : super._();
  @override
  PatchDeviceBody rebuild(void Function(PatchDeviceBodyBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PatchDeviceBodyBuilder toBuilder() => PatchDeviceBodyBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PatchDeviceBody &&
        enabled == other.enabled &&
        fcmToken == other.fcmToken &&
        name == other.name &&
        soundEnabled == other.soundEnabled;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, enabled.hashCode);
    _$hash = $jc(_$hash, fcmToken.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, soundEnabled.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PatchDeviceBody')
          ..add('enabled', enabled)
          ..add('fcmToken', fcmToken)
          ..add('name', name)
          ..add('soundEnabled', soundEnabled))
        .toString();
  }
}

class PatchDeviceBodyBuilder
    implements Builder<PatchDeviceBody, PatchDeviceBodyBuilder> {
  _$PatchDeviceBody? _$v;

  bool? _enabled;
  bool? get enabled => _$this._enabled;
  set enabled(bool? enabled) => _$this._enabled = enabled;

  String? _fcmToken;
  String? get fcmToken => _$this._fcmToken;
  set fcmToken(String? fcmToken) => _$this._fcmToken = fcmToken;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  bool? _soundEnabled;
  bool? get soundEnabled => _$this._soundEnabled;
  set soundEnabled(bool? soundEnabled) => _$this._soundEnabled = soundEnabled;

  PatchDeviceBodyBuilder() {
    PatchDeviceBody._defaults(this);
  }

  PatchDeviceBodyBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _enabled = $v.enabled;
      _fcmToken = $v.fcmToken;
      _name = $v.name;
      _soundEnabled = $v.soundEnabled;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PatchDeviceBody other) {
    _$v = other as _$PatchDeviceBody;
  }

  @override
  void update(void Function(PatchDeviceBodyBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PatchDeviceBody build() => _build();

  _$PatchDeviceBody _build() {
    final _$result =
        _$v ??
        _$PatchDeviceBody._(
          enabled: enabled,
          fcmToken: fcmToken,
          name: name,
          soundEnabled: soundEnabled,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
