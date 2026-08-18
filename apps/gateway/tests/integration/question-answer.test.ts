import { randomUUID } from "node:crypto";
import { Writable } from "node:stream";

import {
  validateCommandAccepted,
  validateCommandOutcome,
  validateErrorResponse,
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

/** Short answer-command wait so result-unknown is exercised without real waits. */
const SHORT_ANSWER_TIMEOUT_MS = 200;

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

describe("question answering", () => {
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

  function connectWebUi(token: string): Promise<WebSocket> {
    return new Promise((resolve, reject) => {
      const ws = new WebSocket(`ws://127.0.0.1:${port}/v1/webui/ws`, {
        headers: { authorization: `Bearer ${token}` },
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
        protocolVersion: 2,
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

  function answerQuestion(
    token: string | null,
    instanceId: string,
    requestId: string,
    body: Record<string, unknown>,
    overrides: Record<string, string> = {},
  ) {
    return app.inject({
      method: "POST",
      url: `/v1/pending-interactions/${instanceId}/questions/${requestId}/answer`,
      headers: {
        ...(token === null ? {} : { authorization: `Bearer ${token}` }),
        "content-type": "application/json",
        ...overrides,
      },
      // The session id is a required field of the strict body; default it so
      // tests about auth and other validation failures keep exercising the
      // condition they name rather than a missing session id.
      payload: { sessionId: "ses_1", ...body },
    });
  }

  function sendSessionPrompt(
    token: string,
    instanceId: string,
    sessionId: string,
    body: Record<string, unknown>,
  ) {
    return app.inject({
      method: "POST",
      url: `/v1/instances/${instanceId}/sessions/${sessionId}/prompt`,
      headers: {
        authorization: `Bearer ${token}`,
        "content-type": "application/json",
      },
      payload: body,
    });
  }

  function commandOutcome(
    token: string,
    commandId: string,
    overrides: Record<string, string> = {},
  ) {
    return app.inject({
      method: "GET",
      url: `/v1/pending-interactions/commands/${commandId}`,
      headers: {
        authorization: `Bearer ${token}`,
        ...overrides,
      },
    });
  }

  /**
   * Poll the body-free command outcome endpoint until the command settles on
   * the expected terminal status, returning the validated outcome. The POST
   * acknowledges routing immediately, so terminal outcomes surface through
   * this GET endpoint instead.
   */
  async function expectOutcome(
    token: string,
    commandId: string,
    status: string,
    timeoutMs = 3_000,
  ): Promise<Record<string, unknown>> {
    const deadline = Date.now() + timeoutMs;
    for (;;) {
      const res = await commandOutcome(token, commandId);
      if (res.statusCode === 200) {
        const body = res.json() as Record<string, unknown>;
        if (body.status === status) {
          expect(validateCommandOutcome(body)).toBe(true);
          return body;
        }
      }
      if (Date.now() >= deadline) {
        throw new Error(`timed out waiting for command ${commandId} outcome ${status}`);
      }
      await new Promise((resolve) => setTimeout(resolve, 25));
    }
  }

  describe("authentication and validation", () => {
    it("rejects unauthenticated and malformed tokens with 401 UNAUTHORIZED", async () => {
      const alice = await createUser("unauth-answer@example.com");
      const credential = await createPluginCredential(alice.token);
      const instance = await registerPlugin(credential);
      await seedSnapshot(alice.token, instance.ws, instance.instanceId, [
        questionInteraction(instance.instanceId),
      ]);

      const cases: [string, string | null | undefined][] = [
        ["missing token", null],
        ["wrong scheme", undefined],
        ["garbage token", "not-a-jwt"],
      ];
      for (const [name, token] of cases) {
        const res = await answerQuestion(
          token === undefined ? "" : token,
          instance.instanceId,
          "req_1",
          { commandId: randomUUID(), answers: [["Postgres"]] },
          token === undefined ? { authorization: "Token abc" } : {},
        );
        expect(res.statusCode, name).toBe(401);
        expect(validateErrorResponse(res.json())).toBe(true);
        expect((res.json() as { error: { code: string } }).error.code).toBe("UNAUTHORIZED");
      }
    });

    it("rejects malformed answer bodies with 400 VALIDATION_FAILED", async () => {
      const alice = await createUser("malformed@example.com");
      const credential = await createPluginCredential(alice.token);
      const instance = await registerPlugin(credential);
      await seedSnapshot(alice.token, instance.ws, instance.instanceId, [
        questionInteraction(instance.instanceId),
      ]);

      const commandId = randomUUID();
      const malformed: [string, Record<string, unknown>][] = [
        ["missing commandId", { answers: [["Postgres"]] }],
        ["missing answers", { commandId }],
        ["non-uuid commandId", { commandId: "cmd_1", answers: [["Postgres"]] }],
        ["empty answers", { commandId, answers: [] }],
        ["empty inner answer", { commandId, answers: [[]] }],
        ["empty answer string", { commandId, answers: [[""]] }],
        ["non-string answer value", { commandId, answers: [[42]] }],
        ["unknown property", { commandId, answers: [["Postgres"]], extra: true }],
      ];
      for (const [name, body] of malformed) {
        const res = await answerQuestion(alice.token, instance.instanceId, "req_1", body);
        expect(res.statusCode, name).toBe(400);
        expect(validateErrorResponse(res.json())).toBe(true);
        expect((res.json() as { error: { code: string } }).error.code).toBe("VALIDATION_FAILED");
      }

      // The session id is a required field of the strict body; the helper
      // defaults it for the cases above, so omitting it is a distinct failure.
      const missingSessionId = await app.inject({
        method: "POST",
        url: `/v1/pending-interactions/${instance.instanceId}/questions/req_1/answer`,
        headers: {
          authorization: `Bearer ${alice.token}`,
          "content-type": "application/json",
        },
        payload: { commandId: randomUUID(), answers: [["Postgres"]] },
      });
      expect(missingSessionId.statusCode).toBe(400);
      expect(validateErrorResponse(missingSessionId.json())).toBe(true);
      expect((missingSessionId.json() as { error: { code: string } }).error.code).toBe(
        "VALIDATION_FAILED",
      );
    });
  });

  describe("happy path", () => {
    it("routes a free-form Session prompt without waiting for OpenCode", async () => {
      const alice = await createUser("prompt@example.com");
      const credential = await createPluginCredential(alice.token);
      const instance = await registerPlugin(credential);
      const commandId = randomUUID();
      const commandFrame = nextMessage(instance.ws);

      const response = await sendSessionPrompt(
        alice.token,
        instance.instanceId,
        "ses_existing",
        { commandId, text: "Continue the implementation and run the tests" },
      );

      expect(response.statusCode).toBe(202);
      expect(validateCommandAccepted(response.json())).toBe(true);
      expect(response.json()).toEqual({ commandId, status: "accepted" });
      expect(await commandFrame).toEqual({
        type: "session_prompt_command",
        commandId,
        sessionID: "ses_existing",
        text: "Continue the implementation and run the tests",
      });

      instance.ws.send(
        JSON.stringify({
          type: "session_prompt_result",
          commandId,
          instanceId: instance.instanceId,
          status: "confirmed",
        }),
      );
    });

    it("rejects malformed prompts and unknown instances before routing", async () => {
      const alice = await createUser("prompt-errors@example.com");
      const credential = await createPluginCredential(alice.token);
      const instance = await registerPlugin(credential);

      const malformed = await sendSessionPrompt(
        alice.token,
        instance.instanceId,
        "ses_existing",
        { commandId: randomUUID(), text: "" },
      );
      expect(malformed.statusCode).toBe(400);
      expect(validateErrorResponse(malformed.json())).toBe(true);

      const missing = await sendSessionPrompt(
        alice.token,
        randomUUID(),
        "ses_existing",
        { commandId: randomUUID(), text: "Continue" },
      );
      expect(missing.statusCode).toBe(404);
      expect(validateErrorResponse(missing.json())).toBe(true);
      await expectSilence(instance.ws);
    });

    it("relays a temporary WebUI HTTP stream through the Plugin connection", async () => {
      const alice = await createUser("webui-tunnel@example.com");
      const credential = await createPluginCredential(alice.token);
      const instance = await registerPlugin(credential);
      const client = await connectWebUi(alice.token);
      const readyPromise = nextMessage(client);
      client.send(
        JSON.stringify({
          type: "webui_tunnel_open",
          instanceId: instance.instanceId,
        }),
      );
      const ready = await readyPromise;
      expect(ready.type).toBe("webui_tunnel_ready");
      const tunnelId = ready.tunnelId as string;
      const requestId = randomUUID();
      const pluginRequest = nextMessage(instance.ws);
      client.send(
        JSON.stringify({
          type: "webui_http_request",
          tunnelId,
          requestId,
          method: "GET",
          path: "/",
          headers: { accept: ["text/html"] },
        }),
      );
      expect(await pluginRequest).toEqual({
        type: "webui_http_request",
        tunnelId,
        requestId,
        method: "GET",
        path: "/",
        headers: { accept: ["text/html"] },
      });

      const start = nextMessage(client);
      instance.ws.send(
        JSON.stringify({
          type: "webui_http_response_start",
          tunnelId,
          requestId,
          status: 200,
          headers: { "content-type": ["text/html"] },
        }),
      );
      expect(await start).toMatchObject({ type: "webui_http_response_start", status: 200 });

      const chunk = nextMessage(client);
      instance.ws.send(
        JSON.stringify({
          type: "webui_http_response_chunk",
          tunnelId,
          requestId,
          body: Buffer.from("<html>ok</html>").toString("base64"),
        }),
      );
      expect((await chunk).body).toBe(Buffer.from("<html>ok</html>").toString("base64"));

      const end = nextMessage(client);
      instance.ws.send(JSON.stringify({ type: "webui_http_response_end", tunnelId, requestId }));
      expect(await end).toEqual({ type: "webui_http_response_end", tunnelId, requestId });
    });

    it("accepts after routing a complete answer without waiting for the Plugin result", async () => {
      const alice = await createUser("answer@example.com");
      const credential = await createPluginCredential(alice.token);
      const instance = await registerPlugin(credential);
      expect(instance.result.state).toBe("controllable");

      await seedSnapshot(alice.token, instance.ws, instance.instanceId, [
        questionInteraction(instance.instanceId, "req_1", {
          questions: [
            {
              header: "Database",
              question: "Which database?",
              options: [{ label: "Postgres", description: "Production parity" }],
              multiple: false,
              custom: true,
            },
            {
              header: "Languages",
              question: "Which languages?",
              options: [
                { label: "rust", description: "Systems" },
                { label: "go", description: "Web" },
              ],
              multiple: true,
              custom: true,
            },
            {
              header: "Extra",
              question: "Anything else?",
              options: [],
              multiple: false,
              custom: true,
            },
          ],
        }),
      ]);

      const commandId = randomUUID();
      const answers = [
        ["Postgres"],
        ["rust", "go", "Custom: polyglot"],
        ["Custom: as needed"],
      ];

      const command = nextMessage(instance.ws);
      const response = answerQuestion(alice.token, instance.instanceId, "req_1", {
        commandId,
        sessionId: "ses_1",
        answers,
      });
      const frame = (await command) as Record<string, unknown>;
      expect(frame).toEqual({
        type: "question_answer_command",
        commandId,
        requestId: "req_1",
        sessionID: "ses_1",
        answers,
      });

      const res = await response;
      expect(res.statusCode).toBe(202);
      const body = res.json();
      expect(validateCommandAccepted(body)).toBe(true);
      expect(body).toEqual({ commandId, status: "accepted" });

      // The moment the command is routed, the body-free outcome correlation
      // records it as accepted; the GET endpoint serves it to the owner.
      const accepted = await commandOutcome(alice.token, commandId);
      expect(accepted.statusCode).toBe(200);
      expect(validateCommandOutcome(accepted.json())).toBe(true);
      expect(accepted.json()).toEqual({
        commandId,
        requestId: "req_1",
        instanceId: instance.instanceId,
        kind: "question",
        status: "accepted",
        updatedAt: new Date(T0).toISOString(),
      });

      // The HTTP submission has already completed and does not depend on the
      // Plugin result; the terminal outcome still surfaces through the GET
      // endpoint once the owning Plugin reports it.
      instance.ws.send(
        JSON.stringify({
          type: "question_answer_result",
          commandId,
          instanceId: instance.instanceId,
          status: "confirmed",
        }),
      );
      const outcome = await expectOutcome(alice.token, commandId, "confirmed");
      expect(outcome).toEqual({
        commandId,
        requestId: "req_1",
        instanceId: instance.instanceId,
        kind: "question",
        status: "confirmed",
        updatedAt: new Date(T0).toISOString(),
      });
    });
  });

  describe("exclusion", () => {
    it("answers 404 with silence for foreign, unknown, offline, conflicting, and incompatible targets", async () => {
      const alice = await createUser("exclude-answer@example.com");
      const bob = await createUser("bob-answer@example.com");
      const aliceCredential = await createPluginCredential(alice.token);
      const bobCredential = await createPluginCredential(bob.token);

      // Controllable owner of devbox:/work/notify.
      const owner = await registerPlugin(aliceCredential);
      expect(owner.result.state).toBe("controllable");
      await seedSnapshot(alice.token, owner.ws, owner.instanceId, [
        questionInteraction(owner.instanceId),
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
        const res = await answerQuestion(c.token, c.instanceId, "req_1", {
          commandId: randomUUID(),
          answers: [["Postgres"]],
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
      const alice = await createUser("projection@example.com");
      const credential = await createPluginCredential(alice.token);
      const instance = await registerPlugin(credential);
      expect(instance.result.state).toBe("controllable");

      // A request id the Plugin never reported pending is unknown.
      let silence = expectSilence(instance.ws);
      let res = await answerQuestion(alice.token, instance.instanceId, "never_seen", {
        commandId: randomUUID(),
        answers: [["Postgres"]],
      });
      await silence;
      expect(res.statusCode).toBe(404);
      expect((res.json() as { error: { code: string } }).error.code).toBe("NOT_FOUND");

      await seedSnapshot(alice.token, instance.ws, instance.instanceId, [
        questionInteraction(instance.instanceId, "req_question"),
        permissionInteraction(instance.instanceId, "req_permission"),
      ]);

      // The request id alone is insufficient: a client must echo the session
      // carried by the projected interaction.
      silence = expectSilence(instance.ws);
      res = await answerQuestion(alice.token, instance.instanceId, "req_question", {
        commandId: randomUUID(),
        sessionId: "ses_wrong",
        answers: [["Postgres"]],
      });
      await silence;
      expect(res.statusCode).toBe(409);
      expect((res.json() as { error: { code: string } }).error.code).toBe("CONFLICT");

      // A projected permission request is the wrong kind: conflict, no command.
      silence = expectSilence(instance.ws);
      res = await answerQuestion(alice.token, instance.instanceId, "req_permission", {
        commandId: randomUUID(),
        answers: [["Postgres"]],
      });
      await silence;
      expect(res.statusCode).toBe(409);
      expect((res.json() as { error: { code: string } }).error.code).toBe("CONFLICT");

      // A newer empty snapshot means the question request is no longer
      // pending: answering it is a stale conflict, no command.
      await seedSnapshot(alice.token, instance.ws, instance.instanceId, []);
      silence = expectSilence(instance.ws);
      res = await answerQuestion(alice.token, instance.instanceId, "req_question", {
        commandId: randomUUID(),
        answers: [["Postgres"]],
      });
      await silence;
      expect(res.statusCode).toBe(409);
      expect((res.json() as { error: { code: string } }).error.code).toBe("CONFLICT");
    });
  });

  describe("outcomes", () => {
    it.each(["confirmed", "stale", "upstream_error", "result_unknown"])(
      "tracks the Plugin's terminal %s outcome via the command outcome endpoint",
      async (status) => {
        const alice = await createUser(`outcome-${status}@example.com`);
        const credential = await createPluginCredential(alice.token);
        const instance = await registerPlugin(credential);
        await seedSnapshot(alice.token, instance.ws, instance.instanceId, [
          questionInteraction(instance.instanceId),
        ]);

        const commandId = randomUUID();
        const command = nextMessage(instance.ws);
        const response = answerQuestion(alice.token, instance.instanceId, "req_1", {
          commandId,
          answers: [["Postgres"]],
        });
        const frame = (await command) as { commandId: string };
        expect(frame.commandId).toBe(commandId);

        // The POST acknowledges routing immediately and never reports a
        // terminal status.
        const res = await response;
        expect(res.statusCode).toBe(202);
        expect(res.json()).toEqual({ commandId, status: "accepted" });

        instance.ws.send(
          JSON.stringify({
            type: "question_answer_result",
            commandId,
            instanceId: instance.instanceId,
            status,
          }),
        );

        const outcome = await expectOutcome(alice.token, commandId, status);
        expect(outcome).toEqual({
          commandId,
          requestId: "req_1",
          instanceId: instance.instanceId,
          kind: "question",
          status,
          updatedAt: new Date(T0).toISOString(),
        });
      },
    );

    it("removes a confirmed request from the projection so a repeat answer is a 409", async () => {
      const alice = await createUser("confirm-remove@example.com");
      const credential = await createPluginCredential(alice.token);
      const instance = await registerPlugin(credential);
      await seedSnapshot(alice.token, instance.ws, instance.instanceId, [
        questionInteraction(instance.instanceId),
      ]);

      const commandId = randomUUID();
      const command = nextMessage(instance.ws);
      const response = answerQuestion(alice.token, instance.instanceId, "req_1", {
        commandId,
        answers: [["Postgres"]],
      });
      const frame = (await command) as { commandId: string };
      expect(frame.commandId).toBe(commandId);
      const res = await response;
      expect(res.statusCode).toBe(202);
      expect(res.json()).toEqual({ commandId, status: "accepted" });

      // A confirmed result drops the request from the projection; the GET
      // outcome reaching `confirmed` confirms the result was applied before
      // the racing client is refused.
      instance.ws.send(
        JSON.stringify({
          type: "question_answer_result",
          commandId,
          instanceId: instance.instanceId,
          status: "confirmed",
        }),
      );
      const outcome = await expectOutcome(alice.token, commandId, "confirmed");
      expect(outcome).toMatchObject({ commandId, status: "confirmed" });

      // A racing client targeting the same request is refused before any
      // second command reaches the Plugin.
      const silence = expectSilence(instance.ws);
      const again = await answerQuestion(alice.token, instance.instanceId, "req_1", {
        commandId: randomUUID(),
        answers: [["Postgres"]],
      });
      await silence;
      expect(again.statusCode).toBe(409);
      expect((again.json() as { error: { code: string } }).error.code).toBe("CONFLICT");
    });
  });

  describe("timeout and disconnect", () => {
    it("returns result_unknown when the Plugin never answers within the bounded timeout", async () => {
      await startApp({ answerTimeoutMs: SHORT_ANSWER_TIMEOUT_MS });
      const alice = await createUser("answer-timeout@example.com");
      const credential = await createPluginCredential(alice.token);
      const instance = await registerPlugin(credential);
      await seedSnapshot(alice.token, instance.ws, instance.instanceId, [
        questionInteraction(instance.instanceId),
      ]);

      const commandId = randomUUID();
      const command = nextMessage(instance.ws);
      const response = answerQuestion(alice.token, instance.instanceId, "req_1", {
        commandId,
        answers: [["Postgres"]],
      });
      const frame = (await command) as { commandId: string };
      expect(frame.commandId).toBe(commandId);
      const res = await response;
      expect(res.statusCode).toBe(202);
      expect(res.json()).toEqual({ commandId, status: "accepted" });
      // The Plugin never replies; the command settles as result_unknown on the
      // outcome endpoint.
      const outcome = await expectOutcome(alice.token, commandId, "result_unknown");
      expect(outcome).toMatchObject({ commandId, status: "result_unknown" });
      // The connection remains healthy after the timeout.
      expect(instance.ws.readyState).toBe(WebSocket.OPEN);
    });

    it("returns result_unknown when the owning Plugin disconnects mid-command", async () => {
      const alice = await createUser("answer-disconnect@example.com");
      const credential = await createPluginCredential(alice.token);
      const instance = await registerPlugin(credential);
      await seedSnapshot(alice.token, instance.ws, instance.instanceId, [
        questionInteraction(instance.instanceId),
      ]);

      const commandId = randomUUID();
      const command = nextMessage(instance.ws);
      const response = answerQuestion(alice.token, instance.instanceId, "req_1", {
        commandId,
        answers: [["Postgres"]],
      });
      const frame = (await command) as { commandId: string };
      expect(frame.commandId).toBe(commandId);
      instance.ws.close();
      const res = await response;
      expect(res.statusCode).toBe(202);
      expect(res.json()).toEqual({ commandId, status: "accepted" });
      const outcome = await expectOutcome(alice.token, commandId, "result_unknown");
      expect(outcome).toMatchObject({ commandId, status: "result_unknown" });
    });
  });

  describe("correlation", () => {
    it("rejects a second command for the same request while the first is in flight", async () => {
      const alice = await createUser("inflight@example.com");
      const credential = await createPluginCredential(alice.token);
      const instance = await registerPlugin(credential);
      await seedSnapshot(alice.token, instance.ws, instance.instanceId, [
        questionInteraction(instance.instanceId, "req_1"),
      ]);

      const firstCommandId = randomUUID();
      const firstFrame = nextMessage(instance.ws);
      const firstResponse = answerQuestion(alice.token, instance.instanceId, "req_1", {
        commandId: firstCommandId,
        answers: [["first"]],
      });
      await firstFrame;

      const second = await answerQuestion(alice.token, instance.instanceId, "req_1", {
        commandId: randomUUID(),
        answers: [["second"]],
      });
      expect(second.statusCode).toBe(409);
      await expectSilence(instance.ws);

      const firstRes = await firstResponse;
      expect(firstRes.statusCode).toBe(202);
      expect(firstRes.json()).toEqual({ commandId: firstCommandId, status: "accepted" });

      instance.ws.send(
        JSON.stringify({
          type: "question_answer_result",
          commandId: firstCommandId,
          instanceId: instance.instanceId,
          status: "confirmed",
        }),
      );
      const outcome = await expectOutcome(alice.token, firstCommandId, "confirmed");
      expect(outcome).toMatchObject({ commandId: firstCommandId, status: "confirmed" });
    });

    it("correlates commands by connection+commandId and ignores late, duplicate, foreign-instance, and foreign-connection results", async () => {
      const alice = await createUser("correlate@example.com");
      const credential = await createPluginCredential(alice.token);
      const instance = await registerPlugin(credential);
      await seedSnapshot(alice.token, instance.ws, instance.instanceId, [
        questionInteraction(instance.instanceId, "req_a"),
        questionInteraction(instance.instanceId, "req_b", { sessionId: "ses_b" }),
      ]);

      const commandA = randomUUID();
      const commandB = randomUUID();
      // Issue each command and read its frame before issuing the next, so the
      // two frames are correlated deterministically; both stay in flight.
      const frameA = nextMessage(instance.ws);
      const responseA = answerQuestion(alice.token, instance.instanceId, "req_a", {
        commandId: commandA,
        answers: [["x"]],
      });
      const sentA = (await frameA) as { commandId: string };
      expect(sentA.commandId).toBe(commandA);

      const frameB = nextMessage(instance.ws);
      const responseB = answerQuestion(alice.token, instance.instanceId, "req_b", {
        commandId: commandB,
        sessionId: "ses_b",
        answers: [["y"]],
      });
      const sentB = (await frameB) as { commandId: string };
      expect(sentB.commandId).toBe(commandB);

      // A result for a command that was never issued is ignored.
      instance.ws.send(
        JSON.stringify({
          type: "question_answer_result",
          commandId: randomUUID(),
          instanceId: instance.instanceId,
          status: "confirmed",
        }),
      );
      // A result naming a different instance is ignored even for a real commandId.
      instance.ws.send(
        JSON.stringify({
          type: "question_answer_result",
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
          type: "question_answer_result",
          commandId: commandA,
          instanceId: second.instanceId,
          status: "confirmed",
        }),
      );

      // Settle B; a duplicate late reply for B after settlement is ignored.
      instance.ws.send(
        JSON.stringify({
          type: "question_answer_result",
          commandId: commandB,
          instanceId: instance.instanceId,
          status: "confirmed",
        }),
      );
      const resB = await responseB;
      expect(resB.statusCode).toBe(202);
      expect(resB.json()).toEqual({ commandId: commandB, status: "accepted" });
      const outcomeB = await expectOutcome(alice.token, commandB, "confirmed");
      expect(outcomeB).toMatchObject({ commandId: commandB, status: "confirmed" });
      instance.ws.send(
        JSON.stringify({
          type: "question_answer_result",
          commandId: commandB,
          instanceId: instance.instanceId,
          status: "stale",
        }),
      );
      // The late duplicate after settlement must not overwrite the outcome.
      const afterLate = await commandOutcome(alice.token, commandB);
      expect(afterLate.statusCode).toBe(200);
      expect(afterLate.json()).toMatchObject({ commandId: commandB, status: "confirmed" });

      // Settle A with the correct result on the exact connection.
      instance.ws.send(
        JSON.stringify({
          type: "question_answer_result",
          commandId: commandA,
          instanceId: instance.instanceId,
          status: "upstream_error",
        }),
      );
      const resA = await responseA;
      expect(resA.statusCode).toBe(202);
      expect(resA.json()).toEqual({ commandId: commandA, status: "accepted" });
      // The foreign-instance and foreign-connection confirmed results never
      // settled A: only the exact connection's result advances it.
      const outcomeA = await expectOutcome(alice.token, commandA, "upstream_error");
      expect(outcomeA).toMatchObject({ commandId: commandA, status: "upstream_error" });

      // The first connection remains healthy and still answers a fresh snapshot.
      await seedSnapshot(alice.token, instance.ws, instance.instanceId, [
        questionInteraction(instance.instanceId, "req_c"),
      ]);
    });
  });

  describe("no persistence and log leakage", () => {
    it("never persists or logs answer content", async () => {
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
      // Probe that logs an answer body the way the real route's body would be
      // logged; the central redaction must censor the answers path.
      app.post("/_probe-answers", async (request) => {
        request.log.info({ body: request.body }, "probe answers");
        return { status: "ok" };
      });
      await app.listen({ host: "127.0.0.1", port: 0 });
      const address = app.server.address();
      if (address === null || typeof address === "string") {
        throw new Error("expected an ephemeral TCP port");
      }
      port = address.port;

      const alice = await createUser("no-log-answer@example.com");
      const credential = await createPluginCredential(alice.token);
      const instance = await registerPlugin(credential);
      await seedSnapshot(alice.token, instance.ws, instance.instanceId, [
        questionInteraction(instance.instanceId, "req_sentinel"),
      ]);

      const answerSentinel = "SENTINEL-ANSWER-3d2c1b0a";
      const probeSentinel = "SENTINEL-PROBE-4e3d2c1b";
      const commandId = randomUUID();
      const command = nextMessage(instance.ws);
      const response = answerQuestion(alice.token, instance.instanceId, "req_sentinel", {
        commandId,
        answers: [[answerSentinel]],
      });
      // The gateway relayed the answer verbatim to the Plugin over the control
      // channel — the only place the content is allowed to travel.
      const frame = (await command) as { answers: string[][] };
      expect(frame.answers).toEqual([[answerSentinel]]);
      const res = await response;
      expect(res.statusCode).toBe(202);
      expect(res.json()).toEqual({ commandId, status: "accepted" });

      // Log an answer body directly: the answer path must be redacted.
      const probe = await app.inject({
        method: "POST",
        url: "/_probe-answers",
        payload: { commandId: randomUUID(), answers: [[probeSentinel]] },
      });
      expect(probe.statusCode).toBe(200);

      const logged = output();
      expect(logged).toContain("probe answers");
      expect(logged).not.toContain(answerSentinel);
      expect(logged).not.toContain(probeSentinel);

      // No persistence: no table holds interactions or answers.
      const tables = (await handle.db.execute<{ tablename: string }>(
        sql`select tablename from pg_tables where schemaname = 'public'`,
      )) as { tablename: string }[];
      const names = tables.map((row) => row.tablename);
      expect(names).not.toContain("pending_interactions");
      expect(names).not.toContain("interactions");
      expect(names).not.toContain("answers");
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
