import { describe, expect, it } from "vitest";
import type { NotifyEvent } from "@notify/contracts";

import { QueuePump } from "../src/pump.js";
import type { PumpLogger } from "../src/pump.js";

function base(eventId: string): Omit<NotifyEvent, "type" | "payload"> {
  return {
    eventId,
    occurredAt: "2026-01-01T00:00:00.000Z",
    source: { machine: "m1", project: "proj", directory: "/work" },
    session: { id: "ses_1", title: "Session" },
  };
}

function heartbeat(eventId: string): NotifyEvent {
  return { ...base(eventId), type: "heartbeat", payload: { status: "busy", elapsedSeconds: 1 } };
}

function resolved(eventId: string): NotifyEvent {
  return {
    ...base(eventId),
    type: "action_resolved",
    payload: { requestId: "req_1", kind: "question" },
  };
}

function terminal(eventId: string): NotifyEvent {
  return { ...base(eventId), type: "terminal", payload: { outcome: "completed", elapsedSeconds: 1 } };
}

interface Deferred {
  promise: Promise<void>;
  resolve: () => void;
  reject: (error: Error) => void;
  settled: boolean;
}

function deferred(): Deferred {
  let resolve!: () => void;
  let reject!: (error: Error) => void;
  const state: Deferred = {
    promise: new Promise<void>((res, rej) => {
      resolve = res;
      reject = rej;
    }),
    resolve: () => {
      state.settled = true;
      resolve();
    },
    reject: (error: Error) => {
      state.settled = true;
      reject(error);
    },
    settled: false,
  };
  return state;
}

/**
 * Sender stand-in: every `send` parks on a manually settled deferred and
 * tracks concurrency so tests can prove only one delivery is ever in
 * flight. `throwNext` makes the next `send` throw synchronously.
 */
class FakeSender {
  readonly calls: NotifyEvent[] = [];
  readonly deferreds: Deferred[] = [];
  active = 0;
  maxConcurrent = 0;
  throwNext: Error | null = null;

  send(event: NotifyEvent): Promise<void> {
    this.calls.push(event);
    if (this.throwNext !== null) {
      const error = this.throwNext;
      this.throwNext = null;
      throw error;
    }
    const gate = deferred();
    this.deferreds.push(gate);
    this.active += 1;
    this.maxConcurrent = Math.max(this.maxConcurrent, this.active);
    return gate.promise.finally(() => {
      this.active -= 1;
    });
  }
}

interface LogRecord {
  level: "debug" | "error";
  message: string;
  context?: Record<string, unknown>;
}

function makeLogger(): { logger: PumpLogger; records: LogRecord[] } {
  const records: LogRecord[] = [];
  return {
    records,
    logger: {
      debug(message, context) {
        records.push({ level: "debug", message, context });
      },
      error(message, context) {
        records.push({ level: "error", message, context });
      },
    },
  };
}

/** Let queued microtasks and the drain loop advance. */
async function flush(times = 10): Promise<void> {
  for (let i = 0; i < times; i += 1) {
    await Promise.resolve();
  }
}

function makePump(options: { capacity?: number } = {}) {
  const sender = new FakeSender();
  const { logger, records } = makeLogger();
  const pump = new QueuePump({
    sender,
    logger,
    ...(options.capacity !== undefined ? { capacity: options.capacity } : {}),
  });
  return { pump, sender, records };
}

