import { validateErrorResponse } from "@notify/contracts";
import { sql } from "drizzle-orm";
import type { FastifyInstance } from "fastify";
import { afterAll, beforeAll, beforeEach, describe, expect, it } from "vitest";

import { buildServer } from "../../src/app.js";
import { createDb, type GatewayDatabase } from "../../src/db/client.js";
import type { Clock } from "../../src/lib/clock.js";
import type { Mailer } from "../../src/modules/mail/mailer.js";
import { buildTestConfig } from "../helpers/build-test-app.js";
import { TestPostgres } from "../helpers/postgres.js";

const TWENTY_FOUR_HOURS_MS = 24 * 60 * 60 * 1000;
const PASSWORD = "correct horse battery staple";

class FakeClock implements Clock {
  nowMsValue = 1_700_000_000_000;

  now(): Date {
    return new Date(this.nowMsValue);
  }

  nowMs(): number {
    return this.nowMsValue;
  }

  advance(ms: number): void {
    this.nowMsValue += ms;
  }
}

class FakeMailer implements Mailer {
  verificationEmails: { to: string; code: string }[] = [];
  failing = false;

  async sendVerificationEmail(to: string, code: string): Promise<void> {
    if (this.failing) {
      throw new Error("SMTP connection refused");
    }
    this.verificationEmails.push({ to, code });
  }

  async sendPasswordResetEmail(): Promise<void> {
    throw new Error("not implemented in this fake");
  }
}

interface AuthHarness {
  app: FastifyInstance;
  mailer: FakeMailer;
  clock: FakeClock;
}

