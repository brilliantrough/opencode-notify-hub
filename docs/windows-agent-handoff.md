# Windows Development Handoff

This document records the Windows-specific capabilities already integrated into
the shared `main` branch. It complements the manually synchronized
`docs/project_memory/current-state.md`, which is the current operational
handoff and must never contain credentials.

## Shared Branch

- Repository: `git@github.com:brilliantrough/opencode-notify-hub.git`
- Canonical development branch: `main`
- Windows parity was merged by `6888a83`.
- Windows typography was fixed by `e7daadd`.
- Accepted ingest requests update key usage metadata in `fff513c`.
- Linux and Windows development are sequential continuations of this shared
  history, not independent implementations.

Before Windows work:

```powershell
git fetch origin
git switch main
git pull --ff-only
git status --short
git log --oneline -10
```

Read the latest commits and project memory before editing. If the maintainer
explicitly starts concurrent Linux and Windows work, use separate branches and
wait for the requested integration step before pushing the combined result.

## Toolchain

The verified Windows development node uses:

```text
Node.js   22.x
pnpm      9.15.0
Flutter   3.44.9 stable
Dart      3.12.x
```

Windows native builds require Visual Studio with Desktop development with C++,
the MSVC toolchain, Windows SDK, CMake/Ninja, and Windows Developer Mode for
plugin symlinks.

## Integrated Windows Behavior

The shared client includes:

- tray left-click restore and right-click native menu handling;
- close-to-tray with process-lifetime tray listeners;
- the real multi-size Windows application ICO;
- notification clicks that restore and focus the window;
- launch-at-startup OS state read-back and quoted executable paths;
- secure credential cleanup that attempts every field;
- local sign-out even when secure storage cleanup reports an error;
- `Microsoft YaHei UI` typography with Windows fallbacks;
- long-text and desktop display-scale widget coverage;
- Windows CI analysis, tests, release build, and artifact upload.

The Gateway also records `ingest_keys.last_used_at` after an authenticated event
is accepted, including accepted deduplicated requests. Updates are scoped to the
active key and owner, only move forward, and are best-effort after dispatch so a
metadata failure does not cause event redelivery. No database migration is
required because the column already exists.

## Verification

Run from the repository root:

```powershell
corepack enable
pnpm install --frozen-lockfile
flutter pub get
pnpm typecheck
pnpm test
pnpm build
flutter analyze

Set-Location apps\client
flutter test
flutter build windows --release `
  --dart-define=GATEWAY_URL=https://notify.example.com

Set-Location ..\..\packages\notify_api
dart test
```

Distribute the entire
`apps\client\build\windows\x64\runner\Release\` directory, not only
`client.exe`.

Native tray, notification, sleep/resume, Explorer restart, autostart restart,
credential inspection, and DPI behavior still require the manual checks in
`docs/e2e-verification.md`; unit tests do not prove those OS behaviors.

## Environment-Only Drift

Windows Flutter commands may rewrite hosted registry URLs in `pubspec.lock` and
line endings in generated Linux/Windows registrant files. Inspect the worktree
before committing and restore only environment-generated drift that is not part
of the task. Never use a blanket reset or `git add .` without reviewing every
path.

## Handoff

After verification:

```powershell
git fetch origin
git status --short
git diff
git log --oneline -10
git add <intended-files-only>
git commit -m "<focused message>"
git push origin main
```

Update `docs/project_memory/current-state.md` with the pushed SHA, completed
work, exact verification evidence, and remaining platform checks. Do not record
passwords, tokens, ingest secrets, Firebase service-account data, production
logs, or private keys.
