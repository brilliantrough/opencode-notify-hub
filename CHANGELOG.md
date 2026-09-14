# Changelog

All notable changes will be documented in this file. The project intends to use
[Semantic Versioning](https://semver.org/) after the first public release.

## [Unreleased]

### Changed

- 首页改为在线入口优先：机器、项目、连接状态和“打开”；固定与历史会话移到次级入口，停止客户端每 30 秒逐目录查询及“实例暂未同步”提示。
- Gateway 提供同账号 `GET /v1/instances` 在线连接池、连接/重连和上下线即时快照、每 10 分钟完整广播（含空池）。
- 离线入口、历史/固定会话、离线请求及通知历史支持本机逐项删除，不删除远端会话或其他客户端记录。

### Fixed

- Plugin 到 OpenCode 的真实 HTTP 请求保留服务认证，修复 health 查询 401 导致版本 unknown；仅健康检查通过的入口上报 WebUI 可用性，未知版本可重新探测。

## [0.2.0-beta.2] - 2026-09-14

- Home now defaults to bounded favorite/recent shortcuts, with separate session
  and instance browsers, collapsed machine groups, persistent follow/hide/restore,
  offline cleanup, and one expandable synchronization error summary.
- Fixed session catalog requests returning HTTP 400: parse the HTTP query's
  `limit` as a number before strict range validation.

### Added

- Plugin remote registration now skips confirmed empty directories, discovers
  idle history after initialization, and starts on the first main-session event.
  `NOTIFY_REMOTE_DIRECTORIES` allows exact empty-directory overrides; failed or
  inconclusive discovery preserves access with an explicit diagnostic.
- Repeat viewing/copying of locally saved Plugin keys, import of existing keys,
  and Bash/Zsh or PowerShell environment export with a machine-name field.
- Direct key selection on the Plugin setup page, device renaming, session-search
  clearing, reopening/copying connected WebUI session links, and Ctrl+Enter prompt
  submission with empty/duplicate submission controls.

- Cold-start discovery of idle and recent main sessions, title/project/machine
  search, 50 local bookmarks, and last-opened session shortcuts per instance.
- Renewable WebUI authentication and automatic reconnect behind a stable local
  origin while Notify runs, with independent tunnels for multiple instances.

### Fixed

- Switching sessions within one instance no longer replaces its loopback port
  or closes existing browser tabs; token renewal keeps ongoing SSE streams open.
- Browser request cancellation and Plugin disconnect now clean up upstream
  WebUI requests; disconnected writes are never replayed automatically.
- Source-level Android/Windows alignment: responsive session actions, foreground
  resume refresh/reconnect, Android keep-alive before WebUI launch, and a Windows
  power-resume bridge. The maintainer confirmed Windows acceptance at `19eedca`
  without source changes; Android release signing and package checks passed,
  while this round's Android device acceptance remains unverified.

## [0.2.0-beta.1] - 2026-08-21

### Added

- Gateway admin panel at `/admin`: operator login and password change, user
  list and count, admin-created accounts (bypassing the whitelist and email
  verification), user password reset with session revocation, and a
  registration whitelist (email-domain suffixes plus exact addresses).
- Android client with a specialUse keep-alive foreground service so realtime
  notifications survive backgrounding without vendor push services, an
  in-app WebUI browser keeping the loopback tunnel alive, and a
  battery-optimization whitelist guidance tile.
- First release-signed Android APK asset (universal APK covering
  arm64-v8a, armeabi-v7a, and x86_64).
- "Forgot password" email-code reset across clients.

### Changed

- Clients no longer prefill a default server address; the gateway origin must
  be entered once and is then persisted (the server is private to each
  deployment).
- Registration is closed by default and only opens through the admin-managed
  whitelist; rejected addresses get a localized contact-administrator message.

### Fixed

- Treat the Plugin control protocol as the compatibility boundary so OpenCode
  patch releases such as 1.18.19 remain remotely controllable.
- Android WebUI launches in an in-app WebView: an external browser froze the
  app process and killed the loopback tunnel.
- Settings state equality again includes the font scale so UI updates are not
  silently dropped.

## [0.1.0-beta.2] - 2026-08-20

### Added

- Machine-grouped OpenCode instance presence with owner-scoped removal of stale
  offline instances.
- Live, paginated device-local notification history backed by SQLite with a
  10,000-entry retention limit and an external legacy JSON import tool.

### Fixed

- Stabilized machine-group lifecycle handling when presence snapshots replace
  groups while the client UI is mounted.

## [0.1.0-beta.1] - 2026-08-19

### Added

- OpenCode session plugin with bounded notification envelopes and HMAC ingest.
- Fastify gateway with account, device, ingest-key, WebSocket, and FCM routing.
- Portable Flutter Linux and Windows desktop clients with account restore,
  runtime gateway selection, tray integration, notification history, custom
  sounds, and machine-aware notifications.
- Best-effort remote Session prompts and temporary system-browser OpenCode WebUI
  access through an authenticated Gateway/Plugin tunnel.
- Remote question and permission workbench with multi-device conflict handling.
- OpenAPI contracts and generated Dart API client.
- Public user, operator, contributor, security, and privacy documentation.

### Known limitations

- Linux and Windows desktop archives are unsigned beta builds. Windows may show
  SmartScreen warnings.
- Real Windows production question/permission/toast-click/Prompt/WebUI
  acceptance, clean-machine installation, lifecycle recovery, scaling, and
  autostart coverage remain incomplete.
- Android is not included. Distribution requires project-specific Firebase and
  release signing setup.
- Remote control is supported against the tested OpenCode 1.18.x explicit-port
  runtime and remains subject to upstream Plugin-host behavior.
- Account deletion currently requires the gateway operator.
