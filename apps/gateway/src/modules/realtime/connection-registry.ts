import type { NotifyEvent } from "@notify/contracts";

import type { Clock } from "../../lib/clock.js";
import type { EventDispatcher } from "../events/events.routes.js";

/** Server pings every open socket this often and expects a pong per interval. */
export const WS_PING_INTERVAL_MS = 30_000;

/**
 * Backpressure ceiling: a socket with more than this many unflushed bytes is
 * a hopelessly slow reader — terminate it instead of queueing further events
 * into an unbounded kernel/user-space buffer. Exactly 1 MiB.
 */
export const WS_MAX_BUFFERED_BYTES = 1024 * 1024;

/**
 * Application-level close codes. 4401 tells the client its access token
 * reached `exp` (refresh, then reconnect); 1012 (Service Restart) is the
 * graceful-shutdown close.
 */
export const WS_CLOSE_TOKEN_EXPIRED = 4401;
export const WS_CLOSE_SERVER_SHUTDOWN = 1012;

/** `ws` readyState constant for an open connection. */
const READY_OPEN = 1;

/**
 * The structural subset of a `ws` WebSocket the registry drives. Declared
 * structurally (rather than importing `ws`) so the registry — a plain
 * in-memory index — stays unit-testable without real sockets.
 */
export interface RealtimeSocket {
  readonly readyState: number;
  /** Bytes written but not yet flushed to the peer (ws.WebSocket). */
  readonly bufferedAmount: number;
  send(data: string, cb?: (err?: Error | null) => void): void;
  ping(): void;
  close(code?: number, reason?: string): void;
  terminate(): void;
  on(event: string, listener: (...args: unknown[]) => void): void;
}

interface Connection {
  socket: RealtimeSocket;
  /** Reset by every peer pong or ping; a full silent interval means dead. */
  alive: boolean;
  heartbeat: NodeJS.Timeout;
  expiry: NodeJS.Timeout;
}

export interface ConnectionRegistryDeps {
  clock: Clock;
  /** Defaults to {@link WS_PING_INTERVAL_MS}; tests pass a small value. */
  pingIntervalMs?: number;
}

/**
 * Per-user index of open realtime sockets and the {@link EventDispatcher}
 * the ingest route fans out through. Sending the contract envelope
 * `{type:"event",event}` is best-effort per socket: failed or closed sockets
 * are pruned, never retried, and dispatch never rejects (events are not
 * persisted, so a dispatch failure must not surface as an ingest failure).
 * Zero online recipients still counts as a successful realtime dispatch —
 * the event is deduped and never replayed by design (no event store, no
 * catch-up; offline delivery is FCM's job, not this module's).
 *
 * Each connection carries two timers: the heartbeat (ping every interval,
 * terminate after a full silent interval) and the token-expiry close
 * (4401 at the access token's `exp`, so clients refresh and reconnect).
 */
export class ConnectionRegistry implements EventDispatcher {
  private readonly byUser = new Map<string, Set<Connection>>();
  private readonly pingIntervalMs: number;
  private readonly clock: Clock;

  constructor(deps: ConnectionRegistryDeps) {
    this.clock = deps.clock;
    this.pingIntervalMs = deps.pingIntervalMs ?? WS_PING_INTERVAL_MS;
  }

