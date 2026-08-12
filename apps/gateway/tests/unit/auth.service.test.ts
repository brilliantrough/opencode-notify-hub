import argon2 from "argon2";
import { describe, expect, it } from "vitest";

import type { Clock } from "../../src/lib/clock.js";
import { generateVerificationCode, sha256Hex } from "../../src/lib/crypto.js";
import type { Mailer } from "../../src/modules/mail/mailer.js";
import type {
  AuthRepository,
  RefreshTokenRecord,
  RotationOutcome,
  UserRecord,
  VerificationTokenRecord,
} from "../../src/modules/auth/auth.repository.js";
import { DuplicateEmailError } from "../../src/modules/auth/auth.repository.js";
import { AuthError, AuthService } from "../../src/modules/auth/auth.service.js";
import { createAccessTokens } from "../../src/plugins/jwt.js";

/** Deterministic, manually advanced clock. */
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

interface SentVerification {
  to: string;
  code: string;
}

/** Captures outgoing mail; can be switched to fail like an SMTP outage. */
class FakeMailer implements Mailer {
  verificationEmails: SentVerification[] = [];
  failing = false;

  async sendVerificationEmail(to: string, code: string): Promise<void> {
    if (this.failing) {
      throw new Error("SMTP connection refused");
    }
    this.verificationEmails.push({ to, code });
  }

  async sendPasswordResetEmail(_to: string, _code: string): Promise<void> {
    throw new Error("not implemented in this fake");
  }
}

/**
 * In-memory repository that models the real one's semantics, including the
 * atomic single-use consume: only the first call for a live token wins.
 */
class FakeAuthRepository implements AuthRepository {
  readonly users: UserRecord[] = [];
  readonly tokens: VerificationTokenRecord[] = [];
  readonly resetTokens: VerificationTokenRecord[] = [];
  readonly families: { id: string; userId: string; revokedAt: Date | null }[] = [];
  readonly refreshTokens: RefreshTokenRecord[] = [];
  private nextId = 1;

  async findUserByEmail(email: string): Promise<UserRecord | null> {
    return this.users.find((user) => user.email === email) ?? null;
  }

  async createUser(input: { email: string; passwordHash: string }): Promise<UserRecord> {
    if (this.users.some((user) => user.email === input.email)) {
      throw new DuplicateEmailError();
    }
    const user: UserRecord = {
      id: `user-${this.nextId++}`,
      email: input.email,
      passwordHash: input.passwordHash,
      emailVerifiedAt: null,
    };
    this.users.push(user);
    return user;
  }

  async createVerificationToken(input: {
    userId: string;
    tokenHash: string;
    expiresAt: Date;
  }): Promise<void> {
    this.tokens.push({ ...input, consumedAt: null });
  }

  async consumeVerificationToken(input: {
    userId: string;
    tokenHash: string;
    now: Date;
  }): Promise<boolean> {
    const token = this.tokens.find(
      (candidate) =>
        candidate.userId === input.userId &&
        candidate.tokenHash === input.tokenHash &&
        candidate.consumedAt === null &&
        candidate.expiresAt.getTime() > input.now.getTime(),
    );
    if (token === undefined) {
      return false;
    }
    token.consumedAt = input.now;
    const user = this.users.find((candidate) => candidate.id === input.userId);
    if (user !== undefined) {
      user.emailVerifiedAt = input.now;
    }
    return true;
  }

  async createPasswordResetToken(input: {
    userId: string;
    tokenHash: string;
    expiresAt: Date;
  }): Promise<void> {
    this.resetTokens.push({ ...input, consumedAt: null });
  }

  async consumePasswordResetToken(input: {
    userId: string;
    tokenHash: string;
    now: Date;
    passwordHash: string;
  }): Promise<boolean> {
    const token = this.resetTokens.find(
      (candidate) =>
        candidate.userId === input.userId &&
        candidate.tokenHash === input.tokenHash &&
        candidate.consumedAt === null &&
        candidate.expiresAt.getTime() > input.now.getTime(),
    );
    if (token === undefined) {
      return false;
    }
    token.consumedAt = input.now;
    const user = this.users.find((candidate) => candidate.id === input.userId);
    if (user !== undefined) {
      user.passwordHash = input.passwordHash;
    }
    for (const family of this.families) {
      if (family.userId === input.userId && family.revokedAt === null) {
        family.revokedAt = input.now;
      }
    }
    return true;
  }

