# Architecture

OpenCode Notify has four runtime components and one generated client package.

```text
┌──────────────┐       signed HTTPS        ┌─────────────────┐
│ OpenCode     │ ─────────────────────────► │ Gateway         │
│ plugin       │   POST /v1/events          │ Fastify + PG    │
└──────────────┘                             └───────┬─────────┘
                                                  │
                              ┌───────────────────┴───────────────────┐
                              │                                       │
                         WebSocket /v1/ws                              FCM
                              │                                       │
                    ┌─────────▼─────────┐                   ┌─────────▼─────────┐
                    │ Desktop/foreground│                   │ Background Android│
                    │ Flutter clients   │                   │ system delivery   │
                    └───────────────────┘                   └───────────────────┘
```

The separate control path is bidirectional and carries no notification replay:

```text
system browser ◄── localhost proxy ──► Flutter client
                                            │
                                 prompt REST / WebUI WebSocket
                                            ▼
                                         Gateway
                                            │
                                     /v1/plugin/ws
                                            ▼
                                          Plugin ──► local OpenCode
```

## Components

### `packages/plugin`

A self-contained OpenCode plugin. It observes only main-session events,
maintains per-session state, builds schema-valid envelopes, queues them with
bounded priority, and sends HMAC-authenticated requests. Invalid configuration
fails closed and sends nothing.

The Plugin also owns an outbound authenticated control WebSocket. Session
prompts and temporary WebUI HTTP/SSE requests travel down that existing
instance-specific connection; the Plugin calls only its local OpenCode server.

### `packages/contracts`

JSON schemas and TypeScript types for REST bodies, notification events, and
WebSocket server frames. The package generates
`packages/contracts/openapi/openapi.yaml`, which is the public API contract.

### `apps/gateway`

A Fastify service that owns accounts, email verification/password reset,
short-lived access tokens, refresh-token rotation, device registrations,
ingest-key verification, event fanout, health checks, and rate limits.

### `apps/client`

A Flutter client for Linux, Windows, and Android. It stores refresh credentials
in the OS secure store, maintains a reconnecting WebSocket while appropriate,
routes notifications through one dedupe/history path, and uses FCM for Android
background delivery. For temporary WebUI access it hosts a loopback-only HTTP
proxy, keeps its authenticated Gateway tunnel alive, and opens that local origin
in the system browser.

### `packages/notify_api`

The generated Dart/Dio client derived from OpenAPI. It is committed so Flutter
builds do not require code generation.

## Event lifecycle

1. OpenCode marks a main session busy.
2. The plugin emits silent heartbeats every 60 seconds by default.
3. Questions, permissions, provider actions, stops, and failures emit
   immediately.
4. A stable idle state emits completion after a 15-second debounce by default.
5. Non-interactive OpenCode shutdown flushes a completion only if the round has
   already entered idle debounce; it never fabricates completion for a busy
   round.
6. The gateway fans each accepted event to current user WebSockets and, for
   actionable/terminal events, eligible Android FCM targets.

There is no event store or catch-up queue in the gateway. Zero online WebSocket
recipients is still a successful dispatch; desktop clients do not receive
offline replay.

## Trust boundaries

### Plugin to gateway

- Bearer credential: `keyId.secret`.
- Signature: HMAC-SHA256 over `<timestamp>.<exact request body>`.
- Timestamp freshness and signature are verified before event dispatch.
- Events are deduplicated per user by event id for a bounded in-memory window.

### Client to gateway

- Passwords are hashed with Argon2id.
- Access tokens are HS256 JWTs with a 15-minute lifetime.
- Refresh tokens rotate; reuse revokes the token family.
- Native WebSocket upgrades use a bearer access token and reconnect after close
  code `4401` or a rejected `401` upgrade.

### Gateway to Firebase

Only enabled Android devices with an FCM token are targets. Invalid tokens are
cleared per device. FCM send failures are isolated and sanitized in logs.

## Persistence

The gateway persists seven account/configuration tables:

- users;
- email verification tokens;
- password reset tokens;
- refresh token families;
- refresh tokens;
- devices;
- ingest keys.

Raw passwords, refresh tokens, ingest secrets, and notification event payloads
are not stored. See [PRIVACY.md](../PRIVACY.md) for user-facing disclosure.

## Reliability model

- Plugin queue capacity is bounded; overflow drops lower-priority traffic.
- Delivery retries are bounded and events are dropped after exhaustion.
- WebSocket connections use heartbeat and backpressure limits.
- Gateway shutdown closes sockets with `1012` so clients reconnect.
- Token expiry closes sockets with `4401` so clients refresh.
- Notification ids are deduplicated in client memory and persisted history.

## Deployment boundary

The gateway assumes it is behind a trusted HTTPS reverse proxy because Fastify
uses `trustProxy: true` for rate-limit client addresses. Do not expose port 8080
directly to untrusted networks. The proxy must overwrite forwarding headers and
support WebSocket upgrades.
