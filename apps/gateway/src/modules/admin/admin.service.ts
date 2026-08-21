import { hashPassword, verifyPassword } from "../../lib/crypto.js";
import type { Clock } from "../../lib/clock.js";
import type { AccessTokens } from "../../plugins/jwt.js";
import { ADMIN_TOKEN_ROLE, ADMIN_TOKEN_TTL_SECONDS } from "../../plugins/jwt.js";
import { DuplicateEmailError } from "../auth/auth.repository.js";
import type { RegistrationPolicy } from "../auth/auth.service.js";
import { normalizeEmail } from "../auth/auth.service.js";
import type { AdminRepository, AdminUserRecord, WhitelistSnapshot } from "./admin.repository.js";

export type AdminErrorKind =
  | "INVALID_CREDENTIALS"
  | "EMAIL_TAKEN"
  | "USER_NOT_FOUND"
  | "INVALID_WHITELIST_ENTRY";

/**
 * Domain error of the admin module. Messages are static and safe to return
 * to clients; they never contain hashes or SMTP internals.
 */
export class AdminError extends Error {
  readonly kind: AdminErrorKind;

  constructor(kind: AdminErrorKind, message: string) {
    super(message);
    this.name = "AdminError";
    this.kind = kind;
  }
}

/** Whitespace-separated list of allowed whitelist entries per kind. */
const MAX_WHITELIST_ENTRIES = 1000;

const DOMAIN_PATTERN = /^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$/;

function normalizeDomainValue(value: string): string {
  return value.trim().toLowerCase().replace(/^\*@/, "");
}

function isValidEmailShape(value: string): boolean {
  return /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(value);
}

/**
 * Admin panel business logic: operator authentication, user administration,
 * and the registration whitelist. Admin-created accounts skip both the
 * whitelist and the email-verification dance — the operator hands the
 * credentials over directly.
 */
export class AdminService {
  private readonly repository: AdminRepository;
  private readonly clock: Clock;
  private readonly accessTokens: AccessTokens;
  private readonly seedUsername: string;
  private readonly seedPassword: string;

  constructor(deps: {
    repository: AdminRepository;
    clock: Clock;
    accessTokens: AccessTokens;
    seedUsername: string;
    seedPassword: string;
  }) {
    this.repository = deps.repository;
    this.clock = deps.clock;
    this.accessTokens = deps.accessTokens;
    this.seedUsername = deps.seedUsername;
    this.seedPassword = deps.seedPassword;
  }

  /**
   * Seed the configured operator account when the table is still empty.
   * Runs lazily on the first login attempt, so app construction never
   * touches the database (readiness stays the only DB-dependent concern)
   * and a database that was unavailable at boot self-heals. Later panel
   * password changes always win: seeding only happens from an empty table.
   */
  private async seedIfEmpty(): Promise<void> {
    if ((await this.repository.countAdminAccounts()) > 0) {
      return;
    }
    const passwordHash = await hashPassword(this.seedPassword);
    await this.repository.ensureAdminAccount({
      username: this.seedUsername,
      passwordHash,
    });
  }

  /** Verify operator credentials and issue a long-lived admin token. */
  async login(username: string, password: string): Promise<string> {
    const normalized = username.trim().toLowerCase();
    await this.seedIfEmpty();
    const account = await this.repository.findAdminByUsername(normalized);
    if (account === null || !(await verifyPassword(account.passwordHash, password))) {
      throw new AdminError("INVALID_CREDENTIALS", "Invalid username or password");
    }
    return this.accessTokens.sign(account.id, {
      role: ADMIN_TOKEN_ROLE,
      ttlSeconds: ADMIN_TOKEN_TTL_SECONDS,
    });
  }

  /** Change the operator password identified by admin id. */
  async changePasswordFor(
    adminId: string,
    currentPassword: string,
    newPassword: string,
  ): Promise<void> {
    const account = await this.repository.findAdminById(adminId);
    if (account === null || !(await verifyPassword(account.passwordHash, currentPassword))) {
      throw new AdminError("INVALID_CREDENTIALS", "Current password is incorrect");
    }
    const passwordHash = await hashPassword(newPassword);
    await this.repository.updateAdminPassword({
      id: adminId,
      passwordHash,
      now: this.clock.now(),
    });
  }

  listUsers(): Promise<AdminUserRecord[]> {
    return this.repository.listUsers();
  }

  /** Whitelist-free, immediately-verified account creation. */
  async createUser(email: string, password: string): Promise<AdminUserRecord> {
    const normalized = normalizeEmail(email);
    const passwordHash = await hashPassword(password);
    try {
      return await this.repository.createVerifiedUser({
        email: normalized,
        passwordHash,
        now: this.clock.now(),
      });
    } catch (error) {
      if (error instanceof DuplicateEmailError) {
        throw new AdminError("EMAIL_TAKEN", "Email already registered");
      }
      throw error;
    }
  }

  /** Replace a user's password and revoke their sessions. */
  async resetUserPassword(userId: string, password: string): Promise<void> {
    const passwordHash = await hashPassword(password);
    const updated = await this.repository.setUserPassword({
      userId,
      passwordHash,
      now: this.clock.now(),
    });
    if (!updated) {
      throw new AdminError("USER_NOT_FOUND", "User not found");
    }
  }

  async getWhitelist(): Promise<WhitelistSnapshot> {
    const entries = await this.repository.listWhitelist();
    return {
      domains: entries.filter((e) => e.kind === "domain").map((e) => e.value),
      emails: entries.filter((e) => e.kind === "email").map((e) => e.value),
    };
  }

  /** Validate, normalize, deduplicate, and atomically replace the list. */
  async replaceWhitelist(input: WhitelistSnapshot): Promise<WhitelistSnapshot> {
    const domains = new Set<string>();
    for (const raw of input.domains) {
      const value = normalizeDomainValue(raw);
      if (value === "" || value.length > 253 || !DOMAIN_PATTERN.test(value)) {
        throw new AdminError(
          "INVALID_WHITELIST_ENTRY",
          `Invalid domain entry: ${raw === "" ? "(empty)" : raw}`,
        );
      }
      domains.add(value);
    }
    const emails = new Set<string>();
    for (const raw of input.emails) {
      const value = normalizeEmail(raw);
      if (!isValidEmailShape(value)) {
        throw new AdminError("INVALID_WHITELIST_ENTRY", `Invalid email entry: ${raw}`);
      }
      emails.add(value);
    }
    if (domains.size > MAX_WHITELIST_ENTRIES || emails.size > MAX_WHITELIST_ENTRIES) {
      throw new AdminError("INVALID_WHITELIST_ENTRY", "Too many whitelist entries");
    }
    const entries = [
      ...[...domains].map((value) => ({ kind: "domain" as const, value })),
      ...[...emails].map((value) => ({ kind: "email" as const, value })),
    ];
    await this.repository.replaceWhitelist(entries);
    return { domains: [...domains], emails: [...emails] };
  }
}

/**
 * Registration gate backed by the admin-managed whitelist. An empty
 * whitelist is closed: self-registration is disabled entirely until the
 * operator opens suffixes or exact addresses from the panel.
 */
export class WhitelistRegistrationPolicy implements RegistrationPolicy {
  private readonly repository: AdminRepository;

  constructor(repository: AdminRepository) {
    this.repository = repository;
  }

  async isEmailAllowed(email: string): Promise<boolean> {
    const normalized = normalizeEmail(email);
    const entries = await this.repository.listWhitelist();
    return entries.some((entry) =>
      entry.kind === "email"
        ? entry.value === normalized
        : normalized.endsWith(`@${entry.value}`),
    );
  }
}
