import fastifyRateLimit from "@fastify/rate-limit";
import type { FastifyInstance, FastifyRequest } from "fastify";

/**
 * In-memory rate-limit policies (design doc section 8.1: login, register,
 * verification, and reset endpoints must be rate-limited).
 *
 * The plugin is registered with `global: false`, so only routes carrying a
 * `config.rateLimit` value are limited, each with its own bucket. The store
 * is process-local; the deployment target is a single gateway instance.
 */

/** Per-route limit for every auth endpoint: 10 requests/minute per client IP. */
export const AUTH_ENDPOINT_RATE_LIMIT = {
  max: 10,
  timeWindow: "1 minute",
} as const;

/**
 * Verified event-ingress limit: 240 requests/minute per authenticated ingest
 * keyId. Applied by the events route itself after HMAC authentication —
 * buckets can only be minted by credentials that really exist.
 */
export const INGEST_EVENTS_RATE_LIMIT = {
  max: 240,
  timeWindow: "1 minute",
} as const;

/**
 * Pre-auth event-ingress ceiling: 1000 requests/minute per client IP,
 * applied by the plugin's onRequest hook before any ingest-key lookup. The
 * presented keyId is attacker-controlled before authentication, so keying
 * the pre-auth limiter by it would let rotating random keyIds mint
 * unlimited buckets and unlimited key-store lookups. The
 * ceiling sits above 4x the verified per-key budget so a user running
 * several keys behind one IP keeps their full per-key allowance.
 */
export const INGEST_EVENTS_IP_RATE_LIMIT = {
  max: 1000,
  timeWindow: "1 minute",
} as const;

/**
 * Route `config.rateLimit` value for the event-ingress endpoint: the
 * pre-auth per-IP ceiling. Keyed strictly by client IP, never by the
 * presented credential.
 */
export function ingestEventsIpRateLimit(): {
  max: number;
  timeWindow: string;
  keyGenerator: (request: FastifyRequest) => string;
} {
  return {
    ...INGEST_EVENTS_IP_RATE_LIMIT,
    keyGenerator: (request) => request.ip,
  };
}

/**
 * Registers @fastify/rate-limit in opt-in mode: only routes with a
 * `config.rateLimit` value are limited. Exceeded limits produce a 429 with
 * a `Retry-After` header; the app error handler renders it in the contract
 * error shape with code RATE_LIMITED.
 */
export async function registerRateLimit(app: FastifyInstance): Promise<void> {
  await app.register(fastifyRateLimit, { global: false });
}
