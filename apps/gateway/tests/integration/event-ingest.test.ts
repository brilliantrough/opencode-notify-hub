import { createHmac, randomBytes, randomUUID } from "node:crypto";

import {
  validateErrorResponse,
  validateEventIngestResponse,
} from "@notify/contracts";
import { sql } from "drizzle-orm";
import type { FastifyInstance, LightMyRequestResponse } from "fastify";
import { afterAll, beforeAll, beforeEach, describe, expect, it } from "vitest";

import { buildServer } from "../../src/app.js";
import { createDb, type GatewayDatabase } from "../../src/db/client.js";
import type { Clock } from "../../src/lib/clock.js";
import type { EventDispatcher } from "../../src/modules/events/events.routes.js";
import type { Mailer } from "../../src/modules/mail/mailer.js";
import {
  INGEST_EVENTS_IP_RATE_LIMIT,
  INGEST_EVENTS_RATE_LIMIT,
} from "../../src/plugins/rate-limit.js";
import { buildTestConfig } from "../helpers/build-test-app.js";
import { TestPostgres } from "../helpers/postgres.js";

const PASSWORD = "correct horse battery staple";

/** Fixed "now" for the fake clock: deterministic timestamp windows. */
const T0 = 1_800_000_000_000;

const EVENT_ID = "3f6f1e2a-7c3b-4d5e-8f60-1a2b3c4d5e6f";

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

class RecordingDispatcher implements EventDispatcher {
  calls: { userId: string; event: Record<string, unknown> }[] = [];

  async dispatch(input: { userId: string; event: never }): Promise<void> {
    this.calls.push(input);
  }
}

/**
 * Dispatcher whose dispatch promise pends until the test releases it, and
 * which can be told to fail. Used to hold an in-flight dispatch open while a
 * concurrent duplicate arrives.
 */
class BlockingDispatcher implements EventDispatcher {
  calls: { userId: string; event: Record<string, unknown> }[] = [];
  private gate: Promise<void> = Promise.resolve();
  private open: () => void = () => {};
  private failure: Error | null = null;
  private callWaiters: (() => void)[] = [];

  block(): void {
    this.gate = new Promise<void>((resolve) => {
      this.open = resolve;
    });
  }

  release(): void {
    this.open();
  }

  failWith(error: Error): void {
    this.failure = error;
  }

  recover(): void {
    this.failure = null;
  }

  dispatch(input: { userId: string; event: never }): Promise<void> {
    this.calls.push(input);
    for (const waiter of this.callWaiters.splice(0)) {
      waiter();
    }
    return (async () => {
      await this.gate;
      if (this.failure !== null) {
        throw this.failure;
      }
    })();
  }

  async waitForCalls(n: number): Promise<void> {
    while (this.calls.length < n) {
      await new Promise<void>((resolve) => {
        this.callWaiters.push(resolve);
      });
    }
  }
}

/** The exact signing rule the OpenCode plugin implements. */
function sign(secret: string, timestamp: string, rawBody: string): string {
  return createHmac("sha256", secret).update(`${timestamp}.${rawBody}`).digest("hex");
}

function randomCredential(): string {
  return `${randomBytes(9).toString("base64url")}.${randomBytes(32).toString("base64url")}`;
}

/** Canonical JSON body of a schema-valid heartbeat event. */
function rawEvent(eventId: string = EVENT_ID): string {
  return JSON.stringify({
    eventId,
    type: "heartbeat",
    occurredAt: "2026-08-10T12:00:00.000Z",
    source: { machine: "workstation", project: "notify", directory: "/repo" },
    session: { id: "session-1", title: "Coding" },
    payload: { status: "busy", elapsedSeconds: 12 },
  });
}

interface PostEventOptions {
  /** Bearer credential; null omits the Authorization header. */
  credential?: string | null;
  /** Raw Authorization header value; wins over `credential`. */
  authorization?: string;
  /** Sign with this secret instead of the credential's secret part. */
  signWith?: string;
  /** Timestamp header value; null omits the header. Defaults to the fake now. */
  timestamp?: string | null;
  /** Signature header value; null omits the header. Defaults to a valid signature. */
  signature?: string | null;
  /** Raw request body; defaults to a canonical heartbeat event. */
  body?: string;
  remoteAddress?: string;
}

