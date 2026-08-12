import { createHmac } from "node:crypto";
import { Writable } from "node:stream";

import { validateErrorResponse } from "@notify/contracts";
import { sql } from "drizzle-orm";
import type { FastifyInstance } from "fastify";
import { afterAll, beforeAll, beforeEach, describe, expect, it } from "vitest";

import { buildServer } from "../../src/app.js";
import { createDb, type GatewayDatabase } from "../../src/db/client.js";
import type { Clock } from "../../src/lib/clock.js";
import type { FcmSender } from "../../src/modules/fcm/fcm-sender.js";
import { MailerError, type Mailer } from "../../src/modules/mail/mailer.js";
import { buildTestConfig, noopFcmSender } from "../helpers/build-test-app.js";
import { TestPostgres } from "../helpers/postgres.js";

const T0 = 1_800_000_000_000;

/**
 * Unique sentinel values: any appearance in captured logs is a redaction or
 * sanitization failure, and none of them can collide with real log content.
 */
const SENTINELS = {
  email: "sentinel-user-a1b2c3@example.com",
  password: "SENTINEL-PASS-9f0e1d2c",
  smtpCause: "SENTINEL-SMTP-8e7f6a5b",
  fcmToken: "SENTINEL-FCMT-7d6c5b4a",
  question: "SENTINEL-QUES-6c5b4a39",
  permission: "SENTINEL-PERM-5b4a3928",
  provider: "SENTINEL-PROV-4a392817",
  summary: "SENTINEL-SUMM-39281706",
  nestedToken: "SENTINEL-NEST-28170615",
  authHeader: "SENTINEL-AUTH-17061524",
};

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

class FakeClock implements Clock {
  now(): Date {
    return new Date(T0);
  }

  nowMs(): number {
    return T0;
  }
}

/** Delivers verification mail; reset delivery fails with an SMTP sentinel. */
class ResetFailingMailer implements Mailer {
  verificationEmails: { to: string; code: string }[] = [];
  resetEmails: { to: string; code: string }[] = [];

  async sendVerificationEmail(to: string, code: string): Promise<void> {
    this.verificationEmails.push({ to, code });
  }

  async sendPasswordResetEmail(to: string, code: string): Promise<void> {
    this.resetEmails.push({ to, code });
    throw new MailerError("Email delivery failed", {
      cause: new Error(`SMTP 535 authentication failed: ${SENTINELS.smtpCause}`),
    });
  }
}

/** Every delivery fails with an SMTP sentinel embedded in the cause. */
class VerificationFailingMailer implements Mailer {
  verificationEmails: { to: string; code: string }[] = [];

  async sendVerificationEmail(to: string, code: string): Promise<void> {
    this.verificationEmails.push({ to, code });
    throw new MailerError("Email delivery failed", {
      cause: new Error(`SMTP 535 authentication failed: ${SENTINELS.smtpCause}`),
    });
  }

  async sendPasswordResetEmail(): Promise<void> {}
}

function sign(secret: string, timestamp: string, rawBody: string): string {
  return createHmac("sha256", secret).update(`${timestamp}.${rawBody}`).digest("hex");
}

function rawQuestionEvent(eventId: string): string {
  return JSON.stringify({
    eventId,
    type: "action_required",
    occurredAt: "2026-08-10T12:00:00.000Z",
    source: { machine: "workstation", project: "notify", directory: "/repo" },
    session: { id: "session-1", title: "Coding" },
    payload: {
      requestId: "req-1",
      kind: "question",
      questions: [{ question: SENTINELS.question }],
    },
  });
}

function expectNoSentinels(logged: string, extra: string[] = []): void {
  for (const sentinel of [...Object.values(SENTINELS), ...extra]) {
    expect(logged).not.toContain(sentinel);
  }
}

