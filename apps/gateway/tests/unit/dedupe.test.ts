import { describe, expect, it } from "vitest";

import type { Clock } from "../../src/lib/clock.js";
import {
  DEDUPE_MAX_SIZE,
  DEDUPE_TTL_MS,
  EventDedupe,
} from "../../src/lib/dedupe.js";

class FakeClock implements Clock {
  constructor(private value: number) {}

  now(): Date {
    return new Date(this.value);
  }

  nowMs(): number {
    return this.value;
  }

  advance(ms: number): void {
    this.value += ms;
  }
}

const T0 = 1_800_000_000_000;
const USER_A = "11111111-1111-4111-8111-111111111111";
const USER_B = "22222222-2222-4222-8222-222222222222";
const EVENT_1 = "33333333-3333-4333-8333-333333333333";
const EVENT_2 = "44444444-4444-4444-8444-444444444444";

const noop = async (): Promise<void> => {};

function deferred(): { promise: Promise<void>; release: () => void } {
  let release!: () => void;
  const promise = new Promise<void>((resolve) => {
    release = resolve;
  });
  return { promise, release };
}

describe("EventDedupe", () => {
  it("pins the specification constants: ten-minute TTL, 100k capacity", () => {
    expect(DEDUPE_TTL_MS).toBe(10 * 60 * 1000);
    expect(DEDUPE_MAX_SIZE).toBe(100_000);
  });

  it("dispatches the first sighting and reports a repeat inside the TTL as duplicate", async () => {
    const dedupe = new EventDedupe(new FakeClock(T0));
    let dispatches = 0;
    const dispatch = async (): Promise<void> => {
      dispatches += 1;
    };

    await expect(dedupe.dispatchOnce(USER_A, EVENT_1, dispatch)).resolves.toBe(false);
    await expect(dedupe.dispatchOnce(USER_A, EVENT_1, dispatch)).resolves.toBe(true);
    await expect(dedupe.dispatchOnce(USER_A, EVENT_2, dispatch)).resolves.toBe(false);
    expect(dispatches).toBe(2);
  });

  it("isolates dedupe per user: the same eventId from another user dispatches", async () => {
    const dedupe = new EventDedupe(new FakeClock(T0));

    await expect(dedupe.dispatchOnce(USER_A, EVENT_1, noop)).resolves.toBe(false);
    await expect(dedupe.dispatchOnce(USER_B, EVENT_1, noop)).resolves.toBe(false);
    await expect(dedupe.dispatchOnce(USER_A, EVENT_1, noop)).resolves.toBe(true);
    await expect(dedupe.dispatchOnce(USER_B, EVENT_1, noop)).resolves.toBe(true);
  });

  it("expires committed entries at the TTL boundary", async () => {
    const clock = new FakeClock(T0);
    const dedupe = new EventDedupe(clock);

    await expect(dedupe.dispatchOnce(USER_A, EVENT_1, noop)).resolves.toBe(false);

    clock.advance(DEDUPE_TTL_MS - 1);
    await expect(dedupe.dispatchOnce(USER_A, EVENT_1, noop)).resolves.toBe(true);

    clock.advance(2); // now T0 + TTL + 1
    await expect(dedupe.dispatchOnce(USER_A, EVENT_1, noop)).resolves.toBe(false);
    // The recommit starts a fresh window.
    await expect(dedupe.dispatchOnce(USER_A, EVENT_1, noop)).resolves.toBe(true);
  });

  it("evicts the oldest committed entry when capacity is exceeded", async () => {
    const clock = new FakeClock(T0);
    const dedupe = new EventDedupe(clock, DEDUPE_TTL_MS, 2);

    await expect(dedupe.dispatchOnce(USER_A, "a", noop)).resolves.toBe(false);
    clock.advance(1);
    await expect(dedupe.dispatchOnce(USER_A, "b", noop)).resolves.toBe(false);
    clock.advance(1);
    await expect(dedupe.dispatchOnce(USER_A, "c", noop)).resolves.toBe(false); // evicts "a"

    await expect(dedupe.dispatchOnce(USER_A, "b", noop)).resolves.toBe(true);
    await expect(dedupe.dispatchOnce(USER_A, "c", noop)).resolves.toBe(true);
    // "a" was evicted, so it dispatches again (and evicts "b"; checked last).
    await expect(dedupe.dispatchOnce(USER_A, "a", noop)).resolves.toBe(false);
  });

  it("evicts expired entries before live ones when capacity is exceeded", async () => {
    const clock = new FakeClock(T0);
    const dedupe = new EventDedupe(clock, 1_000, 3);

    await expect(dedupe.dispatchOnce(USER_A, "a", noop)).resolves.toBe(false); // expires T0+1000
    clock.advance(500);
    await expect(dedupe.dispatchOnce(USER_A, "b", noop)).resolves.toBe(false); // expires T0+1500
    clock.advance(100);
    await expect(dedupe.dispatchOnce(USER_A, "c", noop)).resolves.toBe(false); // expires T0+1600

    clock.advance(600); // T0+1200: "a" expired, "b"/"c" live
    await expect(dedupe.dispatchOnce(USER_A, "d", noop)).resolves.toBe(false); // sweeps "a"
    await expect(dedupe.dispatchOnce(USER_A, "b", noop)).resolves.toBe(true);
    await expect(dedupe.dispatchOnce(USER_A, "c", noop)).resolves.toBe(true);
    await expect(dedupe.dispatchOnce(USER_A, "d", noop)).resolves.toBe(true);

    clock.advance(100); // T0+1300: nothing expired
    await expect(dedupe.dispatchOnce(USER_A, "e", noop)).resolves.toBe(false); // evicts live "b"
    await expect(dedupe.dispatchOnce(USER_A, "c", noop)).resolves.toBe(true);
    await expect(dedupe.dispatchOnce(USER_A, "d", noop)).resolves.toBe(true);
    await expect(dedupe.dispatchOnce(USER_A, "e", noop)).resolves.toBe(true);
    // "b" was evicted while still inside its TTL. Checked last: it redispatches.
    await expect(dedupe.dispatchOnce(USER_A, "b", noop)).resolves.toBe(false);
  });

  describe("single-flight", () => {
    it("runs concurrent duplicates through one dispatch; waiters share the outcome", async () => {
      const dedupe = new EventDedupe(new FakeClock(T0));
      const gate = deferred();
      let dispatches = 0;

      // dispatchOnce registers the in-flight entry synchronously, so the
      // waiter attaches deterministically without sleeping.
      const owner = dedupe.dispatchOnce(USER_A, EVENT_1, async () => {
        dispatches += 1;
        await gate.promise;
      });
      const waiter = dedupe.dispatchOnce(USER_A, EVENT_1, async () => {
        dispatches += 1;
      });

      gate.release();
      await expect(owner).resolves.toBe(false);
      await expect(waiter).resolves.toBe(true);
      expect(dispatches).toBe(1);

      // The successful dispatch committed: later repeats dedupe.
      await expect(dedupe.dispatchOnce(USER_A, EVENT_1, noop)).resolves.toBe(true);
    });

    it("lets concurrent different eventIds dispatch independently", async () => {
      const dedupe = new EventDedupe(new FakeClock(T0));
      let dispatches = 0;
      const dispatch = async (): Promise<void> => {
        dispatches += 1;
      };
      const [first, second] = await Promise.all([
        dedupe.dispatchOnce(USER_A, EVENT_1, dispatch),
        dedupe.dispatchOnce(USER_A, EVENT_2, dispatch),
      ]);
      expect(first).toBe(false);
      expect(second).toBe(false);
      expect(dispatches).toBe(2);
    });

    it("fails owner and waiters together, commits nothing, and allows a retry", async () => {
      const dedupe = new EventDedupe(new FakeClock(T0));
      const gate = deferred();
      let dispatches = 0;

      const owner = dedupe.dispatchOnce(USER_A, EVENT_1, async () => {
        dispatches += 1;
        await gate.promise;
        throw new Error("fanout down");
      });
      const waiter = dedupe.dispatchOnce(USER_A, EVENT_1, noop);
      const ownerExpectation = expect(owner).rejects.toThrow("fanout down");
      const waiterExpectation = expect(waiter).rejects.toThrow("fanout down");
      gate.release();
      await ownerExpectation;
      await waiterExpectation;
      expect(dispatches).toBe(1);

      // The failure left nothing behind: a retry dispatches again and,
      // succeeding, commits the dedupe entry.
      await expect(
        dedupe.dispatchOnce(USER_A, EVENT_1, async () => {
          dispatches += 1;
        }),
      ).resolves.toBe(false);
      expect(dispatches).toBe(2);
      await expect(dedupe.dispatchOnce(USER_A, EVENT_1, noop)).resolves.toBe(true);
      expect(dispatches).toBe(2);
    });
  });
});
