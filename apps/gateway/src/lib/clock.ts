/**
 * Injectable time source (plan: stable service boundary). Services take a
 * `Clock` so tests can advance time deterministically — token expiry and
 * `verifiedAt` stamps must never read the wall clock directly.
 */
export interface Clock {
  now(): Date;
  nowMs(): number;
}

/** Wall-clock implementation used by the production wiring. */
export const systemClock: Clock = {
  now: () => new Date(),
  nowMs: () => Date.now(),
};
