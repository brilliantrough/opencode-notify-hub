# API and Event Contracts

The generated OpenAPI 3.1 document is
[`packages/contracts/openapi/openapi.yaml`](../packages/contracts/openapi/openapi.yaml).
It is the source for the generated Dart/Dio package in `packages/notify_api`.

## Base URL and authentication

Examples use `https://notify.example.com`.

- Account/device/key endpoints use `Authorization: Bearer <access-token>`.
- `POST /v1/events` uses an ingest credential and HMAC headers.
- Native WebSocket clients use a bearer access token during HTTP Upgrade.

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
| `GET /v1/ws` | Upgrade to the authenticated realtime WebSocket |

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
gateway sends only:

```json
{"type":"event","event":{}}
```

where `event` satisfies the notification-event union. Malformed or unknown
frames should be ignored by clients.

- Close `4401`: access token expired; refresh and reconnect immediately.
- Close `1012`: gateway restart; reconnect with backoff.
- Other disconnects: reconnect with bounded exponential backoff.
- Missed events are not replayed.

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
