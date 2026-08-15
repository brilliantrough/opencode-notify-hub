import { createHmac, randomUUID } from "node:crypto";
import { Writable } from "node:stream";

import {
  validateErrorResponse,
  validatePendingSnapshot,
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

/**
 * Issue #14 AC1/AC2: unique sentinel values that exist only inside the
 * interaction bodies, control frames, and event payloads the sweep relays.
 * Any appearance in captured pino logs is a redaction failure, and none can
 * collide with real log content (paths, hostnames, frame types, UUIDs).
 */
const SENTINELS = {
  question: "SENTINEL-SWEEP-QUESTION-a1b2c3d4",
  option: "SENTINEL-SWEEP-OPTION-e5f6a7b8",
  permission: "SENTINEL-SWEEP-PERMISSION-c9d0e1f2",
  pattern: "SENTINEL-SWEEP-PATTERN-a3b4c5d6",
  always: "SENTINEL-SWEEP-ALWAYS-e7f8a9b0",
  metadata: "SENTINEL-SWEEP-META-c1d2e3f4",
  answer: "SENTINEL-SWEEP-ANSWER-a5b6c7d8",
  machine: "SENTINEL-SWEEP-MACHINE-e9f0a1b2",
  project: "SENTINEL-SWEEP-PROJECT-c3d4e5f6",
  directory: "/SENTINEL-SWEEP-DIRECTORY-a7b8c9d0",
  garbage: "SENTINEL-SWEEP-GARBAGE-1d2e3f4a",
  eventQuestion: "SENTINEL-SWEEP-EVENT-QUESTION-5b6c7d8e",
};

/** The seven account tables of specification section 12: the exact public allowlist. */
const PUBLIC_TABLE_ALLOWLIST = [
  "devices",
  "email_verification_tokens",
  "ingest_keys",
  "password_reset_tokens",
  "refresh_token_families",
  "refresh_tokens",
  "users",
];

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

describe("Issue #14 consolidated privacy sweep (AC1 and AC2)", () => {
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
  });

  afterEach(async () => {
    for (const client of clients.splice(0)) {
      if (client.readyState === WebSocket.OPEN || client.readyState === WebSocket.CONNECTING) {
        client.terminate();
      }
    }
    await app.close();
  });

  async function startApp(overrides: { loggerStream?: Writable } = {}): Promise<void> {
    if (app !== undefined) {
      await app.close();
    }
    app = await buildServer({
      config: buildTestConfig({ databaseUrl: pg.databaseUrl, logLevel: "info" }),
      ...(overrides.loggerStream !== undefined ? { loggerStream: overrides.loggerStream } : {}),
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

  /** Create a separate ingest key, returning its id and credential. */
  async function createPluginKey(token: string): Promise<{ id: string; credential: string }> {
    const created = await app.inject({
      method: "POST",
      url: "/v1/ingest-keys",
      headers: { authorization: `Bearer ${token}` },
      payload: { name: "control-second" },
    });
    expect(created.statusCode).toBe(201);
    const body = created.json() as { id: string; secret: string };
    return { id: body.id, credential: body.secret };
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

  function nextClose(ws: WebSocket, timeoutMs = 5_000): Promise<number> {
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => reject(new Error("timed out waiting for close")), timeoutMs);
      ws.once("close", (code: number) => {
        clearTimeout(timer);
        resolve(code);
      });
    });
  }

  /**
   * Register a Plugin instance and await the registration result. Returns the
   * socket, instanceId, and registration state.
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
        machine: SENTINELS.machine,
        project: SENTINELS.project,
        directory: SENTINELS.directory,
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
   * Await the gateway's pending_snapshot_request on a Plugin socket and reply
   * with the given interactions.
   */
  async function answerSnapshot(
    ws: WebSocket,
    instanceId: string,
    interactions: Record<string, unknown>[],
  ): Promise<void> {
    const request = await nextMessage(ws);
    expect(request.type).toBe("pending_snapshot_request");
    ws.send(
      JSON.stringify({
        type: "pending_snapshot_response",
        requestId: request.requestId as string,
        instanceId,
        interactions,
      }),
    );
  }

  function getPendingInteractions(token: string | null) {
    return app.inject({
      method: "GET",
      url: "/v1/pending-interactions",
      headers: token === null ? {} : { authorization: `Bearer ${token}` },
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
      payload: body,
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
      payload: body,
    });
  }

  function getCommandOutcome(token: string, commandId: string) {
    return app.inject({
      method: "GET",
      url: `/v1/pending-interactions/commands/${commandId}`,
      headers: { authorization: `Bearer ${token}` },
    });
  }

  /** POST a signed action_required question event through the real ingest route. */
  async function postQuestionEvent(credential: string): Promise<number> {
    const body = JSON.stringify({
      eventId: randomUUID(),
      type: "action_required",
      occurredAt: "2026-08-10T12:00:00.000Z",
      source: { machine: "workstation", project: "notify", directory: "/repo" },
      session: { id: "session-1", title: "Coding" },
      payload: {
        requestId: "req-event",
        kind: "question",
        questions: [{ question: SENTINELS.eventQuestion }],
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

  describe("AC1: every real interaction path leaves no interaction content in captured logs", () => {
    it("sweeps snapshot, answer, decision, outcome, ingest, control frames, and error paths for sentinel-free pino output", async () => {
      const { stream, output } = captureLogStream();
      await startApp({ loggerStream: stream });

      const token = await createUser("sweep-ac1@example.com");
      const credential = await createPluginCredential(token);
      const desktop = await connectDesktop(token);
      const instance = await registerPlugin(credential);
      expect(instance.result.state).toBe("controllable");

      // Registration traffic: the sentinel identity flows to the desktop
      // presence frame (allowed transport) before the log assertion.
      const presence = await nextMessage(desktop);
      expect(presence.type).toBe("instance_presence");
      const presenceInstances = presence.instances as { machine: string; directory: string }[];
      expect(presenceInstances[0].machine).toBe(SENTINELS.machine);
      expect(presenceInstances[0].directory).toBe(SENTINELS.directory);

      // Pending snapshot GET: relay sentinel question and permission content
      // through memory; the response must carry it, the logs must not.
      const requestId = randomUUID();
      const permissionRequestId = randomUUID();
      const snapshotResponse = getPendingInteractions(token);
      await answerSnapshot(instance.ws, instance.instanceId, [
        questionInteraction(instance.instanceId, requestId, {
          questions: [
            {
              header: "Sweep",
              question: SENTINELS.question,
              options: [{ label: SENTINELS.option, description: "option" }],
              multiple: false,
              custom: true,
            },
          ],
        }),
        permissionInteraction(instance.instanceId, permissionRequestId, {
          permission: SENTINELS.permission,
          patterns: [SENTINELS.pattern],
          always: [SENTINELS.always],
          metadata: { source: SENTINELS.metadata },
        }),
      ]);
      const snapshot = await snapshotResponse;
      expect(snapshot.statusCode).toBe(200);
      expect(validatePendingSnapshot(snapshot.json())).toBe(true);
      const snapshotBody = JSON.stringify(snapshot.json());
      expect(snapshotBody).toContain(SENTINELS.question);
      expect(snapshotBody).toContain(SENTINELS.option);
      expect(snapshotBody).toContain(SENTINELS.permission);
      expect(snapshotBody).toContain(SENTINELS.pattern);
      expect(snapshotBody).toContain(SENTINELS.always);
      expect(snapshotBody).toContain(SENTINELS.metadata);

      // Question answer POST: the sentinel answer travels only on the control
      // channel; the client's outcome response is body-free by contract.
      const answerCommandId = randomUUID();
      const answerFrame = nextMessage(instance.ws);
      const answerResponse = answerQuestion(token, instance.instanceId, requestId, {
        commandId: answerCommandId,
        answers: [[SENTINELS.answer]],
      });
      const sentAnswer = (await answerFrame) as { type: string; answers: string[][] };
      expect(sentAnswer.type).toBe("question_answer_command");
      expect(sentAnswer.answers).toEqual([[SENTINELS.answer]]);
      instance.ws.send(
        JSON.stringify({
          type: "question_answer_result",
          commandId: answerCommandId,
          instanceId: instance.instanceId,
          status: "confirmed",
        }),
      );
      const answerRes = await answerResponse;
      expect(answerRes.statusCode).toBe(200);

      // Permission decision POST: same body-free outcome contract.
      const decisionCommandId = randomUUID();
      const decisionFrame = nextMessage(instance.ws);
      const decisionResponse = decidePermission(token, instance.instanceId, permissionRequestId, {
        commandId: decisionCommandId,
        decision: "always",
      });
      const sentDecision = (await decisionFrame) as { type: string; decision: string };
      expect(sentDecision.type).toBe("permission_decide_command");
      expect(sentDecision.decision).toBe("always");
      instance.ws.send(
        JSON.stringify({
          type: "permission_decide_result",
          commandId: decisionCommandId,
          instanceId: instance.instanceId,
          status: "confirmed",
        }),
      );
      const decisionRes = await decisionResponse;
      expect(decisionRes.statusCode).toBe(200);

      // Command outcome GET: body-free by construction — no sentinel content.
      for (const commandId of [answerCommandId, decisionCommandId]) {
        const outcome = await getCommandOutcome(token, commandId);
        expect(outcome.statusCode).toBe(200);
        const outcomeBody = JSON.stringify(outcome.json());
        for (const sentinel of Object.values(SENTINELS)) {
          expect(outcomeBody).not.toContain(sentinel);
        }
        expect(outcomeBody).not.toContain("answers");
        expect(outcomeBody).not.toContain("decision");
      }

      // Ingest + notification delivery: the sentinel question reaches the
      // desktop socket (allowed transport) while the request logs stay clean.
      const eventDelivery = nextMessage(desktop);
      expect(await postQuestionEvent(credential)).toBe(202);
      const eventMessage = (await eventDelivery) as {
        type: string;
        event: { payload: { questions: { question: string }[] } };
      };
      expect(eventMessage.type).toBe("event");
      expect(eventMessage.event.payload.questions[0].question).toBe(SENTINELS.eventQuestion);

      // Error path: unauthenticated pending GET.
      const unauth = await getPendingInteractions(null);
      expect(unauth.statusCode).toBe(401);
      expect(validateErrorResponse(unauth.json())).toBe(true);

      // Seed a fresh snapshot so a wrong-kind answer is a real 409 conflict.
      const wrongKindResponse = getPendingInteractions(token);
      await answerSnapshot(instance.ws, instance.instanceId, [
        permissionInteraction(instance.instanceId, "per_wrong"),
      ]);
      expect((await wrongKindResponse).statusCode).toBe(200);

      // Error paths: wrong-kind answer is 409, never-projected answer is 404,
      // and an unknown-instance decision is 404 — all with socket silence.
      const conflictSilence = expectSilence(instance.ws);
      const conflict = await answerQuestion(token, instance.instanceId, "per_wrong", {
        commandId: randomUUID(),
        answers: [[SENTINELS.answer]],
      });
      await conflictSilence;
      expect(conflict.statusCode).toBe(409);
      expect((conflict.json() as { error: { code: string } }).error.code).toBe("CONFLICT");

      const neverSilence = expectSilence(instance.ws);
      const never = await answerQuestion(token, instance.instanceId, "never_seen", {
        commandId: randomUUID(),
        answers: [[SENTINELS.answer]],
      });
      await neverSilence;
      expect(never.statusCode).toBe(404);
      expect((never.json() as { error: { code: string } }).error.code).toBe("NOT_FOUND");

      const foreignSilence = expectSilence(instance.ws);
      const foreign = await decidePermission(token, randomUUID(), "per_1", {
        commandId: randomUUID(),
        decision: "once",
      });
      await foreignSilence;
      expect(foreign.statusCode).toBe(404);
      expect((foreign.json() as { error: { code: string } }).error.code).toBe("NOT_FOUND");

      // Control-WS close reason 4400: a garbage frame is rejected without
      // logging its contents.
      const garbageSocket = await connectPlugin(credential);
      const invalidClose = nextClose(garbageSocket);
      garbageSocket.send(SENTINELS.garbage);
      expect(await invalidClose).toBe(4400);

      // Control-WS close reason 4403: revoking the Plugin key closes its
      // socket; the reason and key stay out of the logs.
      const secondKey = await createPluginKey(token);
      const revocable = await registerPlugin(secondKey.credential, {
        directory: "/work/revocable",
      });
      const revokedClose = nextClose(revocable.ws);
      const revoked = await app.inject({
        method: "DELETE",
        url: `/v1/ingest-keys/${secondKey.id}`,
        headers: { authorization: `Bearer ${token}` },
      });
      expect(revoked.statusCode).toBe(204);
      expect(await revokedClose).toBe(4403);

      // The captured pino output must contain none of the sentinel values,
      // including the registration identity, interaction bodies, answers,
      // permission patterns/always/metadata, the event question, the garbage
      // frame, and the close reasons.
      const logged = output();
      // Non-vacuous: real request logs were produced for the exercised paths.
      expect(logged).toContain("incoming request");
      expect(logged).toContain("/v1/pending-interactions");
      expect(logged).toContain("/v1/plugin/ws");
      for (const sentinel of Object.values(SENTINELS)) {
        expect(logged).not.toContain(sentinel);
      }
      // The paths themselves must not surface interaction content either.
      expect(logged).not.toContain("question_answer_command");
      expect(logged).not.toContain("permission_decide_command");
      expect(logged).not.toContain("pending_snapshot_response");
    });
  });

  describe("AC2: no durable interaction or outcome store after exercising every endpoint", () => {
    it("leaves Postgres with exactly the public account-table allowlist after all interaction traffic", async () => {
      await startApp();

      const token = await createUser("sweep-ac2@example.com");
      const credential = await createPluginCredential(token);
      const instance = await registerPlugin(credential);
      expect(instance.result.state).toBe("controllable");

      // Pending snapshot GET with question + permission content.
      const snapshotResponse = getPendingInteractions(token);
      await answerSnapshot(instance.ws, instance.instanceId, [
        questionInteraction(instance.instanceId),
        permissionInteraction(instance.instanceId),
      ]);
      expect((await snapshotResponse).statusCode).toBe(200);

      // Question answer POST.
      const answerCommandId = randomUUID();
      const answerFrame = nextMessage(instance.ws);
      const answerResponse = answerQuestion(token, instance.instanceId, "req_1", {
        commandId: answerCommandId,
        answers: [["Postgres"]],
      });
      expect(((await answerFrame) as { commandId: string }).commandId).toBe(answerCommandId);
      instance.ws.send(
        JSON.stringify({
          type: "question_answer_result",
          commandId: answerCommandId,
          instanceId: instance.instanceId,
          status: "confirmed",
        }),
      );
      expect((await answerResponse).statusCode).toBe(200);

      // Permission decision POST.
      const decisionCommandId = randomUUID();
      const decisionFrame = nextMessage(instance.ws);
      const decisionResponse = decidePermission(token, instance.instanceId, "per_1", {
        commandId: decisionCommandId,
        decision: "once",
      });
      expect(((await decisionFrame) as { commandId: string }).commandId).toBe(decisionCommandId);
      instance.ws.send(
        JSON.stringify({
          type: "permission_decide_result",
          commandId: decisionCommandId,
          instanceId: instance.instanceId,
          status: "confirmed",
        }),
      );
      expect((await decisionResponse).statusCode).toBe(200);

      // Command outcome GET for both recorded commands.
      for (const commandId of [answerCommandId, decisionCommandId]) {
        const outcome = await getCommandOutcome(token, commandId);
        expect(outcome.statusCode).toBe(200);
      }

      // A fresh control-WS connection registered and revoked key traffic.
      const secondKey = await createPluginKey(token);
      const revocable = await registerPlugin(secondKey.credential);
      const revokedClose = nextClose(revocable.ws);
      const revoked = await app.inject({
        method: "DELETE",
        url: `/v1/ingest-keys/${secondKey.id}`,
        headers: { authorization: `Bearer ${token}` },
      });
      expect(revoked.statusCode).toBe(204);
      expect(await revokedClose).toBe(4403);

      // The public schema must contain exactly the seven account tables and
      // nothing else: no pending interactions, answers, decisions, or command
      // outcome store was created by any of the above traffic.
      const tables = (await handle.db.execute<{ tablename: string }>(
        sql`select tablename from pg_tables where schemaname = 'public'`,
      )) as { tablename: string }[];
      const names = tables.map((row) => row.tablename).sort();
      expect(names).toEqual([...PUBLIC_TABLE_ALLOWLIST].sort());
    });
  });
});
