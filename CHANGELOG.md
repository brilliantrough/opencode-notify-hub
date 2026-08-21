# Changelog

All notable changes will be documented in this file. The project intends to use
[Semantic Versioning](https://semver.org/) after the first public release.

## [Unreleased]

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
