import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../auth/auth_controller.dart';
import '../auth/auth_state.dart';
import '../keepalive/keep_alive.dart';
import '../settings/settings_controller.dart';
import 'webui_tunnel.dart';

typedef WebUiBrowserLauncher = Future<bool> Function(Uri uri);

final webUiBrowserLauncherProvider = Provider<WebUiBrowserLauncher>(
  (ref) => (uri) async {
    if (Platform.isAndroid &&
        ref.read(settingsControllerProvider).keepAliveEnabled) {
      await ref.read(keepAliveProvider).start();
    }
    return launchUrl(uri, mode: webUiLaunchMode(Platform.isAndroid));
  },
);

/// Android must keep the Notify process foregrounded while its loopback bridge
/// serves the WebUI. An external browser can freeze the background Dart isolate.
@visibleForTesting
LaunchMode webUiLaunchMode(bool isAndroid) =>
    isAndroid ? LaunchMode.inAppWebView : LaunchMode.externalApplication;

enum WebUiBrowserStatus { idle, opening, active }

class WebUiConnection {
  const WebUiConnection(this.instanceId, this.status, this.localUri);
  final String instanceId;
  final WebUiBrowserStatus status;
  final Uri? localUri;
}

class WebUiBrowserState {
  const WebUiBrowserState._({
    required this.status,
    this.instanceId,
    this.localUri,
    this.connections = const {},
  });

  const WebUiBrowserState.idle() : this._(status: WebUiBrowserStatus.idle);

  const WebUiBrowserState.opening(String instanceId)
    : this._(status: WebUiBrowserStatus.opening, instanceId: instanceId);

  const WebUiBrowserState.active(String instanceId, Uri localUri)
    : this._(
        status: WebUiBrowserStatus.active,
        instanceId: instanceId,
        localUri: localUri,
      );

  final WebUiBrowserStatus status;
  final String? instanceId;
  final Uri? localUri;
  final Map<String, WebUiConnection> connections;

  WebUiBrowserState.multiple(Map<String, WebUiConnection> connections)
    : this._(
        connections: connections,
        status: connections.isEmpty
            ? WebUiBrowserStatus.idle
            : connections.values.any(
                (c) => c.status == WebUiBrowserStatus.active,
              )
            ? WebUiBrowserStatus.active
            : WebUiBrowserStatus.opening,
      );

  bool activeFor(String candidate) =>
      connections[candidate]?.status == WebUiBrowserStatus.active ||
      (status == WebUiBrowserStatus.active && instanceId == candidate);
  bool openingFor(String candidate) =>
      connections[candidate]?.status == WebUiBrowserStatus.opening ||
      (status == WebUiBrowserStatus.opening && instanceId == candidate);
}

final webUiBrowserControllerProvider =
    NotifierProvider<WebUiBrowserController, WebUiBrowserState>(
      WebUiBrowserController.new,
    );

/// One long-lived local origin per opened instance, shared by all its sessions.
class WebUiBrowserController extends Notifier<WebUiBrowserState> {
  final Map<String, GatewayWebUiTunnel> _tunnels = {};
  final Map<String, StreamSubscription<bool>> _subscriptions = {};

