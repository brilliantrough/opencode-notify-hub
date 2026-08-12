# Gateway Self-Hosting and Deployment

This guide deploys the OpenCode Notify gateway behind HTTPS/WSS. Examples use
reserved names and must be adapted to your infrastructure.

## Requirements

- Docker 26+ and Docker Compose v2.32+.
- PostgreSQL 16 or newer reachable from the gateway container.
- A reverse proxy such as Nginx or Caddy terminating HTTPS/WSS.
- A DNS name and valid TLS certificate.
- SMTP credentials for email verification and password reset.
- Firebase service-account JSON for Android FCM.

Firebase is currently a required gateway configuration even if you do not plan
to distribute the Android client. The service account must contain non-empty
`project_id`, `client_email`, and `private_key` fields.

## Deployment files

- `Dockerfile`: multi-stage Node.js 22 image, unprivileged runtime user.
- `deploy/docker-compose.production.yml`: generic gateway-only Compose example.
- `deploy/nginx/notify.example.com.conf`: HTTPS/WSS Nginx example.
- `deploy/scripts/backup.sh`: parameterized seven-table backup.
- `deploy/scripts/restore-test.sh`: isolated restore verification.
- `.env.example`: every required gateway variable.

## 1. Create PostgreSQL database

Run as a PostgreSQL administrator, using a strong generated password:

```sql
CREATE ROLE notify_app LOGIN PASSWORD '<random-password>';
CREATE DATABASE opencode_notify OWNER notify_app;
```

Do not reuse the database role or database for unrelated services.

## 2. Configure the gateway

From the repository root:

```bash
cp .env.example .env
chmod 600 .env
openssl rand -base64 32
```

Edit `.env` and set every required value. A container-to-host PostgreSQL URL on
Linux can use the Compose `host.docker.internal` mapping:

```dotenv
DATABASE_URL=postgresql://notify_app:<url-encoded-password>@host.docker.internal:5432/opencode_notify
PUBLIC_BASE_URL=https://notify.example.com
JWT_SIGNING_KEY=<output-of-openssl-command>
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=notify@example.com
SMTP_PASSWORD=<smtp-password>
SMTP_FROM="OpenCode Notify <notify@example.com>"
FIREBASE_SERVICE_ACCOUNT_JSON='<compact JSON from your Firebase service-account file>'
ALLOWED_ORIGINS=https://notify.example.com
LOG_LEVEL=info
```

`DATABASE_URL` passwords must be URL-encoded. `PUBLIC_BASE_URL` must be the
public HTTPS origin. `ALLOWED_ORIGINS` is a comma-separated exact allowlist for
browser requests; native clients send no Origin header. Produce compact
Firebase JSON with `jq -c . service-account.json`, then paste that complete
output between the single quotes shown above.

Never commit `.env`.

## 3. Build the image

```bash
docker build -f Dockerfile \
  -t opencode-notify-gateway:0.1.0 .
```

For production, push to your registry and deploy an immutable version tag or
digest. Do not rely only on `latest`.

## 4. Start and migrate

Set the image used by the Compose example:

```bash
export OPENCODE_NOTIFY_IMAGE=opencode-notify-gateway:0.1.0
docker compose -f deploy/docker-compose.production.yml up -d
docker compose -f deploy/docker-compose.production.yml run --rm gateway \
  node dist/db/migrate.js
```

Migrations are explicit; gateway startup never modifies the schema. Readiness
returns `503` until the database and bundled migrations are consistent.

The example binds gateway port 8080 to host loopback only. Keep it private and
put the TLS reverse proxy in front of it.

## 5. Configure HTTPS/WSS

Copy `deploy/nginx/notify.example.com.conf` and replace:

- `notify.example.com` with your DNS name;
- certificate/key paths;
- `127.0.0.1:8080` if the gateway is reached differently.

The `/v1/ws` location must preserve Upgrade/Connection headers and use a long
read timeout. The proxy must overwrite forwarding headers; the gateway trusts
them for client-IP rate limiting.

Validate and reload Nginx:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

## 6. Verify

```bash
curl -fsS https://notify.example.com/health/live
curl -fsS https://notify.example.com/health/ready
```

Both should return `{"status":"ok"}`. Then register a staging account, create
an ingest key, and follow [e2e-verification.md](e2e-verification.md).

## Backup and restore verification

The scripts target only the seven account/configuration tables; event payloads
are not persisted.

```bash
export PG_CONTAINER=notify-postgres
export PG_USER=notify_app
export PG_DATABASE=opencode_notify
export BACKUP_DIR=/var/backups/opencode-notify
export RETENTION_DAYS=14
bash deploy/scripts/backup.sh

export PG_ADMIN_USER=postgres
export RESTORE_DATABASE=opencode_notify_restore_test
bash deploy/scripts/restore-test.sh \
  /var/backups/opencode-notify/accounts-<timestamp>.dump
```

The restore script accepts only a scratch database name ending in
`_restore_test`, then drops and recreates that database. Never point
`RESTORE_DATABASE` at production.

## Upgrade

1. Back up account tables and test the backup.
2. Build/pull the new immutable image.
3. Review migration SQL and release notes.
4. Run migrations with the new image.
5. Update `OPENCODE_NOTIFY_IMAGE` and recreate the gateway.
6. Verify readiness, login, WebSocket reconnect, and signed ingest.

```bash
export OPENCODE_NOTIFY_IMAGE=registry.example.com/opencode-notify-gateway:<version>
docker compose -f deploy/docker-compose.production.yml pull
docker compose -f deploy/docker-compose.production.yml run --rm gateway \
  node dist/db/migrate.js
docker compose -f deploy/docker-compose.production.yml up -d --force-recreate
```

## Rollback

Application rollback uses the previous immutable image. Database rollback may
require restoring a tested backup if a migration is not backward compatible.
Do not run destructive schema changes without a rehearsed restore path.

## Production checklist

- [ ] Immutable gateway image tag/digest recorded.
- [ ] `.env` permissions restricted and secrets backed up securely.
- [ ] PostgreSQL accessible only from trusted networks.
- [ ] Real SMTP and Firebase credentials verified with staging accounts.
- [ ] TLS renewal and WebSocket proxy timeouts verified.
- [ ] Backup retention, restore test, and off-host copy scheduled.
- [ ] Container log rotation and readiness monitoring enabled.
- [ ] Operator privacy/retention/contact policy published to users.
