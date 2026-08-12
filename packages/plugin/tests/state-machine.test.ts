import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import { normalizeEvent, type NormalizedQuestion } from "../src/events.js";
import {
  SessionMachine,
  type SessionActionRequired,
  type SessionActionResolved,
  type SessionCompletion,
  type SessionHeartbeat,
  type SessionProviderAction,
  type SessionTerminal,
  type TimerScheduler,
} from "../src/state-machine.js";

const SESSION = "ses_abc123";
const DEBOUNCE = 15_000;
const HEARTBEAT = 60_000;

interface Harness {
  machine: SessionMachine;
  completions: SessionCompletion[];
  heartbeats: SessionHeartbeat[];
  failures: SessionTerminal[];
  stops: SessionTerminal[];
  actions: SessionActionRequired[];
  resolutions: SessionActionResolved[];
}

function makeMachine(idleDebounceMs?: number, heartbeatMs?: number): Harness {
  const completions: SessionCompletion[] = [];
  const heartbeats: SessionHeartbeat[] = [];
  const failures: SessionTerminal[] = [];
  const stops: SessionTerminal[] = [];
  const actions: SessionActionRequired[] = [];
  const resolutions: SessionActionResolved[] = [];
  const machine = new SessionMachine({
    onCompleted: (completion) => completions.push(completion),
    onHeartbeat: (heartbeat) => heartbeats.push(heartbeat),
    onFailed: (terminal) => failures.push(terminal),
    onStopped: (terminal) => stops.push(terminal),
    onActionRequired: (action) => actions.push(action),
    onActionResolved: (resolution) => resolutions.push(resolution),
    ...(idleDebounceMs === undefined ? {} : { idleDebounceMs }),
    ...(heartbeatMs === undefined ? {} : { heartbeatMs }),
  });
  return { machine, completions, heartbeats, failures, stops, actions, resolutions };
}

/**
 * Fully manual scheduler: proves the machine only ever goes through the
 * injected `TimerScheduler` seam and records the delays it is handed.
 */
class ManualScheduler implements TimerScheduler {
  private current = 0;
  readonly delays: number[] = [];
  cleared = 0;
  private nextHandle = 1;
  private readonly pending = new Map<number, { fireAt: number; callback: () => void }>();

  now(): number {
    return this.current;
  }

  setTimeout(callback: () => void, delayMs: number): unknown {
    const handle = this.nextHandle++;
    this.delays.push(delayMs);
    this.pending.set(handle, { fireAt: this.current + delayMs, callback });
    return handle;
  }

  clearTimeout(handle: unknown): void {
    if (this.pending.delete(handle as number)) {
      this.cleared++;
    }
  }

  advance(ms: number): void {
    const target = this.current + ms;
    for (;;) {
      let due: number | undefined;
      for (const [handle, entry] of this.pending) {
        if (entry.fireAt <= target && (due === undefined || entry.fireAt < this.pending.get(due)!.fireAt)) {
          due = handle;
        }
      }
      if (due === undefined) {
        break;
      }
      const entry = this.pending.get(due)!;
      this.pending.delete(due);
      this.current = entry.fireAt;
      entry.callback();
    }
    this.current = target;
  }
}

