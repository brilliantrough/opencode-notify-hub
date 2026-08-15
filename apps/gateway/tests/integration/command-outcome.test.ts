import { randomUUID } from "node:crypto";
import { Writable } from "node:stream";

import {
  validateCommandOutcome,
  validateErrorResponse,
  validatePermissionCommandResult,
  validateQuestionCommandResult,
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

/** Fixed "now" for the fake clock: deterministic timestamps. */
const T0 = 1_800_000_000_000;

/** Fast heartbeat so control sockets stay alive in milliseconds. */
const TEST_PING_INTERVAL_MS = 60;

/** Short answer-command wait so result-unknown is exercised without real waits. */
const SHORT_ANSWER_TIMEOUT_MS = 200;

/** Tiny outcome TTL so expiry is exercised by advancing the fake clock. */
const TINY_OUTCOME_TTL_MS = 5_000;

/** A fake clock that tests can advance deterministically. */
class FakeClock implements Clock {
  constructor(private value: number) {}

  now(): Date {
    return new Date(this.value);
  }

  nowMs(): number {
    return this.value;
  }

  advance(ms: number): void {
    this.value += ms;
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

describe("command outcomes", () => {
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
    overrides: {
      snapshotTimeoutMs?: number;
      answerTimeoutMs?: number;
      outcomeTtlMs?: number;
      maxCommandOutcomes?: number;
    } = {},
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
        overrides.snapshotTimeoutMs !== undefined ||
        overrides.answerTimeoutMs !== undefined ||
        overrides.outcomeTtlMs !== undefined ||
        overrides.maxCommandOutcomes !== undefined
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
    return { token: await login(email), userId: (await userIdFor(email))! };
  }

  /** Log an existing user in; returns a fresh access token (a second client). */
  async function login(email: string): Promise<string> {
    const login = await app.inject({
      method: "POST",
      url: "/v1/auth/login",
      payload: { email, password: PASSWORD },
    });
    expect(login.statusCode).toBe(200);
    return login.json().accessToken as string;
  }

  async function userIdFor(email: string): Promise<string | undefined> {
    const rows = (await handle.db.execute<{ id: string }>(
      sql`select id from users where email = ${email}`,
    )) as { id: string }[];
    return rows[0]?.id;
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
      payload: body,
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

  function getCommandOutcome(
    token: string | null,
    commandId: string,
    overrides: Record<string, string> = {},
  ) {
    return app.inject({
      method: "GET",
      url: `/v1/pending-interactions/commands/${commandId}`,
      headers: {
        ...(token === null ? {} : { authorization: `Bearer ${token}` }),
        ...overrides,
      },
    });
  }

  describe("authentication", () => {
    it("rejects unauthenticated and malformed tokens with 401 UNAUTHORIZED", async () => {
      const alice = await createUser("outcome-unauth@example.com");
      const credential = await createPluginCredential(alice.token);
      const instance = await registerPlugin(credential);
      const commandId = randomUUID();

      const cases: [string, string | null | undefined][] = [
        ["missing token", null],
        ["wrong scheme", undefined],
        ["garbage token", "not-a-jwt"],
      ];
      for (const [name, token] of cases) {
        const res = await getCommandOutcome(
          token === undefined ? "" : token,
          commandId,
          token === undefined ? { authorization: "Token abc" } : {},
        );
        expect(res.statusCode, name).toBe(401);
        expect(validateErrorResponse(res.json())).toBe(true);
        expect((res.json() as { error: { code: string } }).error.code).toBe("UNAUTHORIZED");
      }
    });
  });

  describe("question answer outcomes", () => {
    it("records accepted when the command is sent and confirmed after the plugin result", async () => {
      const alice = await createUser("outcome-question@example.com");
      const credential = await createPluginCredential(alice.token);
      const instance = await registerPlugin(credential);
      expect(instance.result.state).toBe("controllable");
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

      // The moment the gateway routed the command, the outcome is `accepted`.
      const accepted = await getCommandOutcome(alice.token, commandId);
      expect(accepted.statusCode).toBe(200);
      const acceptedBody = accepted.json();
      expect(validateCommandOutcome(acceptedBody)).toBe(true);
      expect(acceptedBody).toEqual({
        commandId,
        requestId: "req_1",
        instanceId: instance.instanceId,
        kind: "question",
        status: "accepted",
        updatedAt: new Date(T0).toISOString(),
      });

      instance.ws.send(
        JSON.stringify({
          type: "question_answer_result",
          commandId,
          instanceId: instance.instanceId,
          status: "confirmed",
        }),
      );
      const res = await response;
      expect(res.statusCode).toBe(200);
      expect(validateQuestionCommandResult(res.json())).toBe(true);
      expect(res.json()).toEqual({ commandId, status: "confirmed" });

      // The terminal plugin result advances the outcome to `confirmed`.
      const confirmed = await getCommandOutcome(alice.token, commandId);
      expect(confirmed.statusCode).toBe(200);
      expect(validateCommandOutcome(confirmed.json())).toBe(true);
      expect(confirmed.json()).toEqual({
        commandId,
        requestId: "req_1",
        instanceId: instance.instanceId,
        kind: "question",
        status: "confirmed",
        updatedAt: new Date(T0).toISOString(),
      });
    });
  });

  describe("permission decision outcomes", () => {
    it("records accepted when the command is sent and confirmed after the plugin result", async () => {
      const alice = await createUser("outcome-decision@example.com");
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
      const frame = (await command) as { commandId: string };
      expect(frame.commandId).toBe(commandId);

      const accepted = await getCommandOutcome(alice.token, commandId);
      expect(accepted.statusCode).toBe(200);
      expect(accepted.json()).toEqual({
        commandId,
        requestId: "per_1",
        instanceId: instance.instanceId,
        kind: "permission",
        status: "accepted",
        updatedAt: new Date(T0).toISOString(),
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
      expect(validatePermissionCommandResult(res.json())).toBe(true);
      expect(res.json()).toEqual({ commandId, status: "confirmed" });

      const confirmed = await getCommandOutcome(alice.token, commandId);
      expect(confirmed.statusCode).toBe(200);
      expect(confirmed.json()).toEqual({
        commandId,
        requestId: "per_1",
        instanceId: instance.instanceId,
        kind: "permission",
        status: "confirmed",
        updatedAt: new Date(T0).toISOString(),
      });
    });

    it("reflects every terminal plugin status on the outcome", async () => {
      const alice = await createUser("outcome-statuses@example.com");
      const credential = await createPluginCredential(alice.token);
      const instance = await registerPlugin(credential);
      await seedSnapshot(alice.token, instance.ws, instance.instanceId, [
        permissionInteraction(instance.instanceId, "per_a"),
        permissionInteraction(instance.instanceId, "per_b", {
          sessionId: "ses_b",
          occurredAt: "2026-08-14T09:00:02.000Z",
        }),
        permissionInteraction(instance.instanceId, "per_c", {
          sessionId: "ses_c",
          occurredAt: "2026-08-14T09:00:03.000Z",
        }),
        permissionInteraction(instance.instanceId, "per_d", {
          sessionId: "ses_d",
          occurredAt: "2026-08-14T09:00:04.000Z",
        }),
      ]);

      const statuses = ["confirmed", "stale", "upstream_error", "result_unknown"] as const;
      const requestIds = ["per_a", "per_b", "per_c", "per_d"];
      for (const [index, status] of statuses.entries()) {
        const commandId = randomUUID();
        const command = nextMessage(instance.ws);
        const response = decidePermission(alice.token, instance.instanceId, requestIds[index], {
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
        expect((await response).json()).toEqual({ commandId, status });
        const outcome = await getCommandOutcome(alice.token, commandId);
        expect(outcome.statusCode).toBe(200);
        expect((outcome.json() as { status: string }).status).toBe(status);
      }
    });
  });

  describe("timeout and disconnect", () => {
    it("settles to result_unknown after the answer timeout and exposes it", async () => {
      await startApp({ answerTimeoutMs: SHORT_ANSWER_TIMEOUT_MS });
      const alice = await createUser("outcome-timeout@example.com");
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
      // The Plugin never replies; the command settles as result_unknown.
      expect((await response).json()).toEqual({ commandId, status: "result_unknown" });
      const outcome = await getCommandOutcome(alice.token, commandId);
      expect(outcome.statusCode).toBe(200);
      expect(validateCommandOutcome(outcome.json())).toBe(true);
      expect(outcome.json()).toEqual({
        commandId,
        requestId: "req_1",
        instanceId: instance.instanceId,
        kind: "question",
        status: "result_unknown",
        updatedAt: new Date(T0).toISOString(),
      });
    });

    it("settles to result_unknown when the owning Plugin disconnects mid-command", async () => {
      const alice = await createUser("outcome-disconnect@example.com");
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
      expect((await response).json()).toEqual({ commandId, status: "result_unknown" });
      const outcome = await getCommandOutcome(alice.token, commandId);
      expect(outcome.statusCode).toBe(200);
      expect((outcome.json() as { status: string }).status).toBe("result_unknown");
    });
  });

  describe("ownership and expiry", () => {
    it("answers a uniform 404 for unknown, foreign, and expired command ids", async () => {
      await startApp({ outcomeTtlMs: TINY_OUTCOME_TTL_MS });
      const alice = await createUser("outcome-owner@example.com");
      const bob = await createUser("outcome-bob@example.com");
      const aliceCredential = await createPluginCredential(alice.token);
      const instance = await registerPlugin(aliceCredential);
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
      instance.ws.send(
        JSON.stringify({
          type: "question_answer_result",
          commandId,
          instanceId: instance.instanceId,
          status: "confirmed",
        }),
      );
      expect((await response).json()).toEqual({ commandId, status: "confirmed" });

      // The clock passing the tiny TTL expires the owner's entry. Unknown and
      // foreign ids are 404 regardless of time, so all three answer the same
      // uniform 404 with no hint about who owns the command.
      clock.advance(TINY_OUTCOME_TTL_MS + 1);
      const notFound: { name: string; token: string; id: string }[] = [
        // A command that was never submitted is unknown to everyone.
        { name: "unknown", token: alice.token, id: randomUUID() },
        // A real command id owned by another account is invisible.
        { name: "foreign", token: bob.token, id: commandId },
        // The owner's own entry expires once the fake clock passes the TTL.
        { name: "expired", token: alice.token, id: commandId },
      ];
      for (const c of notFound) {
        const res = await getCommandOutcome(c.token, c.id);
        expect(res.statusCode, c.name).toBe(404);
        expect(validateErrorResponse(res.json())).toBe(true);
        expect((res.json() as { error: { code: string } }).error.code).toBe("NOT_FOUND");
      }
    });

    it("expires the entry when the clock passes the TTL and a fresh command is still visible", async () => {
      await startApp({ outcomeTtlMs: TINY_OUTCOME_TTL_MS });
      const alice = await createUser("outcome-expire@example.com");
      const credential = await createPluginCredential(alice.token);
      const instance = await registerPlugin(credential);
      await seedSnapshot(alice.token, instance.ws, instance.instanceId, [
        questionInteraction(instance.instanceId, "req_a"),
        questionInteraction(instance.instanceId, "req_b", { sessionId: "ses_b" }),
      ]);

      const firstCommandId = randomUUID();
      const firstFrame = nextMessage(instance.ws);
      const firstResponse = answerQuestion(alice.token, instance.instanceId, "req_a", {
        commandId: firstCommandId,
        answers: [["Postgres"]],
      });
      await firstFrame;
      instance.ws.send(
        JSON.stringify({
          type: "question_answer_result",
          commandId: firstCommandId,
          instanceId: instance.instanceId,
          status: "confirmed",
        }),
      );
      expect((await firstResponse).json()).toEqual({
        commandId: firstCommandId,
        status: "confirmed",
      });

      // The clock passing the TTL expires the first entry on the next access.
      clock.advance(TINY_OUTCOME_TTL_MS + 1);
      const expired = await getCommandOutcome(alice.token, firstCommandId);
      expect(expired.statusCode).toBe(404);
      expect((expired.json() as { error: { code: string } }).error.code).toBe("NOT_FOUND");

      // The same clock keeps recording fresh outcomes for later commands.
      const secondCommandId = randomUUID();
      const secondFrame = nextMessage(instance.ws);
      const secondResponse = answerQuestion(alice.token, instance.instanceId, "req_b", {
        commandId: secondCommandId,
        answers: [["Postgres"]],
      });
      await secondFrame;
      const accepted = await getCommandOutcome(alice.token, secondCommandId);
      expect(accepted.statusCode).toBe(200);
      expect((accepted.json() as { status: string }).status).toBe("accepted");
      instance.ws.send(
        JSON.stringify({
          type: "question_answer_result",
          commandId: secondCommandId,
          instanceId: instance.instanceId,
          status: "confirmed",
        }),
      );
      expect((await secondResponse).json()).toEqual({
        commandId: secondCommandId,
        status: "confirmed",
      });
    });
  });

  describe("racing desktop clients", () => {
    it("awards the request to the first confirmed client and leaves the loser's command unrecorded", async () => {
      const alice = await createUser("outcome-race@example.com");
      const secondToken = await login("outcome-race@example.com");
      const credential = await createPluginCredential(alice.token);
      const instance = await registerPlugin(credential);
      await seedSnapshot(alice.token, instance.ws, instance.instanceId, [
        questionInteraction(instance.instanceId),
      ]);

      // Client one issues the command for the pending request.
      const winnerCommandId = randomUUID();
      const winnerFrame = nextMessage(instance.ws);
      const winnerResponse = answerQuestion(alice.token, instance.instanceId, "req_1", {
        commandId: winnerCommandId,
        answers: [["Postgres"]],
      });
      const sentWinner = (await winnerFrame) as { commandId: string };
      expect(sentWinner.commandId).toBe(winnerCommandId);

      // Client two races the same request: refused as an in-flight conflict
      // before any second command reaches the Plugin.
      const loserCommandId = randomUUID();
      const silence = expectSilence(instance.ws);
      const loser = await answerQuestion(secondToken, instance.instanceId, "req_1", {
        commandId: loserCommandId,
        answers: [["sqlite"]],
      });
      await silence;
      expect(loser.statusCode).toBe(409);
      expect((loser.json() as { error: { code: string } }).error.code).toBe("CONFLICT");

      // The loser's command was never sent, so its outcome is unknown (404),
      // and it must not leak the winner's outcome under the loser's commandId.
      const loserOutcome = await getCommandOutcome(alice.token, loserCommandId);
      expect(loserOutcome.statusCode).toBe(404);
      expect((loserOutcome.json() as { error: { code: string } }).error.code).toBe("NOT_FOUND");

      // The winner's command was sent: the winner can query `accepted` even
      // while the loser was refused.
      const winnerInFlight = await getCommandOutcome(alice.token, winnerCommandId);
      expect(winnerInFlight.statusCode).toBe(200);
      expect((winnerInFlight.json() as { status: string }).status).toBe("accepted");

      instance.ws.send(
        JSON.stringify({
          type: "question_answer_result",
          commandId: winnerCommandId,
          instanceId: instance.instanceId,
          status: "confirmed",
        }),
      );
      expect((await winnerResponse).json()).toEqual({
        commandId: winnerCommandId,
        status: "confirmed",
      });

      // The winner's outcome is now terminal for both desktop clients.
      const winnerOutcome = await getCommandOutcome(secondToken, winnerCommandId);
      expect(winnerOutcome.statusCode).toBe(200);
      expect((winnerOutcome.json() as { status: string }).status).toBe("confirmed");
    });
  });

  describe("replay and cache hardening", () => {
    it("keeps a settled confirmed outcome when the same commandId replays on a different connection", async () => {
      const alice = await createUser("outcome-replay@example.com");
      const credential = await createPluginCredential(alice.token);
      const first = await registerPlugin(credential, { directory: "/work/one" });
      const second = await registerPlugin(credential, { directory: "/work/two" });
      expect(first.result.state).toBe("controllable");
      expect(second.result.state).toBe("controllable");
      await seedSnapshot(alice.token, first.ws, first.instanceId, [
        questionInteraction(first.instanceId, "req_one"),
      ]);
      await seedSnapshot(alice.token, second.ws, second.instanceId, [
        questionInteraction(second.instanceId, "req_two", { sessionId: "ses_two" }),
      ]);

      const commandId = randomUUID();

      // First connection: the command is sent and confirmed.
      const firstFrame = nextMessage(first.ws);
      const firstResponse = answerQuestion(alice.token, first.instanceId, "req_one", {
        commandId,
        answers: [["Postgres"]],
      });
      expect(((await firstFrame) as { commandId: string }).commandId).toBe(commandId);
      first.ws.send(
        JSON.stringify({
          type: "question_answer_result",
          commandId,
          instanceId: first.instanceId,
          status: "confirmed",
        }),
      );
      expect((await firstResponse).json()).toEqual({ commandId, status: "confirmed" });

      // Second connection replays the same commandId for a different request:
      // the gateway routes it (the per-connection in-flight gates do not
      // collide), but the recorded outcome must not be clobbered by the replay.
      const replayFrame = nextMessage(second.ws);
      const replayResponse = answerQuestion(alice.token, second.instanceId, "req_two", {
        commandId,
        answers: [["sqlite"]],
      });
      expect(((await replayFrame) as { commandId: string }).commandId).toBe(commandId);

      const outcome = await getCommandOutcome(alice.token, commandId);
      expect(outcome.statusCode).toBe(200);
      expect(validateCommandOutcome(outcome.json())).toBe(true);
      expect(outcome.json()).toEqual({
        commandId,
        requestId: "req_one",
        instanceId: first.instanceId,
        kind: "question",
        status: "confirmed",
        updatedAt: new Date(T0).toISOString(),
      });

      // The replay settles on its own connection without disturbing the first
      // confirmed outcome.
      second.ws.send(
        JSON.stringify({
          type: "question_answer_result",
          commandId,
          instanceId: second.instanceId,
          status: "confirmed",
        }),
      );
      await replayResponse;
      const afterReplay = await getCommandOutcome(alice.token, commandId);
      expect(afterReplay.statusCode).toBe(200);
      expect(afterReplay.json()).toEqual({
        commandId,
        requestId: "req_one",
        instanceId: first.instanceId,
        kind: "question",
        status: "confirmed",
        updatedAt: new Date(T0).toISOString(),
      });
    });

    it("evicts the oldest outcome once the cache exceeds the cap, independent of the TTL", async () => {
      await startApp({ maxCommandOutcomes: 3 });
      const alice = await createUser("outcome-cap@example.com");
      const credential = await createPluginCredential(alice.token);
      const instance = await registerPlugin(credential);
      await seedSnapshot(alice.token, instance.ws, instance.instanceId, [
        questionInteraction(instance.instanceId, "req_a"),
        questionInteraction(instance.instanceId, "req_b", { sessionId: "ses_b" }),
        questionInteraction(instance.instanceId, "req_c", { sessionId: "ses_c" }),
        questionInteraction(instance.instanceId, "req_d", { sessionId: "ses_d" }),
      ]);

      const commandIds = [randomUUID(), randomUUID(), randomUUID(), randomUUID()];
      const requestIds = ["req_a", "req_b", "req_c", "req_d"];
      for (let i = 0; i < 4; i++) {
        const frame = nextMessage(instance.ws);
        const response = answerQuestion(alice.token, instance.instanceId, requestIds[i], {
          commandId: commandIds[i],
          answers: [["Postgres"]],
        });
        expect(((await frame) as { commandId: string }).commandId).toBe(commandIds[i]);
        instance.ws.send(
          JSON.stringify({
            type: "question_answer_result",
            commandId: commandIds[i],
            instanceId: instance.instanceId,
            status: "confirmed",
          }),
        );
        expect((await response).json()).toEqual({ commandId: commandIds[i], status: "confirmed" });
      }

      // The fake clock advancing under the TTL is irrelevant: the oldest
      // (first-recorded) outcome was dropped purely by the size cap.
      clock.advance(1_000);

      const evicted = await getCommandOutcome(alice.token, commandIds[0]);
      expect(evicted.statusCode).toBe(404);
      expect((evicted.json() as { error: { code: string } }).error.code).toBe("NOT_FOUND");

      for (const commandId of commandIds.slice(1)) {
        const res = await getCommandOutcome(alice.token, commandId);
        expect(res.statusCode).toBe(200);
        expect((res.json() as { status: string }).status).toBe("confirmed");
      }
    });
  });

  describe("no interaction bodies in cache or logs", () => {
    it("never puts answers or decisions in the outcome cache or the logs", async () => {
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
      // Probe that logs a command body the way the real routes' bodies would
      // be logged; the central redaction must censor the answers/decision
      // paths.
      app.post("/_probe-commands", async (request) => {
        request.log.info({ body: request.body }, "probe commands");
        return { status: "ok" };
      });
      await app.listen({ host: "127.0.0.1", port: 0 });
      const address = app.server.address();
      if (address === null || typeof address === "string") {
        throw new Error("expected an ephemeral TCP port");
      }
      port = address.port;

      const alice = await createUser("outcome-sentinel@example.com");
      const credential = await createPluginCredential(alice.token);
      const instance = await registerPlugin(credential);
      await seedSnapshot(alice.token, instance.ws, instance.instanceId, [
        questionInteraction(instance.instanceId, "req_sentinel"),
        permissionInteraction(instance.instanceId, "per_sentinel"),
      ]);

      const answerSentinel = "SENTINEL-ANSWER-1a2b3c4d";
      const decisionSentinel = "SENTINEL-DECISION-5e6f7a8b";
      const answerCommandId = randomUUID();
      const decisionCommandId = randomUUID();

      // Relay a sentinel answer and a sentinel decision through the real
      // routes; the content only ever travels on the control channel.
      const answerFrame = nextMessage(instance.ws);
      const answerResponse = answerQuestion(alice.token, instance.instanceId, "req_sentinel", {
        commandId: answerCommandId,
        answers: [[answerSentinel]],
      });
      const sentAnswer = (await answerFrame) as { answers: string[][] };
      expect(sentAnswer.answers).toEqual([[answerSentinel]]);

      const decisionFrame = nextMessage(instance.ws);
      const decisionResponse = decidePermission(alice.token, instance.instanceId, "per_sentinel", {
        commandId: decisionCommandId,
        decision: "once",
      });
      const sentDecision = (await decisionFrame) as { decision: string };
      expect(sentDecision.decision).toBe("once");

      instance.ws.send(
        JSON.stringify({
          type: "question_answer_result",
          commandId: answerCommandId,
          instanceId: instance.instanceId,
          status: "confirmed",
        }),
      );
      instance.ws.send(
        JSON.stringify({
          type: "permission_decide_result",
          commandId: decisionCommandId,
          instanceId: instance.instanceId,
          status: "confirmed",
        }),
      );
      expect((await answerResponse).json()).toEqual({
        commandId: answerCommandId,
        status: "confirmed",
      });
      expect((await decisionResponse).json()).toEqual({
        commandId: decisionCommandId,
        status: "confirmed",
      });

      // The outcome endpoint is body-free by construction: no answers, no
      // decisions, and none of the sentinel content anywhere in the response.
      const answerOutcome = await getCommandOutcome(alice.token, answerCommandId);
      expect(answerOutcome.statusCode).toBe(200);
      const answerBody = answerOutcome.json();
      expect(validateCommandOutcome(answerBody)).toBe(true);
      expect(JSON.stringify(answerBody)).not.toContain(answerSentinel);
      expect(JSON.stringify(answerBody)).not.toContain("answers");

      const decisionOutcome = await getCommandOutcome(alice.token, decisionCommandId);
      expect(decisionOutcome.statusCode).toBe(200);
      const decisionBody = decisionOutcome.json();
      expect(validateCommandOutcome(decisionBody)).toBe(true);
      expect(JSON.stringify(decisionBody)).not.toContain(decisionSentinel);
      expect(JSON.stringify(decisionBody)).not.toContain("decision");

      // Log a command body directly: the answer and decision paths must be
      // redacted, and no sentinel content may reach the logs.
      const probe = await app.inject({
        method: "POST",
        url: "/_probe-commands",
        payload: {
          commandId: randomUUID(),
          answers: [[answerSentinel]],
          decision: decisionSentinel,
        },
      });
      expect(probe.statusCode).toBe(200);

      const logged = output();
      expect(logged).toContain("probe commands");
      expect(logged).not.toContain(answerSentinel);
      expect(logged).not.toContain(decisionSentinel);

      // No persistence: no table holds interactions, answers, decisions, or
      // outcomes.
      const tables = (await handle.db.execute<{ tablename: string }>(
        sql`select tablename from pg_tables where schemaname = 'public'`,
      )) as { tablename: string }[];
      const names = tables.map((row) => row.tablename);
      expect(names).not.toContain("pending_interactions");
      expect(names).not.toContain("interactions");
      expect(names).not.toContain("answers");
      expect(names).not.toContain("permission_decisions");
      expect(names).not.toContain("decisions");
      expect(names).not.toContain("command_outcomes");
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
