import { createHmac, randomUUID } from "node:crypto";

import {
  validateErrorResponse,
  validatePluginControlServerMessage,
  validateWsServerMessage,
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
  WS_CLOSE_SERVER_SHUTDOWN,
  WS_CLOSE_TOKEN_EXPIRED,
} from "../../src/modules/realtime/connection-registry.js";
import {
  buildTestConfig,
  noopFcmSender,
  TEST_JWT_SIGNING_KEY,
} from "../helpers/build-test-app.js";
import { TestPostgres } from "../helpers/postgres.js";

const PASSWORD = "correct horse battery staple";

/** Fixed "now" for the fake clock: deterministic token expiry. */
const T0 = 1_800_000_000_000;

/** Fast heartbeat so ping/pong and stale-socket tests run in milliseconds. */
const TEST_PING_INTERVAL_MS = 60;

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

/** Sign a JWT by hand so tests can choose exp (e.g. already-expired, expiring soon). */
function craftToken(payload: { sub: string; iat: number; exp: number }): string {
  const key = Buffer.from(TEST_JWT_SIGNING_KEY, "base64");
  const b64 = (value: unknown): string =>
    Buffer.from(JSON.stringify(value), "utf8").toString("base64url");
  const input = `${b64({ alg: "HS256", typ: "JWT" })}.${b64(payload)}`;
  return `${input}.${createHmac("sha256", key).update(input, "utf8").digest("base64url")}`;
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

describe("WebSocket routing", () => {
  let pg: TestPostgres;
  let handle: GatewayDatabase;
  let app: FastifyInstance;
  let mailer: FakeMailer;
  let clock: FakeClock;
  let port: number;
  let appClosed = false;
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
    appClosed = false;
  });

  afterEach(async () => {
    for (const client of clients.splice(0)) {
      if (client.readyState === WebSocket.OPEN || client.readyState === WebSocket.CONNECTING) {
        client.terminate();
      }
    }
    if (!appClosed) {
      await app.close();
    }
  });

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

  /** Create an ingest key for the user; returns the `keyId.secret` credential. */
  async function createIngestCredential(token: string): Promise<string> {
    const created = await app.inject({
      method: "POST",
      url: "/v1/ingest-keys",
      headers: { authorization: `Bearer ${token}` },
      payload: { name: "workstation" },
    });
    expect(created.statusCode).toBe(201);
    return created.json().secret as string;
  }

  async function createPluginKey(token: string): Promise<{ id: string; credential: string }> {
    const created = await app.inject({
      method: "POST",
      url: "/v1/ingest-keys",
      headers: { authorization: `Bearer ${token}` },
      payload: { name: "control" },
    });
    expect(created.statusCode).toBe(201);
    const body = created.json() as { id: string; secret: string };
    return { id: body.id, credential: body.secret };
  }

  /** POST a schema-valid heartbeat event through the signed ingest endpoint. */
  async function postEvent(credential: string, eventId: string): Promise<void> {
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
    expect(res.json()).toEqual({ eventId, deduplicated: false });
  }

  function connect(
    authorization: string | null,
    options: { autoPong?: boolean; origin?: string } = {},
  ): Promise<WebSocket> {
    return new Promise((resolve, reject) => {
      const headers: Record<string, string> = {};
      if (authorization !== null) {
        headers.authorization = authorization;
      }
      if (options.origin !== undefined) {
        headers.origin = options.origin;
      }
      const ws = new WebSocket(`ws://127.0.0.1:${port}/v1/ws`, {
        headers,
        ...(options.autoPong === undefined ? {} : { autoPong: options.autoPong }),
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

  async function pluginUpgradeFailure(credential: string): Promise<number> {
    try {
      await connectPlugin(credential);
    } catch (error) {
      const response = (error as { response?: { statusCode?: number } }).response;
      if (response !== undefined) {
        return response.statusCode ?? 0;
      }
      throw error;
    }
    throw new Error("expected the Plugin upgrade to be rejected");
  }

  /** The rejected upgrade's HTTP response: status and parsed body. */
  async function upgradeFailure(
    authorization: string | null,
    options: { origin?: string } = {},
  ): Promise<{ statusCode: number; body: unknown }> {
    try {
      await connect(authorization, options);
    } catch (error) {
      const response = (error as { response?: { statusCode?: number } }).response;
      if (response === undefined) {
        throw error;
      }
      const body = await new Promise<string>((resolve) => {
        let data = "";
        (response as NodeJS.ReadableStream).on("data", (chunk) => {
          data += String(chunk);
        });
        (response as NodeJS.ReadableStream).on("end", () => resolve(data));
      });
      return { statusCode: response.statusCode ?? 0, body: JSON.parse(body) };
    }
    throw new Error("expected the upgrade to be rejected");
  }

  function nextMessage(ws: WebSocket, timeoutMs = 3_000): Promise<unknown> {
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => reject(new Error("timed out waiting for a message")), timeoutMs);
      ws.once("message", (data: Buffer) => {
        clearTimeout(timer);
        resolve(JSON.parse(data.toString("utf8")));
      });
    });
  }

  /** Asserts that no message arrives within the window. */
  async function expectSilence(ws: WebSocket, windowMs = 300): Promise<void> {
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

  describe("upgrade authentication", () => {
    it("rejects missing, malformed, and expired tokens with a contract-shaped 401 before upgrade", async () => {
      const expired = craftToken({
        sub: "user-x",
        iat: Math.floor(T0 / 1000) - 1000,
        exp: Math.floor(T0 / 1000) - 100,
      });

      const cases: [string, string | null][] = [
        ["no Authorization header", null],
        ["wrong scheme", "Token abc.def.ghi"],
        ["garbage token", "Bearer not-a-jwt"],
        ["badly signed token", `Bearer ${craftToken({ sub: "user-x", iat: 1, exp: 9_999_999_999 })}x`],
        ["expired token", `Bearer ${expired}`],
      ];

      for (const [name, authorization] of cases) {
        const failure = await upgradeFailure(authorization);
        expect(failure.statusCode, name).toBe(401);
        expect(validateErrorResponse(failure.body), name).toBe(true);
        expect((failure.body as { error: { code: string } }).error.code, name).toBe("UNAUTHORIZED");
      }
    });

    it("accepts a live access token and leaves the socket open", async () => {
      const { token } = await createUser("alice@example.com");
      const ws = await connect(`Bearer ${token}`);
      expect(ws.readyState).toBe(WebSocket.OPEN);
    });

    it("accepts a browser upgrade from a configured Origin", async () => {
      const { token } = await createUser("origin-ok@example.com");
      const ws = await connect(`Bearer ${token}`, { origin: "https://app.test" });
      expect(ws.readyState).toBe(WebSocket.OPEN);
    });

    it("rejects a browser upgrade from a disallowed Origin with a contract-shaped 403", async () => {
      const { token } = await createUser("origin-denied@example.com");
      const failure = await upgradeFailure(`Bearer ${token}`, { origin: "https://evil.test" });
      expect(failure.statusCode).toBe(403);
      expect(validateErrorResponse(failure.body)).toBe(true);
      expect((failure.body as { error: { code: string } }).error.code).toBe("FORBIDDEN");
    });
  });

  describe("event routing", () => {
    it("delivers an ingested event to every socket of the user", async () => {
      const alice = await createUser("alice@example.com");
      const credential = await createIngestCredential(alice.token);
      const first = await connect(`Bearer ${alice.token}`);
      const second = await connect(`Bearer ${alice.token}`);

      const eventId = randomUUID();
      const deliveries = [nextMessage(first), nextMessage(second)];
      await postEvent(credential, eventId);
      const [one, two] = await Promise.all(deliveries);

      for (const message of [one, two]) {
        expect(validateWsServerMessage(message)).toBe(true);
        const envelope = message as { type: string; event: { eventId: string; type: string } };
        expect(envelope.type).toBe("event");
        expect(envelope.event.eventId).toBe(eventId);
        expect(envelope.event.type).toBe("heartbeat");
      }
    });

    it("never delivers one user's event to another user's socket", async () => {
      const alice = await createUser("alice@example.com");
      const bob = await createUser("bob@example.com");
      const aliceCredential = await createIngestCredential(alice.token);
      const bobSocket = await connect(`Bearer ${bob.token}`);
      const aliceSocket = await connect(`Bearer ${alice.token}`);

      const aliceDelivery = nextMessage(aliceSocket);
      const bobSilence = expectSilence(bobSocket);
      await postEvent(aliceCredential, randomUUID());
      await aliceDelivery;
      await bobSilence;
    });
  });

  describe("OpenCode instance presence", () => {
    it("registers a Plugin instance and publishes controllable presence to its owner", async () => {
      const alice = await createUser("presence@example.com");
      const credential = await createIngestCredential(alice.token);
      const desktop = await connect(`Bearer ${alice.token}`);
      const plugin = await connectPlugin(credential);
      const instanceId = randomUUID();

      const registrationResult = nextMessage(plugin);
      const presenceDelivery = nextMessage(desktop);
      plugin.send(
        JSON.stringify({
          type: "register",
          instanceId,
          machine: "devbox",
          project: "notify",
          directory: "/work/notify",
          openCodeVersion: "1.18.18",
          protocolVersion: 1,
        }),
      );

      const result = await registrationResult;
      expect(validatePluginControlServerMessage(result)).toBe(true);
      expect(result).toEqual({ type: "registration", instanceId, state: "controllable" });

      const message = await presenceDelivery;
      expect(validateWsServerMessage(message)).toBe(true);
      expect(message).toMatchObject({
        type: "instance_presence",
        instances: [
          {
            instanceId,
            machine: "devbox",
            project: "notify",
            directory: "/work/notify",
            openCodeVersion: "1.18.18",
            protocolVersion: 1,
            state: "controllable",
          },
        ],
      });
    });

    it("isolates owners while allowing two projects on one machine", async () => {
      const alice = await createUser("presence-owner@example.com");
      const bob = await createUser("presence-other@example.com");
      const credential = await createIngestCredential(alice.token);
      const aliceDesktop = await connect(`Bearer ${alice.token}`);
      const bobDesktop = await connect(`Bearer ${bob.token}`);
      const bobSilence = expectSilence(bobDesktop, 500);

      for (const [project, directory] of [
        ["api", "/work/api"],
        ["web", "/work/web"],
      ]) {
        const plugin = await connectPlugin(credential);
        const registered = nextMessage(plugin);
        const delivered = nextMessage(aliceDesktop);
        plugin.send(
          JSON.stringify({
            type: "register",
            instanceId: randomUUID(),
            machine: "devbox",
            project,
            directory,
            openCodeVersion: "1.18.18",
            protocolVersion: 1,
          }),
        );
        expect(await registered).toMatchObject({ state: "controllable" });
        const snapshot = (await delivered) as { instances: { project: string; state: string }[] };
        expect(snapshot.instances.at(-1)).toMatchObject({ project, state: "controllable" });
      }

      await bobSilence;
    });

    it("scopes identical runtime instance ids to their Plugin-key owners", async () => {
      const alice = await createUser("presence-collision-a@example.com");
      const bob = await createUser("presence-collision-b@example.com");
      const aliceKey = await createIngestCredential(alice.token);
      const bobKey = await createIngestCredential(bob.token);
      const aliceDesktop = await connect(`Bearer ${alice.token}`);
      const bobDesktop = await connect(`Bearer ${bob.token}`);
      const instanceId = randomUUID();

      for (const [credential, desktop, project] of [
        [aliceKey, aliceDesktop, "alice-project"],
        [bobKey, bobDesktop, "bob-project"],
      ] as const) {
        const plugin = await connectPlugin(credential);
        const result = nextMessage(plugin);
        const snapshot = nextMessage(desktop);
        plugin.send(
          JSON.stringify({
            type: "register",
            instanceId,
            machine: "shared-name",
            project,
            directory: "/work/shared",
            openCodeVersion: "1.18.18",
            protocolVersion: 1,
          }),
        );
        expect(await result).toMatchObject({ state: "controllable" });
        expect(await snapshot).toMatchObject({
          instances: [{ instanceId, project, state: "controllable" }],
        });
      }
    });

    it("keeps the first machine/project owner and promotes a connected conflict", async () => {
      const alice = await createUser("presence-conflict@example.com");
      const credential = await createIngestCredential(alice.token);
      const desktop = await connect(`Bearer ${alice.token}`);
      const first = await connectPlugin(credential);
      const firstId = randomUUID();
      const firstResult = nextMessage(first);
      const firstSnapshot = nextMessage(desktop);
      first.send(
        JSON.stringify({
          type: "register",
          instanceId: firstId,
          machine: "DEVBOX",
          project: "notify",
          directory: "/work/notify",
          openCodeVersion: "1.18.18",
          protocolVersion: 1,
        }),
      );
      await firstResult;
      await firstSnapshot;

      const second = await connectPlugin(credential);
      const secondId = randomUUID();
      const secondResult = nextMessage(second);
      const conflictSnapshot = nextMessage(desktop);
      second.send(
        JSON.stringify({
          type: "register",
          instanceId: secondId,
          machine: "devbox",
          project: "notify-copy",
          directory: "/work/notify/",
          openCodeVersion: "1.18.18",
          protocolVersion: 1,
        }),
      );
      expect(await secondResult).toEqual({
        type: "registration",
        instanceId: secondId,
        state: "conflicting",
      });
      expect(await conflictSnapshot).toMatchObject({
        instances: [
          { instanceId: firstId, state: "controllable" },
          { instanceId: secondId, state: "conflicting" },
        ],
      });

      const notification = nextMessage(desktop);
      await postEvent(credential, randomUUID());
      expect(await notification).toMatchObject({ type: "event" });

      const promoted = nextMessage(second);
      const promotedSnapshot = nextMessage(desktop);
      first.close();
      expect(await promoted).toEqual({
        type: "registration",
        instanceId: secondId,
        state: "controllable",
      });
      expect(await promotedSnapshot).toMatchObject({
        instances: [
          { instanceId: firstId, state: "offline" },
          { instanceId: secondId, state: "controllable" },
        ],
      });
    });

    it.each([
      ["1.18.17", 1],
      ["1.18.18", 2],
    ])(
      "reports OpenCode %s / protocol %i as incompatible without breaking notification ingest",
      async (openCodeVersion, protocolVersion) => {
        const alice = await createUser(`incompatible-${protocolVersion}@example.com`);
        const credential = await createIngestCredential(alice.token);
        const desktop = await connect(`Bearer ${alice.token}`);
        const plugin = await connectPlugin(credential);
        const instanceId = randomUUID();
        const registered = nextMessage(plugin);
        const delivered = nextMessage(desktop);
        plugin.send(
          JSON.stringify({
            type: "register",
            instanceId,
            machine: "devbox",
            project: "notify",
            directory: `/work/incompatible-${protocolVersion}`,
            openCodeVersion,
            protocolVersion,
          }),
        );

        expect(await registered).toEqual({
          type: "registration",
          instanceId,
          state: "incompatible",
        });
        expect(await delivered).toMatchObject({
          instances: [{ instanceId, state: "incompatible", openCodeVersion, protocolVersion }],
        });
        await postEvent(credential, randomUUID());
      },
    );

    it("closes control and publishes offline presence when the Plugin key is revoked", async () => {
      const alice = await createUser("presence-revoked@example.com");
      const key = await createPluginKey(alice.token);
      const desktop = await connect(`Bearer ${alice.token}`);
      const plugin = await connectPlugin(key.credential);
      const instanceId = randomUUID();
      const registered = nextMessage(plugin);
      const online = nextMessage(desktop);
      plugin.send(
        JSON.stringify({
          type: "register",
          instanceId,
          machine: "devbox",
          project: "notify",
          directory: "/work/revoked",
          openCodeVersion: "1.18.18",
          protocolVersion: 1,
        }),
      );
      await registered;
      await online;

      const closed = nextClose(plugin);
      const offline = nextMessage(desktop);
      const revoked = await app.inject({
        method: "DELETE",
        url: `/v1/ingest-keys/${key.id}`,
        headers: { authorization: `Bearer ${alice.token}` },
      });
      expect(revoked.statusCode).toBe(204);
      expect(await closed).toBe(4403);
      expect(await offline).toMatchObject({
        instances: [{ instanceId, state: "offline" }],
      });
      expect(await pluginUpgradeFailure(key.credential)).toBe(401);
    });
  });

  describe("heartbeat", () => {
    it("pings connected sockets and keeps them open while they pong", async () => {
      const { token } = await createUser("alice@example.com");
      const ws = await connect(`Bearer ${token}`);

      let pings = 0;
      ws.on("ping", () => {
        pings += 1;
      });
      // The ws client answers pings automatically; several intervals pass.
      await new Promise((resolve) => setTimeout(resolve, TEST_PING_INTERVAL_MS * 4));

      expect(pings).toBeGreaterThanOrEqual(2);
      expect(ws.readyState).toBe(WebSocket.OPEN);
    });

    it("closes a socket that never answers pings", async () => {
      const { token } = await createUser("alice@example.com");
      const ws = await connect(`Bearer ${token}`, { autoPong: false });

      const code = await nextClose(ws);
      // Terminated without a close frame: abnormal closure on the client.
      expect(code).toBe(1006);
    });
  });

  describe("access-token expiry", () => {
    it("closes the socket with 4401 when the presented token reaches exp", async () => {
      const soon = craftToken({
        sub: "user-x",
        iat: Math.floor(T0 / 1000),
        exp: Math.floor(T0 / 1000) + 1,
      });
      const ws = await connect(`Bearer ${soon}`);

      const code = await nextClose(ws);
      expect(code).toBe(WS_CLOSE_TOKEN_EXPIRED);
    });
  });

  describe("disconnect", () => {
    it("replays nothing after a reconnect; only new events arrive", async () => {
      const alice = await createUser("alice@example.com");
      const credential = await createIngestCredential(alice.token);

      const first = await connect(`Bearer ${alice.token}`);
      const firstDelivery = nextMessage(first);
      await postEvent(credential, randomUUID());
      await firstDelivery;
      first.close();
      await nextClose(first);

      // Missed while disconnected: accepted and fanned out to zero sockets.
      const missedId = randomUUID();
      await postEvent(credential, missedId);

      const second = await connect(`Bearer ${alice.token}`);
      await expectSilence(second);

      const nextId = randomUUID();
      const delivery = nextMessage(second);
      await postEvent(credential, nextId);
      const message = (await delivery) as { event: { eventId: string } };
      expect(message.event.eventId).toBe(nextId);
    });
  });

  describe("graceful shutdown", () => {
    it("closes every open socket with 1012 when the app closes", async () => {
      const { token } = await createUser("alice@example.com");
      const ws = await connect(`Bearer ${token}`);

      const closed = nextClose(ws);
      appClosed = true;
      await app.close();

      expect(await closed).toBe(WS_CLOSE_SERVER_SHUTDOWN);
    });
  });
});