describe("SessionMachine completion debounce", () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("emits nothing at 14,999 ms and completed exactly at 15,000 ms", () => {
    const { machine, completions } = makeMachine();
    machine.onBusy(SESSION);
    vi.advanceTimersByTime(5_000);
    machine.onIdle(SESSION); // 5s of work; the debounce delay must not inflate elapsed

    vi.advanceTimersByTime(DEBOUNCE - 1);
    expect(completions).toEqual([]);

    vi.advanceTimersByTime(1);
    expect(completions).toEqual([{ sessionID: SESSION, elapsedMs: 5_000 }]);
  });

  it("a busy during the debounce cancels the pending completion", () => {
    const { machine, completions } = makeMachine();
    machine.onBusy(SESSION);
    machine.onIdle(SESSION);

    vi.advanceTimersByTime(5_000);
    machine.onBusy(SESSION);
    vi.advanceTimersByTime(60_000);
    expect(completions).toEqual([]);

    // The round is still open: a later idle completes it, with elapsed
    // re-snapshotted at that idle from the original busy (t=0), so it is
    // 65,000 ms of work — the cancellation discarded the first snapshot.
    machine.onIdle(SESSION);
    vi.advanceTimersByTime(DEBOUNCE);
    expect(completions).toEqual([{ sessionID: SESSION, elapsedMs: 65_000 }]);
  });

  it("a retry during the debounce cancels the pending completion", () => {
    const { machine, completions } = makeMachine();
    machine.onBusy(SESSION);
    machine.onIdle(SESSION);

    vi.advanceTimersByTime(5_000);
    machine.onRetry(SESSION);
    vi.advanceTimersByTime(60_000);
    expect(completions).toEqual([]);

    machine.onIdle(SESSION);
    vi.advanceTimersByTime(DEBOUNCE);
    expect(completions).toEqual([{ sessionID: SESSION, elapsedMs: 65_000 }]);
  });

  it("a cancellation discards the snapshot; resume re-snapshots from the original busySince", () => {
    const { machine, completions } = makeMachine();
    machine.onBusy(SESSION); // t = 0
    vi.advanceTimersByTime(3_000);
    machine.onIdle(SESSION); // snapshot 3,000
    vi.advanceTimersByTime(5_000);
    machine.onBusy(SESSION); // cancels: snapshot discarded, busySince kept
    vi.advanceTimersByTime(7_000); // t = 15,000
    machine.onIdle(SESSION); // re-snapshots 15,000 — not the frozen 3,000

    vi.advanceTimersByTime(DEBOUNCE - 1);
    expect(completions).toEqual([]);

    vi.advanceTimersByTime(1);
    expect(completions).toEqual([{ sessionID: SESSION, elapsedMs: 15_000 }]);
  });

  it("status-idle and deprecated-idle merge into a single pending timer and keep the first snapshot", () => {
    const { machine, completions } = makeMachine();
    machine.onBusy(SESSION);
    vi.advanceTimersByTime(2_000);
    machine.onIdle(SESSION); // modern session.status idle — snapshots 2,000

    vi.advanceTimersByTime(5_000);
    machine.onIdle(SESSION); // deprecated session.idle — keeps the 2,000 snapshot and the original timer

    vi.advanceTimersByTime(DEBOUNCE - 5_000 - 1);
    expect(completions).toEqual([]);

    vi.advanceTimersByTime(1);
    expect(completions).toEqual([{ sessionID: SESSION, elapsedMs: 2_000 }]);
  });

  it("a busy after completion starts a fresh round with a fresh busySince", () => {
    const { machine, completions } = makeMachine();
    machine.onBusy(SESSION);
    vi.advanceTimersByTime(3_000);
    machine.onIdle(SESSION); // snapshot 3,000
    vi.advanceTimersByTime(DEBOUNCE);
    expect(completions).toEqual([{ sessionID: SESSION, elapsedMs: 3_000 }]);

    // t = 18,000: new round starts here.
    machine.onBusy(SESSION);
    vi.advanceTimersByTime(20_000);
    machine.onIdle(SESSION); // snapshot 20,000

    vi.advanceTimersByTime(DEBOUNCE - 1);
    expect(completions).toHaveLength(1);

    vi.advanceTimersByTime(1);
    expect(completions).toEqual([
      { sessionID: SESSION, elapsedMs: 3_000 },
      { sessionID: SESSION, elapsedMs: 20_000 },
    ]);
  });

  it("elapsed is measured from the first busy of the round, not later busies", () => {
    const { machine, completions } = makeMachine();
    machine.onBusy(SESSION); // t = 0: round starts
    vi.advanceTimersByTime(3_000);
    machine.onBusy(SESSION); // repeated busy keeps the original busySince
    vi.advanceTimersByTime(2_000);
    machine.onIdle(SESSION); // t = 5,000: snapshots 5,000 from the first busy

    vi.advanceTimersByTime(DEBOUNCE);
    expect(completions).toEqual([{ sessionID: SESSION, elapsedMs: 5_000 }]);
  });

  it("a retry keeps the round's original busySince", () => {
    const { machine, completions } = makeMachine();
    machine.onBusy(SESSION); // t = 0
    vi.advanceTimersByTime(3_000);
    machine.onRetry(SESSION);
    vi.advanceTimersByTime(2_000);
    machine.onIdle(SESSION); // t = 5,000: snapshots 5,000 from the first busy

    vi.advanceTimersByTime(DEBOUNCE);
    expect(completions).toEqual([{ sessionID: SESSION, elapsedMs: 5_000 }]);
  });

  it("an idle without any prior busy still completes, with elapsed 0", () => {
    const { machine, completions } = makeMachine();
    machine.onIdle(SESSION);

    vi.advanceTimersByTime(DEBOUNCE - 1);
    expect(completions).toEqual([]);

    vi.advanceTimersByTime(1);
    expect(completions).toEqual([{ sessionID: SESSION, elapsedMs: 0 }]);
  });

  it("a repeated idle after completion does not emit again without a new busy", () => {
    const { machine, completions } = makeMachine();
    machine.onIdle(SESSION);
    vi.advanceTimersByTime(DEBOUNCE);
    expect(completions).toEqual([{ sessionID: SESSION, elapsedMs: 0 }]);

    machine.onIdle(SESSION);
    vi.advanceTimersByTime(60_000);
    expect(completions).toHaveLength(1);
  });

  it("keeps per-session timers and rounds independent", () => {
    const { machine, completions } = makeMachine();
    machine.onBusy("ses_a"); // t = 0
    vi.advanceTimersByTime(5_000);
    machine.onBusy("ses_b"); // t = 5,000
    machine.onIdle("ses_a");

    vi.advanceTimersByTime(DEBOUNCE - 1); // t = 19,999
    expect(completions).toEqual([]);

    vi.advanceTimersByTime(1); // t = 20,000: only ses_a is due, snapshot 5,000
    expect(completions).toEqual([{ sessionID: "ses_a", elapsedMs: 5_000 }]);

    machine.onIdle("ses_b"); // t = 20,000: snapshots 15,000 from its busy at t = 5,000
    vi.advanceTimersByTime(DEBOUNCE);
    expect(completions).toEqual([
      { sessionID: "ses_a", elapsedMs: 5_000 },
      { sessionID: "ses_b", elapsedMs: 15_000 },
    ]);
  });

  it("disposeAll clears pending timers and all session state", () => {
    const { machine, completions } = makeMachine();
    machine.onBusy(SESSION);
    machine.onIdle(SESSION);
    vi.advanceTimersByTime(5_000);

    machine.disposeAll();
    vi.advanceTimersByTime(60_000);
    expect(completions).toEqual([]);

    // State is gone too: a post-dispose round starts from scratch.
    machine.onBusy(SESSION); // t = 65,000
    vi.advanceTimersByTime(10_000);
    machine.onIdle(SESSION); // snapshot 10,000
    vi.advanceTimersByTime(DEBOUNCE);
    expect(completions).toEqual([{ sessionID: SESSION, elapsedMs: 10_000 }]);
  });

  it("flushes pending idle completions without completing active sessions", () => {
    const { machine, completions } = makeMachine();
    machine.onBusy(SESSION);
    vi.advanceTimersByTime(5_000);
    machine.onIdle(SESSION);
    machine.onBusy("ses_active");

    machine.flushPendingCompletions();

    expect(completions).toEqual([{ sessionID: SESSION, elapsedMs: 5_000 }]);
    vi.advanceTimersByTime(60_000);
    expect(completions).toHaveLength(1);
  });

  it("honors a custom idleDebounceMs", () => {
    const { machine, completions } = makeMachine(500);
    machine.onBusy(SESSION);
    vi.advanceTimersByTime(200);
    machine.onIdle(SESSION); // snapshot 200

    vi.advanceTimersByTime(499);
    expect(completions).toEqual([]);

    vi.advanceTimersByTime(1);
    expect(completions).toEqual([{ sessionID: SESSION, elapsedMs: 200 }]);
  });

  it("drives all timing through the injected scheduler", () => {
    const scheduler = new ManualScheduler();
    const completions: SessionCompletion[] = [];
    const machine = new SessionMachine({
      onCompleted: (completion) => completions.push(completion),
      scheduler,
    });

    machine.onBusy(SESSION);
    scheduler.advance(2_000);
    machine.onIdle(SESSION);
    expect(scheduler.delays).toEqual([DEBOUNCE]);

    // Merged idle: no second timer is scheduled.
    scheduler.advance(1_000);
    machine.onIdle(SESSION);
    expect(scheduler.delays).toEqual([DEBOUNCE]);

    // Busy cancels through the injected clearTimeout.
    scheduler.advance(1_000);
    machine.onBusy(SESSION);
    expect(scheduler.cleared).toBe(1);
    scheduler.advance(60_000);
    expect(completions).toEqual([]);

    // Elapsed comes from the injected now(), not Date.now(): the snapshot
    // is taken at the final idle (now = 64,000) from busySince (now = 0).
    machine.onIdle(SESSION);
    scheduler.advance(DEBOUNCE);
    expect(completions).toEqual([{ sessionID: SESSION, elapsedMs: 64_000 }]);
  });
});

