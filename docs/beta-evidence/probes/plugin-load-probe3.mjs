// Probe: does a project-local plugin actually EXECUTE under `opencode serve`
// 1.18.18? Marker plugin appends a line to a file at load (top-level) and on
// the first event hook. Tests: (a) file absent right after server start,
// (b) present after the first directory-scoped request (session create+prompt
// with a fake provider so a real turn runs).
import { createServer } from "node:http";
import { spawn } from "node:child_process";
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { createOpencodeClient } from "@opencode-ai/sdk/v2";

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const dataOf = (r) => (r && typeof r === "object" && "data" in r ? r.data : r);

const root = mkdtempSync(join(tmpdir(), "plugin-load-probe-"));
const project = join(root, "project");
const xdg = join(root, "xdg");
const marker = join(root, "loaded.txt");
mkdirSync(join(xdg, "opencode"), { recursive: true });
mkdirSync(join(project, ".opencode", "plugins"), { recursive: true });
writeFileSync(join(project, ".opencode", "plugins", "marker.js"), `
import { appendFileSync } from "node:fs";
appendFileSync(${JSON.stringify(marker)}, "imported\\n");
export default async function markerPlugin(input) {
  appendFileSync(${JSON.stringify(marker)}, "invoked serverUrl=" + (input?.serverUrl?.toString?.() ?? "none") + "\\n");
  return { event: async () => { appendFileSync(${JSON.stringify(marker)}, "event\\n"); } };
}
`);

const provider = createServer((req, res) => {
  let raw = "";
  req.on("data", (c) => (raw += c));
  req.on("end", () => {
    if (req.method === "GET" && (req.url ?? "").includes("/models")) {
      res.writeHead(200, { "Content-Type": "application/json" });
      res.end(JSON.stringify({ object: "list", data: [{ id: "fake-model", object: "model", owned_by: "probe" }] }));
      return;
    }
    if (req.method === "POST" && (req.url ?? "").includes("/chat/completions")) {
      const body = raw ? JSON.parse(raw) : {};
      if (body.stream === true) {
        res.writeHead(200, { "Content-Type": "text/event-stream", "Cache-Control": "no-cache", Connection: "keep-alive" });
        const id = "chatcmpl-probe";
        const created = Math.floor(Date.now() / 1000);
        res.write(`data: ${JSON.stringify({ id, object: "chat.completion.chunk", created, model: "fake-model", choices: [{ index: 0, delta: { role: "assistant", content: null, tool_calls: [{ index: 0, id: "call_probe", type: "function", function: { name: "question", arguments: JSON.stringify({questions:[{question:"Pick?",header:"Q",options:[{label:"A",description:"a"}]}]}) } }] }, finish_reason: null }] })}\n\n`);
        res.write(`data: ${JSON.stringify({ id, object: "chat.completion.chunk", created, model: "fake-model", choices: [{ index: 0, delta: {}, finish_reason: "tool_calls" }] })}\n\n`);
        res.write("data: [DONE]\n\n");
        return res.end();
      }
      res.writeHead(200, { "Content-Type": "application/json" });
      res.end(JSON.stringify({ id: "chatcmpl-probe", object: "chat.completion", created: 0, model: "fake-model", choices: [{ index: 0, message: { role: "assistant", content: null, tool_calls: [{ id: "call_probe", type: "function", function: { name: "question", arguments: JSON.stringify({questions:[{question:"Pick?",header:"Q",options:[{label:"A",description:"a"}]}]}) } }] }, finish_reason: "tool_calls" }] }));
      return;
    }
    res.writeHead(404);
    res.end();
  });
});

