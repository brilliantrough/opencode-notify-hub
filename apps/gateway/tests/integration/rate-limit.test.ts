import { validateErrorResponse } from "@notify/contracts";
import { sql } from "drizzle-orm";
import type { FastifyInstance } from "fastify";
import { afterAll, afterEach, beforeAll, beforeEach, describe, expect, it, vi } from "vitest";

import { buildServer } from "../../src/app.js";
import { createDb, type GatewayDatabase } from "../../src/db/client.js";
import type { Mailer } from "../../src/modules/mail/mailer.js";
import {
  INGEST_EVENTS_IP_RATE_LIMIT,
  INGEST_EVENTS_RATE_LIMIT,
  ingestEventsIpRateLimit,
} from "../../src/plugins/rate-limit.js";
import { buildTestConfig } from "../helpers/build-test-app.js";
import { TestPostgres } from "../helpers/postgres.js";

class FakeMailer implements Mailer {
  async sendVerificationEmail(): Promise<void> {}
  async sendPasswordResetEmail(): Promise<void> {}
}

const EMAIL = "ratelimit@example.com";

/** Every auth endpoint with a valid-shape payload; status codes don't matter, only the limit. */
const AUTH_ENDPOINTS: { url: string; payload: Record<string, unknown> }[] = [
  { url: "/v1/auth/register", payload: { email: EMAIL, password: "password-123" } },
  { url: "/v1/auth/verify-email", payload: { email: EMAIL, code: "Abcd1234" } },
  { url: "/v1/auth/resend-verification", payload: { email: EMAIL } },
  { url: "/v1/auth/login", payload: { email: EMAIL, password: "password-123" } },
  { url: "/v1/auth/refresh", payload: { refreshToken: "x".repeat(43) } },
  { url: "/v1/auth/logout", payload: { refreshToken: "x".repeat(43) } },
  { url: "/v1/auth/forgot-password", payload: { email: EMAIL } },
  {
    url: "/v1/auth/reset-password",
    payload: { email: EMAIL, code: "Abcd1234", password: "password-123" },
  },
];

