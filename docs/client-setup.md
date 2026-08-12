# Flutter Client Build Setup

The Flutter client lives in `apps/client` and uses the root pub workspace with
the generated `packages/notify_api` package.

## Toolchain

- Flutter 3.44.9 stable (verified; includes Dart 3.12.2).
- Dart compatible with the workspace constraint `^3.8.0`.
- Android SDK 36 and Java 17 for Android builds.
- Visual Studio with **Desktop development with C++** for Windows builds.
- A Linux host for Linux builds and a Windows host for Windows builds; Flutter
  desktop targets are not cross-compiled.

Install Flutter using the official instructions and confirm:

```bash
flutter doctor -v
flutter pub get
```

China-based contributors may optionally configure the official community
mirror for their shell; it is not required by the project:

```bash
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
export PUB_HOSTED_URL=https://pub.flutter-io.cn
```

## Gateway URL

The client has no runtime server picker. Set the gateway base URL at build time:

```bash
--dart-define=GATEWAY_URL=https://notify.example.com
```

Omitting it compiles the documentation placeholder
`https://notify.example.com`, which is not a running service.

## Linux

Install native dependencies on Debian/Ubuntu:

```bash
sudo apt-get update
sudo apt-get install -y clang cmake ninja-build pkg-config \
  libgtk-3-dev libsecret-1-dev \
  libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
  libnotify-dev libayatana-appindicator3-dev
```

Build a release bundle:

```bash
cd apps/client
flutter build linux --release \
  --dart-define=GATEWAY_URL=https://notify.example.com
```

The complete portable bundle is
`apps/client/build/linux/x64/release/bundle/`. Start `client` from that
directory and distribute the whole directory, not the executable alone.

## Windows

On a Windows host with Visual Studio and Flutter desktop support enabled:

```powershell
cd apps/client
flutter build windows --release `
  --dart-define=GATEWAY_URL=https://notify.example.com
```

Distribute the complete `build\windows\x64\runner\Release\` directory. Test the
tray, desktop notification permission, sound, autostart, and WebSocket reconnect
on every supported Windows version before publishing it.

## Android

### Development build

```bash
cd apps/client
flutter build apk --debug \
  --dart-define=GATEWAY_URL=https://notify.example.com
```

Output: `build/app/outputs/flutter-apk/app-debug.apk`.

### Firebase configuration

The repository intentionally contains placeholder Firebase options. Before
testing background/lock-screen delivery:

1. Create a Firebase project and Android app for
   `dev.opencodenotify.client`.
2. Install FlutterFire CLI and run `flutterfire configure` from `apps/client`.
3. Add the generated `android/app/google-services.json` locally; never commit a
   service-account private key.
4. Configure the gateway with a service-account JSON from the same Firebase
   project.
5. Rebuild and reinstall the app.

### Release signing

The current Flutter template uses the debug signing key for local release-mode
runs. **Do not distribute that APK.** Before publishing, configure a private
release keystore through `android/key.properties` or CI secrets, remove the
debug signing fallback, back up the signing key securely, and verify the APK or
AAB signature.

Typical release commands after signing is configured:

```bash
flutter build apk --release \
  --dart-define=GATEWAY_URL=https://notify.example.com
flutter build appbundle --release \
  --dart-define=GATEWAY_URL=https://notify.example.com
```

## Verification

From the repository root:

```bash
flutter pub get
flutter analyze
(cd apps/client && flutter test)
(cd packages/notify_api && dart test)
```

See [testing.md](testing.md) for integration and E2E procedures.

## Build troubleshooting

- If an interrupted Gradle build leaves a corrupt cached POM, remove only the
  reported entry under `~/.gradle/caches/modules-2/files-2.1/io.flutter/` and
  retry.
- If Linux CMake cached missing libraries, remove `apps/client/build/linux` and
  rebuild after installing dependencies.
- If Android background notifications fail, verify client and gateway Firebase
  project ids match; foreground WebSocket success does not prove FCM works.
