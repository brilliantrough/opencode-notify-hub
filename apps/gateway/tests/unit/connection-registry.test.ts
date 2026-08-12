import type { NotifyEvent } from "@notify/contracts";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import type { Clock } from "../../src/lib/clock.js";
import {
  ConnectionRegistry,
  WS_CLOSE_SERVER_SHUTDOWN,
  WS_CLOSE_TOKEN_EXPIRED,
  WS_MAX_BUFFERED_BYTES,
  WS_PING_INTERVAL_MS,
  type RealtimeSocket,
} from "../../src/modules/realtime/connection-registry.js";

const T0 = 1_800_000_000_000;

class FakeClock implements Clock {
  constructor(private value: number) {}

  now(): Date {
    return new Date(this.value);
  }

  nowMs(): number {
    return this.value;
  }
}

/** Matches the `ws` readyState constants the registry checks. */
const OPEN = 1;
const CLOSING = 2;
const CLOSED = 3;

class FakeSocket implements RealtimeSocket {
  readyState: number = OPEN;
  /** Bytes the peer has not yet read (ws.WebSocket.bufferedAmount). */
  bufferedAmount = 0;
  sent: string[] = [];
  pingCount = 0;
  closeCalls: { code?: number; reason?: string }[] = [];
  terminated = false;
  /** When set, the next send reports this error through its callback. */
  sendError: Error | null = null;
  /** When true, send throws synchronously instead of reporting via callback. */
  sendThrows = false;
  /** When true, send records the payload but never invokes the callback
   *  (simulates a TCP flush that never completes). */
  holdSendCallbacks = false;
  /** `ws` reports a successful send as `null`, not `undefined`. */
  sendNullOnSuccess = false;
  private listeners = new Map<string, ((...args: unknown[]) => void)[]>();

  send(data: string, cb?: (err?: Error | null) => void): void {
    if (this.sendThrows) {
      throw new Error("send blew up");
    }
    if (this.sendError !== null) {
      const error = this.sendError;
      this.sendError = null;
      if (cb !== undefined) {
        cb(error);
      }
      return;
    }
    this.sent.push(data);
    if (this.holdSendCallbacks) {
      return;
    }
    if (cb !== undefined) {
      cb(this.sendNullOnSuccess ? null : undefined);
    }
  }

  ping(): void {
    this.pingCount += 1;
  }

  close(code?: number, reason?: string): void {
    this.closeCalls.push({ code, reason });
    this.readyState = CLOSED;
    this.emit("close");
  }

  terminate(): void {
    this.terminated = true;
    this.readyState = CLOSED;
    this.emit("close");
  }

  on(event: string, listener: (...args: unknown[]) => void): void {
    const list = this.listeners.get(event) ?? [];
    list.push(listener);
    this.listeners.set(event, list);
  }

  emit(event: string, ...args: unknown[]): void {
    for (const listener of this.listeners.get(event) ?? []) {
      listener(...args);
    }
  }

  /** Simulate the peer answering a ping. */
  pong(): void {
    this.emit("pong");
  }

  /** Simulate the peer sending its own control-frame heartbeat. */
  peerPing(): void {
    this.emit("ping");
  }
}

const EVENT: NotifyEvent = {
  eventId: "3f6f1e2a-7c3b-4d5e-8f60-1a2b3c4d5e6f",
  type: "heartbeat",
  occurredAt: "2026-08-10T12:00:00.000Z",
  source: { machine: "workstation", project: "notify", directory: "/repo" },
  session: { id: "session-1", title: "Coding" },
  payload: { status: "busy", elapsedSeconds: 12 },
} as NotifyEvent;

/** Far enough in the future that expiry never interferes with the test. */
const NEVER = T0 + 3_600_000;

