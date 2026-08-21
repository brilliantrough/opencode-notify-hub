import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Android keep-alive bridge: a `specialUse` foreground service plus the
/// battery-optimization exemption request.
///
/// Every method degrades to a no-op (`false`) where the platform channel is
/// absent — desktop platforms and tests — so callers need no platform guards.
class KeepAliveBridge {
  KeepAliveBridge({MethodChannel? channel})
    : _channel =
          channel ??
          const MethodChannel('dev.opencodenotify.client/keep_alive');

  /// The shared instance bound to the real platform channel.
  static final KeepAliveBridge instance = KeepAliveBridge();

  final MethodChannel _channel;

  /// Starts the foreground service. Returns whether the platform accepted it.
  Future<bool> start() => _invokeBool('start');

  /// Stops the foreground service.
  Future<bool> stop() => _invokeBool('stop');

  /// Whether this package is exempt from battery optimization.
  Future<bool> isIgnoringBatteryOptimizations() =>
      _invokeBool('isIgnoringBatteryOptimizations');

  /// Opens the system surface asking to exempt this package from battery
  /// optimization. Returns whether any settings surface could be opened.
  Future<bool> requestIgnoreBatteryOptimizations() =>
      _invokeBool('requestIgnoreBatteryOptimizations');

  Future<bool> _invokeBool(String method) async {
    try {
      return await _channel.invokeMethod<bool>(method) ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}

/// Overridable seam; tests inject a fake here.
final keepAliveProvider = Provider<KeepAliveBridge>((ref) => KeepAliveBridge.instance);
