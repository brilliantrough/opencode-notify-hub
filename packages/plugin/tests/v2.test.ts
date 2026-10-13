import { createServer } from "node:http";
import { once } from "node:events";
import { afterEach, describe, expect, it, vi } from "vitest";
import { V2Api, type V2Form } from "../src/v2-api.js";
import { setupV2 } from "../src/v2.js";

afterEach(() => { vi.unstubAllEnvs(); vi.unstubAllGlobals(); vi.restoreAllMocks(); });

const form: V2Form = {
  id: "frm_1", sessionID: "ses_main", metadata: { kind: "question" },
  fields: [
    { key: "q0", title: "Choice", description: "Continue?", type: "string", custom: true, options: [{ label: "Yes", value: "Yes" }] },
    { key: "q1", title: "Many", description: "Which?", type: "multiselect", custom: true, options: [{ label: "A", value: "A" }] },
  ],
};
const session = (id: string, directory = "/work") => ({ id, title: "Main", location: { directory }, time: { updated: 1000 } });

describe("OpenCode 2 adapter", () => {
  it("uses authenticated V2 routes, preserves ordered form answers, and rejects foreign sessions", async () => {
    let settled = false;
    let activeAvailable = true;
    const writes: Array<{ path: string; body: unknown }> = [];
    const server = createServer(async (req, res) => {
      expect(req.headers.authorization).toBe(`Basic ${Buffer.from("opencode:test-password").toString("base64")}`);
      const url = new URL(req.url!, "http://localhost");
      res.setHeader("content-type", "application/json");
      if (req.method === "POST") {
        let body = "";
        for await (const chunk of req) body += chunk;
        writes.push({ path: url.pathname, body: JSON.parse(body) });
        if (url.pathname.includes("/form/")) settled = true;
        res.writeHead(204).end();
      } else if (url.pathname === "/api/info") res.end(JSON.stringify({ pid: process.pid, version: "2.0.28" }));
      else if (url.pathname === "/api/session") {
        expect(url.searchParams.get("directory")).toBe("/work");
        expect(url.searchParams.get("parentID")).toBe("null");
        res.end(JSON.stringify({ data: [session("ses_main")], cursor: { next: "anchor-not-proof-of-another-page" } }));
      } else if (url.pathname === "/api/session/active") {
        res.writeHead(activeAvailable ? 200 : 503).end(JSON.stringify({ data: { ses_main: { type: "running" } } }));
      } else if (url.pathname === "/api/form" || url.pathname === "/api/permission/request") {
        expect(url.searchParams.get("location[directory]")).toBe("/work");
        res.end(JSON.stringify({ location: { directory: "/work" }, data: url.pathname === "/api/form" ? [form] : [{
          id: "per_1", sessionID: "ses_main", action: "bash", resources: ["pwd"], save: ["pwd"],
          source: { type: "tool", messageID: "msg_1", id: "call_1" },
        }] }));
      } else if (url.pathname.endsWith("/form/frm_1")) res.end(JSON.stringify({ data: { ...form, state: { status: settled ? "answered" : "pending" } } }));
      else res.end(JSON.stringify({ data: session(url.pathname.split("/").at(-1)!, url.pathname.endsWith("ses_foreign") ? "/elsewhere" : "/work") }));
    });
    server.listen(0, "127.0.0.1");
    await once(server, "listening");
    const address = server.address() as { port: number };
    vi.stubEnv("NOTIFY_OPENCODE_URL", `http://127.0.0.1:${address.port}`);
    vi.stubEnv("NOTIFY_OPENCODE_PASSWORD", "test-password");
    const api = new V2Api("/work", () => "Main");
    const signal = AbortSignal.timeout(5000);
    try {
      const pending = await api.listPending({ instanceId: "i", machine: "m", project: "p", directory: "/work" }, signal);
      expect(pending.map(p => p.kind)).toEqual(["question", "permission"]);
      expect(pending[1]).toMatchObject({ tool: { messageId: "msg_1", callId: "call_1" }, patterns: ["pwd"], always: ["pwd"] });
      expect(await api.answer("frm_1", "ses_main", [["Yes"], ["A", "custom"]], signal)).toBe("confirmed");
      expect(writes[0]).toEqual({ path: "/api/session/ses_main/form/frm_1/reply", body: { answer: { q0: "Yes", q1: ["A", "custom"] } } });
      expect(await api.answer("frm_1", "ses_main", [["Yes"], []], signal)).toBe("stale");
      for (const decision of ["once", "always", "reject"] as const) expect(await api.decide("per_1", "ses_main", decision, signal)).toBe("confirmed");
      expect(writes.slice(1).map(w => w.body)).toEqual([{ decision: "once" }, { decision: "always" }, { decision: "reject" }]);
      expect(await api.prompt("ses_foreign", "do not send", signal)).toBe("upstream_error");
      expect(writes).toHaveLength(4);
      const catalog = await api.catalog({ limit: 50 }, signal);
      expect(catalog.sessions[0]?.status).toBe("busy");
      expect(catalog.hasMore).toBe(false);
      activeAvailable = false;
      expect((await api.catalog({ limit: 50 }, signal)).sessions[0]?.status).toBe("unknown");
    } finally { server.closeAllConnections(); await new Promise<void>(resolve => server.close(() => resolve())); }
  });

  it("refuses a different OpenCode process even when the endpoint authenticates", async () => {
    const server = createServer((_req, res) => res.end(JSON.stringify({ pid: process.pid + 1, version: "2.0.28" })));
    server.listen(0, "127.0.0.1");
    await once(server, "listening");
    vi.stubEnv("NOTIFY_OPENCODE_URL", `http://127.0.0.1:${(server.address() as { port: number }).port}`);
    try { await expect(new V2Api("/work", () => "").probe()).rejects.toThrow("identity mismatch"); }
    finally { server.closeAllConnections(); await new Promise<void>(resolve => server.close(() => resolve())); }
  });

  it("translates V2 events through the notification pipeline and disposes its subscription", async () => {
    vi.stubEnv("NOTIFY_GATEWAY_URL", "http://localhost:9");
    vi.stubEnv("NOTIFY_INGEST_KEY", "smoke.secret");
    vi.stubEnv("NOTIFY_INCLUDE_SUMMARY", "true");
    vi.stubEnv("NOTIFY_IDLE_DEBOUNCE_MS", "15000");
    vi.spyOn(console, "error").mockImplementation(() => {});
    const delivered: Array<{ type: string; payload: Record<string, unknown>; session: { id: string } }> = [];
    vi.stubGlobal("fetch", async (_url: unknown, init: RequestInit) => {
      delivered.push(JSON.parse(String(init.body)));
      return new Response("true", { status: 202 });
    });
    let drained!: () => void;
    const ready = new Promise<void>(resolve => { drained = resolve; });
    let aborted = false;
    const cleanup = await setupV2({
      app: { version: "2.0.28" }, location: { directory: "/work", project: { directory: "/work", canonical: "/work" } },
      session: { get: async ({ sessionID }) => session(sessionID, sessionID === "ses_foreign" ? "/elsewhere" : "/work") },
      event: { async *subscribe({ signal }) {
        yield { type: "session.execution.started", data: { sessionID: "ses_foreign" } };
        yield { type: "session.execution.succeeded", data: { sessionID: "ses_foreign" } };
        yield { type: "session.execution.started", data: { sessionID: "ses_main" } };
        yield { type: "form.created", data: { form } };
        yield { type: "form.replied", data: { sessionID: "ses_main", id: form.id } };
        yield { type: "session.text.ended", data: { sessionID: "ses_main", assistantMessageID: "msg_1", ordinal: 0, text: "finished" } };
        yield { type: "session.execution.succeeded", data: { sessionID: "ses_main" } };
        drained();
        await new Promise<void>(resolve => signal.addEventListener("abort", () => { aborted = true; resolve(); }, { once: true }));
      } },
    });
    await ready;
    await cleanup?.();
    expect(aborted).toBe(true);
    expect(delivered.every(event => event.session.id === "ses_main")).toBe(true);
    expect(delivered.map(event => event.type)).toEqual(["action_required", "action_resolved", "terminal"]);
    expect(delivered.at(-1)?.payload).toMatchObject({ outcome: "completed", summary: "finished" });
  });
});
