import { createHmac } from "node:crypto";

import { describe, expect, it } from "vitest";
import type { NotifyEvent } from "@notify/contracts";

import { GatewaySender } from "../src/sender.js";
import type { IngestKey } from "../src/config.js";

const GATEWAY_URL = "https://gateway.example.com";
const INGEST_KEY: IngestKey = { keyId: "kid_abc123", secret: "sekret-value-9" };

/** Minimal contract-shaped heartbeat; the sender never inspects it. */
function event(eventId: string): NotifyEvent {
  return {
    eventId,
    type: "heartbeat",
    occurredAt: "2026-01-01T00:00:00.000Z",
    source: { machine: "m1", project: "proj", directory: "/work" },
    session: { id: "ses_1", title: "Session" },
    payload: { status: "busy", elapsedSeconds: 3 },
  };
}

interface RecordedCall {
  url: string;
  init: RequestInit;
}

type FetchResult = { status: number };
type FetchBehavior = (url: string, init: RequestInit) => Promise<FetchResult> | FetchResult;

/** A fetch stand-in that records every call and delegates to `behavior`. */
function makeFetch(behavior: FetchBehavior): { fetchImpl: typeof fetch; calls: RecordedCall[] } {
  const calls: RecordedCall[] = [];
  const fetchImpl = (async (url: unknown, init: RequestInit) => {
    calls.push({ url: String(url), init });
    return behavior(String(url), init);
  }) as unknown as typeof fetch;
  return { fetchImpl, calls };
}

function ok(status = 202): FetchResult {
  return { status };
}

interface SenderHarness {
  sender: GatewaySender;
  calls: RecordedCall[];
  sleeps: number[];
}

function makeSender(options: {
  behavior: FetchBehavior;
  now?: () => number;
  random?: () => number;
  timeoutMs?: number;
  maxRetries?: number;
  backoffBaseMs?: number;
  backoffCapMs?: number;
}): SenderHarness {
  const { fetchImpl, calls } = makeFetch(options.behavior);
  const sleeps: number[] = [];
  const sender = new GatewaySender({
    gatewayUrl: GATEWAY_URL,
    ingestKey: INGEST_KEY,
    fetch: fetchImpl,
    now: options.now ?? (() => 1_700_000_000_000),
    random: options.random ?? (() => 0.5),
    sleep: (ms) => {
      sleeps.push(ms);
      return Promise.resolve();
    },
    timeoutMs: options.timeoutMs,
    maxRetries: options.maxRetries,
    backoffBaseMs: options.backoffBaseMs,
    backoffCapMs: options.backoffCapMs,
  });
  return { sender, calls, sleeps };
}

function headers(call: RecordedCall): Record<string, string> {
  return call.init.headers as Record<string, string>;
}

/** Independent recomputation of the gateway's signing rule. */
function expectedSignature(timestamp: string, rawBody: string): string {
  return createHmac("sha256", INGEST_KEY.secret)
    .update(`${timestamp}.${rawBody}`)
    .digest("hex");
}

describe("GatewaySender — request shape", () => {
  it("POSTs the exact raw JSON envelope to /v1/events with the signed headers", async () => {
    const { sender, calls } = makeSender({ behavior: () => ok() });
    const evt = event("evt_exact");

    await sender.send(evt);

    expect(calls).toHaveLength(1);
    const call = calls[0];
    expect(call.url).toBe(`${GATEWAY_URL}/v1/events`);
    expect(call.init.method).toBe("POST");
    const rawBody = JSON.stringify(evt);
    expect(call.init.body).toBe(rawBody);
    expect(typeof call.init.body).toBe("string");
    expect(headers(call)).toEqual({
      "Content-Type": "application/json",
      Authorization: `Bearer ${INGEST_KEY.keyId}.${INGEST_KEY.secret}`,
      "X-Notify-Timestamp": "1700000000000",
      "X-Notify-Signature": expectedSignature("1700000000000", rawBody),
    });
  });

  it("signs the live timestamp: a different clock reading yields a different signature", async () => {
    const { sender, calls } = makeSender({ behavior: () => ok(), now: () => 1_700_000_111_222 });
    const evt = event("evt_clock");

    await sender.send(evt);

    const rawBody = JSON.stringify(evt);
    expect(headers(calls[0])["X-Notify-Timestamp"]).toBe("1700000111222");
    expect(headers(calls[0])["X-Notify-Signature"]).toBe(
      expectedSignature("1700000111222", rawBody),
    );
    expect(headers(calls[0])["X-Notify-Signature"]).not.toBe(
      expectedSignature("1700000000000", rawBody),
    );
  });

  it("attaches an abort signal to every attempt", async () => {
    const { sender, calls } = makeSender({ behavior: () => ok() });

    await sender.send(event("evt_signal"));

    expect(calls[0].init.signal).toBeInstanceOf(AbortSignal);
    expect(calls[0].init.signal?.aborted).toBe(false);
  });
});

describe("GatewaySender — success", () => {
  it.each([200, 202, 204])("resolves on a %i response", async (status) => {
    const { sender, calls, sleeps } = makeSender({ behavior: () => ok(status) });

    await expect(sender.send(event(`evt_${status}`))).resolves.toBeUndefined();
    expect(calls).toHaveLength(1);
    expect(sleeps).toEqual([]);
  });
});