  /** When true, the session creation of a login fails (models a DB error mid-login). */
  failFirstTokenInsert = false;

  async createRefreshSession(input: {
    userId: string;
    tokenHash: string;
    expiresAt: Date;
  }): Promise<{ familyId: string }> {
    if (this.failFirstTokenInsert) {
      throw new Error("refresh session insert failed");
    }
    // Models the real repository's transaction: family and first token
    // appear together or not at all.
    const family = { id: `family-${this.nextId++}`, userId: input.userId, revokedAt: null };
    this.families.push(family);
    this.appendRefreshToken(family.id, family.userId, input.tokenHash, input.expiresAt);
    return { familyId: family.id };
  }

  private appendRefreshToken(
    familyId: string,
    userId: string,
    tokenHash: string,
    expiresAt: Date,
  ): void {
    this.refreshTokens.push({
      id: `refresh-${this.nextId++}`,
      familyId,
      userId,
      tokenHash,
      expiresAt,
      rotatedAt: null,
      familyRevokedAt: null,
    });
  }

  async findRefreshTokenByHash(tokenHash: string): Promise<RefreshTokenRecord | null> {
    const token = this.refreshTokens.find((candidate) => candidate.tokenHash === tokenHash);
    if (token === undefined) {
      return null;
    }
    const family = this.families.find((candidate) => candidate.id === token.familyId);
    return { ...token, familyRevokedAt: family?.revokedAt ?? null };
  }

  async rotateRefreshToken(input: {
    tokenId: string;
    familyId: string;
    now: Date;
    next: { tokenHash: string; expiresAt: Date };
  }): Promise<RotationOutcome> {
    const token = this.refreshTokens.find((candidate) => candidate.id === input.tokenId);
    const family = this.families.find((candidate) => candidate.id === input.familyId);
    if (token === undefined || token.rotatedAt !== null) {
      if (family !== undefined && family.revokedAt === null) {
        family.revokedAt = input.now;
      }
      return "reused";
    }
    token.rotatedAt = input.now;
    this.appendRefreshToken(input.familyId, token.userId, input.next.tokenHash, input.next.expiresAt);
    return "rotated";
  }

  async revokeRefreshFamily(familyId: string, now: Date): Promise<void> {
    const family = this.families.find((candidate) => candidate.id === familyId);
    if (family !== undefined && family.revokedAt === null) {
      family.revokedAt = now;
    }
  }
}

const TEST_SIGNING_KEY = Buffer.from("0123456789abcdef0123456789abcdef").toString("base64");

function makeService() {
  const repo = new FakeAuthRepository();
  const mailer = new FakeMailer();
  const clock = new FakeClock();
  const service = new AuthService({
    repository: repo,
    mailer,
    clock,
    accessTokens: createAccessTokens({ signingKey: TEST_SIGNING_KEY, clock }),
  });
  return { service, repo, mailer, clock };
}

const PASSWORD = "correct horse battery staple";
const TWENTY_FOUR_HOURS_MS = 24 * 60 * 60 * 1000;

describe("generateVerificationCode", () => {
  it("returns exactly eight alphanumeric characters", () => {
    for (let i = 0; i < 100; i += 1) {
      expect(generateVerificationCode()).toMatch(/^[A-Za-z0-9]{8}$/);
    }
  });
});

