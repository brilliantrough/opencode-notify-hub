#!/usr/bin/env bash
# Image smoke test for the gateway OCI image.
#
# Asserts, in order:
#   1. the image builds from the repo-root Dockerfile;
#   2. the default user is the built-in `node` user (UID 1000);
#   3. compiled gateway/contracts dist and the Drizzle SQL + meta migration
#      files are present in the image;
#   4. workspace resolution works in the production install
#      (@notify/contracts and the gateway's own compiled modules import);
#   5. startup fails fast with a full config error when env is missing;
#   6. against a temporary PostgreSQL + throwaway Firebase service account:
#      the gateway starts and serves liveness WITHOUT migrating (readiness
#      stays 503 on the empty schema), the explicit migration command
#      (`node dist/db/migrate.js`) applies the schema, and readiness then
#      turns 200.
#
# Every container and the network are removed on exit (trap + --rm), so an
# aborted run leaks nothing.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
IMAGE="opencode-notify-gateway:smoke"
NETWORK="notify-smoke-net"
PG="notify-smoke-pg"
APP="notify-smoke-app"

fail() {
  echo "image smoke FAILED: $*" >&2
  exit 1
}

cleanup() {
  docker rm -f "$APP" "$PG" >/dev/null 2>&1 || true
  docker network rm "$NETWORK" >/dev/null 2>&1 || true
}
trap cleanup EXIT
# Clear leftovers from an aborted previous run before starting.
cleanup

command -v curl >/dev/null || fail "curl is required on the host"
command -v openssl >/dev/null || fail "openssl is required on the host"

echo "== build image =="
docker build -t "$IMAGE" "$REPO_ROOT"

echo "== non-root user =="
WHOAMI="$(docker run --rm --entrypoint whoami "$IMAGE")"
[ "$WHOAMI" = "node" ] || fail "expected whoami=node, got '$WHOAMI'"
echo "whoami: $WHOAMI"
UID_OUT="$(docker run --rm --entrypoint id "$IMAGE" -u)"
[ "$UID_OUT" = "1000" ] || fail "expected uid=1000, got '$UID_OUT'"
echo "uid: $UID_OUT"
LICENSE_LABEL="$(docker image inspect --format '{{ index .Config.Labels "org.opencontainers.image.licenses" }}' "$IMAGE")"
[ "$LICENSE_LABEL" = "MIT" ] || fail "expected OCI license label MIT, got '$LICENSE_LABEL'"
echo "license: $LICENSE_LABEL"

echo "== bundled files =="
for f in \
  /app/LICENSE \
  /app/apps/gateway/dist/index.js \
  /app/apps/gateway/dist/db/migrate.js \
  /app/apps/gateway/drizzle/0000_initial.sql \
  /app/apps/gateway/drizzle/meta/_journal.json \
  /app/packages/contracts/dist/index.js; do
  docker run --rm --entrypoint test "$IMAGE" -f "$f" || fail "missing $f"
done
echo "dist + drizzle migration files present"

echo "== workspace imports (production install) =="
docker run --rm --entrypoint node -w /app/apps/gateway "$IMAGE" \
  --input-type=module -e '
    await import("@notify/contracts");
    await import("./dist/config.js");
    await import("./dist/app.js");
    console.log("imports ok");
  ' || fail "workspace imports broke in the production image"

echo "== fail-fast without env =="
set +e
EMPTY_OUT="$(docker run --rm "$IMAGE" 2>&1)"
EMPTY_CODE=$?
set -e
[ "$EMPTY_CODE" -ne 0 ] || fail "empty-env run exited 0"
echo "$EMPTY_OUT" | grep -q "Invalid gateway configuration" \
  || fail "empty-env output missing config error: $EMPTY_OUT"
echo "$EMPTY_OUT" | grep -q "DATABASE_URL is required" \
  || fail "empty-env output missing DATABASE_URL issue: $EMPTY_OUT"
echo "empty-env exit=$EMPTY_CODE with full config error"

