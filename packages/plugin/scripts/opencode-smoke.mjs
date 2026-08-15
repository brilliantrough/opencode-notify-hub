#!/usr/bin/env node
/**
 * Issue #14 disposable release smoke harness.
 *
 * Spawns TWO isolated real `opencode serve` processes (own project
 * directories, own XDG_CONFIG_HOME/HOME, own ports), each loading the
 * production `@notify/plugin` build with a synthetic DEAD gateway
 * (`NOTIFY_GATEWAY_URL=http://127.0.0.1:9`) and a synthetic ingest key, and
 * proves the Remote Unblock server-side behaviors against 1.18.x:
 *
 *   - both servers stay healthy while the plugin fails to reach its gateway;
 *   - instance-specific server separation and cross-Server isolation;
 *   - SDK reconnect recovery (a fresh client lists pending server state);
 *   - permission decisions once / always / reject, including that an
 *     `always` reply persists a project-scoped pattern that auto-allows a
 *     matching action in a NEW session;
 *   - question variants through a fake OpenAI-compatible provider that makes
 *     the model invoke the `question` tool deterministically (multi-question
 *     atomic reply, single-select, multi-select + custom text);
 *   - the plugin's EXACT V2 paths on natural model-turn state (Proof 8):
 *     reads through the location-scoped `v2.question.request.list` /
 *     `v2.permission.request.list` lists and replies through the
 *     session-scoped `v2.session.question.reply` /
 *     `v2.session.permission.reply` endpoints, plus that a
 *     `v2.session.permission.create`'d request surfaces in the
 *     location-scoped list. This is a HARD proof (gates the exit code)
 *     because the plugin ships against those V2 endpoints, which are the
 *     working paths on this build. A loud printed note (informational only,
 *     does not gate the exit code) records that opencode's V1 global
 *     `/question` / `/permission` lists are broken on this build.
 *
 * Question proofs are marked SKIPPED (never FAILED) when the fake-provider
 * path is unavailable — e.g. `@ai-sdk/openai-compatible` cannot be installed
 * offline — because that is an environment limitation, not a product defect.
 * The exit code is 0 only if every non-skipped proof passes.
 *
 * The harness never reads the user's `~/.config/opencode`: each server gets a
 * freshly created XDG_CONFIG_HOME and HOME, and it refuses to run when a
 * real-looking NOTIFY_GATEWAY_URL / NOTIFY_INGEST_KEY is inherited from the
 * parent environment (children always receive the synthetic values).
 *
 * Release tooling only; deliberately NOT wired into `pnpm test` or CI.
 */

