import { and, eq, isNull, lt, or } from "drizzle-orm";
import type { PostgresJsDatabase } from "drizzle-orm/postgres-js";

import * as schema from "../../db/schema.js";
import { ingestKeys } from "../../db/schema.js";

/** An ingest key as list responses see it: metadata only, never the hash. */
export interface IngestKeyRecord {
  id: string;
  userId: string;
  keyId: string;
  name: string;
  createdAt: Date;
  lastUsedAt: Date | null;
}

/** The stored secret hash of a still-active key, for credential verification. */
export interface ActiveIngestKeySecret {
  id: string;
  userId: string;
  keyId: string;
  secretHash: string;
}

/**
 * Persistence boundary of the ingest-keys module. Revocation is a soft
 * delete (revoked_at): revoked keys vanish from list and verification but
 * the row stays for audit. Every method besides `findActiveByKeyId` is
 * scoped to the owning user, so foreign ids are indistinguishable from
 * unknown ids.
 */
export interface IngestKeyRepository {
  /** The user's still-active keys, oldest first. */
  list(userId: string): Promise<IngestKeyRecord[]>;
  create(input: {
    userId: string;
    keyId: string;
    secretHash: string;
    name: string;
  }): Promise<IngestKeyRecord>;
  /**
   * Sets `revokedAt` on the user's active key. Returns false when no active
   * key with `id` belongs to `userId` (unknown, foreign, or already revoked).
   */
  revoke(input: { userId: string; id: string }): Promise<boolean>;
  /** Records an accepted event request for the user's active key. */
  recordUse(input: { userId: string; id: string; usedAt: Date }): Promise<void>;
  /** Lookup by the public keyId for credential verification; active keys only. */
  findActiveByKeyId(keyId: string): Promise<ActiveIngestKeySecret | null>;
}

const ingestKeyColumns = {
  id: ingestKeys.id,
  userId: ingestKeys.userId,
  keyId: ingestKeys.keyId,
  name: ingestKeys.name,
  createdAt: ingestKeys.createdAt,
  lastUsedAt: ingestKeys.lastUsedAt,
} as const;

export class DrizzleIngestKeyRepository implements IngestKeyRepository {
  constructor(private readonly db: PostgresJsDatabase<typeof schema>) {}

  async list(userId: string): Promise<IngestKeyRecord[]> {
    const rows = await this.db
      .select(ingestKeyColumns)
      .from(ingestKeys)
      .where(and(eq(ingestKeys.userId, userId), isNull(ingestKeys.revokedAt)))
      .orderBy(ingestKeys.createdAt);
    return rows;
  }

  async create(input: {
    userId: string;
    keyId: string;
    secretHash: string;
    name: string;
  }): Promise<IngestKeyRecord> {
    const rows = await this.db
      .insert(ingestKeys)
      .values({
        userId: input.userId,
        keyId: input.keyId,
        secretHash: input.secretHash,
        name: input.name,
      })
      .returning(ingestKeyColumns);
    return rows[0] as IngestKeyRecord;
  }

  async revoke(input: { userId: string; id: string }): Promise<boolean> {
    // The id + userId + not-yet-revoked predicate enforces ownership and
    // idempotence in one statement: foreign or stale ids simply match no row.
    const rows = await this.db
      .update(ingestKeys)
      .set({ revokedAt: new Date() })
      .where(
        and(
          eq(ingestKeys.id, input.id),
          eq(ingestKeys.userId, input.userId),
          isNull(ingestKeys.revokedAt),
        ),
      )
      .returning({ id: ingestKeys.id });
    return rows.length > 0;
  }

  async recordUse(input: { userId: string; id: string; usedAt: Date }): Promise<void> {
    await this.db
      .update(ingestKeys)
      .set({ lastUsedAt: input.usedAt })
      .where(
        and(
          eq(ingestKeys.id, input.id),
          eq(ingestKeys.userId, input.userId),
          isNull(ingestKeys.revokedAt),
          or(isNull(ingestKeys.lastUsedAt), lt(ingestKeys.lastUsedAt, input.usedAt)),
        ),
      );
  }

  async findActiveByKeyId(keyId: string): Promise<ActiveIngestKeySecret | null> {
    const rows = await this.db
      .select({
        id: ingestKeys.id,
        userId: ingestKeys.userId,
        keyId: ingestKeys.keyId,
        secretHash: ingestKeys.secretHash,
      })
      .from(ingestKeys)
      .where(and(eq(ingestKeys.keyId, keyId), isNull(ingestKeys.revokedAt)))
      .limit(1);
    return rows[0] ?? null;
  }
}
