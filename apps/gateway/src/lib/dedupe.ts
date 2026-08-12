import type { Clock } from "./clock.js";

/** Replay window of the per-user event dedupe: ten minutes. */
export const DEDUPE_TTL_MS = 10 * 60 * 1000;

/** Maximum retained (userId, eventId) pairs; overflow evicts oldest-first. */
export const DEDUPE_MAX_SIZE = 100_000;

/**
 * In-memory per-user event dedupe with single-flight dispatch (design:
 * events are deduplicated per user by eventId for a short window).
 * Process-local like the rate-limit store — the deployment target is a
 * single gateway instance, and nothing here is persisted.
 *
 * The first caller for a (userId, eventId) pair owns one dispatch promise;
 * concurrent duplicates await the same promise and can never trigger a
 * second dispatch. Only a successful dispatch commits the ten-minute dedupe
 * entry; a failure removes the in-flight state, so owner and waiters all
 * fail and a later retry dispatches again.
 *
 * Committed entries live in a Map keyed by `${userId} ${eventId}` with
 * their expiry stamp; insertion order doubles as oldest-first eviction
 * order. Expired entries are swept lazily on capacity pressure, so a burst
 * of one-shot events never evicts live ones.
 */
export class EventDedupe {
  private readonly committed = new Map<string, number>();
  private readonly inFlight = new Map<string, Promise<void>>();

  constructor(
    private readonly clock: Clock,
    private readonly ttlMs: number = DEDUPE_TTL_MS,
    private readonly maxSize: number = DEDUPE_MAX_SIZE,
  ) {}

  /**
   * Runs `dispatch` at most once per live (userId, eventId) pair. Returns
   * `false` to the owning caller (whose dispatch ran) and `true` to every
   * duplicate — whether it awaited the in-flight dispatch or found the
   * committed entry. A dispatch failure rejects the owner and every waiter
   * with the same error and commits nothing.
   */
  async dispatchOnce(
    userId: string,
    eventId: string,
    dispatch: () => Promise<void>,
  ): Promise<boolean> {
    const key = `${userId} ${eventId}`;
    const expiresAt = this.committed.get(key);
    if (expiresAt !== undefined && expiresAt > this.clock.nowMs()) {
      return true;
    }

    const pending = this.inFlight.get(key);
    if (pending !== undefined) {
      await pending;
      return true;
    }

    // No await between the in-flight check and the registration: ownership
    // is atomic with respect to the event loop, so concurrent duplicates
    // always attach as waiters instead of dispatching twice.
    const run = (async () => {
      await dispatch();
    })();
    this.inFlight.set(key, run);
    try {
      await run;
    } catch (error) {
      this.inFlight.delete(key);
      throw error;
    }
    this.inFlight.delete(key);
    this.commit(key);
    return false;
  }

  private commit(key: string): void {
    const now = this.clock.nowMs();
    // (Re)insert at the tail so Map order stays oldest-first.
    this.committed.delete(key);
    this.committed.set(key, now + this.ttlMs);
    if (this.committed.size > this.maxSize) {
      this.evictExpired(now);
    }
    while (this.committed.size > this.maxSize) {
      const oldest = this.committed.keys().next();
      if (oldest.done) {
        break;
      }
      this.committed.delete(oldest.value);
    }
  }

  private evictExpired(now: number): void {
    for (const [key, expiresAt] of this.committed) {
      if (expiresAt <= now) {
        this.committed.delete(key);
      }
    }
  }
}
