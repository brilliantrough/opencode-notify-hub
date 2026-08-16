# Upstream blocker: opencode 1.18.18 plugin-host gaps (handoff for a fresh agent)

**Status:** verified 2026-08-15 against a real `opencode` 1.18.18 binary on this
machine (Linux, `~/.opencode/bin/opencode`). Every claim below was reproduced by
a probe committed next to this file in `docs/beta-evidence/probes/`. Read this
file first; it is self-contained.

## One-paragraph summary

Phase 1 remote unblock is architected around an OpenCode **plugin** that runs
inside the user's OpenCode process, reads the pending question/permission store
through the instance's own HTTP API (`input.serverUrl`), and relays answers back
through it. On opencode **1.18.18 there is no launch mode where both halves
work**: modes that invoke the plugin factory (TUI, `run`, `attach`) do not give
the plugin a reachable pending store, and modes that expose the store
(`serve`/`web`) never invoke the plugin factory. The notification side
(plugin `event` hook → HTTPS POST) works in the TUI today and is unaffected.
The answer side is blocked **upstream**, not by anything in this repo.

## Verified launch-mode matrix (opencode 1.18.18)

| Mode | factory invoked | `event` hook fires | pending store reachable | verdict |
| --- | --- | --- | --- | --- |
| `opencode serve` / `opencode web` | **never** (module imported lazily, factory never called) | no | yes (HTTP listener fine) | unsupported — no plugin host |
| `opencode run` | yes (`serverUrl=http://localhost:4096/`) | yes | n/a — `question` tool is **denied** headless ("Model tried to call unavailable tool 'question'") | notifications only, no questions |
| `opencode` TUI (pty) | yes | yes (`question.asked` observed) | **no** — TUI process binds no LISTEN socket; `serverUrl` (`localhost:4096`) gives `ECONNREFUSED` even with `NO_PROXY`; in-process `input.client` has no `question`/`permission`/`v2`/`global.health` surfaces (enumerated keys: `_client,global,project,pty,config,tool,instance,path,vcs,session,command,provider,find,file,app,mcp,lsp,formatter,tui,auth,event`; `session`/`global` expose only `_client`) | notifications only |
| `opencode serve` + `opencode attach` (pty) | yes, **in the attach process**, with `serverUrl` = the **reachable** serve listener (health 200) | yes | **no** — a session driven from the attach TUI keeps its messages and pending question in the **attach process's private store**; the serve API shows no such session/messages/questions, so the plugin (querying the serve) sees `[]` | control channel registers **controllable** but answers cannot route |

## Second verified defect: the V1 pending APIs are broken on 1.18.18

Independent of the launch-mode gaps: the V1 global endpoints do not see the
natural pending store at all.

- A pending permission created by a real model turn (question tool's own
  permission assertion) is **absent** from `GET /permission`
  (`client.permission.list({directory})` → `[]`), and
  `client.permission.reply(...)` answers **404 `PermissionNotFoundError`**.
- Requests created through the V2 session APIs are likewise invisible to the
  V1 lists.
- The working authoritative surface (all proven live): location-scoped lists
  `client.v2.question.request.list({location:{directory}})` /
  `client.v2.permission.request.list({location:{directory}})` (envelope
  `data = {location, data: [...]}`), and session-scoped replies
  `client.v2.session.question.reply({sessionID, requestID, questionV2Reply:{answers}})` /
  `client.v2.session.permission.reply({sessionID, requestID, reply})`.
- Related upstream reports: anomalyco/opencode#42541 (V2 list empty for
  question-tool requests on `next` builds), #36835 (separate pending stores
  TUI vs HTTP API), #37650 (pending permission listing schema failure).

Our plugin was migrated to the V2 surface in commit `a442e33`
(`packages/plugin/src/pending-adapter.ts`, `question-reply-adapter.ts`,
`permission-reply-adapter.ts`). V2 field mapping: permission `action→permission`,
`resources→patterns`, `save→always`, `source(type==="tool")→tool`;
question fields unchanged. Reply commands now carry the `sessionID` captured
from the original event/snapshot and call the V2 session-scoped reply directly;
there is no pending-list preflight. A request already handled locally returns
stale and is treated as a best-effort no-op.

## Third verified defect: proxy environment poisons loopback plugin traffic

This host (like many dev machines) exports `HTTP_PROXY`/`ALL_PROXY=
http://localhost:7890` with **no** `no_proxy` for localhost. A proxy-aware
fetch in the plugin host then routes `http://localhost:4096/...` to the proxy,
which answers **502**. Fixed in commit `a442e33`:
`packages/plugin/src/direct-fetch.ts` (`createLoopbackDirectFetch`) drives
`http://` URLs through `node:http` directly (never proxied) and is wired into
every `createOpencodeClient` the plugin builds. Any future plugin→serverUrl
code path must keep this property.

