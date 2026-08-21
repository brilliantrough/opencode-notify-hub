import { createHmac, timingSafeEqual } from "node:crypto";

import type { FastifyInstance, FastifyReply, FastifyRequest } from "fastify";

import { ErrorCodes, errorBody } from "../lib/errors.js";
import type { Clock } from "../lib/clock.js";

/** Access tokens live exactly 900 seconds (specification section 8.2). */
export const ACCESS_TOKEN_TTL_SECONDS = 900;

/**
 * Admin panel sessions live longer than user access tokens (they are used
 * interactively in a browser tab and carry no refresh flow).
 */
export const ADMIN_TOKEN_TTL_SECONDS = 12 * 60 * 60;

/** Marker role of admin-panel tokens; user tokens carry no role claim. */
export const ADMIN_TOKEN_ROLE = "admin";

export interface AccessTokenPayload {
  sub: string;
  iat: number;
  exp: number;
  /** Present only on admin-panel tokens. */
  role?: string;
}

export interface SignTokenOptions {
  /** Extra claim distinguishing token audiences (admin panel). */
  role?: string;
  /** Overrides the default 900s TTL (admin sessions use a longer one). */
  ttlSeconds?: number;
}

/**
 * Signing boundary of the gateway's access tokens. Both issuance and
 * verification read the injected clock, so tests advance time
 * deterministically instead of waiting out real TTLs.
 */
export interface AccessTokens {
  sign(userId: string, options?: SignTokenOptions): string;
  /** Returns the payload, or null for malformed, badly signed, or expired tokens. */
  verify(token: string): AccessTokenPayload | null;
}

function base64urlJson(value: unknown): string {
  return Buffer.from(JSON.stringify(value), "utf8").toString("base64url");
}

/** Minimum entropy of the HMAC key: 256 bits (specification section 8.2). */
export const MIN_SIGNING_KEY_BYTES = 32;

export class SigningKeyError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "SigningKeyError";
  }
}

/**
 * Decode the configured signing key defensively. `GatewayConfig` already
 * validates JWT_SIGNING_KEY, but the security primitive defends itself too:
 * this boundary rejects anything that is not canonical base64 (padding,
 * alphabet, and unused trailing bits all checked) decoding to at least
 * {@link MIN_SIGNING_KEY_BYTES} bytes. `Buffer.from(value, "base64")` alone
 * silently ignores invalid characters and non-canonical encodings, so the
 * round-trip re-encode is the strict check.
 */
function decodeSigningKey(signingKey: string): Buffer {
  if (signingKey.length % 4 !== 0 || !/^[A-Za-z0-9+/]*={0,2}$/.test(signingKey)) {
    throw new SigningKeyError("JWT signing key must be canonical base64");
  }
  const key = Buffer.from(signingKey, "base64");
  if (key.toString("base64") !== signingKey) {
    throw new SigningKeyError("JWT signing key must be canonical base64");
  }
  if (key.length < MIN_SIGNING_KEY_BYTES) {
    throw new SigningKeyError(
      `JWT signing key must decode to at least ${MIN_SIGNING_KEY_BYTES} bytes`,
    );
  }
  return key;
}

/**
 * HS256 access tokens over the configured signing key. Implemented directly
 * on node:crypto (rather than a JWT dependency) so issuance and verification
 * share the injected {@link Clock}: `iat`/`exp` must be controllable in
 * tests to prove the exact 900-second TTL.
 *
 * @throws SigningKeyError when `signingKey` is not canonical base64 decoding
 *   to at least 32 bytes.
 */
export function createAccessTokens(deps: {
  /** Base64-encoded signing key (GatewayConfig.jwtSigningKey). */
  signingKey: string;
  clock: Clock;
}): AccessTokens {
  const key = decodeSigningKey(deps.signingKey);
  const header = base64urlJson({ alg: "HS256", typ: "JWT" });

  const hmac = (input: string): Buffer =>
    createHmac("sha256", key).update(input, "utf8").digest();

  return {
    sign(userId, options = {}) {
      const iat = Math.floor(deps.clock.nowMs() / 1000);
      const ttl = options.ttlSeconds ?? ACCESS_TOKEN_TTL_SECONDS;
      const payload = base64urlJson({
        sub: userId,
        iat,
        exp: iat + ttl,
        ...(options.role !== undefined ? { role: options.role } : {}),
      } satisfies AccessTokenPayload);
      const signingInput = `${header}.${payload}`;
      return `${signingInput}.${hmac(signingInput).toString("base64url")}`;
    },

    verify(token) {
      const parts = token.split(".");
      if (parts.length !== 3) {
        return null;
      }
      const signingInput = `${parts[0]}.${parts[1]}`;
      const presented = Buffer.from(parts[2], "base64url");
      const expected = hmac(signingInput);
      if (presented.length !== expected.length || !timingSafeEqual(presented, expected)) {
        return null;
      }
      let payload: unknown;
      try {
        payload = JSON.parse(Buffer.from(parts[1], "base64url").toString("utf8"));
      } catch {
        return null;
      }
      if (
        typeof payload !== "object" ||
        payload === null ||
        typeof (payload as AccessTokenPayload).sub !== "string" ||
        typeof (payload as AccessTokenPayload).iat !== "number" ||
        typeof (payload as AccessTokenPayload).exp !== "number"
      ) {
        return null;
      }
      const claims = payload as AccessTokenPayload;
      if (claims.exp <= Math.floor(deps.clock.nowMs() / 1000)) {
        return null;
      }
      return claims;
    },
  };
}

declare module "fastify" {
  interface FastifyInstance {
    /**
     * preHandler guard for bearer-authenticated routes: rejects with 401
     * UNAUTHORIZED unless the request carries a live access token, and then
     * stamps {@link FastifyRequest.userId}.
     */
    authenticate: (request: FastifyRequest, reply: FastifyReply) => Promise<void>;
  }
  interface FastifyRequest {
    /** Subject of the presented access token; set by `app.authenticate`. */
    userId?: string;
  }
}

/**
 * Decorate the app with the `authenticate` preHandler. Applied directly to
 * the root instance (not through `register`, which would encapsulate the
 * decorator) so every module can guard its routes.
 */
export function registerJwtAuth(app: FastifyInstance, accessTokens: AccessTokens): void {
  app.decorate("authenticate", async (request: FastifyRequest, reply: FastifyReply) => {
    const header = request.headers.authorization;
    const token =
      typeof header === "string" && header.startsWith("Bearer ")
        ? header.slice("Bearer ".length)
        : null;
    const payload = token === null ? null : accessTokens.verify(token);
    if (payload === null || payload.role !== undefined) {
      // Admin-panel tokens are not user sessions: their subject is not a
      // user id, so they must never satisfy the user guard.
      await reply
        .status(401)
        .send(errorBody(ErrorCodes.UNAUTHORIZED, "Missing or invalid access token"));
      return;
    }
    request.userId = payload.sub;
  });
}
