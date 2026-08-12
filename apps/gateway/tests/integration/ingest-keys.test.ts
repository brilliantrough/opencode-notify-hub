import {
  validateCreateIngestKeyResponse,
  validateErrorResponse,
  validateIngestKeyListResponse,
} from "@notify/contracts";
import { sql } from "drizzle-orm";
import type { FastifyInstance, LightMyRequestResponse } from "fastify";
import { afterAll, beforeAll, beforeEach, describe, expect, it } from "vitest";

import { buildServer } from "../../src/app.js";
import { createDb, type GatewayDatabase } from "../../src/db/client.js";
import { sha256Hex } from "../../src/lib/crypto.js";
import { DrizzleIngestKeyRepository } from "../../src/modules/ingest-keys/ingest-keys.repository.js";
import { IngestKeyService } from "../../src/modules/ingest-keys/ingest-keys.service.js";
import type { Mailer } from "../../src/modules/mail/mailer.js";
import { buildTestConfig } from "../helpers/build-test-app.js";
import { TestPostgres } from "../helpers/postgres.js";

const PASSWORD = "correct horse battery staple";
const CREDENTIAL_PATTERN = /^[A-Za-z0-9_-]{12}\.[A-Za-z0-9_-]{43}$/;

class FakeMailer implements Mailer {
  verificationEmails: { to: string; code: string }[] = [];

  async sendVerificationEmail(to: string, code: string): Promise<void> {
    this.verificationEmails.push({ to, code });
  }

  async sendPasswordResetEmail(): Promise<void> {
    throw new Error("not used in this suite");
  }
}

interface CreateKeyBody {
  id: string;
  name: string;
  createdAt: string;
  secret: string;
}

