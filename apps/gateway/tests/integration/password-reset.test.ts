import { validateErrorResponse, validateTokenPair } from "@notify/contracts";
import { sql } from "drizzle-orm";
import type { FastifyInstance } from "fastify";
import { afterAll, beforeAll, beforeEach, describe, expect, it } from "vitest";

import { buildServer } from "../../src/app.js";
import { createDb, type GatewayDatabase } from "../../src/db/client.js";
import type { Clock } from "../../src/lib/clock.js";
import type { Mailer } from "../../src/modules/mail/mailer.js";
import { buildTestConfig } from "../helpers/build-test-app.js";
import { TestPostgres } from "../helpers/postgres.js";

const PASSWORD = "correct horse battery staple";
const NEW_PASSWORD = "a completely different passphrase";
const ONE_HOUR_MS = 60 * 60 * 1000;

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
  resetEmails: { to: string; code: string }[] = [];
  failing = false;

  async sendVerificationEmail(to: string, code: string): Promise<void> {
    this.verificationEmails.push({ to, code });
  }

  async sendPasswordResetEmail(to: string, code: string): Promise<void> {
    if (this.failing) {
      throw new Error("SMTP connection refused");
    }
    this.resetEmails.push({ to, code });
  }
}

interface ResetHarness {
  app: FastifyInstance;
  mailer: FakeMailer;
  clock: FakeClock;
}