describe("SessionMachine heartbeat", () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("emits exactly one heartbeat every 60,000 ms while busy, elapsed from the original busySince", () => {
    const { machine, heartbeats } = makeMachine();
    machine.onBusy(SESSION); // t = 0

    vi.advanceTimersByTime(HEARTBEAT - 1);
    expect(heartbeats).toEqual([]);

    vi.advanceTimersByTime(1); // t = 60,000: first tick
    expect(heartbeats).toEqual([{ sessionID: SESSION, status: "busy", elapsedMs: 60_000 }]);

    vi.advanceTimersByTime(HEARTBEAT); // t = 120,000: re-armed tick
    expect(heartbeats).toEqual([
      { sessionID: SESSION, status: "busy", elapsedMs: 60_000 },
      { sessionID: SESSION, status: "busy", elapsedMs: 120_000 },
    ]);
  });

  it("a retry sets the current heartbeat status without rescheduling the timer", () => {
    const { machine, heartbeats } = makeMachine();
    machine.onBusy(SESSION); // t = 0: heartbeat armed for t = 60,000
    vi.advanceTimersByTime(30_000);
    machine.onRetry(SESSION); // t = 30,000: status becomes retry, timer untouched

    vi.advanceTimersByTime(30_000); // t = 60,000: tick at the ORIGINAL fire time
    expect(heartbeats).toEqual([{ sessionID: SESSION, status: "retry", elapsedMs: 60_000 }]);
  });

  it("a retry without any prior busy opens a round and heartbeats from it", () => {
    const { machine, completions, heartbeats } = makeMachine();
    machine.onRetry(SESSION); // t = 0: opens the round

    vi.advanceTimersByTime(HEARTBEAT); // t = 60,000
    expect(heartbeats).toEqual([{ sessionID: SESSION, status: "retry", elapsedMs: 60_000 }]);

    machine.onIdle(SESSION); // snapshot 60,000 from the retry-opened round
    vi.advanceTimersByTime(DEBOUNCE);
    expect(completions).toEqual([{ sessionID: SESSION, elapsedMs: 60_000 }]);
  });

  it("repeated busy/retry never schedule a duplicate heartbeat timer", () => {
    const scheduler = new ManualScheduler();
    const heartbeats: SessionHeartbeat[] = [];
    const machine = new SessionMachine({
      onCompleted: () => {},
      onHeartbeat: (heartbeat) => heartbeats.push(heartbeat),
      scheduler,
    });

    machine.onBusy(SESSION);
    scheduler.advance(1_000);
    machine.onBusy(SESSION);
    scheduler.advance(1_000);
    machine.onRetry(SESSION);
    // Exactly one timer was ever scheduled despite three active signals.
    expect(scheduler.delays).toEqual([HEARTBEAT]);

    scheduler.advance(HEARTBEAT); // the tick fires at its 60,000 mark; now() is 60,000 there
    expect(heartbeats).toEqual([{ sessionID: SESSION, status: "retry", elapsedMs: 60_000 }]);
    expect(scheduler.delays).toEqual([HEARTBEAT, HEARTBEAT]);
  });

  it("an idle clears the heartbeat", () => {
    const { machine, completions, heartbeats } = makeMachine();
    machine.onBusy(SESSION); // t = 0
    vi.advanceTimersByTime(5_000);
    machine.onIdle(SESSION); // heartbeat stops here

    vi.advanceTimersByTime(180_000);
    expect(heartbeats).toEqual([]);
    expect(completions).toEqual([{ sessionID: SESSION, elapsedMs: 5_000 }]);
  });

  it("failed and stopped clear the heartbeat", () => {
    const { machine, heartbeats } = makeMachine();
    machine.onBusy(SESSION); // t = 0
    vi.advanceTimersByTime(5_000);
    machine.onFailed(SESSION);
    vi.advanceTimersByTime(180_000);
    expect(heartbeats).toEqual([]);

    machine.onBusy(SESSION); // t = 185,000: fresh round re-arms
    vi.advanceTimersByTime(5_000);
    machine.onStopped(SESSION);
    vi.advanceTimersByTime(180_000);
    expect(heartbeats).toEqual([]);
  });

  it("a busy during the debounce re-arms the heartbeat, still elapsed from the original busySince", () => {
    const { machine, heartbeats } = makeMachine();
    machine.onBusy(SESSION); // t = 0
    vi.advanceTimersByTime(5_000);
    machine.onIdle(SESSION); // t = 5,000: heartbeat cleared
    vi.advanceTimersByTime(5_000);
    machine.onBusy(SESSION); // t = 10,000: debounce cancelled, heartbeat re-armed

    vi.advanceTimersByTime(HEARTBEAT); // t = 70,000
    expect(heartbeats).toEqual([{ sessionID: SESSION, status: "busy", elapsedMs: 70_000 }]);
  });

  it("a heartbeat callback that idles the session is not re-armed (reentrant)", () => {
    const heartbeats: SessionHeartbeat[] = [];
    const completions: SessionCompletion[] = [];
    const machine = new SessionMachine({
      onCompleted: (completion) => completions.push(completion),
      onHeartbeat: (heartbeat) => {
        heartbeats.push(heartbeat);
        machine.onIdle(SESSION); // reentrant: close the round from inside the tick
      },
    });
    machine.onBusy(SESSION); // t = 0

    vi.advanceTimersByTime(HEARTBEAT); // t = 60,000: tick emits, then must not re-arm
    expect(heartbeats).toEqual([{ sessionID: SESSION, status: "busy", elapsedMs: 60_000 }]);

    vi.advanceTimersByTime(180_000);
    expect(heartbeats).toHaveLength(1);
    // The reentrant idle still completed the round normally (snapshot 60,000).
    expect(completions).toEqual([{ sessionID: SESSION, elapsedMs: 60_000 }]);
  });

  it("disposeAll stops the heartbeat", () => {
    const { machine, heartbeats } = makeMachine();
    machine.onBusy(SESSION);
    vi.advanceTimersByTime(5_000);

    machine.disposeAll();
    vi.advanceTimersByTime(180_000);
    expect(heartbeats).toEqual([]);
  });

  it("honors a custom heartbeatMs", () => {
    const { machine, heartbeats } = makeMachine(undefined, 1_000);
    machine.onBusy(SESSION);

    vi.advanceTimersByTime(999);
    expect(heartbeats).toEqual([]);

    vi.advanceTimersByTime(1);
    expect(heartbeats).toEqual([{ sessionID: SESSION, status: "busy", elapsedMs: 1_000 }]);
  });
});

