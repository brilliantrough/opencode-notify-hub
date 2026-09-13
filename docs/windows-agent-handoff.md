# Windows Development Handoff

Updated: 2026-09-13

## 2026-09-13 远程会话入口交接（当前任务）

- 本轮代码随本交接文档提交到 `main`；对齐点以维护者转发的 Linux Agent prompt 中完整 SHA 为准，`ac2aba0` 及下文 8 月 SHA 仅为历史。
- 当前任务：拉取指定 SHA，运行与本轮改动相关的窄范围检查，构建并打包完整 Windows Release 目录；最终 UI/休眠验收由维护者执行。Linux 已通过本轮 60 项针对性检查、Flutter 静态分析、Linux Release 构建及文档链接检查。
- `docs/project_memory/` 被 Git 忽略，不随 pull 同步；本节和交接 prompt 已包含开工所需信息，不要求先传记忆文件。补充历史时可手动复制 Linux 状态文件，保留 Windows 自己的状态文件；旧记忆不能覆盖本轮指定 SHA 和已确认的任务。
- idle/历史会话发现、搜索、固定、缓存、会话深链接、多实例独立隧道和续认证都在共享 Dart 与生成 API 中，无需另写 Windows 实现。
- 后续轻量体验改动也在共享 Dart：本机密钥重复查看/补录、Bash/PowerShell 配置导出与机器名填写、搜索清空、连接重开/复制、设备重命名和 Ctrl+Enter 发送。复用已有 flutter_secure_storage，需 Windows 验证原生密钥持久化和剪贴板。
- Windows 保持系统浏览器与关闭到托盘；托盘“退出”先关闭全部本地隧道。窄窗口或放大字号时会话操作移到标题下方。
- `windows/runner/flutter_window.cpp` 新增 `WM_POWERBROADCAST/PBT_APMRESUMEAUTOMATIC` → `dev.opencodenotify.client/power` 的 `resume` 消息；共享代码唤醒后重建远端 socket，保留本地 HTTP 端口，不重放写请求。
- 新增原生唤醒入口仅完成源码适配；本轮未编译 Windows、未进行 Windows UI 或休眠验收。后续构建完整 Release 目录，由维护者确认 cold start idle 会话、托盘常驻、多会话、多实例、休眠恢复与退出清理。
- Gateway 已部署 `opencode-notify-gateway:20260913-remote-access`，公网健康检查通过。Plugin 仍需安装本轮 Linux 构建并重启 OpenCode，Gateway 更新本身不会替换各机器上的 Plugin。

This tracked document is the entry point for the Windows development agent.
Linux and Windows are sequential continuations of one shared branch, not
separate implementations. The previous `windows/client-parity-20260816` and
`windows/dev-node` branches are already ancestors of `main` and are retired.
Resume neither branch. Start only from a clean, fast-forwarded `main` at the
alignment SHA reported in the current Linux agent handoff prompt. Manually
synchronized `docs/project_memory/linux-current-state.md` is optional history.

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
git stash push --include-untracked -m "windows-local-before-20260913-handoff"
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
git switch -c windows/client-parity-20260913
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
9. local `docs/project_memory/linux-current-state.md` and
   `docs/project_memory/windows-current-state.md`, when present

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
- system-browser OpenCode WebUI through independent client-held localhost tunnels;
- `url_launcher_windows` with no embedded WebView or WebView2 dependency;
- notification titles containing machine, directory, session, and status;
- history rows containing machine context while retaining expanded details;
- generated protocol-v2 `notify_api` models for Session prompt and WebUI control.
- V1 `prompt_async` Session control for the `opencode --port` TUI/WebUI agent
  loop; the V2 input-admission endpoint is not used for native prompt control.
- Completed short Sessions are retained from terminal events even when no
  heartbeat arrived first, so the client can open their Session WebUI.
- WebUI Session links carry the encoded directory and Session ID. The Plugin
  adds the directory query to OpenCode API requests, streams SSE directly, and
  the client keeps each local HTTP handler alive until its response ends.
