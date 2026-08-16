# Remote Unblock Phase 1

Status: designed and protocol-prototyped against OpenCode `1.18.18` on
2026-08-14.

PRD: [GitHub issue #6](https://github.com/brilliantrough/opencode-notify-hub/issues/6)

## Goal

Deliver a daily-usable Beta in which a user receives an OpenCode notification
on another Linux or Windows desktop, opens the authoritative pending request,
answers it, and sees the same OpenCode session resume. The first live acceptance
environment is a Linux OpenCode host and Linux desktop client.

## Included

- list pending OpenCode questions and permissions;
- notification deep links to a focused request page;
- multi-question forms submitted atomically;
- single-select, multi-select, and custom text answers;
- permission responses: allow once, always allow, and reject;
- multiple concurrent OpenCode Servers on one machine;
- automatic synchronization on client start, login recovery, and Plugin
  reconnect;
- read-only last-known requests while an instance is offline;
- explicit sent, rejected, and result-unknown client submission states, with
  body-free terminal outcomes retained only for diagnostics.

## Not Included

- free-form session prompts, message history, or recent conversation excerpts;
- session abort, question reject, or offline answer queues;
- Android interaction UI or notification actions;
- provider-specific actions beyond existing notifications and links;
- generic OpenCode HTTP port forwarding or a full remote WebUI;
- team sharing across separate user accounts;
- persistent interaction or audit history.

## Runtime Contract

- Officially supported launch modes are `opencode serve` and `opencode web`.
- Phase 1 is pinned to OpenCode `1.18.18`. An incompatible version continues to
  send ordinary notifications but is not remotely actionable.
- A machine is configured once with the existing Gateway URL, Plugin key, and
  machine name. No second key or per-launch configuration is introduced.
- A machine may run several Servers, but only one remotely actionable instance
  may own a given project directory. The first registration wins; a duplicate
  instance keeps notification delivery but its control registration is rejected.
- OpenCode loads the project Plugin lazily on the first directory-scoped request,
  not merely when the HTTP listener starts.
- **Launch-mode matrix (1.18.18, verified 2026-08-15):** the interactive
  plugin-hosting modes are the supported ones — the TUI (`opencode` in a pty)
  and `opencode attach` invoke the Plugin factory and its event hook (so
  notifications work); `opencode run` invokes it but denies the question tool
  headless (notifications only); `opencode serve` and `opencode web` import
  the plugin module lazily but never invoke the factory (verified with marker
  probes). In the standalone TUI, `input.serverUrl` (`http://localhost:4096/`)
  has no reachable listener (verified with `NO_PROXY` + direct `node:http` →
  `ECONNREFUSED`; the TUI process has no LISTEN socket), so the control channel
  registers `incompatible(unknown)`. In `serve + attach`, the factory is
  invoked in the attach process, the event hook works, and the ControlChannel
  registers CONTROLLABLE — but the attached session's state (sessions,
  messages, pending questions) lives in the attach process's private store,
  not in the reachable serve listener the plugin is told about (the serve
  reports an empty question list and empty session messages for the attached
  session), so the plugin's pending/reply adapters never see the question and
  the answer round-trip cannot complete. Plugin version resolution and
  adapters must not assume `input.client.global.health` exists, that the
  embedded server serves the API on 1.18.18, or that `input.serverUrl` holds
  the pending store. Plugin→OpenCode loopback traffic must bypass host proxies
  (`direct-fetch.ts`). See docs/beta-evidence/README.md.

## Architecture

```text
Desktop client -- HTTPS commands --> Gateway
Desktop client <-- existing WSS ---- Gateway
                                      |
                                      | per-instance outbound WSS
                                      v
                                  Notify Plugin
                                      |
                                      | OpenCode V2 SDK over serverUrl
                                      v
                                OpenCode 1.18.18
```

Each Plugin instance opens an outbound control WebSocket after Plugin
initialization. It registers machine, project, OpenCode version, runtime
instance ID, and supported protocol version. The event hook remains
non-blocking and independent from this control loop.

The Plugin must not call its own OpenCode HTTP listener while its initialization
function is still awaited. The listener does not become available until Plugin
initialization returns; doing so deadlocks Server startup. OpenCode SDK calls
start asynchronously after hooks have been returned.

Client commands use authenticated HTTPS. Gateway routes them to the owning
Plugin connection. Client WebSocket frames carry instance presence, pending
snapshots/deltas, and command outcomes; the client WebSocket remains
server-to-client only.

## State Authority

OpenCode is authoritative. On `1.18.18` the working read path is the **V2
location-scoped pending lists** — `v2.question.request.list` and
`v2.permission.request.list`, both called with `location.directory` — and the
working reply path is the **V2 session-scoped replies** —
`v2.session.question.reply` and `v2.session.permission.reply`. The V1 global
`/question` and `/permission` lists and replies do **not** see natural pending
state on this build (empty lists, `404` replies) and are not used. Gateway
notification events and client state are projections only.

- Online: synchronize pending requests from the Plugin/OpenCode V2 pending
  lists.
