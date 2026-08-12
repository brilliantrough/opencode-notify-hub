import 'package:audioplayers/audioplayers.dart';
import 'package:client/notifications/sound_player.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAudioPlayer extends Mock implements AudioPlayer {}

class FakeSource extends Fake implements Source {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeSource());
  });

  group('SoundPlayer', () {
    test('exposes the bundled alert asset path', () {
      expect(SoundPlayer.alertAsset, 'sounds/alert.wav');
    });

    test('playAlert plays the bundled alert asset', () async {
      final player = MockAudioPlayer();
      when(() => player.play(any())).thenAnswer((_) async {});
      final soundPlayer = SoundPlayer(player: player);

      await soundPlayer.playAlert();

      final captured =
          verify(() => player.play(captureAny())).captured.single
              as AssetSource;
      expect(captured.path, SoundPlayer.alertAsset);
    });

    test('dispose disposes the underlying player', () async {
      final player = MockAudioPlayer();
      when(() => player.dispose()).thenAnswer((_) async {});
      final soundPlayer = SoundPlayer(player: player);

      await soundPlayer.dispose();

      verify(() => player.dispose()).called(1);
    });
  });
}
