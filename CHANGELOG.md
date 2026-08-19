# Changelog

All notable changes will be documented in this file. The project intends to use
[Semantic Versioning](https://semver.org/) after the first public release.

## [Unreleased]

### Added

- Machine-grouped OpenCode instance presence with owner-scoped removal of stale
  offline instances.
- Live, paginated device-local notification history backed by SQLite with a
  10,000-entry retention limit and an external legacy JSON import tool.

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
