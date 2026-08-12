import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notify_api/notify_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_controller.dart';
import '../auth/auth_state.dart';
import 'device_identity.dart';

/// Shared-preferences key holding the gateway ID of the current device.
const deviceIdPrefsKey = 'device_id_v1';

final devicesApiProvider = Provider<DevicesApi>(
  (ref) => ref.watch(apiClientProvider).notifyApi.getDevicesApi(),
);

/// Identity of the current device. Overridden in tests.
final deviceIdentityProvider = Provider<DeviceIdentity>(
  (ref) => DeviceIdentity.current(),
);

/// Getter for the current FCM registration token. Read only on Android, after
/// device registration completes, to compensate for token availability that
/// raced registration (e.g. `FcmService.init` ran before the device row
/// existed and dropped the token). Overridden in tests; never evaluated on
/// other platforms, so desktop/test runs never touch FirebaseMessaging.
final currentFcmTokenProvider = Provider<Future<String?> Function()>(
  (ref) => FirebaseMessaging.instance.getToken,
);

/// Shared-preferences handle (async because `getInstance` is). Overridable;
/// tests typically use `SharedPreferences.setMockInitialValues` instead.
final sharedPreferencesProvider = Provider<Future<SharedPreferences>>(
  (ref) => SharedPreferences.getInstance(),
);

final devicesControllerProvider =
    AsyncNotifierProvider<DevicesController, List<Device>>(
      DevicesController.new,
    );

/// Manages the authenticated user's gateway-registered devices.
///
/// The device list only exists for an authenticated session: [build] watches
/// [authControllerProvider] and stays empty while unauthenticated, and every
/// mutating method requires an [Authenticated] state (throwing [StateError]
/// otherwise), so all gateway calls are scoped to the current user.
///
/// The current physical device is remembered across restarts by persisting
/// its gateway ID under [deviceIdPrefsKey] in shared preferences;
/// [registerCurrentDevice] reuses the matching server row instead of
/// registering a duplicate on every login.
class DevicesController extends AsyncNotifier<List<Device>> {
  DevicesApi get _api => ref.read(devicesApiProvider);
  DeviceIdentity get _identity => ref.read(deviceIdentityProvider);
  Future<SharedPreferences> get _prefs => ref.read(sharedPreferencesProvider);

  @override
  Future<List<Device>> build() async {
    final auth = ref.watch(authControllerProvider);
    if (auth is! Authenticated) {
      return const [];
    }
    return _listDevices();
  }

  /// Registers the current device with the gateway, or reuses the existing
  /// row when the persisted device ID still exists for this user.
  ///
  /// Returns the gateway [Device] representing this machine. A persisted ID
  /// that no longer exists server-side (deleted on another client, or a
  /// different account) is treated as stale: a new device is registered and
  /// the persisted ID overwritten.
  ///
  /// On Android the resolved device also receives the current FCM token when
  /// the server-side value is missing or stale, so the row ends up with a
  /// token even when token availability raced registration.
  Future<Device> registerCurrentDevice() async {
    _requireAuthenticated();
    final prefs = await _prefs;
    final persistedId = prefs.getString(deviceIdPrefsKey);
    final devices = await _listDevices();
    if (persistedId != null) {
      for (final device in devices) {
        if (device.id == persistedId) {
          state = AsyncData(devices);
          return _publishCurrentFcmToken(device);
        }
      }
    }
    final name = await _identity.defaultName();
    final response = await _api.registerDevice(
      registerDeviceBody: RegisterDeviceBody(
        (b) => b
          ..name = name
          ..platform = RegisterDeviceBodyPlatformEnum.valueOf(
            _identity.platform.name,
          ),
      ),
    );
    final registered = response.data;
    if (registered == null) {
      throw StateError('Empty registerDevice response');
    }
    await prefs.setString(deviceIdPrefsKey, registered.id);
    state = AsyncData([...devices, registered]);
    return _publishCurrentFcmToken(registered);
  }

  /// Publishes the current FCM token to [device] after registration, when
  /// needed. No-op off Android, when no token is available, or when the
  /// server already holds the current token.
  Future<Device> _publishCurrentFcmToken(Device device) async {
    if (_identity.platform != ClientPlatform.android) {
      return device;
    }
    final token = await ref.read(currentFcmTokenProvider)();
    if (token == null || token == device.fcmToken) {
      return device;
    }
    return updateFcmToken(device.id, token);
  }

  /// Renames a device.
  Future<Device> rename(String id, String name) {
    return _patch(id, PatchDeviceBody((b) => b.name = name));
  }

  /// Enables or disables notifications for a device.
  Future<Device> setEnabled(String id, bool enabled) {
    return _patch(id, PatchDeviceBody((b) => b.enabled = enabled));
  }

  /// Enables or disables notification sounds for a device.
  Future<Device> setSoundEnabled(String id, bool soundEnabled) {
    return _patch(id, PatchDeviceBody((b) => b.soundEnabled = soundEnabled));
  }

  /// Publishes a new FCM token for a device.
  Future<Device> updateFcmToken(String id, String token) {
    return _patch(id, PatchDeviceBody((b) => b.fcmToken = token));
  }

  /// Deletes a device. The persisted current-device ID is cleared only when
  /// the deleted device is this one.
  Future<void> remove(String id) async {
    _requireAuthenticated();
    await _api.deleteDevice(id: id);
    final current = await future;
    state = AsyncData([
      for (final device in current)
        if (device.id != id) device,
    ]);
    final prefs = await _prefs;
    if (prefs.getString(deviceIdPrefsKey) == id) {
      await prefs.remove(deviceIdPrefsKey);
    }
  }

  Future<Device> _patch(String id, PatchDeviceBody body) async {
    _requireAuthenticated();
    final response = await _api.updateDevice(id: id, patchDeviceBody: body);
    final updated = response.data;
    if (updated == null) {
      throw StateError('Empty updateDevice response');
    }
    final current = await future;
    state = AsyncData([
      for (final device in current)
        if (device.id == id) updated else device,
    ]);
    return updated;
  }

  Future<List<Device>> _listDevices() async {
    final response = await _api.listDevices();
    final data = response.data;
    if (data == null) {
      return const [];
    }
    return data.map(_toDevice).toList();
  }

  void _requireAuthenticated() {
    if (ref.read(authControllerProvider) is! Authenticated) {
      throw StateError(
        'DevicesController requires an authenticated session',
      );
    }
  }

  static Device _toDevice(DeviceListResponseInner inner) {
    return Device(
      (b) => b
        ..id = inner.id
        ..name = inner.name
        ..enabled = inner.enabled
        ..soundEnabled = inner.soundEnabled
        ..fcmToken = inner.fcmToken
        ..platform = DevicePlatformEnum.valueOf(inner.platform.name),
    );
  }
}
