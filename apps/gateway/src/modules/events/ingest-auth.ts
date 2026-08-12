import { createHmac, timingSafeEqual } from "node:crypto";

import type { Clock } from "../../lib/clock.js";
import type {
  IngestKeyService,
  VerifiedIngestKey,
} from "../ingest-keys/ingest-keys.service.js";

/**
 * Requests signed more than five minutes from server time are rejected
 * (replay protection alongside the dedupe window).
 */
export const INGEST_TIMESTAMP_TOLERANCE_MS = 5 * 60 * 1000;

declare module "fastify" {
  interface FastifyRequest {
    /** Set by the event-ingress preValidation hook once HMAC auth succeeds. */
    verifiedIngestKey?: VerifiedIngestKey;
  }
}

/**
 * The exact signing rule shared with the OpenCode plugin:
 * hex HMAC-SHA256 of `${timestamp}.${rawBody}` keyed with the key secret,
 * where rawBody is the exact request body bytes.
 */
export function expectedIngestSignature(
  secret: string,
  timestamp: string,
  rawBody: string,
): string {
  return createHmac("sha256", secret).update(`${timestamp}.${rawBody}`).digest("hex");
}

/** Constant-work compare; a length mismatch still burns one comparison. */
function timingSafeStringEqual(expected: string, candidate: string): boolean {
  const left = Buffer.from(expected, "utf8");
  const right = Buffer.from(candidate, "utf8");
  if (left.length !== right.length) {
    timingSafeEqual(left, left);
    return false;
  }
  return timingSafeEqual(left, right);
}

function firstHeaderValue(value: string | string[] | undefined): string | undefined {
  return Array.isArray(value) ? value[0] : value;
}

export interface IngestAuthInput {
  authorization: string | string[] | undefined;
  timestamp: string | string[] | undefined;
  signature: string | string[] | undefined;
  /** Exact request body bytes as captured by the raw-body parser. */
  rawBody: string;
}

/**
 * HMAC ingress authentication. Every failure — missing or malformed
 * headers, a stale timestamp, a bad signature, an unknown or revoked
 * keyId — returns null so the caller answers one uniform 401 and never
 * reveals whether a keyId exists. All checks run unconditionally (dummy
 * compares included), so the work profile does not depend on which check
 * failed. Throws when the key store itself fails; callers map that to 503.
 */
export async function authenticateIngestRequest(
  ingestKeys: IngestKeyService,
  clock: Clock,
  input: IngestAuthInput,
): Promise<VerifiedIngestKey | null> {
  const authorization = firstHeaderValue(input.authorization);
  const timestamp = firstHeaderValue(input.timestamp);
  const signature = firstHeaderValue(input.signature);

  const credential =
    authorization !== undefined && authorization.startsWith("Bearer ")
      ? authorization.slice("Bearer ".length)
      : null;

  const timestampMs =
    timestamp !== undefined && /^\d+$/.test(timestamp) ? Number(timestamp) : Number.NaN;
  const timestampOk =
    Number.isSafeInteger(timestampMs) &&
    Math.abs(clock.nowMs() - timestampMs) <= INGEST_TIMESTAMP_TOLERANCE_MS;

  // Sign with the presented secret (empty when no credential): the HMAC and
  // its compare run either way, keeping the timing profile uniform.
  const secret = credential === null ? "" : credential.slice(credential.indexOf(".") + 1);
  const expected = expectedIngestSignature(secret, timestamp ?? "", input.rawBody);
  const signatureOk =
    signature !== undefined && timingSafeStringEqual(expected, signature);

  const verified = credential === null ? null : await ingestKeys.verify(credential);

  if (!timestampOk || !signatureOk || verified === null) {
    return null;
  }
  return verified;
}
