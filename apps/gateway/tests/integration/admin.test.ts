import { validateErrorResponse } from "@notify/contracts";
import { sql } from "drizzle-orm";
import type { FastifyInstance } from "fastify";
import { afterAll, beforeAll, beforeEach, describe, expect, it } from "vitest";

import { buildServer } from "../../src/app.js";
import { createDb, type GatewayDatabase } from "../../src/db/client.js";
import type { Clock } from "../../src/lib/clock.js";
import { DrizzleAdminRepository } from "../../src/modules/admin/admin.repository.js";
import { WhitelistRegistrationPolicy } from "../../src/modules/admin/admin.service.js";
import type { Mailer } from "../../src/modules/mail/mailer.js";
import {
  buildTestConfig,
  TEST_ADMIN_PASSWORD,
  TEST_ADMIN_USERNAME,
} from "../helpers/build-test-app.js";
import { TestPostgres } from "../helpers/postgres.js";

const USER_PASSWORD = "correct horse battery staple";
const NEW_PASSWORD = "a different long password";

class FakeClock implements Clock {
  nowMsValue = 1_700_000_000_000;

  now(): Date {
    return new Date(this.nowMsValue);
  }

  nowMs(): number {
    return this.nowMsValue;
  }
}

class FakeMailer implements Mailer {
  verificationEmails: { to: string; code: string }[] = [];

  async sendVerificationEmail(to: string, code: string): Promise<void> {
    this.verificationEmails.push({ to, code });
  }

  async sendPasswordResetEmail(): Promise<void> {}
}

interface Harness {
  app: FastifyInstance;
  mailer: FakeMailer;
  clock: FakeClock;
}

