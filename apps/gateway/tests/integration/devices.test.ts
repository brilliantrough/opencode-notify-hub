import {
  validateDevice,
  validateDeviceListResponse,
  validateErrorResponse,
} from "@notify/contracts";
import { sql } from "drizzle-orm";
import type { FastifyInstance, LightMyRequestResponse } from "fastify";
import { afterAll, beforeAll, beforeEach, describe, expect, it } from "vitest";

import { buildServer } from "../../src/app.js";
import { createDb, type GatewayDatabase } from "../../src/db/client.js";
import { DrizzleDeviceRepository } from "../../src/modules/devices/devices.repository.js";
import type { Mailer } from "../../src/modules/mail/mailer.js";
import { buildTestConfig } from "../helpers/build-test-app.js";
import { TestPostgres } from "../helpers/postgres.js";

const PASSWORD = "correct horse battery staple";

class FakeMailer implements Mailer {
  verificationEmails: { to: string; code: string }[] = [];

  async sendVerificationEmail(to: string, code: string): Promise<void> {
    this.verificationEmails.push({ to, code });
  }

  async sendPasswordResetEmail(): Promise<void> {
    throw new Error("not used in this suite");
  }
}

interface DeviceBody {
  id: string;
  name: string;
  platform: string;
  enabled: boolean;
  soundEnabled: boolean;
  fcmToken?: string;
}

