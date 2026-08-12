/**
 * Signed gateway delivery for notification envelopes.
 *
 * `GatewaySender` POSTs one `NotifyEvent` to `${gatewayUrl}/v1/events` as
 * the exact raw JSON bytes of `JSON.stringify(event)` — never a
 * re-serialization — because the gateway authenticates the HMAC over those
 * exact bytes (`apps/gateway/src/modules/events/ingest-auth.ts`). Every
 * attempt carries:
 * - `Authorization: Bearer keyId.secret`
 * - `X-Notify-Timestamp`: current milliseconds (recomputed per attempt)
 * - `X-Notify-Signature`: hex HMAC-SHA256 of `${timestamp}.${rawBody}`
 *   keyed with the ingest secret
 * - `Content-Type: application/json`
 *
 * Retry policy: any 2xx resolves. 4xx is permanent (the gateway's 401/429
 * answers are policy verdicts, not transient faults) and rejects
 * immediately. Network errors, timeouts (each attempt is bounded by an
 * `AbortSignal.timeout`), and 5xx (the gateway's 503 is explicitly
 * retryable) are retried: the initial attempt plus `maxRetries` more, with
 * full-jitter exponential backoff — `random() * min(cap, base * 2^n)` —
 * so a fleet of plugins never retries in lockstep.
 *
 * Privacy: thrown errors carry status codes and sanitized network-error
 * text only; the ingest secret, keyId, and event body are redacted from
 * every message that can escape this module.
 *
 * Determinism: `fetch`, `now`, `random`, and `sleep` are injectable seams
 * (defaulting to the global fetch, `Date.now`, `Math.random`, and a real
 * timer), so tests pin exact headers, signatures, and backoff sequences.
 */

import { createHmac } from "node:crypto";

import type { NotifyEvent } from "@notify/contracts";

import {
  DEFAULT_HTTP_TIMEOUT_MS,
  DEFAULT_MAX_RETRIES,
  type IngestKey,
} from "./config.js";

/** First backoff delay before jitter, in milliseconds. */
export const DEFAULT_BACKOFF_BASE_MS = 100;
/** Hard ceiling for one backoff delay before jitter, in milliseconds. */
export const DEFAULT_BACKOFF_CAP_MS = 5_000;

export interface GatewaySenderOptions {
  /** Gateway base URL (validated by `loadConfig`); no trailing slash. */
  gatewayUrl: string;
  ingestKey: IngestKey;
  /** Per-attempt timeout; defaults to {@link DEFAULT_HTTP_TIMEOUT_MS}. */
  timeoutMs?: number;
  /** Retries after the initial attempt; defaults to {@link DEFAULT_MAX_RETRIES}. */
  maxRetries?: number;
  /** Backoff base; defaults to {@link DEFAULT_BACKOFF_BASE_MS}. */
  backoffBaseMs?: number;
  /** Backoff ceiling; defaults to {@link DEFAULT_BACKOFF_CAP_MS}. */
  backoffCapMs?: number;
  /** Fetch seam; defaults to the global fetch. */
  fetch?: typeof fetch;
  /** Clock seam (milliseconds); defaults to `Date.now`. */
  now?: () => number;
  /** Jitter seam in `[0, 1)`; defaults to `Math.random`. */
  random?: () => number;
  /** Sleep seam; defaults to a real timer. */
  sleep?: (ms: number) => Promise<void>;
}

type AttemptOutcome =
  | { kind: "ok" }
  | { kind: "retryable"; detail: string }
  | { kind: "permanent"; detail: string };

const defaultSleep = (ms: number): Promise<void> =>
  new Promise((resolve) => {
    setTimeout(resolve, ms);
  });

export class GatewaySender {
  private readonly gatewayUrl: string;
  private readonly ingestKey: IngestKey;
  private readonly timeoutMs: number;
  private readonly maxRetries: number;
  private readonly backoffBaseMs: number;
  private readonly backoffCapMs: number;
  private readonly fetchImpl: typeof fetch;
  private readonly now: () => number;
  private readonly random: () => number;
  private readonly sleep: (ms: number) => Promise<void>;

