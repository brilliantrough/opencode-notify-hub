import { createHmac, randomUUID } from "node:crypto";
import { Writable } from "node:stream";

import {
  validateErrorResponse,
  validatePermissionCommandResult,
} from "@notify/contracts";
import { sql } from "drizzle-orm";
import type { FastifyInstance } from "fastify";
import { afterAll, afterEach, beforeAll, beforeEach, describe, expect, it } from "vitest";
import { WebSocket } from "ws";

import { buildServer } from "../../src/app.js";
import { createDb, type GatewayDatabase } from "../../src/db/client.js";
import type { Clock } from "../../src/lib/clock.js";
import type { Mailer } from "../../src/modules/mail/mailer.js";
import { buildTestConfig, noopFcmSender } from "../helpers/build-test-app.js";
import { TestPostgres } from "../helpers/postgres.js";

const PASSWORD = "correct horse battery staple";

/** Fixed "now" for the fake clock: deterministic snapshot timestamps. */
const T0 = 1_800_000_000_000;

/** Fast heartbeat so control sockets stay alive in milliseconds. */
const TEST_PING_INTERVAL_MS = 60;

/** Short decision-command wait so result-unknown is exercised without real waits. */
const SHORT_DECISION_TIMEOUT_MS = 200;

class FakeClock implements Clock {
  constructor(private value: number) {}

  now(): Date {
    return new Date(this.value);
  }

  nowMs(): number {
    return this.value;
  }
}

class FakeMailer implements Mailer {
  verificationEmails: { to: string; code: string }[] = [];

  async sendVerificationEmail(to: string, code: string): Promise<void> {
    this.verificationEmails.push({ to, code });
  }

  async sendPasswordResetEmail(): Promise<void> {
    throw new Error("not used in this suite");
  }
}

/** A schema-valid pending permission interaction for the requested instance. */
function permissionInteraction(
  instanceId: string,
  requestId = "per_1",
  overrides: Record<string, unknown> = {},
): Record<string, unknown> {
  return {
    kind: "permission",
    instanceId,
    machine: "spoofed-machine",
    project: "spoofed-project",
    directory: "/spoofed",
    sessionId: "ses_2",
    sessionTitle: "Implement API",
    requestId,
    occurredAt: "2026-08-14T09:00:01.000Z",
    permission: "bash",
    patterns: ["rm -rf build/"],
    always: ["printf *"],
    metadata: { source: "interactive" },
    ...overrides,
  };
}

/** A schema-valid pending question interaction for the requested instance. */
function questionInteraction(
  instanceId: string,
  requestId = "req_1",
  overrides: Record<string, unknown> = {},
): Record<string, unknown> {
  return {
    kind: "question",
    instanceId,
    machine: "spoofed-machine",
    project: "spoofed-project",
    directory: "/spoofed",
    sessionId: "ses_1",
    sessionTitle: "Implement API",
    requestId,
    occurredAt: "2026-08-14T09:00:00.000Z",
    tool: { messageId: "msg_1", callId: "call_1" },
    questions: [
      {
        header: "Database",
        question: "Which database?",
        options: [{ label: "Postgres", description: "Production parity" }],
        multiple: false,
        custom: true,
      },
    ],
    ...overrides,
  };
}

