# Development Guide

## Prerequisites

- Git.
- Node.js 22 or newer.
- Corepack and pnpm 9.15.0 (pinned by the root `packageManager`).
- Flutter 3.44.9 / compatible Dart 3.8+.
- Java 17 and Android SDK 36 for Android work.
- Docker for PostgreSQL integration tests and image tests.
- Platform dependencies from [client-setup.md](client-setup.md) for desktop
  builds.

## Bootstrap

```bash
git clone <repository-url>
cd opencode-notify
corepack enable
pnpm install --frozen-lockfile
flutter pub get
```

The TypeScript packages use a pnpm workspace; the Flutter client and generated
Dart API use the root pub workspace.

## Common commands

```bash
pnpm typecheck
pnpm test
pnpm build

(cd apps/client && flutter test)
(cd packages/notify_api && dart test)
flutter analyze
```

See [testing.md](testing.md) for integration and image suites.

## Run the gateway locally

The production configuration currently requires PostgreSQL, SMTP, and a valid
Firebase service-account JSON. Start a disposable PostgreSQL instance or use a
development database you control:

```bash
docker run --name notify-postgres --rm -d \
  -e POSTGRES_USER=notify \
  -e POSTGRES_PASSWORD=notify-dev-password \
  -e POSTGRES_DB=notify \
  -p 127.0.0.1:5432:5432 \
  postgres:16-alpine
```

Copy `.env.example` to `.env`, set every required value, and use development
SMTP/Firebase projects rather than production credentials:

```bash
cp .env.example .env
# Set DATABASE_URL to:
# postgres://notify:notify-dev-password@localhost:5432/notify

pnpm build
node --env-file=.env apps/gateway/dist/db/migrate.js
node --env-file=.env apps/gateway/dist/index.js
```

Node's environment-file loader handles quoted values and compact JSON without
executing `.env` as shell code.

The gateway listens on port 8080 by default. Direct HTTP is suitable only for
local development; production clients require HTTPS/WSS through a trusted
reverse proxy.

## Run the client

```bash
cd apps/client
flutter run -d linux \
  --dart-define=GATEWAY_URL=http://127.0.0.1:8080
```

Use a target-specific device id from `flutter devices`. Android background FCM
still requires matching Firebase configuration even when the HTTP gateway is
local.

## Build the plugin

```bash
pnpm --filter @notify/plugin build
```

The build generates and smoke-tests
`packages/plugin/dist/session-notify.js`. See
[plugin-install.md](plugin-install.md) for installation and environment
configuration.

## Schema and generated client workflow

Edit schemas under `packages/contracts/src/schemas`, then:

```bash
pnpm --filter @notify/contracts generate:openapi
pnpm --filter @notify/contracts test
bash packages/notify_api/tool/regen.sh
```

Review generated diffs. Do not hand-edit generated Dart models.

## Database migrations

Migrations live under `apps/gateway/drizzle`. Generate a migration only for an
intentional schema change:

```bash
pnpm --filter @notify/gateway db:generate
```

Review SQL, migration metadata, rollback/restore impact, and compatibility with
the currently supported gateway before committing it. Gateway startup never
auto-migrates; operators run migrations explicitly.

## Logging and secrets

The gateway and plugin redact known secret fields, but contributors must still
use synthetic credentials and reserved domains. Never load a production `.env`
while running tests or include raw logs in fixtures.
