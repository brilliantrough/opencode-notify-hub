import { validateErrorResponse, validateTokenPair } from "@notify/contracts";
import { sql } from "drizzle-orm";
import type { FastifyInstance } from "fastify";
import { afterAll, beforeAll, beforeEach, describe, expect, it } from "vitest";

import { buildServer } from "../../src/app.js";
import { createDb, type GatewayDatabase } from "../../src/db/client.js";
import type { Clock } from "../../src/lib/clock.js";
import { sha256Hex } from "../../src/lib/crypto.js";
import type { Mailer } from "../../src/modules/mail/mailer.js";
import { buildTestConfig, TEST_JWT_SIGNING_KEY } from "../helpers/build-test-app.js";
import { TestPostgres } from "../helpers/postgres.js";
import { createAccessTokens } from "../../src/plugins/jwt.js";

const PASSWORD = "correct horse battery staple";
const THIRTY_DAYS_MS = 30 * 24 * 60 * 60 * 1000;
const NINE_HUNDRED_SECONDS_MS = 900 * 1000;

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

  async sendVerificationEmail(to: string, code: string): Promise<void> {
    this.verificationEmails.push({ to, code });
  }

  async sendPasswordResetEmail(): Promise<void> {
    throw new Error("not implemented in this fake");
  }
}

interface TokenHarness {
  app: FastifyInstance;
  mailer: FakeMailer;
  clock: FakeClock;
}

interface DecodedJwt {
  header: Record<string, unknown>;
  payload: Record<string, unknown>;
}

function decodeJwt(token: string): DecodedJwt {
  const parts = token.split(".");
  if (parts.length !== 3) {
    throw new Error(`expected a compact JWT, got ${parts.length} parts`);
  }
  return {
    header: JSON.parse(Buffer.from(parts[0], "base64url").toString("utf8")),
    payload: JSON.parse(Buffer.from(parts[1], "base64url").toString("utf8")),
  };
}