- Offline: retain the last-known request as read-only and label its state
  unknown with the instance's last-online time.
- Reconnected: replace projections with a fresh authoritative snapshot.
- No offline command queue is allowed.

Gateway retains command outcome metadata by `commandId` in memory for about ten
minutes. It does not persist request bodies, answers, permission decisions, or
OpenCode interaction state.

## Question UX

- The focused page shows machine, project, session title, all questions, option
  descriptions, and one final submit action.
- All required questions must be answered before the request is submitted.
- Single-select accepts one option or one custom answer.
- Multi-select accepts options plus a custom answer.
- OpenCode `1.18.18` accepts custom answers even though the pending question
  payload omits a `custom` flag. Phase 1 therefore offers custom text for every
  question.
- Closing or navigating back does not call `question.reject`; the request stays
  pending.

## Permission UX

The page shows the unabridged machine, project, session, permission type,
`patterns`, `always` patterns, tool identity, command/path, and metadata.

- Allow once and reject are immediate actions.
- Always allow is shown only when OpenCode returns at least one `always` pattern.
- Selecting always allow opens a second confirmation that displays the exact
  patterns OpenCode will save.
- Only the second confirmation submits the `always` response.

This confirmation is required because the prototype proved that an `always`
response for `printf prototype-always` saved `printf *` and automatically
allowed a matching command in a newly created session.

## Workbench UX

The existing home page becomes a pending-first workbench:

1. actionable online requests, oldest waiting first;
2. read-only last-known requests in a separate offline section;
3. the existing active-session overview.

Notification clicks preserve their request target through login and reconnect.
After synchronization, an already-resolved target reports that it was handled
elsewhere and returns to the workbench.

## Command Semantics

- Every submission has a client-generated `commandId`.
- Every submission carries the `sessionId` captured with the original pending
  interaction, so the Plugin can call the V2 session-scoped reply directly.
- The Gateway returns `202 accepted` as soon as it writes the command to the
  owning Plugin connection. This means sent, not OpenCode-confirmed.
- The client optimistically removes an accepted request and does not query the
  terminal outcome or reconcile a fresh pending snapshot.
- OpenCode remains the final arbiter. If somebody already handled the request,
  the direct reply is stale and becomes a no-op.
- The Gateway retains body-free terminal outcomes for diagnostics only.
- No offline queue is introduced and clients do not automatically resubmit.

## Identity And Privacy

Only the account that owns the configured Plugin key can view or answer its
instances. Phase 1 deliberately reuses that key for notifications and remote
control. Revoking it disables both capabilities.

Complete interaction payloads are relayed without secret masking. They travel
through Gateway memory and to the desktop client over TLS but are never written
to the database or application logs. Gateway log-redaction rules must cover all
interaction request, response, and error bodies.

Only upgraded Plugins establish the control WSS. Older Plugins continue to send
notifications without configuration migration or control capability.

## Protocol Prototype Findings

A throwaway harness started two isolated real `opencode serve` processes and
loaded a probe Plugin in each. It established all of the following on version
`1.18.18`:

- Plugin input exposes the instance-specific `serverUrl`;
- a Plugin-created `@opencode-ai/sdk/v2` client exposes the question and
  permission V2 list/reply APIs (`v2.question.request.list`,
  `v2.permission.request.list`, `v2.session.question.reply`,
  `v2.session.permission.reply`);
- a pending two-question request is recoverable from a newly created SDK client;
- arbitrary custom text and a multi-select plus custom answer are accepted;
- the second Server does not see the first Server's pending request;
- `once`, `always`, and `reject` permission replies clear their requests;
- pending state survives client reconnection while the Server remains alive;
- synchronous self-HTTP during Plugin initialization deadlocks startup and must
  be deferred.

The prototype sessions, fixture directories, processes, package script, and
harness source were removed after recording these results.

> **Historical note (superseded).** The original prototype conclusion treated
> OpenCode's V1 global `/question` and `/permission` paths as authoritative.
> That conclusion was superseded by the release smoke finding against a real
> `1.18.18` server: the V1 global lists/replies do **not** see natural pending
> state (empty lists, `404` replies), while the V2 location-scoped lists and
> V2 session-scoped replies above are the working authoritative APIs. The
> finding is the hard Proof 8 (P8, gates the exit code) in
> `packages/plugin/scripts/opencode-smoke.mjs`, which exercises exactly those
> V2 paths against natural model-turn state.

## Beta Acceptance Matrix

- Linux Server to Linux desktop completes the full notification-to-resume loop.
- Windows and Linux desktop builds compile and pass automated interaction tests.
- One machine can route two different project Servers without cross-delivery.
- A duplicate same-project Server is rejected from control without losing
  ordinary notifications.
- Single, multi, multi-question, and custom answers resume the correct session.
- Permission once, confirmed always, and reject resume the correct session.
- Two clients racing the same request may both receive `accepted`; OpenCode
  applies the first valid reply and treats the later reply as stale.
- Client restart, login refresh, Plugin reconnect, offline display, and stale
  local requests remain best-effort projections rather than a consistency
  protocol.
- Interaction bodies are absent from the database and production logs.
