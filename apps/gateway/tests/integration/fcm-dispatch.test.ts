import { createHmac } from "node:crypto";

import { getApps } from "firebase-admin/app";
import type { FastifyInstance } from "fastify";
import { afterAll, beforeAll, beforeEach, describe, expect, it } from "vitest";

import { buildServer } from "../../src/app.js";
import { createDb, type GatewayDatabase } from "../../src/db/client.js";
import type { Clock } from "../../src/lib/clock.js";
import type { FcmPush, FcmSender } from "../../src/modules/fcm/fcm-sender.js";
import type { Mailer } from "../../src/modules/mail/mailer.js";
import { CHANNEL_SILENT } from "../../src/modules/fcm/payload.js";
import { buildTestConfig, TEST_FIREBASE_SERVICE_ACCOUNT } from "../helpers/build-test-app.js";
import { TestPostgres } from "../helpers/postgres.js";

const PASSWORD = "correct horse battery staple";
const T0 = 1_800_000_000_000;
const EVENT_ID = "3f6f1e2a-7c3b-4d5e-8f60-1a2b3c4d5e6f";
const DEVICE_TOKEN = "integration-fcm-registration-token";

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

class RecordingFcmSender implements FcmSender {
  sent: FcmPush[] = [];

  async send(push: FcmPush): Promise<void> {
    this.sent.push(push);
  }
}

function sign(secret: string, timestamp: string, rawBody: string): string {
  return createHmac("sha256", secret).update(`${timestamp}.${rawBody}`).digest("hex");
}

function rawActionRequired(eventId: string = EVENT_ID): string {
  return JSON.stringify({
    eventId,
    type: "action_required",
    occurredAt: "2026-08-10T12:00:00.000Z",
    source: { machine: "workstation", project: "notify", directory: "/repo" },
    session: { id: "session-1", title: "Coding" },
    payload: {
      requestId: "req-1",
      kind: "question",
      questions: [{ question: "Deploy to production?" }],
    },
  });
}

function rawHeartbeat(eventId: string): string {
  return JSON.stringify({
    eventId,
    type: "heartbeat",
    occurredAt: "2026-08-10T12:00:00.000Z",
    source: { machine: "workstation", project: "notify", directory: "/repo" },
    session: { id: "session-1", title: "Coding" },
    payload: { status: "busy", elapsedSeconds: 12 },
  });
}

describe("production event dispatch composition", () => {
  let pg: TestPostgres;
  let handle: GatewayDatabase;
  let mailer: FakeMailer;
  let clock: FakeClock;
  const apps: FastifyInstance[] = [];

  async function build(overrides: Parameters<typeof buildServer>[0]): Promise<FastifyInstance> {
    const app = await buildServer({
      config: buildTestConfig({ databaseUrl: pg.databaseUrl }),
      db: handle.db,
      mailer,
      clock,
      ...overrides,
    });
    apps.push(app);
    return app;
  }

  /** Register, verify, login; register an android device; create an ingest key. */
  async function provisionUser(app: FastifyInstance, email: string): Promise<string> {
    const register = await app.inject({
      method: "POST",
      url: "/v1/auth/register",
      payload: { email, password: PASSWORD },
    });
    expect(register.statusCode).toBe(201);
    const { code } = mailer.verificationEmails[mailer.verificationEmails.length - 1];
    await app.inject({ method: "POST", url: "/v1/auth/verify-email", payload: { email, code } });
    const login = await app.inject({
      method: "POST",
      url: "/v1/auth/login",
      payload: { email, password: PASSWORD },
    });
    const token = login.json().accessToken as string;
    const device = await app.inject({
      method: "POST",
      url: "/v1/devices",
      headers: { authorization: `Bearer ${token}` },
      payload: {
        name: "pixel",
        platform: "android",
        fcmToken: DEVICE_TOKEN,
        soundEnabled: false,
      },
    });
    expect(device.statusCode).toBe(201);
    const key = await app.inject({
      method: "POST",
      url: "/v1/ingest-keys",
      headers: { authorization: `Bearer ${token}` },
      payload: { name: "workstation" },
    });
    expect(key.statusCode).toBe(201);
    return key.json().secret as string;
  }

  function postEvent(app: FastifyInstance, credential: string, body: string) {
    const timestamp = String(clock.nowMs());
    const secret = credential.slice(credential.indexOf(".") + 1);
    return app.inject({
      method: "POST",
      url: "/v1/events",
      headers: {
        "content-type": "application/json",
        authorization: `Bearer ${credential}`,
        "x-notify-timestamp": timestamp,
        "x-notify-signature": sign(secret, timestamp, body),
      },
      payload: body,
    });
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

  beforeEach(() => {
    mailer = new FakeMailer();
    clock = new FakeClock(T0);
  });

  it("composes registry + device repository + injected FCM sender when no dispatcher is supplied", async () => {
    const fcm = new RecordingFcmSender();
    const app = await build({ fcmSender: fcm });
    const credential = await provisionUser(app, "compose@example.com");

    const res = await postEvent(app, credential, rawActionRequired());
    expect(res.statusCode).toBe(202);

    expect(fcm.sent).toHaveLength(1);
    const push = fcm.sent[0];
    expect(push.token).toBe(DEVICE_TOKEN);
    expect(push.channelId).toBe(CHANNEL_SILENT); // soundEnabled: false
    expect(push.title).toBe("workstation · repo · Coding · 需要回答");
    const parsed = JSON.parse(push.dataEvent) as { eventId: string; type: string };
    expect(parsed.eventId).toBe(EVENT_ID);
    expect(parsed.type).toBe("action_required");
  });

  it("heartbeat events never reach the FCM sender through the composite", async () => {
    const fcm = new RecordingFcmSender();
    const app = await build({ fcmSender: fcm });
    const credential = await provisionUser(app, "heartbeat@example.com");

    const res = await postEvent(app, credential, rawHeartbeat("7a1f2e3b-4c5d-4e6f-8a9b-0c1d2e3f4a5b"));
    expect(res.statusCode).toBe(202);
    expect(fcm.sent).toHaveLength(0);
  });

  it("injecting fcmSender never initializes a Firebase app (hermetic tests)", async () => {
    const before = getApps().length;
    const app = await build({ fcmSender: new RecordingFcmSender() });
    expect(app).toBeDefined();
    expect(getApps()).toHaveLength(before);
  });

  it("two servers over the same service account share one named Firebase app", async () => {
    const project = `notify-it-${process.pid}`;
    const name = `notify-fcm-${project}`;
    const config = buildTestConfig({
      databaseUrl: pg.databaseUrl,
      firebaseServiceAccountJson: JSON.stringify({
        project_id: project,
        client_email: `firebase-adminsdk@${project}.iam.gserviceaccount.com`,
        private_key: TEST_FIREBASE_SERVICE_ACCOUNT.private_key,
      }),
    });
    // No fcmSender and no eventDispatcher: the real Firebase path.
    const first = await buildServer({ config, db: handle.db, mailer, clock });
    const second = await buildServer({ config, db: handle.db, mailer, clock });
    apps.push(first, second);
    expect(getApps().filter((app) => app.name === name)).toHaveLength(1);
  });
});
