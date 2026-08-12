import 'package:audioplayers/audioplayers.dart';

/// Plays the bundled notification alert sound.
///
/// The underlying [AudioPlayer] is injectable so tests can verify playback
/// without touching the audio platform channel.
class SoundPlayer {
  SoundPlayer({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  /// Path (within `assets/`) of the bundled alert sound.
  static const String alertAsset = 'sounds/alert.wav';

  final AudioPlayer _player;

  /// Plays the alert sound once.
  Future<void> playAlert() => _player.play(AssetSource(alertAsset));

  /// Releases the underlying player.
  Future<void> dispose() => _player.dispose();
}
