import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'alert_sound.dart';

final soundPreviewPlayerProvider = Provider<SoundPlayer>((ref) {
  final player = SoundPlayer();
  ref.onDispose(() => unawaited(player.dispose()));
  return player;
});

/// Plays bundled and locally imported notification sounds.
///
/// The underlying [AudioPlayer] is injectable so tests can verify playback
/// without touching the audio platform channel.
class SoundPlayer {
  SoundPlayer({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  Future<void> play(AlertSound sound) => switch (sound) {
    BundledAlertSound() => _player.play(
      AssetSource(sound.assetPath),
      volume: sound.volume,
    ),
    CustomAlertSound() => _player.play(
      DeviceFileSource(sound.localPath),
      volume: 1,
    ),
  };

  /// Releases the underlying player.
  Future<void> dispose() => _player.dispose();
}