- OpenCode instances are grouped by machine with online/total counts. Offline
  records can be forgotten individually or per machine and reappear after a
  Plugin reconnect; production now contains the matching Gateway route.
- Notification History is device-local SQLite, retains the newest 10,000 rows,
  updates live, and supports 20/30/50/100-row pages. The application does not
  automatically migrate the previous JSON value; use the external converter
  under `apps/client/tool/` when legacy rows must be retained.

Historical deployment (2026-08-19, superseded by the image at the top of this
document): production `https://notify.pezayo.com` ran gateway image
`opencode-notify-gateway:a9a43ac`, built from canonical commit
`a9a43acaea749bad7610f0f6baeae9ef21151300` and deployed on 2026-08-19. It
exposes Remote Unblock, session prompt, WebUI tunnel, and
`DELETE /v1/instances/{instanceId}` routes. The previous
`opencode-notify-gateway:20260818-machine-webui` image and pre-deploy Compose file
remain on the production host for rollback. Complete the Windows-specific
interactive question, permission, prompt, browser WebUI, and offline-instance
deletion acceptance checks against production after installing a protocol-v2
Plugin.

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

The Linux shared feature baseline through
`a9a43acaea749bad7610f0f6baeae9ef21151300` contains the Windows parity merge
plus the shared remote control, history, instance cleanup, and group-lifecycle
fixes. Use the newer final alignment SHA recorded in the synchronized Linux
memory, which also includes this handoff update. Linux has verified the shared
code with TypeScript and Flutter analysis/tests, generated-client tests, release
builds, X11 integration, real OpenCode smoke, runtime server selection,
Prompt/WebUI tunnels, notification/history machine context, and the sound
catalog. No known feature requires an independent Windows implementation after
the pull; Windows work is native validation and focused repair of observed
Windows failures.

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

## Toolchain And Lightweight Verification

Expected toolchain:

```text
Node.js   22.x
pnpm      9.15.0
Flutter   3.44.9 stable
Dart      3.12.x
```

Visual Studio must include Desktop development with C++, MSVC, a Windows SDK,
CMake/Ninja, and Developer Mode for plugin symlinks.

For ordinary Windows alignment, run from the repository root in PowerShell:

```powershell
$env:PUB_HOSTED_URL = "https://pub.flutter-io.cn"
$env:FLUTTER_STORAGE_BASE_URL = "https://storage.flutter-io.cn"

corepack enable
pnpm install --frozen-lockfile
flutter pub get

Set-Location apps\client
flutter build windows --release
```

