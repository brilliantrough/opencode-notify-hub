# Controlled Beta Verification

This document is the operator checklist for the controlled Remote Unblock
Beta ([design](design/remote-unblock-phase-1.md)). It covers the deployment
steps, the supported-compatibility matrix, the rollback plan, the privacy
guarantees, the known Phase 1 exclusions, and the exact verification commands
plus what each one proves. Run it against a dedicated staging gateway and
staging OpenCode hosts, never production credentials.

This remains the historical Phase 1 checklist. Later Session prompt and browser
WebUI features have their current behavior and tests documented in
[Client guide](client-guide.md#session-control) and [Testing](testing.md).

## Scope

The Beta lets a user answer an OpenCode pending question or permission request
from another Linux or Windows desktop and see the same OpenCode session
resume. The first live acceptance environment is a Linux OpenCode host with a
Linux desktop client.

## Deployment steps

Deploy in this order: gateway, plugin, then desktop client. Keep every
artifact's version, digest, and checksum from the [release process](releasing.md)
in the environment record below.

### 1. Gateway image

Follow [deployment.md](deployment.md) for the full procedure. The Beta uses
the rollback tag pattern this repository's deployment history follows: an
**immutable version tag or digest**, never `latest` alone.

- Build and tag immutably: `opencode-notify-gateway:<version>` (example
  `0.1.0`), and for a real registry
  `registry.example.com/opencode-notify-gateway:<version>`.
- Record the digest from the registry in the release notes and in the
  environment record; rollback and upgrade both select the previous immutable
  image by tag or digest.
- Deploy through Compose with the exact tag:

```bash
export OPENCODE_NOTIFY_IMAGE=registry.example.com/opencode-notify-gateway:<version>
docker compose -f deploy/docker-compose.production.yml up -d
docker compose -f deploy/docker-compose.production.yml run --rm gateway \
  node dist/db/migrate.js
```

- Verify `/health/ready` returns `{"status":"ok"}` before pointing any plugin
  or client at the gateway.

### 2. Plugin bundle

Install the production plugin bundle per
[plugin-install.md](plugin-install.md):

```bash
pnpm install --frozen-lockfile
pnpm --filter @notify/plugin build
mkdir -p ~/.config/opencode/plugins
cp packages/plugin/dist/session-notify.js ~/.config/opencode/plugins/
```

The plugin reads `NOTIFY_GATEWAY_URL` and `NOTIFY_INGEST_KEY` from the
environment OpenCode starts in. Validation fails closed: a missing or invalid
variable disables the plugin entirely with a single sanitized warning. Restart
OpenCode after installing or changing any variable.

### 3. Desktop client

Build each desktop target on its native operating system per
[client-setup.md](client-setup.md). Builds are server-portable; select the
staging gateway from the login page before running the acceptance matrix:

```bash
cd apps/client
flutter build linux --release
# Windows host:
flutter build windows --release
```

Distribute the complete portable bundle directory, not the executable alone.

## Environment record

Record before verifying, and keep it sanitized:

- gateway image tag and digest;
- plugin bundle checksum and OpenCode version;
- client version/checksum, OS, desktop environment, and architecture;
- staging gateway URL;
- test date and tester.

## Compatibility matrix

OpenCode 1.18.18 remains the pinned evidence target. Runtime compatibility is
defined by the Notify Plugin control protocol, not an exact OpenCode host
version: the Plugin adapts host API differences and reports the host version for
diagnostics. Compatibility is per machine/instance and is published to the
client as instance presence.

| Component | Compatible | Behavior |
| --- | --- | --- |
| OpenCode version | diagnostic; evidence pinned to `1.18.18` | Patch releases do not require a Gateway deployment. |
| OpenCode launch mode | `opencode serve`, `opencode web` | Officially supported modes. |
| Plugin control protocol | version `2` | Establishes the control WSS; fully actionable. |
| Older Plugin (notification-era) | notification-only | Sends ordinary notifications; no control connection, no config migration required. |
| Incompatible Plugin protocol | notification-only, diagnosable | Registers as `state: "incompatible"`; presence shows the instance and versions; excluded from pending collection and commands (`404`), notifications keep flowing. |

An incompatible protocol never blocks notifications and never receives remote
commands; its instance stays visible so an operator can diagnose why it is not
actionable. The `state: "incompatible"` presence contract is proven by the
`incompatible-notification-only` integration suite.

## Rollback plan

- **Application (gateway):** point `OPENCODE_NOTIFY_IMAGE` at the previous
  immutable image tag or digest and recreate:

```bash
export OPENCODE_NOTIFY_IMAGE=registry.example.com/opencode-notify-gateway:<previous-version>
docker compose -f deploy/docker-compose.production.yml pull
docker compose -f deploy/docker-compose.production.yml up -d --force-recreate
```

- **Database:** if the forward migration is not backward compatible, restore
  the last tested backup (`deploy/scripts/restore-test.sh`) to the scratch
  `*_restore_test` database first, verify it, then restore to production.
  Rehearse the restore before it is needed.
- **Plugin:** reinstall the previous bundle in
  `~/.config/opencode/plugins/` and restart OpenCode. The bundle is a single
  self-contained file; no other state is stored locally.
- **Desktop client:** reinstall the previous platform bundle; the persisted
  server selection remains in local preferences.

Roll back the gateway before the plugin: a reverted gateway and an upgraded
plugin degrade to the notification-only path, never to a broken one.

## Privacy guarantees

- Interaction bodies — question text, answers, permission patterns, metadata,
  decisions — transit **gateway memory only**, over TLS from Plugin to gateway
  and gateway to desktop client. They are never written to PostgreSQL and never
  written to application logs.
- Gateway log-redaction covers interaction request, response, and error bodies.
  The `log-redaction` integration suite asserts interaction content is redacted
  at any logged depth, and `privacy-sweep` sweeps every real interaction path
  (snapshot, answer, decision, outcome, ingest, control frames, and error
  paths) for sentinel-free log output and leaves PostgreSQL with exactly the
  public account-table allowlist after all interaction traffic.
- The command outcome cache is **body-free and in-memory** for about ten
  minutes: `commandId`, request/instance identity, status, and `updatedAt`
  only — never answers, decisions, patterns, or metadata. It is volatile; a
  gateway restart loses it. It is diagnostic only; clients optimistically
  remove requests after the Gateway returns `202 accepted`.

The full user-facing policy is [PRIVACY.md](../PRIVACY.md) and the persistence
boundary is [ADR 0003](adr/0003-relay-full-interactions-without-persistence.md).

## Known Phase 1 exclusions

These remain explicitly out of scope for the Beta:

- Android interaction UI (notifications only);
- offline answer queues;
- provider actions beyond existing notifications and links;
- generic OpenCode HTTP port forwarding or a full remote WebUI;
- team sharing across separate user accounts;
- persistent interaction or audit history.

## Verification commands

Run in this order on a clean staging environment.

### 1. OpenCode release smoke

```bash
pnpm --filter @notify/plugin smoke:opencode
```

This is the disposable release harness
(`packages/plugin/scripts/opencode-smoke.mjs`). It spawns two isolated real
`opencode serve` processes loading the production plugin bundle against a
synthetic dead gateway and proves, against OpenCode 1.18.18:

- servers stay healthy while the plugin cannot reach its gateway (P1);
- instance-specific server separation (P2) and cross-Server isolation of
  pending state (P3);
- SDK reconnect recovery: a brand-new client lists pending state (P4);
- permission `once`, `always` (persisting a project-scoped pattern that
  auto-allows a matching action in a new session), and `reject` (P5–P7);
- **P8 (hard proof, gates the exit code):** the plugin's exact V2 paths work
  on natural model-turn state — location-scoped
  `v2.question.request.list` / `v2.permission.request.list` with
  `location.directory` list the pending requests and the session-scoped
  `v2.session.question.reply` / `v2.session.permission.reply` replies resolve
  them;
- question variants (multi-question atomic reply, single-select, multi-select
  plus custom text) through a fake OpenAI-compatible provider; marked SKIPPED,
  never FAILED, when the fake-provider path is unavailable offline.

It also prints an informational (non-gating) note that OpenCode's V1 global
`/question` / `/permission` list endpoints are broken on this build — empty or
`404` for natural pending state — which is why the plugin reads and replies
exclusively through the V2 paths. Exit code `0` means every non-skipped proof
passed.

### 2. Gateway image smoke

```bash
bash apps/gateway/tests/deploy/image-smoke.sh
```

Proves the production Docker image itself: it builds from the repo-root
`Dockerfile`, runs as the non-root `node` user, contains the compiled
gateway/contracts dist and migration files, resolves workspace imports,
fails fast on missing env, and — against a disposable PostgreSQL + throwaway
Firebase account — starts without migrating (readiness `503`), applies the
explicit migration, and reaches readiness `200`.

### 3. Gateway integration suites

```bash
pnpm --filter @notify/gateway test:integration
```

Requires Docker (Testcontainers PostgreSQL 16). Relevant to the Beta, the
suites prove:

- `pending-interactions`: snapshot aggregation across connected `controllable`
  instances, account isolation, exclusion of conflicting/incompatible/offline
  instances, partial `200` on timeout, and the provider-notification
  regression;
- `question-answer` / `permission-decision`: routing to the owning instance,
  event-carried `sessionId`, immediate `202 accepted`, direct V2 replies,
  `404`/`409` routing gates, in-flight dedup, and the `always` confirmation rule;
- `command-outcome`: body-free, in-memory outcome records and uniform `404`;
- `incompatible-notification-only`: incompatible versions keep notifications
  and publish diagnosable presence but are excluded from commands;
- `log-redaction` and `privacy-sweep`: interaction content is absent from logs
  and the database (see Privacy guarantees above);
- `ws-routing` and `event-ingest`: notification delivery over the desktop
  WebSocket and signed ingestion.

### 4. Client checks

```bash
flutter analyze
(cd apps/client && flutter test)
(cd packages/notify_api && dart test)
```

plus the desktop interaction flow test
(`flutter test integration_test/desktop_flow_test.dart -d linux`) and the
manual [end-to-end matrix](e2e-verification.md), including the full
notification-to-resume loop on Linux and the Windows desktop parity columns.
