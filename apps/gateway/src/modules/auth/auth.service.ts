import {
  generateRefreshToken,
  generateVerificationCode,
  hashPassword,
  sha256Hex,
  verifyPassword,
} from "../../lib/crypto.js";
import type { Clock } from "../../lib/clock.js";
import type { AccessTokens } from "../../plugins/jwt.js";
import type { Mailer } from "../mail/mailer.js";
import {
  DuplicateEmailError,
  type AuthRepository,
  type UserRecord,
} from "./auth.repository.js";

/** Verification codes live 24 hours from issuance (specification 8.1). */
export const VERIFICATION_CODE_TTL_MS = 24 * 60 * 60 * 1000;

/** Password reset codes live one hour from issuance (specification 8.1). */
export const PASSWORD_RESET_CODE_TTL_MS = 60 * 60 * 1000;

/** Refresh tokens live 30 days from issuance; every refresh re-issues. */
export const REFRESH_TOKEN_TTL_MS = 30 * 24 * 60 * 60 * 1000;

/** Token pair returned by login and refresh, matching the TokenPair contract. */
export interface TokenPair {
  accessToken: string;
  refreshToken: string;
}

export type AuthErrorKind =
  | "EMAIL_TAKEN"
  | "INVALID_CODE"
  | "MAIL_UNAVAILABLE"
  | "INVALID_CREDENTIALS"
  | "EMAIL_UNVERIFIED"
  | "INVALID_REFRESH"
  | "REFRESH_REUSED";

/**
 * Domain error of the auth module. Messages are static and safe to return
 * to clients: they never contain SMTP internals, codes, or hashes.
 */
export class AuthError extends Error {
  readonly kind: AuthErrorKind;

  constructor(kind: AuthErrorKind, message: string) {
    super(message);
    this.name = "AuthError";
    this.kind = kind;
  }
}

/**
 * Normalization the database CHECK enforces (`email = lower(btrim(email))`).
 * Every write path goes through this before persisting.
 */
export function normalizeEmail(email: string): string {
  return email.trim().toLowerCase();
}

export interface AuthServiceDeps {
  repository: AuthRepository;
  mailer: Mailer;
  clock: Clock;
  accessTokens: AccessTokens;
  /**
   * Sanitized delivery-failure logging (pino-compatible warn subset).
   * Only the internal user id is logged — never the email address, the
   * one-time code, or the SMTP transport error.
   */
  logger?: AuthLogger;
}

/** Pino-compatible warn-only logger subset. */
export interface AuthLogger {
  warn(obj: Record<string, unknown>, msg: string): void;
}

export class AuthService {
  private readonly repository: AuthRepository;
  private readonly mailer: Mailer;
  private readonly clock: Clock;
  private readonly accessTokens: AccessTokens;
  private readonly logger?: AuthLogger;
  /**
   * Argon2id hash verified against when the email is unknown, so a login
   * attempt burns the same password work whether or not the account exists.
   * Computed once, lazily (hashing is deliberately expensive).
   */
  private dummyPasswordHash: Promise<string> | null = null;

  constructor(deps: AuthServiceDeps) {
    this.repository = deps.repository;
    this.mailer = deps.mailer;
    this.clock = deps.clock;
    this.accessTokens = deps.accessTokens;
    if (deps.logger !== undefined) {
      this.logger = deps.logger;
    }
  }

  /**
   * Create an unverified account and email a verification code. When SMTP
   * fails the account stays unverified and the caller gets a retryable
   * MAIL_UNAVAILABLE — the code can be resent later.
   */
  async register(email: string, password: string): Promise<void> {
    const normalized = normalizeEmail(email);
    if ((await this.repository.findUserByEmail(normalized)) !== null) {
      throw new AuthError("EMAIL_TAKEN", "Email already registered");
    }
    const passwordHash = await hashPassword(password);
    let user: UserRecord;
    try {
      user = await this.repository.createUser({ email: normalized, passwordHash });
    } catch (error) {
      // A concurrent registration with the same normalized email wins the
      // unique constraint; report the conflict rather than a 500.
      if (error instanceof DuplicateEmailError) {
        throw new AuthError("EMAIL_TAKEN", "Email already registered");
      }
      throw error;
    }
    await this.issueVerificationCode(user);
  }

