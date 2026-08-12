import { validateErrorResponse, validateHealthStatus } from "@notify/contracts";
import { sql } from "drizzle-orm";
import type { FastifyInstance } from "fastify";
import { afterAll, afterEach, beforeAll, describe, expect, it } from "vitest";
import { WebSocket } from "ws";

import { buildServer } from "../../src/app.js";
import { createDb, type GatewayDatabase } from "../../src/db/client.js";
import type { Clock } from "../../src/lib/clock.js";
import type { Mailer } from "../../src/modules/mail/mailer.js";
import { WS_CLOSE_SERVER_SHUTDOWN } from "../../src/modules/realtime/connection-registry.js";
import type { GracefulShutdown } from "../../src/shutdown.js";
import { buildTestConfig, noopFcmSender } from "../helpers/build-test-app.js";
import { TestPostgres } from "../helpers/postgres.js";

const PASSWORD = "correct horse battery staple";
const T0 = 1_800_000_000_000;

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

  async sendPasswordResetEmail(): Promise<void> {}
}

/** The generic retryable body every readiness failure must answer. */
function expectGeneric503(body: unknown): void {
  expect(validateErrorResponse(body)).toBe(true);
  expect(body).toEqual({
    error: { code: "SERVICE_UNAVAILABLE", message: "Service unavailable" },
  });
}

describe("readiness probe", () => {
  let pg: TestPostgres;
  let handle: GatewayDatabase;
  const apps: FastifyInstance[] = [];

  async function build(overrides: Parameters<typeof buildServer>[0]): Promise<FastifyInstance> {
    const app = await buildServer({
      config: buildTestConfig({ databaseUrl: pg.databaseUrl }),
      db: handle.db,
      fcmSender: noopFcmSender,
      ...overrides,
    });
    apps.push(app);
    return app;
  }

  beforeAll(async () => {
    pg = await TestPostgres.start();
    await pg.migrate();
    handle = createDb(pg.databaseUrl);
  });

  afterAll(async () => {
    for (const app of apps.splice(0)) {
      await app.close();
    }
    await handle.close();
    await pg.stop();
  });

  it("answers 200 with contract health when the database, schema, and Firebase init are ready", async () => {
    const app = await build({});
    const res = await app.inject({ method: "GET", url: "/health/ready" });
    expect(res.statusCode).toBe(200);
    expect(res.json()).toEqual({ status: "ok" });
    expect(validateHealthStatus(res.json())).toBe(true);

    // Repeat probes stay ready and never fail on duplicate Firebase init.
    const again = await app.inject({ method: "GET", url: "/health/ready" });
    expect(again.statusCode).toBe(200);
  });

  it("answers a generic retryable 503 when the app has no database at all", async () => {
    const app = await buildServer({ config: buildTestConfig() });
    apps.push(app);
    const res = await app.inject({ method: "GET", url: "/health/ready" });
    expect(res.statusCode).toBe(503);
    expectGeneric503(res.json());
  });

  it("answers a generic retryable 503 when the database is gone, while liveness stays ok", async () => {
    const doomed = await TestPostgres.start();
    const doomedHandle = createDb(doomed.databaseUrl);
    const app = await build({
      config: buildTestConfig({ databaseUrl: doomed.databaseUrl }),
      db: doomedHandle.db,
    });
    // End the pool: every query rejects immediately (deterministic DB outage).
    await doomedHandle.close();
    await doomed.stop();
    try {
      const ready = await app.inject({ method: "GET", url: "/health/ready" });
      expect(ready.statusCode).toBe(503);
      expectGeneric503(ready.json());

      const live = await app.inject({ method: "GET", url: "/health/live" });
      expect(live.statusCode).toBe(200);
      expect(live.json()).toEqual({ status: "ok" });
    } finally {
      await app.close();
      apps.splice(apps.indexOf(app), 1);
    }
  });

  it("answers 503 against an empty database and never mutates the schema", async () => {
    const empty = await TestPostgres.start();
    const emptyHandle = createDb(empty.databaseUrl);
    const app = await build({
      config: buildTestConfig({ databaseUrl: empty.databaseUrl }),
      db: emptyHandle.db,
    });
    try {
      const res = await app.inject({ method: "GET", url: "/health/ready" });
      expect(res.statusCode).toBe(503);
      expectGeneric503(res.json());

      // Readiness is a probe, not a migrator: no drizzle bookkeeping appears.
      const client = empty.connect({ max: 1 });
      try {
        const schemas = await client`
          select schema_name from information_schema.schemata
          where schema_name = 'drizzle'
        `;
        expect(schemas).toEqual([]);
      } finally {
        await empty.release(client);
      }
    } finally {
      await app.close();
      apps.splice(apps.indexOf(app), 1);
      await emptyHandle.close();
      await empty.stop();
    }
  });

  it("answers 503 when the applied schema is behind the bundled migrations", async () => {
    const app = await build({});
    const baseline = await app.inject({ method: "GET", url: "/health/ready" });
    expect(baseline.statusCode).toBe(200);

    // Simulate a partially applied migration set: drop the bookkeeping row.
    const client = pg.connect({ max: 1 });
    const rows = await client`
      select hash, created_at from drizzle.__drizzle_migrations order by id
    `;
    expect(rows.length).toBeGreaterThan(0);
    await client`delete from drizzle.__drizzle_migrations`;
    try {
      const res = await app.inject({ method: "GET", url: "/health/ready" });
      expect(res.statusCode).toBe(503);
      expectGeneric503(res.json());
    } finally {
      for (const row of rows) {
        await client`
          insert into drizzle.__drizzle_migrations (hash, created_at)
          values (${row.hash as string}, ${row.created_at as number})
        `;
      }
      await pg.release(client);
    }

    const restored = await app.inject({ method: "GET", url: "/health/ready" });
    expect(restored.statusCode).toBe(200);
  });

  it("answers 503 when the Firebase service account cannot initialize", async () => {
    const invalidPem = buildTestConfig({
      databaseUrl: pg.databaseUrl,
      firebaseServiceAccountJson: JSON.stringify({
        project_id: "notify-broken-pem",
        client_email: "firebase-adminsdk@notify-broken-pem.iam.gserviceaccount.com",
        private_key: "not-a-private-key",
      }),
    });
    const app = await build({ config: invalidPem });
    const res = await app.inject({ method: "GET", url: "/health/ready" });
    expect(res.statusCode).toBe(503);
    expectGeneric503(res.json());

    const notJson = await build({
      config: buildTestConfig({
        databaseUrl: pg.databaseUrl,
        firebaseServiceAccountJson: "{ not json",
      }),
    });
    const res2 = await notJson.inject({ method: "GET", url: "/health/ready" });
    expect(res2.statusCode).toBe(503);
    expectGeneric503(res2.json());
  });
});

