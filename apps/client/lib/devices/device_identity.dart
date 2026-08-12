import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

/// Client platforms supported by the gateway's `Device.platform` enum.
enum ClientPlatform { windows, linux, android }

/// Resolves the host operating system to a [ClientPlatform].
///
/// Throws [UnsupportedError] on any other platform (macOS, iOS, ...).
ClientPlatform currentPlatform() {
  if (Platform.isWindows) {
    return ClientPlatform.windows;
  }
  if (Platform.isLinux) {
    return ClientPlatform.linux;
  }
  if (Platform.isAndroid) {
    return ClientPlatform.android;
  }
  throw UnsupportedError(
    'Unsupported client platform: ${Platform.operatingSystem}',
  );
}

/// Identity of the machine this client instance runs on: its [platform] plus
/// a human-readable default device name used when registering with the
/// gateway.
class DeviceIdentity {
  const DeviceIdentity({required this.platform});

  /// Identity for the current host.
  factory DeviceIdentity.current() =>
      DeviceIdentity(platform: currentPlatform());

  /// The host platform.
  final ClientPlatform platform;

  /// A sensible default display name for this device:
  /// - Windows: the `COMPUTERNAME` environment variable (falling back to the
  ///   host name when unset or empty),
  /// - Linux: the host name,
  /// - Android: the device model reported by `device_info_plus`.
  Future<String> defaultName() async {
    switch (platform) {
      case ClientPlatform.windows:
        final computerName = Platform.environment['COMPUTERNAME'];
        if (computerName != null && computerName.isNotEmpty) {
          return computerName;
        }
        return Platform.localHostname;
      case ClientPlatform.linux:
        return Platform.localHostname;
      case ClientPlatform.android:
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        return androidInfo.model;
    }
  }
}
