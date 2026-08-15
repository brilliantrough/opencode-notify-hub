#!/usr/bin/env bash
# Issue #14 live closed loop — build and run the first Linux host →
# Linux desktop remote-unblock loop against a REAL gateway, REAL opencode,
# and the REAL desktop UI.
#
#   scripts/beta/closed-loop.sh
#
# Orchestrates:
#   1. the fake OpenAI-compatible provider (scripts/beta/fake-provider.mjs);
#   2. ephemeral postgres + migrations + the REAL gateway
#      (scripts/beta/stack-up.mjs);
#   3. the Flutter live acceptance test (live_acceptance_test.dart) which
#      registers/verifies a synthetic user through the real gateway API,
#      logs in through the real login page, spawns `opencode serve` and the
#      notify daemon (see docs/beta-evidence/README.md for why the daemon
#      stands in for the plugin-INSIDE-opencode half), and answers a real
#      question through the real form;
#   4. full teardown in every path (only this script's own children, tracked
#      by PID).
#
# Release tooling only; never CI. Requires docker, node, tsx (gateway deps),
# flutter with the linux desktop target, an X display (DISPLAY), opencode.
#
# Safety: never touches the user's opencode processes. All harness processes
# use isolated temp dirs and ephemeral high ports, and only PIDs this script
# itself spawned are ever signalled.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OPENCODE_BIN="${OPENCODE_BIN:-/home/pzy000/.opencode/bin/opencode}"
FLUTTER_BIN="${FLUTTER_BIN:-/home/pzy000/development/flutter/bin/flutter}"
PUB_HOSTED_URL="${PUB_HOSTED_URL:-https://pub.flutter-io.cn}"

EVIDENCE_DIR="$ROOT/docs/beta-evidence"
mkdir -p "$EVIDENCE_DIR"
EVIDENCE="$EVIDENCE_DIR/closed-loop-$(date +%Y-%m-%d).log"

STATE_FILE="$(mktemp /tmp/notify-loop-state-XXXXXX.json)"
PROVIDER_FILE="$(mktemp /tmp/notify-loop-provider-XXXXXX.json)"
LOOP_WORK="$(mktemp -d /tmp/notify-loop-work-XXXXXX)"

PROVIDER_PID=""
STACKUP_PID=""

log() { printf '[closed-loop] %s\n' "$*" | tee -a "$EVIDENCE"; }

teardown() {
  set +e
  log "tearing down..."
  if [ -n "$PROVIDER_PID" ] && kill -0 "$PROVIDER_PID" 2>/dev/null; then
    kill -TERM "$PROVIDER_PID" 2>/dev/null
    for _ in $(seq 1 20); do
      kill -0 "$PROVIDER_PID" 2>/dev/null || break
      sleep 0.25
    done
    kill -9 "$PROVIDER_PID" 2>/dev/null
  fi
  if [ -n "$STACKUP_PID" ] && kill -0 "$STACKUP_PID" 2>/dev/null; then
    kill -TERM "$STACKUP_PID" 2>/dev/null
    for _ in $(seq 1 30); do
      kill -0 "$STACKUP_PID" 2>/dev/null || break
      sleep 0.25
    done
    kill -9 "$STACKUP_PID" 2>/dev/null
  fi
  # Belt and braces: stack-up --stop removes container + workdir (idempotent).
  node "$ROOT/scripts/beta/stack-up.mjs" --stop --state "$STATE_FILE" >>"$EVIDENCE" 2>&1 || true
  rm -f "$PROVIDER_FILE"
  rm -rf "$LOOP_WORK"
  set -e
}
trap teardown EXIT

free_port() {
  python3 - <<'PY'
import socket
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.bind(("127.0.0.1", 0))
print(s.getsockname()[1])
s.close()
PY
}

echo "=== opencode-notify Issue #14 live closed loop ===" | tee -a "$EVIDENCE"
echo "date: $(date -u +%Y-%m-%dT%H:%M:%SZ)" | tee -a "$EVIDENCE"
"$OPENCODE_BIN" --version 2>/dev/null | sed 's/^/opencode: /' | tee -a "$EVIDENCE"
"$FLUTTER_BIN" --version 2>/dev/null | head -1 | tee -a "$EVIDENCE" || true
docker --version | tee -a "$EVIDENCE"

# ---- 0. Ensure the production plugin bundle exists.
if [ ! -f "$ROOT/packages/plugin/dist/session-notify.js" ]; then
  log "plugin dist missing; building..."
  (cd "$ROOT" && pnpm --filter @notify/plugin build) 2>&1 | tee -a "$EVIDENCE"
fi
PLUGIN_DIST="$ROOT/packages/plugin/dist/session-notify.js"
sha256sum "$PLUGIN_DIST" | tee -a "$EVIDENCE"

# ---- 1. Fake provider.
log "starting fake provider"
node "$ROOT/scripts/beta/fake-provider.mjs" --port-file "$PROVIDER_FILE" \
  >>"$EVIDENCE" 2>&1 &
PROVIDER_PID=$!
for _ in $(seq 1 40); do
  if [ -s "$PROVIDER_FILE" ] && node -e 'const s=require(process.argv[1]);if(!s.baseURL)process.exit(1)' "$PROVIDER_FILE" 2>/dev/null; then
    break
  fi
  sleep 0.25