describe("SessionMachine terminal outcomes", () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("failed emits immediately once with the actual round elapsed; no completed follows", () => {
    const { machine, completions, failures } = makeMachine();
    machine.onBusy(SESSION); // t = 0
    vi.advanceTimersByTime(5_000);

    machine.onFailed(SESSION); // immediate: no debounce, no timer advance
    expect(failures).toEqual([{ sessionID: SESSION, elapsedMs: 5_000 }]);

    machine.onIdle(SESSION); // a later idle in the same round cannot complete
    vi.advanceTimersByTime(180_000);
    expect(failures).toHaveLength(1);
    expect(completions).toEqual([]);
  });

  it("stopped emits immediately once and suppresses a later completed", () => {
    const { machine, completions, stops } = makeMachine();
    machine.onBusy(SESSION); // t = 0
    vi.advanceTimersByTime(7_000);

    machine.onStopped(SESSION);
    expect(stops).toEqual([{ sessionID: SESSION, elapsedMs: 7_000 }]);

    machine.onIdle(SESSION);
    vi.advanceTimersByTime(180_000);
    expect(stops).toHaveLength(1);
    expect(completions).toEqual([]);
  });

  it("a failure during the idle debounce cancels it and emits the frozen snapshot", () => {
    const { machine, completions, failures } = makeMachine();
    machine.onBusy(SESSION); // t = 0
    vi.advanceTimersByTime(5_000);
    machine.onIdle(SESSION); // t = 5,000: snapshot 5,000, debounce armed

    vi.advanceTimersByTime(10_000); // t = 15,000: debounce still pending
    machine.onFailed(SESSION);
    // The frozen 5,000 snapshot is emitted — the 10,000 ms of debounce wait
    // must NOT be counted.
    expect(failures).toEqual([{ sessionID: SESSION, elapsedMs: 5_000 }]);

    vi.advanceTimersByTime(180_000); // the cancelled debounce never fires
    expect(failures).toHaveLength(1);
    expect(completions).toEqual([]);
  });

  it("a stop during the idle debounce uses the frozen snapshot too", () => {
    const { machine, completions, stops } = makeMachine();
    machine.onBusy(SESSION); // t = 0
    vi.advanceTimersByTime(3_000);
    machine.onIdle(SESSION); // snapshot 3,000

    vi.advanceTimersByTime(10_000);
    machine.onStopped(SESSION);
    expect(stops).toEqual([{ sessionID: SESSION, elapsedMs: 3_000 }]);

    vi.advanceTimersByTime(180_000);
    expect(stops).toHaveLength(1);
    expect(completions).toEqual([]);
  });

  it("stopped after failed in the same round never emits a second terminal", () => {
    const { machine, failures, stops } = makeMachine();
    machine.onBusy(SESSION);
    vi.advanceTimersByTime(5_000);

    machine.onFailed(SESSION);
    expect(failures).toEqual([{ sessionID: SESSION, elapsedMs: 5_000 }]);

    machine.onStopped(SESSION); // higher priority: records the outcome, emits nothing
    expect(stops).toEqual([]);
    expect(failures).toHaveLength(1);
  });

  it("failed after stopped in the same round never emits a second terminal", () => {
    const { machine, failures, stops } = makeMachine();
    machine.onBusy(SESSION);
    vi.advanceTimersByTime(5_000);

    machine.onStopped(SESSION);
    expect(stops).toEqual([{ sessionID: SESSION, elapsedMs: 5_000 }]);

    machine.onFailed(SESSION); // lower priority: emits nothing either
    expect(failures).toEqual([]);
    expect(stops).toHaveLength(1);
  });

  it("a terminal without any prior busy emits elapsed 0", () => {
    const { machine, failures, stops } = makeMachine();
    machine.onFailed(SESSION);
    expect(failures).toEqual([{ sessionID: SESSION, elapsedMs: 0 }]);

    machine.onBusy("ses_other");
    vi.advanceTimersByTime(2_000);
    machine.onStopped("ses_other");
    expect(stops).toEqual([{ sessionID: "ses_other", elapsedMs: 2_000 }]);
  });

  it("a new busy after a terminal resets the round and can complete again", () => {
    const { machine, completions, failures } = makeMachine();
    machine.onBusy(SESSION); // t = 0
    vi.advanceTimersByTime(5_000);
    machine.onFailed(SESSION); // t = 5,000: round 1 closed as failed
    expect(failures).toEqual([{ sessionID: SESSION, elapsedMs: 5_000 }]);

    machine.onBusy(SESSION); // t = 5,000: fresh round, terminal state reset
    vi.advanceTimersByTime(3_000);
    machine.onIdle(SESSION); // snapshot 3,000 from the NEW busy
    vi.advanceTimersByTime(DEBOUNCE);
    expect(completions).toEqual([{ sessionID: SESSION, elapsedMs: 3_000 }]);
    expect(failures).toHaveLength(1);
  });

  it("a failed callback that re-opens the round is not clobbered (reentrant)", () => {
    const failures: SessionTerminal[] = [];
    const completions: SessionCompletion[] = [];
    const machine = new SessionMachine({
      onCompleted: (completion) => completions.push(completion),
      onFailed: (terminal) => {
        failures.push(terminal);
        machine.onBusy(SESSION); // reentrant: new round from inside the terminal
      },
    });
    machine.onBusy(SESSION); // t = 0
    vi.advanceTimersByTime(5_000);

    machine.onFailed(SESSION); // emits, then the callback opens round 2 at t = 5,000
    expect(failures).toEqual([{ sessionID: SESSION, elapsedMs: 5_000 }]);

    vi.advanceTimersByTime(2_000);
    machine.onIdle(SESSION); // snapshot 2,000 from round 2's busy
    vi.advanceTimersByTime(DEBOUNCE);
    expect(completions).toEqual([{ sessionID: SESSION, elapsedMs: 2_000 }]);
    expect(failures).toHaveLength(1);
  });

  it("abort-classified errors become stopped through the events seam", () => {
    const { machine, failures, stops } = makeMachine();
    machine.onBusy(SESSION); // t = 0
    vi.advanceTimersByTime(4_000);

    // The abort classification itself lives in events.ts (pinned in
    // events.test.ts); here the normalized outcome drives the machine.
    const event = normalizeEvent({
      type: "session.error",
      properties: {
        sessionID: SESSION,
        error: { name: "MessageAbortedError", data: { message: "aborted" } },
      },
    });
    if (event?.kind === "session.error" && event.sessionID !== undefined) {
      if (event.outcome === "stopped") {
        machine.onStopped(event.sessionID);
      } else {
        machine.onFailed(event.sessionID);
      }
    }

    expect(stops).toEqual([{ sessionID: SESSION, elapsedMs: 4_000 }]);
    expect(failures).toEqual([]);
  });
});

