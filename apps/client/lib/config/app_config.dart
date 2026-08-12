/// Compile-time application configuration.
///
/// The gateway base URL is set at build time:
///
/// ```sh
/// flutter run --dart-define=GATEWAY_URL=https://gateway.internal.example.com
/// ```
class AppConfig {
  AppConfig({String? gatewayHttpBase})
      : gatewayHttpBase = gatewayHttpBase ??
            const String.fromEnvironment(
              'GATEWAY_URL',
              defaultValue: 'https://notify.example.com',
            );

  /// HTTP(S) base URL of the notification gateway.
  final String gatewayHttpBase;

  /// WebSocket endpoint derived from [gatewayHttpBase]: the `http(s)` scheme
  /// becomes `ws(s)` and the `/v1/ws` path is appended.
  ///
  /// Throws [ArgumentError] when [gatewayHttpBase] has no `http(s)` scheme,
  /// so a misconfigured `--dart-define=GATEWAY_URL` fails fast instead of
  /// producing an undialable WebSocket URI.
  String get gatewayWsBase {
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
    return '$base/v1/ws';
  }
}
