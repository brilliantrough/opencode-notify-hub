import type { FastifyInstance } from "fastify";

/**
 * Bounded forced-exit backstop: when the drain hangs (a socket never
 * closes, the pool never ends), the process still exits — non-zero, because
 * an orderly shutdown did not complete — at most this long after the
 * signal. The timer is unref'd so it can never hold the process open after
 * a normal finish.
 */
export const FORCED_EXIT_TIMEOUT_MS = 10_000;

export interface GracefulShutdownDeps {
  /** The running server; `close()` stops accepts and drains connections. */
  app: FastifyInstance;
  /** End the database pool after the app has drained. */
  closeDatabase: () => Promise<void>;
  /** Defaults to `process.exit`; tests inject a recorder. */
  exit?: (code: number) => void;
  /** Backstop deadline; defaults to {@link FORCED_EXIT_TIMEOUT_MS}. */
  forcedExitTimeoutMs?: number;
  /**
   * Timer seam for the backstop; tests inject a manually-fired clock.
   * Receives the timeout callback and the deadline, returns a cancel
   * function. The default arms an unref'd `setTimeout`.
   */
  setTimer?: (onTimeout: () => void, ms: number) => () => void;
}

export interface GracefulShutdown {
  /**
   * Run the shutdown sequence once: stop accepts and drain the app
   * (`app.close()` — the realtime `preClose` hook closes every socket with
   * 1012 Service Restart), then close the database pool, then exit 0. A
   * failing step never skips the pool close and flips the exit code to 1;
   * the returned promise never rejects (a signal handler must not produce
   * an unhandled rejection). A hung drain is cut short by the bounded
   * forced-exit backstop ({@link FORCED_EXIT_TIMEOUT_MS}, exit 1), which a
   * normal finish clears. Idempotent: repeat calls share the first run.
   */
  shutdown(): Promise<void>;
  /** Detach the signal listeners (tests, embedding). */
  uninstall(): void;
}

const SIGNALS = ["SIGINT", "SIGTERM"] as const;

/**
 * One shutdown per app: installing twice for the same instance must not
 * stack duplicate signal handlers, so handles are memoized per app.
 */
const installed = new WeakMap<FastifyInstance, GracefulShutdown>();

/** Default backstop clock: a real, unref'd timeout. */
function defaultSetTimer(onTimeout: () => void, ms: number): () => void {
  const timer = setTimeout(onTimeout, ms);
  timer.unref();
  return () => {
    clearTimeout(timer);
  };
}

/**
 * Install SIGINT/SIGTERM handling for the gateway. The sequence is also
 * directly driveable through {@link GracefulShutdown.shutdown}, which keeps
 * the whole flow testable without delivering real signals to the process.
 */
export function installGracefulShutdown(deps: GracefulShutdownDeps): GracefulShutdown {
  const existing = installed.get(deps.app);
  if (existing !== undefined) {
    return existing;
  }

  const exit = deps.exit ?? ((code: number) => process.exit(code));
  const setTimer = deps.setTimer ?? defaultSetTimer;
  const forcedExitTimeoutMs = deps.forcedExitTimeoutMs ?? FORCED_EXIT_TIMEOUT_MS;
  let running: Promise<void> | null = null;

  const onSignal = (): void => {
    void handle.shutdown();
  };

  const removeListeners = (): void => {
    for (const signal of SIGNALS) {
      process.removeListener(signal, onSignal);
    }
  };

  const handle: GracefulShutdown = {
    shutdown(): Promise<void> {
      if (running !== null) {
        return running;
      }
      // Detach first: a second signal during the drain cannot re-enter.
      removeListeners();
      // Arm the backstop before draining: a hung app.close or pool end is
      // force-exited (exit 1 — the orderly sequence did not complete). The
      // settled flag guarantees exit is invoked exactly once, whichever
      // path wins, even against a stale timer callback.
      let settled = false;
      const cancelBackstop = setTimer(() => {
        if (settled) {
          return;
        }
        settled = true;
        exit(1);
      }, forcedExitTimeoutMs);
      running = (async () => {
        let failed = false;
        try {
          await deps.app.close();
        } catch {
          failed = true;
        }
        try {
          await deps.closeDatabase();
        } catch {
          failed = true;
        }
        cancelBackstop();
        if (!settled) {
          settled = true;
          exit(failed ? 1 : 0);
        }
      })();
      return running;
    },
    uninstall(): void {
      removeListeners();
      installed.delete(deps.app);
    },
  };

  for (const signal of SIGNALS) {
    process.on(signal, onSignal);
  }
  installed.set(deps.app, handle);
  return handle;
}