describe("admin panel and registration whitelist", () => {
  let pg: TestPostgres;
  let handle: GatewayDatabase;

  // The whitelist policy is wired exactly like the production entrypoint.
  async function buildAdminApp(): Promise<Harness> {
    const mailer = new FakeMailer();
    const clock = new FakeClock();
    const app = await buildServer({
      config: buildTestConfig({ databaseUrl: pg.databaseUrl }),
      db: handle.db,
      mailer,
      clock,
      registrationPolicy: new WhitelistRegistrationPolicy(
        new DrizzleAdminRepository(handle.db),
      ),
    });
    return { app, mailer, clock };
  }

  async function cleanup(): Promise<void> {
    await handle.db.execute(
      sql`truncate registration_whitelist, admin_users, email_verification_tokens, password_reset_tokens, refresh_tokens, refresh_token_families, users cascade`,
    );
  }

  async function adminLogin(app: FastifyInstance): Promise<string> {
    const response = await app.inject({
      method: "POST",
      url: "/v1/admin/login",
      payload: { username: TEST_ADMIN_USERNAME, password: TEST_ADMIN_PASSWORD },
    });
    expect(response.statusCode).toBe(200);
    return (response.json() as { accessToken: string }).accessToken;
  }

  async function putWhitelist(
    app: FastifyInstance,
    token: string,
    body: { domains?: string[]; emails?: string[] },
  ): Promise<number> {
    const response = await app.inject({
      method: "PUT",
      url: "/v1/admin/whitelist",
      headers: { authorization: `Bearer ${token}` },
      payload: { domains: body.domains ?? [], emails: body.emails ?? [] },
    });
    return response.statusCode;
  }

  async function register(
    app: FastifyInstance,
    email: string,
    password: string = USER_PASSWORD,
  ): Promise<{ status: number; code: string }> {
    const response = await app.inject({
      method: "POST",
      url: "/v1/auth/register",
      payload: { email, password },
    });
    const body = response.body === "" ? {} : (response.json() as object);
    const error = (body as { error?: { code?: string } }).error;
    return { status: response.statusCode, code: error?.code ?? "" };
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

  beforeEach(cleanup);

  describe("panel page", () => {
    it("serves the admin HTML page without authentication", async () => {
      const { app } = await buildAdminApp();
      const response = await app.inject({ method: "GET", url: "/admin" });
      expect(response.statusCode).toBe(200);
      expect(response.headers["content-type"]).toContain("text/html");
      expect(response.body).toContain("Notify 管理后台");
      expect(response.body).toContain("/v1/admin/login");
    });
  });

  describe("admin authentication", () => {
    it("rejects a wrong password", async () => {
      const { app } = await buildAdminApp();
      const response = await app.inject({
        method: "POST",
        url: "/v1/admin/login",
        payload: { username: TEST_ADMIN_USERNAME, password: "wrong-password" },
      });
      expect(response.statusCode).toBe(401);
      expect(validateErrorResponse(response.json())).toBe(true);
      expect((response.json() as { error: { code: string } }).error.code).toBe(
        "INVALID_CREDENTIALS",
      );
    });

    it("issues a token for the seeded operator", async () => {
      const { app } = await buildAdminApp();
      const token = await adminLogin(app);
      expect(token).not.toBe("");
    });

    it("guards every admin endpoint", async () => {
      const { app } = await buildAdminApp();
      for (const [method, url] of [
        ["GET", "/v1/admin/users"],
        ["GET", "/v1/admin/whitelist"],
      ] as const) {
        const response = await app.inject({ method, url });
        expect(response.statusCode).toBe(401);
      }
    });

    it("rejects user access tokens on admin endpoints", async () => {
      const { app, mailer } = await buildAdminApp();
      const token = await adminLogin(app);
      expect(
        await putWhitelist(app, token, { domains: ["nju.edu.cn"] }),
      ).toBe(204);
      const registered = await register(app, "student@nju.edu.cn");
      expect(registered.status).toBe(201);

      const code = mailer.verificationEmails.at(-1)?.code;
      expect(code).toBeDefined();
      const verified = await app.inject({
        method: "POST",
        url: "/v1/auth/verify-email",
        payload: { email: "student@nju.edu.cn", code },
      });
      expect(verified.statusCode).toBe(204);

      const login = await app.inject({
        method: "POST",
        url: "/v1/auth/login",
        payload: { email: "student@nju.edu.cn", password: USER_PASSWORD },
      });
      expect(login.statusCode).toBe(200);
      const userToken = (login.json() as { accessToken: string }).accessToken;

      const response = await app.inject({
        method: "GET",
        url: "/v1/admin/users",
        headers: { authorization: `Bearer ${userToken}` },
      });
      expect(response.statusCode).toBe(401);
    });

    it("rejects admin tokens on user endpoints", async () => {
      const { app } = await buildAdminApp();
      const token = await adminLogin(app);
      const response = await app.inject({
        method: "GET",
        url: "/v1/devices",
        headers: { authorization: `Bearer ${token}` },
      });
      expect(response.statusCode).toBe(401);
    });

    it("changes the operator password", async () => {
      const { app } = await buildAdminApp();
      const token = await adminLogin(app);

      const wrongCurrent = await app.inject({
        method: "POST",
        url: "/v1/admin/change-password",
        headers: { authorization: `Bearer ${token}` },
        payload: { currentPassword: "not-the-password", newPassword: NEW_PASSWORD },
      });
      expect(wrongCurrent.statusCode).toBe(401);

      const change = await app.inject({
        method: "POST",
        url: "/v1/admin/change-password",
        headers: { authorization: `Bearer ${token}` },
        payload: { currentPassword: TEST_ADMIN_PASSWORD, newPassword: NEW_PASSWORD },
      });
      expect(change.statusCode).toBe(204);

      const reloginOld = await app.inject({
        method: "POST",
        url: "/v1/admin/login",
        payload: { username: TEST_ADMIN_USERNAME, password: TEST_ADMIN_PASSWORD },
      });
      expect(reloginOld.statusCode).toBe(401);

      const reloginNew = await app.inject({
        method: "POST",
        url: "/v1/admin/login",
        payload: { username: TEST_ADMIN_USERNAME, password: NEW_PASSWORD },
      });
      expect(reloginNew.statusCode).toBe(200);
    });
  });

  describe("user management", () => {
    it("lists users with total and verified state", async () => {
      const { app } = await buildAdminApp();
      const token = await adminLogin(app);

      const created = await app.inject({
        method: "POST",
        url: "/v1/admin/users",
        headers: { authorization: `Bearer ${token}` },
        payload: { email: "Friend@Example.com", password: USER_PASSWORD },
      });
      expect(created.statusCode).toBe(201);
      const createdBody = created.json() as { id: string; email: string; verified: boolean };
      expect(createdBody.email).toBe("friend@example.com");
      expect(createdBody.verified).toBe(true);

      const list = await app.inject({
        method: "GET",
        url: "/v1/admin/users",
        headers: { authorization: `Bearer ${token}` },
      });
      expect(list.statusCode).toBe(200);
      const body = list.json() as { total: number; users: { email: string }[] };
      expect(body.total).toBe(1);
      expect(body.users[0].email).toBe("friend@example.com");
    });

    it("created users can log in immediately without email verification", async () => {
      const { app } = await buildAdminApp();
      const token = await adminLogin(app);
      const created = await app.inject({
        method: "POST",
        url: "/v1/admin/users",
        headers: { authorization: `Bearer ${token}` },
        payload: { email: "friend@example.com", password: USER_PASSWORD },
      });
      expect(created.statusCode).toBe(201);

      const login = await app.inject({
        method: "POST",
        url: "/v1/auth/login",
        payload: { email: "friend@example.com", password: USER_PASSWORD },
      });
      expect(login.statusCode).toBe(200);
    });

    it("reports duplicate emails as EMAIL_TAKEN", async () => {
      const { app } = await buildAdminApp();
      const token = await adminLogin(app);
      const first = await app.inject({
        method: "POST",
        url: "/v1/admin/users",
        headers: { authorization: `Bearer ${token}` },
        payload: { email: "friend@example.com", password: USER_PASSWORD },
      });
      expect(first.statusCode).toBe(201);
      const second = await app.inject({
        method: "POST",
        url: "/v1/admin/users",
        headers: { authorization: `Bearer ${token}` },
        payload: { email: "FRIEND@example.com", password: USER_PASSWORD },
      });
      expect(second.statusCode).toBe(409);
      expect((second.json() as { error: { code: string } }).error.code).toBe("EMAIL_TAKEN");
    });

    it("resets a user password and revokes sessions", async () => {
      const { app } = await buildAdminApp();
      const token = await adminLogin(app);
      const created = await app.inject({
        method: "POST",
        url: "/v1/admin/users",
        headers: { authorization: `Bearer ${token}` },
        payload: { email: "friend@example.com", password: USER_PASSWORD },
      });
      const userId = (created.json() as { id: string }).id;

      const login = await app.inject({
        method: "POST",
        url: "/v1/auth/login",
        payload: { email: "friend@example.com", password: USER_PASSWORD },
      });
      const { refreshToken } = login.json() as { refreshToken: string };

      const reset = await app.inject({
        method: "POST",
        url: `/v1/admin/users/${userId}/reset-password`,
        headers: { authorization: `Bearer ${token}` },
        payload: { password: NEW_PASSWORD },
      });
      expect(reset.statusCode).toBe(204);

      const oldLogin = await app.inject({
        method: "POST",
        url: "/v1/auth/login",
        payload: { email: "friend@example.com", password: USER_PASSWORD },
      });
      expect(oldLogin.statusCode).toBe(401);

      const newLogin = await app.inject({
        method: "POST",
        url: "/v1/auth/login",
        payload: { email: "friend@example.com", password: NEW_PASSWORD },
      });
      expect(newLogin.statusCode).toBe(200);

      const refreshed = await app.inject({
        method: "POST",
        url: "/v1/auth/refresh",
        payload: { refreshToken },
      });
      expect(refreshed.statusCode).toBe(401);

      const unknown = await app.inject({
        method: "POST",
        url: "/v1/admin/users/00000000-0000-0000-0000-000000000000/reset-password",
        headers: { authorization: `Bearer ${token}` },
        payload: { password: NEW_PASSWORD },
      });
      expect(unknown.statusCode).toBe(404);
    });
  });

  describe("registration whitelist", () => {
    it("blocks all self-registration while the whitelist is empty", async () => {
      const { app } = await buildAdminApp();
      const result = await register(app, "anyone@example.com");
      expect(result.status).toBe(403);
      expect(result.code).toBe("EMAIL_NOT_ALLOWED");
      expect(result.code).toMatch(/[A-Z_]+/);
    });

    it("allows addresses matching a domain suffix", async () => {
      const { app } = await buildAdminApp();
      const token = await adminLogin(app);
      expect(await putWhitelist(app, token, { domains: ["nju.edu.cn", "smail.nju.edu.cn"] })).toBe(204);

      expect((await register(app, "student@nju.edu.cn")).status).toBe(201);
      expect((await register(app, "student@smail.nju.edu.cn")).status).toBe(201);

      // Subdomains of a listed suffix are NOT covered.
      const subdomain = await register(app, "student@mail.nju.edu.cn");
      expect(subdomain.status).toBe(403);
      expect(subdomain.code).toBe("EMAIL_NOT_ALLOWED");

      const foreign = await register(app, "student@gmail.com");
      expect(foreign.status).toBe(403);
    });

    it("allows exactly-listed addresses", async () => {
      const { app } = await buildAdminApp();
      const token = await adminLogin(app);
      expect(
        await putWhitelist(app, token, { emails: ["friend@gmail.com"] }),
      ).toBe(204);

      expect((await register(app, "friend@gmail.com")).status).toBe(201);
      const other = await register(app, "not-friend@gmail.com");
      expect(other.status).toBe(403);
    });

    it("round-trips the whitelist and rejects invalid entries", async () => {
      const { app } = await buildAdminApp();
      const token = await adminLogin(app);

      const invalid = await app.inject({
        method: "PUT",
        url: "/v1/admin/whitelist",
        headers: { authorization: `Bearer ${token}` },
        payload: { domains: ["not a domain"], emails: [] },
      });
      expect(invalid.statusCode).toBe(400);

      const invalidEmail = await app.inject({
        method: "PUT",
        url: "/v1/admin/whitelist",
        headers: { authorization: `Bearer ${token}` },
        payload: { domains: [], emails: ["no-at-sign"] },
      });
      expect(invalidEmail.statusCode).toBe(400);

      expect(await putWhitelist(app, token, { domains: ["NJU.EDU.CN"], emails: ["Friend@Gmail.com"] })).toBe(204);

      const read = await app.inject({
        method: "GET",
        url: "/v1/admin/whitelist",
        headers: { authorization: `Bearer ${token}` },
      });
      const body = read.json() as { domains: string[]; emails: string[] };
      expect(body.domains).toEqual(["nju.edu.cn"]);
      expect(body.emails).toEqual(["friend@gmail.com"]);
    });

    it("replacing the whitelist takes effect immediately", async () => {
      const { app } = await buildAdminApp();
      const token = await adminLogin(app);
      expect(await putWhitelist(app, token, { domains: ["nju.edu.cn"] })).toBe(204);
      expect((await register(app, "student@nju.edu.cn")).status).toBe(201);

      expect(await putWhitelist(app, token, { domains: [], emails: [] })).toBe(204);
      const blocked = await register(app, "another@nju.edu.cn");
      expect(blocked.status).toBe(403);
    });

    it("admin-created accounts bypass the whitelist entirely", async () => {
      const { app } = await buildAdminApp();
      const token = await adminLogin(app);
      // Whitlist stays empty: self-registration is closed.
      const created = await app.inject({
        method: "POST",
        url: "/v1/admin/users",
        headers: { authorization: `Bearer ${token}` },
        payload: { email: "vip@gmail.com", password: USER_PASSWORD },
      });
      expect(created.statusCode).toBe(201);
    });
  });
});
