import type { FastifyInstance } from "fastify";
import { afterEach, describe, expect, it } from "vitest";

import {
  installGracefulShutdown,
  type GracefulShutdown,
} from "../../src/shutdown.js";

/** Minimal FastifyInstance stand-in: shutdown only ever calls `close()`. */
function fakeApp(order: string[]): FastifyInstance {
  return {
    close: async () => {
      order.push("app.close");
    },
  } as unknown as FastifyInstance;
}

describe("installGracefulShutdown", () => {
  const handles: GracefulShutdown[] = [];

  function track(handle: GracefulShutdown): GracefulShutdown {
    handles.push(handle);
    return handle;
  }

  afterEach(() => {
    for (const handle of handles.splice(0)) {
      handle.uninstall();
    }
  });

  it("runs app close, then the database pool, then exit 0", async () => {
    const order: string[] = [];
    const handle = track(
      installGracefulShutdown({
        app: fakeApp(order),
        closeDatabase: async () => {
          order.push("db.close");
        },
        exit: (code) => {
          order.push(`exit:${code}`);
        },
      }),
    );

    await handle.shutdown();

    expect(order).toEqual(["app.close", "db.close", "exit:0"]);
  });

  it("is idempotent: a second (concurrent) shutdown never re-runs the sequence", async () => {
    const order: string[] = [];
    const handle = track(
      installGracefulShutdown({
        app: fakeApp(order),
        closeDatabase: async () => {
          order.push("db.close");
        },
        exit: (code) => {
          order.push(`exit:${code}`);
        },
      }),
    );

    await Promise.all([handle.shutdown(), handle.shutdown()]);
    await handle.shutdown();

    expect(order).toEqual(["app.close", "db.close", "exit:0"]);
  });

  it("registers exactly one SIGINT and one SIGTERM listener per app", () => {
    const sigintBefore = process.listenerCount("SIGINT");
    const sigtermBefore = process.listenerCount("SIGTERM");
    const app = fakeApp([]);

    const first = track(installGracefulShutdown({ app, closeDatabase: async () => {} }));
    expect(process.listenerCount("SIGINT")).toBe(sigintBefore + 1);
    expect(process.listenerCount("SIGTERM")).toBe(sigtermBefore + 1);

    // A duplicate install for the same app must not stack more handlers.
    const second = installGracefulShutdown({ app, closeDatabase: async () => {} });
    expect(second).toBe(first);
    expect(process.listenerCount("SIGINT")).toBe(sigintBefore + 1);
    expect(process.listenerCount("SIGTERM")).toBe(sigtermBefore + 1);
  });

  it("uninstall detaches the signal listeners", () => {
    const sigintBefore = process.listenerCount("SIGINT");
    const sigtermBefore = process.listenerCount("SIGTERM");
    const handle = installGracefulShutdown({
      app: fakeApp([]),
      closeDatabase: async () => {},
    });

    handle.uninstall();

    expect(process.listenerCount("SIGINT")).toBe(sigintBefore);
    expect(process.listenerCount("SIGTERM")).toBe(sigtermBefore);
  });

  it("shutdown detaches the signal listeners so a second signal cannot re-enter", async () => {
    const app = fakeApp([]);
    const handle = track(
      installGracefulShutdown({ app, closeDatabase: async () => {}, exit: () => {} }),
    );
    const sigintBefore = process.listenerCount("SIGINT");
    const sigtermBefore = process.listenerCount("SIGTERM");

    await handle.shutdown();

    expect(process.listenerCount("SIGINT")).toBe(sigintBefore - 1);
    expect(process.listenerCount("SIGTERM")).toBe(sigtermBefore - 1);
  });

  it("a failing close still closes the pool and exits non-zero (never rejects)", async () => {
    const order: string[] = [];
    const app = {
      close: async () => {
        order.push("app.close");
        throw new Error("close failed");
      },
    } as unknown as FastifyInstance;
    const handle = track(
      installGracefulShutdown({
        app,
        closeDatabase: async () => {
          order.push("db.close");
        },
        exit: (code) => {
          order.push(`exit:${code}`);
        },
      }),
    );

    // A signal handler must never produce an unhandled rejection.
    await expect(handle.shutdown()).resolves.toBeUndefined();
    expect(order).toEqual(["app.close", "db.close", "exit:1"]);
  });

  it("forces exit 1 when the drain hangs past the bounded backstop", async () => {
    const order: string[] = [];
    let armed: (() => void) | undefined;
    const app = {
      // Never settles: only the backstop can end this shutdown.
      close: () => new Promise<void>(() => {}),
    } as unknown as FastifyInstance;
    const handle = track(
      installGracefulShutdown({
        app,
        closeDatabase: async () => {},
        exit: (code) => {
          order.push(`exit:${code}`);
        },
        setTimer: (onTimeout) => {
          armed = onTimeout;
          return () => {};
        },
      }),
    );

    void handle.shutdown();
    expect(order).toEqual([]);
    armed?.();
    expect(order).toEqual(["exit:1"]);
  });

  it("a normal finish clears the backstop: the timer never fires a second exit", async () => {
    const order: string[] = [];
    let armed: (() => void) | undefined;
    let cancelled = false;
    const handle = track(
      installGracefulShutdown({
        app: fakeApp(order),
        closeDatabase: async () => {
          order.push("db.close");
        },
        exit: (code) => {
          order.push(`exit:${code}`);
        },
        setTimer: (onTimeout) => {
          armed = onTimeout;
          return () => {
            cancelled = true;
          };
        },
      }),
    );

    await handle.shutdown();

    expect(cancelled).toBe(true);
    expect(order).toEqual(["app.close", "db.close", "exit:0"]);
    // A stale timer callback must not produce a second exit.
    armed?.();
    expect(order).toEqual(["app.close", "db.close", "exit:0"]);
  });

  it("the default backstop timer is unref'd so it cannot hold the process open", async () => {
    const order: string[] = [];
    const handle = track(
      installGracefulShutdown({
        app: fakeApp(order),
        closeDatabase: async () => {
          order.push("db.close");
        },
        exit: (code) => {
          order.push(`exit:${code}`);
        },
        // Default setTimer (real timers, unref'd), shortened deadline.
        forcedExitTimeoutMs: 5,
      }),
    );

    // The drain finishes first; the armed real timer is cleared on time.
    await handle.shutdown();
    await new Promise((resolve) => {
      setTimeout(resolve, 25);
    });
    expect(order).toEqual(["app.close", "db.close", "exit:0"]);
  });
});
