#!/usr/bin/env bash
set -u
ROOT=$(mktemp -d "${TMPDIR:-/tmp}"/run-cli-XXXXXX)
mkdir -p "$ROOT/project/.opencode/plugins" "$ROOT/xdg/opencode" "$ROOT/home"
cat > "$ROOT/project/.opencode/plugins/marker.js" <<JS
import { appendFileSync } from "node:fs";
appendFileSync("$ROOT/loaded.txt", "imported\n");
export default async function markerPlugin(input) {
  appendFileSync("$ROOT/loaded.txt", "invoked serverUrl=" + (input?.serverUrl?.toString?.() ?? "none") + "\n");
  return { event: async () => { appendFileSync("$ROOT/loaded.txt", "event\n"); } };
}
JS
cat > "$ROOT/xdg/opencode/opencode.json" <<JSON
{ "\$schema": "https://opencode.ai/config.json" }
JSON
cd "$ROOT/project"
HOME="$ROOT/home" XDG_CONFIG_HOME="$ROOT/xdg" OPENCODE_DISABLE_AUTOUPDATE=1 "${OPENCODE_BIN:-opencode}" run --print-logs --log-level DEBUG "hi" > "$ROOT/out.log" 2>&1 || true
echo "--- plugin log lines:"
grep -i plugin "$ROOT/out.log" | head -10
echo "--- marker file:"
cat "$ROOT/loaded.txt" 2>/dev/null || echo NO_MARKER
rm -rf "$ROOT"
