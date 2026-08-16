# OpenCode Notify

Cross-platform notifications for [OpenCode](https://opencode.ai/) sessions.
OpenCode Notify sends completion and action-required events from an OpenCode
plugin to authenticated Linux, Windows, and Android clients through a
self-hosted gateway.

> **Release status:** pre-release. The source, build instructions, and
> self-hosting path are available, but signed desktop/mobile binaries are not
> published yet. Android background notifications also require your own
> Firebase configuration.

## How it works

```text
OpenCode session
    │
    │ session-notify plugin (HMAC-signed HTTPS)
    ▼
OpenCode Notify gateway
    ├── WebSocket ──► Linux / Windows / foreground Android
    └── FCM ───────► background / lock-screen Android
```

The plugin reports bounded event envelopes, not complete conversations. The
gateway authenticates users and ingest keys, routes live events, and does not
persist notification event payloads. See [Privacy](PRIVACY.md) for the exact
data boundaries.

## Features

- Completion, failure, stop, question, permission, and provider-action alerts.
- Linux tray client with notification history and autostart; the Windows target
  shares the desktop implementation and is pending full E2E verification.
- Android foreground WebSocket delivery and background FCM delivery.
- Per-user ingest keys with one-time secret display and revocation.
- HMAC-signed event ingestion, short-lived access tokens, and refresh rotation.
- Self-hosted Docker gateway with PostgreSQL, SMTP, health checks, and backups.
- Shared JSON Schema/OpenAPI contracts with a generated Dart API client.

## Supported platforms

| Component | Supported | Notes |
| --- | --- | --- |
| OpenCode plugin | OpenCode 1.18.x on Node.js/Bun hosts | Built as one self-contained ESM file |
| Desktop client | Linux; Windows target included | Linux is tested on KDE/X11; Windows must be built and E2E-tested on Windows before release |
| Mobile client | Android | Real Firebase config and release signing are required for distribution |
| Gateway | Linux containers, Node.js 22+ | PostgreSQL 16+, HTTPS/WSS reverse proxy, SMTP, Firebase service account |
| Apple/Web clients | Not supported | No iOS, macOS, or web target is currently shipped |

## Quick start

Install the platform toolchain from [Client Setup](docs/client-setup.md) and
Node.js/pnpm prerequisites from [Plugin Installation](docs/plugin-install.md)
before starting.

### Use an existing gateway

1. Build and start the client, then choose the gateway from the login page:

   ```bash
   flutter pub get
   (cd apps/client && flutter run -d linux)
   ```

2. Register and verify an account in the client.
3. Open **Keys**, create an ingest key, and copy the secret immediately.
4. Build and install the OpenCode plugin:

   ```bash
   pnpm install --frozen-lockfile
   pnpm --filter @notify/plugin build
   mkdir -p ~/.config/opencode/plugins
   cp packages/plugin/dist/session-notify.js ~/.config/opencode/plugins/
   ```

5. Export the gateway URL and key before starting OpenCode:

   ```bash
   export NOTIFY_GATEWAY_URL=https://notify.example.com
   export NOTIFY_INGEST_KEY=keyId.secret
   opencode
   ```

Read the complete [client guide](docs/client-guide.md) and
[plugin guide](docs/plugin-install.md) before using production credentials.

### Self-host the gateway

The gateway requires PostgreSQL, SMTP, Firebase service-account JSON, and an
HTTPS/WSS reverse proxy. Start with the generic
[deployment guide](docs/deployment.md) and `.env.example`.

## Documentation

- [Project roadmap](ROADMAP.md)
- [Documentation index](docs/README.md)
- [Client user guide](docs/client-guide.md)
- [Client build setup](docs/client-setup.md)
- [OpenCode plugin installation](docs/plugin-install.md)
- [Self-hosting and deployment](docs/deployment.md)
- [Operations runbook](docs/runbook.md)
- [Architecture](docs/architecture.md)
- [API and event contracts](docs/api.md)
- [Development](docs/development.md)
- [Multi-device agent workflow](docs/agent-workflow.md)
- [Testing](docs/testing.md)
- [Release process](docs/releasing.md)

## Repository layout

| Path | Purpose |
| --- | --- |
| `packages/plugin` | OpenCode session plugin |
| `packages/contracts` | JSON schemas, TypeScript types, OpenAPI source |
| `apps/gateway` | Fastify gateway and PostgreSQL persistence |
| `apps/client` | Flutter Linux, Windows, and Android client |
| `packages/notify_api` | Generated Dart API client |
| `deploy` | Generic Compose, Nginx, backup, and restore examples |

## Contributing and security

Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request. Use the
private process in [SECURITY.md](SECURITY.md) for vulnerabilities; do not put
credentials, exploit details, or personal data in public issues.

## License

[MIT](LICENSE)
