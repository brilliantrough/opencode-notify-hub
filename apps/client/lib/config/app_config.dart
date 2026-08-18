/// Network configuration derived from the persisted server selection.
class AppConfig {
  const AppConfig({required this.gatewayHttpBase});

  /// HTTP(S) base URL of the notification gateway.
  final String gatewayHttpBase;

  /// WebSocket endpoint derived from [gatewayHttpBase]: the `http(s)` scheme
  /// becomes `ws(s)` and the `/v1/ws` path is appended.
  ///
  /// Throws [ArgumentError] when [gatewayHttpBase] has no `http(s)` scheme,
  /// so an invalid server selection fails fast instead of producing an
  /// undialable WebSocket URI.
  String get gatewayWsBase {
    return _webSocketEndpoint('/v1/ws');
  }

  /// Temporary OpenCode WebUI tunnel endpoint.
  String get gatewayWebUiWsBase => _webSocketEndpoint('/v1/webui/ws');

  String _webSocketEndpoint(String path) {
    var base = gatewayHttpBase;
    if (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    if (base.startsWith('https://')) {
      base = 'wss://${base.substring('https://'.length)}';
    } else if (base.startsWith('http://')) {
      base = 'ws://${base.substring('http://'.length)}';
    } else {
      throw ArgumentError.value(
        gatewayHttpBase,
        'gatewayHttpBase',
        'must start with http:// or https://',
      );
    }
    return '$base$path';
  }
}