describe("AuthService.register", () => {
  it("normalizes the email before persisting it", async () => {
    const { service, repo } = makeService();
    await service.register("  Alice@Example.COM  ", PASSWORD);
    expect(repo.users).toHaveLength(1);
    expect(repo.users[0].email).toBe("alice@example.com");
  });

  it("stores an Argon2id password hash, never the plaintext", async () => {
    const { service, repo } = makeService();
    await service.register("alice@example.com", PASSWORD);
    const hash = repo.users[0].passwordHash;
    expect(hash).toMatch(/^\$argon2id\$/);
    expect(hash).not.toContain(PASSWORD);
    await expect(argon2.verify(hash, PASSWORD)).resolves.toBe(true);
    await expect(argon2.verify(hash, "wrong password")).resolves.toBe(false);
  });

  it("emails the plaintext code but stores only its SHA-256 hash", async () => {
    const { service, repo, mailer } = makeService();
    await service.register("alice@example.com", PASSWORD);

    expect(mailer.verificationEmails).toHaveLength(1);
    const { to, code } = mailer.verificationEmails[0];
    expect(to).toBe("alice@example.com");
    expect(code).toMatch(/^[A-Za-z0-9]{8}$/);

    expect(repo.tokens).toHaveLength(1);
    expect(repo.tokens[0].tokenHash).toBe(sha256Hex(code));
    expect(repo.tokens[0].tokenHash).toMatch(/^[0-9a-f]{64}$/);
    expect(repo.tokens[0].tokenHash).not.toBe(code);
  });

  it("gives the verification code a 24-hour expiry", async () => {
    const { service, repo, clock } = makeService();
    await service.register("alice@example.com", PASSWORD);
    expect(repo.tokens[0].expiresAt.getTime()).toBe(
      clock.nowMs() + TWENTY_FOUR_HOURS_MS,
    );
  });

  it("rejects a duplicate email, even under different case and whitespace", async () => {
    const { service } = makeService();
    await service.register("alice@example.com", PASSWORD);
    await expect(service.register("ALICE@example.com", PASSWORD)).rejects.toMatchObject({
      name: "AuthError",
      kind: "EMAIL_TAKEN",
    });
    await expect(service.register("  alice@example.com ", PASSWORD)).rejects.toMatchObject({
      kind: "EMAIL_TAKEN",
    });
  });

  it("maps a unique-constraint race to EMAIL_TAKEN", async () => {
    const { service, repo } = makeService();
    // Simulate a concurrent insert winning between lookup and insert: the
    // repository reports the unique violation as DuplicateEmailError.
    repo.createUser = async () => {
      throw new DuplicateEmailError();
    };
    await expect(service.register("alice@example.com", PASSWORD)).rejects.toMatchObject({
      kind: "EMAIL_TAKEN",
    });
  });

  it("keeps the account unverified and reports a retryable error when SMTP fails", async () => {
    const { service, repo, mailer } = makeService();
    mailer.failing = true;

    await expect(service.register("alice@example.com", PASSWORD)).rejects.toMatchObject({
      name: "AuthError",
      kind: "MAIL_UNAVAILABLE",
    });

    // The account exists but is unverified; the caller can resend later.
    expect(repo.users).toHaveLength(1);
    expect(repo.users[0].emailVerifiedAt).toBeNull();

    mailer.failing = false;
    await service.resendVerification("alice@example.com");
    expect(mailer.verificationEmails).toHaveLength(1);
  });
});