describe("graceful shutdown", () => {
  let pg: TestPostgres;
  let handle: GatewayDatabase;
  let mailer: FakeMailer;
  let clock: FakeClock;
  const shutdowns: GracefulShutdown[] = [];

  beforeAll(async () => {
    pg = await TestPostgres.start();
    await pg.migrate();
    handle = createDb(pg.databaseUrl);
  });

  afterAll(async () => {
    await pg.stop();
  });

  afterEach(() => {
    for (const shutdown of shutdowns.splice(0)) {
      shutdown.uninstall();
    }
  });

  /** Register, verify, log in; returns the access token. */
  async function createUser(app: FastifyInstance, email: string): Promise<string> {
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

  it("closes sockets with 1012, drains the app, closes the pool, and exits 0", async () => {
    mailer = new FakeMailer();
    clock = new FakeClock(T0);
    const app = await buildServer({
      config: buildTestConfig({ databaseUrl: pg.databaseUrl }),
      db: handle.db,
      mailer,
      clock,
      fcmSender: noopFcmSender,
    });
    await app.listen({ host: "127.0.0.1", port: 0 });
    const address = app.server.address();
    if (address === null || typeof address === "string") {
      throw new Error("expected an ephemeral TCP port");
    }
    const port = address.port;

    const token = await createUser(app, "shutdown@example.com");
    const ws = await new Promise<WebSocket>((resolve, reject) => {
      const client = new WebSocket(`ws://127.0.0.1:${port}/v1/ws`, {
        headers: { authorization: `Bearer ${token}` },
      });
      client.once("open", () => resolve(client));
      client.once("error", reject);
    });
    const closed = new Promise<number>((resolve, reject) => {
      const timer = setTimeout(() => reject(new Error("timed out waiting for close")), 5_000);
      ws.once("close", (code: number) => {
        clearTimeout(timer);
        resolve(code);
      });
    });

    const order: string[] = [];
    const originalClose = app.close.bind(app);
    const observingClose = async (): Promise<void> => {
      order.push("app.close");
      await originalClose();
    };
    app.close = observingClose as typeof app.close;
    let poolClosed = false;
    const { installGracefulShutdown } = await import("../../src/shutdown.js");
    const shutdown = installGracefulShutdown({
      app,
      closeDatabase: async () => {
        order.push("db.close");
        await handle.close();
        poolClosed = true;
      },
      exit: (code) => {
        order.push(`exit:${code}`);
      },
    });
    shutdowns.push(shutdown);

    await shutdown.shutdown();

    // Every open socket got the graceful 1012 (Service Restart) close.
    expect(await closed).toBe(WS_CLOSE_SERVER_SHUTDOWN);
    // Sequence: app drained first, then the pool, then exit 0.
    expect(order).toEqual(["app.close", "db.close", "exit:0"]);
    // The pool is really closed.
    expect(poolClosed).toBe(true);
    await expect(handle.db.execute(sql`select 1`)).rejects.toThrow();
    // The listener is gone: new connections are refused.
    await expect(
      new Promise<void>((resolve, reject) => {
        const socket = new WebSocket(`ws://127.0.0.1:${port}/v1/ws`);
        socket.once("open", () => {
          socket.terminate();
          reject(new Error("server still accepts connections"));
        });
        socket.once("error", () => resolve());
      }),
    ).resolves.toBeUndefined();

    // A repeated shutdown is a no-op: the sequence ran exactly once.
    await shutdown.shutdown();
    expect(order).toEqual(["app.close", "db.close", "exit:0"]);
  });
});