describe("permission decisions", () => {
  let pg: TestPostgres;
  let handle: GatewayDatabase;
  let app: FastifyInstance;
  let mailer: FakeMailer;
  let clock: FakeClock;
  let port: number;
  const clients: WebSocket[] = [];

  beforeAll(async () => {
    pg = await TestPostgres.start();
    await pg.migrate();
    handle = createDb(pg.databaseUrl);
  });

  afterAll(async () => {
    await handle.close();
    await pg.stop();
  });

  beforeEach(async () => {
    await handle.db.execute(
      sql`truncate refresh_tokens, refresh_token_families, password_reset_tokens, email_verification_tokens, devices, ingest_keys, users cascade`,
    );
    mailer = new FakeMailer();
    clock = new FakeClock(T0);
    await startApp();
  });

  afterEach(async () => {
    for (const client of clients.splice(0)) {
      if (client.readyState === WebSocket.OPEN || client.readyState === WebSocket.CONNECTING) {
        client.terminate();
      }
    }
    await app.close();
  });

  async function startApp(
    overrides: { snapshotTimeoutMs?: number; answerTimeoutMs?: number } = {},
  ): Promise<void> {
    if (app !== undefined) {
      await app.close();
    }
    app = await buildServer({
      config: buildTestConfig({ databaseUrl: pg.databaseUrl }),
      db: handle.db,
      mailer,
      clock,
      realtime: { pingIntervalMs: TEST_PING_INTERVAL_MS },
      control:
        overrides.snapshotTimeoutMs !== undefined || overrides.answerTimeoutMs !== undefined
          ? overrides
          : undefined,
      fcmSender: noopFcmSender,
    });
    await app.listen({ host: "127.0.0.1", port: 0 });
    const address = app.server.address();
    if (address === null || typeof address === "string") {
      throw new Error("expected an ephemeral TCP port");
    }
    port = address.port;
  }

  /** Register, verify, log in; returns the access token and the user id. */
  async function createUser(email: string): Promise<{ token: string; userId: string }> {
    const register = await app.inject({
      method: "POST",
      url: "/v1/auth/register",
      payload: { email, password: PASSWORD },
    });
    expect(register.statusCode).toBe(201);
    const { code } = mailer.verificationEmails[mailer.verificationEmails.length - 1];
    const verify = await app.inject({
      method: "POST",
      url: "/v1/auth/verify-email",
      payload: { email, code },
    });
    expect(verify.statusCode).toBe(204);
    const login = await app.inject({
      method: "POST",
      url: "/v1/auth/login",
      payload: { email, password: PASSWORD },
    });
    expect(login.statusCode).toBe(200);
    const rows = (await handle.db.execute<{ id: string }>(
      sql`select id from users where email = ${email}`,
    )) as { id: string }[];
    return { token: login.json().accessToken as string, userId: rows[0].id };
  }

  /** Create an ingest key (the Plugin control credential) for the user. */
  async function createPluginCredential(token: string): Promise<string> {
    const created = await app.inject({
      method: "POST",
      url: "/v1/ingest-keys",
      headers: { authorization: `Bearer ${token}` },
      payload: { name: "control" },
    });
    expect(created.statusCode).toBe(201);
    return created.json().secret as string;
  }

  function connectPlugin(credential: string): Promise<WebSocket> {
    return new Promise((resolve, reject) => {
      const ws = new WebSocket(`ws://127.0.0.1:${port}/v1/plugin/ws`, {
        headers: { authorization: `Bearer ${credential}` },
      });
      clients.push(ws);
      ws.once("open", () => resolve(ws));
      ws.once("unexpected-response", (_request, response) => {
        reject(Object.assign(new Error("unexpected response"), { response }));
      });
      ws.once("error", reject);
    });
  }

  function nextMessage(ws: WebSocket, timeoutMs = 3_000): Promise<Record<string, unknown>> {
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => reject(new Error("timed out waiting for a message")), timeoutMs);
      ws.once("message", (data: Buffer) => {
        clearTimeout(timer);
        resolve(JSON.parse(data.toString("utf8")) as Record<string, unknown>);
      });
    });
  }

  /** Asserts that no message arrives within the window. */
  async function expectSilence(ws: WebSocket, windowMs = 250): Promise<void> {
    await new Promise<void>((resolve, reject) => {
      const timer = setTimeout(resolve, windowMs);
      ws.once("message", (data: Buffer) => {
        clearTimeout(timer);
        reject(new Error(`expected silence, received: ${data.toString("utf8")}`));
      });
    });
  }

  /**
   * Register a Plugin instance and await the registration result. Returns the
   * socket and the registration state for later assertions.
   */
  async function registerPlugin(
    credential: string,
    overrides: Record<string, unknown> = {},
  ): Promise<{ ws: WebSocket; instanceId: string; result: Record<string, unknown> }> {
    const instanceId = randomUUID();
    const ws = await connectPlugin(credential);
    const resultPromise = nextMessage(ws);
    ws.send(
      JSON.stringify({
        type: "register",
        instanceId,
        machine: "devbox",
        project: "notify",
        directory: "/work/notify",
        openCodeVersion: "1.18.18",
        protocolVersion: 1,
        ...overrides,
      }),
    );
    const result = (await resultPromise) as { type: string; instanceId: string; state: string };
    expect(result.type).toBe("registration");
    expect(result.instanceId).toBe(instanceId);
    return { ws, instanceId, result };
  }

  /**
   * Seed the registry's requestId projection by collecting one snapshot from
   * the owning Plugin. The GET is answered with `interactions`, so the
   * instance's projection reflects exactly that pending set.
   */
  async function seedSnapshot(
    token: string,
    ws: WebSocket,
    instanceId: string,
    interactions: Record<string, unknown>[],
  ): Promise<void> {
    const request = nextMessage(ws);
    const response = getPendingInteractions(token);
    const requestMsg = (await request) as { requestId: string };
    ws.send(
      JSON.stringify({
        type: "pending_snapshot_response",
        requestId: requestMsg.requestId,
        instanceId,
        interactions,
      }),
    );
    const res = await response;
    expect(res.statusCode).toBe(200);
  }

  function getPendingInteractions(
    token: string | null,
    overrides: Record<string, string> = {},
  ) {
    return app.inject({
      method: "GET",
      url: "/v1/pending-interactions",
      headers: {
        ...(token === null ? {} : { authorization: `Bearer ${token}` }),
        ...overrides,
      },
    });
  }

  function decidePermission(
    token: string | null,
    instanceId: string,
    requestId: string,
    body: Record<string, unknown>,
    overrides: Record<string, string> = {},
  ) {
    return app.inject({
      method: "POST",
      url: `/v1/pending-interactions/${instanceId}/permissions/${requestId}/decision`,
      headers: {
        ...(token === null ? {} : { authorization: `Bearer ${token}` }),
        "content-type": "application/json",
        ...overrides,
      },
      payload: body,
    });
  }

  describe("authentication and validation", () => {
    it("rejects unauthenticated and malformed tokens with 401 UNAUTHORIZED", async () => {
      const alice = await createUser("unauth-decision@example.com");
      const credential = await createPluginCredential(alice.token);
      const instance = await registerPlugin(credential);
      await seedSnapshot(alice.token, instance.ws, instance.instanceId, [
        permissionInteraction(instance.instanceId),
      ]);

      const cases: [string, string | null | undefined][] = [
        ["missing token", null],
        ["wrong scheme", undefined],
        ["garbage token", "not-a-jwt"],
      ];
      for (const [name, token] of cases) {
        const res = await decidePermission(
          token === undefined ? "" : token,
          instance.instanceId,
          "per_1",
          { commandId: randomUUID(), decision: "once" },
          token === undefined ? { authorization: "Token abc" } : {},
        );
        expect(res.statusCode, name).toBe(401);
        expect(validateErrorResponse(res.json())).toBe(true);
        expect((res.json() as { error: { code: string } }).error.code).toBe("UNAUTHORIZED");
      }
    });

    it("rejects malformed decision bodies with 400 VALIDATION_FAILED", async () => {
      const alice = await createUser("malformed-decision@example.com");
      const credential = await createPluginCredential(alice.token);
      const instance = await registerPlugin(credential);
      await seedSnapshot(alice.token, instance.ws, instance.instanceId, [
        permissionInteraction(instance.instanceId),
      ]);

      const commandId = randomUUID();
      const malformed: [string, Record<string, unknown>][] = [
        ["missing commandId", { decision: "once" }],
        ["missing decision", { commandId }],
        ["non-uuid commandId", { commandId: "cmd_1", decision: "once" }],
        ["unknown decision", { commandId, decision: "allow" }],
        ["non-string decision", { commandId, decision: 1 }],
        ["unknown property", { commandId, decision: "once", patterns: [] }],
      ];
      for (const [name, body] of malformed) {
        const res = await decidePermission(alice.token, instance.instanceId, "per_1", body);
        expect(res.statusCode, name).toBe(400);
        expect(validateErrorResponse(res.json())).toBe(true);
        expect((res.json() as { error: { code: string } }).error.code).toBe("VALIDATION_FAILED");
      }
    });
  });

  describe("happy path", () => {
    it("routes a once decision to the owning Plugin and returns the confirmed result", async () => {
      const alice = await createUser("decide-once@example.com");
      const credential = await createPluginCredential(alice.token);
      const instance = await registerPlugin(credential);
      expect(instance.result.state).toBe("controllable");

      await seedSnapshot(alice.token, instance.ws, instance.instanceId, [
        permissionInteraction(instance.instanceId),
      ]);

      const commandId = randomUUID();
      const command = nextMessage(instance.ws);
      const response = decidePermission(alice.token, instance.instanceId, "per_1", {
        commandId,
        decision: "once",
      });
      const frame = (await command) as Record<string, unknown>;
      expect(frame).toEqual({
        type: "permission_decide_command",
        commandId,
        requestId: "per_1",
        decision: "once",
      });
      instance.ws.send(
        JSON.stringify({
          type: "permission_decide_result",
          commandId,
          instanceId: instance.instanceId,
          status: "confirmed",
        }),
      );

      const res = await response;
      expect(res.statusCode).toBe(200);
      const body = res.json();
      expect(validatePermissionCommandResult(body)).toBe(true);
      expect(body).toEqual({ commandId, status: "confirmed" });
    });

    it("routes a reject decision to the owning Plugin and returns the confirmed result", async () => {
      const alice = await createUser("decide-reject@example.com");
      const credential = await createPluginCredential(alice.token);
      const instance = await registerPlugin(credential);
      expect(instance.result.state).toBe("controllable");

      await seedSnapshot(alice.token, instance.ws, instance.instanceId, [
        permissionInteraction(instance.instanceId),
      ]);

      const commandId = randomUUID();
      const command = nextMessage(instance.ws);
      const response = decidePermission(alice.token, instance.instanceId, "per_1", {
        commandId,
        decision: "reject",
      });
      const frame = (await command) as Record<string, unknown>;
      expect(frame).toEqual({
        type: "permission_decide_command",
        commandId,
        requestId: "per_1",
        decision: "reject",
      });
      instance.ws.send(
        JSON.stringify({
          type: "permission_decide_result",
          commandId,
          instanceId: instance.instanceId,
          status: "confirmed",
        }),
      );

      const res = await response;
      expect(res.statusCode).toBe(200);
      const body = res.json();
      expect(validatePermissionCommandResult(body)).toBe(true);
      expect(body).toEqual({ commandId, status: "confirmed" });
    });

    it("routes an always decision to the owning Plugin, returns the confirmed result, and clears the projection", async () => {
      const alice = await createUser("decide-always@example.com");
      const credential = await createPluginCredential(alice.token);
      const instance = await registerPlugin(credential);
      expect(instance.result.state).toBe("controllable");

      await seedSnapshot(alice.token, instance.ws, instance.instanceId, [
        permissionInteraction(instance.instanceId),
      ]);

      const commandId = randomUUID();
      const command = nextMessage(instance.ws);
      const response = decidePermission(alice.token, instance.instanceId, "per_1", {
        commandId,
        decision: "always",
      });
      const frame = (await command) as Record<string, unknown>;
      expect(frame).toEqual({
        type: "permission_decide_command",
        commandId,
        requestId: "per_1",
        decision: "always",
      });
      instance.ws.send(
        JSON.stringify({
          type: "permission_decide_result",
          commandId,
          instanceId: instance.instanceId,
          status: "confirmed",
        }),
      );

      const res = await response;
      expect(res.statusCode).toBe(200);
      const body = res.json();
      expect(validatePermissionCommandResult(body)).toBe(true);
      expect(body).toEqual({ commandId, status: "confirmed" });

      // A confirmed always decision resolves the request exactly like once or
      // reject: the projection drops it, so a repeat decision is a 409 and no
      // second command reaches the Plugin.
      const silence = expectSilence(instance.ws);
      const again = await decidePermission(alice.token, instance.instanceId, "per_1", {
        commandId: randomUUID(),
        decision: "reject",
      });
      await silence;
      expect(again.statusCode).toBe(409);
      expect((again.json() as { error: { code: string } }).error.code).toBe("CONFLICT");
    });
  });

  describe("exclusion", () => {
    it("answers 404 with silence for foreign, unknown, offline, conflicting, and incompatible targets", async () => {
      const alice = await createUser("exclude-decision@example.com");
      const bob = await createUser("bob-decision@example.com");
      const aliceCredential = await createPluginCredential(alice.token);
      const bobCredential = await createPluginCredential(bob.token);

      // Controllable owner of devbox:/work/notify.
      const owner = await registerPlugin(aliceCredential);
      expect(owner.result.state).toBe("controllable");
      await seedSnapshot(alice.token, owner.ws, owner.instanceId, [
        permissionInteraction(owner.instanceId),
      ]);

      // Same machine + directory under a different instance: conflicting.
      const conflict = await registerPlugin(aliceCredential, {
        project: "notify-copy",
        directory: "/work/notify/",
      });
      expect(conflict.result.state).toBe("conflicting");

      // Unsupported OpenCode version: incompatible.
      const incompatible = await registerPlugin(aliceCredential, {
        openCodeVersion: "1.18.17",
      });
      expect(incompatible.result.state).toBe("incompatible");

      // Registered then disconnected: offline.
      const offline = await registerPlugin(aliceCredential, {
        project: "gone",
        directory: "/work/gone",
      });
      expect(offline.result.state).toBe("controllable");
      offline.ws.close();
      await new Promise((resolve) => setTimeout(resolve, 30));

      // A live instance owned by another account: foreign.
      const foreign = await registerPlugin(bobCredential, {
        project: "bobproj",
        directory: "/work/bob",
      });
      expect(foreign.result.state).toBe("controllable");

      const cases: { name: string; token: string; instanceId: string }[] = [
        { name: "foreign", token: alice.token, instanceId: foreign.instanceId },
        { name: "unknown", token: alice.token, instanceId: randomUUID() },
        { name: "offline", token: alice.token, instanceId: offline.instanceId },
        { name: "conflicting", token: alice.token, instanceId: conflict.instanceId },
        { name: "incompatible", token: alice.token, instanceId: incompatible.instanceId },
      ];

      // None of the still-connected non-actionable or foreign sockets may be
      // handed a command.
      const silence: Promise<void>[] = [
        expectSilence(conflict.ws),
        expectSilence(incompatible.ws),
        expectSilence(foreign.ws),
      ];
      for (const c of cases) {
        const res = await decidePermission(c.token, c.instanceId, "per_1", {
          commandId: randomUUID(),
          decision: "once",
        });
        expect(res.statusCode, c.name).toBe(404);
        expect(validateErrorResponse(res.json())).toBe(true);
        expect((res.json() as { error: { code: string } }).error.code).toBe("NOT_FOUND");
      }
      await Promise.all(silence);
    });
  });

  describe("projection gating", () => {
    it("answers 404 for a never-projected request and 409 with silence for stale and wrong-kind requests", async () => {
      const alice = await createUser("projection-decision@example.com");
      const credential = await createPluginCredential(alice.token);
      const instance = await registerPlugin(credential);
      expect(instance.result.state).toBe("controllable");

      // A request id the Plugin never reported pending is unknown.
      let silence = expectSilence(instance.ws);
      let res = await decidePermission(alice.token, instance.instanceId, "never_seen", {
        commandId: randomUUID(),
        decision: "once",
      });
      await silence;
      expect(res.statusCode).toBe(404);
      expect((res.json() as { error: { code: string } }).error.code).toBe("NOT_FOUND");

      await seedSnapshot(alice.token, instance.ws, instance.instanceId, [
        permissionInteraction(instance.instanceId, "req_permission"),
        questionInteraction(instance.instanceId, "req_question"),
      ]);

      // A projected question request is the wrong kind: conflict, no command.
      silence = expectSilence(instance.ws);
      res = await decidePermission(alice.token, instance.instanceId, "req_question", {
        commandId: randomUUID(),
        decision: "once",
      });
      await silence;
      expect(res.statusCode).toBe(409);
      expect((res.json() as { error: { code: string } }).error.code).toBe("CONFLICT");

      // A newer empty snapshot means the permission request is no longer
      // pending: deciding it is a stale conflict, no command.
      await seedSnapshot(alice.token, instance.ws, instance.instanceId, []);
      silence = expectSilence(instance.ws);
      res = await decidePermission(alice.token, instance.instanceId, "req_permission", {
        commandId: randomUUID(),
        decision: "once",
      });
      await silence;
      expect(res.statusCode).toBe(409);
      expect((res.json() as { error: { code: string } }).error.code).toBe("CONFLICT");
    });
  });

  describe("outcomes", () => {
    it.each(["confirmed", "stale", "upstream_error", "result_unknown"])(
      "returns the Plugin's terminal %s outcome",
      async (status) => {
        const alice = await createUser(`outcome-decision-${status}@example.com`);
        const credential = await createPluginCredential(alice.token);
        const instance = await registerPlugin(credential);
        await seedSnapshot(alice.token, instance.ws, instance.instanceId, [
          permissionInteraction(instance.instanceId),
        ]);

        const commandId = randomUUID();
        const command = nextMessage(instance.ws);
        const response = decidePermission(alice.token, instance.instanceId, "per_1", {
          commandId,
          decision: "once",
        });
        const frame = (await command) as { commandId: string };
        expect(frame.commandId).toBe(commandId);
        instance.ws.send(
          JSON.stringify({
            type: "permission_decide_result",
            commandId,
            instanceId: instance.instanceId,
            status,
          }),
        );

        const res = await response;
        expect(res.statusCode).toBe(200);
        const body = res.json();
        expect(validatePermissionCommandResult(body)).toBe(true);
        expect(body).toEqual({ commandId, status });
      },
    );

    it("removes a confirmed request from the projection so a repeat decision is a 409", async () => {
      const alice = await createUser("confirm-remove-decision@example.com");
      const credential = await createPluginCredential(alice.token);
      const instance = await registerPlugin(credential);
      await seedSnapshot(alice.token, instance.ws, instance.instanceId, [
        permissionInteraction(instance.instanceId),
      ]);

      const commandId = randomUUID();
      const command = nextMessage(instance.ws);
      const response = decidePermission(alice.token, instance.instanceId, "per_1", {
        commandId,
        decision: "once",
      });
      const frame = (await command) as { commandId: string };
      expect(frame.commandId).toBe(commandId);
      instance.ws.send(
        JSON.stringify({
          type: "permission_decide_result",
          commandId,
          instanceId: instance.instanceId,
          status: "confirmed",
        }),
      );
      const res = await response;
      expect(res.statusCode).toBe(200);
      expect(res.json()).toEqual({ commandId, status: "confirmed" });

      // A racing client targeting the same request is refused before any
      // second command reaches the Plugin.
      const silence = expectSilence(instance.ws);
      const again = await decidePermission(alice.token, instance.instanceId, "per_1", {
        commandId: randomUUID(),
        decision: "reject",
      });
      await silence;
      expect(again.statusCode).toBe(409);
      expect((again.json() as { error: { code: string } }).error.code).toBe("CONFLICT");
    });
  });

  describe("timeout and disconnect", () => {
    it("returns result_unknown when the Plugin never answers within the bounded timeout", async () => {
      await startApp({ answerTimeoutMs: SHORT_DECISION_TIMEOUT_MS });
      const alice = await createUser("decision-timeout@example.com");
      const credential = await createPluginCredential(alice.token);
      const instance = await registerPlugin(credential);
      await seedSnapshot(alice.token, instance.ws, instance.instanceId, [
        permissionInteraction(instance.instanceId),
      ]);

      const commandId = randomUUID();
      const command = nextMessage(instance.ws);
      const response = decidePermission(alice.token, instance.instanceId, "per_1", {
        commandId,
        decision: "once",
      });
      const frame = (await command) as { commandId: string };
      expect(frame.commandId).toBe(commandId);
      // The Plugin never replies; the command settles as result_unknown.
      const res = await response;
      expect(res.statusCode).toBe(200);
      expect(res.json()).toEqual({ commandId, status: "result_unknown" });
      // The connection remains healthy after the timeout.
      expect(instance.ws.readyState).toBe(WebSocket.OPEN);
    });

    it("returns result_unknown when the owning Plugin disconnects mid-command", async () => {
      const alice = await createUser("decision-disconnect@example.com");
      const credential = await createPluginCredential(alice.token);
      const instance = await registerPlugin(credential);
      await seedSnapshot(alice.token, instance.ws, instance.instanceId, [
        permissionInteraction(instance.instanceId),
      ]);

      const commandId = randomUUID();
      const command = nextMessage(instance.ws);
      const response = decidePermission(alice.token, instance.instanceId, "per_1", {
        commandId,
        decision: "once",
      });
      const frame = (await command) as { commandId: string };
      expect(frame.commandId).toBe(commandId);
      instance.ws.close();
      const res = await response;
      expect(res.statusCode).toBe(200);
      expect(res.json()).toEqual({ commandId, status: "result_unknown" });
    });
  });

  describe("correlation", () => {
    it("rejects a second command for the same request while the first is in flight", async () => {
      const alice = await createUser("inflight-decision@example.com");
      const credential = await createPluginCredential(alice.token);
      const instance = await registerPlugin(credential);
      await seedSnapshot(alice.token, instance.ws, instance.instanceId, [
        permissionInteraction(instance.instanceId, "per_1"),
      ]);

      const firstCommandId = randomUUID();
      const firstFrame = nextMessage(instance.ws);
      const firstResponse = decidePermission(alice.token, instance.instanceId, "per_1", {
        commandId: firstCommandId,
        decision: "once",
      });
      await firstFrame;

      const second = await decidePermission(alice.token, instance.instanceId, "per_1", {
        commandId: randomUUID(),
        decision: "reject",
      });
      expect(second.statusCode).toBe(409);
      await expectSilence(instance.ws);

      instance.ws.send(
        JSON.stringify({
          type: "permission_decide_result",
          commandId: firstCommandId,
          instanceId: instance.instanceId,
          status: "confirmed",
        }),
      );
      expect((await firstResponse).json().status).toBe("confirmed");
    });

    it("rejects a duplicate commandId on the same connection while the first is in flight", async () => {
      const alice = await createUser("duplicate-command-decision@example.com");
      const credential = await createPluginCredential(alice.token);
      const instance = await registerPlugin(credential);
      await seedSnapshot(alice.token, instance.ws, instance.instanceId, [
        permissionInteraction(instance.instanceId, "per_a"),
        permissionInteraction(instance.instanceId, "per_b", {
          sessionId: "ses_b",
          occurredAt: "2026-08-14T09:00:02.000Z",
        }),
      ]);

      const sharedCommandId = randomUUID();
      const firstFrame = nextMessage(instance.ws);
      const firstResponse = decidePermission(alice.token, instance.instanceId, "per_a", {
        commandId: sharedCommandId,
        decision: "once",
      });
      const sent = (await firstFrame) as { commandId: string };
      expect(sent.commandId).toBe(sharedCommandId);

      // The same commandId against a different request on the same connection
      // is a conflict: the correlation keys are connection+commandId.
      const second = await decidePermission(alice.token, instance.instanceId, "per_b", {
        commandId: sharedCommandId,
        decision: "reject",
      });
      expect(second.statusCode).toBe(409);
      await expectSilence(instance.ws);

      instance.ws.send(
        JSON.stringify({
          type: "permission_decide_result",
          commandId: sharedCommandId,
          instanceId: instance.instanceId,
          status: "confirmed",
        }),
      );
      expect((await firstResponse).json().status).toBe("confirmed");
    });

    it("correlates commands by connection+commandId and ignores late, duplicate, foreign-instance, and foreign-connection results", async () => {
      const alice = await createUser("correlate-decision@example.com");
      const credential = await createPluginCredential(alice.token);
      const instance = await registerPlugin(credential);
      await seedSnapshot(alice.token, instance.ws, instance.instanceId, [
        permissionInteraction(instance.instanceId, "per_a"),
        permissionInteraction(instance.instanceId, "per_b", {
          sessionId: "ses_b",
          occurredAt: "2026-08-14T09:00:02.000Z",
        }),
      ]);

      const commandA = randomUUID();
      const commandB = randomUUID();
      // Issue each command and read its frame before issuing the next, so the
      // two frames are correlated deterministically; both stay in flight.
      const frameA = nextMessage(instance.ws);
      const responseA = decidePermission(alice.token, instance.instanceId, "per_a", {
        commandId: commandA,
        decision: "once",
      });
      const sentA = (await frameA) as { commandId: string };
      expect(sentA.commandId).toBe(commandA);

      const frameB = nextMessage(instance.ws);
      const responseB = decidePermission(alice.token, instance.instanceId, "per_b", {
        commandId: commandB,
        decision: "reject",
      });
      const sentB = (await frameB) as { commandId: string };
      expect(sentB.commandId).toBe(commandB);

      // A result for a command that was never issued is ignored.
      instance.ws.send(
        JSON.stringify({
          type: "permission_decide_result",
          commandId: randomUUID(),
          instanceId: instance.instanceId,
          status: "confirmed",
        }),
      );
      // A result naming a different instance is ignored even for a real commandId.
      instance.ws.send(
        JSON.stringify({
          type: "permission_decide_result",
          commandId: commandA,
          instanceId: randomUUID(),
          status: "confirmed",
        }),
      );

      // A result from a different connection (another instance of the same
      // user) for a real commandId is ignored: the command was issued on the
      // first connection only.
      const second = await registerPlugin(credential, {
        project: "second",
        directory: "/work/second",
      });
      expect(second.result.state).toBe("controllable");
      second.ws.send(
        JSON.stringify({
          type: "permission_decide_result",
          commandId: commandA,
          instanceId: second.instanceId,
          status: "confirmed",
        }),
      );

      // Settle B; a duplicate late reply for B after settlement is ignored.
      instance.ws.send(
        JSON.stringify({
          type: "permission_decide_result",
          commandId: commandB,
          instanceId: instance.instanceId,
          status: "confirmed",
        }),
      );
      const resB = await responseB;
      expect(resB.json()).toEqual({ commandId: commandB, status: "confirmed" });
      instance.ws.send(
        JSON.stringify({
          type: "permission_decide_result",
          commandId: commandB,
          instanceId: instance.instanceId,
          status: "stale",
        }),
      );

      // Settle A with the correct result on the exact connection.
      instance.ws.send(
        JSON.stringify({
          type: "permission_decide_result",
          commandId: commandA,
          instanceId: instance.instanceId,
          status: "upstream_error",
        }),
      );
      const resA = await responseA;
      expect(resA.json()).toEqual({ commandId: commandA, status: "upstream_error" });

      // The first connection remains healthy and still answers a fresh snapshot.
      await seedSnapshot(alice.token, instance.ws, instance.instanceId, [
        permissionInteraction(instance.instanceId, "per_c"),
      ]);
    });
  });

  describe("question regression", () => {
    it("keeps question answering unaffected alongside permission decisions", async () => {
      const alice = await createUser("question-regression-decision@example.com");
      const credential = await createPluginCredential(alice.token);
      const instance = await registerPlugin(credential);
      await seedSnapshot(alice.token, instance.ws, instance.instanceId, [
        permissionInteraction(instance.instanceId, "per_1"),
        questionInteraction(instance.instanceId, "req_1"),
      ]);

      // A permission decision and a question answer can both run on the same
      // connection without cross-talk.
      const permissionCommandId = randomUUID();
      const permissionFrame = nextMessage(instance.ws);
      const permissionResponse = decidePermission(alice.token, instance.instanceId, "per_1", {
        commandId: permissionCommandId,
        decision: "once",
      });
      const sentPermission = (await permissionFrame) as { type: string; commandId: string };
      expect(sentPermission.type).toBe("permission_decide_command");
      expect(sentPermission.commandId).toBe(permissionCommandId);

      const answerCommandId = randomUUID();
      const answerFrame = nextMessage(instance.ws);
      const answerResponse = app.inject({
        method: "POST",
        url: `/v1/pending-interactions/${instance.instanceId}/questions/req_1/answer`,
        headers: {
          authorization: `Bearer ${alice.token}`,
          "content-type": "application/json",
        },
        payload: { commandId: answerCommandId, answers: [["Postgres"]] },
      });
      const sentAnswer = (await answerFrame) as { type: string; commandId: string };
      expect(sentAnswer.type).toBe("question_answer_command");
      expect(sentAnswer.commandId).toBe(answerCommandId);

      instance.ws.send(
        JSON.stringify({
          type: "permission_decide_result",
          commandId: permissionCommandId,
          instanceId: instance.instanceId,
          status: "confirmed",
        }),
      );
      instance.ws.send(
        JSON.stringify({
          type: "question_answer_result",
          commandId: answerCommandId,
          instanceId: instance.instanceId,
          status: "confirmed",
        }),
      );
      expect((await permissionResponse).json()).toEqual({
        commandId: permissionCommandId,
        status: "confirmed",
      });
      expect((await answerResponse).json()).toEqual({
        commandId: answerCommandId,
        status: "confirmed",
      });

      // A question answer targeting the permission request is still the wrong
      // kind (conflict), and vice versa, with no command sent.
      const wrongPermission = await decidePermission(alice.token, instance.instanceId, "req_1", {
        commandId: randomUUID(),
        decision: "once",
      });
      expect(wrongPermission.statusCode).toBe(409);
      const wrongAnswer = await app.inject({
        method: "POST",
        url: `/v1/pending-interactions/${instance.instanceId}/questions/per_1/answer`,
        headers: {
          authorization: `Bearer ${alice.token}`,
          "content-type": "application/json",
        },
        payload: { commandId: randomUUID(), answers: [["Postgres"]] },
      });
      expect(wrongAnswer.statusCode).toBe(409);
      await expectSilence(instance.ws);
    });
  });

  describe("provider notification regression", () => {
    it("keeps provider actions ordinary notifications and out of the decision flow", async () => {
      const alice = await createUser("provider-decision@example.com");
      const credential = await createPluginCredential(alice.token);
      const instance = await registerPlugin(credential);

      const providerActionEvent = JSON.stringify({
        eventId: randomUUID(),
        type: "action_required",
        occurredAt: "2026-08-10T12:00:00.000Z",
        source: { machine: "workstation", project: "notify", directory: "/repo" },
        session: { id: "session-1", title: "Coding" },
        payload: {
          requestId: "pro_1",
          kind: "provider_action",
          providerAction: {
            provider: "anthropic",
            title: "Sign-in required",
            message: "Your Anthropic session has expired.",
            label: "Reconnect",
            link: "https://provider.example/reconnect",
          },
        },
      });
      const timestamp = String(clock.nowMs());
      const secret = credential.slice(credential.indexOf(".") + 1);
      const signature = createHmac("sha256", secret)
        .update(`${timestamp}.${providerActionEvent}`)
        .digest("hex");
      const ingest = await app.inject({
        method: "POST",
        url: "/v1/events",
        headers: {
          "content-type": "application/json",
          authorization: `Bearer ${credential}`,
          "x-notify-timestamp": timestamp,
          "x-notify-signature": signature,
        },
        payload: providerActionEvent,
      });
      expect(ingest.statusCode).toBe(202);

      // Provider actions never become pending interactions, so a decision for
      // their request id is unknown even after a fresh snapshot.
      await seedSnapshot(alice.token, instance.ws, instance.instanceId, [
        permissionInteraction(instance.instanceId),
      ]);
      const silence = expectSilence(instance.ws);
      const res = await decidePermission(alice.token, instance.instanceId, "pro_1", {
        commandId: randomUUID(),
        decision: "once",
      });
      await silence;
      expect(res.statusCode).toBe(404);
      expect((res.json() as { error: { code: string } }).error.code).toBe("NOT_FOUND");
      expect(JSON.stringify(res.json())).not.toContain("provider_action");
      expect(JSON.stringify(res.json())).not.toContain("Sign-in required");
    });
  });

  describe("no persistence and log leakage", () => {
    it("never persists or logs permission decisions or interaction content", async () => {
      const { stream, output } = captureLogStream();
      await app.close();
      app = await buildServer({
        config: buildTestConfig({ databaseUrl: pg.databaseUrl, logLevel: "info" }),
        loggerStream: stream,
        db: handle.db,
        mailer,
        clock,
        realtime: { pingIntervalMs: TEST_PING_INTERVAL_MS },
        fcmSender: noopFcmSender,
      });
      // Probe that logs a decision body and a pending interaction the way the
      // real routes' bodies would be logged; the central redaction must censor
      // the decision, patterns, always, and metadata paths.
      app.post("/_probe-decisions", async (request) => {
        request.log.info({ body: request.body }, "probe decisions");
        return { status: "ok" };
      });
      await app.listen({ host: "127.0.0.1", port: 0 });
      const address = app.server.address();
      if (address === null || typeof address === "string") {
        throw new Error("expected an ephemeral TCP port");
      }
      port = address.port;

      const alice = await createUser("no-log-decision@example.com");
      const credential = await createPluginCredential(alice.token);
      const instance = await registerPlugin(credential);
      await seedSnapshot(alice.token, instance.ws, instance.instanceId, [
        permissionInteraction(instance.instanceId, "per_sentinel"),
      ]);

      // The real route relays only enum-valid decisions; the sentinel values
      // exercise the redaction rules directly through the probe.
      const decisionSentinel = "SENTINEL-DECISION-7d6c5b4a";
      const patternsSentinel = "SENTINEL-PATTERNS-6c5b4a39";
      const alwaysSentinel = "SENTINEL-ALWAYS-5b4a3928";
      const metadataSentinel = "SENTINEL-METADATA-4a392817";
      const commandId = randomUUID();
      const command = nextMessage(instance.ws);
      const response = decidePermission(alice.token, instance.instanceId, "per_sentinel", {
        commandId,
        decision: "once",
      });
      const frame = (await command) as { decision: string };
      expect(frame.decision).toBe("once");
      instance.ws.send(
        JSON.stringify({
          type: "permission_decide_result",
          commandId,
          instanceId: instance.instanceId,
          status: "confirmed",
        }),
      );
      const res = await response;
      expect(res.statusCode).toBe(200);

      // Log a decision body and a full interaction body directly: every
      // sensitive path must be redacted.
      const probe = await app.inject({
        method: "POST",
        url: "/_probe-decisions",
        payload: {
          commandId: randomUUID(),
          decision: decisionSentinel,
          interactions: [
            {
              kind: "permission",
              patterns: [patternsSentinel],
              always: [alwaysSentinel],
              metadata: { source: metadataSentinel },
            },
          ],
        },
      });
      expect(probe.statusCode).toBe(200);

      const logged = output();
      expect(logged).toContain("probe decisions");
      expect(logged).not.toContain(decisionSentinel);
      expect(logged).not.toContain(patternsSentinel);
      expect(logged).not.toContain(alwaysSentinel);
      expect(logged).not.toContain(metadataSentinel);

      // No persistence: no table holds interactions or decisions.
      const tables = (await handle.db.execute<{ tablename: string }>(
        sql`select tablename from pg_tables where schemaname = 'public'`,
      )) as { tablename: string }[];
      const names = tables.map((row) => row.tablename);
      expect(names).not.toContain("pending_interactions");
      expect(names).not.toContain("interactions");
      expect(names).not.toContain("permission_decisions");
      expect(names).not.toContain("decisions");
    });
  });
});

function captureLogStream(): { stream: Writable; output: () => string } {
  let output = "";
  const stream = new Writable({
    write(chunk, _encoding, callback) {
      output += String(chunk);
      callback();
    },
  });
  return { stream, output: () => output };
}