describe("login, refresh rotation, and logout", () => {
  let pg: TestPostgres;
  let handle: GatewayDatabase;

  async function buildTokenApp(): Promise<TokenHarness> {
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
      sql`truncate refresh_tokens, refresh_token_families, email_verification_tokens, users cascade`,
    );
  }

  /** Register and verify an account so login can succeed. */
  async function registerVerified(harness: TokenHarness, email: string): Promise<void> {
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

  async function login(
    app: FastifyInstance,
    email: string,
    password: string = PASSWORD,
  ): Promise<{ statusCode: number; body: { accessToken: string; refreshToken: string } }> {
    const res = await app.inject({
      method: "POST",
      url: "/v1/auth/login",
      payload: { email, password },
    });
    return { statusCode: res.statusCode, body: res.json() };
  }

  async function refresh(
    app: FastifyInstance,
    refreshToken: string,
  ): Promise<ReturnType<FastifyInstance["inject"]>> {
    return app.inject({
      method: "POST",
      url: "/v1/auth/refresh",
      payload: { refreshToken },
    });
  }

  type RefreshTokenRow = {
    token_hash: string;
    rotated_at: string | null;
    expires_at: string;
  };

  type FamilyRow = { revoked_at: string | null };

  async function tokenRowByHash(tokenHash: string): Promise<RefreshTokenRow | null> {
    const rows = await handle.db.execute<RefreshTokenRow>(
      sql`select token_hash, rotated_at, expires_at from refresh_tokens where token_hash = ${tokenHash}`,
    );
    return rows[0] ?? null;
  }

  async function familyRows(): Promise<FamilyRow[]> {
    const rows = await handle.db.execute<FamilyRow>(
      sql`select revoked_at from refresh_token_families`,
    );
    return [...rows];
  }

  async function userIdByEmail(email: string): Promise<string> {
    const rows = await handle.db.execute<{ id: string }>(
      sql`select id from users where email = ${email}`,
    );
    return rows[0].id;
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

  it("logs in with a verified account and returns a 900-second access token pair", async () => {
    const harness = await buildTokenApp();
    const { app, clock } = harness;
    try {
      await registerVerified(harness, "alice@example.com");

      const { statusCode, body } = await login(app, "ALICE@example.com");
      expect(statusCode).toBe(200);
      expect(validateTokenPair(body)).toBe(true);

      // Access token: HS256 compact JWT carrying the user id and exactly
      // 900 seconds between iat and exp.
      const { header, payload } = decodeJwt(body.accessToken);
      expect(header.alg).toBe("HS256");
      expect(header.typ).toBe("JWT");
      expect(payload.sub).toBe(await userIdByEmail("alice@example.com"));
      expect(typeof payload.iat).toBe("number");
      expect(payload.iat).toBe(Math.floor(clock.nowMs() / 1000));
      expect(payload.exp).toBe((payload.iat as number) + 900);

      // Refresh token: 32-byte opaque base64url (43 chars), stored only as
      // its SHA-256 hash with a 30-day expiry, inside a fresh family.
      expect(body.refreshToken).toMatch(/^[A-Za-z0-9_-]{43}$/);
      const row = await tokenRowByHash(sha256Hex(body.refreshToken));
      expect(row).not.toBeNull();
      expect(row!.rotated_at).toBeNull();
      expect(row!.token_hash).not.toBe(body.refreshToken);
      expect(new Date(row!.expires_at).getTime()).toBe(clock.nowMs() + THIRTY_DAYS_MS);
      const rawLookup = await tokenRowByHash(body.refreshToken);
      expect(rawLookup).toBeNull();
      expect(await familyRows()).toHaveLength(1);
    } finally {
      await app.close();
    }
  });

  it("answers wrong passwords and unknown emails with an identical 401", async () => {
    const harness = await buildTokenApp();
    const { app } = harness;
    try {
      await registerVerified(harness, "alice@example.com");

      const wrongPassword = await app.inject({
        method: "POST",
        url: "/v1/auth/login",
        payload: { email: "alice@example.com", password: "wrong password" },
      });
      expect(wrongPassword.statusCode).toBe(401);
      expect(wrongPassword.json().error.code).toBe("INVALID_CREDENTIALS");
      expect(validateErrorResponse(wrongPassword.json())).toBe(true);

      const unknownEmail = await app.inject({
        method: "POST",
        url: "/v1/auth/login",
        payload: { email: "nobody@example.com", password: PASSWORD },
      });
      expect(unknownEmail.statusCode).toBe(401);
      // Byte-identical body: the response cannot enumerate accounts.
      expect(unknownEmail.json()).toEqual(wrongPassword.json());

      // No session artifacts were created by the failed attempts.
      expect(await familyRows()).toHaveLength(0);
    } finally {
      await app.close();
    }
  });

  it("rejects an unverified account with an explicit 403 and issues no tokens", async () => {
    const harness = await buildTokenApp();
    const { app, mailer } = harness;
    try {
      const register = await app.inject({
        method: "POST",
        url: "/v1/auth/register",
        payload: { email: "alice@example.com", password: PASSWORD },
      });
      expect(register.statusCode).toBe(201);
      expect(mailer.verificationEmails).toHaveLength(1);

      const res = await app.inject({
        method: "POST",
        url: "/v1/auth/login",
        payload: { email: "alice@example.com", password: PASSWORD },
      });
      expect(res.statusCode).toBe(403);
      expect(res.json().error.code).toBe("EMAIL_UNVERIFIED");
      expect(validateErrorResponse(res.json())).toBe(true);

      expect(await familyRows()).toHaveLength(0);
    } finally {
      await app.close();
    }
  });

  it("rotates the refresh token on every refresh", async () => {
    const harness = await buildTokenApp();
    const { app, clock } = harness;
    try {
      await registerVerified(harness, "alice@example.com");
      const first = await login(app, "alice@example.com");

      const rotated = await refresh(app, first.body.refreshToken);
      expect(rotated.statusCode).toBe(200);
      const second = rotated.json();
      expect(validateTokenPair(second)).toBe(true);
      expect(second.refreshToken).not.toBe(first.body.refreshToken);
      expect(decodeJwt(second.accessToken).payload.sub).toBe(
        await userIdByEmail("alice@example.com"),
      );

      // The old token is marked rotated; the successor is live in the same family.
      const oldRow = await tokenRowByHash(sha256Hex(first.body.refreshToken));
      expect(oldRow!.rotated_at).not.toBeNull();
      const newRow = await tokenRowByHash(sha256Hex(second.refreshToken));
      expect(newRow!.rotated_at).toBeNull();
      expect(new Date(newRow!.expires_at).getTime()).toBe(clock.nowMs() + THIRTY_DAYS_MS);
      expect(await familyRows()).toHaveLength(1);

      // The successor refreshes again: rotation chains.
      clock.advance(60_000);
      const third = await refresh(app, second.refreshToken);
      expect(third.statusCode).toBe(200);
      expect(third.json().refreshToken).not.toBe(second.refreshToken);
    } finally {
      await app.close();
    }
  });

  it("revokes the whole family when a rotated token is replayed, killing the successor too", async () => {
    const harness = await buildTokenApp();
    const { app } = harness;
    try {
      await registerVerified(harness, "alice@example.com");
      const first = await login(app, "alice@example.com");
      const rotated = await refresh(app, first.body.refreshToken);
      expect(rotated.statusCode).toBe(200);
      const successor = rotated.json().refreshToken;

      // Replay of the already-rotated token = reuse detection.
      const replay = await refresh(app, first.body.refreshToken);
      expect(replay.statusCode).toBe(401);
      expect(replay.json().error.code).toBe("REFRESH_REUSED");
      expect(validateErrorResponse(replay.json())).toBe(true);

      const families = await familyRows();
      expect(families).toHaveLength(1);
      expect(families[0].revoked_at).not.toBeNull();

      // The legitimately rotated successor is dead too.
      const dead = await refresh(app, successor);
      expect(dead.statusCode).toBe(401);
      expect(dead.json().error.code).toBe("REFRESH_REUSED");
    } finally {
      await app.close();
    }
  });

  it("lets exactly one of two concurrent refreshes win, then revokes the family", async () => {
    const harness = await buildTokenApp();
    const { app } = harness;
    try {
      await registerVerified(harness, "alice@example.com");
      const first = await login(app, "alice@example.com");

      const [a, b] = await Promise.all([
        refresh(app, first.body.refreshToken),
        refresh(app, first.body.refreshToken),
      ]);
      const byStatus = [a, b].sort((x, y) => x.statusCode - y.statusCode);
      expect(byStatus[0].statusCode).toBe(200);
      expect(byStatus[1].statusCode).toBe(401);
      expect(byStatus[1].json().error.code).toBe("REFRESH_REUSED");

      const families = await familyRows();
      expect(families[0].revoked_at).not.toBeNull();

      // Even the winner's freshly issued token is unusable: the losing
      // transaction revoked the family it belongs to.
      const winnerToken = byStatus[0].json().refreshToken;
      const after = await refresh(app, winnerToken);
      expect(after.statusCode).toBe(401);
      expect(after.json().error.code).toBe("REFRESH_REUSED");
    } finally {
      await app.close();
    }
  });

  it("rejects expired and unknown refresh tokens", async () => {
    const harness = await buildTokenApp();
    const { app, clock } = harness;
    try {
      await registerVerified(harness, "alice@example.com");
      const first = await login(app, "alice@example.com");

      clock.advance(THIRTY_DAYS_MS + 1_000);
      const expired = await refresh(app, first.body.refreshToken);
      expect(expired.statusCode).toBe(401);
      expect(validateErrorResponse(expired.json())).toBe(true);

      const unknown = await refresh(app, "not-a-real-token");
      expect(unknown.statusCode).toBe(401);
      expect(unknown.json()).toEqual(expired.json());

      // Expiry is not reuse: the family is untouched and unrevoked.
      const families = await familyRows();
      expect(families[0].revoked_at).toBeNull();
    } finally {
      await app.close();
    }
  });

  it("logout revokes the presented family and is idempotent", async () => {
    const harness = await buildTokenApp();
    const { app } = harness;
    try {
      await registerVerified(harness, "alice@example.com");
      const first = await login(app, "alice@example.com");

      const logout = await app.inject({
        method: "POST",
        url: "/v1/auth/logout",
        payload: { refreshToken: first.body.refreshToken },
      });
      expect(logout.statusCode).toBe(204);
      expect(logout.body).toBe("");
      expect((await familyRows())[0].revoked_at).not.toBeNull();

      const dead = await refresh(app, first.body.refreshToken);
      expect(dead.statusCode).toBe(401);

      // Repeat logout of the same (now revoked) token and of an unknown
      // token both succeed silently.
      for (const token of [first.body.refreshToken, "never-issued"]) {
        const again = await app.inject({
          method: "POST",
          url: "/v1/auth/logout",
          payload: { refreshToken: token },
        });
        expect(again.statusCode).toBe(204);
      }
    } finally {
      await app.close();
    }
  });

  it("authenticate guards routes with the access token and rejects expiry", async () => {
    const harness = await buildTokenApp();
    const { app, clock } = harness;
    try {
      app.get(
        "/v1/test-protected",
        { preHandler: app.authenticate },
        async (request) => ({ userId: request.userId }),
      );
      await registerVerified(harness, "alice@example.com");
      const first = await login(app, "alice@example.com");

      const missing = await app.inject({ method: "GET", url: "/v1/test-protected" });
      expect(missing.statusCode).toBe(401);
      expect(missing.json().error.code).toBe("UNAUTHORIZED");
      expect(validateErrorResponse(missing.json())).toBe(true);

      const garbage = await app.inject({
        method: "GET",
        url: "/v1/test-protected",
        headers: { authorization: "Bearer not-a-jwt" },
      });
      expect(garbage.statusCode).toBe(401);
      expect(garbage.json()).toEqual(missing.json());

      const ok = await app.inject({
        method: "GET",
        url: "/v1/test-protected",
        headers: { authorization: `Bearer ${first.body.accessToken}` },
      });
      expect(ok.statusCode).toBe(200);
      expect(ok.json().userId).toBe(await userIdByEmail("alice@example.com"));

      // Exactly 900 seconds of life: one second past expiry rejects.
      clock.advance(NINE_HUNDRED_SECONDS_MS + 1_000);
      const expired = await app.inject({
        method: "GET",
        url: "/v1/test-protected",
        headers: { authorization: `Bearer ${first.body.accessToken}` },
      });
      expect(expired.statusCode).toBe(401);
      expect(expired.json()).toEqual(missing.json());
    } finally {
      await app.close();
    }
  });

  it("rejects a well-formed HS256 token signed by a different key", async () => {
    const harness = await buildTokenApp();
    const { app } = harness;
    try {
      app.get(
        "/v1/test-protected",
        { preHandler: app.authenticate },
        async (request) => ({ userId: request.userId }),
      );
      // Well-formed, unexpired, correctly structured JWT — but signed with a
      // different 32-byte key than the app is configured with.
      const foreignKey = Buffer.from("fedcba9876543210fedcba9876543210").toString("base64");
      expect(foreignKey).not.toBe(TEST_JWT_SIGNING_KEY);
      const foreign = createAccessTokens({ signingKey: foreignKey, clock: harness.clock });
      const foreignToken = foreign.sign("some-user-id");

      const res = await app.inject({
        method: "GET",
        url: "/v1/test-protected",
        headers: { authorization: `Bearer ${foreignToken}` },
      });
      expect(res.statusCode).toBe(401);
      expect(res.json().error.code).toBe("UNAUTHORIZED");
      expect(validateErrorResponse(res.json())).toBe(true);
    } finally {
      await app.close();
    }
  });
});