describe("event ingestion", () => {
  let pg: TestPostgres;
  let handle: GatewayDatabase;
  let app: FastifyInstance;
  let mailer: FakeMailer;
  let dispatcher: RecordingDispatcher;
  let clock: FakeClock;

  function postEvent(options: PostEventOptions = {}): Promise<LightMyRequestResponse> {
    const body = options.body ?? rawEvent();
    const credential = options.credential === undefined ? currentCredential : options.credential;
    const timestamp = options.timestamp === undefined ? String(clock.nowMs()) : options.timestamp;
    const signingSecret =
      options.signWith ??
      (credential === null || credential === undefined
        ? ""
        : credential.slice(credential.indexOf(".") + 1));
    const signature =
      options.signature === undefined
        ? sign(signingSecret, timestamp ?? "", body)
        : options.signature;

    const headers: Record<string, string> = { "content-type": "application/json" };
    if (options.authorization !== undefined) {
      headers.authorization = options.authorization;
    } else if (credential !== null) {
      headers.authorization = `Bearer ${credential}`;
    }
    if (timestamp !== null) {
      headers["x-notify-timestamp"] = timestamp;
    }
    if (signature !== null) {
      headers["x-notify-signature"] = signature;
    }
    return app.inject({
      method: "POST",
      url: "/v1/events",
      headers,
      payload: body,
      ...(options.remoteAddress !== undefined ? { remoteAddress: options.remoteAddress } : {}),
    });
  }

  /** Credential of the key created by the current test; set by createCredential. */
  let currentCredential: string;

  /** Register, verify, log in, and create an ingest key; returns the credential. */
  async function createCredential(email: string): Promise<string> {
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
    const token = login.json().accessToken as string;
    const created = await app.inject({
      method: "POST",
      url: "/v1/ingest-keys",
      headers: { authorization: `Bearer ${token}` },
      payload: { name: "workstation" },
    });
    expect(created.statusCode).toBe(201);
    return created.json().secret as string;
  }

  /** Revoke the user's only ingest key (tests truncate before each run). */
  async function revokeSoleKey(email: string): Promise<void> {
    const login = await app.inject({
      method: "POST",
      url: "/v1/auth/login",
      payload: { email, password: PASSWORD },
    });
    const token = login.json().accessToken as string;
    const list = await app.inject({
      method: "GET",
      url: "/v1/ingest-keys",
      headers: { authorization: `Bearer ${token}` },
    });
    const keys = list.json() as { id: string }[];
    expect(keys).toHaveLength(1);
    const res = await app.inject({
      method: "DELETE",
      url: `/v1/ingest-keys/${keys[0].id}`,
      headers: { authorization: `Bearer ${token}` },
    });
    expect(res.statusCode).toBe(204);
  }

  async function userIdFor(email: string): Promise<string> {
    const rows = (await handle.db.execute<{ id: string }>(
      sql`select id from users where email = ${email}`,
    )) as { id: string }[];
    return rows[0].id;
  }

  beforeAll(async () => {
    pg = await TestPostgres.start();
    await pg.migrate();
    handle = createDb(pg.databaseUrl);
  });

  afterAll(async () => {
    await app.close();
    await handle.close();
    await pg.stop();
  });

  beforeEach(async () => {
    await handle.db.execute(
      sql`truncate refresh_tokens, refresh_token_families, password_reset_tokens, email_verification_tokens, devices, ingest_keys, users cascade`,
    );
    if (app !== undefined) {
      await app.close();
    }
    mailer = new FakeMailer();
    dispatcher = new RecordingDispatcher();
    clock = new FakeClock(T0);
    app = await buildServer({
      config: buildTestConfig({ databaseUrl: pg.databaseUrl }),
      db: handle.db,
      mailer,
      clock,
      eventDispatcher: dispatcher,
    });
  });

  describe("acceptance", () => {
    it("accepts a validly signed event: 202 contract shape, dispatched once, nothing persisted", async () => {
      currentCredential = await createCredential("alice@example.com");
      const userId = await userIdFor("alice@example.com");

      const res = await postEvent();
      expect(res.statusCode).toBe(202);
      const body = res.json();
      expect(validateEventIngestResponse(body)).toBe(true);
      expect(body).toEqual({ eventId: EVENT_ID, deduplicated: false });

      expect(dispatcher.calls).toHaveLength(1);
      expect(dispatcher.calls[0].userId).toBe(userId);
      expect(dispatcher.calls[0].event.eventId).toBe(EVENT_ID);
      expect((dispatcher.calls[0].event.session as { id: string }).id).toBe("session-1");

      // No event persistence: the schema has no events table at all.
      const tables = (await handle.db.execute<{ tablename: string }>(
        sql`select tablename from pg_tables where schemaname = 'public'`,
      )) as { tablename: string }[];
      expect(tables.map((row) => row.tablename)).not.toContain("events");
    });

    it("authenticates over the exact raw bytes, not a re-serialization", async () => {
      currentCredential = await createCredential("alice@example.com");
      // Non-canonical JSON: odd whitespace, reordered keys, unicode content.
      const body = `{ "payload": { "elapsedSeconds": 7, "status": "busy" },
  "session": { "title": "émoji 🚀", "id": "s-unicode" },
  "source": { "directory": "/repo", "project": "notify", "machine": "w" },
  "occurredAt": "2026-08-10T12:00:00.000Z",
  "type": "heartbeat",
  "eventId": "${EVENT_ID}" }`;

      const res = await postEvent({ body });
      expect(res.statusCode).toBe(202);
      expect(res.json().deduplicated).toBe(false);
      expect(dispatcher.calls).toHaveLength(1);
      const session = dispatcher.calls[0].event.session as { title: string };
      expect(session.title).toBe("émoji 🚀");
    });
  });

  describe("signature and credential rejection", () => {
    it("rejects a body changed after signing", async () => {
      currentCredential = await createCredential("alice@example.com");
      const signedBody = rawEvent();
      const secret = currentCredential.slice(currentCredential.indexOf(".") + 1);
      const timestamp = String(clock.nowMs());
      const signature = sign(secret, timestamp, signedBody);
      // Same event, one byte different in the payload.
      const tamperedBody = signedBody.replace('"elapsedSeconds":12', '"elapsedSeconds":13');

      const res = await postEvent({
        body: tamperedBody,
        timestamp,
        signature,
      });
      expect(res.statusCode).toBe(401);
      expect(res.json().error.code).toBe("UNAUTHORIZED");
      expect(validateErrorResponse(res.json())).toBe(true);
      expect(dispatcher.calls).toHaveLength(0);
    });

    it("rejects wrong secrets and unknown keyIds with one uniform 401", async () => {
      currentCredential = await createCredential("alice@example.com");
      const keyId = currentCredential.slice(0, currentCredential.indexOf("."));
      const wrongSecret = randomBytes(32).toString("base64url");

      // (a) Valid credential, signature made with a different secret.
      const badSignature = await postEvent({ signWith: wrongSecret });
      // (b) Known keyId with a wrong secret part, self-consistently signed.
      const wrongCredential = await postEvent({
        credential: `${keyId}.${wrongSecret}`,
        signWith: wrongSecret,
      });
      // (c) Entirely unknown keyId, self-consistently signed.
      const unknownKeyId = await postEvent({ credential: randomCredential() });

      for (const res of [badSignature, wrongCredential, unknownKeyId]) {
        expect(res.statusCode).toBe(401);
        expect(res.json().error.code).toBe("UNAUTHORIZED");
        expect(validateErrorResponse(res.json())).toBe(true);
      }
      // The response never reveals whether the keyId exists.
      expect(wrongCredential.body).toBe(unknownKeyId.body);
      expect(badSignature.body).toBe(unknownKeyId.body);
      expect(dispatcher.calls).toHaveLength(0);
    });

    it("rejects missing and malformed headers with the same uniform 401", async () => {
      currentCredential = await createCredential("alice@example.com");

      const cases: [string, PostEventOptions][] = [
        ["no Authorization header", { credential: null }],
        ["no timestamp header", { timestamp: null }],
        ["no signature header", { signature: null }],
        ["non-numeric timestamp", { timestamp: "soon" }],
        ["float timestamp", { timestamp: `${T0}.5` }],
        ["wrong auth scheme", { authorization: "Token abc.def" }],
        ["credential without a dot", { credential: "nodothere" }],
        ["short non-hex signature", { signature: "zz" }],
      ];

      const bodies: string[] = [];
      for (const [name, options] of cases) {
        const res = await postEvent(options);
        expect(res.statusCode, name).toBe(401);
        expect(res.json().error.code, name).toBe("UNAUTHORIZED");
        bodies.push(res.body);
      }
      for (const body of bodies) {
        expect(body).toBe(bodies[0]);
      }
      expect(dispatcher.calls).toHaveLength(0);
    });

    it("rejects a revoked key exactly like an unknown one", async () => {
      currentCredential = await createCredential("alice@example.com");

      const before = await postEvent({ body: rawEvent(randomUUID()) });
      expect(before.statusCode).toBe(202);

      await revokeSoleKey("alice@example.com");
      const revoked = await postEvent({ body: rawEvent(randomUUID()) });
      expect(revoked.statusCode).toBe(401);

      const unknown = await postEvent({
        credential: randomCredential(),
        body: rawEvent(randomUUID()),
      });
      expect(unknown.statusCode).toBe(401);
      expect(revoked.body).toBe(unknown.body);
    });
  });

  describe("timestamp window", () => {
    it("accepts timestamps 299 seconds off and rejects 301 seconds off", async () => {
      currentCredential = await createCredential("alice@example.com");

      const minus299 = await postEvent({
        timestamp: String(T0 - 299_000),
        body: rawEvent(randomUUID()),
      });
      expect(minus299.statusCode).toBe(202);

      const plus299 = await postEvent({
        timestamp: String(T0 + 299_000),
        body: rawEvent(randomUUID()),
      });
      expect(plus299.statusCode).toBe(202);

      const minus301 = await postEvent({
        timestamp: String(T0 - 301_000),
        body: rawEvent(randomUUID()),
      });
      expect(minus301.statusCode).toBe(401);

      const plus301 = await postEvent({
        timestamp: String(T0 + 301_000),
        body: rawEvent(randomUUID()),
      });
      expect(plus301.statusCode).toBe(401);

      expect(dispatcher.calls).toHaveLength(2);
    });
  });

  describe("event schema validation", () => {
    it("rejects schema-invalid events with 400 VALIDATION_FAILED after auth", async () => {
      currentCredential = await createCredential("alice@example.com");

      const wrongType = rawEvent().replace('"heartbeat"', '"bogus"');
      const res = await postEvent({ body: wrongType });
      expect(res.statusCode).toBe(400);
      expect(res.json().error.code).toBe("VALIDATION_FAILED");
      expect(validateErrorResponse(res.json())).toBe(true);

      const missingPayload = JSON.stringify({
        eventId: randomUUID(),
        type: "heartbeat",
        occurredAt: "2026-08-10T12:00:00.000Z",
        source: { machine: "w", project: "p", directory: "/d" },
        session: { id: "s", title: "t" },
      });
      const res2 = await postEvent({ body: missingPayload });
      expect(res2.statusCode).toBe(400);
      expect(res2.json().error.code).toBe("VALIDATION_FAILED");

      expect(dispatcher.calls).toHaveLength(0);
    });

    it("rejects a non-JSON signed body with 400", async () => {
      currentCredential = await createCredential("alice@example.com");
      const res = await postEvent({ body: "this is not json" });
      expect(res.statusCode).toBe(400);
      expect(validateErrorResponse(res.json())).toBe(true);
      expect(dispatcher.calls).toHaveLength(0);
    });
  });

  describe("dedupe", () => {
    it("answers duplicates with deduplicated:true and dispatches only once", async () => {
      currentCredential = await createCredential("alice@example.com");

      const first = await postEvent();
      expect(first.statusCode).toBe(202);
      expect(first.json()).toEqual({ eventId: EVENT_ID, deduplicated: false });

      const second = await postEvent();
      expect(second.statusCode).toBe(202);
      expect(second.json()).toEqual({ eventId: EVENT_ID, deduplicated: true });
      expect(validateEventIngestResponse(second.json())).toBe(true);

      expect(dispatcher.calls).toHaveLength(1);
    });

    it("scopes dedupe per user: another user's identical eventId still dispatches", async () => {
      currentCredential = await createCredential("alice@example.com");
      const aliceFirst = await postEvent();
      expect(aliceFirst.json().deduplicated).toBe(false);

      const bobCredential = await createCredential("bob@example.com");
      const bobFirst = await postEvent({ credential: bobCredential });
      expect(bobFirst.json().deduplicated).toBe(false);
      expect(dispatcher.calls).toHaveLength(2);

      // ...while repeats within each user still dedupe.
      const aliceSecond = await postEvent();
      expect(aliceSecond.json().deduplicated).toBe(true);
      const bobSecond = await postEvent({ credential: bobCredential });
      expect(bobSecond.json().deduplicated).toBe(true);
      expect(dispatcher.calls).toHaveLength(2);
    });

    it("expires dedupe entries after ten minutes", async () => {
      currentCredential = await createCredential("alice@example.com");

      expect((await postEvent()).json().deduplicated).toBe(false);

      clock.advance(9 * 60 * 1000);
      expect((await postEvent()).json().deduplicated).toBe(true);
      expect(dispatcher.calls).toHaveLength(1);

      clock.advance(61_000); // now 10 minutes 1 second after the first sighting
      expect((await postEvent()).json().deduplicated).toBe(false);
      expect(dispatcher.calls).toHaveLength(2);
    });
  });

  describe("concurrent ingestion (single-flight)", () => {
    /** Rebuild the app with a controllable dispatcher for the concurrency tests. */
    async function rebuildWith(blocking: BlockingDispatcher): Promise<void> {
      await app.close();
      app = await buildServer({
        config: buildTestConfig({ databaseUrl: pg.databaseUrl }),
        db: handle.db,
        mailer,
        clock,
        eventDispatcher: blocking,
      });
    }

    /** Give an already-injected request time to reach its in-flight await. */
    async function settle(): Promise<void> {
      await new Promise((resolve) => setTimeout(resolve, 20));
    }

    it("dispatches concurrent identical events once; owner gets the original, waiter the duplicate", async () => {
      const blocking = new BlockingDispatcher();
      blocking.block();
      await rebuildWith(blocking);
      currentCredential = await createCredential("alice@example.com");

      const first = postEvent();
      await blocking.waitForCalls(1);
      const second = postEvent();
      await settle();
      blocking.release();

      const [firstRes, secondRes] = await Promise.all([first, second]);
      expect(blocking.calls).toHaveLength(1);
      expect(firstRes.statusCode).toBe(202);
      expect(secondRes.statusCode).toBe(202);
      expect(firstRes.json()).toEqual({ eventId: EVENT_ID, deduplicated: false });
      expect(secondRes.json()).toEqual({ eventId: EVENT_ID, deduplicated: true });
      expect(validateEventIngestResponse(secondRes.json())).toBe(true);

      // The successful dispatch committed the entry: later repeats dedupe.
      const third = await postEvent();
      expect(third.json().deduplicated).toBe(true);
      expect(blocking.calls).toHaveLength(1);
    });

    it("fails both concurrent callers with a safe 503, commits nothing, and lets a retry dispatch", async () => {
      const blocking = new BlockingDispatcher();
      blocking.block();
      blocking.failWith(new Error("fanout down: smtp://internal-host secret detail"));
      await rebuildWith(blocking);
      currentCredential = await createCredential("alice@example.com");

      const first = postEvent();
      await blocking.waitForCalls(1);
      const second = postEvent();
      await settle();
      blocking.release();

      const [firstRes, secondRes] = await Promise.all([first, second]);
      expect(blocking.calls).toHaveLength(1);
      for (const res of [firstRes, secondRes]) {
        expect(res.statusCode).toBe(503);
        expect(res.json().error.code).toBe("SERVICE_UNAVAILABLE");
        expect(validateErrorResponse(res.json())).toBe(true);
        // No dispatcher internals leak into the response.
        expect(res.body).not.toContain("fanout down");
        expect(res.body).not.toContain("internal-host");
      }

      // No committed dedupe: a later retry dispatches again and succeeds.
      blocking.recover();
      const retry = await postEvent();
      expect(retry.statusCode).toBe(202);
      expect(retry.json()).toEqual({ eventId: EVENT_ID, deduplicated: false });
      expect(blocking.calls).toHaveLength(2);

      // ...and only then is the eventId deduplicated.
      const repeat = await postEvent();
      expect(repeat.json().deduplicated).toBe(true);
      expect(blocking.calls).toHaveLength(2);
    });
  });

  describe("rate limits", () => {
    it("caps pre-auth requests per client IP even when keyIds rotate", async () => {
      // Random keyIds must not mint unlimited buckets or key-store lookups;
      // the per-IP ceiling fires before any key lookup.
      let lastStatus = 0;
      for (let attempt = 0; attempt < INGEST_EVENTS_IP_RATE_LIMIT.max; attempt += 1) {
        const res = await postEvent({ credential: randomCredential() });
        lastStatus = res.statusCode;
        expect(lastStatus, `attempt ${attempt + 1}`).toBe(401);
      }

      const limited = await postEvent({ credential: randomCredential() });
      expect(limited.statusCode).toBe(429);
      expect(limited.json().error.code).toBe("RATE_LIMITED");
      expect(validateErrorResponse(limited.json())).toBe(true);
      const retryAfter = Number(limited.headers["retry-after"]);
      expect(Number.isInteger(retryAfter)).toBe(true);
      expect(retryAfter).toBeGreaterThanOrEqual(1);
      expect(retryAfter).toBeLessThanOrEqual(60);

      // The ceiling is per IP: another client IP is unaffected.
      const otherIp = await postEvent({
        credential: randomCredential(),
        remoteAddress: "10.9.8.7",
      });
      expect(otherIp.statusCode).toBe(401);
      expect(dispatcher.calls).toHaveLength(0);
    });

    it("applies the 240/minute policy per verified keyId after auth", async () => {
      const keyA = await createCredential("alice@example.com");
      currentCredential = keyA;
      const keyB = await (async () => {
        const login = await app.inject({
          method: "POST",
          url: "/v1/auth/login",
          payload: { email: "alice@example.com", password: PASSWORD },
        });
        const created = await app.inject({
          method: "POST",
          url: "/v1/ingest-keys",
          headers: { authorization: `Bearer ${login.json().accessToken as string}` },
          payload: { name: "laptop" },
        });
        expect(created.statusCode).toBe(201);
        return created.json().secret as string;
      })();

      // Key A exhausts its verified budget.
      for (let attempt = 0; attempt < INGEST_EVENTS_RATE_LIMIT.max; attempt += 1) {
        const res = await postEvent({ credential: keyA, body: rawEvent(randomUUID()) });
        expect(res.statusCode, `key A attempt ${attempt + 1}`).toBe(202);
      }
      expect(dispatcher.calls).toHaveLength(INGEST_EVENTS_RATE_LIMIT.max);

      // Request 241 on key A is limited.
      const limited = await postEvent({ credential: keyA, body: rawEvent(randomUUID()) });
      expect(limited.statusCode).toBe(429);
      expect(limited.json().error.code).toBe("RATE_LIMITED");
      expect(validateErrorResponse(limited.json())).toBe(true);
      const retryAfter = Number(limited.headers["retry-after"]);
      expect(Number.isInteger(retryAfter)).toBe(true);
      expect(retryAfter).toBeGreaterThanOrEqual(1);
      expect(retryAfter).toBeLessThanOrEqual(60);
      expect(dispatcher.calls).toHaveLength(INGEST_EVENTS_RATE_LIMIT.max);

      // Key B has its own verified bucket: same user, same IP, unaffected.
      const fromKeyB = await postEvent({ credential: keyB, body: rawEvent(randomUUID()) });
      expect(fromKeyB.statusCode).toBe(202);
      expect(dispatcher.calls).toHaveLength(INGEST_EVENTS_RATE_LIMIT.max + 1);
    });
  });

  describe("key-store outage", () => {
    it("answers 503 when the database is unavailable, with the IP ceiling still first", async () => {
      // An ended pool: every new query rejects immediately with
      // CONNECTION_ENDED, simulating a key-store outage.
      const dead = createDb(pg.databaseUrl);
      await dead.close();
      const deadApp = await buildServer({
        config: buildTestConfig({ databaseUrl: pg.databaseUrl }),
        db: dead.db,
        mailer: new FakeMailer(),
        clock,
        eventDispatcher: dispatcher,
      });
      try {
        const injectDead = () =>
          deadApp.inject({
            method: "POST",
            url: "/v1/events",
            headers: {
              "content-type": "application/json",
              authorization: `Bearer ${randomCredential()}`,
              "x-notify-timestamp": String(clock.nowMs()),
              "x-notify-signature": "ab".repeat(32),
            },
            payload: rawEvent(),
          });

        const first = await injectDead();
        expect(first.statusCode).toBe(503);
        expect(first.json().error.code).toBe("SERVICE_UNAVAILABLE");
        expect(validateErrorResponse(first.json())).toBe(true);

        // Exhaust the per-IP ceiling against the dead store: every request
        // fails 503 (the limiter does not fire early) until the 1001st,
        // which is rejected with 429 without any key-store lookup.
        for (let attempt = 1; attempt < INGEST_EVENTS_IP_RATE_LIMIT.max; attempt += 1) {
          const res = await injectDead();
          expect(res.statusCode, `attempt ${attempt + 1}`).toBe(503);
        }
        const limited = await injectDead();
        expect(limited.statusCode).toBe(429);
        expect(limited.json().error.code).toBe("RATE_LIMITED");
        expect(dispatcher.calls).toHaveLength(0);
      } finally {
        await deadApp.close();
        await dead.close();
      }
    });
  });
});