  @override
  WebUiBrowserState build() {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (previous is Authenticated &&
          (next is! Authenticated || previous.email != next.email)) {
        unawaited(close());
      }
    });
    ref.onDispose(() {
      for (final subscription in _subscriptions.values) {
        unawaited(subscription.cancel());
      }
      for (final tunnel in _tunnels.values) {
        unawaited(tunnel.close());
      }
      _subscriptions.clear();
      _tunnels.clear();
    });
    return const WebUiBrowserState.idle();
  }

  /// Opens or reopens the current instance in the system browser.
  /// Returns a user-facing error when the best-effort operation fails.
  Future<String?> open(
    String instanceId, {
    String? directory,
    String? sessionId,
  }) async {
    final initialPath = _sessionPath(directory, sessionId);
    final current = state.connections[instanceId];
    if (current?.localUri != null) {
      final uri = current!.localUri!.resolve(initialPath);
      if (!await _launch(uri)) return '无法打开浏览器';
      if (ref.mounted && state.connections.containsKey(instanceId)) {
        _update(instanceId, state.connections[instanceId]!.status, uri);
      }
      return null;
    }
    if (_tunnels.containsKey(instanceId)) {
      return 'OpenCode WebUI 正在打开';
    }

    _update(instanceId, WebUiBrowserStatus.opening, null);
    GatewayWebUiTunnel? tunnel;
    try {
      tunnel = ref.read(webUiTunnelFactoryProvider)(instanceId);
      tunnel.initialPath = initialPath;
      _tunnels[instanceId] = tunnel;
      final uri = (await tunnel.start()).resolve(initialPath);
      if (!ref.mounted || _tunnels[instanceId] != tunnel) {
        return 'OpenCode WebUI 连接已关闭';
      }
      final started = tunnel;
      _update(instanceId, WebUiBrowserStatus.active, uri);
      _subscriptions[instanceId] = tunnel.connectionChanges.listen((connected) {
        if (!ref.mounted || _tunnels[instanceId] != started) return;
        _update(
          instanceId,
          connected ? WebUiBrowserStatus.active : WebUiBrowserStatus.opening,
          state.connections[instanceId]?.localUri ?? uri,
        );
      });
      unawaited(_observe(instanceId, tunnel));
      if (!await _launch(uri)) {
        await close(instanceId);
        return '无法打开系统默认浏览器';
      }
      if (!ref.mounted || _tunnels[instanceId] != tunnel) {
        return 'OpenCode WebUI 连接已关闭';
      }
      return null;
    } catch (_) {
      if (ref.mounted && (tunnel == null || _tunnels[instanceId] == tunnel)) {
        await close(instanceId);
      }
      await tunnel?.close();
      return '无法建立 OpenCode WebUI 连接';
    }
  }

  String _sessionPath(String? directory, String? sessionId) {
    if (directory == null || directory.isEmpty) {
      return '/';
    }
    final encodedDirectory = base64Url
        .encode(utf8.encode(directory))
        .replaceAll('=', '');
    return '/$encodedDirectory/session${sessionId == null || sessionId.isEmpty ? '' : '/${Uri.encodeComponent(sessionId)}'}';
  }

  void _update(String id, WebUiBrowserStatus status, Uri? uri) {
    state = WebUiBrowserState.multiple({
      ...state.connections,
      id: WebUiConnection(id, status, uri),
    });
  }

  /// Returning from Android's browser retries disconnected transports; Windows
  /// power-resume also replaces sockets that still look connected after sleep.
  void resume({bool afterSleep = false}) {
    for (final tunnel in _tunnels.values.toList()) {
      tunnel.resume(afterSleep: afterSleep);
    }
  }

  Future<String?> reopen(String instanceId) async {
    final uri = state.connections[instanceId]?.localUri;
    if (uri == null) return '连接尚未建立';
    return await _launch(uri) ? null : '无法打开浏览器';
  }

  Future<void> close([String? instanceId]) async {
    final ids = instanceId == null
        ? state.connections.keys.toList()
        : [instanceId];
    final closing = <Future<void>>[];
    final next = Map.of(state.connections);
    for (final id in ids) {
      next.remove(id);
      final subscription = _subscriptions.remove(id);
      if (subscription != null) closing.add(subscription.cancel());
      final tunnel = _tunnels.remove(id);
      if (tunnel != null) closing.add(tunnel.close());
    }
    state = WebUiBrowserState.multiple(next);
    await Future.wait(closing);
  }

  Future<bool> _launch(Uri uri) async {
    try {
      return await ref.read(webUiBrowserLauncherProvider)(uri);
    } catch (_) {
      return false;
    }
  }

  Future<void> _observe(String instanceId, GatewayWebUiTunnel tunnel) async {
    await tunnel.done;
    if (ref.mounted && _tunnels[instanceId] == tunnel) await close(instanceId);
  }
}
