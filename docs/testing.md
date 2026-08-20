# Testing Guide

These commands are a menu, not a mandatory matrix for every change. Linux
development should run the narrowest checks that cover the changed behavior.
GitHub CI is reserved for pull requests or explicit manual dispatch. Windows
source-alignment work normally requires dependency resolution and a Release
build; the maintainer performs final native UI acceptance. When the maintainer
has already tested the application and authorizes a release, do not repeat the
full suites below unless a build failure or specific risk requires diagnosis.

## TypeScript workspace

Run unit/contract tests, type checks, and builds from the repository root:

```bash
pnpm test
pnpm typecheck
pnpm build
```

This covers contracts, gateway unit tests, plugin tests, and the plugin bundle
smoke gate. The smoke gate verifies the plugin has exactly one default runtime
export, loads in a fake OpenCode host, makes no unexpected network calls, and
does not leak the configured credential.

## Gateway integration tests

Docker must be running. Tests use Testcontainers with a disposable PostgreSQL
16 instance:

```bash
pnpm --filter @notify/gateway test:integration
```

The suite covers auth, migrations/readiness, devices, ingest keys, event
ingestion, WebSocket routing, FCM dispatch behavior, and shutdown.

## Gateway image smoke test

Build and run the production Docker image against disposable dependencies:

```bash
bash apps/gateway/tests/deploy/image-smoke.sh
```

This test requires Docker and may download base/PostgreSQL images. It validates
the non-root runtime image, migrations, health endpoints, and container
behavior.

## Flutter and Dart

```bash
flutter pub get
flutter analyze
(cd apps/client && flutter test)
(cd packages/notify_api && dart test)
```

Linux client tests require the native packages listed in
[client-setup.md](client-setup.md).

## Client integration test

The desktop flow test requires a runnable Flutter desktop target:

```bash
cd apps/client
flutter test integration_test/desktop_flow_test.dart -d linux
```

Use a local test gateway or the test's own fixture behavior; never point
integration tests at production accounts.

## Manual E2E

Follow [e2e-verification.md](e2e-verification.md). At minimum verify:

- terminal and action-required popup delivery;
- two consecutive events on the same WebSocket;
- desktop close-to-tray behavior;
- token-expiry and gateway-restart reconnect;
- cross-user isolation;
- Android foreground and background delivery when Firebase is configured.

Sanitize all evidence before attaching it to an issue or pull request.

## Before a pull request

Run the narrow suite while developing and all affected suites before review.
Contract, authentication, persistence, cross-user routing, or shared realtime
changes require integration tests in addition to unit tests.