const QUESTIONS: NormalizedQuestion[] = [
  {
    question: "Which database should the migration target?",
    options: [{ label: "Postgres" }, { label: "SQLite" }],
  },
  {
    question: "Backfill existing rows?",
    options: [{ label: "Yes" }, { label: "No" }],
    multiple: false,
  },
];

const OTHER_QUESTIONS: NormalizedQuestion[] = [{ question: "Pick one", options: [{ label: "A" }] }];

/** Provider action whose dedupe identity falls back to the title (no reason). */
const RETRY_ACTION: SessionProviderAction = {
  provider: "anthropic",
  title: "Re-authenticate",
  message: "OAuth token expired",
  label: "Open login",
  link: "https://example.com/login",
};
// sha256 hex of the canonical identity JSON
// '["ses_abc123","anthropic","Re-authenticate","Open login"]' — computed
// independently of the implementation and pinned as a literal.
const RETRY_ACTION_ID = "provider:d1008f9c2f698b8810721133eccfb31593e5dc884e05fea1800c9d01373bff6c";

describe("SessionMachine question and permission actions", () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("a question ask emits action_required immediately with the full normalized payload", () => {
    const { machine, actions } = makeMachine();
    machine.onBusy(SESSION);
    machine.onQuestionAsked(SESSION, "req_q1", QUESTIONS);

    expect(actions).toEqual([
      { sessionID: SESSION, requestId: "req_q1", kind: "question", questions: QUESTIONS },
    ]);
  });

  it("a duplicate question ask while pending is suppressed and keeps the first payload", () => {
    const { machine, actions, resolutions } = makeMachine();
    machine.onQuestionAsked(SESSION, "req_q1", QUESTIONS);
    machine.onQuestionAsked(SESSION, "req_q1", OTHER_QUESTIONS);
    expect(actions).toEqual([
      { sessionID: SESSION, requestId: "req_q1", kind: "question", questions: QUESTIONS },
    ]);

    // The pending request still resolves exactly once afterwards.
    machine.onQuestionResolved(SESSION, "req_q1");
    expect(resolutions).toEqual([{ sessionID: SESSION, requestId: "req_q1", kind: "question" }]);
  });

  it("a question resolved emits only for a pending request, then removes it", () => {
    const { machine, resolutions } = makeMachine();
    machine.onQuestionResolved(SESSION, "req_unknown"); // never asked: silent
    expect(resolutions).toEqual([]);

    machine.onQuestionAsked(SESSION, "req_q1", QUESTIONS);
    machine.onQuestionResolved(SESSION, "req_q1");
    machine.onQuestionResolved(SESSION, "req_q1"); // already resolved: silent
    expect(resolutions).toEqual([{ sessionID: SESSION, requestId: "req_q1", kind: "question" }]);
  });

  it("the same requestID may be asked again after it resolved", () => {
    const { machine, actions, resolutions } = makeMachine();
    machine.onQuestionAsked(SESSION, "req_q1", QUESTIONS);
    machine.onQuestionResolved(SESSION, "req_q1");
    machine.onQuestionAsked(SESSION, "req_q1", OTHER_QUESTIONS);

    expect(actions).toHaveLength(2);
    expect(actions[1]).toEqual({
      sessionID: SESSION,
      requestId: "req_q1",
      kind: "question",
      questions: OTHER_QUESTIONS,
    });
    expect(resolutions).toHaveLength(1);
  });

  it("a rejected question resolves through the same path (events seam)", () => {
    const { machine, actions, resolutions } = makeMachine();
    machine.onQuestionAsked(SESSION, "req_q1", QUESTIONS);

    // The rejected→resolved mapping lives in events.ts (pinned in
    // events.test.ts); here the normalized outcome drives the machine.
    const event = normalizeEvent({
      type: "question.rejected",
      properties: { sessionID: SESSION, requestID: "req_q1" },
    });
    if (event?.kind === "question.resolved") {
      machine.onQuestionResolved(event.sessionID, event.requestID);
    }

    expect(resolutions).toEqual([{ sessionID: SESSION, requestId: "req_q1", kind: "question" }]);
    expect(actions).toHaveLength(1);
  });

  it("a permission ask emits action_required with permission and summary; resolved emits kind permission", () => {
    const { machine, actions, resolutions } = makeMachine();
    machine.onPermissionAsked(SESSION, "req_p1", "bash", "bash: pnpm test");
    machine.onPermissionAsked(SESSION, "req_p1", "bash", "bash: pnpm build"); // duplicate: suppressed
    expect(actions).toEqual([
      {
        sessionID: SESSION,
        requestId: "req_p1",
        kind: "permission",
        permission: { permission: "bash", summary: "bash: pnpm test" },
      },
    ]);

    machine.onPermissionResolved(SESSION, "req_p1");
    machine.onPermissionResolved(SESSION, "req_p1"); // already resolved: silent
    expect(resolutions).toEqual([{ sessionID: SESSION, requestId: "req_p1", kind: "permission" }]);
  });

  it("tracks question and permission requests independently per session", () => {
    const { machine, actions, resolutions } = makeMachine();
    machine.onQuestionAsked("ses_a", "req_1", QUESTIONS);
    machine.onQuestionAsked("ses_b", "req_1", OTHER_QUESTIONS);
    expect(actions).toHaveLength(2);

    machine.onQuestionResolved("ses_a", "req_1");
    // ses_b's identical requestID is still pending: a duplicate ask there
    // is suppressed, then its own resolve emits.
    machine.onQuestionAsked("ses_b", "req_1", QUESTIONS);
    expect(actions).toHaveLength(2);
    machine.onQuestionResolved("ses_b", "req_1");

    expect(resolutions).toEqual([
      { sessionID: "ses_a", requestId: "req_1", kind: "question" },
      { sessionID: "ses_b", requestId: "req_1", kind: "question" },
    ]);
  });

  it("identical question and permission requestIDs neither suppress nor resolve each other", () => {
    const { machine, actions, resolutions } = makeMachine();
    machine.onQuestionAsked(SESSION, "req_shared", QUESTIONS);
    // Same upstream ID as a permission: a DIFFERENT pending request, not a
    // duplicate — it must emit.
    machine.onPermissionAsked(SESSION, "req_shared", "bash", "bash: pnpm test");
    expect(actions).toHaveLength(2);
    expect(actions[1]?.kind).toBe("permission");

    // Resolving the question leaves the same-ID permission pending.
    machine.onQuestionResolved(SESSION, "req_shared");
    expect(resolutions).toEqual([{ sessionID: SESSION, requestId: "req_shared", kind: "question" }]);
    machine.onPermissionAsked(SESSION, "req_shared", "bash", "bash: pnpm build"); // still pending: suppressed
    expect(actions).toHaveLength(2);

    machine.onPermissionResolved(SESSION, "req_shared");
    expect(resolutions).toEqual([
      { sessionID: SESSION, requestId: "req_shared", kind: "question" },
      { sessionID: SESSION, requestId: "req_shared", kind: "permission" },
    ]);
  });

  it("a resolve only ever resolves its own kind", () => {
    const { machine, actions, resolutions } = makeMachine();
    machine.onQuestionAsked(SESSION, "req_q1", QUESTIONS);
    machine.onPermissionAsked(SESSION, "req_p1", "bash", "bash: pnpm test");

    // Cross-kind resolves hit nothing pending of that kind: silent.
    machine.onPermissionResolved(SESSION, "req_q1");
    machine.onQuestionResolved(SESSION, "req_p1");
    expect(resolutions).toEqual([]);

    // Both requests are still pending: duplicates suppressed, own-kind
    // resolves emit.
    machine.onQuestionAsked(SESSION, "req_q1", OTHER_QUESTIONS);
    machine.onPermissionAsked(SESSION, "req_p1", "bash", "bash: pnpm build");
    expect(actions).toHaveLength(2);
    machine.onQuestionResolved(SESSION, "req_q1");
    machine.onPermissionResolved(SESSION, "req_p1");
    expect(resolutions).toEqual([
      { sessionID: SESSION, requestId: "req_q1", kind: "question" },
      { sessionID: SESSION, requestId: "req_p1", kind: "permission" },
    ]);
  });
});

