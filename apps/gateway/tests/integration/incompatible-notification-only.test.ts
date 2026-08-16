import { createHmac, randomUUID } from "node:crypto";

import { validateErrorResponse } from "@notify/contracts";
import { sql } from "drizzle-orm";
import type { FastifyInstance } from "fastify";
import { afterAll, afterEach, beforeAll, beforeEach, describe, expect, it } from "vitest";
import { WebSocket } from "ws";

import { buildServer } from "../../src/app.js";
import { createDb, type GatewayDatabase } from "../../src/db/client.js";
import type { Clock } from "../../src/lib/clock.js";
import type { Mailer } from "../../src/modules/mail/mailer.js";
import {
  buildTestConfig,
  noopFcmSender,
} from "../helpers/build-test-app.js";
import { TestPostgres } from "../helpers/postgres.js";

const PASSWORD = "correct horse battery staple";

/** Fixed "now" for the fake clock: deterministic snapshot timestamps. */
const T0 = 1_800_000_000_000;

/** Fast heartbeat so control sockets stay alive in milliseconds. */
const TEST_PING_INTERVAL_MS = 60;

/** Unique sentinel notification content; an appearance anywhere except the
 * desktop delivery frame is a leak. */
const NOTIFICATION_QUESTION = "SENTINEL-INCOMPATIBLE-QUESTION-9f8e7d6c";

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

