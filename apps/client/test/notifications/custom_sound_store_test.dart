import 'dart:io';

import 'package:client/notifications/custom_sound_store.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  late Directory temporary;
  late Directory support;

  setUp(() async {
    temporary = await Directory.systemTemp.createTemp('notify-sound-test-');
    support = Directory(path.join(temporary.path, 'support'));
  });

  tearDown(() async {
    if (await temporary.exists()) {
      await temporary.delete(recursive: true);
    }
  });

  test(
    'copies a selected sound into the application support directory',
    () async {
      final source = File(path.join(temporary.path, 'Gentle Bell.WAV'));
      await source.writeAsBytes([1, 2, 3, 4]);
      final store = FileSystemCustomSoundStore(
        pickFile: () async => XFile(source.path, name: 'Gentle Bell.WAV'),
        supportDirectory: () async => support,
      );

      final imported = await store.importSound();

      expect(imported, isNotNull);
      expect(imported!.displayName, 'Gentle Bell');
      expect(path.basename(imported.localPath), 'custom.wav');
      expect(await File(imported.localPath).readAsBytes(), [1, 2, 3, 4]);
    },
  );

  test('returns null when the native picker is cancelled', () async {
    final store = FileSystemCustomSoundStore(
      pickFile: () async => null,
      supportDirectory: () async => support,
    );

    expect(await store.importSound(), isNull);
  });

  test('rejects unsupported formats before copying', () async {
    final source = File(path.join(temporary.path, 'alert.txt'));
    await source.writeAsString('not audio');
    final store = FileSystemCustomSoundStore(
      pickFile: () async => XFile(source.path),
      supportDirectory: () async => support,
    );

    await expectLater(
      store.importSound(),
      throwsA(isA<CustomSoundImportException>()),
    );
    expect(await support.exists(), isFalse);
  });

  test('rejects files larger than the configured limit', () async {
    final source = File(path.join(temporary.path, 'alert.wav'));
    await source.writeAsBytes([1, 2, 3, 4, 5]);
    final store = FileSystemCustomSoundStore(
      pickFile: () async => XFile(source.path),
      supportDirectory: () async => support,
      maxBytes: 4,
    );

    await expectLater(
      store.importSound(),
      throwsA(isA<CustomSoundImportException>()),
    );
  });
}