describe("SessionMachine provider actions", () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("a retry with an action emits provider_action immediately with a deterministic synthetic requestId", () => {
    const { machine, actions } = makeMachine();
    machine.onRetry(SESSION, RETRY_ACTION);

    expect(actions).toEqual([
      {
        sessionID: SESSION,
        requestId: RETRY_ACTION_ID,
        kind: "provider_action",
        providerAction: {
          provider: "anthropic",
          title: "Re-authenticate",
          message: "OAuth token expired",
          label: "Open login",
          link: "https://example.com/login",
        },
      },
    ]);
  });

  it("the synthetic requestId is a bounded stable hash: provider:<64 lowercase hex>, 73 chars, machine-independent", () => {
    const first = makeMachine();
    const second = makeMachine();
    first.machine.onRetry(SESSION, RETRY_ACTION);
    second.machine.onRetry(SESSION, RETRY_ACTION);

    const id = first.actions[0]?.requestId ?? "";
    expect(id).toMatch(/^provider:[0-9a-f]{64}$/);
    expect(id).toHaveLength(73);
    expect(second.actions[0]?.requestId).toBe(id); // deterministic across machines
    expect(id).toBe(RETRY_ACTION_ID); // pinned literal: stability across runs
  });

  it("the dedupe identity excludes the message and link", () => {
    const { machine, actions } = makeMachine();
    machine.onRetry(SESSION, RETRY_ACTION);
    // Same provider/title/label, different free-text fields: SAME action,
    // still suppressed — message/link never feed the hash.
    machine.onRetry(SESSION, {
      ...RETRY_ACTION,
      message: "Token expired again, please re-authenticate",
      link: "https://example.com/alt-login",
    });
    expect(actions).toHaveLength(1);
  });

  it("delimiter-containing fields cannot collide across field boundaries", () => {
    const { machine, actions } = makeMachine();
    // With a naive `:`-joined key both would be
    // `ses_abc123:acme:inc:Re-authenticate:Open login` — a collision that
    // would wrongly suppress the second ask.
    machine.onRetry(SESSION, { ...RETRY_ACTION, provider: "acme:inc" });
    machine.onRetry(SESSION, { ...RETRY_ACTION, provider: "acme", title: "inc:Re-authenticate" });

    expect(actions).toHaveLength(2);
    expect(actions[0]?.requestId).toBe(
      "provider:47ed58f17658cf86dfb58afb2ae60d0c79b8e7d42857fb6f3775aaa21258e279",
    );
    expect(actions[1]?.requestId).toBe(
      "provider:ce34aa1d4e34871b12ef6585f7dcdd0a05a56c38543edb2fd39aae68f1f3e8d7",
    );
  });

  it("the dedupe identity uses the reason when present, not the title", () => {
    const { machine, actions } = makeMachine();
    machine.onRetry(SESSION, { ...RETRY_ACTION, reason: "oauth_expired" });

    expect(actions).toEqual([
      {
        sessionID: SESSION,
        requestId: "provider:dbde1a960fdd3d5310dc6ca41c3ddf4370888d064274266ab445f8000b0cf3e2",
        kind: "provider_action",
        providerAction: {
          provider: "anthropic",
          title: "Re-authenticate",
          message: "OAuth token expired",
          label: "Open login",
          link: "https://example.com/login",
        },
      },
    ]);
  });

  it("a repeated identical provider action is suppressed while pending", () => {
    const { machine, actions, resolutions } = makeMachine();
    machine.onRetry(SESSION, RETRY_ACTION);
    machine.onRetry(SESSION, RETRY_ACTION);
    machine.onRetry(SESSION, { ...RETRY_ACTION }); // equal by value: still the same action
    expect(actions).toHaveLength(1);
    expect(resolutions).toEqual([]); // provider actions never resolve
  });

  it("a changed provider action replaces the pending one and emits again, without any resolved", () => {
    const { machine, actions, resolutions } = makeMachine();
    machine.onRetry(SESSION, RETRY_ACTION);
    machine.onRetry(SESSION, { ...RETRY_ACTION, label: "Open settings" }); // changed: replaces
    expect(actions).toHaveLength(2);
    expect(actions[1]?.requestId).toBe(
      "provider:31e51d2731d0fadb2131a4d30ed178a7485933214bc76f927bf9363e5c77122a",
    );

    // The replaced action is gone: asking it again re-emits.
    machine.onRetry(SESSION, RETRY_ACTION);
    expect(actions).toHaveLength(3);
    expect(actions[2]?.requestId).toBe(RETRY_ACTION_ID);
    expect(resolutions).toEqual([]);
  });

  it("a busy without an action clears the pending provider action silently", () => {
    const { machine, actions, resolutions } = makeMachine();
    machine.onRetry(SESSION, RETRY_ACTION);
    machine.onBusy(SESSION); // busy never carries an action: pending provider action drops
    machine.onRetry(SESSION, RETRY_ACTION); // same action emits again

    expect(actions).toHaveLength(2);
    expect(actions[1]?.requestId).toBe(RETRY_ACTION_ID);
    expect(resolutions).toEqual([]);
  });

  it("a terminal clears the pending provider action silently", () => {
    const { machine, actions, resolutions } = makeMachine();
    machine.onRetry(SESSION, RETRY_ACTION);
    machine.onFailed(SESSION);
    expect(resolutions).toEqual([]); // no fabricated resolved for the dropped action

    machine.onRetry(SESSION, RETRY_ACTION); // fresh round: the same action emits again
    expect(actions).toHaveLength(2);

    machine.onStopped(SESSION);
    expect(resolutions).toEqual([]);
    machine.onRetry(SESSION, RETRY_ACTION);
    expect(actions).toHaveLength(3);
  });
});

