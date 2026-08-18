# Gateway Operations Runbook

This runbook assumes the generic deployment in [deployment.md](deployment.md).
Replace example names with your own service, Compose, and monitoring names.

## Health checks

| Endpoint | Expected | Meaning |
| --- | --- | --- |
| `GET /health/live` | `200 {"status":"ok"}` | Process is serving HTTP |
| `GET /health/ready` | `200 {"status":"ok"}` | Database, migrations, and Firebase are ready |

Alert on repeated readiness failure and process/container restarts.

## Inspect service

```bash
docker compose -f deploy/docker-compose.production.yml ps
docker compose -f deploy/docker-compose.production.yml logs --since 15m gateway
curl -fsS https://notify.example.com/health/ready
```

Sanitize logs before sharing. Although known secret paths are redacted, do not
assume arbitrary proxy/platform logs are safe.

## Incident: readiness returns 503

Check, in order:

1. `DATABASE_URL` DNS, port, credentials, and TLS requirements.
2. PostgreSQL availability and role/database ownership.
3. Whether all bundled migrations were explicitly applied.
4. Whether `FIREBASE_SERVICE_ACCOUNT_JSON` is valid single-line JSON for a real
   service account.

Run migrations with the exact deployed image:

```bash
docker compose -f deploy/docker-compose.production.yml run --rm gateway \
  node dist/db/migrate.js
```

Do not use a generic hostname shared by multiple Docker containers. Use a
unique service/network alias or stable database DNS name.

## Incident: email is not delivered

- Confirm outbound TCP connectivity to the SMTP host/port.
- Verify `SMTP_SECURE` matches the provider's implicit TLS vs STARTTLS port.
- Confirm the sender address is authorized.
- Check provider rate limits, bounces, and spam quarantine.
- Never log or paste verification/reset codes into public issues.

## Incident: WebSocket disconnects

- Identify the affected channel first. `/v1/plugin/ws` carries remote-control
  traffic from the Plugin; notification events use the independent signed
  HTTPS `POST /v1/events` path. A blocked Plugin WebSocket disables instance
  presence and remote answers/decisions, but does not stop event ingestion.
- `/v1/ws` carries desktop and foreground-client notifications. There is no
  HTTP fallback, gateway event store, or reconnect replay, so events emitted
  while this channel is blocked are not delivered to those clients. Eligible
  Android `action_required` and `terminal` events can still arrive through FCM.
- Confirm `/v1/ws` uses HTTP/1.1 Upgrade and Connection headers.
- Set proxy read/send timeouts to at least 3600 seconds.
- Confirm load balancers/CDNs also support long-lived WebSockets.
- Verify client and server clocks for token expiry behavior.
- A `4401` close is normal token expiry; clients refresh and reconnect.
- A `1012` close is normal gateway restart; clients reconnect with backoff.

If the first notification arrives but later notifications do not, verify the
gateway version includes null-safe `ws.send` callback handling. The Node `ws`
library can report success with `null`; success must not remove the socket.

## Incident: signed events are rejected

- Verify the ingest key is active and belongs to the intended account.
- Ensure the plugin and gateway use the exact same gateway/key pair.
- Check clock synchronization; stale timestamps are rejected.
- Confirm the JSON body is not modified after signature calculation.
- Restart OpenCode after changing plugin environment variables.

Do not print the ingest secret or complete Authorization header.

## Incident: Android push fails

- Verify client and gateway use the same Firebase project.
- Confirm the device has a current FCM token, is enabled, and granted Android
  notification permission.
- Inspect sanitized FCM error codes. Invalid/unregistered tokens are cleared.
- Foreground WebSocket success does not prove background FCM is configured.

## Incident: rate limiting affects many users

The gateway uses `trustProxy: true`. The reverse proxy must overwrite and build
`X-Forwarded-For` correctly rather than accepting an untrusted client-supplied
chain. Confirm `request.ip` resolves to the real end client rather than one
shared proxy address.

## Backup schedule

Run the parameterized backup script from a restricted account:

```bash
PG_CONTAINER=notify-postgres \
PG_USER=notify_app \
PG_DATABASE=opencode_notify \
BACKUP_DIR=/var/backups/opencode-notify \
RETENTION_DAYS=14 \
bash deploy/scripts/backup.sh
```

Encrypt off-host copies. Monitor backup age and size; a cron exit code alone
does not prove restorability.

## Restore drill

```bash
PG_CONTAINER=notify-postgres \
PG_ADMIN_USER=postgres \
RESTORE_DATABASE=opencode_notify_restore_test \
bash deploy/scripts/restore-test.sh /path/to/accounts-<timestamp>.dump
```

Confirm every account table is queryable and row counts are plausible. Drop the
scratch database after recording the drill. Never restore over production as a
test.

## Credential rotation

- **JWT signing key:** rotating it invalidates access tokens; active refresh
  credentials can obtain new access tokens after reconnect. Schedule a gateway
  restart and monitor login/refresh failures.
- **SMTP password:** update `.env`, recreate the gateway, and test verification
  and reset email with staging accounts.
- **Firebase service account:** replace JSON, recreate the gateway, verify
  readiness, and send a staging background push.
- **Ingest key:** create a replacement in the client, update/restart OpenCode,
  verify delivery, then revoke the old key.

## Graceful restart

Compose sends SIGTERM. The gateway stops accepting new work, closes WebSockets
with `1012`, waits for HTTP drain, and exits. Avoid `docker kill` except when the
graceful timeout has failed.

## Data deletion request

The pre-release API has no self-service account deletion. Authenticate the
request through your operator process, back up according to policy, and delete
the user row in a controlled maintenance procedure; foreign-key cascades remove
owned tokens, devices, and keys. Ensure backup retention/deletion obligations
are also handled.
