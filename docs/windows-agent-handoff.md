# Windows Client Agent Handoff

This document records the Windows development node prepared for the next agent
working on the Flutter desktop client. It describes the current checkout,
toolchain, verified commands, local changes, and the required handoff boundary.

## Current Checkout

- Repository: `git@github.com:brilliantrough/opencode-notify-hub.git`
- Working directory: `D:\Linewrite\github_repo\opencode-notify-hub`
- Branch: `windows/dev-node`
- Base commit: `be34a01` (`origin/main`)
- The branch contains completed Windows parity work that is ready for review
  and a focused commit; it has not been pushed yet.
- Do not work directly on `main`; keep Windows work on this branch or create a
  dedicated task branch from it.

The remote `main` is the clean public baseline. Do not use an old Linux clone
as the source for a new Windows checkout.

## Installed Toolchain

The following tools are installed and were verified on this Windows host:

```text
fnm       1.39.0
Node.js   v22.23.2
npm       10.9.8
Corepack  0.34.6
pnpm      9.15.0
Flutter   3.44.9 stable
Dart      3.12.2
Git       2.53.0
```

Flutter SDK path:

```text
D:\Linewrite\dev-sdk\flutter\flutter
```

The Flutter SDK is a Git checkout detached at the official `3.44.9` tag. Do
not use the VS Code Flutter upgrade action, because it may move the SDK back to
the latest `stable` release.

Windows native prerequisites are available:

- Visual Studio with Desktop development with C++;
- MSVC toolchain;
- Windows SDK;
- CMake/Ninja through the Flutter Windows toolchain;
- Windows Developer Mode, required for plugin symlinks.

`flutter doctor -v` reported Android command-line tools/licenses and Maven
network warnings. Those are not blockers for Windows desktop development.

## Bootstrap And Verification

Open a new PowerShell after installing or changing PATH entries. From the
repository root:

```powershell
fnm current
node --version
corepack enable
pnpm --version

pnpm install --frozen-lockfile
flutter pub get
flutter analyze
```

TypeScript checks:

```powershell
pnpm typecheck
```

Flutter client tests:

```powershell
Set-Location apps\client
flutter test
```

Generated Dart API tests:

```powershell
Set-Location packages\notify_api
dart test
```

The current Windows verification passed all `315` Flutter client tests,
`flutter analyze`, `pnpm typecheck`, and the generated API tests.

## Windows Build

Use a staging or development Gateway URL. Do not put production credentials,
ingest keys, Firebase service accounts, or signing keys in the repository or
the agent prompt.

```powershell
Set-Location apps\client
flutter build windows --release `
  --dart-define=GATEWAY_URL=https://notify.example.com
```

The complete unsigned release bundle is:

```text
apps\client\build\windows\x64\runner\Release\
```

The executable is generated at:

```text
apps\client\build\windows\x64\runner\Release\client.exe
```

The release build was verified successfully on this machine. The linker may
print third-party Firebase PDB or MSVC section warnings; they do not prevent
the build, but they should remain visible in verification notes.

## Changes Already Prepared

The Windows baseline includes these portability fixes:

1. `apps/client/test/devices/device_identity_test.dart` no longer assumes the
   test host is Linux. It derives the expected desktop platform and hostname
   behavior from the current Windows/Linux host.
2. `packages/plugin/scripts/smoke-dist.mjs` converts the generated bundle path
   with `pathToFileURL()` before importing it, fixing Node ESM loading of
   Windows absolute paths.

The plugin build and smoke test passed after these fixes:

```text
runtime: node v22.23.2
exports: ["default"]
hooks: ["dispose", "event"]
stubbedFetchCalls: 2
credentialLeak: false
```

The Windows parity implementation also includes:

- Windows tray left-click and right-click callback handling;
- close-to-tray and restore/focus coverage;
- a real 10-image Windows ICO bundled for the tray;
- launch-at-startup state read-back and quoted paths containing spaces;
- resilient secure credential deletion and unconditional local sign-out;
- 100%, 125%, 150%, and 200% long-text widget coverage;
- a `windows-latest` CI job that analyzes, tests, builds, and uploads the
  release bundle;
- explicit Windows manual checks in `docs/e2e-verification.md`.

Current automated verification passed `326` Flutter client tests,
`flutter analyze`, `pnpm typecheck`, generated API tests, plugin distribution
smoke tests, and a Windows release build. The bundled tray ICO was verified at
`33772` bytes with `10` image entries.

## Generated Or Environment-Only Changes

The working tree also contains changes created while preparing and verifying
the Windows node:

- `pubspec.lock`: hosted registry URLs changed from
  `https://pub.flutter-io.cn` to `https://pub.dev`; package versions and
  checksums did not change.
- `apps/client/windows/flutter/*`: Flutter generated plugin registration files.
- `apps/client/linux/flutter/*`: Flutter generated plugin registration files
  with Windows line-ending effects.

Inspect these files before committing. Do not blindly run `git add .`. If the
task does not intentionally change dependency provenance or generated plugin
registrants, restore only these environment-generated files before committing:

```powershell
git restore pubspec.lock
git restore apps/client/linux/flutter
git restore apps/client/windows/flutter
```

Do not restore the intended source, test, CI, or documentation changes listed
above.

## Recommended Next Step

The provisioning and automated Windows parity work are complete. Before
claiming the P1 exit criteria, run the unchecked Windows rows in
`docs/e2e-verification.md` against an isolated staging gateway. Sleep/resume,
Explorer restart, notification shortcut relocation, real autostart restart,
credential inspection, and native DPI rendering require OS interaction and
must not be marked complete from unit tests alone.

After the intended changes are verified:

```powershell
git status --short
git diff
git diff --cached
git add <intended-files-only>
git commit -m "feat(windows): establish Windows client baseline"
git push -u origin windows/dev-node
```

The roadmap's next Windows priorities are native tray behavior, a valid
multi-size Windows tray icon, notification identity/click handling, close-to-
tray behavior, autostart, secure credential storage, and DPI/long-text visual
verification. See `ROADMAP.md` and `docs/e2e-verification.md` before selecting
the next focused task.
