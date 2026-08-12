import 'package:built_collection/built_collection.dart';
import 'package:client/auth/auth_controller.dart';
import 'package:client/auth/auth_state.dart';
import 'package:client/devices/device_identity.dart';
import 'package:client/devices/devices_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:notify_api/notify_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDevicesApi extends Mock implements DevicesApi {}

/// Deterministic identity: the host branches of [DeviceIdentity] are covered
/// by `device_identity_test.dart`; controller tests use this fake.
class FakeDeviceIdentity extends DeviceIdentity {
  FakeDeviceIdentity([ClientPlatform platform = ClientPlatform.linux])
    : super(platform: platform);

  @override
  Future<String> defaultName() async => 'test-host';
}

/// Auth controller seeded directly into a fixed state.
class SeededAuthController extends AuthController {
  SeededAuthController(this._seed);

  final AuthState _seed;

  @override
  AuthState build() => _seed;
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      RegisterDeviceBody(
        (b) => b
          ..name = ''
          ..platform = RegisterDeviceBodyPlatformEnum.linux,
      ),
    );
    registerFallbackValue(PatchDeviceBody((b) => b));
  });

  const authenticated = Authenticated(
    accessToken: 'access-1',
    email: 'user@example.com',
  );

  late MockDevicesApi devicesApi;
  late ProviderContainer container;

  Device device({
    String id = 'dev-1',
    String name = 'test-host',
    bool enabled = true,
    bool soundEnabled = true,
    String? fcmToken,
  }) {
    return Device(
      (b) => b
        ..id = id
        ..name = name
        ..enabled = enabled
        ..soundEnabled = soundEnabled
        ..fcmToken = fcmToken
        ..platform = DevicePlatformEnum.linux,
    );
  }

  DeviceListResponseInner listInner({
    String id = 'dev-1',
    String name = 'test-host',
    bool enabled = true,
    bool soundEnabled = true,
    String? fcmToken,
  }) {
    return DeviceListResponseInner(
      (b) => b
        ..id = id
        ..name = name
        ..enabled = enabled
        ..soundEnabled = soundEnabled
        ..fcmToken = fcmToken
        ..platform = DeviceListResponseInnerPlatformEnum.linux,
    );
  }

  Response<BuiltList<DeviceListResponseInner>> listResponse(
    List<DeviceListResponseInner> devices,
  ) {
    return Response<BuiltList<DeviceListResponseInner>>(
      data: devices.toBuiltList(),
      statusCode: 200,
      requestOptions: RequestOptions(path: '/v1/devices'),
    );
  }

  Response<Device> deviceResponse(Device data, {int statusCode = 200}) {
    return Response<Device>(
      data: data,
      statusCode: statusCode,
      requestOptions: RequestOptions(path: '/v1/devices'),
    );
  }

  void stubList(List<DeviceListResponseInner> devices) {
    when(
      () => devicesApi.listDevices(),
    ).thenAnswer((_) async => listResponse(devices));
  }

  void stubPatch(Device updated) {
    when(
      () => devicesApi.updateDevice(
        id: any(named: 'id'),
        patchDeviceBody: any(named: 'patchDeviceBody'),
      ),
    ).thenAnswer((_) async => deviceResponse(updated));
  }

  (String, PatchDeviceBody) capturedUpdate() {
    final captured = verify(
      () => devicesApi.updateDevice(
        id: captureAny(named: 'id'),
        patchDeviceBody: captureAny(named: 'patchDeviceBody'),
      ),
    ).captured;
    return (captured[0] as String, captured[1] as PatchDeviceBody);
  }

  PatchDeviceBody capturedPatch() {
    return capturedUpdate().$2;
  }

  Future<String?> persistedDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('device_id_v1');
  }

  DevicesController controller() =>
      container.read(devicesControllerProvider.notifier);

  Future<List<Device>> devices() =>
      container.read(devicesControllerProvider.future);

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    devicesApi = MockDevicesApi();
    stubList(const []);
    container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => SeededAuthController(authenticated),
        ),
        devicesApiProvider.overrideWithValue(devicesApi),
        deviceIdentityProvider.overrideWithValue(FakeDeviceIdentity()),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('build', () {
    test('lists the authenticated user\'s devices', () async {
      stubList([listInner(id: 'dev-1'), listInner(id: 'dev-2', name: 'b')]);

      final result = await devices();

      expect(result.map((d) => d.id), ['dev-1', 'dev-2']);
      expect(result.first.platform, DevicePlatformEnum.linux);
      verify(() => devicesApi.listDevices()).called(greaterThan(0));
    });

    test('is empty and never calls the gateway when unauthenticated', () async {
      final unauthenticated = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(
            () => SeededAuthController(const Unauthenticated()),
          ),
          devicesApiProvider.overrideWithValue(devicesApi),
          deviceIdentityProvider.overrideWithValue(FakeDeviceIdentity()),
        ],
      );
      addTearDown(unauthenticated.dispose);

      final result = await unauthenticated.read(devicesControllerProvider.future);

      expect(result, isEmpty);
      verifyNever(() => devicesApi.listDevices());
    });
  });

  group('registerCurrentDevice', () {
    test('first login registers the device and persists its id', () async {
      when(
        () => devicesApi.registerDevice(
          registerDeviceBody: any(named: 'registerDeviceBody'),
        ),
      ).thenAnswer(
        (_) async => deviceResponse(device(id: 'dev-1'), statusCode: 201),
      );

      final registered = await controller().registerCurrentDevice();

      expect(registered.id, 'dev-1');
      expect(await persistedDeviceId(), 'dev-1');
      final captured =
          verify(
                () => devicesApi.registerDevice(
                  registerDeviceBody: captureAny(named: 'registerDeviceBody'),
                ),
              ).captured.single
              as RegisterDeviceBody;
      expect(captured.name, 'test-host');
      expect(captured.platform, RegisterDeviceBodyPlatformEnum.linux);
      expect((await devices()).map((d) => d.id), contains('dev-1'));
    });

    test('second login reuses the device matching the persisted id', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'device_id_v1': 'dev-9',
      });
      stubList([
        listInner(id: 'dev-9', name: 'renamed-host', fcmToken: 'fcm-old'),
        listInner(id: 'dev-other'),
      ]);

      final reused = await controller().registerCurrentDevice();

      expect(reused.id, 'dev-9');
      expect(reused.name, 'renamed-host');
      verifyNever(
        () => devicesApi.registerDevice(
          registerDeviceBody: any(named: 'registerDeviceBody'),
        ),
      );
      expect(await persistedDeviceId(), 'dev-9');
    });

    test('stale persisted id registers a new device and overwrites it',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'device_id_v1': 'dev-gone',
      });
      stubList([listInner(id: 'dev-other')]);
      when(
        () => devicesApi.registerDevice(
          registerDeviceBody: any(named: 'registerDeviceBody'),
        ),
      ).thenAnswer(
        (_) async => deviceResponse(device(id: 'dev-new'), statusCode: 201),
      );

      final registered = await controller().registerCurrentDevice();

      expect(registered.id, 'dev-new');
      expect(await persistedDeviceId(), 'dev-new');
    });

    test('throws StateError when unauthenticated', () async {
      final unauthenticated = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(
            () => SeededAuthController(const Unauthenticated()),
          ),
          devicesApiProvider.overrideWithValue(devicesApi),
          deviceIdentityProvider.overrideWithValue(FakeDeviceIdentity()),
        ],
      );
      addTearDown(unauthenticated.dispose);

      await expectLater(
        unauthenticated
            .read(devicesControllerProvider.notifier)
            .registerCurrentDevice(),
        throwsStateError,
      );
      verifyNever(
        () => devicesApi.registerDevice(
          registerDeviceBody: any(named: 'registerDeviceBody'),
        ),
      );
    });
  });

  group('registerCurrentDevice FCM token compensation', () {
    ProviderContainer androidContainer({String? token}) {
      final c = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(
            () => SeededAuthController(authenticated),
          ),
          devicesApiProvider.overrideWithValue(devicesApi),
          deviceIdentityProvider.overrideWithValue(
            FakeDeviceIdentity(ClientPlatform.android),
          ),
          currentFcmTokenProvider.overrideWithValue(() async => token),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    void stubRegister(Device registered) {
      when(
        () => devicesApi.registerDevice(
          registerDeviceBody: any(named: 'registerDeviceBody'),
        ),
      ).thenAnswer((_) async => deviceResponse(registered, statusCode: 201));
    }

    test('fresh registration publishes the current FCM token', () async {
      stubRegister(device(id: 'dev-1'));
      stubPatch(device(id: 'dev-1', fcmToken: 'tok-1'));

      await androidContainer(token: 'tok-1')
          .read(devicesControllerProvider.notifier)
          .registerCurrentDevice();

      final (id, patch) = capturedUpdate();
      expect(id, 'dev-1');
      expect(patch.fcmToken, 'tok-1');
    });

    test('reused registration patches a stale server-side token', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'device_id_v1': 'dev-9',
      });
      stubList([listInner(id: 'dev-9', fcmToken: 'fcm-old')]);
      stubPatch(device(id: 'dev-9', fcmToken: 'tok-1'));

      final reused = await androidContainer(token: 'tok-1')
          .read(devicesControllerProvider.notifier)
          .registerCurrentDevice();

      expect(reused.id, 'dev-9');
      final (id, patch) = capturedUpdate();
      expect(id, 'dev-9');
      expect(patch.fcmToken, 'tok-1');
    });

    test('skips the patch when the server already has the current token',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'device_id_v1': 'dev-9',
      });
      stubList([listInner(id: 'dev-9', fcmToken: 'tok-1')]);

      await androidContainer(token: 'tok-1')
          .read(devicesControllerProvider.notifier)
          .registerCurrentDevice();

      verifyNever(
        () => devicesApi.updateDevice(
          id: any(named: 'id'),
          patchDeviceBody: any(named: 'patchDeviceBody'),
        ),
      );
    });

    test('skips the patch when no FCM token is available', () async {
      stubRegister(device(id: 'dev-1'));

      await androidContainer(token: null)
          .read(devicesControllerProvider.notifier)
          .registerCurrentDevice();

      verifyNever(
        () => devicesApi.updateDevice(
          id: any(named: 'id'),
          patchDeviceBody: any(named: 'patchDeviceBody'),
        ),
      );
    });

    test('never touches FCM tokens off Android', () async {
      stubRegister(device(id: 'dev-1'));

      // The default container uses the linux FakeDeviceIdentity; a token
      // provider is intentionally not overridden — the linux path must not
      // even read it.
      await controller().registerCurrentDevice();

      verifyNever(
        () => devicesApi.updateDevice(
          id: any(named: 'id'),
          patchDeviceBody: any(named: 'patchDeviceBody'),
        ),
      );
    });
  });

  group('remove', () {
    setUp(() {
      stubList([listInner(id: 'dev-1'), listInner(id: 'dev-2')]);
      when(() => devicesApi.deleteDevice(id: any(named: 'id'))).thenAnswer(
        (_) async => Response<void>(
          statusCode: 204,
          requestOptions: RequestOptions(path: '/v1/devices/x'),
        ),
      );
    });

    test('deletes the device and clears the persisted id when it is current',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'device_id_v1': 'dev-1',
      });
      await devices(); // complete the initial build

      await controller().remove('dev-1');

      verify(() => devicesApi.deleteDevice(id: 'dev-1')).called(1);
      expect((await devices()).map((d) => d.id), ['dev-2']);
      expect(await persistedDeviceId(), isNull);
    });

    test('keeps the persisted id when removing another device', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'device_id_v1': 'dev-1',
      });
      await devices();

      await controller().remove('dev-2');

      verify(() => devicesApi.deleteDevice(id: 'dev-2')).called(1);
      expect((await devices()).map((d) => d.id), ['dev-1']);
      expect(await persistedDeviceId(), 'dev-1');
    });
  });

  group('updateFcmToken', () {
    test('patches only the FCM token and updates state', () async {
      stubList([listInner(id: 'dev-1'), listInner(id: 'dev-2')]);
      stubPatch(device(id: 'dev-1', fcmToken: 'fcm-new'));
      await devices();

      final updated = await controller().updateFcmToken('dev-1', 'fcm-new');

      expect(updated.fcmToken, 'fcm-new');
      final captured = capturedPatch();
      expect(captured.fcmToken, 'fcm-new');
      expect(captured.name, isNull);
      expect(captured.enabled, isNull);
      expect(captured.soundEnabled, isNull);
      final current = await devices();
      expect(current.firstWhere((d) => d.id == 'dev-1').fcmToken, 'fcm-new');
    });
  });

  group('rename', () {
    test('patches only the name and updates state', () async {
      stubList([listInner(id: 'dev-1')]);
      stubPatch(device(id: 'dev-1', name: 'desk-pc'));
      await devices();

      final updated = await controller().rename('dev-1', 'desk-pc');

      expect(updated.name, 'desk-pc');
      final (id, captured) = capturedUpdate();
      expect(id, 'dev-1');
      expect(captured.name, 'desk-pc');
      expect(captured.enabled, isNull);
      expect(captured.soundEnabled, isNull);
      expect(captured.fcmToken, isNull);
      expect((await devices()).single.name, 'desk-pc');
    });
  });

  group('setEnabled', () {
    test('patches only enabled and updates state', () async {
      stubList([listInner(id: 'dev-1')]);
      stubPatch(device(id: 'dev-1', enabled: false));
      await devices();

      final updated = await controller().setEnabled('dev-1', false);

      expect(updated.enabled, isFalse);
      final captured = capturedPatch();
      expect(captured.enabled, isFalse);
      expect(captured.name, isNull);
      expect(captured.soundEnabled, isNull);
      expect(captured.fcmToken, isNull);
      expect((await devices()).single.enabled, isFalse);
    });
  });

  group('setSoundEnabled', () {
    test('patches only soundEnabled and updates state', () async {
      stubList([listInner(id: 'dev-1')]);
      stubPatch(device(id: 'dev-1', soundEnabled: false));
      await devices();

      final updated = await controller().setSoundEnabled('dev-1', false);

      expect(updated.soundEnabled, isFalse);
      final captured = capturedPatch();
      expect(captured.soundEnabled, isFalse);
      expect(captured.name, isNull);
      expect(captured.enabled, isNull);
      expect(captured.fcmToken, isNull);
      expect((await devices()).single.soundEnabled, isFalse);
    });
  });

  group('auth scoping', () {
    test('every mutating method requires an authenticated session', () async {
      final unauthenticated = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(
            () => SeededAuthController(const Unauthenticated()),
          ),
          devicesApiProvider.overrideWithValue(devicesApi),
          deviceIdentityProvider.overrideWithValue(FakeDeviceIdentity()),
        ],
      );
      addTearDown(unauthenticated.dispose);
      final controller =
          unauthenticated.read(devicesControllerProvider.notifier);

      await expectLater(controller.rename('x', 'y'), throwsStateError);
      await expectLater(controller.setEnabled('x', true), throwsStateError);
      await expectLater(
        controller.setSoundEnabled('x', true),
        throwsStateError,
      );
      await expectLater(controller.updateFcmToken('x', 't'), throwsStateError);
      await expectLater(controller.remove('x'), throwsStateError);
      verifyNever(
        () => devicesApi.updateDevice(
          id: any(named: 'id'),
          patchDeviceBody: any(named: 'patchDeviceBody'),
        ),
      );
      verifyNever(() => devicesApi.deleteDevice(id: any(named: 'id')));
    });
  });
}
