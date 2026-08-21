import { and, asc, eq, isNull } from "drizzle-orm";
import type { PostgresJsDatabase } from "drizzle-orm/postgres-js";

import * as schema from "../../db/schema.js";
import { adminUsers, refreshTokenFamilies, registrationWhitelist, users } from "../../db/schema.js";
import { DuplicateEmailError } from "../auth/auth.repository.js";

/** PostgreSQL error code of a unique-constraint violation (postgres-js). */
const PG_UNIQUE_VIOLATION = "23505";

/**
 * True when the error (or any wrapped `cause` — drizzle wraps driver
 * errors in DrizzleQueryError) is a unique-constraint violation.
 */
function isUniqueViolation(error: unknown, depth = 0): boolean {
  if (typeof error !== "object" || error === null || depth > 4) {
    return false;
  }
  const record = error as { code?: unknown; cause?: unknown };
  if (record.code === PG_UNIQUE_VIOLATION) {
    return true;
  }
  return isUniqueViolation(record.cause, depth + 1);
}

export interface AdminAccountRecord {
  id: string;
  username: string;
  passwordHash: string;
}

/** Panel-facing projection of a user row (never the password hash). */
export interface AdminUserRecord {
  id: string;
  email: string;
  verified: boolean;
  createdAt: Date;
}

export type WhitelistKind = "domain" | "email";

export interface WhitelistEntry {
  kind: WhitelistKind;
  value: string;
}

export interface WhitelistSnapshot {
  domains: string[];
  emails: string[];
}

/**
 * Persistence boundary of the admin module: the operator account, the
 * panel's user management, and the registration whitelist. Values are
 * normalized (lowercase, trimmed) by the service before they get here.
 */
export interface AdminRepository {
  /** Idempotent startup seed; never overwrites an existing account. */
  ensureAdminAccount(input: { username: string; passwordHash: string }): Promise<void>;
  /** Number of operator rows; zero triggers lazy seeding on first login. */
  countAdminAccounts(): Promise<number>;
  findAdminByUsername(username: string): Promise<AdminAccountRecord | null>;
  findAdminById(id: string): Promise<AdminAccountRecord | null>;
  updateAdminPassword(input: { id: string; passwordHash: string; now: Date }): Promise<void>;
  listUsers(): Promise<AdminUserRecord[]>;
  /** @throws DuplicateEmailError when the normalized email already exists. */
  createVerifiedUser(input: {
    email: string;
    passwordHash: string;
    now: Date;
  }): Promise<AdminUserRecord>;
  /**
   * Replace the user's password hash and revoke every live refresh-token
   * family in one transaction. Returns false when the user id is unknown.
   */
  setUserPassword(input: {
    userId: string;
    passwordHash: string;
    now: Date;
  }): Promise<boolean>;
  listWhitelist(): Promise<WhitelistEntry[]>;
  /** Replace the whole whitelist atomically. */
  replaceWhitelist(entries: WhitelistEntry[]): Promise<void>;
}

export class DrizzleAdminRepository implements AdminRepository {
  constructor(private readonly db: PostgresJsDatabase<typeof schema>) {}

  async ensureAdminAccount(input: { username: string; passwordHash: string }): Promise<void> {
    await this.db
      .insert(adminUsers)
      .values({ username: input.username, passwordHash: input.passwordHash })
      .onConflictDoNothing({ target: adminUsers.username });
  }

  async countAdminAccounts(): Promise<number> {
    const rows = await this.db
      .select({ id: adminUsers.id })
      .from(adminUsers)
      .limit(1);
    return rows.length;
  }

  async findAdminByUsername(username: string): Promise<AdminAccountRecord | null> {
    const rows = await this.db
      .select({
        id: adminUsers.id,
        username: adminUsers.username,
        passwordHash: adminUsers.passwordHash,
      })
      .from(adminUsers)
      .where(eq(adminUsers.username, username))
      .limit(1);
    return rows[0] ?? null;
  }

  async findAdminById(id: string): Promise<AdminAccountRecord | null> {
    const rows = await this.db
      .select({
        id: adminUsers.id,
        username: adminUsers.username,
        passwordHash: adminUsers.passwordHash,
      })
      .from(adminUsers)
      .where(eq(adminUsers.id, id))
      .limit(1);
    return rows[0] ?? null;
  }

  async updateAdminPassword(input: { id: string; passwordHash: string; now: Date }): Promise<void> {
    await this.db
      .update(adminUsers)
      .set({ passwordHash: input.passwordHash, updatedAt: input.now })
      .where(eq(adminUsers.id, input.id));
  }

  async listUsers(): Promise<AdminUserRecord[]> {
    const rows = await this.db
      .select({
        id: users.id,
        email: users.email,
        emailVerifiedAt: users.emailVerifiedAt,
        createdAt: users.createdAt,
      })
      .from(users)
      .orderBy(asc(users.createdAt));
    return rows.map((row) => ({
      id: row.id,
      email: row.email,
      verified: row.emailVerifiedAt !== null,
      createdAt: row.createdAt,
    }));
  }

  async createVerifiedUser(input: {
    email: string;
    passwordHash: string;
    now: Date;
  }): Promise<AdminUserRecord> {
    try {
      const rows = await this.db
        .insert(users)
        .values({
          email: input.email,
          passwordHash: input.passwordHash,
          emailVerifiedAt: input.now,
        })
        .returning({
          id: users.id,
          email: users.email,
          emailVerifiedAt: users.emailVerifiedAt,
          createdAt: users.createdAt,
        });
      const row = rows[0];
      if (row === undefined) {
        throw new Error("insert returned no row");
      }
      return {
        id: row.id,
        email: row.email,
        verified: row.emailVerifiedAt !== null,
        createdAt: row.createdAt,
      };
    } catch (error) {
      if (isUniqueViolation(error)) {
        throw new DuplicateEmailError();
      }
      throw error;
    }
  }

  async setUserPassword(input: {
    userId: string;
    passwordHash: string;
    now: Date;
  }): Promise<boolean> {
    return this.db.transaction(async (tx) => {
      const rows = await tx
        .update(users)
        .set({ passwordHash: input.passwordHash, updatedAt: input.now })
        .where(eq(users.id, input.userId))
        .returning({ id: users.id });
      if (rows.length === 0) {
        return false;
      }
      await tx
        .update(refreshTokenFamilies)
        .set({ revokedAt: input.now })
        .where(
          and(
            eq(refreshTokenFamilies.userId, input.userId),
            isNull(refreshTokenFamilies.revokedAt),
          ),
        );
      return true;
    });
  }

  async listWhitelist(): Promise<WhitelistEntry[]> {
    const rows = await this.db
      .select({ kind: registrationWhitelist.kind, value: registrationWhitelist.value })
      .from(registrationWhitelist)
      .orderBy(asc(registrationWhitelist.value));
    return rows.map((row) => ({
      kind: row.kind as WhitelistKind,
      value: row.value,
    }));
  }

  async replaceWhitelist(entries: WhitelistEntry[]): Promise<void> {
    await this.db.transaction(async (tx) => {
      await tx.delete(registrationWhitelist);
      if (entries.length > 0) {
        await tx.insert(registrationWhitelist).values(entries);
      }
    });
  }
}
