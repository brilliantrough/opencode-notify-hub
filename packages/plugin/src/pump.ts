/**
 * Non-blocking delivery pump over the bounded priority queue.
 *
 * The plugin's event pipeline must never stall on the network: producers
 * call {@link QueuePump.enqueue} (or a bare {@link QueuePump.kick}) and get
 * control back synchronously, while at most one drain loop delivers queued
 * events one at a time through the {@link GatewaySender}. `kick()` starts
 * the loop only when none is running (`void this.drain().catch(...)`
 * style), so any number of kicks — or enqueues landing mid-drain — never
 * create a second concurrent sender.
 *
 * Loss policy: the queue is bounded; when it evicts or rejects, the pump
 * logs the loss. Heartbeat churn (evicted or rejected heartbeats) is
 * routine and logged at debug; losing a non-heartbeat event is an error.
 * A delivery that fails after the sender's own retries is logged once at
 * error and dropped — the loop moves on; later events are not hostages of
 * a dead gateway.
 *
 * Shutdown: {@link QueuePump.stop} prevents new work (later kicks are
 * no-ops, later enqueues are refused), then drains every event accepted
 * before shutdown. `drain()` never rejects, so no path can produce an
 * unhandled rejection.
 */

import type { NotifyEvent } from "@notify/contracts";

import {
  BoundedQueue,
  notifyEventPriority,
  type EnqueueResult,
} from "./queue.js";

/** Minimal log surface; payloads are never passed through it. */
export interface PumpLogger {
  debug(message: string, context?: Record<string, unknown>): void;
  error(message: string, context?: Record<string, unknown>): void;
}

/** The sender contract the pump depends on (`GatewaySender.send`). */
export interface PumpSender {
  send(event: NotifyEvent): Promise<void>;
}

export interface QueuePumpOptions {
  sender: PumpSender;
  /** Defaults to a silent logger. */
  logger?: PumpLogger;
  /** Queue capacity; defaults to the queue's own default (100). */
  capacity?: number;
}

const noopLogger: PumpLogger = {
  debug(): void {},
  error(): void {},
};

export class QueuePump {
  private readonly queue: BoundedQueue<NotifyEvent>;
  private readonly sender: PumpSender;
  private readonly logger: PumpLogger;
  private draining: Promise<void> | null = null;
  private stopped = false;
  private stopping: Promise<void> | null = null;

  constructor(options: QueuePumpOptions) {
    this.sender = options.sender;
    this.logger = options.logger ?? noopLogger;
    this.queue =
      options.capacity === undefined
        ? new BoundedQueue<NotifyEvent>(notifyEventPriority)
        : new BoundedQueue<NotifyEvent>(notifyEventPriority, options.capacity);
  }

  get size(): number {
    return this.queue.size;
  }

  /**
   * Offer an event to the queue and make sure a drain loop is running.
   * Returns the queue's verdict so callers can react to a rejection; any
   * eviction or rejection is logged here (heartbeat churn at debug,
   * anything else at error). After {@link stop} the event is refused.
   */
  enqueue(event: NotifyEvent): EnqueueResult<NotifyEvent> {
    if (this.stopped) {
      this.logger.debug(`notify pump stopped; dropping event ${event.eventId}`, {
        eventId: event.eventId,
        eventType: event.type,
      });
      return { accepted: false };
    }
    const result = this.queue.enqueue(event);
    if (result.evicted !== undefined) {
      this.logLoss("evicted", result.evicted);
    }
    if (!result.accepted) {
      this.logLoss("rejected", event);
    }
    this.kick();
    return result;
  }

  /**
   * Start the drain loop if none is running; returns synchronously without
   * awaiting any network work. Events enqueued while the loop runs are
   * picked up by that same loop.
   */
  kick(): void {
    if (this.stopped || this.draining !== null) {
      return;
    }
    const run = this.drain();
    this.draining = run;
    const settle = (): void => {
      if (this.draining === run) {
        this.draining = null;
        // An enqueue that landed between the last empty dequeue and this
        // settlement saw `draining` set and skipped its kick; re-drive it.
        if (!this.stopped && this.queue.size > 0) {
          this.kick();
        }
      }
    };
    // `drain` never rejects; the rejection arm is belt and braces against
    // an unhandled rejection if that invariant is ever broken.
    void run.then(settle, settle);
  }

  /**
   * Stop the pump: refuse new work and wait for every event accepted before
   * shutdown to finish delivery. Repeated calls share one stop operation.
   * Never rejects.
   */
  stop(): Promise<void> {
    if (this.stopping !== null) {
      return this.stopping;
    }
    this.stopped = true;
    const current = this.draining;
    this.stopping = (async () => {
      if (current !== null) {
        await current.then(
          () => undefined,
          () => undefined,
        );
      }
      // An enqueue can land after drain's final empty dequeue but before its
      // promise settles. New enqueues are now refused, so one final drain is
      // sufficient to close that race.
      if (this.queue.size > 0) {
        await this.drain().then(
          () => undefined,
          () => undefined,
        );
      }
    })();
    return this.stopping;
  }

  /**
   * Deliver queued events one at a time until the queue is empty. A failed
   * send is logged and dropped; the loop continues with the next event.
   * Stopping only closes admission, so already accepted events still drain.
   * Never throws.
   */
  private async drain(): Promise<void> {
    while (true) {
      let event: NotifyEvent | undefined;
      try {
        event = this.queue.dequeue();
      } catch {
        return; // a broken queue must not escape as an unhandled rejection
      }
      if (event === undefined) {
        return;
      }
      try {
        await this.sender.send(event);
      } catch (error) {
        const detail = error instanceof Error ? error.message : String(error);
        this.logger.error(`gateway delivery failed; dropping event ${event.eventId}: ${detail}`, {
          eventId: event.eventId,
          eventType: event.type,
        });
      }
    }
  }

  /** Heartbeat churn is routine (debug); any other loss is an error. */
  private logLoss(kind: "evicted" | "rejected", event: NotifyEvent): void {
    const message = `notify queue full; ${kind} event ${event.eventId}`;
    const context = { eventId: event.eventId, eventType: event.type };
    if (event.type === "heartbeat") {
      this.logger.debug(message, context);
    } else {
      this.logger.error(message, context);
    }
  }
}
