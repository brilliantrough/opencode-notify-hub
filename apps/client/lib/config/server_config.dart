import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_config.dart';

class ServerConfig {
  const ServerConfig._(this.gatewayHttpBase);

  static const defaultGatewayHttpBase = 'https://notify.pezayo.com';

  final String gatewayHttpBase;

  static ServerConfig parse(String input) {
    var candidate = input.trim();
    if (candidate.isEmpty) {
      throw const FormatException('请输入服务器地址');
    }
    if (!candidate.contains('://')) {
      candidate = 'https://$candidate';
    }

    final uri = Uri.tryParse(candidate);
    if (uri == null || uri.host.isEmpty) {
      throw const FormatException('请输入有效的服务器地址');
    }
    if (uri.userInfo.isNotEmpty ||
        (uri.path.isNotEmpty && uri.path != '/') ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const FormatException('服务器地址不能包含账号、路径、查询或片段');
    }

    final loopback =
        uri.host == 'localhost' || uri.host == '127.0.0.1' || uri.host == '::1';
    if (uri.scheme != 'https' && !(uri.scheme == 'http' && loopback)) {
      throw const FormatException('服务器必须使用 HTTPS；本机调试可使用 HTTP');
    }

    return ServerConfig._(uri.origin);
  }

  static ServerConfig fromStored(String? value) {
    if (value == null) {
      return const ServerConfig._(defaultGatewayHttpBase);
    }
    try {
      return parse(value);
    } on FormatException {
      return const ServerConfig._(defaultGatewayHttpBase);
    }
  }
}

abstract interface class ServerConfigStore {
  String? read();

  Future<void> write(String gatewayHttpBase);
}

class MemoryServerConfigStore implements ServerConfigStore {
  MemoryServerConfigStore([this._value]);

  String? _value;

  @override
  String? read() => _value;

  @override
  Future<void> write(String gatewayHttpBase) async {
    _value = gatewayHttpBase;
  }
}

class SharedPreferencesServerConfigStore implements ServerConfigStore {
  SharedPreferencesServerConfigStore(this._preferences);

  static const preferenceKey = 'gateway_http_base_v1';

  final SharedPreferences _preferences;

  @override
  String? read() => _preferences.getString(preferenceKey);

  @override
  Future<void> write(String gatewayHttpBase) =>
      _preferences.setString(preferenceKey, gatewayHttpBase);
}

final serverConfigStoreProvider = Provider<ServerConfigStore>(
  (ref) => MemoryServerConfigStore(),
);

final serverConfigProvider =
    NotifierProvider<ServerConfigController, ServerConfig>(
      ServerConfigController.new,
    );

class ServerConfigController extends Notifier<ServerConfig> {
  @override
  ServerConfig build() =>
      ServerConfig.fromStored(ref.watch(serverConfigStoreProvider).read());

  Future<bool> setServer(String input) async {
    final next = ServerConfig.parse(input);
    if (next.gatewayHttpBase == state.gatewayHttpBase) {
      return false;
    }
    await ref.read(serverConfigStoreProvider).write(next.gatewayHttpBase);
    state = next;
    return true;
  }
}

final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig(
    gatewayHttpBase: ref.watch(serverConfigProvider).gatewayHttpBase,
  ),
);