  constructor(options: GatewaySenderOptions) {
    this.gatewayUrl = options.gatewayUrl;
    this.ingestKey = options.ingestKey;
    this.timeoutMs = options.timeoutMs ?? DEFAULT_HTTP_TIMEOUT_MS;
    this.maxRetries = options.maxRetries ?? DEFAULT_MAX_RETRIES;
    this.backoffBaseMs = options.backoffBaseMs ?? DEFAULT_BACKOFF_BASE_MS;
    this.backoffCapMs = options.backoffCapMs ?? DEFAULT_BACKOFF_CAP_MS;
    this.fetchImpl = options.fetch ?? fetch;
    this.now = options.now ?? Date.now;
    this.random = options.random ?? Math.random;
    this.sleep = options.sleep ?? defaultSleep;
  }

  /**
   * Deliver one event. Resolves on any 2xx; rejects immediately on 4xx;
   * rejects after the initial attempt plus `maxRetries` retries when every
   * attempt fails retryably (network, timeout, 5xx). The rejection message
   * never contains the ingest secret, the keyId, or the event body.
   */
  async send(event: NotifyEvent): Promise<void> {
    const rawBody = JSON.stringify(event);
    let lastDetail = "no attempt made";
    for (let attempt = 0; attempt <= this.maxRetries; attempt += 1) {
      if (attempt > 0) {
        await this.sleep(this.backoffDelay(attempt - 1));
      }
      const outcome = await this.tryOnce(rawBody);
      if (outcome.kind === "ok") {
        return;
      }
      if (outcome.kind === "permanent") {
        throw new Error(`gateway event delivery rejected: ${outcome.detail}`);
      }
      lastDetail = outcome.detail;
    }
    throw new Error(
      `gateway event delivery failed after ${this.maxRetries + 1} attempts: ${lastDetail}`,
    );
  }

  /**
   * One signed POST. A synchronous fetch throw lands in the same catch as
   * a rejection because the call sits inside this async function.
   */
  private async tryOnce(rawBody: string): Promise<AttemptOutcome> {
    const timestamp = String(Math.floor(this.now()));
    const signature = createHmac("sha256", this.ingestKey.secret)
      .update(`${timestamp}.${rawBody}`)
      .digest("hex");
    let status: number;
    try {
      const response = await this.fetchImpl(`${this.gatewayUrl}/v1/events`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${this.ingestKey.keyId}.${this.ingestKey.secret}`,
          "X-Notify-Timestamp": timestamp,
          "X-Notify-Signature": signature,
        },
        body: rawBody,
        signal: AbortSignal.timeout(this.timeoutMs),
      });
      status = response.status;
    } catch (error) {
      return { kind: "retryable", detail: `network error (${this.describe(error, rawBody)})` };
    }
    if (status >= 200 && status < 300) {
      return { kind: "ok" };
    }
    if (status >= 500) {
      return { kind: "retryable", detail: `HTTP ${status}` };
    }
    return { kind: "permanent", detail: `HTTP ${status}` };
  }

  /** Full-jitter exponential backoff: `random() * min(cap, base * 2^n)`. */
  private backoffDelay(failedAttempts: number): number {
    const bound = Math.min(this.backoffCapMs, this.backoffBaseMs * 2 ** failedAttempts);
    return this.random() * bound;
  }

  /** Describe an unknown thrown value, then strip anything sensitive. */
  private describe(error: unknown, rawBody: string): string {
    const text =
      error instanceof Error ? `${error.name}: ${error.message}` : String(error);
    return this.redact(text, rawBody);
  }

  /**
   * Belt-and-braces redaction: nothing in this module ever interpolates
   * the secret or the body into a message, but an injected fetch can
   * manufacture an error that does, so both are scrubbed unconditionally.
   */
  private redact(text: string, rawBody: string): string {
    let out = text;
    const credential = `${this.ingestKey.keyId}.${this.ingestKey.secret}`;
    for (const sensitive of [credential, this.ingestKey.secret, this.ingestKey.keyId, rawBody]) {
      if (sensitive.length > 0 && out.includes(sensitive)) {
        out = out.split(sensitive).join("[redacted]");
      }
    }
    return out;
  }
}
