#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 /path/to/accounts-<timestamp>.dump" >&2
  exit 2
fi

dump_file="$1"
: "${PG_CONTAINER:?Set PG_CONTAINER to the PostgreSQL container name}"
PG_ADMIN_USER="${PG_ADMIN_USER:-postgres}"
RESTORE_DATABASE="${RESTORE_DATABASE:-opencode_notify_restore_test}"

if [[ ! -f "$dump_file" ]]; then
  echo "Backup file does not exist: $dump_file" >&2
  exit 2
fi
if [[ ! "$RESTORE_DATABASE" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
  echo "RESTORE_DATABASE must be a simple PostgreSQL identifier" >&2
  exit 2
fi
if [[ ! "$RESTORE_DATABASE" =~ _restore_test$ ]]; then
  echo "RESTORE_DATABASE must end with _restore_test" >&2
  exit 2
fi

docker exec "$PG_CONTAINER" psql -v ON_ERROR_STOP=1 \
  -U "$PG_ADMIN_USER" -d postgres \
  -c "DROP DATABASE IF EXISTS \"$RESTORE_DATABASE\" WITH (FORCE);"
docker exec "$PG_CONTAINER" psql -v ON_ERROR_STOP=1 \
  -U "$PG_ADMIN_USER" -d postgres \
  -c "CREATE DATABASE \"$RESTORE_DATABASE\";"

docker exec -i "$PG_CONTAINER" pg_restore \
  -U "$PG_ADMIN_USER" \
  -d "$RESTORE_DATABASE" \
  --no-owner \
  --exit-on-error \
  < "$dump_file"

docker exec "$PG_CONTAINER" psql -v ON_ERROR_STOP=1 \
  -U "$PG_ADMIN_USER" -d "$RESTORE_DATABASE" \
  -c "SELECT 'users' AS table_name, count(*) FROM users
      UNION ALL SELECT 'devices', count(*) FROM devices
      UNION ALL SELECT 'ingest_keys', count(*) FROM ingest_keys;"

printf 'Restore verified in scratch database: %s\n' "$RESTORE_DATABASE"