describe("broad log redaction through real routes", () => {
  let pg: TestPostgres;
  let handle: GatewayDatabase;
  const apps: FastifyInstance[] = [];

  async function build(
    mailer: Mailer,
    overrides: Parameters<typeof buildServer>[0] = {},
  ): Promise<{ app: FastifyInstance; output: () => string }> {
    const { stream, output } = captureLogStream();
    const app = await buildServer({
      config: buildTestConfig({ databaseUrl: pg.databaseUrl, logLevel: "info" }),
      loggerStream: stream,
      db: handle.db,
      mailer,
      clock: new FakeClock(),
      ...overrides,
    });
    apps.push(app);
    return { app, output };
  }

  beforeAll(async () => {
    pg = await TestPostgres.start();
    await pg.migrate();
    handle = createDb(pg.databaseUrl);
  });

  beforeEach(async () => {
    await handle.db.execute(
      sql`truncate refresh_tokens, refresh_token_families, password_reset_tokens, email_verification_tokens, devices, ingest_keys, users cascade`,
    );
  });

  afterAll(async () => {
    for (const app of apps.splice(0)) {
      await app.close();
    }
    await handle.close();
    await pg.stop();
  });

  it("verification delivery failure: sanitized warn, retryable 503, no email/code/cause", async () => {
    const mailer = new VerificationFailingMailer();
    const { app, output } = await build(mailer);

    const res = await app.inject({
      method: "POST",
      url: "/v1/auth/register",
      payload: { email: SENTINELS.email, password: SENTINELS.password },
    });
    expect(res.statusCode).toBe(503);
    expect(validateErrorResponse(res.json())).toBe(true);
    expect(res.json().error.code).toBe("SERVICE_UNAVAILABLE");

    const logged = output();
    expect(logged).toContain("verification email delivery failed");
    expect(mailer.verificationEmails).toHaveLength(1);
    // The plaintext code really existed — and still never reached the logs.
    expectNoSentinels(logged, [mailer.verificationEmails[0].code]);
  });

  it("password reset delivery failure: sanitized warn, uniform 204, no email/code/cause", async () => {
    const mailer = new ResetFailingMailer();
    const { app, output } = await build(mailer);
    const register = await app.inject({
      method: "POST",
      url: "/v1/auth/register",
      payload: { email: SENTINELS.email, password: SENTINELS.password },
    });
    expect(register.statusCode).toBe(201);

    const res = await app.inject({
      method: "POST",
      url: "/v1/auth/forgot-password",
      payload: { email: SENTINELS.email },
    });
    // Delivery failure stays invisible to the caller (anti-enumeration 204).
    expect(res.statusCode).toBe(204);

    const logged = output();
    expect(logged).toContain("password reset email delivery failed");
    expect(mailer.resetEmails).toHaveLength(1);
    expectNoSentinels(logged, [mailer.resetEmails[0].code]);
  });

  it("FCM failure through the real ingest route never logs token, content, or credentials", async () => {
    // Like real firebase errors, the transport error embeds the device token.
    const fcmSender: FcmSender = {
      async send(): Promise<void> {
        throw Object.assign(
          new Error(`send failed for registration token ${SENTINELS.fcmToken}`),
          { code: "messaging/internal-error" },
        );
      },
    };
    const mailer = new ResetFailingMailer();
    const { app, output } = await build(mailer, { fcmSender });

    const credential = await provisionDeviceAndKey(app, mailer);
    const body = rawQuestionEvent("11111111-2222-4333-8444-555555555555");
    const timestamp = String(T0);
    const secret = credential.slice(credential.indexOf(".") + 1);
    const signature = sign(secret, timestamp, body);
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
    // Per-device FCM failures are isolated: ingest still succeeds.
    expect(res.statusCode).toBe(202);

    const logged = output();
    // The failure was logged (sanitized), not swallowed.
    expect(logged).toContain("messaging/internal-error");
    expectNoSentinels(logged, [credential, secret, signature]);
  });

  it("ingest dispatch failure: retryable 503 with no credentials or content in logs", async () => {
    const mailer = new ResetFailingMailer();
    const { app, output } = await build(mailer, {
      eventDispatcher: {
        async dispatch(): Promise<void> {
          throw new Error("database connection terminated unexpectedly");
        },
      },
    });

    const credential = await provisionDeviceAndKey(app, mailer);
    const body = rawQuestionEvent("66666666-7777-4888-8999-000000000000");
    const timestamp = String(T0);
    const secret = credential.slice(credential.indexOf(".") + 1);
    const signature = sign(secret, timestamp, body);
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
    expect(res.statusCode).toBe(503);
    expect(validateErrorResponse(res.json())).toBe(true);
    expect(res.json().error.code).toBe("SERVICE_UNAVAILABLE");

    const logged = output();
    expect(logged).toContain("event dispatch failed");
    expectNoSentinels(logged, [credential, secret, signature]);
  });

  /** Register + verify + login + device (sentinel FCM token) + ingest key. */
  async function provisionDeviceAndKey(
    app: FastifyInstance,
    mailer: ResetFailingMailer,
  ): Promise<string> {
    const register = await app.inject({
      method: "POST",
      url: "/v1/auth/register",
      payload: { email: SENTINELS.email, password: SENTINELS.password },
    });
    expect(register.statusCode).toBe(201);
    const { code } = mailer.verificationEmails[mailer.verificationEmails.length - 1];
    const verify = await app.inject({
      method: "POST",
      url: "/v1/auth/verify-email",
      payload: { email: SENTINELS.email, code },
    });
    expect(verify.statusCode).toBe(204);
    const login = await app.inject({
      method: "POST",
      url: "/v1/auth/login",
      payload: { email: SENTINELS.email, password: SENTINELS.password },
    });
    expect(login.statusCode).toBe(200);
    const token = login.json().accessToken as string;
    const device = await app.inject({
      method: "POST",
      url: "/v1/devices",
      headers: { authorization: `Bearer ${token}` },
      payload: {
        name: "pixel",
        platform: "android",
        fcmToken: SENTINELS.fcmToken,
        soundEnabled: true,
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
});

describe("redaction of nested sensitive fields", () => {
  it("redacts credentials, tokens, and event content at any logged depth", async () => {
    const { stream, output } = captureLogStream();
    const app = await buildServer({
      config: buildTestConfig({ logLevel: "info" }),
      loggerStream: stream,
    });
    app.post("/_probe-nested", async (request) => {
      request.log.info(
        {
          // Depth 2: credentials under a wrapper object.
          context: {
            password: SENTINELS.password,
            signature: SENTINELS.smtpCause,
          },
          // Depth 3: an event envelope logged inside an error context.
          details: {
            event: {
              payload: {
                questions: SENTINELS.question,
                permission: SENTINELS.permission,
                providerAction: SENTINELS.provider,
                summary: SENTINELS.summary,
              },
              fcmToken: SENTINELS.fcmToken,
            },
          },
          // Depth 4: a stray token deep in an arbitrary structure.
          outer: { middle: { inner: { token: SENTINELS.nestedToken } } },
        },
        "nested probe",
      );
      return { status: "ok" };
    });

    const res = await app.inject({
      method: "POST",
      url: "/_probe-nested",
      headers: { authorization: `Bearer ${SENTINELS.authHeader}` },
    });
    expect(res.statusCode).toBe(200);
    await app.close();

    const logged = output();
    // Guard against a vacuous pass: the probe logged and redaction ran.
    expect(logged).toContain("nested probe");
    expect(logged).toContain("[redacted]");
    expectNoSentinels(logged);
  });
});

describe("server error responses", () => {
  async function buildWithProbes(): Promise<FastifyInstance> {
    const { AppError } = await import("../../src/lib/errors.js");
    const app = await buildServer({ config: buildTestConfig() });
    app.get("/_probe-503", async () => {
      throw new AppError(`backend at ${SENTINELS.smtpCause} exploded`, 503);
    });
    app.get("/_probe-500", async () => {
      throw new AppError("sensitive internal detail", 500);
    });
    app.get("/_probe-plain", async () => {
      throw new Error("plain failure detail");
    });
    return app;
  }

  it("a genuine 503 keeps its status with a generic SERVICE_UNAVAILABLE body", async () => {
    const app = await buildWithProbes();
    try {
      const res = await app.inject({ method: "GET", url: "/_probe-503" });
      expect(res.statusCode).toBe(503);
      expect(validateErrorResponse(res.json())).toBe(true);
      expect(res.json()).toEqual({
        error: { code: "SERVICE_UNAVAILABLE", message: "Service unavailable" },
      });
    } finally {
      await app.close();
    }
  });

  it("a genuine 500 AppError answers a generic INTERNAL body", async () => {
    const app = await buildWithProbes();
    try {
      const res = await app.inject({ method: "GET", url: "/_probe-500" });
      expect(res.statusCode).toBe(500);
      expect(res.json()).toEqual({
        error: { code: "INTERNAL", message: "Internal server error" },
      });
    } finally {
      await app.close();
    }
  });

  it("a plain error answers 500 INTERNAL with no internals in the body", async () => {
    const app = await buildWithProbes();
    try {
      const res = await app.inject({ method: "GET", url: "/_probe-plain" });
      expect(res.statusCode).toBe(500);
      expect(res.json()).toEqual({
        error: { code: "INTERNAL", message: "Internal server error" },
      });
    } finally {
      await app.close();
    }
  });
});