describe("forgot and reset password", () => {
  let pg: TestPostgres;
  let handle: GatewayDatabase;

  async function buildResetApp(): Promise<ResetHarness> {
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
    await handle.db.execute(
      sql`truncate refresh_tokens, refresh_token_families, password_reset_tokens, email_verification_tokens, users cascade`,
    );
  }

  /** Register and verify an account so login and reset can succeed. */
  async function registerVerified(harness: ResetHarness, email: string): Promise<void> {
    const { app, mailer } = harness;
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
  }

  async function forgot(
    app: FastifyInstance,
    email: string,
  ): Promise<ReturnType<FastifyInstance["inject"]>> {
    return app.inject({
      method: "POST",
      url: "/v1/auth/forgot-password",
      payload: { email },
    });
  }

  async function reset(
    app: FastifyInstance,
    payload: { email: string; code: string; password: string },
  ): Promise<ReturnType<FastifyInstance["inject"]>> {
    return app.inject({ method: "POST", url: "/v1/auth/reset-password", payload });
  }

  type UserRow = { id: string; password_hash: string };

  type ResetTokenRow = {
    token_hash: string;
    expires_at: string;
    consumed_at: string | null;
  };

  async function requireUserRow(email: string): Promise<UserRow> {
    const rows = await handle.db.execute<UserRow>(
      sql`select id, password_hash from users where email = ${email}`,
    );
    if (rows.length === 0) {
      throw new Error(`expected a users row for ${email}`);
    }
    return rows[0];
  }

  async function resetTokenRows(userId: string): Promise<ResetTokenRow[]> {
    const rows = await handle.db.execute<ResetTokenRow>(
      sql`select token_hash, expires_at, consumed_at from password_reset_tokens where user_id = ${userId} order by created_at`,
    );
    return [...rows];
  }

  async function familyRows(userId: string): Promise<{ revoked_at: string | null }[]> {
    const rows = await handle.db.execute<{ revoked_at: string | null }>(
      sql`select revoked_at from refresh_token_families where user_id = ${userId} order by created_at`,
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

  it("emails a one-hour reset code and stores only its SHA-256 hash", async () => {
    const { app, mailer, clock } = await buildResetApp();
    try {
      await registerVerified({ app, mailer, clock }, "alice@example.com");

      const res = await forgot(app, "ALICE@example.com");
      expect(res.statusCode).toBe(204);
      expect(res.body).toBe("");

      expect(mailer.resetEmails).toHaveLength(1);
      const { to, code } = mailer.resetEmails[0];
      expect(to).toBe("alice@example.com");
      expect(code).toMatch(/^[A-Za-z0-9]{8}$/);

      const user = await requireUserRow("alice@example.com");
      const tokens = await resetTokenRows(user.id);
      expect(tokens).toHaveLength(1);
      expect(tokens[0].token_hash).toMatch(/^[0-9a-f]{64}$/);
      expect(tokens[0].token_hash).not.toBe(code);
      expect(tokens[0].consumed_at).toBeNull();
      expect(new Date(tokens[0].expires_at).getTime()).toBe(clock.nowMs() + ONE_HOUR_MS);

      // The plaintext code never reaches the database.
      const raw = await handle.db.execute<{ n: number }>(
        sql`select count(*)::int as n from password_reset_tokens where token_hash = ${code}`,
      );
      expect(raw[0].n).toBe(0);
    } finally {
      await app.close();
    }
  });

  it("answers known and unknown emails with an identical 204 and mails only the known one", async () => {
    const { app, mailer, clock } = await buildResetApp();
    try {
      await registerVerified({ app, mailer, clock }, "alice@example.com");

      const known = await forgot(app, "alice@example.com");
      expect(known.statusCode).toBe(204);
      expect(known.body).toBe("");
      expect(mailer.resetEmails).toHaveLength(1);

      const unknown = await forgot(app, "nobody@example.com");
      expect(unknown.statusCode).toBe(204);
      expect(unknown.body).toBe(known.body);
      expect(mailer.resetEmails).toHaveLength(1);
    } finally {
      await app.close();
    }
  });

  it("still answers 204 when the reset email cannot be delivered", async () => {
    const { app, mailer, clock } = await buildResetApp();
    try {
      await registerVerified({ app, mailer, clock }, "alice@example.com");
      mailer.failing = true;

      const res = await forgot(app, "alice@example.com");
      expect(res.statusCode).toBe(204);
      expect(res.body).toBe("");
    } finally {
      await app.close();
    }
  });

  it("rejects invalid bodies with VALIDATION_FAILED", async () => {
    const { app } = await buildResetApp();
    try {
      const shortPassword = await reset(app, {
        email: "alice@example.com",
        code: "Abcd1234",
        password: "short",
      });
      expect(shortPassword.statusCode).toBe(400);
      expect(shortPassword.json().error.code).toBe("VALIDATION_FAILED");
      expect(validateErrorResponse(shortPassword.json())).toBe(true);

      const badCode = await reset(app, {
        email: "alice@example.com",
        code: "too-short",
        password: NEW_PASSWORD,
      });
      expect(badCode.statusCode).toBe(400);
      expect(badCode.json().error.code).toBe("VALIDATION_FAILED");

      const extra = await app.inject({
        method: "POST",
        url: "/v1/auth/forgot-password",
        payload: { email: "alice@example.com", admin: true },
      });
      expect(extra.statusCode).toBe(400);
      expect(extra.json().error.code).toBe("VALIDATION_FAILED");
    } finally {
      await app.close();
    }
  });

  it("resets the password with the emailed code and replaces the Argon2id hash", async () => {
    const { app, mailer, clock } = await buildResetApp();
    try {
      await registerVerified({ app, mailer, clock }, "alice@example.com");
      const before = await requireUserRow("alice@example.com");

      await forgot(app, "alice@example.com");
      const { code } = mailer.resetEmails[0];

      const res = await reset(app, {
        email: "ALICE@example.com",
        code,
        password: NEW_PASSWORD,
      });
      expect(res.statusCode).toBe(204);
      expect(res.body).toBe("");

      const after = await requireUserRow("alice@example.com");
      expect(after.password_hash).toMatch(/^\$argon2id\$/);
      expect(after.password_hash).not.toBe(before.password_hash);
      expect(after.password_hash).not.toContain(NEW_PASSWORD);

      const tokens = await resetTokenRows(after.id);
      expect(tokens[0].consumed_at).not.toBeNull();

      // The old password is dead; the new one logs in.
      const oldLogin = await app.inject({
        method: "POST",
        url: "/v1/auth/login",
        payload: { email: "alice@example.com", password: PASSWORD },
      });
      expect(oldLogin.statusCode).toBe(401);
      const newLogin = await app.inject({
        method: "POST",
        url: "/v1/auth/login",
        payload: { email: "alice@example.com", password: NEW_PASSWORD },
      });
      expect(newLogin.statusCode).toBe(200);
      expect(validateTokenPair(newLogin.json())).toBe(true);
    } finally {
      await app.close();
    }
  });

  it("rejects wrong codes, unknown emails, and expired codes with the same INVALID_CODE shape", async () => {
    const { app, mailer, clock } = await buildResetApp();
    try {
      await registerVerified({ app, mailer, clock }, "alice@example.com");
      const before = await requireUserRow("alice@example.com");

      await forgot(app, "alice@example.com");
      const { code } = mailer.resetEmails[0];
      const wrong = code === "AAAAAAAA" ? "BBBBBBBB" : "AAAAAAAA";

      const wrongCode = await reset(app, {
        email: "alice@example.com",
        code: wrong,
        password: NEW_PASSWORD,
      });
      expect(wrongCode.statusCode).toBe(400);
      expect(wrongCode.json().error.code).toBe("INVALID_CODE");
      expect(validateErrorResponse(wrongCode.json())).toBe(true);

      const unknownEmail = await reset(app, {
        email: "nobody@example.com",
        code,
        password: NEW_PASSWORD,
      });
      expect(unknownEmail.statusCode).toBe(400);
      expect(unknownEmail.json()).toEqual(wrongCode.json());

      clock.advance(ONE_HOUR_MS + 1_000);
      const expired = await reset(app, {
        email: "alice@example.com",
        code,
        password: NEW_PASSWORD,
      });
      expect(expired.statusCode).toBe(400);
      expect(expired.json()).toEqual(wrongCode.json());

      // Failed attempts changed nothing: password and token are untouched.
      const after = await requireUserRow("alice@example.com");
      expect(after.password_hash).toBe(before.password_hash);
      const tokens = await resetTokenRows(after.id);
      expect(tokens[0].consumed_at).toBeNull();

      // The old password still logs in.
      const login = await app.inject({
        method: "POST",
        url: "/v1/auth/login",
        payload: { email: "alice@example.com", password: PASSWORD },
      });
      expect(login.statusCode).toBe(200);
    } finally {
      await app.close();
    }
  });

  it("consumes the code exactly once, even when two resets race", async () => {
    const { app, mailer, clock } = await buildResetApp();
    try {
      await registerVerified({ app, mailer, clock }, "alice@example.com");
      await forgot(app, "alice@example.com");
      const { code } = mailer.resetEmails[0];

      const ok = await reset(app, {
        email: "alice@example.com",
        code,
        password: NEW_PASSWORD,
      });
      expect(ok.statusCode).toBe(204);

      // Single-use: replaying the consumed code is rejected.
      const replay = await reset(app, {
        email: "alice@example.com",
        code,
        password: "yet another passphrase",
      });
      expect(replay.statusCode).toBe(400);
      expect(replay.json().error.code).toBe("INVALID_CODE");

      // A fresh code, raced concurrently, produces exactly one winner.
      await forgot(app, "alice@example.com");
      const second = mailer.resetEmails[1].code;
      const [a, b] = await Promise.all([
        reset(app, { email: "alice@example.com", code: second, password: "race passphrase one" }),
        reset(app, { email: "alice@example.com", code: second, password: "race passphrase two" }),
      ]);
      const statuses = [a.statusCode, b.statusCode].sort();
      expect(statuses).toEqual([204, 400]);
    } finally {
      await app.close();
    }
  });

  it("revokes every refresh-token family when the reset succeeds", async () => {
    const { app, mailer, clock } = await buildResetApp();
    try {
      await registerVerified({ app, mailer, clock }, "alice@example.com");

      // Two sessions = two families; rotate the first so it holds two tokens.
      const first = await app.inject({
        method: "POST",
        url: "/v1/auth/login",
        payload: { email: "alice@example.com", password: PASSWORD },
      });
      const second = await app.inject({
        method: "POST",
        url: "/v1/auth/login",
        payload: { email: "alice@example.com", password: PASSWORD },
      });
      const rotated = await app.inject({
        method: "POST",
        url: "/v1/auth/refresh",
        payload: { refreshToken: first.json().refreshToken },
      });
      expect(rotated.statusCode).toBe(200);
      const liveTokens = [rotated.json().refreshToken, second.json().refreshToken];

      const user = await requireUserRow("alice@example.com");
      const beforeFamilies = await familyRows(user.id);
      expect(beforeFamilies).toHaveLength(2);
      expect(beforeFamilies.every((family) => family.revoked_at === null)).toBe(true);

      await forgot(app, "alice@example.com");
      const res = await reset(app, {
        email: "alice@example.com",
        code: mailer.resetEmails[0].code,
        password: NEW_PASSWORD,
      });
      expect(res.statusCode).toBe(204);

      // Every family is revoked in the same transaction as the reset.
      const afterFamilies = await familyRows(user.id);
      expect(afterFamilies).toHaveLength(2);
      expect(afterFamilies.every((family) => family.revoked_at !== null)).toBe(true);

      // Every prior refresh token fails, from either family.
      for (const token of liveTokens) {
        const dead = await app.inject({
          method: "POST",
          url: "/v1/auth/refresh",
          payload: { refreshToken: token },
        });
        expect(dead.statusCode).toBe(401);
        expect(validateErrorResponse(dead.json())).toBe(true);
      }

      // The account recovers: the new password starts a fresh family.
      const login = await app.inject({
        method: "POST",
        url: "/v1/auth/login",
        payload: { email: "alice@example.com", password: NEW_PASSWORD },
      });
      expect(login.statusCode).toBe(200);
      const refreshed = await app.inject({
        method: "POST",
        url: "/v1/auth/refresh",
        payload: { refreshToken: login.json().refreshToken },
      });
      expect(refreshed.statusCode).toBe(200);
    } finally {
      await app.close();
    }
  });
});
