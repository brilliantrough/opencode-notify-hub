# Windows Development Handoff

Updated: 2026-09-14

## 当前发布任务：0.2.0-beta.2

- 维护者已确认 `19eedcac8f65737a57ad0569b11d672c0dbb9035` 的 Windows 构建与手动验收通过，Windows 无源码修改，并已授权发布。本节取代下文旧验证任务；不重复 UI 自动化、两组测试或全平台矩阵。
- Linux 是本次 Release 协调端。使用维护者 prompt 提供的最终发布 SHA，客户端版本 `0.2.0-beta.2+4`、Plugin `0.2.0-beta.2`；发布准备仅更新版本和文档。旧 `19eedca` 验证 ZIP 不可改名冒充新版本。
- 先按下文分支协调流程保护本地工作，再快进 `main` 并核对准确 SHA。依赖和打包都使用 `$env:PUB_HOSTED_URL = 'https://pub.flutter-io.cn'`、`$env:FLUTTER_STORAGE_BASE_URL = 'https://storage.flutter-io.cn'`；仓库根目录 `flutter pub get --enforce-lockfile`，`apps/client` 下 `flutter build windows --release`。构建后确认 `pubspec.lock` 和源码未变，失败则报告，不升级依赖绕过。
- 将完整 `apps/client/build/windows/x64/runner/Release/` 加仓库 `LICENSE`，放入顶层 `opencode-notify-client-windows-x64-0.2.0-beta.2/` 后打 ZIP。交付 ZIP、SHA-256、准确源 SHA、版本和 `git status`，以及 `client.exe`、`data/app.so` 和原生 DLL 的哈希，参照 [releasing.md](releasing.md)。
- Windows 负责构建与传回 ZIP，不创建标签、Release 或触发 CI；Linux 收齐、复核后统一上传。若无已配置传输通道，将完整 ZIP 交给维护者转交，不以“本机路径”冒充已传至 Linux。

## 统一交接：新首页与目录按需注册（已完成的验证背景）

- 使用维护者最新 prompt 的完整 SHA，一次拉取即可包含 `799d9b2` 的客户端体验改动、`1d6fc41` 的首页重做/平台适配/Gateway 修复，以及本轮 Plugin 目录按需注册。上次 Windows 已验证的是 `799d9b2`；不要再以它或 `1d6fc41` 作为本轮最终对齐点。
- 最新改动在 OpenCode 主机运行的 `session-notify.js`：确认空目录不注册，有非归档历史主会话（含 idle）或后续主会话事件则注册；查询失败保留入口，`NOTIFY_REMOTE_DIRECTORIES` 可精确指定空目录入口。详见 [plugin-install.md](plugin-install.md#目录按需注册)。不涉及新的 Windows 原生依赖或客户端/Gateway 协议变动。
- Windows 本轮执行下节的客户端轻量检查和完整 Release ZIP 打包即可。Plugin 已通过 Linux 121 项针对性检查、类型检查、Node/Bun 加载检查及真实认证接口查询；仅测试 Notify 客户端不要求在 Windows 安装或重启 OpenCode。
- 真实联调时，目标 OpenCode 主机必须更新 Plugin 并重启实际服务进程，再清理 Notify 旧离线实例；仅更新客户端、拉取 Git 或重连 attach 不会卸载服务中已加载的旧 Plugin。`packages/plugin/dist/` 是构建产物，不随 Git 拉取生成。
- 当前版本仍 `0.2.0-beta.1+3`，按最终 SHA 命名验证包；不发布、不打标签、不触发 CI，UI 由维护者验收。Windows 结果不能替代 Android 原生验收。

## 首页修正与轻量验证流程

- 首页改动随本文提交到 `main`；使用维护者交接 prompt 中的新完整 SHA，`799d9b2` 仅是上次验证基线。本轮只需 `flutter analyze --no-pub`、`test/ui/home_page_test.dart` 与 `test/sessions/session_catalog_test.dart` 两组测试，以及 `flutter build windows --release`；交付完整 Release 目录与 ZIP，桌面交互由维护者验收。

- 维护者已澄清：上次 Windows 在 `799d9b2` 上没有改码，直接测试通过，因此没有额外 Windows 提交是正常结果。此为维护者反馈；本次首页重做仍待 Windows 复测。
- 新首页为常用/会话/实例，默认限量预览；实例在线/全部/已隐藏筛选、折叠分组、关注、持久化隐藏/恢复和离线清理；去掉独立实时会话栏，错误汇总到详情。都是共享 Dart，Windows 后续应拉取包含这批改动的新 SHA 再构建。
- Linux 本轮 31 项客户端检查（含 360px 布局、隐藏持久化/恢复与账号隔离）、2 项 Gateway 检查、分析与 Linux Release 已通过；没有本轮 Windows 原生构建结论。
- Gateway 查询参数 `limit` 的字符串/整数不匹配已修复并部署 `20260913-catalog-query`；HTTP 400 根因消除。部分目标仍有 502/504，需要检查目标 OpenCode 的 Plugin 更新/重启及服务状态。
- 本次平台对齐已核对 `app.dart`：Windows 导航栏与 Android 底部导航均使用同一 `HomePage`，关注/隐藏使用已有跨平台 SharedPreferences，无新增原生依赖。搜索按 Enter 收起输入焦点，切换首页分栏同样收起键盘；同步详情可滚动以适配短窗口与大字号。
- 后续 Windows 重点复测：缩窄窗口/放大字号、关注和隐藏后重启恢复、离线清理、搜索后切换分栏，以及托盘恢复后直达会话；拉取本轮新 SHA 后构建完整 Release。此次只做源码对齐及轻量静态检查，不提前构建 Windows/Android 包。

## 2026-09-13 远程会话入口交接（上轮背景）

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