describe("SessionMachine action cleanup and isolation", () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("failed and stopped clear pending question/permission requests without fabricating resolved events", () => {
    const { machine, actions, resolutions } = makeMachine();
    machine.onBusy(SESSION);
    machine.onQuestionAsked(SESSION, "req_q1", QUESTIONS);
    machine.onPermissionAsked(SESSION, "req_p1", "bash", "bash: pnpm test");

    machine.onFailed(SESSION);
    expect(resolutions).toEqual([]);

    // Both requests were dropped: the same IDs may be asked again.
    machine.onQuestionAsked(SESSION, "req_q1", QUESTIONS);
    machine.onPermissionAsked(SESSION, "req_p1", "bash", "bash: pnpm test");
    expect(actions).toHaveLength(4);

    machine.onStopped(SESSION);
    expect(resolutions).toEqual([]);
    machine.onQuestionAsked(SESSION, "req_q1", QUESTIONS);
    expect(actions).toHaveLength(5);
  });

  it("a completed round clears pending question/permission requests silently", () => {
    const { machine, actions, completions, resolutions } = makeMachine();
    machine.onBusy(SESSION);
    machine.onQuestionAsked(SESSION, "req_q1", QUESTIONS);
    machine.onPermissionAsked(SESSION, "req_p1", "bash", "bash: pnpm test");
    machine.onIdle(SESSION);

    vi.advanceTimersByTime(DEBOUNCE);
    expect(completions).toEqual([{ sessionID: SESSION, elapsedMs: 0 }]);
    expect(resolutions).toEqual([]); // dropped without resolved events

    machine.onQuestionAsked(SESSION, "req_q1", QUESTIONS);
    machine.onPermissionAsked(SESSION, "req_p1", "bash", "bash: pnpm test");
    expect(actions).toHaveLength(4);
  });

  it("a busy that cancels the debounce keeps pending question/permission requests", () => {
    const { machine, actions, completions, resolutions } = makeMachine();
    machine.onBusy(SESSION);
    machine.onQuestionAsked(SESSION, "req_q1", QUESTIONS);
    machine.onIdle(SESSION);
    machine.onBusy(SESSION); // debounce cancelled: the round continues, question stays pending

    machine.onQuestionAsked(SESSION, "req_q1", OTHER_QUESTIONS); // still pending: suppressed
    expect(actions).toHaveLength(1);

    machine.onIdle(SESSION);
    vi.advanceTimersByTime(DEBOUNCE);
    expect(completions).toEqual([{ sessionID: SESSION, elapsedMs: 0 }]);
    expect(resolutions).toEqual([]); // cleared by the completion, silently
  });

  it("actions arriving before any busy start no round, heartbeat, or debounce", () => {
    const scheduler = new ManualScheduler();
    const completions: SessionCompletion[] = [];
    const heartbeats: SessionHeartbeat[] = [];
    const failures: SessionTerminal[] = [];
    const actions: SessionActionRequired[] = [];
    const resolutions: SessionActionResolved[] = [];
    const machine = new SessionMachine({
      onCompleted: (completion) => completions.push(completion),
      onHeartbeat: (heartbeat) => heartbeats.push(heartbeat),
      onFailed: (terminal) => failures.push(terminal),
      onActionRequired: (action) => actions.push(action),
      onActionResolved: (resolution) => resolutions.push(resolution),
      scheduler,
    });

    machine.onQuestionAsked(SESSION, "req_q1", QUESTIONS);
    machine.onPermissionAsked(SESSION, "req_p1", "bash", "bash: pnpm test");
    machine.onQuestionResolved(SESSION, "req_q1");
    expect(actions).toHaveLength(2);
    expect(resolutions).toHaveLength(1);

    // No timer was ever scheduled, and time passing emits nothing.
    expect(scheduler.delays).toEqual([]);
    scheduler.advance(300_000);
    expect(completions).toEqual([]);
    expect(heartbeats).toEqual([]);
    expect(failures).toEqual([]);

    // A later terminal measures no working period.
    machine.onFailed(SESSION);
    expect(failures).toEqual([{ sessionID: SESSION, elapsedMs: 0 }]);
  });

  it("asks and resolves never perturb the heartbeat, debounce, or elapsed", () => {
    const scheduler = new ManualScheduler();
    const completions: SessionCompletion[] = [];
    const heartbeats: SessionHeartbeat[] = [];
    const machine = new SessionMachine({
      onCompleted: (completion) => completions.push(completion),
      onHeartbeat: (heartbeat) => heartbeats.push(heartbeat),
      onActionRequired: () => {},
      scheduler,
    });

    machine.onBusy(SESSION); // t = 0: heartbeat armed
    scheduler.advance(5_000);
    machine.onQuestionAsked(SESSION, "req_q1", QUESTIONS); // t = 5,000: no timer traffic
    machine.onPermissionAsked(SESSION, "req_p1", "bash", "bash: pnpm test");
    expect(scheduler.delays).toEqual([HEARTBEAT]);

    scheduler.advance(55_000); // t = 60,000: heartbeat fires at its original time
    expect(heartbeats).toEqual([{ sessionID: SESSION, status: "busy", elapsedMs: 60_000 }]);
    expect(scheduler.delays).toEqual([HEARTBEAT, HEARTBEAT]);

    machine.onQuestionResolved(SESSION, "req_q1");
    machine.onIdle(SESSION); // t = 60,000: snapshot 60,000; debounce armed
    machine.onQuestionAsked(SESSION, "req_q2", QUESTIONS); // asked during the debounce
    scheduler.advance(DEBOUNCE);
    expect(completions).toEqual([{ sessionID: SESSION, elapsedMs: 60_000 }]);
    expect(scheduler.delays).toEqual([HEARTBEAT, HEARTBEAT, DEBOUNCE]);
  });

  it("an action_required callback that resolves the request reentrantly is consistent", () => {
    const actions: SessionActionRequired[] = [];
    const resolutions: SessionActionResolved[] = [];
    const machine = new SessionMachine({
      onCompleted: () => {},
      onActionRequired: (action) => {
        actions.push(action);
        if (action.kind === "question") {
          machine.onQuestionResolved(action.sessionID, action.requestId); // reentrant resolve
        }
      },
      onActionResolved: (resolution) => resolutions.push(resolution),
    });

    machine.onQuestionAsked(SESSION, "req_q1", QUESTIONS);
    expect(actions).toHaveLength(1);
    expect(resolutions).toEqual([{ sessionID: SESSION, requestId: "req_q1", kind: "question" }]);

    machine.onQuestionResolved(SESSION, "req_q1"); // already resolved reentrantly: silent
    expect(resolutions).toHaveLength(1);
  });

  it("disposeAll drops pending actions along with the session state", () => {
    const { machine, actions, resolutions } = makeMachine();
    machine.onQuestionAsked(SESSION, "req_q1", QUESTIONS);
    machine.onRetry(SESSION, RETRY_ACTION);
    expect(actions).toHaveLength(2);

    machine.disposeAll();
    machine.onQuestionResolved(SESSION, "req_q1"); // state is gone: silent
    expect(resolutions).toEqual([]);

    machine.onQuestionAsked(SESSION, "req_q1", QUESTIONS); // a fresh ask emits again
    expect(actions).toHaveLength(3);
  });
});