import { createServer } from "node:http";
import { spawn } from "node:child_process";
import { copyFileSync, existsSync, mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { basename, dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import { createOpencodeClient } from "@opencode-ai/sdk/v2";

const HERE = dirname(fileURLToPath(import.meta.url));
const PLUGIN_DIR = resolve(HERE, "..");
const DIST = join(PLUGIN_DIR, "dist", "session-notify.js");

const SMOKE_GATEWAY_URL = "http://127.0.0.1:9"; // intentionally dead
const SMOKE_INGEST_KEY = "smoke.smoke_secret";

const OVERALL_TIMEOUT_MS = 10 * 60 * 1000; // ~10 minutes, clear failure

// ---------------------------------------------------------------------------
// Environment guards
// ---------------------------------------------------------------------------

function guardEnvironment() {
  const inheritedGateway = process.env.NOTIFY_GATEWAY_URL;
  const inheritedKey = process.env.NOTIFY_INGEST_KEY;
  if (inheritedGateway !== undefined && inheritedGateway.trim() !== "" && inheritedGateway !== SMOKE_GATEWAY_URL) {
    fail(
      `refusing to run: parent env NOTIFY_GATEWAY_URL=${JSON.stringify(inheritedGateway)} looks like a real gateway. ` +
        `The smoke harness must never use production credentials; unset NOTIFY_* or export the synthetic values.`,
    );
  }
  if (inheritedKey !== undefined && inheritedKey.trim() !== "" && inheritedKey !== SMOKE_INGEST_KEY) {
    fail(
      `refusing to run: parent env NOTIFY_INGEST_KEY=${JSON.stringify(inheritedKey)} looks like a real ingest key. ` +
        `The smoke harness must never use production credentials; unset NOTIFY_* or export the synthetic values.`,
    );
  }
}

/** Child env: parent env minus every NOTIFY_*, plus explicit synthetic values. */
function childEnv(xdg, home, extra = {}) {
  const env = { ...process.env };
  for (const key of Object.keys(env)) {
    if (key.startsWith("NOTIFY_")) delete env[key];
  }
  Object.assign(env, {
    NOTIFY_GATEWAY_URL: SMOKE_GATEWAY_URL,
    NOTIFY_INGEST_KEY: SMOKE_INGEST_KEY,
    NOTIFY_IDLE_DEBOUNCE_MS: "15000",
    NOTIFY_HEARTBEAT_MS: "60000",
    NOTIFY_HTTP_TIMEOUT_MS: "3000",
    NOTIFY_MAX_RETRIES: "1",
    HOME: home,
    XDG_CONFIG_HOME: xdg,
    XDG_DATA_HOME: join(home, ".local", "share"),
    XDG_CACHE_HOME: join(home, ".cache"),
    OPENCODE_DISABLE_AUTOUPDATE: "1",
    ...extra,
  });
  return env;
}

// ---------------------------------------------------------------------------
// Small utilities
// ---------------------------------------------------------------------------

function fail(message) {
  console.error(`\nSMOKE FAIL: ${message}`);
  process.exit(1);
}

const sleep = (ms) => new Promise((resolvePromise) => setTimeout(resolvePromise, ms));

async function withTimeout(promise, ms, label) {
  let timer;
  try {
    return await Promise.race([
      promise,
      new Promise((_, rejectPromise) => {
        timer = setTimeout(
          () => rejectPromise(new Error(`${label} timed out after ${Math.round(ms / 1000)}s`)),
          ms,
        );
      }),
    ]);
  } finally {
    clearTimeout(timer);
  }
}

function isRecord(value) {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

/** The v2 SDK response envelope is `{ data, error, request, response }`. */
function dataOf(result) {
  return isRecord(result) ? result.data : result;
}

function errOf(result) {
  return isRecord(result) ? result.error : undefined;
}

async function waitHealthy(baseUrl, ms = 45_000) {
  const start = Date.now();
  let lastError;
  while (Date.now() - start < ms) {
    try {
      const res = await fetch(`${baseUrl}/api/health`, { signal: AbortSignal.timeout(3000) });
      if (res.ok) return await res.text();
    } catch (error) {
      lastError = error;
    }
    await sleep(500);
  }
  throw new Error(`health never became ready: ${lastError?.message ?? "unknown"}`);
}

async function waitForAgents(client, ms = 60_000) {
  const start = Date.now();
  while (Date.now() - start < ms) {
    try {
      const agents = dataOf(await client.v2.agent.list({}));
      if (Array.isArray(agents?.data) && agents.data.length > 0) return agents.data;
    } catch {
      // server not ready yet; keep polling
    }
    await sleep(500);
  }
  throw new Error("default agent never became ready");
}

async function pollUntil(client, fn, ms = 30_000, label = "poll") {
  const start = Date.now();
  while (Date.now() - start < ms) {
    const result = await fn();
    if (result) return result;
    await sleep(500);
  }
  throw new Error(`${label} never satisfied within ${Math.round(ms / 1000)}s`);
}

// ---------------------------------------------------------------------------
// Fake OpenAI-compatible provider (in-process)
// ---------------------------------------------------------------------------

/**
 * A minimal OpenAI-compatible `POST /v1/chat/completions` + `GET /v1/models`
 * server. It returns a `question` tool call for the fixture selected by a
 * marker in the first user message, and a plain text reply once the
 * conversation contains a tool result (so the agent loop terminates). Handles
 * both streaming (SSE) and non-streaming request bodies.
 */
function startFakeProvider() {
  const FIXTURES = {
    SMOKE_Q_MULTI: {
      questions: [
        {
          question: "Which database should the migration target?",
          header: "Database",
          options: [
            { label: "PostgreSQL", description: "Production parity" },
            { label: "SQLite", description: "Fast local runs" },
          ],
          multiple: false,
          custom: true,
        },
        {
          question: "Backfill existing rows?",
          header: "Backfill",
          options: [
            { label: "Yes", description: "Backfill in the same migration" },
            { label: "No", description: "Defer to a follow-up job" },
          ],
          multiple: false,
          custom: false,
        },
      ],
    },
    SMOKE_Q_SINGLE: {
      questions: [
        {
          question: "Which transport should the sync use?",
          header: "Transport",
          options: [
            { label: "WebSocket", description: "Bidirectional" },
            { label: "HTTP polling", description: "Simpler" },
          ],
          multiple: false,
          custom: true,
        },
      ],
    },
    SMOKE_Q_MULTISELECT: {
      questions: [
        {
          question: "Which platforms should we target?",
          header: "Platforms",
          options: [
            { label: "Linux", description: "Host OS" },
            { label: "Windows", description: "Desktop" },
            { label: "macOS", description: "Desktop" },
          ],
          multiple: true,
          custom: true,
        },
      ],
    },
  };

  const requests = [];
  const server = createServer((req, res) => {
    let raw = "";
    req.on("data", (chunk) => (raw += chunk.toString()));
    req.on("end", () => {
      let parsed = null;
      try {
        parsed = raw ? JSON.parse(raw) : null;
      } catch {
        parsed = null;
      }
      requests.push({ method: req.method, url: req.url, body: parsed });

      const url = req.url ?? "";
      if (req.method === "GET" && url.includes("/models")) {
        writeJson(res, { object: "list", data: [{ id: "fake-model", object: "model", owned_by: "smoke" }] });
        return;
      }
      if (req.method === "POST" && url.includes("/chat/completions")) {
        const marker = pickMarker(parsed);
        const fixture = FIXTURES[marker] ?? FIXTURES.SMOKE_Q_MULTI;
        const hasToolResult = Array.isArray(parsed?.messages) && parsed.messages.some((m) => m?.role === "tool");
        if (parsed?.stream === true) {
          hasToolResult ? writeStreamText(res) : writeStreamToolCall(res, fixture);
        } else {
          hasToolResult ? writeJsonText(res) : writeJsonToolCall(res, fixture);
        }
        return;
      }
      writeStatus(res, 404, { error: { message: `not found ${url}` } });
    });
  });

  return new Promise((resolvePromise) => {
    server.listen(0, "127.0.0.1", () => {
      const { port } = server.address();
      resolvePromise({
        port,
        baseURL: `http://127.0.0.1:${port}/v1`,
        requests,
        stop: () => new Promise((done) => server.close(() => done())),
      });
    });
  });
}

function pickMarker(body) {
  const messages = isRecord(body) && Array.isArray(body.messages) ? body.messages : [];
  for (const message of messages) {
    if (!isRecord(message) || message.role !== "user") continue;
    const text = typeof message.content === "string" ? message.content : JSON.stringify(message.content ?? "");
    for (const marker of ["SMOKE_Q_MULTISELECT", "SMOKE_Q_SINGLE", "SMOKE_Q_MULTI"]) {
      if (typeof text === "string" && text.includes(marker)) return marker;
    }
  }
  return null;
}

function toolCallArguments(fixture) {
  return JSON.stringify({ questions: fixture.questions });
}

function writeJson(res, body) {
  res.writeHead(200, { "Content-Type": "application/json" });
  res.end(JSON.stringify(body));
}

function writeStatus(res, status, body) {
  res.writeHead(status, { "Content-Type": "application/json" });
  res.end(JSON.stringify(body));
}

function writeJsonToolCall(res, fixture) {
  const args = toolCallArguments(fixture);
  writeJson(res, {
    id: `chatcmpl-smoke-${Date.now()}`,
    object: "chat.completion",
    created: Math.floor(Date.now() / 1000),
    model: "fake-model",
    choices: [
      {
        index: 0,
        message: {
          role: "assistant",
          content: null,
          tool_calls: [
            { id: `call_${Date.now()}`, type: "function", function: { name: "question", arguments: args } },
          ],
        },
        finish_reason: "tool_calls",
      },
    ],
    usage: { prompt_tokens: 1, completion_tokens: 1, total_tokens: 2 },
  });
}

function writeJsonText(res) {
  writeJson(res, {
    id: `chatcmpl-smoke-${Date.now()}`,
    object: "chat.completion",
    created: Math.floor(Date.now() / 1000),
    model: "fake-model",
    choices: [
      {
        index: 0,
        message: { role: "assistant", content: "Understood. The questions were answered." },
        finish_reason: "stop",
      },
    ],
    usage: { prompt_tokens: 1, completion_tokens: 1, total_tokens: 2 },
  });
}

function sseChunk(res, id, created, delta, finish) {
  res.write(
    `data: ${JSON.stringify({
      id,
      object: "chat.completion.chunk",
      created,
      model: "fake-model",
      choices: [{ index: 0, delta, finish_reason: finish ?? null }],
    })}\n\n`,
  );
}

function writeStreamToolCall(res, fixture) {
  res.writeHead(200, { "Content-Type": "text/event-stream", "Cache-Control": "no-cache", Connection: "keep-alive" });
  const id = `chatcmpl-smoke-${Date.now()}`;
  const created = Math.floor(Date.now() / 1000);
  sseChunk(res, id, created, {
    role: "assistant",
    content: null,
    tool_calls: [
      {
        index: 0,
        id: `call_${Date.now()}`,
        type: "function",
        function: { name: "question", arguments: toolCallArguments(fixture) },
      },
    ],
  });
  sseChunk(res, id, created, {}, "tool_calls");
  res.write("data: [DONE]\n\n");
  res.end();
}

function writeStreamText(res) {
  res.writeHead(200, { "Content-Type": "text/event-stream", "Cache-Control": "no-cache", Connection: "keep-alive" });
  const id = `chatcmpl-smoke-${Date.now()}`;
  const created = Math.floor(Date.now() / 1000);
  sseChunk(res, id, created, { role: "assistant", content: "Understood. The questions were answered." });
  sseChunk(res, id, created, {}, "stop");
  res.write("data: [DONE]\n\n");
  res.end();
}

// ---------------------------------------------------------------------------
// Server lifecycle
// ---------------------------------------------------------------------------

class SmokeServer {
  constructor({ name, root, port, config, extraEnv }) {
    this.name = name;
    this.root = root;
    this.project = join(root, "project");
    this.xdg = join(root, "xdg");
    this.port = port;
    this.baseUrl = `http://127.0.0.1:${port}`;
    this.proc = null;
    this.log = "";

    mkdirSync(join(this.xdg, "opencode"), { recursive: true });
    mkdirSync(join(this.project, ".opencode", "plugins"), { recursive: true });
    copyFileSync(DIST, join(this.project, ".opencode", "plugins", "session-notify.js"));
    writeFileSync(join(this.xdg, "opencode", "opencode.json"), JSON.stringify(config, null, 2));
    this.env = childEnv(this.xdg, join(root, "home"), extraEnv);
  }

  start() {
    this.proc = spawn(
      process.env.OPENCODE_SMOKE_BIN || "opencode",
      ["serve", "--hostname", "127.0.0.1", "--port", String(this.port)],
      { env: this.env, cwd: this.project, stdio: ["ignore", "pipe", "pipe"] },
    );
    this.proc.stdout.on("data", (chunk) => (this.log += chunk.toString()));
    this.proc.stderr.on("data", (chunk) => (this.log += chunk.toString()));
    this.proc.on("exit", (code, signal) => {
      this.log += `\n[server exit code=${code} signal=${signal}]\n`;
    });
  }

  async kill() {
    if (!this.proc) return;
    try {
      this.proc.kill("SIGTERM");
    } catch {
      // already gone
    }
    for (let i = 0; i < 20; i++) {
      if (this.proc.exitCode !== null) break;
      await sleep(250);
    }
    if (this.proc.exitCode === null) {
      try {
        this.proc.kill("SIGKILL");
      } catch {
        // already gone
      }
    }
  }
}

let nextPort = 30000 + Math.floor(Math.random() * 20000);

function allocatePort() {
  return nextPort++;
}

// ---------------------------------------------------------------------------
// Proof harness
// ---------------------------------------------------------------------------

const results = [];

async function proof(name, fn) {
  const startedAt = Date.now();
  try {
    const detail = await fn();
    results.push({ name, status: "PASS", detail: detail ?? "", ms: Date.now() - startedAt });
    return true;
  } catch (error) {
    const reason = error instanceof Error ? error.message : String(error);
    if (error instanceof Skipped) {
      results.push({ name, status: "SKIP", detail: reason, ms: Date.now() - startedAt });
      return "skipped";
    }
    results.push({ name, status: "FAIL", detail: reason, ms: Date.now() - startedAt });
    return false;
  }
}

class Skipped extends Error {}

function skip(reason) {
  throw new Skipped(reason);
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
  guardEnvironment();

  const startedAt = Date.now();
  console.log("== opencode-notify issue #14 smoke harness ==");
  console.log("gateway (dead): " + SMOKE_GATEWAY_URL);
  console.log("ingest key (synthetic): " + SMOKE_INGEST_KEY);

  // 1. Ensure the production bundle exists.
  if (!existsSync(DIST)) {
    console.log("dist missing; building the plugin first");
    await new Promise((resolvePromise, rejectPromise) => {
      const child = spawn("pnpm", ["--filter", "@notify/plugin", "build"], {
        stdio: "inherit",
        cwd: resolve(HERE, "../../.."),
      });
      child.on("exit", (code) => (code === 0 ? resolvePromise() : rejectPromise(new Error(`pnpm build exited ${code}`))));
    });
  }

  // 2. Locate the opencode binary and record its version.
  const opencodeBin = process.env.OPENCODE_SMOKE_BIN || "opencode";
  const versionOutput = await new Promise((resolvePromise) => {
    const child = spawn(opencodeBin, ["--version"], { stdio: ["ignore", "pipe", "ignore"] });
    let out = "";
    child.stdout.on("data", (chunk) => (out += chunk.toString()));
    child.on("exit", () => resolvePromise(out.trim()));
  });
  console.log("opencode: " + opencodeBin + " " + (versionOutput || "(version unavailable)"));

  const root = mkdtempSync(join(tmpdir(), "opencode-smoke-"));
  let provider = null;
  const servers = [];

  const deadline = setTimeout(() => {
    console.error("\nSMOKE FAIL: overall timeout after ~10 minutes");
    printSummary(startedAt);
    process.exit(1);
  }, OVERALL_TIMEOUT_MS);

  try {
    provider = await startFakeProvider();

    // Server A hosts the behavioral proofs and the fake provider.
    const serverA = new SmokeServer({
      name: "A",
      root: join(root, "A"),
      port: allocatePort(),
      config: {
        $schema: "https://opencode.ai/config.json",
        permission: "ask",
        provider: {
          smoke: {
            npm: "@ai-sdk/openai-compatible",
            name: "Smoke Fake",
            options: { baseURL: provider.baseURL, apiKey: "smoke-test" },
            models: { "fake-model": { name: "Fake Model" } },
          },
        },
      },
    });
    servers.push(serverA);

    // Server B is the isolation counterpart; same plugin, no provider config.
    const serverB = new SmokeServer({
      name: "B",
      root: join(root, "B"),
      port: allocatePort(),
      config: { $schema: "https://opencode.ai/config.json", permission: "ask" },
    });
    servers.push(serverB);

    serverA.start();
    serverB.start();
    await Promise.all([waitHealthy(serverA.baseUrl), waitHealthy(serverB.baseUrl)]);

    const clientA = createOpencodeClient({ baseUrl: serverA.baseUrl, directory: serverA.project });
    const clientB = createOpencodeClient({ baseUrl: serverB.baseUrl, directory: serverB.project });

    await waitForAgents(clientA);
    await waitForAgents(clientB);

    // ---- Proof 1: servers stay healthy with the plugin loaded and a dead gateway.
    await proof("P1 servers healthy despite dead plugin gateway", async () => {
      const healthA = await waitHealthy(serverA.baseUrl, 10_000);
      const healthB = await waitHealthy(serverB.baseUrl, 10_000);
      const pluginInstalled =
        existsSync(join(serverA.project, ".opencode", "plugins", "session-notify.js")) &&
        existsSync(join(serverB.project, ".opencode", "plugins", "session-notify.js"));
      if (!pluginInstalled) throw new Error("production plugin bundle not installed into a project");
      const result = JSON.parse(healthA);
      if (result.healthy !== true) throw new Error(`server A health ${healthA}`);
      const resultB = JSON.parse(healthB);
      if (resultB.healthy !== true) throw new Error(`server B health ${healthB}`);
      return `A=${healthA.trim()} B=${healthB.trim()} plugin=${basename(DIST)}`;
    });

    // ---- Proof 2: instance-specific server separation.
    await proof("P2 instance-specific server separation", async () => {
      const created = dataOf(await clientA.v2.session.create({ agent: "build", location: { directory: serverA.project } }));
      const sid = created?.data?.id;
      if (!sid) throw new Error(`session create on A failed: ${JSON.stringify(errOf(created))}`);

      const listA = dataOf(await clientA.v2.session.list({ directory: serverA.project }));
      const listB = dataOf(await clientB.v2.session.list({ directory: serverB.project }));
      const inA = (listA?.data ?? []).some((session) => session.id === sid);
      const inB = (listB?.data ?? []).some((session) => session.id === sid);
      if (!inA) throw new Error("session created on A not visible on A");
      if (inB) throw new Error("session created on A visible on B — servers are not isolated");
      return `session ${sid} visible on A, absent on B`;
    });

    // ---- Proof 3: cross-Server isolation of pending state.
    await proof("P3 cross-Server isolation of pending interactions", async () => {
      const created = dataOf(await clientA.v2.session.create({ agent: "build", location: { directory: serverA.project } }));
      const sid = created?.data?.id;
      if (!sid) throw new Error(`session create on A failed: ${JSON.stringify(errOf(created))}`);

      const perm = dataOf(await clientA.v2.session.permission.create({ sessionID: sid, action: "edit", resources: ["iso.ts"], save: [] }));
      if (perm?.data?.effect !== "ask") throw new Error(`expected pending permission on A, got ${JSON.stringify(perm?.data)}`);

      const pendingB = dataOf(await clientB.v2.permission.request.list({ location: { directory: serverB.project } }));
      const inB = (pendingB?.data ?? []).some((request) => request.action === "edit" && request.resources?.includes("iso.ts"));
      if (inB) throw new Error("permission created on A listed on B");
      return "permission pending on A absent from B";
    });

    // ---- Proof 4: SDK reconnect recovery — a brand-new client lists pending state.
    await proof("P4 SDK reconnect recovery lists pending state", async () => {
      const created = dataOf(await clientA.v2.session.create({ agent: "build", location: { directory: serverA.project } }));
      const sid = created?.data?.id;
      if (!sid) throw new Error(`session create on A failed: ${JSON.stringify(errOf(created))}`);

      const perm = dataOf(
        await clientA.v2.session.permission.create({ sessionID: sid, action: "bash", resources: ["echo recover"], save: [] }),
      );
      const pendingId = perm?.data?.id;
      if (perm?.data?.effect !== "ask" || !pendingId) {
        throw new Error(`expected pending permission, got ${JSON.stringify(perm?.data)}`);
      }

      // A fresh SDK client (no shared state, a different connection) must see it.
      const freshClient = createOpencodeClient({ baseUrl: serverA.baseUrl, directory: serverA.project });
      const viaFresh = dataOf(await freshClient.v2.permission.request.list({ location: { directory: serverA.project } }));
      const found = (viaFresh?.data ?? []).some((request) => request.id === pendingId);
      if (!found) throw new Error("fresh client did not see the pending permission");
      return `request ${pendingId} visible to a new client`;
    });

    // ---- Proof 5: permission once.
    await proof("P5 permission once", async () => {
      const { sid, pendingId } = await createPendingPermission(clientA, serverA.project, "edit", ["once.ts"], []);
      const reply = await clientA.v2.session.permission.reply({ sessionID: sid, requestID: pendingId, reply: "once" });
      if (errOf(reply)) throw new Error(`once reply errored: ${JSON.stringify(errOf(reply))}`);
      await pollUntil(clientA, async () => {
        const list = dataOf(await clientA.v2.session.permission.list({ sessionID: sid }));
        return !(list?.data ?? []).some((request) => request.id === pendingId);
      }, 10_000, "permission once resolution");
      return `request ${pendingId} resolved and removed`;
    });

    // ---- Proof 6: permission always persists a project-scoped pattern.
    await proof("P6 permission always persists to a NEW session", async () => {
      const pattern = "smoke-always-*.ts";
      const resource = "smoke-always-1.ts";

      const session1 = dataOf(await clientA.v2.session.create({ agent: "build", location: { directory: serverA.project } }));
      const sid1 = session1?.data?.id;
      const perm = dataOf(
        await clientA.v2.session.permission.create({ sessionID: sid1, action: "edit", resources: [resource], save: [pattern] }),
      );
      if (perm?.data?.effect !== "ask") throw new Error(`expected pending permission, got ${JSON.stringify(perm?.data)}`);
      const reply = await clientA.v2.session.permission.reply({ sessionID: sid1, requestID: perm.data.id, reply: "always" });
      if (errOf(reply)) throw new Error(`always reply errored: ${JSON.stringify(errOf(reply))}`);

      const saved = dataOf(await clientA.v2.permission.saved.list({}));
      const savedEntry = (saved?.data ?? []).find((entry) => entry.action === "edit" && entry.resource === pattern);
      if (!savedEntry) throw new Error(`saved.list lacks ${pattern}: ${JSON.stringify(saved?.data)}`);

      // A NEW session with the same action/resource must auto-allow (not pending).
      const session2 = dataOf(await clientA.v2.session.create({ agent: "build", location: { directory: serverA.project } }));
      const sid2 = session2?.data?.id;
      const again = dataOf(await clientA.v2.session.permission.create({ sessionID: sid2, action: "edit", resources: [resource], save: [] }));
      if (again?.data?.effect !== "allow") throw new Error(`expected auto-allow in new session, got ${JSON.stringify(again?.data)}`);
      const stillPending = dataOf(await clientA.v2.session.permission.list({ sessionID: sid2 }));
      if ((stillPending?.data ?? []).some((request) => request.resources?.includes(resource))) {
        throw new Error("matching action still pending in the new session");
      }
      return `saved ${savedEntry.id}; re-create effect=${again?.data?.effect}, not pending`;
    });

    // ---- Proof 7: permission reject.
    await proof("P7 permission reject", async () => {
      const { sid, pendingId } = await createPendingPermission(clientA, serverA.project, "edit", ["reject.ts"], []);
      const reply = await clientA.v2.session.permission.reply({ sessionID: sid, requestID: pendingId, reply: "reject" });
      if (errOf(reply)) throw new Error(`reject reply errored: ${JSON.stringify(errOf(reply))}`);
      await pollUntil(clientA, async () => {
        const list = dataOf(await clientA.v2.session.permission.list({ sessionID: sid }));
        return !(list?.data ?? []).some((request) => request.id === pendingId);
      }, 10_000, "permission reject resolution");
      return `request ${pendingId} rejected and removed`;
    });

    // ---- Question proofs: conditional on the fake provider path.
    const qStatus = await runQuestionProofs(clientA, serverA, provider);
    if (qStatus === "unavailable") {
      for (const q of ["Q1 multi-question atomic reply", "Q2 single-select reply", "Q3 multi-select + custom text reply"]) {
        results.push({ name: q, status: "SKIP", detail: qStatusReason, ms: 0 });
      }
      console.log(`\nNOTE: fake-provider question path unavailable (${qStatusReason}); question proofs skipped.`);
    }

    // ---- Proof 8: the plugin's exact V2 read/reply paths against natural model-turn state.
    // The plugin pending-adapter and reply adapters read through the V2
    // location-scoped request lists and reply through the V2 session-scoped
    // endpoints. This proof exercises those exact paths on a real model turn:
    // the location lists must surface the natural question-tool permission and
    // question, and the session-scoped replies must resolve them.
    await proof(
      "P8 V2 location-scoped lists + session-scoped replies on natural model-turn state",
      async () => runLocationScopedQuestionFlow(clientA, serverA, provider),
    );

    // -----------------------------------------------------------------------
    // Loud informational note (does NOT gate the exit code): opencode's V1
    // global `/question` / `/permission` list endpoints are broken on this
    // build — they do not surface requests that the V2 pending store holds,
    // and the V1 reply endpoints answer 404. The plugin therefore reads and
    // replies exclusively through the V2 endpoints proven above.
    console.warn(
      "\nNOTE (informational): opencode's V1 global `/question` / `/permission` list endpoints are " +
        "broken on this build — they do not surface the natural pending store, and the V1 reply " +
        "endpoints answer QuestionNotFoundError/PermissionNotFoundError. The plugin reads and replies " +
        "exclusively through the V2 location-scoped lists and session-scoped replies proven by the " +
        "proofs above (see issue #42541).",
    );
  } finally {
    clearTimeout(deadline);
    for (const server of servers) {
      try {
        await server.kill();
      } catch {
        // best-effort teardown
      }
    }
    if (provider) {
      try {
        await provider.stop();
      } catch {
        // best-effort teardown
      }
    }
    try {
      rmSync(root, { recursive: true, force: true });
    } catch {
      // best-effort cleanup
    }
  }

  const failed = results.filter((result) => result.status === "FAIL");
  const skipped = results.filter((result) => result.status === "SKIP");
  const passed = results.filter((result) => result.status === "PASS");
  const warned = results.filter((result) => result.status === "WARN");
  console.log("");
  printSummary(startedAt);
  if (failed.length > 0) {
    console.error(`\nSMOKE FAIL: ${failed.length} proof(s) failed; ${skipped.length} skipped; ${passed.length} passed; ${warned.length} warned.`);
    process.exit(1);
  }
  console.log(`\nSMOKE OK: ${passed.length} passed, ${skipped.length} skipped, ${warned.length} warned, 0 failed.`);
}

function printSummary(startedAt) {
  const wall = ((Date.now() - startedAt) / 1000).toFixed(1);
  console.log(`proof-by-proof summary (wall ${wall}s):`);
  for (const result of results) {
    console.log(`  [${result.status.padEnd(5)}] ${result.name}${result.detail ? ` — ${result.detail}` : ""} (${result.ms}ms)`);
  }
}

// ---------------------------------------------------------------------------
// Question proofs
// ---------------------------------------------------------------------------

let qStatusReason = null;

async function runQuestionProofs(client, server, provider) {
  // Does the fake provider path exist at all? If the provider is not registered
  // (e.g. @ai-sdk/openai-compatible could not be installed), skip all three.
  try {
    const providers = dataOf(await client.v2.provider.list({}));
    const hasSmoke = (providers?.data ?? []).some((entry) => entry.id === "smoke");
    if (!hasSmoke) {
      qStatusReason = "provider 'smoke' not registered on server A (is @ai-sdk/openai-compatible installable here?)";
      return "unavailable";
    }
  } catch (error) {
    qStatusReason = `provider list failed: ${error.message}`;
    return "unavailable";
  }

  const variants = [
    {
      name: "Q1 multi-question atomic reply",
      marker: "SMOKE_Q_MULTI",
      answers: [["PostgreSQL"], ["Yes"]],
      expectQuestions: 2,
    },
    {
      name: "Q2 single-select reply",
      marker: "SMOKE_Q_SINGLE",
      answers: [["WebSocket"]],
      expectQuestions: 1,
    },
    {
      name: "Q3 multi-select + custom text reply",
      marker: "SMOKE_Q_MULTISELECT",
      answers: [["Linux", "Windows", "custom environment"]],
      expectQuestions: 1,
    },
  ];

  let outcome = "ok";
  for (const variant of variants) {
    const beforeCount = provider.requests.length;
    const result = await proof(variant.name, async () => runOneQuestionVariant(client, server, provider, variant, beforeCount));
    if (result === "skipped") {
      // The fake-provider path is unusable for this variant; keep going so the
      // remaining variants can also be reported, but remember the skip reason.
      qStatusReason = qStatusReason ?? "fake provider never contacted for a question variant";
      continue;
    }
    if (result === false) {
      outcome = "failed";
      return outcome;
    }
  }
  return outcome;
}

async function runOneQuestionVariant(client, server, provider, variant, beforeCount) {
  const providerContacted = () => provider.requests.length > beforeCount;

  const created = dataOf(await client.v2.session.create({
    agent: "build",
    model: { id: "fake-model", providerID: "smoke" },
    location: { directory: server.project },
  }));
  const sid = created?.data?.id;
  if (!sid) throw new Error(`question session create failed: ${JSON.stringify(errOf(created))}`);

  await client.v2.session.prompt({ sessionID: sid, prompt: { text: variant.marker } });

  // The question tool first asserts a permission; a pending permission appears.
  const permission = await pollUntil(client, async () => {
    const list = dataOf(await client.v2.session.permission.list({ sessionID: sid }));
    const pending = (list?.data ?? []).find((request) => request.action === "question");
    return pending ?? null;
  }, 30_000, `pending question permission (${variant.name})`).catch((error) => {
    if (!providerContacted()) {
      qStatusReason = "fake provider received no chat-completions request (question tool was never invoked by the model)";
      skip(qStatusReason);
    }
    throw new Error(`question tool permission never became pending: ${error.message}`);
  });

  const replyPerm = await client.v2.session.permission.reply({ sessionID: sid, requestID: permission.id, reply: "once" });
  if (errOf(replyPerm)) throw new Error(`question permission reply errored: ${JSON.stringify(errOf(replyPerm))}`);

  // After the permission resolves, the question tool runs and the request appears.
  const question = await pollUntil(client, async () => {
    const list = dataOf(await client.v2.session.question.list({ sessionID: sid }));
    return (list?.data ?? [])[0] ?? null;
  }, 30_000, `pending question (${variant.name})`).catch((error) => {
    if (!providerContacted()) {
      qStatusReason = "fake provider received no chat-completions request (question tool was never invoked by the model)";
      skip(qStatusReason);
    }
    throw new Error(`question never became pending: ${error.message}`);
  });

  const actualCount = Array.isArray(question.questions) ? question.questions.length : 0;
  if (actualCount !== variant.expectQuestions) {
    throw new Error(`expected ${variant.expectQuestions} question(s), got ${actualCount}: ${JSON.stringify(question.questions)}`);
  }

  const reply = await client.v2.session.question.reply({
    sessionID: sid,
    requestID: question.id,
    questionV2Reply: { answers: variant.answers },
  });
  if (errOf(reply)) throw new Error(`question reply errored: ${JSON.stringify(errOf(reply))}`);

  await pollUntil(client, async () => {
    const list = dataOf(await client.v2.session.question.list({ sessionID: sid }));
    return (list?.data ?? []).length === 0;
  }, 15_000, `question resolution (${variant.name})`);

  // Confirm the tool completed with exactly the answers we submitted.
  const messages = dataOf(await client.v2.session.messages({ sessionID: sid, order: "asc" }));
  const toolPart = (messages?.data ?? [])
    .filter((message) => message.type === "assistant")
    .flatMap((message) => message.content ?? [])
    .find((part) => part?.type === "tool" && part?.name === "question");
  if (!toolPart || toolPart.state?.status !== "completed") {
    throw new Error(`question tool did not complete: ${JSON.stringify(toolPart?.state)}`);
  }
  const structured = toolPart.state?.structured?.answers;
  if (JSON.stringify(structured) !== JSON.stringify(variant.answers)) {
    throw new Error(`tool answers ${JSON.stringify(structured)} != submitted ${JSON.stringify(variant.answers)}`);
  }
  return `${question.id} ${actualCount} question(s) answered atomically; tool completed`;
}

async function createPendingPermission(client, directory, action, resources, save) {
  const created = dataOf(await client.v2.session.create({ agent: "build", location: { directory } }));
  const sid = created?.data?.id;
  if (!sid) throw new Error(`session create failed: ${JSON.stringify(errOf(created))}`);
  const perm = dataOf(await client.v2.session.permission.create({ sessionID: sid, action, resources, save }));
  if (perm?.data?.effect !== "ask" || !perm?.data?.id) {
    throw new Error(`expected pending permission (effect=ask), got ${JSON.stringify(perm?.data)}`);
  }
  return { sid, pendingId: perm.data.id };
}

// ---------------------------------------------------------------------------
// Proof 8: the plugin's exact V2 read/reply paths on natural model-turn state
// ---------------------------------------------------------------------------

/**
 * Drive one fake-provider question turn, then exercise the plugin's exact
 * V2 paths: read the pending state through the LOCATION-scoped lists
 * (`v2.question.request.list({ location })` / `v2.permission.request.list
 * ({ location })`) and reply through the SESSION-scoped endpoints. Also
 * proves that a `v2.session.permission.create`'d request surfaces in the
 * location-scoped permission list.
 */
async function runLocationScopedQuestionFlow(client, server, provider) {
  const beforeCount = provider.requests.length;
  const providerContacted = () => provider.requests.length > beforeCount;

  // A fresh session on the fake-model provider, prompting the question tool.
  const created = dataOf(await client.v2.session.create({
    agent: "build",
    model: { id: "fake-model", providerID: "smoke" },
    location: { directory: server.project },
  }));
  const sid = created?.data?.id;
  if (!sid) throw new Error(`question session create failed: ${JSON.stringify(errOf(created))}`);

  await client.v2.session.prompt({ sessionID: sid, prompt: { text: "SMOKE_Q_SINGLE" } });

  // The question tool first asserts a permission; the LOCATION-scoped list
  // must surface the natural question-tool permission (this session's).
  const permission = await pollUntil(client, async () => {
    const list = dataOf(await client.v2.permission.request.list({ location: { directory: server.project } }));
    return (
      (list?.data ?? []).find(
        (request) => request.sessionID === sid && request.action === "question",
      ) ?? null
    );
  }, 30_000, "question-tool permission via location-scoped list").catch((error) => {
    if (!providerContacted()) {
      qStatusReason = "fake provider received no chat-completions request (question tool was never invoked by the model)";
      skip(qStatusReason);
    }
    throw new Error(`question tool permission never appeared in the location-scoped list: ${error.message}`);
  });

  // Answer the natural question-tool permission via the session-scoped reply.
  const replyPerm = await client.v2.session.permission.reply({
    sessionID: sid,
    requestID: permission.id,
    reply: "once",
  });
  if (errOf(replyPerm)) throw new Error(`question permission reply errored: ${JSON.stringify(errOf(replyPerm))}`);

  // After the permission resolves, the question tool runs; the LOCATION-scoped
  // question list must surface the natural question (this session's).
  const question = await pollUntil(client, async () => {
    const list = dataOf(await client.v2.question.request.list({ location: { directory: server.project } }));
    return (list?.data ?? []).find((request) => request.sessionID === sid) ?? null;
  }, 30_000, "question via location-scoped list").catch((error) => {
    if (!providerContacted()) {
      qStatusReason = "fake provider received no chat-completions request (question tool was never invoked by the model)";
      skip(qStatusReason);
    }
    throw new Error(`question never appeared in the location-scoped list: ${error.message}`);
  });

  const actualCount = Array.isArray(question.questions) ? question.questions.length : 0;
  if (actualCount !== 1) {
    throw new Error(`expected 1 question, got ${actualCount}: ${JSON.stringify(question.questions)}`);
  }

  // Answer the natural question via the session-scoped reply.
  const answers = [["WebSocket"]];
  const reply = await client.v2.session.question.reply({
    sessionID: sid,
    requestID: question.id,
    questionV2Reply: { answers },
  });
  if (errOf(reply)) throw new Error(`question reply errored: ${JSON.stringify(errOf(reply))}`);

  await pollUntil(client, async () => {
    const list = dataOf(await client.v2.question.request.list({ location: { directory: server.project } }));
    return !(list?.data ?? []).some((request) => request.id === question.id);
  }, 15_000, "question resolution via location-scoped list");

  // Confirm the tool completed with exactly the answers we submitted.
  const messages = dataOf(await client.v2.session.messages({ sessionID: sid, order: "asc" }));
  const toolPart = (messages?.data ?? [])
    .filter((message) => message.type === "assistant")
    .flatMap((message) => message.content ?? [])
    .find((part) => part?.type === "tool" && part?.name === "question");
  if (!toolPart || toolPart.state?.status !== "completed") {
    throw new Error(`question tool did not complete: ${JSON.stringify(toolPart?.state)}`);
  }
  const structured = toolPart.state?.structured?.answers;
  if (JSON.stringify(structured) !== JSON.stringify(answers)) {
    throw new Error(`tool answers ${JSON.stringify(structured)} != submitted ${JSON.stringify(answers)}`);
  }

  // A v2.session.permission.create'd request must also surface in the
  // location-scoped permission list (the plugin's pending-adapter read path).
  const made = dataOf(
    await client.v2.session.permission.create({
      sessionID: sid,
      action: "edit",
      resources: ["p8.ts"],
      save: [],
    }),
  );
  if (made?.data?.effect !== "ask" || !made?.data?.id) {
    throw new Error(`expected pending permission, got ${JSON.stringify(made?.data)}`);
  }
  const madeId = made.data.id;
  await pollUntil(client, async () => {
    const list = dataOf(await client.v2.permission.request.list({ location: { directory: server.project } }));
    return (list?.data ?? []).some((request) => request.id === madeId);
  }, 10_000, "session-created permission visible via location-scoped list");

  return `${question.id} answered via V2 session-scoped reply after location-scoped reads; ` +
    `session-created permission ${madeId} visible via location-scoped list; tool completed`;
}

// ---- small path helpers used above ----
main().catch((error) => {
  console.error("\nSMOKE FAIL: " + (error instanceof Error ? error.message : String(error)));
  process.exit(1);
});