describe("per-user device management", () => {
  let pg: TestPostgres;
  let handle: GatewayDatabase;
  let app: FastifyInstance;
  let mailer: FakeMailer;

  async function cleanup(): Promise<void> {
    await handle.db.execute(
      sql`truncate refresh_tokens, refresh_token_families, password_reset_tokens, email_verification_tokens, devices, users cascade`,
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

  function authed(
    token: string,
    request: {
      method: "GET" | "POST" | "PATCH" | "DELETE";
      url: string;
      payload?: Record<string, unknown>;
    },
  ): Promise<LightMyRequestResponse> {
    return app.inject({
      ...request,
      headers: { authorization: `Bearer ${token}` },
    });
  }

  async function registerDevice(
    token: string,
    payload: Record<string, unknown>,
  ): Promise<ReturnType<FastifyInstance["inject"]>> {
    return authed(token, { method: "POST", url: "/v1/devices", payload });
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

  describe("registration", () => {
    it("registers a device on each platform and applies contract defaults", async () => {
      const token = await accessTokenFor("alice@example.com");

      for (const platform of ["windows", "linux", "android"]) {
        const res = await registerDevice(token, { name: `${platform} box`, platform });
        expect(res.statusCode).toBe(201);
        const device = res.json() as DeviceBody;
        expect(validateDevice(device)).toBe(true);
        expect(device.platform).toBe(platform);
        // The body omitted both flags; the server applied the defaults.
        expect(device.enabled).toBe(true);
        expect(device.soundEnabled).toBe(true);
        expect(device.fcmToken).toBeUndefined();
      }

      const list = await authed(token, { method: "GET", url: "/v1/devices" });
      expect(list.statusCode).toBe(200);
      expect(validateDeviceListResponse(list.json())).toBe(true);
      expect((list.json() as DeviceBody[]).map((d) => d.platform).sort()).toEqual([
        "android",
        "linux",
        "windows",
      ]);
    });

    it("honours explicit flags and stores the FCM token", async () => {
      const token = await accessTokenFor("alice@example.com");

      const res = await registerDevice(token, {
        name: "phone",
        platform: "android",
        fcmToken: "fcm-token-abc",
        enabled: false,
        soundEnabled: false,
      });
      expect(res.statusCode).toBe(201);
      const device = res.json() as DeviceBody;
      expect(device.enabled).toBe(false);
      expect(device.soundEnabled).toBe(false);
      expect(device.fcmToken).toBe("fcm-token-abc");
    });

    it("rejects invalid bodies with VALIDATION_FAILED", async () => {
      const token = await accessTokenFor("alice@example.com");

      const cases: Record<string, unknown>[] = [
        { name: "tv", platform: "androidtv" }, // unknown platform
        { name: "", platform: "android" }, // empty name
        { name: "x".repeat(65), platform: "android" }, // name too long
        { platform: "android" }, // missing name
        { name: "phone" }, // missing platform
        { name: "phone", platform: "android", enabled: "yes" }, // wrong type
        { name: "phone", platform: "android", admin: true }, // unknown property
      ];
      for (const payload of cases) {
        const res = await registerDevice(token, payload);
        expect(res.statusCode).toBe(400);
        expect(res.json().error.code).toBe("VALIDATION_FAILED");
        expect(validateErrorResponse(res.json())).toBe(true);
      }

      // Nothing was persisted by the rejected attempts.
      const list = await authed(token, { method: "GET", url: "/v1/devices" });
      expect(list.json()).toEqual([]);
    });
  });

  describe("per-user isolation", () => {
    it("lists only the authenticated user's devices", async () => {
      const alice = await accessTokenFor("alice@example.com");
      const bob = await accessTokenFor("bob@example.com");
      await registerDevice(alice, { name: "alice pc", platform: "linux" });
      await registerDevice(bob, { name: "bob pc", platform: "windows" });

      const aliceList = (await authed(alice, { method: "GET", url: "/v1/devices" })).json();
      const bobList = (await authed(bob, { method: "GET", url: "/v1/devices" })).json();
      expect(aliceList).toHaveLength(1);
      expect(aliceList[0].name).toBe("alice pc");
      expect(bobList).toHaveLength(1);
      expect(bobList[0].name).toBe("bob pc");
    });

    it("answers 404 when patching or deleting another user's device", async () => {
      const alice = await accessTokenFor("alice@example.com");
      const bob = await accessTokenFor("bob@example.com");
      const created = (await registerDevice(alice, { name: "alice pc", platform: "linux" }))
        .json() as DeviceBody;

      const patched = await authed(bob, {
        method: "PATCH",
        url: `/v1/devices/${created.id}`,
        payload: { name: "hijacked" },
      });
      expect(patched.statusCode).toBe(404);
      expect(patched.json().error.code).toBe("NOT_FOUND");
      expect(validateErrorResponse(patched.json())).toBe(true);

      const deleted = await authed(bob, {
        method: "DELETE",
        url: `/v1/devices/${created.id}`,
      });
      expect(deleted.statusCode).toBe(404);
      expect(deleted.json().error.code).toBe("NOT_FOUND");

      // The foreign attempts changed nothing.
      const list = (await authed(alice, { method: "GET", url: "/v1/devices" }))
        .json() as DeviceBody[];
      expect(list).toHaveLength(1);
      expect(list[0].name).toBe("alice pc");
    });

    it("rejects every device route without an access token", async () => {
      for (const request of [
        { method: "GET" as const, url: "/v1/devices" },
        { method: "POST" as const, url: "/v1/devices", payload: { name: "x", platform: "linux" } },
        {
          method: "PATCH" as const,
          url: "/v1/devices/00000000-0000-0000-0000-000000000000",
          payload: { name: "x" },
        },
        {
          method: "DELETE" as const,
          url: "/v1/devices/00000000-0000-0000-0000-000000000000",
        },
      ]) {
        const res = await app.inject(request);
        expect(res.statusCode).toBe(401);
        expect(res.json().error.code).toBe("UNAUTHORIZED");
      }
    });
  });

  describe("patch", () => {
    it("renames, toggles enabled and sound, and updates the FCM token", async () => {
      const token = await accessTokenFor("alice@example.com");
      const created = (
        await registerDevice(token, { name: "phone", platform: "android" })
      ).json() as DeviceBody;

      const renamed = await authed(token, {
        method: "PATCH",
        url: `/v1/devices/${created.id}`,
        payload: { name: "work phone" },
      });
      expect(renamed.statusCode).toBe(200);
      expect(renamed.json().name).toBe("work phone");
      // Untouched fields keep their values.
      expect(renamed.json().enabled).toBe(true);
      expect(renamed.json().soundEnabled).toBe(true);

      const toggled = await authed(token, {
        method: "PATCH",
        url: `/v1/devices/${created.id}`,
        payload: { enabled: false, soundEnabled: false },
      });
      expect(toggled.statusCode).toBe(200);
      expect(toggled.json().enabled).toBe(false);
      expect(toggled.json().soundEnabled).toBe(false);

      const soundBackOn = await authed(token, {
        method: "PATCH",
        url: `/v1/devices/${created.id}`,
        payload: { soundEnabled: true },
      });
      expect(soundBackOn.statusCode).toBe(200);
      expect(soundBackOn.json().soundEnabled).toBe(true);
      expect(soundBackOn.json().enabled).toBe(false);

      const withToken = await authed(token, {
        method: "PATCH",
        url: `/v1/devices/${created.id}`,
        payload: { fcmToken: "new-fcm-token" },
      });
      expect(withToken.statusCode).toBe(200);
      expect(withToken.json().fcmToken).toBe("new-fcm-token");
      expect(validateDevice(withToken.json())).toBe(true);

      // The list reflects the final state.
      const list = (await authed(token, { method: "GET", url: "/v1/devices" }))
        .json() as DeviceBody[];
      expect(list[0]).toMatchObject({
        id: created.id,
        name: "work phone",
        enabled: false,
        soundEnabled: true,
        fcmToken: "new-fcm-token",
      });
    });

    it("rejects empty and invalid patch bodies with VALIDATION_FAILED", async () => {
      const token = await accessTokenFor("alice@example.com");
      const created = (
        await registerDevice(token, { name: "phone", platform: "android" })
      ).json() as DeviceBody;

      const cases: Record<string, unknown>[] = [
        {}, // minProperties: 1
        { platform: "windows" }, // platform is not patchable
        { enabled: "no" }, // wrong type
        { fcmToken: "" }, // empty token
        { name: "ok", extra: true }, // unknown property
      ];
      for (const payload of cases) {
        const res = await authed(token, {
          method: "PATCH",
          url: `/v1/devices/${created.id}`,
          payload,
        });
        expect(res.statusCode).toBe(400);
        expect(res.json().error.code).toBe("VALIDATION_FAILED");
        expect(validateErrorResponse(res.json())).toBe(true);
      }

      // None of the rejected patches took effect.
      const list = (await authed(token, { method: "GET", url: "/v1/devices" }))
        .json() as DeviceBody[];
      expect(list[0]).toMatchObject({ name: "phone", enabled: true, soundEnabled: true });
    });

    it("answers 404 for unknown or malformed device ids", async () => {
      const token = await accessTokenFor("alice@example.com");

      const unknown = await authed(token, {
        method: "PATCH",
        url: "/v1/devices/00000000-0000-0000-0000-000000000000",
        payload: { name: "ghost" },
      });
      expect(unknown.statusCode).toBe(404);
      expect(unknown.json().error.code).toBe("NOT_FOUND");

      const malformed = await authed(token, {
        method: "PATCH",
        url: "/v1/devices/not-a-uuid",
        payload: { name: "ghost" },
      });
      expect(malformed.statusCode).toBe(404);
      expect(malformed.json().error.code).toBe("NOT_FOUND");

      const deleteMalformed = await authed(token, {
        method: "DELETE",
        url: "/v1/devices/not-a-uuid",
      });
      expect(deleteMalformed.statusCode).toBe(404);
    });
  });

  describe("delete", () => {
    it("deletes the device and then answers 404 on every further access", async () => {
      const token = await accessTokenFor("alice@example.com");
      const created = (
        await registerDevice(token, { name: "old pc", platform: "windows" })
      ).json() as DeviceBody;

      const deleted = await authed(token, {
        method: "DELETE",
        url: `/v1/devices/${created.id}`,
      });
      expect(deleted.statusCode).toBe(204);
      expect(deleted.body).toBe("");

      const list = (await authed(token, { method: "GET", url: "/v1/devices" })).json();
      expect(list).toEqual([]);

      const again = await authed(token, {
        method: "DELETE",
        url: `/v1/devices/${created.id}`,
      });
      expect(again.statusCode).toBe(404);
      const patch = await authed(token, {
        method: "PATCH",
        url: `/v1/devices/${created.id}`,
        payload: { name: "zombie" },
      });
      expect(patch.statusCode).toBe(404);

      // The row is really gone.
      const rows = await handle.db.execute<{ n: number }>(
        sql`select count(*)::int as n from devices where id = ${created.id}`,
      );
      expect(rows[0].n).toBe(0);
    });
  });

  describe("listAndroidPushTargets", () => {
    it("returns enabled android devices with a token, keeping each soundEnabled value", async () => {
      const token = await accessTokenFor("alice@example.com");
      const other = await accessTokenFor("bob@example.com");

      // Included: enabled android with a token (two of them, one muted).
      const loud = (
        await registerDevice(token, {
          name: "loud phone",
          platform: "android",
          fcmToken: "token-loud",
        })
      ).json() as DeviceBody;
      const mutedCreated = (
        await registerDevice(token, {
          name: "muted phone",
          platform: "android",
          fcmToken: "token-muted",
          soundEnabled: false,
        })
      ).json() as DeviceBody;

      // Excluded: disabled, tokenless, non-android, and foreign-user devices.
      await registerDevice(token, {
        name: "disabled phone",
        platform: "android",
        fcmToken: "token-disabled",
        enabled: false,
      });
      await registerDevice(token, { name: "tokenless phone", platform: "android" });
      await registerDevice(token, {
        name: "desktop",
        platform: "windows",
        fcmToken: "token-desktop",
      });
      await registerDevice(other, {
        name: "bob phone",
        platform: "android",
        fcmToken: "token-bob",
      });

      // The muted phone later re-enables sound; the target must reflect it.
      const remuted = await authed(token, {
        method: "PATCH",
        url: `/v1/devices/${mutedCreated.id}`,
        payload: { soundEnabled: false },
      });
      expect(remuted.statusCode).toBe(200);

      const alice = (
        (await handle.db.execute<{ id: string }>(
          sql`select id from users where email = 'alice@example.com'`,
        )) as { id: string }[]
      )[0];
      const repository = new DrizzleDeviceRepository(handle.db);
      const targets = await repository.listAndroidPushTargets(alice.id);

      expect(targets).toHaveLength(2);
      const byId = new Map(targets.map((t) => [t.id, t]));
      expect(byId.get(loud.id)).toEqual({
        id: loud.id,
        fcmToken: "token-loud",
        soundEnabled: true,
      });
      expect(byId.get(mutedCreated.id)).toEqual({
        id: mutedCreated.id,
        fcmToken: "token-muted",
        soundEnabled: false,
      });

      // A device deleted afterwards no longer appears.
      await authed(token, { method: "DELETE", url: `/v1/devices/${loud.id}` });
      const after = await repository.listAndroidPushTargets(alice.id);
      expect(after.map((t) => t.id)).toEqual([mutedCreated.id]);

      // Bob's query sees only Bob's target.
      const bob = (
        (await handle.db.execute<{ id: string }>(
          sql`select id from users where email = 'bob@example.com'`,
        )) as { id: string }[]
      )[0];
      const bobTargets = await repository.listAndroidPushTargets(bob.id);
      expect(bobTargets).toEqual([
        { id: expect.any(String), fcmToken: "token-bob", soundEnabled: true },
      ]);
    });
  });
});