describe("incompatible-version notification-only behavior (AC4)", () => {
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

  async function startApp(): Promise<void> {
    app = await buildServer({
      config: buildTestConfig({ databaseUrl: pg.databaseUrl }),
      db: handle.db,
      mailer,
      clock,
      realtime: { pingIntervalMs: TEST_PING_INTERVAL_MS },
      fcmSender: noopFcmSender,
    });
    await app.listen({ host: "127.0.0.1", port: 0 });
    const address = app.server.address();
    if (address === null || typeof address === "string") {
      throw new Error("expected an ephemeral TCP port");
    }
    port = address.port;
  }

  /** Register, verify, log in; returns the access token. */
  async function createUser(email: string): Promise<string> {
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
    return login.json().accessToken as string;
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

  function connectDesktop(token: string): Promise<WebSocket> {
    return new Promise((resolve, reject) => {
      const ws = new WebSocket(`ws://127.0.0.1:${port}/v1/ws`, {
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
   * Register a Plugin instance with an unsupported OpenCode version and
   * return the socket, instanceId, and registration result.
   */
  async function registerIncompatiblePlugin(
    credential: string,
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
        openCodeVersion: "1.18.17",
        protocolVersion: 1,
      }),
    );
    const result = (await resultPromise) as { type: string; instanceId: string; state: string };
    expect(result.type).toBe("registration");
    expect(result.instanceId).toBe(instanceId);
    expect(result.state).toBe("incompatible");
    return { ws, instanceId, result };
  }

  function getPendingInteractions(token: string) {
    return app.inject({
      method: "GET",
      url: "/v1/pending-interactions",
      headers: { authorization: `Bearer ${token}` },
    });
  }

  function answerQuestion(
    token: string,
    instanceId: string,
    requestId: string,
    body: Record<string, unknown>,
  ) {
    return app.inject({
      method: "POST",
      url: `/v1/pending-interactions/${instanceId}/questions/${requestId}/answer`,
      headers: { authorization: `Bearer ${token}`, "content-type": "application/json" },
      payload: { sessionId: "ses_1", ...body },
    });
  }

  function decidePermission(
    token: string,
    instanceId: string,
    requestId: string,
    body: Record<string, unknown>,
  ) {
    return app.inject({
      method: "POST",
      url: `/v1/pending-interactions/${instanceId}/permissions/${requestId}/decision`,
      headers: { authorization: `Bearer ${token}`, "content-type": "application/json" },
      payload: { sessionId: "ses_2", ...body },
    });
  }

  function getCommandOutcome(token: string, commandId: string) {
    return app.inject({
      method: "GET",
      url: `/v1/pending-interactions/commands/${commandId}`,
      headers: { authorization: `Bearer ${token}` },
    });
  }

  /** POST a signed action_required question event; returns the response. */
  async function postQuestionEvent(credential: string): Promise<number> {
    const body = JSON.stringify({
      eventId: randomUUID(),
      type: "action_required",
      occurredAt: "2026-08-10T12:00:00.000Z",
      source: { machine: "workstation", project: "notify", directory: "/repo" },
      session: { id: "session-1", title: "Coding" },
      payload: {
        requestId: "req-1",
        kind: "question",
        questions: [{ question: NOTIFICATION_QUESTION }],
      },
    });
    const timestamp = String(clock.nowMs());
    const secret = credential.slice(credential.indexOf(".") + 1);
    const signature = createHmac("sha256", secret)
      .update(`${timestamp}.${body}`)
      .digest("hex");
    const res = await app.inject({
      method: "POST",
      url: "/v1/events",
      headers: {
        "content-type": "application/json",
        authorization: `Bearer ${credential}`,
        "x-notify-timestamp": timestamp,
        "x-notify-signature": signature,
      },
      payload: body,
    });
    return res.statusCode;
  }

  it("registers an unsupported version as incompatible, still delivers notifications, and excludes the instance from pending collection and commands with silence", async () => {
    const token = await createUser("incompatible@example.com");
    const credential = await createPluginCredential(token);
    const desktop = await connectDesktop(token);
    const instance = await registerIncompatiblePlugin(credential);

    // A clear compatibility state is published to the desktop: the instance
    // is present but explicitly not controllable.
    const presence = await nextMessage(desktop);
    expect(presence.type).toBe("instance_presence");
    const presenceInstances = presence.instances as {
      instanceId: string;
      state: string;
      openCodeVersion: string;
    }[];
    expect(presenceInstances).toHaveLength(1);
    expect(presenceInstances[0]).toMatchObject({
      instanceId: instance.instanceId,
      state: "incompatible",
      openCodeVersion: "1.18.17",
    });

    // Notification ingest and delivery keep working end to end.
    const eventDelivery = nextMessage(desktop);
    expect(await postQuestionEvent(credential)).toBe(202);
    const message = (await eventDelivery) as {
      type: string;
      event: { payload: { questions: { question: string }[] } };
    };
    expect(message.type).toBe("event");
    expect(message.event.payload.questions[0].question).toBe(NOTIFICATION_QUESTION);

    // The incompatible instance is excluded from pending collection: no
    // snapshot request is issued to its socket and the snapshot is empty.
    const snapshotSilence = expectSilence(instance.ws);
    const snapshot = await getPendingInteractions(token);
    await snapshotSilence;
    expect(snapshot.statusCode).toBe(200);
    expect(snapshot.json()).toEqual({
      generatedAt: new Date(T0).toISOString(),
      interactions: [],
      queriedInstanceIds: [],
    });

    // Question answers and permission decisions targeting the incompatible
    // instance are refused with silence on its socket.
    const answerSilence = expectSilence(instance.ws);
    const answer = await answerQuestion(token, instance.instanceId, "req_1", {
      commandId: randomUUID(),
      answers: [["Postgres"]],
    });
    await answerSilence;
    expect(answer.statusCode).toBe(404);
    expect(validateErrorResponse(answer.json())).toBe(true);
    expect((answer.json() as { error: { code: string } }).error.code).toBe("NOT_FOUND");

    const decisionSilence = expectSilence(instance.ws);
    const decision = await decidePermission(token, instance.instanceId, "per_1", {
      commandId: randomUUID(),
      decision: "once",
    });
    await decisionSilence;
    expect(decision.statusCode).toBe(404);
    expect(validateErrorResponse(decision.json())).toBe(true);
    expect((decision.json() as { error: { code: string } }).error.code).toBe("NOT_FOUND");

    // No command was ever routed, so no command outcome exists for it.
    const outcome = await getCommandOutcome(token, randomUUID());
    expect(outcome.statusCode).toBe(404);
    expect((outcome.json() as { error: { code: string } }).error.code).toBe("NOT_FOUND");

    // The socket stays open and the instance remains reachable: a second
    // snapshot is still answered with silence rather than a connection error.
    await expectSilence(instance.ws);
    expect(instance.ws.readyState).toBe(WebSocket.OPEN);
  });
});
