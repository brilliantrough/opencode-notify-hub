import { createHmac, randomUUID } from "node:crypto";
import { Writable } from "node:stream";

import {
  validateErrorResponse,
  validatePendingInteraction,
  validatePendingSnapshot,
  validatePluginControlServerMessage,
} from "@notify/contracts";
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

/** Short per-instance wait for the partial-timeout scenario. */
const SHORT_SNAPSHOT_TIMEOUT_MS = 200;

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

function heartbeatEvent(eventId: string): Record<string, unknown> {
  return {
    eventId,
    type: "heartbeat",
    occurredAt: "2026-08-10T12:00:00.000Z",
    source: { machine: "workstation", project: "notify", directory: "/repo" },
    session: { id: "session-1", title: "Coding" },
    payload: { status: "busy", elapsedSeconds: 12 },
  };
}

describe("pending interactions", () => {
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

  async function startApp(overrides: { snapshotTimeoutMs?: number } = {}): Promise<void> {
    if (app !== undefined) {
      await app.close();
    }
    app = await buildServer({
      config: buildTestConfig({ databaseUrl: pg.databaseUrl }),
      db: handle.db,
      mailer,
      clock,
      realtime: { pingIntervalMs: TEST_PING_INTERVAL_MS },
      control: overrides.snapshotTimeoutMs !== undefined ? overrides : undefined,
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
    expect(validatePluginControlServerMessage(result)).toBe(true);
    expect(result.instanceId).toBe(instanceId);
    return { ws, instanceId, result };
  }

  /**
   * Await the gateway's pending_snapshot_request on a Plugin socket and reply
   * with the given interactions. Returns once the request is seen and the
   * response is on the wire.
   */
  async function answerSnapshot(
    ws: WebSocket,
    instanceId: string,
    interactions: Record<string, unknown>[],
  ): Promise<void> {
    const request = await nextMessage(ws);
    expect(request.type).toBe("pending_snapshot_request");
    const requestId = request.requestId as string;
    expect(requestId).toMatch(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/);
    ws.send(
      JSON.stringify({
        type: "pending_snapshot_response",
        requestId,
        instanceId,
        interactions,
      }),
    );
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

  /** POST a signed heartbeat event through the real ingest route. */
  async function postEvent(credential: string, eventId: string): Promise<number> {
    const body = JSON.stringify(heartbeatEvent(eventId));
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
    expect(res.statusCode).toBe(202);
    return res.statusCode;
  }

  describe("authentication", () => {
    it("rejects unauthenticated and malformed tokens with 401 UNAUTHORIZED", async () => {
      const cases: [string, string | null | undefined][] = [
        ["missing token", null],
        ["wrong scheme", undefined],
        ["garbage token", "not-a-jwt"],
      ];
      for (const [name, token] of cases) {
        const res = await getPendingInteractions(
          token === undefined ? "" : token,
          token === undefined ? { authorization: "Token abc" } : {},
        );
        expect(res.statusCode, name).toBe(401);
        expect(validateErrorResponse(res.json())).toBe(true);
        expect((res.json() as { error: { code: string } }).error.code).toBe("UNAUTHORIZED");
      }
    });
  });

  describe("aggregation", () => {
    it("collects complete pending interactions from every connected controllable instance and enriches source from registration", async () => {
      const alice = await createUser("agg@example.com");
      const credential = await createPluginCredential(alice.token);
      const first = await registerPlugin(credential, {
        project: "api",
        directory: "/work/api",
      });
      const second = await registerPlugin(credential, {
        project: "web",
        directory: "/work/web",
      });
      expect(first.result.state).toBe("controllable");
      expect(second.result.state).toBe("controllable");

      const firstRequest = nextMessage(first.ws);
      const secondRequest = nextMessage(second.ws);
      const response = getPendingInteractions(alice.token);
      const [firstMsg, secondMsg] = await Promise.all([firstRequest, secondRequest]);
      first.ws.send(
        JSON.stringify({
          type: "pending_snapshot_response",
          requestId: firstMsg.requestId,
          instanceId: first.instanceId,
          interactions: [questionInteraction(first.instanceId)],
        }),
      );
      second.ws.send(
        JSON.stringify({
          type: "pending_snapshot_response",
          requestId: secondMsg.requestId,
          instanceId: second.instanceId,
          interactions: [
            questionInteraction(second.instanceId, "req_2"),
            permissionInteraction(second.instanceId),
          ],
        }),
      );

      const res = await response;
      expect(res.statusCode).toBe(200);
      const body = res.json();
      expect(validatePendingSnapshot(body)).toBe(true);
      const interactions = body.interactions as Record<string, unknown>[];
      expect(interactions).toHaveLength(3);

      const firstInteraction = interactions.find(
        (interaction) => interaction.instanceId === first.instanceId,
      );
      expect(firstInteraction).toBeDefined();
      expect(firstInteraction).toMatchObject({
        instanceId: first.instanceId,
        machine: "devbox",
        project: "api",
        directory: "/work/api",
        kind: "question",
      });
      const secondQuestion = interactions.find(
        (interaction) =>
          interaction.instanceId === second.instanceId && interaction.kind === "question",
      );
      expect(secondQuestion).toBeDefined();
      expect(secondQuestion).toMatchObject({
        instanceId: second.instanceId,
        machine: "devbox",
        project: "web",
        directory: "/work/web",
        kind: "question",
      });
      const secondPermission = interactions.find(
        (interaction) => interaction.kind === "permission",
      );
      expect(secondPermission).toBeDefined();
      expect(secondPermission).toMatchObject({
        instanceId: second.instanceId,
        project: "web",
        directory: "/work/web",
        permission: "bash",
        patterns: ["rm -rf build/"],
        always: ["printf *"],
        metadata: { source: "interactive" },
      });
      expect(validatePendingInteraction(firstInteraction as Record<string, unknown>)).toBe(true);
    });

    it("returns an empty snapshot when the user has no instances", async () => {
      const alice = await createUser("empty@example.com");
      const res = await getPendingInteractions(alice.token);
      expect(res.statusCode).toBe(200);
      expect(validatePendingSnapshot(res.json())).toBe(true);
      expect(res.json()).toEqual({
        generatedAt: new Date(T0).toISOString(),
        interactions: [],
      });
    });

    it("never queries or reveals another account's instances", async () => {
      const alice = await createUser("alice@example.com");
      const bob = await createUser("bob@example.com");
      const aliceCredential = await createPluginCredential(alice.token);
      const aliceInstance = await registerPlugin(aliceCredential, {
        project: "api",
        directory: "/work/api",
      });

      // Bob's empty snapshot must settle without touching Alice's instance.
      const bobRes = await getPendingInteractions(bob.token);
      expect(bobRes.statusCode).toBe(200);
      expect(bobRes.json()).toEqual({
        generatedAt: new Date(T0).toISOString(),
        interactions: [],
      });

      // Only Alice's own request queries her instance.
      const aliceRequest = nextMessage(aliceInstance.ws);
      const aliceResponse = getPendingInteractions(alice.token);
      const aliceMsg = (await aliceRequest) as { requestId: string };
      aliceInstance.ws.send(
        JSON.stringify({
          type: "pending_snapshot_response",
          requestId: aliceMsg.requestId,
          instanceId: aliceInstance.instanceId,
          interactions: [questionInteraction(aliceInstance.instanceId)],
        }),
      );
      const aliceRes = await aliceResponse;
      expect(aliceRes.statusCode).toBe(200);
      expect(aliceRes.json().interactions).toHaveLength(1);
      expect(aliceRes.json().interactions[0].instanceId).toBe(aliceInstance.instanceId);

      // Bob is never granted sight of Alice's interactions.
      const bobAgain = await getPendingInteractions(bob.token);
      expect(bobAgain.json().interactions).toHaveLength(0);
    });
  });

  describe("exclusion", () => {
    it("queries only controllable instances, skipping conflicting, incompatible, and offline ones", async () => {
      const alice = await createUser("exclude@example.com");
      const credential = await createPluginCredential(alice.token);

      // Controllable owner of devbox:/work/notify.
      const owner = await registerPlugin(credential);
      expect(owner.result.state).toBe("controllable");

      // Same machine + directory under a different instance: conflicting.
      const conflict = await registerPlugin(credential, {
        project: "notify-copy",
        directory: "/work/notify/",
      });
      expect(conflict.result.state).toBe("conflicting");

      // Unsupported OpenCode version: incompatible.
      const incompatible = await registerPlugin(credential, {
        openCodeVersion: "1.18.17",
      });
      expect(incompatible.result.state).toBe("incompatible");

      // Registered then disconnected: offline.
      const offline = await registerPlugin(credential, {
        project: "gone",
        directory: "/work/gone",
      });
      expect(offline.result.state).toBe("controllable");
      offline.ws.close();
      await new Promise((resolve) => setTimeout(resolve, 20));

      const ownerRequest = nextMessage(owner.ws);
      const response = getPendingInteractions(alice.token);

      // Conflicting and incompatible sockets must not be queried at all.
      const conflictSilence = expectSilence(conflict.ws);
      const incompatibleSilence = expectSilence(incompatible.ws);

      const ownerMsg = await ownerRequest;
      owner.ws.send(
        JSON.stringify({
          type: "pending_snapshot_response",
          requestId: ownerMsg.requestId,
          instanceId: owner.instanceId,
          interactions: [questionInteraction(owner.instanceId)],
        }),
      );

      const res = await response;
      await Promise.all([conflictSilence, incompatibleSilence]);
      expect(res.statusCode).toBe(200);
      const interactions = res.json().interactions as Record<string, unknown>[];
      expect(interactions).toHaveLength(1);
      expect(interactions[0].instanceId).toBe(owner.instanceId);
      expect(interactions[0]).toMatchObject({
        machine: "devbox",
        project: "notify",
        directory: "/work/notify",
      });
    });
  });

  describe("partial timeout", () => {
    it("returns a partial 200 snapshot when an instance never answers", async () => {
      await startApp({ snapshotTimeoutMs: SHORT_SNAPSHOT_TIMEOUT_MS });
      const alice = await createUser("timeout@example.com");
      const credential = await createPluginCredential(alice.token);
      const responder = await registerPlugin(credential, {
        project: "api",
        directory: "/work/api",
      });
      const silent = await registerPlugin(credential, {
        project: "web",
        directory: "/work/web",
      });

      const responderRequest = nextMessage(responder.ws);
      const silentRequest = nextMessage(silent.ws);
      const response = getPendingInteractions(alice.token);
      const [responderMsg, silentMsg] = await Promise.all([responderRequest, silentRequest]);
      responder.ws.send(
        JSON.stringify({
          type: "pending_snapshot_response",
          requestId: responderMsg.requestId,
          instanceId: responder.instanceId,
          interactions: [questionInteraction(responder.instanceId)],
        }),
      );
      // The silent socket simply never answers; its request goes unanswered.

      const res = await response;
      expect(res.statusCode).toBe(200);
      const body = res.json();
      expect(validatePendingSnapshot(body)).toBe(true);
      expect(body.interactions).toHaveLength(1);
      expect(body.interactions[0].instanceId).toBe(responder.instanceId);
      // The silent instance's requestId was issued but never resolved.
      expect(silentMsg.requestId).toBeDefined();
    });

    it("ignores late responses after their timeout has settled", async () => {
      await startApp({ snapshotTimeoutMs: SHORT_SNAPSHOT_TIMEOUT_MS });
      const alice = await createUser("late@example.com");
      const credential = await createPluginCredential(alice.token);
      const silent = await registerPlugin(credential, {
        project: "web",
        directory: "/work/web",
      });

      const request = nextMessage(silent.ws);
      const response = getPendingInteractions(alice.token);
      const requestMsg = (await request) as { requestId: string };
      const res = await response;
      expect(res.json().interactions).toHaveLength(0);

      // A late answer for the now-settled request must be ignored silently and
      // must not disturb the connection.
      silent.ws.send(
        JSON.stringify({
          type: "pending_snapshot_response",
          requestId: requestMsg.requestId,
          instanceId: silent.instanceId,
          interactions: [questionInteraction(silent.instanceId)],
        }),
      );
      await expectSilence(silent.ws);
      expect(silent.ws.readyState).toBe(WebSocket.OPEN);
    });
  });

  describe("provider notification regression", () => {
    it("keeps provider actions ordinary notifications and out of the pending snapshot", async () => {
      const alice = await createUser("provider@example.com");
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

      // A subsequent snapshot request returns only question/permission
      // interactions relayed by the Plugin; provider actions never appear.
      const request = nextMessage(instance.ws);
      const response = getPendingInteractions(alice.token);
      const requestMsg = (await request) as { requestId: string };
      instance.ws.send(
        JSON.stringify({
          type: "pending_snapshot_response",
          requestId: requestMsg.requestId,
          instanceId: instance.instanceId,
          interactions: [questionInteraction(instance.instanceId)],
        }),
      );
      const res = await response;
      expect(res.statusCode).toBe(200);
      expect(res.json().interactions).toHaveLength(1);
      expect(res.json().interactions[0].kind).toBe("question");
      expect(JSON.stringify(res.json())).not.toContain("provider_action");
      expect(JSON.stringify(res.json())).not.toContain("Sign-in required");

      // Ordinary notification delivery still works end to end.
      await postEvent(credential, randomUUID());
    });
  });

  describe("no persistence and log leakage", () => {
    it("writes nothing to the database and never logs interaction content", async () => {
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
      await app.listen({ host: "127.0.0.1", port: 0 });
      const address = app.server.address();
      if (address === null || typeof address === "string") {
        throw new Error("expected an ephemeral TCP port");
      }
      port = address.port;

      const alice = await createUser("leak@example.com");
      const credential = await createPluginCredential(alice.token);
      const instance = await registerPlugin(credential);

      const sentinelQuestion = "SENTINEL-QUES-6c5b4a39";
      const sentinelPermission = "SENTINEL-PERM-5b4a3928";
      const request = nextMessage(instance.ws);
      const response = getPendingInteractions(alice.token);
      const requestMsg = (await request) as { requestId: string };
      instance.ws.send(
        JSON.stringify({
          type: "pending_snapshot_response",
          requestId: requestMsg.requestId,
          instanceId: instance.instanceId,
          interactions: [
            questionInteraction(instance.instanceId, "req_sentinel", {
              questions: [
                {
                  header: "h",
                  question: sentinelQuestion,
                  options: [],
                  multiple: false,
                  custom: true,
                },
              ],
            }),
            permissionInteraction(instance.instanceId, "per_sentinel", {
              permission: sentinelPermission,
            }),
          ],
        }),
      );

      const res = await response;
      expect(res.statusCode).toBe(200);
      expect(JSON.stringify(res.json())).toContain(sentinelQuestion);
      expect(JSON.stringify(res.json())).toContain(sentinelPermission);

      // The snapshot travelled through memory only: no interaction content
      // reached the logs and no interactions table exists.
      const logged = output();
      expect(logged).not.toContain(sentinelQuestion);
      expect(logged).not.toContain(sentinelPermission);
      const tables = (await handle.db.execute<{ tablename: string }>(
        sql`select tablename from pg_tables where schemaname = 'public'`,
      )) as { tablename: string }[];
      const names = tables.map((row) => row.tablename);
      expect(names).not.toContain("pending_interactions");
      expect(names).not.toContain("interactions");
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