Distribute and test the entire
`apps\client\build\windows\x64\runner\Release\` directory, not only
`client.exe`. After the commands, inspect `git status --short`; do not commit
registry URL changes, line-ending churn, generated plugin registrants, or other
environment-only drift without understanding each hunk.

The SQLite package is delivered as a Dart native asset. Confirm the complete
Windows Release directory contains the generated native asset. The maintainer
performs the cold launch and History/UI checks manually; do not automate the
full native acceptance flow unless explicitly asked to diagnose a failure.

## Maintainer Manual Windows Acceptance Reference

This checklist belongs to maintainer-led hands-on validation. A Windows Agent
records results supplied by the maintainer, but does not attempt the full UI
sequence unless explicitly asked to diagnose one behavior.

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
13. History/instances: confirm History updates while it is visible, every page
    size works, old pages show the new-entry banner, restart preserves rows, and
    machine grouping plus individual/bulk offline-instance removal works against
    a Gateway containing the new route. Run the external converter against a
    copied legacy `shared_preferences.json` and verify the source stays intact.

Record Windows-owned results only in local
`docs/project_memory/windows-current-state.md`; read Linux-owned status from
`docs/project_memory/linux-current-state.md`. Update the Windows rows in
`docs/e2e-verification.md` when evidence is complete.

## Current Windows Alignment Request

This pass covers source alignment, focused checks, and a Windows verification
bundle. The public release version has not been prepared yet. Start from the
exact Linux `main` alignment SHA in the current handoff prompt and carry the shared
Dart/UI/generated-client changes into the Windows checkout. The shared client
logic is already implemented and verified on Linux, so do not redesign it or
spend time recreating Linux integration evidence.

- Preserve the Windows ownership boundary. Do not edit Gateway, Plugin,
  Contracts, generated protocol authority, or shared semantics to work around a
  Windows environment problem.
- If the pull already contains the needed client changes, make no speculative
  refactors. Only fix a Windows compile error or an observed Windows-native
  incompatibility.
- Do not run the full Flutter, Node, Dart, or desktop integration suites for
  routine alignment. Run a focused check only when it covers a changed seam or
  diagnoses a concrete build/native failure.
- Do not run `integration_test/live_acceptance_test.dart` or the full interactive
  acceptance list for this alignment pass. Skip Windows tests that require an
  unreliable native environment unless they are needed to diagnose a compile or
  packaging failure. The maintainer will perform the runtime checks manually.
- Run the focused checks requested in the current prompt, dependency resolution,
  and one Release build. Use the
  mirror variables below, then run `flutter pub get` and:

  ```powershell
  Set-Location apps\client
  flutter build windows --release
  ```

- Confirm the complete output directory exists at
  `apps\client\build\windows\x64\runner\Release\`, including `client.exe`,
  `data\`, and native DLL/native-asset files. Report that directory to the
  maintainer for manual execution. Do not provide only `client.exe`.
- After the build, inspect `git status --short`; do not commit registry URL
  churn, generated plugin registrants, line endings, or environment-only files.

## Next Windows Alignment Branch

After the Linux agent pushes `main`, do not continue the old
`windows/client-parity-20260818` checkout. Start a fresh branch from the exact
remote `main` SHA:

```powershell
git fetch origin
git switch main
git pull --ff-only origin main
git switch -c windows/client-parity-20260913
```

Read this handoff, `CONTEXT.md`, and platform memory files when present before editing.
The current Windows pass is source alignment, focused checks, and one Release build against the
complete Linux baseline. Do not modify Plugin, Gateway, Contracts, or shared
protocol behavior on that branch.

## Returning Windows Work

Keep Windows fixes focused on observed Windows failures. Before asking to
integrate:

```powershell
git status --short
git diff --check
git diff --stat main...HEAD
git log --oneline main..HEAD
```

Return the build result, any focused diagnostics actually run,
maintainer-supplied manual status, remaining risks, and SHA-256 values for
`client.exe`, `data/app.so`, native notification DLLs, and the complete Release
archive. Include the branch SHA and the exact command the Linux agent should run
to inspect it.

Commit only intended files on the Windows branch. Do not push or merge back to
`main` until the maintainer explicitly requests it. Do not invent missing UI
evidence; record manual validation as maintainer-owned.

## Windows Release Handoff

For a release task, follow the canonical [Release Process](releasing.md). The
release build is different from an ordinary Windows parity branch:

- Build only from the exact `main` SHA and version supplied by the Linux Release
  coordinator.
- Fast-forward local `main` with `git pull --ff-only`; do not build a release
  from a Windows feature branch, a dirty worktree, or an unpushed commit.
- Do not run the full Windows automated matrix or Agent-driven UI acceptance
  before packaging. The maintainer's prior application test and explicit
  release request authorize the file build; run only the dependency, compile,
  packaging, and archive-integrity checks needed to produce trustworthy files.
- Package the complete
  `apps\client\build\windows\x64\runner\Release\` directory plus `LICENSE`
  into `opencode-notify-client-windows-x64-<version>.zip`.
- Transfer that ZIP to the designated Release coordinator together with its
  SHA-256,
  exact source SHA, build result, maintainer-supplied validation status,
  remaining risks, and key executable/DLL checksums.
- Do not transfer only `client.exe`; the Flutter data directory and native DLLs
  are required runtime files.
- Do not commit the ZIP. Create or push the release tag and upload the GitHub
  Release only when the maintainer explicitly designates Windows as the Release
  coordinator and all Linux, Windows, and Plugin assets have been received and
  verified. Otherwise transfer the ZIP to the designated coordinator.
