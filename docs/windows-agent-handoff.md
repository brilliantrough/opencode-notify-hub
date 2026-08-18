# Windows Development Handoff

Updated: 2026-08-18

This tracked document is the entry point for the Windows development agent.
Linux and Windows are sequential continuations of one shared branch, not
separate implementations. The previous `windows/client-parity-20260816` and
`windows/dev-node` branches are already ancestors of `main` and are retired.
Resume neither branch. Start only from a clean, fast-forwarded `main` at the
alignment SHA reported by the Linux agent in the manually synchronized project
memory.

## Safety Rules

- Do not use `git reset --hard`, `git clean`, or blanket checkout/restore.
- Do not delete `docs/project_memory/`; it is intentionally gitignored and may
  contain local handoff state.
- Never commit credentials, tokens, `.env` contents, production logs, Firebase
  service-account data, or private keys.
- Do not merge a stale local `main`. Update it with `git pull --ff-only` only.
- Do not run `integration_test/live_acceptance_test.dart` on Windows. It drives
  Linux/OpenCode processes and is not a cross-platform test.

## Reconcile The Windows Checkout

Inspect before changing anything:

```powershell
git status --short
git branch --show-current
git log --oneline -10
git stash list
git fetch origin
git rev-list --left-right --count main...origin/main
```

If the checkout has tracked or untracked work, preserve it first:

```powershell
git stash push --include-untracked -m "windows-local-before-2026-08-handoff"
git status --short
```

Ignored project memory stays in place. If `main` has local-only commits or the
following fast-forward refuses, stop and report the commit graph; do not merge,
rebase, or reset it without maintainer approval.

```powershell
git switch main
git pull --ff-only origin main
git status --short
git log --oneline -20
```

Do not immediately pop old work onto updated `main`. Inspect it first:

```powershell
git stash show --stat stash@{0}
```

If it is still needed, recover it on a separate branch:

```powershell
git switch -c windows/recover-pre-handoff
git stash pop
```

Otherwise leave the stash intact until the maintainer confirms it can be
dropped. For new Windows fixes, start from clean, updated `main`:

```powershell
git switch main
git switch -c windows/client-parity-20260818
```

## Read Before Editing

Read these in order:

1. `AGENTS.md`
2. `CONTEXT.md`
3. `docs/windows-agent-handoff.md`
4. `docs/design/remote-unblock-phase-1.md`
5. `docs/beta-evidence/upstream-plugin-gap.md`
6. `docs/client-guide.md`
7. `docs/client-setup.md`
8. `docs/e2e-verification.md`
9. local `docs/project_memory/current-state.md`, when present

Confirm the pull contains all of these files. Their absence means the pull is
incomplete and the build must not be trusted:

```powershell
Test-Path apps\client\lib\config\server_config.dart
Test-Path apps\client\lib\config\server_switcher.dart
Test-Path apps\client\lib\ui\server_settings_dialog.dart
Test-Path apps\client\assets\sounds\soft_chime.wav
Test-Path packages\notify_api\lib\src\model\command_accepted.dart
Test-Path apps\client\lib\sessions\webui_browser_controller.dart
Test-Path apps\client\lib\ui\session_prompt_page.dart
Select-String -Path apps\client\pubspec.yaml -Pattern 'url_launcher'
```

## What The Pull Delivers To Windows

The following are shared Dart, generated API, or asset changes and require no
separate Windows port:

- pending question and permission workbench with notification deep links;
- OpenCode instance presence and read-only offline interaction pages;
- `202 CommandAccepted` best-effort answer/decision flow carrying `sessionId`;
- optimistic sent state and backward-compatible pending-route 404 handling for
  older gateways;
- retryable session restore, bounded HTTP/refresh/WS connection timeouts;
- persisted runtime server selection on login and settings pages;
- server switch ordering: logout old account, persist origin, reset server-bound
  state, rebuild HTTP/token refresh/WebSocket, then log into the new server;
- portable builds with no `GATEWAY_URL` compile-time define;
- confirmed logout action in Settings;
- deferred tray initialization after the first Flutter frame;
- original gentle `soft_chime.wav` replacing the old compressed alert;
- bundled sound catalog, preview/selection persistence, and custom audio import;
- Windows native initial title `OpenCode Notify`;
- best-effort native Session prompt composer with no retry/completion promise;
- system-browser OpenCode WebUI through one client-held localhost tunnel;
- `url_launcher_windows` with no embedded WebView or WebView2 dependency;
- notification titles containing machine, directory, session, and status;
- history rows containing machine context while retaining expanded details;
- generated protocol-v2 `notify_api` models for Session prompt and WebUI control.

Production `https://notify.pezayo.com` runs gateway image
`opencode-notify-gateway:20260818-machine-webui`, deployed from the current Linux
working tree on 2026-08-18. It exposes Remote Unblock, session prompt, and WebUI
tunnel routes. The previous `6357a0c` image remains tagged
`opencode-notify-gateway:rollback-6357a0c` on the production host. Complete the
Windows-specific interactive question, permission, prompt, and browser WebUI
acceptance checks against production after installing a protocol-v2 Plugin.

## Platform Ownership Boundary

- Linux owns Contracts/OpenAPI, generated API authority, Gateway, Plugin,
  protocol evolution, production deployment, and the canonical Plugin artifact.
- Windows owns only Windows client/native integration, Windows-specific fixes,
  tests, packaging, screenshots, and acceptance evidence.