describe("QueuePump — non-blocking drain", () => {
  it("returns from kick() without awaiting the network", async () => {
    const { pump, sender } = makePump();

    const enqueueResult = pump.enqueue(heartbeat("h1"));

    expect(enqueueResult).toEqual({ accepted: true });
    // The drain started synchronously but the send is still in flight.
    expect(sender.calls.map((e) => e.eventId)).toEqual(["h1"]);
    expect(sender.deferreds[0].settled).toBe(false);

    sender.deferreds[0].resolve();
    await flush();
  });

  it("logs successful delivery without including the event payload", async () => {
    const { pump, sender, records } = makePump();

    pump.enqueue(terminal("t-success"));
    sender.deferreds[0].resolve();
    await flush();

    const success = records.find(
      (record) => record.level === "debug" && record.message.includes("delivery succeeded"),
    );
    expect(success).toEqual({
      level: "debug",
      message: "gateway delivery succeeded for event t-success",
      context: { eventId: "t-success", eventType: "terminal" },
    });
    expect(JSON.stringify(success)).not.toContain("elapsedSeconds");
  });

  it("re-drives the loop when an enqueue lands as an empty drain settles", async () => {
    const { pump, sender } = makePump();

    pump.kick(); // drain on an empty queue: starts and settles immediately
    pump.enqueue(heartbeat("h1")); // may land while that empty drain settles

    await flush();
    expect(sender.calls.map((e) => e.eventId)).toEqual(["h1"]);

    sender.deferreds[0].resolve();
    await flush();
  });

  it("runs one drain loop at a time, no matter how often kicked", async () => {
    const { pump, sender } = makePump();

    pump.enqueue(heartbeat("h1"));
    pump.enqueue(terminal("t1"));
    pump.kick();
    pump.kick();
    pump.enqueue(heartbeat("h2"));

    // Only the first event is being delivered; no parallel loop started.
    expect(sender.calls.map((e) => e.eventId)).toEqual(["h1"]);

    sender.deferreds[0].resolve();
    await flush();
    expect(sender.calls.map((e) => e.eventId)).toEqual(["h1", "t1"]);

    sender.deferreds[1].resolve();
    await flush();
    expect(sender.calls.map((e) => e.eventId)).toEqual(["h1", "t1", "h2"]);

    sender.deferreds[2].resolve();
    await flush();
    expect(sender.maxConcurrent).toBe(1);
  });

  it("drains queued events by priority (FIFO within a priority)", async () => {
    const { pump, sender } = makePump();

    pump.enqueue(heartbeat("h1")); // in flight, blocks the drain
    pump.enqueue(heartbeat("h2"));
    pump.enqueue(terminal("t1"));
    pump.enqueue(resolved("r1"));
    pump.enqueue(terminal("t2"));

    sender.deferreds[0].resolve();
    await flush();
    expect(sender.calls.map((e) => e.eventId)).toEqual(["h1", "t1"]);

    sender.deferreds[1].resolve();
    await flush();
    expect(sender.calls.map((e) => e.eventId)).toEqual(["h1", "t1", "t2"]);

    sender.deferreds[2].resolve();
    await flush();
    expect(sender.calls.map((e) => e.eventId)).toEqual(["h1", "t1", "t2", "r1"]);

    sender.deferreds[3].resolve();
    await flush();
    expect(sender.calls.map((e) => e.eventId)).toEqual(["h1", "t1", "t2", "r1", "h2"]);
  });
});

describe("QueuePump — delivery failure", () => {
  it("logs the failure, drops the event, and continues draining", async () => {
    const { pump, sender, records } = makePump();

    pump.enqueue(terminal("t-bad"));
    pump.enqueue(terminal("t-good"));

    sender.deferreds[0].reject(new Error("gateway event delivery failed after 4 attempts"));
    await flush();

    const errors = records.filter((r) => r.level === "error");
    expect(errors).toHaveLength(1);
    expect(errors[0].message).toContain("t-bad");
    expect(JSON.stringify(errors[0])).not.toContain("elapsedSeconds");
    // The failure did not stop the loop: the next event was delivered.
    expect(sender.calls.map((e) => e.eventId)).toEqual(["t-bad", "t-good"]);

    sender.deferreds[1].resolve();
    await flush();
    expect(sender.maxConcurrent).toBe(1);
  });

  it("absorbs a synchronous sender throw, logs it, and continues", async () => {
    const { pump, sender, records } = makePump();

    pump.enqueue(terminal("t-parked")); // in flight
    sender.throwNext = new Error("sync explosion");
    pump.enqueue(terminal("t-sync")); // this send will throw synchronously
    pump.enqueue(terminal("t-after"));

    sender.deferreds[0].resolve();
    await flush();

    expect(sender.calls.map((e) => e.eventId)).toEqual(["t-parked", "t-sync", "t-after"]);
    const errors = records.filter((r) => r.level === "error");
    expect(errors).toHaveLength(1);
    expect(errors[0].message).toContain("t-sync");

    sender.deferreds[1].resolve();
    await flush();
    expect(sender.maxConcurrent).toBe(1);
  });
});

