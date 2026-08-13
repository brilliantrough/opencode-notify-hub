import 'dart:io';

import 'package:client/devices/device_identity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('currentPlatform', () {
    test('returns the current desktop host platform', () {
      final expected = Platform.isWindows
          ? ClientPlatform.windows
          : ClientPlatform.linux;

      expect(currentPlatform(), expected);
    });
  });

  group('DeviceIdentity.current', () {
    test('uses the host platform', () {
      expect(DeviceIdentity.current().platform, currentPlatform());
    });
  });

  group('defaultName', () {
    test('desktop returns the non-empty host name', () async {
      final platform = Platform.isWindows
          ? ClientPlatform.windows
          : ClientPlatform.linux;
      final identity = DeviceIdentity(platform: platform);

      final name = await identity.defaultName();

      final computerName = Platform.environment['COMPUTERNAME'];
      final expected = Platform.isWindows && computerName?.isNotEmpty == true
          ? computerName!
          : Platform.localHostname;
      expect(name, expected);
      expect(name, isNotEmpty);
    });
  });
}
