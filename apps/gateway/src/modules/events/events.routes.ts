import {
  eventIngestResponseSchema,
  notifyEventSchema,
  type NotifyEvent,
} from "@notify/contracts";
import type { FastifyPluginAsync, FastifyReply } from "fastify";

import type { Clock } from "../../lib/clock.js";
import { EventDedupe } from "../../lib/dedupe.js";
import { ErrorCodes, errorBody } from "../../lib/errors.js";
import {
  INGEST_EVENTS_RATE_LIMIT,
  ingestEventsIpRateLimit,
} from "../../plugins/rate-limit.js";
import { registerRawBody } from "../../plugins/raw-body.js";
import type {
  IngestKeyService,
  VerifiedIngestKey,
} from "../ingest-keys/ingest-keys.service.js";
import { authenticateIngestRequest } from "./ingest-auth.js";

/**
 * Downstream fanout seam: the route hands every accepted, non-duplicate
 * event to the dispatcher exactly once. The production composition in
 * app.ts wires the composite WebSocket + Android push fanout behind this
 * seam; tests and DB-free embeddings inject a fake (or the no-op below).
 */
export interface EventDispatcher {
  dispatch(input: { userId: string; event: NotifyEvent }): Promise<void>;
}

export const noopEventDispatcher: EventDispatcher = {
  async dispatch(): Promise<void> {},
};

const VERIFIED_LIMIT_WINDOW_MS = 60_000;

/**
 * Fixed-window in-memory limiter applied AFTER HMAC authentication, keyed by
 * the verified keyId: buckets can only be minted by credentials that really
 * exist, and one noisy key cannot starve the user's other keys. Verified
 * keyIds are bounded by the keys in the store, so the map cannot grow
 * without bound.
 */
class VerifiedKeyRateLimiter {
  private readonly buckets = new Map<string, { windowStartMs: number; count: number }>();

  constructor(
    private readonly clock: Clock,
    private readonly max: number,
    private readonly windowMs: number,
  ) {}

  consume(key: string): { allowed: boolean; retryAfterSeconds: number } {
    const now = this.clock.nowMs();
    let bucket = this.buckets.get(key);
    if (bucket === undefined || now - bucket.windowStartMs >= this.windowMs) {
      bucket = { windowStartMs: now, count: 0 };
      this.buckets.set(key, bucket);
    }
    bucket.count += 1;
    const retryAfterSeconds = Math.max(
      1,
      Math.ceil((bucket.windowStartMs + this.windowMs - now) / 1000),
    );
    return { allowed: bucket.count <= this.max, retryAfterSeconds };
  }
}

export interface EventRouteDeps {
  ingestKeys: IngestKeyService;
  clock: Clock;
  dispatcher: EventDispatcher;
  /** Defaults to a fresh in-memory dedupe (ten-minute TTL, 100k entries). */
  dedupe?: EventDedupe;
}

function sendServiceUnavailable(reply: FastifyReply): FastifyReply {
  return reply
    .status(503)
    .send(errorBody(ErrorCodes.SERVICE_UNAVAILABLE, "Ingest temporarily unavailable"));
}

/** One uniform answer for every authentication failure (anti-enumeration). */
function sendUnauthorized(reply: FastifyReply): FastifyReply {
  return reply
    .status(401)
    .send(errorBody(ErrorCodes.UNAUTHORIZED, "Invalid ingest credentials"));
}

function sendRateLimited(reply: FastifyReply, retryAfterSeconds: number): FastifyReply {
  return reply
    .status(429)
    .header("retry-after", String(retryAfterSeconds))
    .send(errorBody(ErrorCodes.RATE_LIMITED, "Too many requests"));
}

/**
 * Signed realtime event ingress: `POST /v1/events`. Two rate limits guard
 * the route — a pre-auth per-IP ceiling (plugin `onRequest`, before any
 * key-store lookup) and the post-auth 240/minute verified-keyId policy —
 * then schema validation, per-user dedupe, and dispatch. Events are never
 * persisted.
 */
export function eventRoutes(deps: EventRouteDeps): FastifyPluginAsync {
  return async (app) => {
    // Scoped JSON parser preserving the exact raw bytes for the HMAC.
    await registerRawBody(app);

    const dedupe = deps.dedupe ?? new EventDedupe(deps.clock);
    const verifiedLimiter = new VerifiedKeyRateLimiter(
      deps.clock,
      INGEST_EVENTS_RATE_LIMIT.max,
      VERIFIED_LIMIT_WINDOW_MS,
    );

    app.post(
      "/v1/events",
      {
        config: { rateLimit: ingestEventsIpRateLimit() },
        schema: { body: notifyEventSchema, response: { 202: eventIngestResponseSchema } },
        preValidation: async (request, reply) => {
          let verified: VerifiedIngestKey | null;
          try {
            verified = await authenticateIngestRequest(deps.ingestKeys, deps.clock, {
              authorization: request.headers.authorization,
              timestamp: request.headers["x-notify-timestamp"],
              signature: request.headers["x-notify-signature"],
              rawBody: request.rawBody ?? "",
            });
          } catch (error) {
            request.log.error(error, "ingest key store lookup failed");
            return sendServiceUnavailable(reply);
          }
          if (verified === null) {
            // One uniform answer for missing/malformed headers, stale
            // timestamps, bad signatures, and unknown or revoked keyIds.
            return sendUnauthorized(reply);
          }
          const verdict = verifiedLimiter.consume(verified.keyId);
          if (!verdict.allowed) {
            return sendRateLimited(reply, verdict.retryAfterSeconds);
          }
          request.verifiedIngestKey = verified;
          return undefined;
        },
      },
      async (request, reply) => {
        const verified = request.verifiedIngestKey as VerifiedIngestKey;
        const event = request.body as NotifyEvent;
        try {
          // Single-flight: concurrent duplicates await this dispatch instead
          // of triggering their own; only success commits the dedupe entry.
          const duplicate = await dedupe.dispatchOnce(verified.userId, event.eventId, () =>
            deps.dispatcher.dispatch({ userId: verified.userId, event }),
          );
          try {
            // A deduplicated 202 still counts as key use: the credential was
            // valid and the gateway accepted the request.
            await deps.ingestKeys.recordUse(verified, deps.clock.now());
          } catch (error) {
            // Usage metadata is best-effort: the event has already been
            // delivered and must not be retried solely for a failed timestamp.
            request.log.warn(error, "failed to update ingest key last-used time");
          }
          return reply.status(202).send({ eventId: event.eventId, deduplicated: duplicate });
        } catch (error) {
          request.log.error(error, "event dispatch failed");
          // Safe and retryable: nothing was committed, the client (or its
          // concurrent duplicates) may send the event again. No internals.
          return sendServiceUnavailable(reply);
        }
      },
    );
  };
}
