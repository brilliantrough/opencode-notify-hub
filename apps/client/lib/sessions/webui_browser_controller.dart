import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../auth/auth_controller.dart';
import '../auth/auth_state.dart';
import 'webui_tunnel.dart';

typedef WebUiBrowserLauncher = Future<bool> Function(Uri uri);

final webUiBrowserLauncherProvider = Provider<WebUiBrowserLauncher>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

enum WebUiBrowserStatus { idle, opening, active }

class WebUiBrowserState {
  const WebUiBrowserState._({
    required this.status,
    this.instanceId,
    this.localUri,
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

  bool activeFor(String candidate) =>
      status == WebUiBrowserStatus.active && instanceId == candidate;
}

final webUiBrowserControllerProvider =
    NotifierProvider<WebUiBrowserController, WebUiBrowserState>(
      WebUiBrowserController.new,
    );

/// Owns the one temporary browser tunnel for the current account.
class WebUiBrowserController extends Notifier<WebUiBrowserState> {
  GatewayWebUiTunnel? _tunnel;

  @override
  WebUiBrowserState build() {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (previous is Authenticated && next is! Authenticated) {
        unawaited(close());
      }
    });
    ref.onDispose(() {
      final tunnel = _tunnel;
      _tunnel = null;
      if (tunnel != null) unawaited(tunnel.close());
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
    final current = state;
    if (current.activeFor(instanceId) &&
        current.localUri != null &&
        current.localUri!.path == initialPath) {
      return await _launch(current.localUri!) ? null : '无法打开系统默认浏览器';
    }
    if (current.status == WebUiBrowserStatus.opening) {
      return 'OpenCode WebUI 正在打开';
    }

    await close();
    state = WebUiBrowserState.opening(instanceId);
    final tunnel = ref.read(webUiTunnelFactoryProvider)(instanceId);
    tunnel.initialPath = initialPath;
    _tunnel = tunnel;
    try {
      final uri = await tunnel.start();
      if (_tunnel != tunnel) return null;
      unawaited(_observe(tunnel));
      if (!await _launch(uri)) {
        await close();
        return '无法打开系统默认浏览器';
      }
      if (_tunnel != tunnel) {
        return 'OpenCode WebUI 临时连接已关闭';
      }
      state = WebUiBrowserState.active(instanceId, uri);
      return null;
    } catch (_) {
      if (_tunnel == tunnel) {
        _tunnel = null;
        state = const WebUiBrowserState.idle();
      }
      await tunnel.close();
      return '无法建立 OpenCode WebUI 临时连接';
    }
  }

  String _sessionPath(String? directory, String? sessionId) {
    if (directory == null ||
        directory.isEmpty ||
        sessionId == null ||
        sessionId.isEmpty) {
      return '/';
    }
    final encodedDirectory = base64Url
        .encode(utf8.encode(directory))
        .replaceAll('=', '');
    return '/$encodedDirectory/session/${Uri.encodeComponent(sessionId)}';
  }

  Future<void> close() async {
    final tunnel = _tunnel;
    _tunnel = null;
    state = const WebUiBrowserState.idle();
    await tunnel?.close();
  }

  Future<bool> _launch(Uri uri) async {
    try {
      return await ref.read(webUiBrowserLauncherProvider)(uri);
    } catch (_) {
      return false;
    }
  }

  Future<void> _observe(GatewayWebUiTunnel tunnel) async {
    await tunnel.done;
    if (_tunnel == tunnel) {
      _tunnel = null;
      state = const WebUiBrowserState.idle();
    }
  }
}
