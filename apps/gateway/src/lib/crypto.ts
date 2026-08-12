import { createHash, randomBytes, randomInt } from "node:crypto";

import argon2 from "argon2";

/**
 * Alphabet of the one-time codes delivered over SMTP (email verification
 * now, password reset in a later task): exactly eight alphanumeric
 * characters per the shared contract.
 */
const CODE_ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

export const VERIFICATION_CODE_LENGTH = 8;

/**
 * Eight-character high-entropy alphanumeric code. `randomInt` draws without
 * modulo bias, so every alphabet character is equally likely.
 */
export function generateVerificationCode(): string {
  let code = "";
  for (let i = 0; i < VERIFICATION_CODE_LENGTH; i += 1) {
    code += CODE_ALPHABET[randomInt(CODE_ALPHABET.length)];
  }
  return code;
}

/**
 * Lowercase hex SHA-256. One-time codes are stored only through this hash;
 * the plaintext code exists solely in the SMTP email.
 */
export function sha256Hex(value: string): string {
  return createHash("sha256").update(value, "utf8").digest("hex");
}

/**
 * Argon2id password hash (specification section 8.1). The raw password
 * never reaches the database.
 */
export async function hashPassword(password: string): Promise<string> {
  return argon2.hash(password, { type: argon2.argon2id });
}

/**
 * Constant-work password check. Malformed stored hashes return false rather
 * than throwing, so a corrupt row behaves like a wrong password.
 */
export async function verifyPassword(hash: string, password: string): Promise<boolean> {
  try {
    return await argon2.verify(hash, password);
  } catch {
    return false;
  }
}

/** Number of random bytes behind one refresh token (256 bits of entropy). */
export const REFRESH_TOKEN_BYTES = 32;

/**
 * Opaque refresh token: 32 random bytes, base64url-encoded (43 characters).
 * Only its SHA-256 hash is ever stored; the plaintext lives solely in the
 * client response body.
 */
export function generateRefreshToken(): string {
  return randomBytes(REFRESH_TOKEN_BYTES).toString("base64url");
}
