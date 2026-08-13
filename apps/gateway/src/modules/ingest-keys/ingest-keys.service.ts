import { randomBytes, timingSafeEqual } from "node:crypto";

import { sha256Hex } from "../../lib/crypto.js";
import type {
  IngestKeyRecord,
  IngestKeyRepository,
} from "./ingest-keys.repository.js";

/** Random bytes behind one key id (72 bits; 12 base64url characters). */
export const INGEST_KEY_ID_BYTES = 9;

/** Random bytes behind one key secret (256 bits; 43 base64url characters). */
export const INGEST_KEY_SECRET_BYTES = 32;

/** Public lookup id of an ingest key, sent as the keyId credential part. */
export function generateIngestKeyId(): string {
  return randomBytes(INGEST_KEY_ID_BYTES).toString("base64url");
}

/**
 * Key secret: 32 random bytes, base64url-encoded. Only its SHA-256 hash is
 * ever stored; the plaintext lives solely in the creation response.
 */
export function generateIngestKeySecret(): string {
  return randomBytes(INGEST_KEY_SECRET_BYTES).toString("base64url");
}

/** An authenticated ingest credential: the key's owner for event routing. */
export interface VerifiedIngestKey {
  id: string;
  userId: string;
  keyId: string;
}

/**
 * Ingest-key lifecycle: creation, listing, revocation, and the constant-time
 * credential check used to authenticate event ingress.
 */
export class IngestKeyService {
  constructor(private readonly repository: IngestKeyRepository) {}

  /**
   * Creates a key and returns its `keyId.secret` credential. This is the
   * only time the secret exists outside the client; the repository stores
   * only SHA-256(secret).
   */
  async create(
    userId: string,
    name: string,
  ): Promise<{ record: IngestKeyRecord; credential: string }> {
    const keyId = generateIngestKeyId();
    const secret = generateIngestKeySecret();
    const record = await this.repository.create({
      userId,
      keyId,
      secretHash: sha256Hex(secret),
      name,
    });
    return { record, credential: `${keyId}.${secret}` };
  }

  /**
   * Verifies a `keyId.secret` credential against the active keys. Revoked
   * and unknown keys fail identically (null). The stored hash and the
   * candidate hash are compared with `timingSafeEqual`; when the keyId is
   * unknown the candidate is compared against a dummy so the timing profile
   * matches the found-key path.
   */
  async verify(credential: string): Promise<VerifiedIngestKey | null> {
    const dot = credential.indexOf(".");
    if (dot <= 0 || dot === credential.length - 1 || credential.indexOf(".", dot + 1) !== -1) {
      return null;
    }
    const keyId = credential.slice(0, dot);
    const secret = credential.slice(dot + 1);

    const active = await this.repository.findActiveByKeyId(keyId);
    const candidate = Buffer.from(sha256Hex(secret), "utf8");
    // A sha256Hex digest is always 64 chars; the dummy keeps the comparison
    // (and its cost) when no active key matches the keyId.
    const stored = Buffer.from(active?.secretHash ?? "0".repeat(64), "utf8");
    if (active === null || !timingSafeEqual(stored, candidate)) {
      return null;
    }
    return { id: active.id, userId: active.userId, keyId: active.keyId };
  }

  /** Records that an authenticated key request was accepted. */
  async recordUse(key: VerifiedIngestKey, usedAt: Date): Promise<void> {
    await this.repository.recordUse({ id: key.id, userId: key.userId, usedAt });
  }
}
