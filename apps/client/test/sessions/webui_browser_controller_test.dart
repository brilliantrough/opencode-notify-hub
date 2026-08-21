import 'dart:async';

import 'package:client/auth/auth_controller.dart';
import 'package:client/auth/auth_state.dart';
import 'package:client/sessions/webui_browser_controller.dart';
import 'package:client/sessions/webui_tunnel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';

class _FakeAuthController extends AuthController {
  @override
  AuthState build() => const Authenticated(
    accessToken: 'access-token',
    email: 'user@example.com',
  );

  void signOut() => state = const Unauthenticated();
}

class _FakeTunnel extends GatewayWebUiTunnel {
  _FakeTunnel(this.uri)
    : super(
        gatewayUri: Uri.parse('wss://notify.example.com/v1/webui/ws'),
        accessToken: 'access-token',
        instanceId: 'instance',
        connector: (_, _) => throw UnimplementedError(),
      );

  final Uri uri;
  final Completer<void> _done = Completer<void>();
  var startCalls = 0;
  var closeCalls = 0;
  String? startedPath;

  @override
  Future<void> get done => _done.future;

  @override
  Future<Uri> start() async {
    startCalls++;
    startedPath = initialPath;
    return uri;
  }

  @override
  Future<void> close() async {
    closeCalls++;
    if (!_done.isCompleted) _done.complete();
  }

  void disconnect() {
    if (!_done.isCompleted) _done.complete();
  }
}

void main() {
  test('uses an in-app WebView on Android to keep the tunnel process active', () {
    expect(webUiLaunchMode(true), LaunchMode.inAppWebView);
    expect(webUiLaunchMode(false), LaunchMode.externalApplication);
  });

  test('starts one tunnel and reopens it in the system browser', () async {
    final auth = _FakeAuthController();
    final tunnel = _FakeTunnel(Uri.parse('http://127.0.0.1:42000/'));
    final launched = <Uri>[];
    var factoryCalls = 0;
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(() => auth),
        webUiTunnelFactoryProvider.overrideWithValue((_) {
          factoryCalls++;
          return tunnel;
        }),
        webUiBrowserLauncherProvider.overrideWithValue((uri) async {
          launched.add(uri);
          return true;
        }),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(webUiBrowserControllerProvider.notifier);
    expect(await controller.open('instance-1'), isNull);
    expect(
      container.read(webUiBrowserControllerProvider).status,
      WebUiBrowserStatus.active,
    );

    expect(await controller.open('instance-1'), isNull);
    expect(factoryCalls, 1);
    expect(tunnel.startCalls, 1);
    expect(launched, [tunnel.uri, tunnel.uri]);

    await controller.close();
    expect(tunnel.closeCalls, 1);
    expect(
      container.read(webUiBrowserControllerProvider).status,
      WebUiBrowserStatus.idle,
    );
  });

  test('closes the tunnel when the account signs out', () async {
    final auth = _FakeAuthController();
    final tunnel = _FakeTunnel(Uri.parse('http://127.0.0.1:42001/'));
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(() => auth),
        webUiTunnelFactoryProvider.overrideWithValue((_) => tunnel),
        webUiBrowserLauncherProvider.overrideWithValue((_) async => true),
      ],
    );
    addTearDown(container.dispose);
    await container
        .read(webUiBrowserControllerProvider.notifier)
        .open('instance-1');

    auth.signOut();
    await pumpEventQueue();

    expect(tunnel.closeCalls, 1);
    expect(
      container.read(webUiBrowserControllerProvider).status,
      WebUiBrowserStatus.idle,
    );
  });

  test(
    'opens a Session-scoped directory route when a target is provided',
    () async {
      final auth = _FakeAuthController();
      final tunnel = _FakeTunnel(Uri.parse('http://127.0.0.1:42004/'));
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(() => auth),
          webUiTunnelFactoryProvider.overrideWithValue((_) => tunnel),
          webUiBrowserLauncherProvider.overrideWithValue((_) async => true),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(webUiBrowserControllerProvider.notifier)
          .open(
            'instance-1',
            directory: '/home/pzy000/test_temp',
            sessionId: 'ses-1',
          );

      expect(
        tunnel.startedPath,
        '/L2hvbWUvcHp5MDAwL3Rlc3RfdGVtcA/session/ses-1',
      );
    },
  );

  test('preserves a Windows directory in the encoded Session route', () async {
    final auth = _FakeAuthController();
    final tunnel = _FakeTunnel(Uri.parse('http://127.0.0.1:42005/'));
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(() => auth),
        webUiTunnelFactoryProvider.overrideWithValue((_) => tunnel),
        webUiBrowserLauncherProvider.overrideWithValue((_) async => true),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(webUiBrowserControllerProvider.notifier)
        .open(
          'instance-1',
          directory: r'D:\dev\my project\',
          sessionId: 'ses with spaces',
        );

    expect(
      tunnel.startedPath,
      '/RDpcZGV2XG15IHByb2plY3Rc/session/ses%20with%20spaces',
    );
  });

  test('returns to idle when the remote tunnel closes', () async {
    final auth = _FakeAuthController();
    final tunnel = _FakeTunnel(Uri.parse('http://127.0.0.1:42002/'));
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(() => auth),
        webUiTunnelFactoryProvider.overrideWithValue((_) => tunnel),
        webUiBrowserLauncherProvider.overrideWithValue((_) async => true),
      ],
    );
    addTearDown(container.dispose);
    await container
        .read(webUiBrowserControllerProvider.notifier)
        .open('instance-1');

    tunnel.disconnect();
    await pumpEventQueue();

    expect(
      container.read(webUiBrowserControllerProvider).status,
      WebUiBrowserStatus.idle,
    );
  });

  test('closes a new tunnel when no browser can open it', () async {
    final auth = _FakeAuthController();
    final tunnel = _FakeTunnel(Uri.parse('http://127.0.0.1:42003/'));
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(() => auth),
        webUiTunnelFactoryProvider.overrideWithValue((_) => tunnel),
        webUiBrowserLauncherProvider.overrideWithValue((_) async => false),
      ],
    );
    addTearDown(container.dispose);

    final error = await container
        .read(webUiBrowserControllerProvider.notifier)
        .open('instance-1');

    expect(error, '无法打开系统默认浏览器');
    expect(tunnel.closeCalls, 1);
    expect(
      container.read(webUiBrowserControllerProvider).status,
      WebUiBrowserStatus.idle,
    );
  });
}