done
PROVIDER_BASE_URL="$(node -e 'const s=require(process.argv[1]);process.stdout.write(s.baseURL)' "$PROVIDER_FILE")"
PROVIDER_PORT="$(node -e 'const s=require(process.argv[1]);process.stdout.write(String(s.port))' "$PROVIDER_FILE")"
log "fake provider on :$PROVIDER_PORT"

# ---- 2. Real gateway + ephemeral postgres.
log "starting stack-up (gateway + ephemeral postgres)"
node "$ROOT/scripts/beta/stack-up.mjs" --state "$STATE_FILE" --tag live \
  >>"$EVIDENCE" 2>&1 &
STACKUP_PID=$!
for _ in $(seq 1 120); do
  if [ -s "$STATE_FILE" ] && node -e 'const s=require(process.argv[1]);if(!s.gatewayUrl)process.exit(1)' "$STATE_FILE" 2>/dev/null; then
    break
  fi
  kill -0 "$STACKUP_PID" 2>/dev/null || break
  sleep 0.25
done
if ! node -e 'const s=require(process.argv[1]);if(!s.gatewayUrl)process.exit(1)' "$STATE_FILE" 2>/dev/null; then
  log "FAIL: stack-up never produced a usable state file"
  exit 1
fi
GATEWAY_URL="$(node -e 'const s=require(process.argv[1]);process.stdout.write(s.gatewayUrl)' "$STATE_FILE")"
MAILBOX_PATH="$(node -e 'const s=require(process.argv[1]);process.stdout.write(s.mailboxPath)' "$STATE_FILE")"
GATEWAY_LOG="$(node -e 'const s=require(process.argv[1]);process.stdout.write(s.gatewayLog)' "$STATE_FILE")"
log "gateway ready at $GATEWAY_URL"

# ---- 3. A free port for the real opencode serve spawned inside the test.
OPENCODE_PORT="$(free_port)"
log "opencode serve will bind :$OPENCODE_PORT"

# ---- 4. Run the live acceptance test (builds + runs the real desktop UI).
log "running flutter integration test (live_acceptance_test.dart) on linux"
set +e
(
  cd "$ROOT/apps/client"
  PUB_HOSTED_URL="$PUB_HOSTED_URL" \
    "$FLUTTER_BIN" test integration_test/live_acceptance_test.dart -d linux \
    --dart-define="LIVE_GATEWAY_URL=$GATEWAY_URL" \
    --dart-define="MAILBOX_PATH=$MAILBOX_PATH" \
    --dart-define="GATEWAY_LOG=$GATEWAY_LOG" \
    --dart-define="OPENCODE_PORT=$OPENCODE_PORT" \
    --dart-define="PROVIDER_BASE_URL=$PROVIDER_BASE_URL" \
    --dart-define="OPENCODE_BIN=$OPENCODE_BIN" \
    --dart-define="PLUGIN_DIST=$PLUGIN_DIST" \
    --dart-define="OPENCODE_LOG=$LOOP_WORK/opencode.log" \
    --dart-define="NOTIFY_DAEMON=$ROOT/packages/plugin/scripts/beta/notify-daemon.ts" \
    --dart-define="TSX_BIN=$ROOT/apps/gateway/node_modules/.bin/tsx"
) >"$LOOP_WORK/flutter-test.log" 2>&1
FLUTTER_EXIT=$?
set -e
tee -a "$EVIDENCE" <"$LOOP_WORK/flutter-test.log" >/dev/null

if [ "$FLUTTER_EXIT" -ne 0 ]; then
  log "FLUTTER TEST FAILED (exit $FLUTTER_EXIT)"
  mkdir -p "$ROOT/docs/beta-evidence/diag"
  cp "$LOOP_WORK/flutter-test.log" "$ROOT/docs/beta-evidence/diag/closed-loop-flutter.log" 2>/dev/null || true
  cp "$LOOP_WORK/opencode.log" "$ROOT/docs/beta-evidence/diag/closed-loop-opencode.log" 2>/dev/null || true
  cp "$GATEWAY_LOG" "$ROOT/docs/beta-evidence/diag/closed-loop-gateway.log" 2>/dev/null || true
  echo "--- opencode serve log (tail) ---" | tee -a "$EVIDENCE"
  tail -n 40 "$LOOP_WORK/opencode.log" 2>/dev/null | tee -a "$EVIDENCE" || true
  echo "--- gateway log (tail) ---" | tee -a "$EVIDENCE"
  tail -n 30 "$GATEWAY_LOG" 2>/dev/null | tee -a "$EVIDENCE" || true
  exit 1
fi

# ---- 5. Evidence summary.
echo | tee -a "$EVIDENCE"
echo "=== EVIDENCE SUMMARY ===" | tee -a "$EVIDENCE"
{
  echo "closed loop: PASS"
  echo "gateway: $GATEWAY_URL (ephemeral postgres + dev mailer + noop FCM)"
  echo "opencode: $("$OPENCODE_BIN" --version 2>/dev/null | head -1)"
  echo "plugin bundle: $PLUGIN_DIST ($(sha256sum "$PLUGIN_DIST" | cut -d' ' -f1))"
  echo "fake provider port: $PROVIDER_PORT"
  echo "gateway log: $GATEWAY_LOG"
  echo "mailbox: $MAILBOX_PATH"
} | tee -a "$EVIDENCE"

log "closed loop PASSED end to end."
log "evidence written to $EVIDENCE"