describe("endpoint rate limits", () => {
  let pg: TestPostgres;
  let handle: GatewayDatabase;
  let app: FastifyInstance;

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
    // Fresh app per test: the in-memory limiter buckets start empty.
    await handle.db.execute(
      sql`truncate refresh_tokens, refresh_token_families, password_reset_tokens, email_verification_tokens, devices, ingest_keys, users cascade`,
    );
    if (app !== undefined) {
      await app.close();
    }
    app = await buildServer({
      config: buildTestConfig({ databaseUrl: pg.databaseUrl }),
      db: handle.db,
      mailer: new FakeMailer(),
    });
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  describe("auth endpoints (10/minute per client IP)", () => {
    it("answers the eleventh request in one minute with 429 RATE_LIMITED and Retry-After", async () => {
      for (const endpoint of AUTH_ENDPOINTS) {
        for (let attempt = 0; attempt < 10; attempt += 1) {
          const res = await app.inject({
            method: "POST",
            url: endpoint.url,
            payload: endpoint.payload,
          });
          expect(res.statusCode, `${endpoint.url} attempt ${attempt + 1}`).not.toBe(429);
        }

        const limited = await app.inject({
          method: "POST",
          url: endpoint.url,
          payload: endpoint.payload,
        });
        expect(limited.statusCode, endpoint.url).toBe(429);
        const body = limited.json();
        expect(body.error.code).toBe("RATE_LIMITED");
        expect(validateErrorResponse(body)).toBe(true);
        const retryAfter = Number(limited.headers["retry-after"]);
        expect(Number.isInteger(retryAfter)).toBe(true);
        expect(retryAfter).toBeGreaterThanOrEqual(1);
        expect(retryAfter).toBeLessThanOrEqual(60);
      }
    });

    it("keeps the anti-enumeration shape: the limiter fires before any account lookup", async () => {
      // Unknown email: ten uniform 204s, then the same 429 a known email
      // would get — the limited response reveals nothing about the account.
      for (let attempt = 0; attempt < 10; attempt += 1) {
        const res = await app.inject({
          method: "POST",
          url: "/v1/auth/forgot-password",
          payload: { email: "ghost@example.com" },
        });
        expect(res.statusCode).toBe(204);
      }
      const limited = await app.inject({
        method: "POST",
        url: "/v1/auth/forgot-password",
        payload: { email: "ghost@example.com" },
      });
      expect(limited.statusCode).toBe(429);
      expect(limited.json().error.code).toBe("RATE_LIMITED");
    });

    it("keys the bucket by client IP", async () => {
      for (let attempt = 0; attempt < 11; attempt += 1) {
        await app.inject({
          method: "POST",
          url: "/v1/auth/login",
          payload: { email: EMAIL, password: "password-123" },
        });
      }
      const fromOtherIp = await app.inject({
        method: "POST",
        url: "/v1/auth/login",
        payload: { email: EMAIL, password: "password-123" },
        remoteAddress: "10.9.8.7",
      });
      expect(fromOtherIp.statusCode).toBe(401);
      expect(fromOtherIp.statusCode).not.toBe(429);
    });

    it("allows requests again once the window has rolled", async () => {
      const login = () =>
        app.inject({
          method: "POST",
          url: "/v1/auth/login",
          payload: { email: EMAIL, password: "password-123" },
        });

      for (let attempt = 0; attempt < 10; attempt += 1) {
        await login();
      }
      expect((await login()).statusCode).toBe(429);

      const now = Date.now();
      vi.useFakeTimers({ toFake: ["Date"] });
      try {
        vi.setSystemTime(now + 61_000);
        const afterWindow = await login();
        expect(afterWindow.statusCode).toBe(401);
        expect(afterWindow.statusCode).not.toBe(429);
      } finally {
        vi.useRealTimers();
      }
    });

    it("does not rate-limit the liveness probe", async () => {
      for (let attempt = 0; attempt < 15; attempt += 1) {
        const res = await app.inject({ method: "GET", url: "/health/live" });
        expect(res.statusCode).toBe(200);
      }
    });
  });

  describe("X-Forwarded-For behind the mandated reverse proxy", () => {
    // Deployment assumption: the gateway only ever sits behind the mandated
    // reverse proxy, which owns the client-facing connection and sets a
    // trustworthy X-Forwarded-For; trustProxy derives request.ip from it so
    // per-client rate buckets cannot be shared through the proxy's peer IP.
    it("keys auth buckets by the forwarded client IP: one exhausted client never blocks another", async () => {
      const login = (forwardedFor: string) =>
        app.inject({
          method: "POST",
          url: "/v1/auth/login",
          headers: { "x-forwarded-for": forwardedFor },
          payload: { email: EMAIL, password: "password-123" },
        });

      for (let attempt = 0; attempt < 10; attempt += 1) {
        expect((await login("203.0.113.10")).statusCode).not.toBe(429);
      }
      expect((await login("203.0.113.10")).statusCode).toBe(429);

      // A different forwarded client behind the same proxy peer keeps its
      // own bucket and still reaches the credential check.
      const other = await login("203.0.113.11");
      expect(other.statusCode).toBe(401);
      expect(other.statusCode).not.toBe(429);
    });

    it("keys the ingest pre-auth ceiling by the forwarded client IP: one exhausted client never blocks another", async () => {
      // Missing credentials 401 before any key-store lookup, so exhausting
      // the 1000/minute pre-auth ceiling stays cheap.
      const ingest = (forwardedFor: string) =>
        app.inject({
          method: "POST",
          url: "/v1/events",
          headers: {
            "content-type": "application/json",
            "x-forwarded-for": forwardedFor,
          },
          payload: "{}",
        });

      for (let attempt = 0; attempt < 1000; attempt += 1) {
        expect((await ingest("203.0.113.20")).statusCode).toBe(401);
      }
      expect((await ingest("203.0.113.20")).statusCode).toBe(429);

      const other = await ingest("203.0.113.21");
      expect(other.statusCode).toBe(401);
      expect(other.statusCode).not.toBe(429);
    });
  });

  describe("ingest-events policies (behavior covered by event-ingest.test.ts)", () => {
    it("caps pre-auth ingress per client IP, never per presented keyId", () => {
      // The pre-auth ceiling must be keyed by client IP so rotating random
      // keyIds cannot mint unlimited buckets or DB lookups.
      // The ceiling sits above 4x the verified per-key budget so a user with
      // several keys behind one IP keeps their full allowance.
      expect(INGEST_EVENTS_IP_RATE_LIMIT).toEqual({ max: 1000, timeWindow: "1 minute" });
      const config = ingestEventsIpRateLimit();
      expect(config.max).toBe(1000);
      expect(config.timeWindow).toBe("1 minute");
      const request = {
        headers: { authorization: "Bearer abcdefghijkl.some-secret-value" },
        ip: "192.0.2.10",
      } as never;
      expect(config.keyGenerator(request)).toBe("192.0.2.10");
    });

    it("limits verified ingress at 240/minute per authenticated keyId", () => {
      expect(INGEST_EVENTS_RATE_LIMIT).toEqual({ max: 240, timeWindow: "1 minute" });
    });
  });
});