describe("ingest-key management", () => {
  let pg: TestPostgres;
  let handle: GatewayDatabase;
  let app: FastifyInstance;
  let mailer: FakeMailer;

  async function cleanup(): Promise<void> {
    await handle.db.execute(
      sql`truncate refresh_tokens, refresh_token_families, password_reset_tokens, email_verification_tokens, devices, ingest_keys, users cascade`,
    );
  }

  /** Register, verify, and log in an account; returns its access token. */
  async function accessTokenFor(email: string): Promise<string> {
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

  async function userIdFor(email: string): Promise<string> {
    const rows = (await handle.db.execute<{ id: string }>(
      sql`select id from users where email = ${email}`,
    )) as { id: string }[];
    return rows[0].id;
  }

  function authed(
    token: string,
    request: { method: "GET" | "POST" | "DELETE"; url: string; payload?: Record<string, unknown> },
  ): Promise<LightMyRequestResponse> {
    return app.inject({ ...request, headers: { authorization: `Bearer ${token}` } });
  }

  async function createKey(token: string, name: string): Promise<CreateKeyBody> {
    const res = await authed(token, { method: "POST", url: "/v1/ingest-keys", payload: { name } });
    expect(res.statusCode).toBe(201);
    return res.json() as CreateKeyBody;
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
    await cleanup();
    mailer = new FakeMailer();
    if (app !== undefined) {
      await app.close();
    }
    app = await buildServer({
      config: buildTestConfig({ databaseUrl: pg.databaseUrl }),
      db: handle.db,
      mailer,
    });
  });

  describe("creation", () => {
    it("returns the keyId.secret credential once in contract shape", async () => {
      const token = await accessTokenFor("alice@example.com");

      const res = await authed(token, {
        method: "POST",
        url: "/v1/ingest-keys",
        payload: { name: "workstation" },
      });
      expect(res.statusCode).toBe(201);
      const body = res.json() as CreateKeyBody;
      expect(validateCreateIngestKeyResponse(body)).toBe(true);
      expect(body.name).toBe("workstation");
      expect(body.secret).toMatch(CREDENTIAL_PATTERN);
      expect(Number.isNaN(Date.parse(body.createdAt))).toBe(false);
    });

    it("stores only SHA-256(secret); the plaintext secret is nowhere in the row", async () => {
      const token = await accessTokenFor("alice@example.com");
      const created = await createKey(token, "workstation");
      const secret = created.secret.slice(created.secret.indexOf(".") + 1);

      const rows = (await handle.db.execute<Record<string, unknown>>(
        sql`select * from ingest_keys where id = ${created.id}`,
      )) as Record<string, unknown>[];
      expect(rows).toHaveLength(1);
      const row = rows[0];
      expect(row.secret_hash).toBe(sha256Hex(secret));
      expect(row.key_id).toBe(created.secret.slice(0, 12));
      for (const value of Object.values(row)) {
        if (typeof value === "string") {
          expect(value).not.toContain(secret);
        }
      }
    });

    it("generates a unique credential for every key", async () => {
      const token = await accessTokenFor("alice@example.com");
      const first = await createKey(token, "workstation");
      const second = await createKey(token, "laptop");
      expect(second.id).not.toBe(first.id);
      expect(second.secret).not.toBe(first.secret);
      expect(second.secret.slice(0, 12)).not.toBe(first.secret.slice(0, 12));
    });

    it("rejects invalid bodies with VALIDATION_FAILED and persists nothing", async () => {
      const token = await accessTokenFor("alice@example.com");

      const cases: Record<string, unknown>[] = [
        {}, // missing name
        { name: "" }, // empty name
        { name: "x".repeat(65) }, // name too long
        { name: { value: "workstation" } }, // wrong type (not coercible to string)
        { name: "ok", extra: true }, // unknown property
      ];
      for (const payload of cases) {
        const res = await authed(token, { method: "POST", url: "/v1/ingest-keys", payload });
        expect(res.statusCode).toBe(400);
        expect(res.json().error.code).toBe("VALIDATION_FAILED");
        expect(validateErrorResponse(res.json())).toBe(true);
      }

      const list = await authed(token, { method: "GET", url: "/v1/ingest-keys" });
      expect(list.json()).toEqual([]);
    });
  });

  describe("listing", () => {
    it("never includes the secret, only metadata in contract shape", async () => {
      const token = await accessTokenFor("alice@example.com");
      const created = await createKey(token, "workstation");
      await createKey(token, "laptop");

      const res = await authed(token, { method: "GET", url: "/v1/ingest-keys" });
      expect(res.statusCode).toBe(200);
      const items = res.json();
      expect(validateIngestKeyListResponse(items)).toBe(true);
      expect(items).toHaveLength(2);
      expect(items[0].id).toBe(created.id);
      for (const item of items) {
        expect(Object.keys(item).sort()).toEqual(["createdAt", "id", "name"]);
      }
      // The one-time secret appears nowhere in the serialized response.
      expect(res.body).not.toContain(created.secret);
      expect(res.body).not.toContain("secret");
    });

    it("lists only the authenticated user's keys", async () => {
      const alice = await accessTokenFor("alice@example.com");
      const bob = await accessTokenFor("bob@example.com");
      await createKey(alice, "alice workstation");
      await createKey(bob, "bob workstation");

      const aliceList = (await authed(alice, { method: "GET", url: "/v1/ingest-keys" })).json();
      const bobList = (await authed(bob, { method: "GET", url: "/v1/ingest-keys" })).json();
      expect(aliceList).toHaveLength(1);
      expect(aliceList[0].name).toBe("alice workstation");
      expect(bobList).toHaveLength(1);
      expect(bobList[0].name).toBe("bob workstation");
    });
  });

  describe("verification", () => {
    it("accepts an active credential and rejects revoked, foreign, and tampered ones", async () => {
      const token = await accessTokenFor("alice@example.com");
      const other = await accessTokenFor("bob@example.com");
      const aliceUserId = await userIdFor("alice@example.com");
      const created = await createKey(token, "workstation");
      const bobKey = await createKey(other, "bob workstation");

      const service = new IngestKeyService(new DrizzleIngestKeyRepository(handle.db));

      const verified = await service.verify(created.secret);
      expect(verified?.userId).toBe(aliceUserId);
      expect(verified?.keyId).toBe(created.secret.slice(0, 12));

      // Tampered secret part fails.
      const keyId = created.secret.slice(0, 12);
      const bobSecret = bobKey.secret.slice(bobKey.secret.indexOf(".") + 1);
      expect(await service.verify(`${keyId}.${bobSecret}`)).toBeNull();

      // Unknown keyId fails.
      expect(await service.verify(`zzzzzzzzzzzz.${bobSecret}`)).toBeNull();

      // Revoking the key makes its credential fail immediately.
      const revoked = await authed(token, {
        method: "DELETE",
        url: `/v1/ingest-keys/${created.id}`,
      });
      expect(revoked.statusCode).toBe(204);
      expect(await service.verify(created.secret)).toBeNull();

      // Bob's key is unaffected.
      expect(await service.verify(bobKey.secret)).not.toBeNull();
    });
  });

  describe("revocation", () => {
    it("revokes the key, removes it from the list, and marks the row revoked", async () => {
      const token = await accessTokenFor("alice@example.com");
      const created = await createKey(token, "workstation");

      const res = await authed(token, {
        method: "DELETE",
        url: `/v1/ingest-keys/${created.id}`,
      });
      expect(res.statusCode).toBe(204);
      expect(res.body).toBe("");

      const list = (await authed(token, { method: "GET", url: "/v1/ingest-keys" })).json();
      expect(list).toEqual([]);

      // Soft delete: the row stays for audit but is flagged revoked.
      const rows = (await handle.db.execute<{ revoked_at: Date | null }>(
        sql`select revoked_at from ingest_keys where id = ${created.id}`,
      )) as { revoked_at: Date | null }[];
      expect(rows).toHaveLength(1);
      expect(rows[0].revoked_at).not.toBeNull();

      // A second revoke answers 404 like an unknown id.
      const again = await authed(token, {
        method: "DELETE",
        url: `/v1/ingest-keys/${created.id}`,
      });
      expect(again.statusCode).toBe(404);
    });

    it("answers 404 when revoking another user's key and changes nothing", async () => {
      const alice = await accessTokenFor("alice@example.com");
      const bob = await accessTokenFor("bob@example.com");
      const created = await createKey(alice, "alice workstation");

      const res = await authed(bob, {
        method: "DELETE",
        url: `/v1/ingest-keys/${created.id}`,
      });
      expect(res.statusCode).toBe(404);
      expect(res.json().error.code).toBe("NOT_FOUND");
      expect(validateErrorResponse(res.json())).toBe(true);

      const list = (await authed(alice, { method: "GET", url: "/v1/ingest-keys" })).json();
      expect(list).toHaveLength(1);
      const rows = (await handle.db.execute<{ revoked_at: Date | null }>(
        sql`select revoked_at from ingest_keys where id = ${created.id}`,
      )) as { revoked_at: Date | null }[];
      expect(rows[0].revoked_at).toBeNull();
    });

    it("answers 404 for unknown or malformed key ids", async () => {
      const token = await accessTokenFor("alice@example.com");

      const unknown = await authed(token, {
        method: "DELETE",
        url: "/v1/ingest-keys/00000000-0000-0000-0000-000000000000",
      });
      expect(unknown.statusCode).toBe(404);
      expect(unknown.json().error.code).toBe("NOT_FOUND");

      const malformed = await authed(token, {
        method: "DELETE",
        url: "/v1/ingest-keys/not-a-uuid",
      });
      expect(malformed.statusCode).toBe(404);
      expect(malformed.json().error.code).toBe("NOT_FOUND");
    });
  });

  describe("authentication", () => {
    it("rejects every ingest-key route without an access token", async () => {
      for (const request of [
        { method: "GET" as const, url: "/v1/ingest-keys" },
        { method: "POST" as const, url: "/v1/ingest-keys", payload: { name: "x" } },
        {
          method: "DELETE" as const,
          url: "/v1/ingest-keys/00000000-0000-0000-0000-000000000000",
        },
      ]) {
        const res = await app.inject(request);
        expect(res.statusCode).toBe(401);
        expect(res.json().error.code).toBe("UNAUTHORIZED");
      }
    });
  });
});
