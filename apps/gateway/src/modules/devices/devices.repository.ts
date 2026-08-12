import { and, eq, isNotNull } from "drizzle-orm";
import type { PostgresJsDatabase } from "drizzle-orm/postgres-js";

import * as schema from "../../db/schema.js";
import { devices } from "../../db/schema.js";

export type DevicePlatform = "windows" | "linux" | "android";

export interface DeviceRecord {
  id: string;
  userId: string;
  name: string;
  platform: DevicePlatform;
  fcmToken: string | null;
  enabled: boolean;
  soundEnabled: boolean;
}

/**
 * Fields a PATCH may change; `platform` is fixed at registration.
 * `fcmToken` may be set to null to clear a dead token (the push dispatcher
 * does this when FCM reports the token invalid/unregistered) without
 * touching the device itself or its enabled/sound preferences.
 */
export interface DevicePatch {
  name?: string;
  enabled?: boolean;
  soundEnabled?: boolean;
  fcmToken?: string | null;
}

/** An enabled android device with a live FCM token, ready for a push. */
export interface AndroidPushTarget {
  id: string;
  fcmToken: string;
  soundEnabled: boolean;
}

/**
 * Persistence boundary of the devices module. Every method is scoped to the
 * owning user: cross-user ids are indistinguishable from unknown ids
 * (update/delete return null/false, never another user's row).
 */
export interface DeviceRepository {
  list(userId: string): Promise<DeviceRecord[]>;
  create(input: {
    userId: string;
    name: string;
    platform: DevicePlatform;
    fcmToken?: string;
    enabled: boolean;
    soundEnabled: boolean;
  }): Promise<DeviceRecord>;
  /** Returns null when no device with `id` belongs to `userId`. */
  update(input: {
    userId: string;
    id: string;
    patch: DevicePatch;
  }): Promise<DeviceRecord | null>;
  /** Returns false when no device with `id` belongs to `userId`. */
  delete(input: { userId: string; id: string }): Promise<boolean>;
  /**
   * Push dispatch source of the notification worker (a later task): the
   * user's enabled android devices that hold an FCM token, each with its
   * current sound preference. Never returns rows of another user.
   */
  listAndroidPushTargets(userId: string): Promise<AndroidPushTarget[]>;
}

const deviceColumns = {
  id: devices.id,
  userId: devices.userId,
  name: devices.name,
  platform: devices.platform,
  fcmToken: devices.fcmToken,
  enabled: devices.enabled,
  soundEnabled: devices.soundEnabled,
} as const;

export class DrizzleDeviceRepository implements DeviceRepository {
  constructor(private readonly db: PostgresJsDatabase<typeof schema>) {}

  async list(userId: string): Promise<DeviceRecord[]> {
    const rows = await this.db
      .select(deviceColumns)
      .from(devices)
      .where(eq(devices.userId, userId))
      .orderBy(devices.createdAt);
    return rows as DeviceRecord[];
  }

  async create(input: {
    userId: string;
    name: string;
    platform: DevicePlatform;
    fcmToken?: string;
    enabled: boolean;
    soundEnabled: boolean;
  }): Promise<DeviceRecord> {
    const rows = await this.db
      .insert(devices)
      .values({
        userId: input.userId,
        name: input.name,
        platform: input.platform,
        fcmToken: input.fcmToken,
        enabled: input.enabled,
        soundEnabled: input.soundEnabled,
      })
      .returning(deviceColumns);
    return rows[0] as DeviceRecord;
  }

  async update(input: {
    userId: string;
    id: string;
    patch: DevicePatch;
  }): Promise<DeviceRecord | null> {
    // The id + userId predicate takes the row lock and enforces ownership in
    // one statement: a foreign id simply matches no row and returns null.
    const rows = await this.db
      .update(devices)
      .set(input.patch)
      .where(and(eq(devices.id, input.id), eq(devices.userId, input.userId)))
      .returning(deviceColumns);
    return (rows[0] as DeviceRecord | undefined) ?? null;
  }

  async delete(input: { userId: string; id: string }): Promise<boolean> {
    const rows = await this.db
      .delete(devices)
      .where(and(eq(devices.id, input.id), eq(devices.userId, input.userId)))
      .returning({ id: devices.id });
    return rows.length > 0;
  }

  async listAndroidPushTargets(userId: string): Promise<AndroidPushTarget[]> {
    const rows = await this.db
      .select({
        id: devices.id,
        fcmToken: devices.fcmToken,
        soundEnabled: devices.soundEnabled,
      })
      .from(devices)
      .where(
        and(
          eq(devices.userId, userId),
          eq(devices.platform, "android"),
          eq(devices.enabled, true),
          isNotNull(devices.fcmToken),
        ),
      );
    // The WHERE clause guarantees fcmToken non-null; narrow for the caller.
    return rows as AndroidPushTarget[];
  }
}
