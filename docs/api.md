# API and Event Contracts

The generated OpenAPI 3.1 document is
[`packages/contracts/openapi/openapi.yaml`](../packages/contracts/openapi/openapi.yaml).
It is the source for the generated Dart/Dio package in `packages/notify_api`.

## Base URL and authentication

Examples use `https://notify.example.com`.

- Account/device/key endpoints use `Authorization: Bearer <access-token>`.
- `POST /v1/events` uses an ingest credential and HMAC headers.
- Native WebSocket clients use a bearer access token during HTTP Upgrade.
- Plugin control WebSockets use the existing Plugin key during HTTP Upgrade.

## Endpoints

| Method and path | Purpose |
| --- | --- |
| `GET /health/live` | Process liveness; dependency independent |
| `GET /health/ready` | Database schema and Firebase readiness |
| `POST /v1/auth/register` | Create an unverified account and send a code |
| `POST /v1/auth/verify-email` | Verify the eight-character email code |
| `POST /v1/auth/resend-verification` | Issue a replacement verification code |
| `POST /v1/auth/login` | Issue access and refresh tokens |
| `POST /v1/auth/refresh` | Rotate refresh credentials and issue tokens |
| `POST /v1/auth/logout` | Revoke the refresh-token family |
| `POST /v1/auth/forgot-password` | Send a reset code |
| `POST /v1/auth/reset-password` | Reset password and revoke old sessions |
| `GET, POST /v1/devices` | List and register devices |
| `PATCH, DELETE /v1/devices/{id}` | Update or remove a user-owned device |
| `GET, POST /v1/ingest-keys` | List and create ingest keys |
| `DELETE /v1/ingest-keys/{id}` | Revoke an ingest key |
| `POST /v1/events` | Accept one signed notification event (`202`) |
| `GET /v1/pending-interactions` | Collect the user's authoritative OpenCode pending snapshot |
| `POST /v1/pending-interactions/{instanceId}/questions/{requestId}/answer` | Route one ordered question answer set to the owning instance |
| `POST /v1/pending-interactions/{instanceId}/permissions/{requestId}/decision` | Route a `once`, `always`, or `reject` permission decision to the owning instance |
| `GET /v1/pending-interactions/commands/{commandId}` | Query the body-free outcome of a submitted command |
| `GET /v1/ws` | Upgrade to the authenticated realtime WebSocket |
| `GET /v1/plugin/ws` | Upgrade to the Plugin control WebSocket |

Use the OpenAPI document for exact request/response schemas and status codes.

## Event types

Every event includes `eventId`, `type`, `occurredAt`, `source`, `session`, and a
type-specific `payload`.

- `heartbeat`: `busy` or `retry` status and elapsed seconds.
- `action_required`: question, permission, or provider-action payload.
- `action_resolved`: clears a question or permission request.
- `terminal`: `completed`, `failed`, or `stopped`, elapsed seconds, and optional
  assistant summary.

Contract schemas reject unknown properties instead of silently removing them.

## Signed event ingestion

The plugin sends the exact JSON bytes with:

```http
Authorization: Bearer keyId.secret
Content-Type: application/json
X-Notify-Timestamp: <Unix epoch milliseconds>
X-Notify-Signature: <lowercase HMAC-SHA256 hex>
```

Signature input:

```text
<timestamp>.<raw JSON request body>
```

The HMAC key is the secret portion after the first dot. Do not reserialize the
body after calculating the signature. Unknown/revoked keys, stale timestamps,
and invalid signatures intentionally share a uniform `401` response.

Successful ingestion returns `202 Accepted` with `eventId` and `deduplicated`.
Deduplication is scoped per user.

## WebSocket

Connect to `wss://notify.example.com/v1/ws` with a live access token. The
gateway sends notification events and complete instance-presence snapshots:

```json
{"type":"event","event":{}}
{"type":"instance_presence","instances":[]}
```

where `event` satisfies the notification-event union. Malformed or unknown
frames should be ignored by clients.

- Close `4401`: access token expired; refresh and reconnect immediately.
- Close `1012`: gateway restart; reconnect with backoff.
- Other disconnects: reconnect with bounded exponential backoff.
- Missed events are not replayed.

## Pending interactions

`GET /v1/pending-interactions` uses an account access token. The gateway asks
only that account's online, compatible, non-conflicting Plugin instances and
returns a partial `200` snapshot if one does not answer before the bounded
timeout. Question and permission bodies transit gateway memory but are not
persisted or logged. Provider actions remain notification events and never
enter this snapshot.

OpenCode `1.18.18` does not expose a creation timestamp in its pending-list
responses. `occurredAt` is therefore the Plugin's stable first-observed time
for the request while that Plugin process remains online.

Each upgraded Plugin connects to `/v1/plugin/ws`, registers its OpenCode
instance, and handles `pending_snapshot_request` frames. Its response carries
the complete question or permission context from its own instance-specific
OpenCode Server. The OpenAPI document defines the exact discriminated unions.

### Question answers

`POST /v1/pending-interactions/{instanceId}/questions/{requestId}/answer`
carries a client-generated UUID `commandId`, the event-derived `sessionId`, and
`answers: string[][]` — one non-empty entry per upstream question, in exact
order. The command is routed
only to the owning account's connected `controllable` instance whose pending
projection contains that question; unknown or foreign instances answer `404`,
stale or wrong-kind targets answer `409`, and a second command for the same
request while one is in flight answers `409`. After writing the command to the
Plugin connection, the Gateway immediately returns `202 {commandId,
status:"accepted"}`. This is a best-effort delivery acknowledgement, not an
OpenCode confirmation. The Plugin calls the V2 session-scoped question reply
directly; if the request was already handled locally, OpenCode returns stale
and the command becomes a no-op. The client marks an accepted request sent and
removes its local card without waiting for that terminal result. Answers transit
memory only and are redacted from logs.

### Permission decisions

`POST /v1/pending-interactions/{instanceId}/permissions/{requestId}/decision`
carries a client-generated UUID `commandId`, the event-derived `sessionId`, and
`decision: "once" | "always" | "reject"`. The `always` decision persists a
reusable pattern in OpenCode, so
the gateway accepts it but never constructs it: the client must have surfaced
the exact `always` patterns first and confirmed the intent. The same ownership,
pending-projection, in-flight, `202 accepted`, direct V2 reply, and stale no-op
rules as question answers apply. Permission patterns, metadata, and decisions
transit memory only and are redacted from logs; nothing is persisted.

### Command outcomes

Every answer or decision command carries a client-generated UUID `commandId`.
The gateway keeps a body-free, in-memory outcome record per command
(`accepted | confirmed | stale | upstream_error | result_unknown` with the
request/instance identity and `updatedAt` only — never answers, decisions,
patterns, or metadata) for about ten minutes.
`GET /v1/pending-interactions/commands/{commandId}` returns the outcome to the
owning account and a uniform `404` for unknown, expired, or foreign ids. It is
an optional diagnostic surface; the desktop client does not wait for or
reconcile against it after a `202 accepted` submission. The cache is
deliberately volatile and has no bearing on delivery semantics.

## Regeneration

After changing contract schemas:

```bash
pnpm --filter @notify/contracts generate:openapi
pnpm --filter @notify/contracts test
bash packages/notify_api/tool/regen.sh
git diff --exit-code packages/contracts/openapi packages/notify_api
```

The Dart generator is pinned to version 7.17.0. A generator upgrade must be an
explicit change with reviewed generated output.