describe("AuthService.verifyEmail", () => {
  it("verifies the account with the emailed code", async () => {
    const { service, repo, mailer, clock } = makeService();
    await service.register("Alice@example.com", PASSWORD);
    const { code } = mailer.verificationEmails[0];

    clock.advance(60_000);
    await service.verifyEmail("alice@example.com", code);

    const user = repo.users[0];
    expect(user.emailVerifiedAt).toEqual(clock.now());
    const token = repo.tokens[0];
    expect(token.consumedAt).toEqual(clock.now());
  });

  it("consumes the code atomically: a second use is rejected", async () => {
    const { service, mailer } = makeService();
    await service.register("alice@example.com", PASSWORD);
    const { code } = mailer.verificationEmails[0];

    await service.verifyEmail("alice@example.com", code);
    await expect(service.verifyEmail("alice@example.com", code)).rejects.toMatchObject({
      kind: "INVALID_CODE",
    });
  });

  it("rejects a wrong code", async () => {
    const { service, mailer } = makeService();
    await service.register("alice@example.com", PASSWORD);
    const { code } = mailer.verificationEmails[0];
    const wrong = code === "AAAAAAAA" ? "BBBBBBBB" : "AAAAAAAA";

    await expect(service.verifyEmail("alice@example.com", wrong)).rejects.toMatchObject({
      kind: "INVALID_CODE",
    });
    // The real code still works afterwards.
    await service.verifyEmail("alice@example.com", code);
  });

  it("returns the same error for an unknown email (no enumeration)", async () => {
    const { service } = makeService();
    const unknown = await service
      .verifyEmail("nobody@example.com", "AAAAAAAA")
      .then(
        () => null,
        (error: unknown) => error,
      );
    expect(unknown).toBeInstanceOf(AuthError);
    expect((unknown as AuthError).kind).toBe("INVALID_CODE");
  });

  it("rejects an expired code", async () => {
    const { service, mailer, clock } = makeService();
    await service.register("alice@example.com", PASSWORD);
    const { code } = mailer.verificationEmails[0];

    clock.advance(TWENTY_FOUR_HOURS_MS + 1);
    await expect(service.verifyEmail("alice@example.com", code)).rejects.toMatchObject({
      kind: "INVALID_CODE",
    });
  });
});

describe("AuthService.resendVerification", () => {
  it("sends a fresh code for a known unverified account", async () => {
    const { service, mailer } = makeService();
    await service.register("alice@example.com", PASSWORD);
    await service.resendVerification("  ALICE@example.com ");

    expect(mailer.verificationEmails).toHaveLength(2);
    const { code } = mailer.verificationEmails[1];
    expect(code).toMatch(/^[A-Za-z0-9]{8}$/);
    await service.verifyEmail("alice@example.com", code);
  });

  it("silently succeeds for an unknown email without sending mail", async () => {
    const { service, mailer } = makeService();
    await service.resendVerification("nobody@example.com");
    expect(mailer.verificationEmails).toHaveLength(0);
  });

  it("silently succeeds for an already verified account without sending mail", async () => {
    const { service, mailer } = makeService();
    await service.register("alice@example.com", PASSWORD);
    await service.verifyEmail("alice@example.com", mailer.verificationEmails[0].code);

    await service.resendVerification("alice@example.com");
    expect(mailer.verificationEmails).toHaveLength(1);
  });

  it("reports a retryable error when SMTP fails for a known unverified account", async () => {
    const { service, mailer } = makeService();
    await service.register("alice@example.com", PASSWORD);
    mailer.failing = true;
    await expect(service.resendVerification("alice@example.com")).rejects.toMatchObject({
      kind: "MAIL_UNAVAILABLE",
    });
  });
});

async function registerAndVerify(
  service: AuthService,
  mailer: FakeMailer,
  email = "alice@example.com",
): Promise<void> {
  await service.register(email, PASSWORD);
  await service.verifyEmail(email, mailer.verificationEmails[0].code);
}

