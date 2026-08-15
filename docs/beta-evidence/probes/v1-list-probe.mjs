// Probe: does the V1 global pending list (what packages/plugin/src/pending-adapter.ts
// polls) see NATURALLY-created pending state (question tool + its permission
// assertion during a model turn) on real opencode 1.18.18? Runs fully offline
// via a fake OpenAI-compatible provider. Cleans up after itself.
import { createServer } from "node:http";
import { spawn } from "node:child_process";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { createOpencodeClient } from "@opencode-ai/sdk/v2";

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const dataOf = (r) => (r && typeof r === "object" && "data" in r ? r.data : r);
const unwrap = (d) => (Array.isArray(d) ? d : (d?.data ?? []));

const root = mkdtempSync(join(tmpdir(), "v1-probe-"));
const project = join(root, "project");
const xdg = join(root, "xdg");
mkdirSync(join(xdg, "opencode"), { recursive: true });
mkdirSync(project, { recursive: true });

const FIXTURE = {
  questions: [
    {
      question: "Pick one?",
      header: "Choice",
      options: [{ label: "A", description: "first" }],
      multiple: false,
      custom: true,
    },
  ],
};

function writeJson(res, body) {
  res.writeHead(200, { "Content-Type": "application/json" });
  res.end(JSON.stringify(body));
}
function chunk(res, id, created, delta, finish) {
  res.write(`data: ${JSON.stringify({ id, object: "chat.completion.chunk", created, model: "fake-model", choices: [{ index: 0, delta, ...(finish ? { finish_reason: finish } : {}) }] })}\n\n`);
}
const provider = createServer((req, res) => {
  let raw = "";
  req.on("data", (c) => (raw += c));
  req.on("end", () => {
    const body = raw ? JSON.parse(raw) : {};
    if (req.method === "GET" && (req.url ?? "").includes("/models")) {
      return writeJson(res, { object: "list", data: [{ id: "fake-model", object: "model", owned_by: "probe" }] });
    }
    if (req.method === "POST" && (req.url ?? "").includes("/chat/completions")) {
      const hasTool = Array.isArray(body.messages) && body.messages.some((m) => m?.role === "tool");
      if (body.stream === true) {
        res.writeHead(200, { "Content-Type": "text/event-stream", "Cache-Control": "no-cache", Connection: "keep-alive" });
        const id = `chatcmpl-probe-${Date.now()}`;
        const created = Math.floor(Date.now() / 1000);
        if (hasTool) {
          chunk(res, id, created, { role: "assistant", content: "done" });
          chunk(res, id, created, {}, "stop");
        } else {
          chunk(res, id, created, { role: "assistant", tool_calls: [{ index: 0, id: "call_probe", type: "function", function: { name: "question", arguments: JSON.stringify(FIXTURE) } }] });
          chunk(res, id, created, {}, "tool_calls");
        }
        res.write("data: [DONE]\n\n");
        return res.end();
      }
      if (hasTool) {
        return writeJson(res, { id: "chatcmpl-probe", object: "chat.completion", created: 0, model: "fake-model", choices: [{ index: 0, message: { role: "assistant", content: "done" }, finish_reason: "stop" }] });
      }
      return writeJson(res, { id: "chatcmpl-probe", object: "chat.completion", created: 0, model: "fake-model", choices: [{ index: 0, message: { role: "assistant", content: null, tool_calls: [{ id: "call_probe", type: "function", function: { name: "question", arguments: JSON.stringify(FIXTURE) } }] }, finish_reason: "tool_calls" }] });
    }
    res.writeHead(404);
    res.end();
  });
});

let proc;
try {
  await new Promise((r) => provider.listen(0, "127.0.0.1", r));
  const providerPort = provider.address().port;
  const port = 41000 + Math.floor(Math.random() * 9000);
  const baseUrl = `http://127.0.0.1:${port}`;
  writeFileSync(join(xdg, "opencode", "opencode.json"), JSON.stringify({
    $schema: "https://opencode.ai/config.json",
    permission: "ask",
    provider: { smoke: { npm: "@ai-sdk/openai-compatible", name: "smoke", options: { baseURL: `http://127.0.0.1:${providerPort}/v1` }, models: { "fake-model": { name: "fake-model" } } } },
    model: "smoke/fake-model",
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
  const client = createOpencodeClient({ baseUrl, directory: project });
  let agentsReady = false;
  for (let i = 0; i < 120 && !agentsReady; i++) {
    try {
      const agents = dataOf(await client.v2.agent.list({}));
      agentsReady = Array.isArray(agents?.data) && agents.data.length > 0;
    } catch {}
    if (!agentsReady) await sleep(500);
  }
  if (!agentsReady) throw new Error("no agents; server log:\n" + log);

  const created = dataOf(await client.v2.session.create({ agent: "build", model: { id: "fake-model", providerID: "smoke" }, location: { directory: project } }));
  const sid = created?.data?.id;
  await client.v2.session.prompt({ sessionID: sid, prompt: { text: "ask the fixture question" } });

  // 1. The question tool's own permission assertion appears (natural V1-era flow).
  let perm;
  for (let i = 0; i < 60 && !perm; i++) {
    const list = unwrap(dataOf(await client.v2.session.permission.list({ sessionID: sid })));
    perm = list.find((r) => r.action === "question");
    if (!perm) await sleep(500);
  }
  if (!perm) throw new Error("question permission never pending; log:\n" + log);

  const v1PermAtNatural = unwrap(dataOf(await client.permission.list({ directory: project })));
  console.log("NATURAL permission pending:", perm.id);
  console.log("V1 /permission sees it:", v1PermAtNatural.some((r) => r.id === perm.id), "count=", v1PermAtNatural.length);

  // 2. Resolve via the V1 global reply path — exactly what the plugin adapter uses.
  const v1PermReply = await client.permission.reply({ requestID: perm.id, directory: project, reply: "once" });
  console.log("V1 permission.reply ok:", dataOf(v1PermReply) === true, "err:", JSON.stringify(v1PermReply?.error ?? null));

  // 3. The question tool runs; the question becomes pending.
  let question;
  for (let i = 0; i < 60 && !question; i++) {
    const list = unwrap(dataOf(await client.v2.session.question.list({ sessionID: sid })));
    question = list[0];
    if (!question) await sleep(500);
  }
  if (!question) throw new Error("question never pending; log:\n" + log);

  const v1QuestionList = unwrap(dataOf(await client.question.list({ directory: project })));
  console.log("V2 question pending:", question.id);
  console.log("V1 /question sees it:", v1QuestionList.some((r) => r.id === question.id), "count=", v1QuestionList.length);

  // 4. Reply through the V1 global path (the plugin's answer path).
  const v1Reply = await client.question.reply({ requestID: question.id, directory: project, answers: [["A"]] });
  console.log("V1 question.reply ok:", dataOf(v1Reply) === true, "err:", JSON.stringify(v1Reply?.error ?? null));

  const afterV1 = unwrap(dataOf(await client.question.list({ directory: project })));
  const afterV2 = unwrap(dataOf(await client.v2.session.question.list({ sessionID: sid })));
  console.log("after reply: V1 count=", afterV1.length, "V2 count=", afterV2.length);
} finally {
  if (proc) {
    proc.kill("SIGTERM");
    for (let i = 0; i < 20 && proc.exitCode === null; i++) await sleep(250);
    if (proc.exitCode === null) proc.kill("SIGKILL");
  }
  provider.close();
  rmSync(root, { recursive: true, force: true });
}