let proc;
try {
  await new Promise((r) => provider.listen(0, "127.0.0.1", r));
  const providerPort = provider.address().port;
  const port = 43000 + Math.floor(Math.random() * 5000);
  const baseUrl = `http://127.0.0.1:${port}`;
  writeFileSync(join(xdg, "opencode", "opencode.json"), JSON.stringify({
    $schema: "https://opencode.ai/config.json",
    provider: { smoke: { npm: "@ai-sdk/openai-compatible", name: "smoke", options: { baseURL: `http://127.0.0.1:${providerPort}/v1`, apiKey: "smoke-test" }, models: { "fake-model": { name: "fake-model" } } } },
  }, null, 2));
  const env = { ...process.env, HOME: join(root, "home"), XDG_CONFIG_HOME: xdg, XDG_DATA_HOME: join(root, "data"), XDG_CACHE_HOME: join(root, "cache"), OPENCODE_DISABLE_AUTOUPDATE: "1" };
  for (const k of Object.keys(env)) if (k.startsWith("NOTIFY_")) delete env[k];
  proc = spawn(process.env.OPENCODE_BIN ?? "opencode", ["serve", "--hostname", "127.0.0.1", "--port", String(port)], { env, cwd: project, stdio: ["ignore", "pipe", "pipe"] });
  let log = "";
  proc.stdout.on("data", (c) => (log += c));
  proc.stderr.on("data", (c) => (log += c));

  const start = Date.now();
  while (Date.now() - start < 45000) {
    try {
      const res = await fetch(`${baseUrl}/api/health`, { signal: AbortSignal.timeout(3000) });
      if (res.ok) break;
    } catch {}
    await sleep(500);
  }
  await sleep(3000);
  console.log("after server start, marker exists:", existsSync(marker));

  const client = createOpencodeClient({ baseUrl, directory: project });
  let providerReady = false;
  for (let i = 0; i < 120 && !providerReady; i++) {
    try {
      const providers = dataOf(await client.v2.provider.list({}));
      providerReady = (providers?.data ?? []).some((p) => p.id === "smoke");
    } catch {}
    if (!providerReady) await sleep(500);
  }
  console.log("provider smoke registered:", providerReady);
  // Attach an SSE event-stream subscriber BEFORE any turn: plugin functions
  // may be invoked only when an interactive client channel exists.
  const events = await fetch(`${baseUrl}/api/event?directory=${encodeURIComponent(project)}`, {
    headers: { accept: "text/event-stream" },
  });
  console.log("sse status:", events.status);
  const reader = events.body?.getReader();
  const ssePump = (async () => {
    try {
      while (reader) {
        const { done } = await reader.read();
        if (done) break;
      }
    } catch {}
  })();
  await sleep(2000);
  console.log("after sse attach, marker exists:", existsSync(marker));
  if (existsSync(marker)) console.log("marker content:", JSON.stringify(readFileSync(marker, "utf8")));

  const created = dataOf(await client.v2.session.create({ agent: "build", model: { id: "fake-model", providerID: "smoke" }, location: { directory: project } }));
  const sid = created?.data?.id;
  await client.v2.session.prompt({ sessionID: sid, prompt: { text: "ask the fixture question" } });

  // The question tool first asserts a permission; wait for the pending state.
  let pending;
  for (let i = 0; i < 60 && !pending; i++) {
    const perms = dataOf(await client.v2.session.permission.list({ sessionID: sid }));
    const list = Array.isArray(perms?.data) ? perms.data : [];
    const questions = dataOf(await client.v2.session.question.list({ sessionID: sid }));
    const qlist = Array.isArray(questions?.data) ? questions.data : [];
    if (list.length > 0 || qlist.length > 0) pending = { permissions: list.length, questions: qlist.length };
    if (!pending) await sleep(500);
  }
  console.log("pending state:", JSON.stringify(pending));
  console.log("after tool execution, marker exists:", existsSync(marker));
  if (existsSync(marker)) console.log("marker content:", JSON.stringify(readFileSync(marker, "utf8")));
  const msgs = dataOf(await client.v2.session.messages({ sessionID: sid }));
  console.log("session messages:", JSON.stringify(msgs).slice(0, 2000));
  console.log("server log tail:", log.slice(-1500));
  reader?.cancel().catch(() => {});
  await ssePump;
} finally {
  if (proc) {
    proc.kill("SIGTERM");
    for (let i = 0; i < 20 && proc.exitCode === null; i++) await sleep(250);
    if (proc.exitCode === null) proc.kill("SIGKILL");
  }
  provider.close();
  rmSync(root, { recursive: true, force: true });
}