  /** Register an authenticated socket; `expiresAtMs` is the token's `exp`. */
  add(userId: string, socket: RealtimeSocket, opts: { expiresAtMs: number }): void {
    const connection: Connection = {
      socket,
      alive: true,
      heartbeat: setInterval(() => {
        if (socket.readyState !== READY_OPEN) {
          // Half-closed socket: prune without pinging (a ping frame on a
          // CLOSING/CLOSED socket is meaningless; its own close event does
          // the final teardown).
          this.remove(userId, connection);
          return;
        }
        if (!connection.alive) {
          // A full interval without a pong: the peer is gone, so cut the
          // TCP connection (a close frame would never be answered).
          this.remove(userId, connection);
          socket.terminate();
          return;
        }
        connection.alive = false;
        socket.ping();
      }, this.pingIntervalMs),
      expiry: setTimeout(
        () => {
          this.remove(userId, connection);
          socket.close(WS_CLOSE_TOKEN_EXPIRED, "access token expired");
        },
        // Node's setTimeout overflows above 2^31-1 ms and fires immediately;
        // clamp so a far-future exp can never close a live socket early.
        // Real access tokens expire within 900 seconds, so this only guards
        // against pathological tokens.
        Math.min(
          Math.max(0, opts.expiresAtMs - this.clock.nowMs()),
          2_147_483_647,
        ),
      ),
    };
    const markAlive = () => {
      connection.alive = true;
    };
    socket.on("pong", markAlive);
    // Native desktop clients also send their own control-frame heartbeat.
    // Counting a peer ping as activity avoids pruning clients whose platform
    // WebSocket stack does not surface an automatic pong while hidden.
    socket.on("ping", markAlive);
    socket.on("close", () => {
      this.remove(userId, connection);
    });
    socket.on("error", () => {
      this.remove(userId, connection);
    });
    let sockets = this.byUser.get(userId);
    if (sockets === undefined) {
      sockets = new Set();
      this.byUser.set(userId, sockets);
    }
    sockets.add(connection);
  }

  /** Number of registered sockets (all users, or one user). */
  count(userId?: string): number {
    if (userId !== undefined) {
      return this.byUser.get(userId)?.size ?? 0;
    }
    let total = 0;
    for (const sockets of this.byUser.values()) {
      total += sockets.size;
    }
    return total;
  }

  /**
   * Fan out one event to the user's open sockets. The payload is serialized
   * once; sends are scheduled with their callbacks and the promise resolves
   * immediately, never awaiting the TCP flush — ingress and dedupe stay
   * decoupled from slow readers. A socket whose buffered backlog exceeds
   * {@link WS_MAX_BUFFERED_BYTES} is terminated and pruned rather than
   * queued further; closed sockets, callback errors, and synchronous send
   * throws are pruned. The promise always resolves.
   */
  async dispatch(input: { userId: string; event: NotifyEvent }): Promise<void> {
    const sockets = this.byUser.get(input.userId);
    if (sockets === undefined) {
      return;
    }
    const payload = JSON.stringify({ type: "event", event: input.event });
    for (const connection of [...sockets]) {
      if (connection.socket.readyState !== READY_OPEN) {
        this.remove(input.userId, connection);
        continue;
      }
      if (connection.socket.bufferedAmount > WS_MAX_BUFFERED_BYTES) {
        // Hopelessly slow reader: cut the connection (a close frame would
        // itself sit behind the unflushed backlog) and drop it.
        this.remove(input.userId, connection);
        connection.socket.terminate();
        continue;
      }
      try {
        connection.socket.send(payload, (err?: Error | null) => {
          if (err != null) {
            this.remove(input.userId, connection);
          }
        });
      } catch {
        this.remove(input.userId, connection);
      }
    }
  }

  /** Graceful shutdown: close every socket (1012 by default) and clear all timers. */
  closeAll(code: number = WS_CLOSE_SERVER_SHUTDOWN, reason = "server shutting down"): void {
    for (const [userId, sockets] of this.byUser) {
      for (const connection of [...sockets]) {
        this.remove(userId, connection);
        connection.socket.close(code, reason);
      }
    }
  }

  private remove(userId: string, connection: Connection): void {
    const sockets = this.byUser.get(userId);
    if (sockets === undefined || !sockets.delete(connection)) {
      return; // already pruned
    }
    clearInterval(connection.heartbeat);
    clearTimeout(connection.expiry);
    if (sockets.size === 0) {
      this.byUser.delete(userId);
    }
  }
}