describe("QueuePump — bounded queue loss logging", () => {
  // The drain loop consumes the first event immediately (its send stays
  // parked on the fake sender), so filling the queue takes capacity + 1
  // enqueues: one in flight, `capacity` waiting.
  it("logs an error when a non-heartbeat event is evicted", () => {
    const { pump, records } = makePump({ capacity: 2 });

    pump.enqueue(terminal("t1")); // in flight
    pump.enqueue(terminal("t2"));
    pump.enqueue(terminal("t3")); // queue full
    const result = pump.enqueue(terminal("t4"));

    expect(result).toEqual({ accepted: true, evicted: terminal("t2") });
    const errors = records.filter((r) => r.level === "error");
    expect(errors).toHaveLength(1);
    expect(errors[0].message).toContain("evict");
    expect(errors[0].message).toContain("t2");
  });

  it("logs heartbeat churn at debug, never error", () => {
    const { pump, records } = makePump({ capacity: 2 });

    pump.enqueue(heartbeat("h1")); // in flight
    pump.enqueue(heartbeat("h2"));
    pump.enqueue(heartbeat("h3")); // queue full
    const result = pump.enqueue(heartbeat("h4"));

    expect(result.accepted).toBe(true);
    expect(result.evicted?.eventId).toBe("h2");
    expect(records.filter((r) => r.level === "error")).toHaveLength(0);
    expect(records.some((r) => r.level === "debug" && r.message.includes("h2"))).toBe(true);
  });

  it("logs a rejected enqueue at debug and reports accepted: false", () => {
    const { pump, records } = makePump({ capacity: 1 });

    pump.enqueue(terminal("t1")); // in flight
    pump.enqueue(terminal("t2")); // queue full
    const result = pump.enqueue(heartbeat("h-rejected"));

    expect(result).toEqual({ accepted: false });
    expect(records.filter((r) => r.level === "error")).toHaveLength(0);
    expect(
      records.some((r) => r.level === "debug" && r.message.includes("h-rejected")),
    ).toBe(true);
  });
});

describe("QueuePump — stop", () => {
  it("prevents new work and drains accepted events after the in-flight send", async () => {
    const { pump, sender } = makePump();

    pump.enqueue(heartbeat("h1")); // in flight
    pump.enqueue(terminal("t1"));

    let stopped = false;
    const stopPromise = pump.stop().then(() => {
      stopped = true;
    });
    await flush();
    expect(stopped).toBe(false);

    sender.deferreds[0].resolve();
    await flush();
    expect(stopped).toBe(false);
    expect(sender.calls.map((e) => e.eventId)).toEqual(["h1", "t1"]);

    sender.deferreds[1].resolve();
    await stopPromise;
    expect(stopped).toBe(true);

    expect(sender.calls.map((e) => e.eventId)).toEqual(["h1", "t1"]);

    // No new work after stop: kick is a no-op and enqueue refuses.
    pump.kick();
    const result = pump.enqueue(heartbeat("h2"));
    await flush();
    expect(result).toEqual({ accepted: false });
    expect(sender.calls.map((e) => e.eventId)).toEqual(["h1", "t1"]);
  });

  it("resolves immediately when idle and tolerates a second stop", async () => {
    const { pump, sender } = makePump();

    await pump.stop();
    await pump.stop();
    pump.kick();
    await flush();
    expect(sender.calls).toHaveLength(0);
  });
});
