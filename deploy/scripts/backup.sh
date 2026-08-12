#!/usr/bin/env bash
set -euo pipefail

: "${PG_CONTAINER:?Set PG_CONTAINER to the PostgreSQL container name}"
PG_USER="${PG_USER:-notify_app}"
PG_DATABASE="${PG_DATABASE:-opencode_notify}"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/opencode-notify}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"

if [[ ! "$RETENTION_DAYS" =~ ^[0-9]+$ ]]; then
  echo "RETENTION_DAYS must be a non-negative integer" >&2
  exit 2
fi

install -d -m 700 "$BACKUP_DIR"
file="$BACKUP_DIR/accounts-$(date -u +%Y%m%dT%H%M%SZ).dump"

docker exec "$PG_CONTAINER" pg_dump \
  -U "$PG_USER" \
  -d "$PG_DATABASE" \
  --format=custom \
  --no-owner \
  --table=users \
  --table=email_verification_tokens \
  --table=password_reset_tokens \
  --table=refresh_token_families \
  --table=refresh_tokens \
  --table=devices \
  --table=ingest_keys \
  > "$file"

chmod 600 "$file"
find "$BACKUP_DIR" -name 'accounts-*.dump' -type f -mtime "+$RETENTION_DAYS" -delete
printf 'Backup written: %s\n' "$file"
