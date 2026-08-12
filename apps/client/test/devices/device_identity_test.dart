import 'dart:io';

import 'package:client/devices/device_identity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // These tests exercise the host (Linux) branches; the Windows/Android
  // branches are covered by the DevicesController tests via a fake identity.
  group('currentPlatform', () {
    test('returns linux on the Linux test host', () {
      expect(currentPlatform(), ClientPlatform.linux);
    });
  });

  group('DeviceIdentity.current', () {
    test('uses the host platform', () {
      expect(DeviceIdentity.current().platform, currentPlatform());
    });
  });

  group('defaultName', () {
    test('linux returns the non-empty host name', () async {
      final identity = DeviceIdentity(platform: ClientPlatform.linux);

      final name = await identity.defaultName();

      expect(name, Platform.localHostname);
      expect(name, isNotEmpty);
    });
  });
}
