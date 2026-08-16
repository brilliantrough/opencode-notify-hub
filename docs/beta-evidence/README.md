# Issue #14 AC9 — first Linux host → Linux desktop closed loop

> **Start here if you are a fresh agent picking up the upstream blocker:**
> [upstream-plugin-gap.md](upstream-plugin-gap.md) is the self-contained
> handoff — verified claims, reproduction probes (committed under
> `probes/`), the fixes already in our code, and what to try next.

## Result (2026-08-15, final)

The remote-unblock closed loop **passes end to end** on this machine
(`scripts/beta/closed-loop.sh`, ~60 s wall; test 30 s, `All tests passed!`).
Non-secret evidence:

- `docs/beta-evidence/closed-loop-2026-08-15.log`

Loop: REAL gateway (ephemeral postgres, dev mailbox mailer, noop FCM) → REAL
`opencode serve` 1.18.18 with the fake OpenAI-compatible provider → the notify
daemon → REAL desktop UI (real login page, real WS delivery, real notification
click → focused question page, real form submit) → answer routed back into the
same opencode session → pending question cleared, `question` tool completed
with the submitted answers, gateway snapshot empty, and the gateway log proved
to carry no question/answer bodies (AC1 re-proven live).

## Verified launch-mode matrix (opencode 1.18.18) — full truth

Three plugin fixes were verified real and correct: version-retry
(`control-channel.ts`), loopback-direct fetch (`direct-fetch.ts`, required
because this host runs `HTTP_PROXY`/`ALL_PROXY=http://localhost:7890` with no
`no_proxy`), and the plugin tests/build/smoke pass. They are necessary but not
sufficient: on 1.18.18 the plugin's `input.serverUrl` never points at the store
holding the pending question, so the answer round-trip cannot complete through
the plugin in any launch mode.

| Mode | factory invoked | event hook (notification) | control channel | pending-question reachable via `serverUrl` | answer round-trip |
| --- | --- | --- | --- | --- | --- |
| `opencode serve` / `web` | **no** | no | no | — | no |
| `opencode run` | yes | — | — | question tool denied (headless) | no |
| `opencode` **TUI** (pty) | yes | **yes** | registers `incompatible(unknown)` | no — `serverUrl` (`localhost:4096`) has no reachable listener (direct `node:http` → `ECONNREFUSED` with `NO_PROXY`; TUI process has no LISTEN socket) | no |
| `opencode serve` + **`opencode attach`** (pty) | **yes** | **yes** | **yes — CONTROLLABLE** | **no** — the attached session's question lives in the attach process's private store; the serve (the plugin's `serverUrl`) reports an empty question list and empty session messages (verified), so the plugin's pending/reply adapters never see the question | no |

Probe references: the committed, re-runnable probes under
`docs/beta-evidence/probes/` (see the table in
[upstream-plugin-gap.md](upstream-plugin-gap.md) for what each proves and the
expected output).

### serve + attach is the closest functional mode (and its one remaining blocker)

In the live loop run with `opencode serve` + a pty-driven `opencode attach`
(production plugin in the project's `.opencode/plugins`, NOTIFY_* to the beta
gateway, `NO_PROXY` set):

- plugin factory invoked in the attach process, `serverUrl` = the serve
  listener (health 200);
- the event hook fired and the **question notification was delivered** through
  the real gateway to the real client;
- the plugin's ControlChannel registered and the instance became
  **CONTROLLABLE** (presence `controllable`) — the control path is open;
- **but** the gateway snapshot (the plugin's `PendingAdapter`, which queries
  the serve via `serverUrl`) returned empty, because the serve holds no pending
  question: the attached session's messages are empty in the serve, the
  question lives in the attach process's private store, and the attach process
  exposes no HTTP listener. The deep-link therefore failed at the focused
  question page, and the answer could not be routed.

**Design-doc flag:** on 1.18.18, the attached-session state (sessions,
messages, pending questions) is kept in the attach process's private store, not
in the reachable `serve` listener the plugin is told about. The plugin's
adapter/version/reply seams assume `input.serverUrl` serves the pending store.

## The notify daemon (honest alternative, kept)

`packages/plugin/scripts/beta/notify-daemon.ts` reproduces the plugin's
**external** wire contract against the real gateway and a real `opencode
serve` instance (whose HTTP listener IS reachable and DOES hold the pending
question created via the V2 API), reusing the production plugin modules:

- notification delivery: subscribes to the real opencode `/api/event` SSE
  stream and, on `question.v2.asked` / `question.v2.replied`, builds the exact
  contract envelopes (`EnvelopeFactory`) and POSTs them to the real gateway
  `/v1/events` HMAC-signed (`GatewaySender`);
- remote unblock: runs the production `ControlChannel` (register +
  pending-snapshot + answer/decision commands) with the production V2 adapters
  (`PendingAdapter` / `QuestionReplyAdapter` / `PermissionReplyAdapter`), so
  the desktop client's event-carried session/request identity is submitted
  directly to the same real opencode session. Command submission is
  best-effort: the Gateway acknowledges delivery without waiting for OpenCode.

The daemon is used because no 1.18.18 launch mode exposes the pending-question
store to the plugin's `serverUrl` (see matrix). Every other part of the loop is
100% production: the gateway, the opencode server and its model turn, the
desktop client, and the assertions against both the gateway and opencode.

## Runner

```bash
bash scripts/beta/closed-loop.sh
```

orchestrates: fake provider → `scripts/beta/stack-up.mjs` (ephemeral postgres
+ migrations + real gateway) → `flutter test integration_test/
live_acceptance_test.dart -d linux` (which itself spawns opencode and the
notify daemon) → full teardown. On success it prints the evidence summary and
writes the curated log above. The integration test is env-gated and skips when
`LIVE_GATEWAY_URL` / `MAILBOX_PATH` are absent.

Related release tooling kept for the record: `scripts/beta/tui-driver.py`
(pty driver, both standalone-TUI and `opencode attach` modes),
`scripts/beta/make-account.mjs` (synthetic account + ingest key through the
real API), and the fake provider's `--hits-file` (one JSON line per
chat-completions request, recording whether a tool-role message carried the
answer sentinel — the same-session-resume observable).

All credentials in the loop are synthetic and scoped to the ephemeral gateway
(one-off user, one-off ingest key); the user's `~/.config/opencode` is never
read, and no user opencode process is ever touched.