describe("ConnectionRegistry", () => {
  let clock: FakeClock;
  let registry: ConnectionRegistry;

  beforeEach(() => {
    vi.useFakeTimers();
    clock = new FakeClock(T0);
    registry = new ConnectionRegistry({ clock });
  });

  afterEach(() => {
    registry.closeAll();
    vi.useRealTimers();
  });

  describe("spec constants", () => {
    it("pins the 30-second ping interval and the close codes", () => {
      expect(WS_PING_INTERVAL_MS).toBe(30_000);
      expect(WS_CLOSE_TOKEN_EXPIRED).toBe(4401);
      expect(WS_CLOSE_SERVER_SHUTDOWN).toBe(1012);
    });

    it("pins the backpressure threshold at exactly 1 MiB", () => {
      expect(WS_MAX_BUFFERED_BYTES).toBe(1024 * 1024);
    });
  });

  describe("dispatch", () => {
    it("sends the contract envelope to every open socket of the user", async () => {
      const first = new FakeSocket();
      const second = new FakeSocket();
      registry.add("user-a", first, { expiresAtMs: NEVER });
      registry.add("user-a", second, { expiresAtMs: NEVER });

      await registry.dispatch({ userId: "user-a", event: EVENT });

      const expected = JSON.stringify({ type: "event", event: EVENT });
      expect(first.sent).toEqual([expected]);
      expect(second.sent).toEqual([expected]);
    });

    it("sends nothing to other users' sockets", async () => {
      const mine = new FakeSocket();
      const theirs = new FakeSocket();
      registry.add("user-a", mine, { expiresAtMs: NEVER });
      registry.add("user-b", theirs, { expiresAtMs: NEVER });

      await registry.dispatch({ userId: "user-a", event: EVENT });

      expect(mine.sent).toHaveLength(1);
      expect(theirs.sent).toHaveLength(0);
    });

    it("resolves without sending when the user has no sockets", async () => {
      await expect(
        registry.dispatch({ userId: "nobody", event: EVENT }),
      ).resolves.toBeUndefined();
    });

    it("prunes sockets that are already closed instead of sending to them", async () => {
      const dead = new FakeSocket();
      const alive = new FakeSocket();
      registry.add("user-a", dead, { expiresAtMs: NEVER });
      registry.add("user-a", alive, { expiresAtMs: NEVER });
      dead.readyState = CLOSED;

      await registry.dispatch({ userId: "user-a", event: EVENT });

      expect(dead.sent).toHaveLength(0);
      expect(alive.sent).toHaveLength(1);
      expect(registry.count("user-a")).toBe(1);
    });

    it("prunes sockets whose send reports an error, and still resolves", async () => {
      const failing = new FakeSocket();
      const healthy = new FakeSocket();
      registry.add("user-a", failing, { expiresAtMs: NEVER });
      registry.add("user-a", healthy, { expiresAtMs: NEVER });
      failing.sendError = new Error("broken pipe");

      await expect(
        registry.dispatch({ userId: "user-a", event: EVENT }),
      ).resolves.toBeUndefined();

      expect(registry.count("user-a")).toBe(1);
      // The pruned socket receives nothing afterwards.
      await registry.dispatch({ userId: "user-a", event: EVENT });
      expect(failing.sent).toHaveLength(0);
      expect(healthy.sent).toHaveLength(2);
    });

    it("keeps sockets when ws reports a successful send with null", async () => {
      const socket = new FakeSocket();
      socket.sendNullOnSuccess = true;
      registry.add("user-a", socket, { expiresAtMs: NEVER });

      await registry.dispatch({ userId: "user-a", event: EVENT });
      await registry.dispatch({ userId: "user-a", event: EVENT });

      expect(socket.sent).toHaveLength(2);
      expect(registry.count("user-a")).toBe(1);
    });

    it("prunes sockets whose send throws synchronously, and still resolves", async () => {
      const throwing = new FakeSocket();
      registry.add("user-a", throwing, { expiresAtMs: NEVER });
      throwing.sendThrows = true;

      await expect(
        registry.dispatch({ userId: "user-a", event: EVENT }),
      ).resolves.toBeUndefined();
      expect(registry.count("user-a")).toBe(0);
    });

    it("unregisters a socket when it emits close", async () => {
      const socket = new FakeSocket();
      registry.add("user-a", socket, { expiresAtMs: NEVER });

      socket.emit("close");
      expect(registry.count("user-a")).toBe(0);

      await registry.dispatch({ userId: "user-a", event: EVENT });
      expect(socket.sent).toHaveLength(0);
    });
  });

  describe("backpressure", () => {
    it("resolves without awaiting the TCP flush; a held send callback blocks nothing", async () => {
      const stalled = new FakeSocket();
      stalled.holdSendCallbacks = true; // callback never fires: flush pends forever
      const healthy = new FakeSocket();
      registry.add("user-a", stalled, { expiresAtMs: NEVER });
      registry.add("user-a", healthy, { expiresAtMs: NEVER });

      // If dispatch awaited the stalled socket's callback it would pend
      // forever; flushing fake timers lets any already-settled microtask
      // through while a pended dispatch stays unsettled.
      let firstSettled = false;
      const first = registry
        .dispatch({ userId: "user-a", event: EVENT })
        .then(() => {
          firstSettled = true;
        });
      await vi.advanceTimersByTimeAsync(0);
      expect(firstSettled).toBe(true);
      await first;
      expect(stalled.sent).toHaveLength(1);
      expect(healthy.sent).toHaveLength(1);
      // The stalled socket stays registered: no error was reported.
      expect(registry.count("user-a")).toBe(2);

      // Later events are equally unblocked.
      let secondSettled = false;
      const second = registry
        .dispatch({ userId: "user-a", event: EVENT })
        .then(() => {
          secondSettled = true;
        });
      await vi.advanceTimersByTimeAsync(0);
      expect(secondSettled).toBe(true);
      await second;
      expect(stalled.sent).toHaveLength(2);
      expect(healthy.sent).toHaveLength(2);
    });

    it("terminates and prunes a socket whose bufferedAmount exceeds the threshold", async () => {
      const bloated = new FakeSocket();
      const healthy = new FakeSocket();
      registry.add("user-a", bloated, { expiresAtMs: NEVER });
      registry.add("user-a", healthy, { expiresAtMs: NEVER });
      bloated.bufferedAmount = WS_MAX_BUFFERED_BYTES + 1;

      await registry.dispatch({ userId: "user-a", event: EVENT });

      // Nothing more is queued onto the slow reader; the connection is cut.
      expect(bloated.sent).toHaveLength(0);
      expect(bloated.terminated).toBe(true);
      expect(registry.count("user-a")).toBe(1);
      expect(healthy.sent).toHaveLength(1);
    });

    it("still sends to a socket buffered exactly at the threshold", async () => {
      const atLimit = new FakeSocket();
      registry.add("user-a", atLimit, { expiresAtMs: NEVER });
      atLimit.bufferedAmount = WS_MAX_BUFFERED_BYTES;

      await registry.dispatch({ userId: "user-a", event: EVENT });

      expect(atLimit.sent).toHaveLength(1);
      expect(atLimit.terminated).toBe(false);
      expect(registry.count("user-a")).toBe(1);
    });
  });

  describe("heartbeat", () => {
    it("pings after one interval and keeps a socket that pongs", () => {
      const socket = new FakeSocket();
      registry.add("user-a", socket, { expiresAtMs: NEVER });

      vi.advanceTimersByTime(WS_PING_INTERVAL_MS);
      expect(socket.pingCount).toBe(1);
      expect(socket.terminated).toBe(false);

      socket.pong();
      vi.advanceTimersByTime(WS_PING_INTERVAL_MS);
      expect(socket.pingCount).toBe(2);
      expect(socket.terminated).toBe(false);
      expect(registry.count("user-a")).toBe(1);
    });

    it("keeps a socket whose peer sends its own ping", () => {
      const socket = new FakeSocket();
      registry.add("user-a", socket, { expiresAtMs: NEVER });

      vi.advanceTimersByTime(WS_PING_INTERVAL_MS);
      expect(socket.pingCount).toBe(1);

      socket.peerPing();
      vi.advanceTimersByTime(WS_PING_INTERVAL_MS);
      expect(socket.pingCount).toBe(2);
      expect(socket.terminated).toBe(false);
      expect(registry.count("user-a")).toBe(1);
    });

    it("terminates and unregisters a socket that misses a whole interval", () => {
      const socket = new FakeSocket();
      registry.add("user-a", socket, { expiresAtMs: NEVER });

      vi.advanceTimersByTime(WS_PING_INTERVAL_MS);
      expect(socket.pingCount).toBe(1);

      // No pong: the next interval sweep declares the socket stale.
      vi.advanceTimersByTime(WS_PING_INTERVAL_MS);
      expect(socket.terminated).toBe(true);
      expect(registry.count("user-a")).toBe(0);
    });

    it("never pings a socket that is no longer OPEN; CLOSING sockets are pruned", () => {
      const closing = new FakeSocket();
      const open = new FakeSocket();
      registry.add("user-a", closing, { expiresAtMs: NEVER });
      registry.add("user-a", open, { expiresAtMs: NEVER });
      closing.readyState = CLOSING;

      vi.advanceTimersByTime(WS_PING_INTERVAL_MS);

      expect(closing.pingCount).toBe(0);
      expect(registry.count("user-a")).toBe(1);
      expect(open.pingCount).toBe(1);
    });
  });

  describe("access-token expiry", () => {
    it("closes the socket with 4401 when the token reaches exp", () => {
      const socket = new FakeSocket();
      registry.add("user-a", socket, { expiresAtMs: T0 + 5_000 });

      vi.advanceTimersByTime(4_999);
      expect(socket.closeCalls).toHaveLength(0);

      vi.advanceTimersByTime(1);
      expect(socket.closeCalls).toHaveLength(1);
      expect(socket.closeCalls[0].code).toBe(WS_CLOSE_TOKEN_EXPIRED);
      expect(registry.count("user-a")).toBe(0);
    });

    it("closes an already-expired token's socket immediately", () => {
      const socket = new FakeSocket();
      registry.add("user-a", socket, { expiresAtMs: T0 - 1 });

      vi.advanceTimersByTime(0);
      expect(socket.closeCalls).toHaveLength(1);
      expect(socket.closeCalls[0].code).toBe(WS_CLOSE_TOKEN_EXPIRED);
      expect(registry.count("user-a")).toBe(0);
    });
  });

  describe("closeAll", () => {
    it("closes every socket with 1012 and empties the registry", async () => {
      const first = new FakeSocket();
      const second = new FakeSocket();
      registry.add("user-a", first, { expiresAtMs: NEVER });
      registry.add("user-b", second, { expiresAtMs: NEVER });

      registry.closeAll();

      for (const socket of [first, second]) {
        expect(socket.closeCalls).toHaveLength(1);
        expect(socket.closeCalls[0].code).toBe(WS_CLOSE_SERVER_SHUTDOWN);
      }
      expect(registry.count("user-a")).toBe(0);
      expect(registry.count("user-b")).toBe(0);

      // No lingering timers or registrations: nothing is sent afterwards.
      await registry.dispatch({ userId: "user-a", event: EVENT });
      expect(first.sent).toHaveLength(0);
      vi.advanceTimersByTime(WS_PING_INTERVAL_MS * 2);
      expect(first.pingCount).toBe(0);
    });
  });
});