describe("GatewaySender — permanent failure (4xx)", () => {
  it.each([400, 401, 403, 404, 409, 422, 429])(
    "does not retry status %i and rejects with the status only",
    async (status) => {
      const { sender, calls, sleeps } = makeSender({ behavior: () => ok(status) });

      const failure = await sender.send(event(`evt_${status}`)).then(
        () => null,
        (error: Error) => error,
      );

      expect(failure).toBeInstanceOf(Error);
      expect(failure?.message).toContain(String(status));
      expect(calls).toHaveLength(1);
      expect(sleeps).toEqual([]);
    },
  );

  it("never leaks the secret or the body in a 4xx rejection", async () => {
    const { sender } = makeSender({ behavior: () => ok(401) });
    const evt = event("evt_redact_4xx");

    const failure = await sender.send(evt).then(
      () => null,
      (error: Error) => error,
    );

    expect(failure?.message).not.toContain(INGEST_KEY.secret);
    expect(failure?.message).not.toContain(INGEST_KEY.keyId);
    expect(failure?.message).not.toContain(JSON.stringify(evt));
  });
});

describe("GatewaySender — retryable failure (network, timeout, 5xx)", () => {
  it("retries a 503 initial-plus-three with deterministic full-jitter backoff, then rejects", async () => {
    const { sender, calls, sleeps } = makeSender({ behavior: () => ok(503) });

    const failure = await sender.send(event("evt_503")).then(
      () => null,
      (error: Error) => error,
    );

    expect(calls).toHaveLength(4);
    // full jitter: random() * min(cap, base * 2^n), base 100, random 0.5
    expect(sleeps).toEqual([50, 100, 200]);
    expect(failure?.message).toContain("503");
    expect(failure?.message).toContain("4");
  });

  it.each([500, 502, 504])("treats status %i as retryable", async (status) => {
    const { sender, calls } = makeSender({ behavior: () => ok(status) });

    await expect(sender.send(event(`evt_${status}`))).rejects.toThrow(String(status));
    expect(calls).toHaveLength(4);
  });

  it("bounds the backoff at the configured cap", async () => {
    const { sender, sleeps } = makeSender({
      behavior: () => ok(500),
      random: () => 1,
      backoffBaseMs: 100,
      backoffCapMs: 150,
    });

    await expect(sender.send(event("evt_cap"))).rejects.toThrow("500");
    expect(sleeps).toEqual([100, 150, 150]);
  });

  it("honors a custom maxRetries", async () => {
    const { sender, calls, sleeps } = makeSender({ behavior: () => ok(500), maxRetries: 1 });

    await expect(sender.send(event("evt_mr"))).rejects.toThrow("500");
    expect(calls).toHaveLength(2);
    expect(sleeps).toEqual([50]);
  });

  it("retries a rejected fetch (network error) and succeeds when a later attempt lands", async () => {
    let attempt = 0;
    const { sender, calls, sleeps } = makeSender({
      behavior: () => {
        attempt += 1;
        if (attempt === 1) {
          return Promise.reject(new TypeError("fetch failed: connect ECONNREFUSED"));
        }
        return ok(202);
      },
    });

    await expect(sender.send(event("evt_flaky"))).resolves.toBeUndefined();
    expect(calls).toHaveLength(2);
    expect(sleeps).toEqual([50]);
  });

  it("reports a network-error exhaustion without leaking secret or body", async () => {
    const evt = event("evt_net");
    const rawBody = JSON.stringify(evt);
    const { sender, calls } = makeSender({
      behavior: () =>
        Promise.reject(new Error(`boom ${INGEST_KEY.keyId}.${INGEST_KEY.secret} ${rawBody}`)),
    });

    const failure = await sender.send(evt).then(
      () => null,
      (error: Error) => error,
    );

    expect(calls).toHaveLength(4);
    expect(failure?.message).toContain("network");
    expect(failure?.message).not.toContain(INGEST_KEY.secret);
    expect(failure?.message).not.toContain(INGEST_KEY.keyId);
    expect(failure?.message).not.toContain(rawBody);
  });

  it("treats a synchronous fetch throw as a retryable network failure", async () => {
    const { sender, calls, sleeps } = makeSender({
      behavior: () => {
        throw new Error("sync boom");
      },
    });

    const pending = sender.send(event("evt_sync"));
    expect(pending).toBeInstanceOf(Promise);
    await expect(pending).rejects.toThrow("network");
    expect(calls).toHaveLength(4);
    expect(sleeps).toEqual([50, 100, 200]);
  });

  it("aborts a hung request after the configured timeout and retries", async () => {
    const { sender, calls } = makeSender({
      timeoutMs: 20,
      behavior: (_url, init) =>
        new Promise<FetchResult>((_resolve, reject) => {
          init.signal?.addEventListener("abort", () => {
            reject(new DOMException("The operation timed out.", "TimeoutError"));
          });
        }),
    });

    const failure = await sender.send(event("evt_timeout")).then(
      () => null,
      (error: Error) => error,
    );

    expect(calls).toHaveLength(4);
    expect(failure?.message).toContain("network");
    for (const call of calls) {
      expect(call.init.signal?.aborted).toBe(true);
    }
  }, 10_000);

  it("recomputes the timestamp and signature on every attempt", async () => {
    const times = [1_000, 2_000, 3_000, 4_000];
    let tick = 0;
    const { sender, calls } = makeSender({
      behavior: () => ok(503),
      now: () => times[Math.min(tick++, times.length - 1)],
    });
    const evt = event("evt_per_attempt");
    const rawBody = JSON.stringify(evt);

    await expect(sender.send(evt)).rejects.toThrow("503");

    expect(calls).toHaveLength(4);
    calls.forEach((call, index) => {
      const timestamp = String(times[index]);
      expect(headers(call)["X-Notify-Timestamp"]).toBe(timestamp);
      expect(headers(call)["X-Notify-Signature"]).toBe(expectedSignature(timestamp, rawBody));
      expect(call.init.body).toBe(rawBody);
    });
  });
});