- Do not fork or edit Plugin behavior on Windows. Install the exact Linux-built
  `session-notify.js`, verify its checksum, restart OpenCode, and report any
  Windows runtime incompatibility for Linux to fix in the shared Plugin.
- Do not rewrite generated API or shared protocol files to work around a Windows
  client issue. First determine whether the problem is native Windows behavior
  or a shared defect, and stop for coordination when shared changes are needed.

## Linux Versus Windows Status

Linux has verified the shared code with TypeScript and Flutter analysis/tests,
generated-client tests, release builds, X11 integration, real OpenCode smoke,
runtime server selection, Prompt/WebUI tunnels, notification/history machine
context, and the sound catalog. No known feature requires an independent
Windows implementation after the pull; Windows work is native validation and
focused repair of observed Windows failures.

The following remain Windows-specific verification work because Linux tests
cannot prove native behavior:

- Credential Manager restore, failure, retry, logout, and account replacement;
- notification toast click -> restore/focus -> pending interaction navigation;
- close-to-tray immediately after launch and tray restore/menu behavior;
- Explorer restart recovery and autostart with a path containing spaces;
- persisted server selection and logout when switching origins;
- Dio/WS fast failure against an unreachable origin;
- `audioplayers_windows` playback quality for `soft_chime.wav`;
- system-browser WebUI launch, localhost loading, reopen, and tunnel teardown;
- sleep/resume, display scaling, long Chinese text, and clean-machine packaging.

## Toolchain And Automated Verification

Expected toolchain:

```text
Node.js   22.x
pnpm      9.15.0
Flutter   3.44.9 stable
Dart      3.12.x
```

Visual Studio must include Desktop development with C++, MSVC, a Windows SDK,
CMake/Ninja, and Developer Mode for plugin symlinks.

Run from the repository root in PowerShell:

```powershell
$env:PUB_HOSTED_URL = "https://pub.flutter-io.cn"
$env:FLUTTER_STORAGE_BASE_URL = "https://storage.flutter-io.cn"

corepack enable
pnpm install --frozen-lockfile
flutter pub get
pnpm docs:check
pnpm typecheck
pnpm test
pnpm build
flutter analyze

Set-Location apps\client
flutter test
flutter test integration_test\desktop_flow_test.dart -d windows
flutter build windows --release

Set-Location ..\..\packages\notify_api
dart test
```

Distribute and test the entire
`apps\client\build\windows\x64\runner\Release\` directory, not only
`client.exe`. After the commands, inspect `git status --short`; do not commit
registry URL changes, line-ending churn, generated plugin registrants, or other
environment-only drift without understanding each hunk.

## Manual Windows Acceptance Tasks

1. Cold launch: the window appears promptly with title `OpenCode Notify`.
2. Stored account: successful restore reaches Home; unreachable server shows
   the retryable restore-failure page; retry and "use another account" work.
3. Runtime server: login and Settings show the selected origin; HTTPS and
   loopback HTTP validate correctly; a changed server logs out, persists across
   restart, and requires the account from the new server.
4. Production compatibility: `https://notify.pezayo.com` restores the account,
   pending interactions, instance presence, and protocol-v2 control state.
5. New gateway: trigger a real question and permission; toast clicks open the
   correct page; answer/decision shows optimistic sent state and does not block
   the OpenCode turn. Send a simple native prompt and confirm it is admitted by
   the intended OpenCode Session without retry or completion claims.
6. Offline/competition: an offline instance opens read-only; a request handled
   elsewhere shows the handled-elsewhere state and cannot be submitted twice.
7. Tray: close hides, left click restores, right click opens the menu, pause
   updates, and exit terminates. Repeat immediately after launch.
8. Sound: preview and select every bundled sound, restart and confirm the
   selection persists, then import a synthetic WAV/MP3 and repeat. Confirm each
   notification plays exactly one selected sound; disabling sound must leave
   notifications visible but mute. Verify the native file picker and packaged
   custom-file playback from the complete portable bundle.
9. Lifecycle: sleep/resume reconnects once; Explorer restart does not leave an
   unusable process; autostart launches the complete bundle.
10. Display: test 100%, 150%, and 200% scaling plus long Chinese interaction
    text without clipping or overlapping controls.
11. Browser WebUI: launch the system default browser, load the localhost OpenCode
    UI, reopen the same tunnel, close it from Home, and verify logout/app exit
    invalidate the URL. Confirm no WebView2 installation is requested.
12. Context: confirm Windows notifications and History rows visibly include the
    machine name, while expanded History retains the complete detail table.

Record each result in local `docs/project_memory/current-state.md` and update
the Windows rows in `docs/e2e-verification.md` when evidence is complete.

## Returning Windows Work

Keep Windows fixes focused on observed Windows failures. Before asking to
integrate:

```powershell
git status --short
git diff --check
git diff --stat main...HEAD
git log --oneline main..HEAD
```

Return exact automated and manual results, sanitized screenshots for the
machine-aware notification/History and browser WebUI flows, remaining risks,
and SHA-256 values for `client.exe`, `data/app.so`, native notification DLLs,
and the complete Release archive. Include the branch SHA and the exact command
the Linux agent should run to inspect it.

Commit only intended files on the Windows branch. Do not push or merge back to
`main` until the maintainer explicitly requests it and the complete Windows
verification evidence is recorded.
