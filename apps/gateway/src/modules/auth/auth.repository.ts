import { and, eq, gt, isNull } from "drizzle-orm";
import type { PostgresJsDatabase } from "drizzle-orm/postgres-js";

import * as schema from "../../db/schema.js";
import {
  emailVerificationTokens,
  passwordResetTokens,
  refreshTokenFamilies,
  refreshTokens,
  users,
} from "../../db/schema.js";

export interface UserRecord {
  id: string;
  email: string;
  passwordHash: string;
  emailVerifiedAt: Date | null;
}

export interface VerificationTokenRecord {
  userId: string;
  tokenHash: string;
  expiresAt: Date;
  consumedAt: Date | null;
}

/** A refresh token row joined with its family's revocation state. */
export interface RefreshTokenRecord {
  id: string;
  familyId: string;
  userId: string;
  tokenHash: string;
  expiresAt: Date;
  rotatedAt: Date | null;
  familyRevokedAt: Date | null;
}

/** Outcome of the atomic rotation compare-and-set. */
export type RotationOutcome =
  /** The presented token won the CAS and `next` is now the family's live token. */
  | "rotated"
  /**
   * The presented token was already rotated (replay or concurrent loser);
   * the family has been revoked by this call.
   */
  | "reused";

/**
 * The email already exists in normalized form. Raised by repositories on a
 * unique-constraint race so services can report EMAIL_TAKEN without a
 * separate lookup round-trip being trustworthy.
 */
export class DuplicateEmailError extends Error {
  constructor(message = "Email already registered") {
    super(message);
    this.name = "DuplicateEmailError";
  }
}

/**
 * Persistence boundary of the auth module. All reads and writes see only
 * normalized emails; callers normalize before calling.
 */
export interface AuthRepository {
  findUserByEmail(email: string): Promise<UserRecord | null>;
  /** @throws DuplicateEmailError when the normalized email already exists. */
  createUser(input: { email: string; passwordHash: string }): Promise<UserRecord>;
  createVerificationToken(input: {
    userId: string;
    tokenHash: string;
    expiresAt: Date;
  }): Promise<void>;
  /**
   * Atomically consumes the matching, unconsumed, unexpired token and marks
   * the user verified in the same transaction. Returns false when no live
   * token matches (unknown, expired, or already consumed — indistinguishable
   * by design). Concurrent calls for the same code produce exactly one true.
   */
  consumeVerificationToken(input: {
    userId: string;
    tokenHash: string;
    now: Date;
  }): Promise<boolean>;

  createPasswordResetToken(input: {
    userId: string;
    tokenHash: string;
    expiresAt: Date;
  }): Promise<void>;
  /**
   * Atomically consumes the matching, unconsumed, unexpired reset token,
   * replaces the user's password hash, and revokes every refresh-token
   * family of the user — all in one transaction, so a reset either takes
   * full effect or none. Returns false when no live token matches
   * (unknown, expired, or already consumed — indistinguishable by design).
   * Concurrent calls for the same code produce exactly one true.
   */
  consumePasswordResetToken(input: {
    userId: string;
    tokenHash: string;
    now: Date;
    passwordHash: string;
  }): Promise<boolean>;

  /**
   * Start a new session family for a user (one per login) AND append its
   * first token in a single transaction: a failure rolls both back, so a
   * family without any usable token can never persist. The plaintext never
   * crosses this boundary.
   */
  createRefreshSession(input: {
    userId: string;
    tokenHash: string;
    expiresAt: Date;
  }): Promise<{ familyId: string }>;
  /** Look a token up by its hash, joined with the family's revocation state. */
  findRefreshTokenByHash(tokenHash: string): Promise<RefreshTokenRecord | null>;
  /**
   * Atomically rotate a token: a conditional
   * `UPDATE ... SET rotated_at = now WHERE id = ? AND rotated_at IS NULL`
   * takes the row lock, so concurrent rotations of the same token serialize
   * and exactly one wins. The winner inserts `next` into the same family in
   * the same transaction; the loser revokes the whole family (which also
   * invalidates the winner's freshly issued successor, because every refresh
   * re-checks the family) and reports "reused".
   */
  rotateRefreshToken(input: {
    tokenId: string;
    familyId: string;
    now: Date;
    next: { tokenHash: string; expiresAt: Date };
  }): Promise<RotationOutcome>;
  /** Revoke a family; no-op when it is already revoked (idempotent logout). */
  revokeRefreshFamily(familyId: string, now: Date): Promise<void>;
}

/** PostgreSQL error code of a unique-constraint violation (postgres-js). */
const PG_UNIQUE_VIOLATION = "23505";

function isUniqueViolation(error: unknown): boolean {
  return (
    typeof error === "object" &&
    error !== null &&
    (error as { code?: unknown }).code === PG_UNIQUE_VIOLATION
  );
}

export class DrizzleAuthRepository implements AuthRepository {
  constructor(private readonly db: PostgresJsDatabase<typeof schema>) {}

  async findUserByEmail(email: string): Promise<UserRecord | null> {
    const rows = await this.db
      .select({
        id: users.id,
        email: users.email,
        passwordHash: users.passwordHash,
        emailVerifiedAt: users.emailVerifiedAt,
      })
      .from(users)
      .where(eq(users.email, email))
      .limit(1);
    return rows[0] ?? null;
  }

  async createUser(input: { email: string; passwordHash: string }): Promise<UserRecord> {
    try {
      const rows = await this.db
        .insert(users)
        .values({ email: input.email, passwordHash: input.passwordHash })
        .returning({
          id: users.id,
          email: users.email,
          passwordHash: users.passwordHash,
          emailVerifiedAt: users.emailVerifiedAt,
        });
      return rows[0];
    } catch (error) {
      if (isUniqueViolation(error)) {
        throw new DuplicateEmailError();
      }
      throw error;
    }
  }

