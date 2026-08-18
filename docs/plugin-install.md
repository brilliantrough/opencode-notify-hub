# Installing the session-notify OpenCode plugin

The plugin ships as a single self-contained ESM file,
`packages/plugin/dist/session-notify.js`. It watches OpenCode session
events and POSTs privacy-bounded notification envelopes to your
notification gateway (`POST {NOTIFY_GATEWAY_URL}/v1/events`, HMAC-signed).

The bundle's entire module surface is **one default function export** —
no named runtime exports. This is deliberate: older OpenCode plugin
loaders reject plugin modules that carry extra named exports. The shape
is enforced by a smoke gate chained into the build itself
(`pnpm --filter @notify/plugin build` runs `tsup` and then
`packages/plugin/scripts/smoke-dist.mjs`, which fails the build if any named export ever
reappears or if the plugin cannot load against a fake host without
network).

## Prerequisites

- **OpenCode** installed, with a plugin API compatible with
  `@opencode-ai/plugin` 1.18.x.
- **Node.js ≥ 22** and **pnpm 9** to build the bundle. (The produced
  bundle itself also runs under Bun, which is what OpenCode's plugin
  host uses.)
- A reachable **notification gateway** and an **ingest key** issued by
  that gateway, in the form `keyId.secret` (both parts base64url).

## Build

From the repository root:

```bash
pnpm install --frozen-lockfile
pnpm --filter @notify/plugin build
```

This produces `packages/plugin/dist/session-notify.js`. The bundle is
fully self-contained: `@notify/contracts` (including its validator) and the
runtime parts of `@opencode-ai/sdk` are bundled, while
`@opencode-ai/plugin` is type-only and erased at build time. Remaining runtime
imports are Node builtins. No `node_modules` needs to sit next to the installed
file.

Optional sanity check (both must print `function`):

```bash
node -e "import('./packages/plugin/dist/session-notify.js').then(m => console.log(typeof m.default))"
bun  -e "import('./packages/plugin/dist/session-notify.js').then(m => console.log(typeof m.default))"
```

For a stronger gate, the committed smoke script additionally asserts the
export set is exactly `["default"]` and loads the plugin against a fake
OpenCode host with the network disabled. It runs automatically at the
end of every `pnpm --filter @notify/plugin build` (and therefore of the
root `pnpm build`); it can also be run standalone under either runtime:

```bash
pnpm --filter @notify/plugin smoke:dist    # Node
bun packages/plugin/scripts/smoke-dist.mjs # Bun
```

## Install

OpenCode loads plugins two ways:

1. **Plugin directories (used here).** Direct `.js`/`.ts` children of
   the global directory `~/.config/opencode/plugins/` (or the
   project-level `.opencode/plugins/`) are auto-discovered and loaded at
   startup. No config entry is required.
2. **`plugin` array in `opencode.json`.** This is primarily for **npm
   packages** (installed with Bun at startup and cached in
   `~/.cache/opencode/node_modules/`), e.g.:

   ```jsonc
   // ~/.config/opencode/opencode.json — npm plugins only.
   // session-notify is a local file and is NOT listed here.
   {
     "$schema": "https://opencode.ai/config.json",
     "plugin": ["opencode-wakatime"]
   }
   ```

   Some OpenCode versions also accept explicit local file paths in this
   array, but that behavior has varied between releases, while the
   plugin directories have worked consistently across them — so the
   recommended install for this bundle is auto-discovery via
   `~/.config/opencode/plugins/`, with **no** `plugin` entry. Do **not**
   add the bare name `session-notify` to the array: it is not an npm
   package, the name would not resolve, and a file placed in the plugin
   directory is already loaded by auto-discovery.

Install the bundle globally:

```bash
mkdir -p ~/.config/opencode/plugins
cp packages/plugin/dist/session-notify.js ~/.config/opencode/plugins/
```

PowerShell on Windows uses the same OpenCode configuration directory:

```powershell
New-Item -ItemType Directory -Force "$HOME\.config\opencode\plugins"
Copy-Item "packages\plugin\dist\session-notify.js" `
  "$HOME\.config\opencode\plugins\session-notify.js"
```

(For a project-only install, copy it to `<project>/.opencode/plugins/`
instead.)

## Configuration

The plugin is configured entirely through environment variables, which
must be present in the environment OpenCode is started from (shell
profile, desktop launcher environment, or `VAR=value opencode`).

### Required

| Variable | Rules |
| --- | --- |
| `NOTIFY_GATEWAY_URL` | Absolute URL, no trailing slash. `https://` for anything real; `http://` is accepted **only** for loopback hosts (`localhost`, `127.0.0.1`, `[::1]`) for local gateway development. URLs with embedded `user:pass@` credentials are rejected. |
| `NOTIFY_INGEST_KEY` | `keyId.secret`, exactly one dot; both parts nonempty base64url (`A–Z a–z 0–9 - _`), as issued by the gateway. Sent as `Authorization: Bearer` and used as the HMAC-SHA256 signing secret. |