echo "== temporary postgresql =="
docker network create "$NETWORK" >/dev/null
docker run -d --rm --name "$PG" --network "$NETWORK" \
  -e POSTGRES_PASSWORD=smoke -e POSTGRES_DB=notify \
  postgres:16-alpine >/dev/null
for i in $(seq 1 30); do
  if docker exec "$PG" pg_isready -U postgres -d notify >/dev/null 2>&1; then
    break
  fi
  [ "$i" -eq 30 ] && fail "temporary postgres never became ready"
  sleep 1
done
DATABASE_URL="postgres://postgres:smoke@${PG}:5432/notify"

# Throwaway Firebase service account: firebase-admin parses the private key
# eagerly, so generate a structurally real PEM (it never touches a network).
FIREBASE_JSON="$(openssl genrsa 2048 2>/dev/null | node -e '
  let key = "";
  process.stdin.on("data", (chunk) => { key += chunk; });
  process.stdin.on("end", () => {
    process.stdout.write(JSON.stringify({
      project_id: "notify-smoke",
      client_email: "firebase-adminsdk@notify-smoke.iam.gserviceaccount.com",
      private_key: key,
    }));
  });
')"
JWT_SIGNING_KEY="$(openssl rand -base64 32)"

echo "== gateway starts without migrating =="
docker run -d --rm --name "$APP" --network "$NETWORK" \
  -p 127.0.0.1::8080 \
  -e DATABASE_URL="$DATABASE_URL" \
  -e PUBLIC_BASE_URL="https://notify.smoke.test" \
  -e JWT_SIGNING_KEY="$JWT_SIGNING_KEY" \
  -e SMTP_HOST="smtp.smoke.test" \
  -e SMTP_PORT="587" \
  -e SMTP_SECURE="false" \
  -e SMTP_USER="smtp-user" \
  -e SMTP_PASSWORD="smtp-password" \
  -e SMTP_FROM="notify@smoke.test" \
  -e FIREBASE_SERVICE_ACCOUNT_JSON="$FIREBASE_JSON" \
  -e ALLOWED_ORIGINS="https://app.smoke.test" \
  -e LOG_LEVEL="warn" \
  "$IMAGE" >/dev/null
HOST_PORT="$(docker port "$APP" 8080/tcp | head -n 1 | awk -F: '{print $NF}')"
[ -n "$HOST_PORT" ] || fail "no published port for the gateway"

LIVE=""
for i in $(seq 1 30); do
  LIVE="$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:${HOST_PORT}/health/live" || true)"
  [ "$LIVE" = "200" ] && break
  [ "$i" -eq 30 ] && { docker logs "$APP" 2>&1; fail "liveness never became 200 (last='$LIVE')"; }
  sleep 1
done
echo "liveness: $LIVE"

READY_BEFORE="$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:${HOST_PORT}/health/ready")"
[ "$READY_BEFORE" = "503" ] \
  || { docker logs "$APP" 2>&1; fail "readiness on unmigrated schema=$READY_BEFORE, expected 503 (startup must not migrate)"; }
docker logs "$APP" 2>&1 | grep -q "Applied migrations" \
  && fail "gateway ran migrations at startup"
echo "readiness before migrate: $READY_BEFORE (startup did not migrate)"

echo "== explicit migration command =="
MIGRATE_OUT="$(docker run --rm --network "$NETWORK" -w /app/apps/gateway \
  -e DATABASE_URL="$DATABASE_URL" \
  --entrypoint node "$IMAGE" dist/db/migrate.js 2>&1)" \
  || fail "explicit migration command failed: $MIGRATE_OUT"
echo "$MIGRATE_OUT" | grep -q "Applied migrations" \
  || fail "unexpected migrate output: $MIGRATE_OUT"
echo "migrate: $MIGRATE_OUT"

READY_AFTER=""
for i in $(seq 1 15); do
  READY_AFTER="$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:${HOST_PORT}/health/ready")"
  [ "$READY_AFTER" = "200" ] && break
  [ "$i" -eq 15 ] && { docker logs "$APP" 2>&1; fail "readiness never became 200 after migration (last='$READY_AFTER')"; }
  sleep 1
done
echo "readiness after migrate: $READY_AFTER"

echo "image smoke passed"
