/**
 * Post-build smoke for the installable artifact. Run under BOTH
 * supported plugin runtimes:
 *
 *   node scripts/smoke-dist.mjs
 *   bun scripts/smoke-dist.mjs
 *
 * (also wired as `pnpm smoke:dist` for the Node half)
 *
 * Two invariants are proven against `dist/session-notify.js`:
 *
 * 1. Export shape: the module's own keys are exactly `["default"]` and
 *    the default export is a function. Older OpenCode loaders reject
 *    plugin modules that carry extra named runtime exports, so this is
 *    a hard release gate, not a nicety.
 *
 * 2. Loader behavior without network: the plugin is invoked with a fake
 *    OpenCode host (capturing `app.log` sink + fake `session.get`) and a
 *    `fetch` stub that absorbs every call. No gateway is started and no
 *    credential can leave the process — the stub is installed BEFORE the
 *    module is imported, and the gateway sender captures `fetch` at
 *    construction. A session upsert → busy → question.asked → idle
 *    sequence must flow through the real normalization/ancestry/machine
 *    pipeline without throwing. The question.asked drive exists so the
 *    immediate action_required path — envelope construction plus the
 *    contract validation inlined into the bundle — actually executes in
 *    the artifact. `dispose` must then flush the pending idle as a completed
 *    terminal, so the stubbed fetch is called EXACTLY TWICE, and the dummy
 *    ingest credential must not appear in any captured log entry.
 *
 * Exits non-zero with a message on any failure.
 */

import { fileURLToPath, pathToFileURL } from "node:url";
import { dirname, resolve } from "node:path";

const here = dirname(fileURLToPath(import.meta.url));
const bundlePath = resolve(here, "../dist/session-notify.js");

function fail(message) {
  console.error(`smoke-dist FAIL: ${message}`);
  process.exit(1);
}

// Stub the network before ANY plugin code runs. The stub absorbs calls
// (success response) so a legitimate send completes without a retry loop;
// the exact call count is asserted below.
const fetchCalls = [];
globalThis.fetch = async (_url, init) => {
  fetchCalls.push(JSON.parse(String(init?.body)));
  return new Response("true", { status: 202 });
};

// Valid-but-unreachable configuration; the credential is a dummy that
// only the stubbed fetch could ever observe. The timers are pinned
// explicitly so a caller's NOTIFY_* environment cannot shrink the
// debounce/heartbeat and make the zero-fetch assertion flaky.
process.env.NOTIFY_GATEWAY_URL = "http://localhost:9";
process.env.NOTIFY_INGEST_KEY = "smokekey.smokesecret";
process.env.NOTIFY_IDLE_DEBOUNCE_MS = "15000";
process.env.NOTIFY_HEARTBEAT_MS = "60000";

const mod = await import(pathToFileURL(bundlePath).href);

// --- Invariant 1: exact export shape -----------------------------------
const keys = Object.keys(mod);
if (keys.length !== 1 || keys[0] !== "default") {
  fail(`module exports ${JSON.stringify(keys)}, expected exactly ["default"]`);
}
if (typeof mod.default !== "function") {
  fail(`default export is ${typeof mod.default}, expected function`);
}

// --- Invariant 2: loads and handles events with no network --------------
const logs = [];
const client = {
  app: {
    log: async ({ body }) => {
      logs.push(body);
    },
  },
  session: {
    get: async ({ path }) => ({
      data: { id: path.id, parentID: null, title: "smoke session" },
    }),
  },
};
const input = {
  client,
  project: { id: "smoke-project" },
  directory: "/tmp",
  worktree: "/tmp",
};

const hooks = await mod.default(input);
if (typeof hooks.event !== "function" || typeof hooks.dispose !== "function") {
  fail(`expected {event, dispose} hooks, got ${JSON.stringify(Object.keys(hooks).sort())}`);
}

await hooks.event({
  event: {
    type: "session.updated",
    properties: { info: { id: "ses_smoke", title: "smoke session" } },
  },
});
await hooks.event({
  event: { type: "session.status", properties: { sessionID: "ses_smoke", status: { type: "busy" } } },
});
// Immediate action: envelope construction and the inlined contract
// validation execute in the artifact, and the send is attempted at once.
await hooks.event({
  event: {
    type: "question.asked",
    properties: {
      id: "qst_smoke1",
      sessionID: "ses_smoke",
      questions: [
        {
          question: "Proceed with the smoke migration?",
          options: [{ label: "Yes" }, { label: "No" }],
        },
      ],
    },
  },
});
await hooks.event({
  event: { type: "session.status", properties: { sessionID: "ses_smoke", status: { type: "idle" } } },
});
await hooks.dispose();

// The immediate action and shutdown-flushed completion must both traverse
// the installed artifact's real envelope, validation, queue, and sender.
if (
  fetchCalls.length !== 2 ||
  fetchCalls[0]?.type !== "action_required" ||
  fetchCalls[1]?.type !== "terminal" ||
  fetchCalls[1]?.payload?.outcome !== "completed"
) {
  fail(
    `stubbed fetch events were ${JSON.stringify(fetchCalls.map((event) => [event?.type, event?.payload?.outcome]))}; expected action_required then terminal/completed`,
  );
}

// Computed, not assumed: scan every captured log entry for either part
// of the dummy credential and report what was actually found.
const serializedLogs = JSON.stringify(logs);
const credentialLeak =
  serializedLogs.includes("smokekey") || serializedLogs.includes("smokesecret");
if (credentialLeak) {
  fail("ingest credential appeared in a log entry");
}

console.log(
  JSON.stringify({
    runtime: process.versions.bun ? `bun ${process.versions.bun}` : `node ${process.version}`,
    exports: keys,
    defaultType: typeof mod.default,
    hooks: Object.keys(hooks).sort(),
    stubbedFetchCalls: fetchCalls.length,
    logEntries: logs.length,
    credentialLeak,
  }),
);