Example:

```bash
export NOTIFY_GATEWAY_URL="https://notify.example.com"
export NOTIFY_INGEST_KEY="Ab12Cd34.xY9_verylongsecret-token"
```

For a PowerShell session:

```powershell
$env:NOTIFY_GATEWAY_URL = "https://notify.example.com"
$env:NOTIFY_INGEST_KEY = "Ab12Cd34.xY9_verylongsecret-token"
opencode
```

Never commit the ingest key or paste it into OpenCode itself.

### Optional

| Variable | Default | Bounds / values |
| --- | --- | --- |
| `NOTIFY_MACHINE` | OS hostname | Any nonempty string; stamped as the event source machine. |
| `NOTIFY_INCLUDE_SUMMARY` | `false` | `true` / `false` only. When `true`, terminal events (completed/failed/stopped) include an assistant-only text summary, capped at 500 characters. See *Privacy* before enabling. |
| `NOTIFY_QUEUE_CAPACITY` | `100` | Integer 1–10 000. Bounded offline queue; overflow drops lowest-priority events. |
| `NOTIFY_HEARTBEAT_MS` | `60000` | Integer 1–3 600 000. Progress heartbeat interval while a round runs. |
| `NOTIFY_IDLE_DEBOUNCE_MS` | `15000` | Integer 1–600 000. Stable-idle delay before a round is declared completed. |
| `NOTIFY_HTTP_TIMEOUT_MS` | `5000` | Integer 1–300 000. Per-attempt gateway POST timeout. |
| `NOTIFY_MAX_RETRIES` | `3` | Integer 1–100. Delivery retries with backoff before an event is dropped. |

### Validation behavior (fail closed)

Configuration is validated once at plugin load. **Any** missing or
invalid value — including a malformed URL, a bad key format, a
non-`true`/`false` summary flag, or an out-of-bounds number — disables
the plugin entirely: it registers no hooks, sends nothing, and emits a
single warning through the OpenCode log:

```
opencode-notify disabled: missing or invalid NOTIFY_* configuration
```

The warning deliberately echoes no environment value, so the ingest
credential can never leak through this path. Fix the variable and
restart OpenCode.

## Privacy

Every event is validated against the shared contract before it leaves
the process; an event that cannot be built validly is dropped, never
sent partially. Envelopes carry:

- event kind, event id, timestamp, and session id/title;
- source identity: machine name, project id, working directory;
- round timing (elapsed seconds) and outcome
  (`completed` / `failed` / `stopped`, heartbeats while running);
- action details when the agent needs you: question text and option
  labels (≤ 8 questions, text ≤ 2000 chars), permission name and its
  summary (≤ 500 chars), provider action fields;
- **only with `NOTIFY_INCLUDE_SUMMARY=true`**: an assistant-only message
  summary (≤ 500 chars) on terminal events.

Never sent: user prompts, tool output, permission metadata beyond the
summary, full conversation text. Delivery uses
`Authorization: Bearer keyId.secret` plus an `X-Notify-Signature`
HMAC-SHA256 over the timestamped body. Logs contain ids, kinds, and
counts only, and the logger additionally scrubs the ingest credential
from anything it emits.

## Troubleshooting

Plugin log entries go through OpenCode's `app.log` with service name
`opencode-notify`. Find them in OpenCode's log files
(`~/.local/share/opencode/log/`, timestamped files, newest 10 kept) or
run OpenCode in the foreground with `opencode --print-logs` /
`--log-level DEBUG`.

- **No notifications, one "disabled" warning** → a required variable is
  missing/invalid; see *Validation behavior* above.
- **Events dropped with a gateway error in the log** → the gateway is
  unreachable or rejecting the key; the message carries only the event
  id and a sanitized reason. Check `NOTIFY_GATEWAY_URL` reachability and
  that the key was issued for that gateway.
- **Plugin not loaded at all** → confirm the file is a *direct* child of
  `~/.config/opencode/plugins/` named `session-notify.js`, and that you
  restarted OpenCode.

## Restart required

Plugins are loaded at startup. After copying the bundle or changing any
`NOTIFY_*` variable, **quit and restart OpenCode** — neither file
changes in the plugin directory nor environment edits apply to an
already-running instance.

## Non-interactive shutdown

`opencode run` disposes its plugin instance immediately after the session
becomes idle, before a normal debounce timer is guaranteed another event-loop
turn. During graceful disposal, session-notify therefore flushes only rounds
that have already entered the idle debounce and waits for their accepted
deliveries. A still-busy round is never reclassified as completed. Long-lived
interactive OpenCode sessions continue to use the configured
`NOTIFY_IDLE_DEBOUNCE_MS` window normally.
