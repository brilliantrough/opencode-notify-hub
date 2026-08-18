/// A notification sound that can be selected by the user.
sealed class AlertSound {
  const AlertSound({required this.id, required this.displayName});

  final String id;
  final String displayName;
}

/// One sound shipped in the application bundle.
final class BundledAlertSound extends AlertSound {
  const BundledAlertSound({
    required super.id,
    required super.displayName,
    required this.sourceName,
    required this.assetPath,
    this.volume = 1,
  });

  final String sourceName;
  final String assetPath;

  /// Playback gain used to keep bundled sounds at a comparable loudness.
  final double volume;
}

/// One user-selected sound copied into the application's support directory.
final class CustomAlertSound extends AlertSound {
  const CustomAlertSound({required super.displayName, required this.localPath})
    : super(id: customAlertSoundId);

  final String localPath;

  @override
  bool operator ==(Object other) =>
      other is CustomAlertSound &&
      other.displayName == displayName &&
      other.localPath == localPath;

  @override
  int get hashCode => Object.hash(displayName, localPath);
}

const String customAlertSoundId = 'custom';

const BundledAlertSound softChimeAlertSound = BundledAlertSound(
  id: 'soft_chime',
  displayName: '柔和和弦',
  sourceName: 'OpenCode Notify',
  assetPath: 'sounds/soft_chime.wav',
);

const List<BundledAlertSound> bundledAlertSounds = [
  softChimeAlertSound,
  BundledAlertSound(
    id: 'ocean_message',
    displayName: '海洋消息',
    sourceName: 'KDE Plasma Ocean',
    assetPath: 'sounds/ocean_message.wav',
    volume: 0.25,
  ),
  BundledAlertSound(
    id: 'ocean_complete',
    displayName: '海洋完成',
    sourceName: 'KDE Plasma Ocean',
    assetPath: 'sounds/ocean_complete.wav',
    volume: 0.3,
  ),
  BundledAlertSound(
    id: 'ocean_information',
    displayName: '海洋提示',
    sourceName: 'KDE Plasma Ocean',
    assetPath: 'sounds/ocean_information.wav',
    volume: 0.25,
  ),
  BundledAlertSound(
    id: 'ocean_email',
    displayName: '海洋清音',
    sourceName: 'KDE Plasma Ocean',
    assetPath: 'sounds/ocean_email.wav',
    volume: 0.2,
  ),
];

bool isBundledAlertSoundId(String id) =>
    bundledAlertSounds.any((sound) => sound.id == id);

/// Resolves persisted settings, falling back when an old or incomplete value
/// can no longer be selected.
AlertSound resolveAlertSound(String id, CustomAlertSound? customSound) {
  if (id == customAlertSoundId && customSound != null) {
    return customSound;
  }
  for (final sound in bundledAlertSounds) {
    if (sound.id == id) {
      return sound;
    }
  }
  return softChimeAlertSound;
}