## Fourth verified defect: plugin factory races the host server

Interactive hosts invoke the plugin factory **before** their HTTP server is
ready, so a one-shot version probe resolves `unknown` and (before the fix) was
cached forever → the gateway pinned the instance `incompatible`. Fixed in
`a442e33`: `ControlChannel` retries the version probe with backoff until
`versionReadyTimeoutMs` (default 60 s) and only then registers `unknown`.

## How to reproduce every claim (probes in this directory)

All probes isolate themselves (`mkdtemp`, own `XDG_CONFIG_HOME`/`HOME`), never
read the user's `~/.config/opencode`, never touch other opencode processes, and
clean up after themselves. They need the repo's fake provider
(`scripts/beta/fake-provider.mjs`) and `@opencode-ai/sdk` — run them from a
directory where `node_modules/@opencode-ai` resolves (e.g. copy/symlink from
`packages/plugin/node_modules`). `OPENCODE_BIN` overrides the binary
(default `opencode` on PATH).

| Probe | Proves | Expected observation |
| --- | --- | --- |
| `v1-list-probe.mjs` (serve, fake provider) | V1 lists/replies broken; V2 paths work | `V1 /permission sees it: false`, `V1 permission.reply ok: false … PermissionNotFoundError`, V2 pending appears and replies succeed |
| `plugin-load-probe3.mjs` (serve) | factory never invoked under serve even with a tool executing | marker only ever contains `imported` |
| `run-cli-probe.sh` (`opencode run`) | factory invoked in run mode; question tool denied headless | marker has `invoked serverUrl=http://localhost:4096/` + `event` lines; run log shows question tool denied/unavailable |
| `tui_deep_probe.py` (TUI in pty) | factory + event hook work in TUI; `input.client` lacks pending surfaces | marker: `invoked …`, `question.asked`, `no session.question.list`, `no global.health`; `ss -tlp` shows no listener on the TUI pid |
| `attach_probe.py` (serve + attach in pty) | attach invokes factory with reachable serve URL; pending store split | marker: `invoked serverUrl=http://127.0.0.1:<port>/ health=200`, `question.asked`; direct serve queries show no attached-session messages/questions |

`scripts/beta/tui-driver.py` is the productionized pty driver used by the
closed loop.

## What works today despite the blocker

- Notifications (the original product) work in the TUI: plugin `event` hook →
  HMAC POST → gateway → desktop. Unaffected by all of the above.
- The full remote-unblock loop passes end to end with the **beta notify
  daemon** (`packages/plugin/scripts/beta/notify-daemon.ts`), which reuses the
  production plugin modules and wire protocols against a real
  `opencode serve` whose store is API-driven. Evidence:
  `docs/beta-evidence/closed-loop-2026-08-15.log` (`closed-loop: PASS`).
  Run: `bash scripts/beta/closed-loop.sh`.
- The two-server release smoke (`pnpm --filter @notify/plugin smoke:opencode`)
  proves the plugin's exact V2 read/reply API paths against real 1.18.18
  servers (11 proofs, including location-scoped visibility of natural
  model-turn pending state).

## What a fresh agent should do next

1. **File / watch upstream issues** (anomalyco/opencode) with the minimal
   repros in `probes/`:
   - plugin factory never invoked under `serve`/`web` (module imported,
     factory not called);
   - TUI: `input.serverUrl` has no listener and `input.client` lacks
     question/permission/global.health surfaces;
   - `attach`: attached-session pending store is private to the attach
     process, invisible to the serve API;
   - V1 `/question` + `/permission` list/reply broken for the natural store
     (link #42541 / #36835).
2. **Re-run the probes on every new opencode release** before claiming
   support; the matrix above is the checklist. Also re-run
   `pnpm --filter @notify/plugin smoke:opencode`.
3. **Unexplored:** `opencode acp` (Agent Client Protocol, editor-facing) was
   never probed — check whether it invokes plugin factories and whose store
   it exposes. The OpenCode desktop app (Electron) loads local plugins but
   upstream #38604 reports hooks never invoked; unverified here.
4. **When a working mode appears**, the only code change expected is deleting
   the daemon from the closed loop and pointing the plugin install docs at
   that mode; contracts/gateway/client are mode-agnostic. The plugin already
   handles proxy-poisoned loopback and startup races.

## Related documents

- `docs/beta-evidence/README.md` — the closed-loop evidence and runner.
- `docs/beta-verification.md` — Beta deployment/compatibility/privacy doc.
- `docs/design/remote-unblock-phase-1.md` — Runtime Contract section
  reflects this matrix.
- GitHub issue #14 close comment — the summary and the two honestly-partial
  acceptance items (Windows build, real-plugin closed loop).