  /**
   * Consume a verification code. Unknown emails, wrong codes, expired codes,
   * and already-used codes all produce the same INVALID_CODE error so the
   * endpoint cannot be used to enumerate accounts.
   */
  async verifyEmail(email: string, code: string): Promise<void> {
    const user = await this.repository.findUserByEmail(normalizeEmail(email));
    if (user === null) {
      throw new AuthError("INVALID_CODE", "Invalid, expired, or already used code");
    }
    const consumed = await this.repository.consumeVerificationToken({
      userId: user.id,
      tokenHash: sha256Hex(code),
      now: this.clock.now(),
    });
    if (!consumed) {
      throw new AuthError("INVALID_CODE", "Invalid, expired, or already used code");
    }
  }

  /**
   * Send a fresh code for a known, still-unverified account. Unknown emails
   * and already-verified accounts resolve silently with no mail, so the
   * response cannot reveal whether an account exists.
   */
  async resendVerification(email: string): Promise<void> {
    const user = await this.repository.findUserByEmail(normalizeEmail(email));
    if (user === null || user.emailVerifiedAt !== null) {
      return;
    }
    await this.issueVerificationCode(user);
  }

  /**
   * Email a one-hour password reset code for a known account. Unknown
   * emails resolve silently with no mail, so the endpoint cannot enumerate
   * accounts. An SMTP failure is also swallowed: the stored token is
   * harmless (its plaintext never left the server) and the caller can
   * simply request another code, so the response stays the contract's
   * uniform 204 either way.
   */
  async forgotPassword(email: string): Promise<void> {
    const user = await this.repository.findUserByEmail(normalizeEmail(email));
    if (user === null) {
      return;
    }
    const code = generateVerificationCode();
    await this.repository.createPasswordResetToken({
      userId: user.id,
      tokenHash: sha256Hex(code),
      expiresAt: new Date(this.clock.nowMs() + PASSWORD_RESET_CODE_TTL_MS),
    });
    try {
      await this.mailer.sendPasswordResetEmail(user.email, code);
    } catch {
      // Delivery is retried by requesting a fresh code; see the docstring.
      // Sanitized: no email, no code, no SMTP transport internals.
      this.logger?.warn({ userId: user.id }, "password reset email delivery failed");
    }
  }

  /**
   * Consume a reset code and replace the password. Unknown emails, wrong
   * codes, expired codes, and already-used codes all produce the same
   * INVALID_CODE error so the endpoint cannot be used to enumerate
   * accounts. On success the repository atomically marks the code consumed,
   * stores the new Argon2id hash, and revokes every refresh-token family
   * of the user in the same transaction.
   */
  async resetPassword(email: string, code: string, password: string): Promise<void> {
    const user = await this.repository.findUserByEmail(normalizeEmail(email));
    if (user === null) {
      throw new AuthError("INVALID_CODE", "Invalid, expired, or already used code");
    }
    // Hash before consuming: the expensive Argon2id work must not hold the
    // token row lock, and a failed consume leaves the password untouched.
    const passwordHash = await hashPassword(password);
    const consumed = await this.repository.consumePasswordResetToken({
      userId: user.id,
      tokenHash: sha256Hex(code),
      now: this.clock.now(),
      passwordHash,
    });
    if (!consumed) {
      throw new AuthError("INVALID_CODE", "Invalid, expired, or already used code");
    }
  }

