import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'alert_sound.dart';

abstract class CustomSoundStore {
  /// Opens the native picker and saves the selected file locally. Returns
  /// `null` when the user cancels the picker.
  Future<CustomAlertSound?> importSound();
}

final customSoundStoreProvider = Provider<CustomSoundStore>(
  (ref) => FileSystemCustomSoundStore(),
);

class CustomSoundImportException implements Exception {
  const CustomSoundImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

typedef SoundFilePicker = Future<XFile?> Function();
typedef SupportDirectoryProvider = Future<Directory> Function();

class FileSystemCustomSoundStore implements CustomSoundStore {
  FileSystemCustomSoundStore({
    SoundFilePicker? pickFile,
    SupportDirectoryProvider? supportDirectory,
    this.maxBytes = defaultMaxBytes,
  }) : _pickFile = pickFile ?? _openSoundFile,
       _supportDirectory = supportDirectory ?? getApplicationSupportDirectory;

  static const int defaultMaxBytes = 10 * 1024 * 1024;
  static const Set<String> supportedExtensions = {
    '.wav',
    '.mp3',
    '.ogg',
    '.oga',
  };

  final SoundFilePicker _pickFile;
  final SupportDirectoryProvider _supportDirectory;
  final int maxBytes;

  static Future<XFile?> _openSoundFile() => openFile(
    acceptedTypeGroups: const [
      XTypeGroup(label: '音频文件', extensions: ['wav', 'mp3', 'ogg', 'oga']),
    ],
  );

  @override
  Future<CustomAlertSound?> importSound() async {
    final selected = await _pickFile();
    if (selected == null) {
      return null;
    }

    final extension = path.extension(selected.path).toLowerCase();
    if (!supportedExtensions.contains(extension)) {
      throw const CustomSoundImportException('请选择 WAV、MP3、OGG 或 OGA 音频文件');
    }

    final source = File(selected.path);
    final length = await source.length();
    if (length == 0) {
      throw const CustomSoundImportException('所选音频文件为空');
    }
    if (length > maxBytes) {
      throw const CustomSoundImportException('自定义提示音不能超过 10 MiB');
    }

    final support = await _supportDirectory();
    final directory = Directory(path.join(support.path, 'notification_sounds'));
    await directory.create(recursive: true);

    final target = File(path.join(directory.path, 'custom$extension'));
    final staging = File(path.join(directory.path, '.custom$extension.tmp'));
    if (await staging.exists()) {
      await staging.delete();
    }
    await source.copy(staging.path);

    await for (final entry in directory.list()) {
      if (entry is File &&
          path.basename(entry.path).startsWith('custom.') &&
          entry.path != staging.path) {
        await entry.delete();
      }
    }
    await staging.rename(target.path);

    final name = path.basenameWithoutExtension(selected.name).trim();
    return CustomAlertSound(
      displayName: name.isEmpty ? '自定义提示音' : name,
      localPath: target.path,
    );
  }
}