describe("AuthService.login", () => {
  it("returns a token pair and opens a family for a verified account", async () => {
    const { service, repo, mailer } = makeService();
    await registerAndVerify(service, mailer);

    const pair = await service.login("  ALICE@example.com ", PASSWORD);

    expect(pair.refreshToken).toMatch(/^[A-Za-z0-9_-]{43}$/);
    expect(repo.families).toHaveLength(1);
    expect(repo.refreshTokens).toHaveLength(1);
    expect(repo.refreshTokens[0].tokenHash).toBe(sha256Hex(pair.refreshToken));
    const payload = JSON.parse(
      Buffer.from(pair.accessToken.split(".")[1], "base64url").toString("utf8"),
    );
    expect(payload.sub).toBe(repo.users[0].id);
    expect(payload.exp).toBe(payload.iat + 900);
  });

  it("a failed first-token insert leaves no orphan family behind", async () => {
    const { service, repo, mailer } = makeService();
    await registerAndVerify(service, mailer);
    repo.failFirstTokenInsert = true;

    await expect(service.login("alice@example.com", PASSWORD)).rejects.toThrow();

    // The family and its first token are created atomically: a failure
    // rolls both back — a family without any usable token must never
    // persist.
    expect(repo.families).toHaveLength(0);
    expect(repo.refreshTokens).toHaveLength(0);
  });

  it("rejects a wrong password and an unknown email identically", async () => {
    const { service, mailer } = makeService();
    await registerAndVerify(service, mailer);

    const wrongPassword = await service.login("alice@example.com", "wrong password").then(
      () => null,
      (error: unknown) => error,
    );
    const unknownEmail = await service.login("nobody@example.com", PASSWORD).then(
      () => null,
      (error: unknown) => error,
    );
    expect(wrongPassword).toBeInstanceOf(AuthError);
    expect((wrongPassword as AuthError).kind).toBe("INVALID_CREDENTIALS");
    expect((unknownEmail as AuthError).kind).toBe("INVALID_CREDENTIALS");
    expect((unknownEmail as AuthError).message).toBe((wrongPassword as AuthError).message);
  });

  it("checks the password before revealing the verification status", async () => {
    const { service, mailer } = makeService();
    await service.register("alice@example.com", PASSWORD);

    await expect(service.login("alice@example.com", "wrong password")).rejects.toMatchObject({
      kind: "INVALID_CREDENTIALS",
    });
    await expect(service.login("alice@example.com", PASSWORD)).rejects.toMatchObject({
      kind: "EMAIL_UNVERIFIED",
    });
    expect(mailer.verificationEmails).toHaveLength(1);
  });
});

describe("AuthService.refresh", () => {
  it("rotates into a fresh pair in the same family", async () => {
    const { service, repo, mailer } = makeService();
    await registerAndVerify(service, mailer);
    const first = await service.login("alice@example.com", PASSWORD);

    const second = await service.refresh(first.refreshToken);

    expect(second.refreshToken).not.toBe(first.refreshToken);
    expect(repo.families).toHaveLength(1);
    expect(repo.refreshTokens).toHaveLength(2);
    expect(repo.refreshTokens[0].rotatedAt).not.toBeNull();
    expect(repo.refreshTokens[1].tokenHash).toBe(sha256Hex(second.refreshToken));
  });

  it("revokes the family when a rotated token is replayed", async () => {
    const { service, repo, mailer } = makeService();
    await registerAndVerify(service, mailer);
    const first = await service.login("alice@example.com", PASSWORD);
    const second = await service.refresh(first.refreshToken);

    await expect(service.refresh(first.refreshToken)).rejects.toMatchObject({
      kind: "REFRESH_REUSED",
    });
    expect(repo.families[0].revokedAt).not.toBeNull();
    await expect(service.refresh(second.refreshToken)).rejects.toMatchObject({
      kind: "REFRESH_REUSED",
    });
  });

  it("rejects expired and unknown tokens without revoking the family", async () => {
    const { service, repo, mailer, clock } = makeService();
    await registerAndVerify(service, mailer);
    const first = await service.login("alice@example.com", PASSWORD);

    clock.advance(30 * 24 * 60 * 60 * 1000 + 1);
    await expect(service.refresh(first.refreshToken)).rejects.toMatchObject({
      kind: "INVALID_REFRESH",
    });
    await expect(service.refresh("never-issued")).rejects.toMatchObject({
      kind: "INVALID_REFRESH",
    });
    expect(repo.families[0].revokedAt).toBeNull();
  });
});

describe("AuthService.logout", () => {
  it("revokes the presented family and is idempotent", async () => {
    const { service, repo, mailer } = makeService();
    await registerAndVerify(service, mailer);
    const first = await service.login("alice@example.com", PASSWORD);

    await service.logout(first.refreshToken);
    expect(repo.families[0].revokedAt).not.toBeNull();
    await expect(service.refresh(first.refreshToken)).rejects.toMatchObject({
      kind: "REFRESH_REUSED",
    });

    // Repeat logout and unknown tokens resolve silently.
    await service.logout(first.refreshToken);
    await service.logout("never-issued");
  });
});