describe("registration and email verification", () => {
  let pg: TestPostgres;
  let handle: GatewayDatabase;

  async function buildAuthApp(): Promise<AuthHarness> {
    const mailer = new FakeMailer();
    const clock = new FakeClock();
    const app = await buildServer({
      config: buildTestConfig({ databaseUrl: pg.databaseUrl }),
      db: handle.db,
      mailer,
      clock,
    });
    return { app, mailer, clock };
  }

  async function cleanup(): Promise<void> {
    // Both tables cascade from users, but truncate them explicitly anyway.
    await handle.db.execute(sql`truncate email_verification_tokens, users cascade`);
  }

  type UserRow = {
    id: string;
    email: string;
    password_hash: string;
    email_verified_at: string | null;
  };

  type TokenRow = {
    token_hash: string;
    // Raw driver rows: timestamptz arrives as a timestamp string.
    expires_at: string;
    consumed_at: string | null;
  };

  async function userRow(email: string): Promise<UserRow | null> {
    const rows = await handle.db.execute<UserRow>(
      sql`select id, email, password_hash, email_verified_at from users where email = ${email}`,
    );
    return rows[0] ?? null;
  }

  /** userRow plus an assertion that the row exists; narrows away null. */
  async function requireUserRow(email: string): Promise<UserRow> {
    const user = await userRow(email);
    if (user === null) {
      throw new Error(`expected a users row for ${email}`);
    }
    return user;
  }

  async function tokenRows(userId: string): Promise<TokenRow[]> {
    const rows = await handle.db.execute<TokenRow>(
      sql`select token_hash, expires_at, consumed_at from email_verification_tokens where user_id = ${userId} order by created_at`,
    );
    return [...rows];
  }

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
    await cleanup();
  });

  it("registers an account, normalizes the email, and stores only hashes", async () => {
    const { app, mailer, clock } = await buildAuthApp();
    try {
      const res = await app.inject({
        method: "POST",
        url: "/v1/auth/register",
        payload: { email: "Alice@Example.COM", password: PASSWORD },
      });
      expect(res.statusCode).toBe(201);
      expect(res.body).toBe("");

      const user = await requireUserRow("alice@example.com");
      expect(user.password_hash).toMatch(/^\$argon2id\$/);
      expect(user.password_hash).not.toContain(PASSWORD);
      expect(user.email_verified_at).toBeNull();

      expect(mailer.verificationEmails).toHaveLength(1);
      const { to, code } = mailer.verificationEmails[0];
      expect(to).toBe("alice@example.com");
      expect(code).toMatch(/^[A-Za-z0-9]{8}$/);

      const tokens = await tokenRows(user.id);
      expect(tokens).toHaveLength(1);
      expect(tokens[0].token_hash).toMatch(/^[0-9a-f]{64}$/);
      expect(tokens[0].token_hash).not.toBe(code);
      expect(tokens[0].consumed_at).toBeNull();
      const expiresMs = new Date(tokens[0].expires_at).getTime();
      expect(expiresMs).toBe(clock.nowMs() + TWENTY_FOUR_HOURS_MS);
    } finally {
      await app.close();
    }
  });

  it("rejects a duplicate email under case variants with the 409 contract shape", async () => {
    const { app } = await buildAuthApp();
    try {
      const first = await app.inject({
        method: "POST",
        url: "/v1/auth/register",
        payload: { email: "alice@example.com", password: PASSWORD },
      });
      expect(first.statusCode).toBe(201);

      const dupe = await app.inject({
        method: "POST",
        url: "/v1/auth/register",
        payload: { email: "ALICE@Example.com", password: PASSWORD },
      });
      expect(dupe.statusCode).toBe(409);
      expect(dupe.json().error.code).toBe("EMAIL_TAKEN");
      expect(validateErrorResponse(dupe.json())).toBe(true);
    } finally {
      await app.close();
    }
  });

  it("rejects invalid bodies with VALIDATION_FAILED", async () => {
    const { app } = await buildAuthApp();
    try {
      const shortPassword = await app.inject({
        method: "POST",
        url: "/v1/auth/register",
        payload: { email: "alice@example.com", password: "short" },
      });
      expect(shortPassword.statusCode).toBe(400);
      expect(shortPassword.json().error.code).toBe("VALIDATION_FAILED");
      expect(validateErrorResponse(shortPassword.json())).toBe(true);

      const extra = await app.inject({
        method: "POST",
        url: "/v1/auth/register",
        payload: { email: "alice@example.com", password: PASSWORD, admin: true },
      });
      expect(extra.statusCode).toBe(400);
      expect(extra.json().error.code).toBe("VALIDATION_FAILED");

      const badCode = await app.inject({
        method: "POST",
        url: "/v1/auth/verify-email",
        payload: { email: "alice@example.com", code: "too-short" },
      });
      expect(badCode.statusCode).toBe(400);
      expect(badCode.json().error.code).toBe("VALIDATION_FAILED");
    } finally {
      await app.close();
    }
  });

  it("verifies the account with the emailed code, exactly once", async () => {
    const { app, mailer } = await buildAuthApp();
    try {
      await app.inject({
        method: "POST",
        url: "/v1/auth/register",
        payload: { email: "alice@example.com", password: PASSWORD },
      });
      const { code } = mailer.verificationEmails[0];

      const ok = await app.inject({
        method: "POST",
        url: "/v1/auth/verify-email",
        payload: { email: "alice@example.com", code },
      });
      expect(ok.statusCode).toBe(204);
      expect(ok.body).toBe("");

      const user = await requireUserRow("alice@example.com");
      expect(user.email_verified_at).not.toBeNull();
      const tokens = await tokenRows(user.id);
      expect(tokens[0].consumed_at).not.toBeNull();

      // Single-use: replaying the consumed code is rejected.
      const replay = await app.inject({
        method: "POST",
        url: "/v1/auth/verify-email",
        payload: { email: "alice@example.com", code },
      });
      expect(replay.statusCode).toBe(400);
      expect(replay.json().error.code).toBe("INVALID_CODE");
      expect(validateErrorResponse(replay.json())).toBe(true);
    } finally {
      await app.close();
    }
  });

  it("allows exactly one winner when two verifications race for the same code", async () => {
    const { app, mailer } = await buildAuthApp();
    try {
      await app.inject({
        method: "POST",
        url: "/v1/auth/register",
        payload: { email: "alice@example.com", password: PASSWORD },
      });
      const { code } = mailer.verificationEmails[0];

      const [a, b] = await Promise.all([
        app.inject({
          method: "POST",
          url: "/v1/auth/verify-email",
          payload: { email: "alice@example.com", code },
        }),
        app.inject({
          method: "POST",
          url: "/v1/auth/verify-email",
          payload: { email: "alice@example.com", code },
        }),
      ]);
      const statuses = [a.statusCode, b.statusCode].sort();
      expect(statuses).toEqual([204, 400]);

      const user = await requireUserRow("alice@example.com");
      expect(user.email_verified_at).not.toBeNull();
    } finally {
      await app.close();
    }
  });

  it("rejects wrong codes and unknown emails with the same INVALID_CODE shape", async () => {
    const { app, mailer } = await buildAuthApp();
    try {
      await app.inject({
        method: "POST",
        url: "/v1/auth/register",
        payload: { email: "alice@example.com", password: PASSWORD },
      });
      const { code } = mailer.verificationEmails[0];
      const wrong = code === "AAAAAAAA" ? "BBBBBBBB" : "AAAAAAAA";

      const wrongCode = await app.inject({
        method: "POST",
        url: "/v1/auth/verify-email",
        payload: { email: "alice@example.com", code: wrong },
      });
      expect(wrongCode.statusCode).toBe(400);
      expect(wrongCode.json().error.code).toBe("INVALID_CODE");

      const unknown = await app.inject({
        method: "POST",
        url: "/v1/auth/verify-email",
        payload: { email: "nobody@example.com", code: wrong },
      });
      expect(unknown.statusCode).toBe(400);
      expect(unknown.json().error.code).toBe("INVALID_CODE");
      expect(unknown.json()).toEqual(wrongCode.json());

      // The real code is unaffected by failed attempts.
      const ok = await app.inject({
        method: "POST",
        url: "/v1/auth/verify-email",
        payload: { email: "alice@example.com", code },
      });
      expect(ok.statusCode).toBe(204);
    } finally {
      await app.close();
    }
  });

  it("rejects an expired code and accepts a resent one", async () => {
    const { app, mailer, clock } = await buildAuthApp();
    try {
      await app.inject({
        method: "POST",
        url: "/v1/auth/register",
        payload: { email: "alice@example.com", password: PASSWORD },
      });
      const { code } = mailer.verificationEmails[0];

      clock.advance(TWENTY_FOUR_HOURS_MS + 1_000);
      const expired = await app.inject({
        method: "POST",
        url: "/v1/auth/verify-email",
        payload: { email: "alice@example.com", code },
      });
      expect(expired.statusCode).toBe(400);
      expect(expired.json().error.code).toBe("INVALID_CODE");

      const resend = await app.inject({
        method: "POST",
        url: "/v1/auth/resend-verification",
        payload: { email: "alice@example.com" },
      });
      expect(resend.statusCode).toBe(204);
      expect(mailer.verificationEmails).toHaveLength(2);

      const ok = await app.inject({
        method: "POST",
        url: "/v1/auth/verify-email",
        payload: { email: "alice@example.com", code: mailer.verificationEmails[1].code },
      });
      expect(ok.statusCode).toBe(204);
    } finally {
      await app.close();
    }
  });

  it("returns a retryable 503 when SMTP fails and keeps the account unverified", async () => {
    const { app, mailer } = await buildAuthApp();
    try {
      mailer.failing = true;
      const res = await app.inject({
        method: "POST",
        url: "/v1/auth/register",
        payload: { email: "alice@example.com", password: PASSWORD },
      });
      expect(res.statusCode).toBe(503);
      expect(res.json().error.code).toBe("SERVICE_UNAVAILABLE");
      expect(validateErrorResponse(res.json())).toBe(true);
      // The safe error never echoes SMTP internals.
      expect(JSON.stringify(res.json())).not.toContain("SMTP connection refused");

      const user = await requireUserRow("alice@example.com");
      expect(user.email_verified_at).toBeNull();

      // The user can resend once SMTP recovers.
      mailer.failing = false;
      const resend = await app.inject({
        method: "POST",
        url: "/v1/auth/resend-verification",
        payload: { email: "alice@example.com" },
      });
      expect(resend.statusCode).toBe(204);
      expect(mailer.verificationEmails).toHaveLength(1);

      const ok = await app.inject({
        method: "POST",
        url: "/v1/auth/verify-email",
        payload: { email: "alice@example.com", code: mailer.verificationEmails[0].code },
      });
      expect(ok.statusCode).toBe(204);
    } finally {
      await app.close();
    }
  });

  it("resends silently for unknown emails and verified accounts (no enumeration)", async () => {
    const { app, mailer } = await buildAuthApp();
    try {
      const unknown = await app.inject({
        method: "POST",
        url: "/v1/auth/resend-verification",
        payload: { email: "nobody@example.com" },
      });
      expect(unknown.statusCode).toBe(204);
      expect(unknown.body).toBe("");
      expect(mailer.verificationEmails).toHaveLength(0);

      await app.inject({
        method: "POST",
        url: "/v1/auth/register",
        payload: { email: "alice@example.com", password: PASSWORD },
      });
      const { code } = mailer.verificationEmails[0];
      await app.inject({
        method: "POST",
        url: "/v1/auth/verify-email",
        payload: { email: "alice@example.com", code },
      });

      const verified = await app.inject({
        method: "POST",
        url: "/v1/auth/resend-verification",
        payload: { email: "alice@example.com" },
      });
      expect(verified.statusCode).toBe(204);
      expect(verified.body).toBe("");
      // No second mail: the resend count stays at the registration mail.
      expect(mailer.verificationEmails).toHaveLength(1);
    } finally {
      await app.close();
    }
  });
});