  /**
   * Store the hash of a fresh code, then email the plaintext. Mail failures
   * surface as the retryable MAIL_UNAVAILABLE; the stored token is harmless
   * because its plaintext never left the server.
   */
  private async issueVerificationCode(user: UserRecord): Promise<void> {
    const code = generateVerificationCode();
    await this.repository.createVerificationToken({
      userId: user.id,
      tokenHash: sha256Hex(code),
      expiresAt: new Date(this.clock.nowMs() + VERIFICATION_CODE_TTL_MS),
    });
    try {
      await this.mailer.sendVerificationEmail(user.email, code);
    } catch {
      // Sanitized: no email, no code, no SMTP transport internals.
      this.logger?.warn({ userId: user.id }, "verification email delivery failed");
      throw new AuthError("MAIL_UNAVAILABLE", "Email delivery failed; please try again later");
    }
  }

  /**
   * Authenticate with email and password. Unknown emails and wrong
   * passwords produce the identical INVALID_CREDENTIALS error, and the
   * unknown-email path verifies against a dummy Argon2 hash so the two
   * paths cost the same (no enumeration by response or by timing). The
   * password is always checked before the verification status, so a
   * caller without the password cannot learn whether an account is
   * verified; a correct password on an unverified account gets the
   * explicit EMAIL_UNVERIFIED.
   */
  async login(email: string, password: string): Promise<TokenPair> {
    const user = await this.repository.findUserByEmail(normalizeEmail(email));
    if (user === null) {
      this.dummyPasswordHash ??= hashPassword("dummy-password-for-timing-parity");
      await verifyPassword(await this.dummyPasswordHash, password);
      throw new AuthError("INVALID_CREDENTIALS", "Invalid email or password");
    }
    if (!(await verifyPassword(user.passwordHash, password))) {
      throw new AuthError("INVALID_CREDENTIALS", "Invalid email or password");
    }
    if (user.emailVerifiedAt === null) {
      throw new AuthError("EMAIL_UNVERIFIED", "Email address is not verified");
    }
    // The family and its first token persist atomically (one transaction),
    // so a failed login can never leave an orphan family behind.
    const refreshToken = generateRefreshToken();
    await this.repository.createRefreshSession({
      userId: user.id,
      tokenHash: sha256Hex(refreshToken),
      expiresAt: new Date(this.clock.nowMs() + REFRESH_TOKEN_TTL_MS),
    });
    return { accessToken: this.accessTokens.sign(user.id), refreshToken };
  }

  /**
   * Rotate a refresh token into a fresh pair. Unknown, expired, or revoked-
   * family tokens are rejected; presenting an already rotated token (replay
   * or the loser of a concurrent rotation) revokes the whole family and
   * reports REFRESH_REUSED — the winner's concurrently issued successor is
   * dead too, because it belongs to the revoked family.
   */
  async refresh(refreshToken: string): Promise<TokenPair> {
    const record = await this.repository.findRefreshTokenByHash(sha256Hex(refreshToken));
    if (record === null || record.expiresAt.getTime() <= this.clock.nowMs()) {
      throw new AuthError("INVALID_REFRESH", "Invalid or expired refresh token");
    }
    if (record.familyRevokedAt !== null) {
      throw new AuthError("REFRESH_REUSED", "Refresh token family was revoked");
    }
    const nextPlaintext = generateRefreshToken();
    const outcome = await this.repository.rotateRefreshToken({
      tokenId: record.id,
      familyId: record.familyId,
      now: this.clock.now(),
      next: {
        tokenHash: sha256Hex(nextPlaintext),
        expiresAt: new Date(this.clock.nowMs() + REFRESH_TOKEN_TTL_MS),
      },
    });
    if (outcome === "reused") {
      throw new AuthError("REFRESH_REUSED", "Refresh token was already used");
    }
    return {
      accessToken: this.accessTokens.sign(record.userId),
      refreshToken: nextPlaintext,
    };
  }

  /**
   * Revoke the family of the presented token. Unknown tokens and already
   * revoked families resolve silently: logout is idempotent and cannot
   * enumerate sessions.
   */
  async logout(refreshToken: string): Promise<void> {
    const record = await this.repository.findRefreshTokenByHash(sha256Hex(refreshToken));
    if (record === null || record.familyRevokedAt !== null) {
      return;
    }
    await this.repository.revokeRefreshFamily(record.familyId, this.clock.now());
  }
}
