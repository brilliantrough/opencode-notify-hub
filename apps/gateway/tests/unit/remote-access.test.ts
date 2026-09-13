import { EventEmitter } from "node:events";
import { expect, it, vi } from "vitest";
import { InstanceRegistry } from "../../src/modules/control/instance-registry.js";
import { createAccessTokens } from "../../src/plugins/jwt.js";
import Fastify from "fastify";
import { sessionControlRoutes } from "../../src/modules/control/session-control.routes.js";

it("accepts the client's HTTP query limit without weakening body validation", async () => {
  const app = Fastify({ ajv: { customOptions: { coerceTypes: false, removeAdditional: false } } });
  const collectSessions = vi.fn<InstanceRegistry["collectSessions"]>(async () => ({ status: "ready", catalog: { sessions: [], hasMore: false } }));
  app.decorate("authenticate", async (request) => { request.userId = "owner"; });
  await app.register(sessionControlRoutes({ collectSessions } as unknown as InstanceRegistry));
  try {
    const path = "/v1/instances/10000000-0000-4000-8000-000000000001/sessions";
    const response = await app.inject(`${path}?search=&limit=50&sessionIds=`);
    expect(response.statusCode, response.body).toBe(200);
    expect(collectSessions.mock.calls[0]?.[2]).toEqual({ search: "", limit: 50, sessionIds: "" });
    for (const limit of ["0", "201", "1.5", "nope"]) {
      expect((await app.inject(`${path}?limit=${limit}`)).statusCode).toBe(400);
    }
  } finally { await app.close(); }
});

class Socket extends EventEmitter {
  readyState = 1;
  bufferedAmount = 0;
  frames: Record<string, unknown>[] = [];
  send(raw: string) { this.frames.push(JSON.parse(raw)); }
  ping() { this.emit("pong"); }
  close() { this.readyState = 3; this.emit("close"); }
  terminate() { this.close(); }
  receive(frame: Record<string, unknown>) { this.emit("message", JSON.stringify(frame)); }
}

it("keeps an owned tunnel across token renewal and correlates session snapshots and cancellations", async () => {
  vi.useFakeTimers();
  const clock = { now: () => new Date(), nowMs: () => Date.now() };
  const tokens = createAccessTokens({ clock, signingKey: Buffer.alloc(32, 1).toString("base64") });
  const registry = new InstanceRegistry({ clock, publish: () => {} });
  const plugin = new Socket();
  const browser = new Socket();
  const instanceId = "10000000-0000-4000-8000-000000000001";
  try {
    registry.add({ id: "key", userId: "owner" } as Parameters<InstanceRegistry["add"]>[0], plugin);
    plugin.receive({ type: "register", instanceId, machine: "host", project: "notify",
      directory: "/work/notify", openCodeVersion: "1.18.15", protocolVersion: 2 });
    expect(await registry.collectSessions("other", instanceId, { limit: 50 })).toEqual({ status: "not_found" });
    const catalog = registry.collectSessions("owner", instanceId, { limit: 50 });
    const request = plugin.frames.at(-1)!;
    plugin.receive({ type: "session_catalog_response", requestId: request.requestId, instanceId,
      status: "ready", catalog: { sessions: [], hasMore: false } });
    expect(await catalog).toEqual({ status: "ready", catalog: { sessions: [], hasMore: false } });

    registry.addWebUiClient("owner", browser, { expiresAtMs: Date.now() + 2000, verifyToken: tokens.verify });
    browser.receive({ type: "webui_tunnel_open", instanceId });
    const tunnelId = browser.frames[0].tunnelId;
    const requestId = "20000000-0000-4000-8000-000000000002";
    browser.receive({ type: "webui_http_request", tunnelId, requestId, method: "GET", path: "/global/event", headers: {} });
    browser.receive({ type: "webui_auth_refresh", accessToken: tokens.sign("owner") });
    await vi.advanceTimersByTimeAsync(3000);
    expect(browser.readyState).toBe(1);
    plugin.receive({ type: "webui_http_response_chunk", tunnelId, requestId, body: "aGVsbG8=" });
    expect(browser.frames.at(-1)?.type).toBe("webui_http_response_chunk");
    browser.receive({ type: "webui_http_cancel", tunnelId, requestId });
    expect(plugin.frames.at(-1)).toEqual({ type: "webui_http_cancel", tunnelId, requestId });
    browser.receive({ type: "webui_auth_refresh", accessToken: tokens.sign("other") });
    expect(browser.readyState).toBe(3);
    expect(plugin.frames.at(-1)?.type).toBe("webui_tunnel_close");
  } finally {
    browser.close();
    registry.closeAll();
    vi.useRealTimers();
  }
});
