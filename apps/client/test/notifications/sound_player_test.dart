import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

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
      expect(SoundPlayer.alertAsset, 'sounds/soft_chime.wav');
    });

    test('bundled alert has a gentle attack and bounded loudness', () async {
      final stats = _readPcmWav(
        await File('assets/sounds/soft_chime.wav').readAsBytes(),
      );

      expect(stats.sampleRate, 44100);
      expect(stats.durationSeconds, inInclusiveRange(0.8, 1.4));
      expect(stats.peakDb, inInclusiveRange(-22, -10));
      expect(stats.rmsDb, inInclusiveRange(-36, -20));
      expect(stats.attack20msDb, lessThanOrEqualTo(-24));
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

({
  int sampleRate,
  double durationSeconds,
  double peakDb,
  double rmsDb,
  double attack20msDb,
})
_readPcmWav(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
  expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WAVE');

  var offset = 12;
  int? sampleRate;
  int? channels;
  int? bitsPerSample;
  int? pcmOffset;
  int? pcmLength;
  while (offset + 8 <= bytes.length) {
    final chunk = String.fromCharCodes(bytes.sublist(offset, offset + 4));
    final length = data.getUint32(offset + 4, Endian.little);
    final contentOffset = offset + 8;
    if (chunk == 'fmt ') {
      expect(data.getUint16(contentOffset, Endian.little), 1);
      channels = data.getUint16(contentOffset + 2, Endian.little);
      sampleRate = data.getUint32(contentOffset + 4, Endian.little);
      bitsPerSample = data.getUint16(contentOffset + 14, Endian.little);
    } else if (chunk == 'data') {
      pcmOffset = contentOffset;
      pcmLength = length;
      break;
    }
    offset = contentOffset + length + (length.isOdd ? 1 : 0);
  }

  expect(channels, 1);
  expect(bitsPerSample, 16);
  final rate = sampleRate!;
  final sampleCount = pcmLength! ~/ 2;
  final attackSamples = math.min(sampleCount, (rate * 0.02).round());
  var peak = 0.0;
  var attackPeak = 0.0;
  var sumSquares = 0.0;
  for (var index = 0; index < sampleCount; index++) {
    final sample =
        data.getInt16(pcmOffset! + index * 2, Endian.little).abs() / 32768;
    peak = math.max(peak, sample);
    if (index < attackSamples) {
      attackPeak = math.max(attackPeak, sample);
    }
    sumSquares += sample * sample;
  }

  double db(double amplitude) => 20 * math.log(amplitude) / math.ln10;
  return (
    sampleRate: rate,
    durationSeconds: sampleCount / rate,
    peakDb: db(peak),
    rmsDb: db(math.sqrt(sumSquares / sampleCount)),
    attack20msDb: db(attackPeak),
  );
}