  async createVerificationToken(input: {
    userId: string;
    tokenHash: string;
    expiresAt: Date;
  }): Promise<void> {
    await this.db.insert(emailVerificationTokens).values({
      userId: input.userId,
      tokenHash: input.tokenHash,
      expiresAt: input.expiresAt,
    });
  }

  async consumeVerificationToken(input: {
    userId: string;
    tokenHash: string;
    now: Date;
  }): Promise<boolean> {
    return this.db.transaction(async (tx) => {
      // The conditional UPDATE takes the row lock: concurrent transactions
      // for the same token serialize, and only the first sees the row in
      // its unconsumed state.
      const consumed = await tx
        .update(emailVerificationTokens)
        .set({ consumedAt: input.now })
        .where(
          and(
            eq(emailVerificationTokens.userId, input.userId),
            eq(emailVerificationTokens.tokenHash, input.tokenHash),
            isNull(emailVerificationTokens.consumedAt),
            gt(emailVerificationTokens.expiresAt, input.now),
          ),
        )
        .returning({ id: emailVerificationTokens.id });
      if (consumed.length === 0) {
        return false;
      }
      await tx
        .update(users)
        .set({ emailVerifiedAt: input.now, updatedAt: input.now })
        .where(eq(users.id, input.userId));
      return true;
    });
  }

  async createPasswordResetToken(input: {
    userId: string;
    tokenHash: string;
    expiresAt: Date;
  }): Promise<void> {
    await this.db.insert(passwordResetTokens).values({
      userId: input.userId,
      tokenHash: input.tokenHash,
      expiresAt: input.expiresAt,
    });
  }

  async consumePasswordResetToken(input: {
    userId: string;
    tokenHash: string;
    now: Date;
    passwordHash: string;
  }): Promise<boolean> {
    return this.db.transaction(async (tx) => {
      // The conditional UPDATE takes the row lock: concurrent resets for
      // the same code serialize, and only the first sees the row in its
      // unconsumed state.
      const consumed = await tx
        .update(passwordResetTokens)
        .set({ consumedAt: input.now })
        .where(
          and(
            eq(passwordResetTokens.userId, input.userId),
            eq(passwordResetTokens.tokenHash, input.tokenHash),
            isNull(passwordResetTokens.consumedAt),
            gt(passwordResetTokens.expiresAt, input.now),
          ),
        )
        .returning({ id: passwordResetTokens.id });
      if (consumed.length === 0) {
        return false;
      }
      await tx
        .update(users)
        .set({ passwordHash: input.passwordHash, updatedAt: input.now })
        .where(eq(users.id, input.userId));
      // Password changed: every existing session of the user dies here, in
      // the same transaction as the hash replacement.
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

  async createRefreshSession(input: {
    userId: string;
    tokenHash: string;
    expiresAt: Date;
  }): Promise<{ familyId: string }> {
    return this.db.transaction(async (tx) => {
      const families = await tx
        .insert(refreshTokenFamilies)
        .values({ userId: input.userId })
        .returning({ id: refreshTokenFamilies.id });
      const family = families[0];
      await tx.insert(refreshTokens).values({
        familyId: family.id,
        tokenHash: input.tokenHash,
        expiresAt: input.expiresAt,
      });
      return { familyId: family.id };
    });
  }

  async findRefreshTokenByHash(tokenHash: string): Promise<RefreshTokenRecord | null> {
    const rows = await this.db
      .select({
        id: refreshTokens.id,
        familyId: refreshTokens.familyId,
        userId: refreshTokenFamilies.userId,
        tokenHash: refreshTokens.tokenHash,
        expiresAt: refreshTokens.expiresAt,
        rotatedAt: refreshTokens.rotatedAt,
        familyRevokedAt: refreshTokenFamilies.revokedAt,
      })
      .from(refreshTokens)
      .innerJoin(
        refreshTokenFamilies,
        eq(refreshTokens.familyId, refreshTokenFamilies.id),
      )
      .where(eq(refreshTokens.tokenHash, tokenHash))
      .limit(1);
    return rows[0] ?? null;
  }

  async rotateRefreshToken(input: {
    tokenId: string;
    familyId: string;
    now: Date;
    next: { tokenHash: string; expiresAt: Date };
  }): Promise<RotationOutcome> {
    return this.db.transaction(async (tx) => {
      // The conditional UPDATE takes the row lock: concurrent rotations of
      // the same token serialize, and only the first sees rotated_at NULL.
      const rotated = await tx
        .update(refreshTokens)
        .set({ rotatedAt: input.now })
        .where(and(eq(refreshTokens.id, input.tokenId), isNull(refreshTokens.rotatedAt)))
        .returning({ id: refreshTokens.id });
      if (rotated.length === 0) {
        // Reuse detected (replay or concurrent loser): kill the family so
        // even the winner's concurrently issued successor becomes unusable.
        await tx
          .update(refreshTokenFamilies)
          .set({ revokedAt: input.now })
          .where(
            and(
              eq(refreshTokenFamilies.id, input.familyId),
              isNull(refreshTokenFamilies.revokedAt),
            ),
          );
        return "reused";
      }
      await tx.insert(refreshTokens).values({
        familyId: input.familyId,
        tokenHash: input.next.tokenHash,
        expiresAt: input.next.expiresAt,
      });
      return "rotated";
    });
  }

  async revokeRefreshFamily(familyId: string, now: Date): Promise<void> {
    await this.db
      .update(refreshTokenFamilies)
      .set({ revokedAt: now })
      .where(
        and(
          eq(refreshTokenFamilies.id, familyId),
          isNull(refreshTokenFamilies.revokedAt),
        ),
      );
  }
}
