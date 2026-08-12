/**
 * Bounded priority queue for outgoing notification events.
 *
 * Priorities are fixed by the notification contract: heartbeat (0) is
 * disposable chatter, action_resolved (1) matters, and terminal /
 * action_required (2) must survive. Within a priority the queue is strict
 * FIFO, ordered by an increasing sequence number assigned at enqueue time.
 *
 * Eviction is deterministic when the queue is full:
 * - A new heartbeat may only replace the oldest heartbeat; if none is
 *   present it is rejected (`accepted: false`) and never evicts anything.
 * - Any other event evicts the oldest event at the lowest present priority,
 *   provided that priority is not higher than the newcomer's. A full queue
 *   of equal-or-higher priority events evicts its own oldest member of the
 *   lowest (i.e. equal) priority and returns it so the caller can log the
 *   loss as an error.
 *
 * The result of {@link BoundedQueue.enqueue} is explicit about acceptance
 * and eviction so callers cannot assume a heartbeat was enqueued.
 */

import type { NotifyEvent } from "@notify/contracts";

/** Priority levels: higher dequeues first. */
export type QueuePriority = 0 | 1 | 2;

/** Default capacity when the caller does not bound the queue explicitly. */
export const DEFAULT_QUEUE_CAPACITY = 100;

/** Outcome of one {@link BoundedQueue.enqueue} call. */
export interface EnqueueResult<T> {
  /** True when the item entered the queue (possibly by evicting another). */
  accepted: boolean;
  /** The item removed to make room, if any. */
  evicted?: T;
}

/**
 * Map a notification event to its queue priority: heartbeat 0,
 * action_resolved 1, terminal and action_required 2.
 */
export function notifyEventPriority(event: { type: NotifyEvent["type"] }): QueuePriority {
  switch (event.type) {
    case "heartbeat":
      return 0;
    case "action_resolved":
      return 1;
    case "action_required":
    case "terminal":
      return 2;
  }
}

interface Entry<T> {
  item: T;
  priority: QueuePriority;
  seq: number;
}

/**
 * A FIFO-within-priority queue with a hard capacity. All operations are
 * linear scans; the capacity is small (default 100) so this stays cheap and
 * the ordering rules stay obvious.
 */
export class BoundedQueue<T> {
  private readonly capacity: number;
  private readonly priorityOf: (item: T) => QueuePriority;
  private entries: Entry<T>[] = [];
  private nextSeq = 0;

  constructor(
    priorityOf: (item: T) => QueuePriority,
    capacity: number = DEFAULT_QUEUE_CAPACITY,
  ) {
    if (!Number.isInteger(capacity) || capacity <= 0) {
      throw new RangeError(`BoundedQueue capacity must be a positive integer, got ${capacity}`);
    }
    this.priorityOf = priorityOf;
    this.capacity = capacity;
  }

  get size(): number {
    return this.entries.length;
  }

  /**
   * Insert an item, evicting per the deterministic rules above when full.
   * The returned result always states whether the item was accepted and
   * which item (if any) was evicted to make room.
   */
  enqueue(item: T): EnqueueResult<T> {
    const priority = this.priorityOf(item);
    if (this.entries.length < this.capacity) {
      this.push(item, priority);
      return { accepted: true };
    }

    const victimIndex = this.evictionIndex(priority);
    if (victimIndex === -1) {
      return { accepted: false };
    }
    const [victim] = this.entries.splice(victimIndex, 1);
    this.push(item, priority);
    return { accepted: true, evicted: victim.item };
  }

  /** Remove and return the highest-priority, oldest item; undefined when empty. */
  dequeue(): T | undefined {
    if (this.entries.length === 0) {
      return undefined;
    }
    let best = 0;
    for (let i = 1; i < this.entries.length; i += 1) {
      if (this.entries[i].priority > this.entries[best].priority) {
        best = i;
      }
    }
    const [entry] = this.entries.splice(best, 1);
    return entry.item;
  }

  private push(item: T, priority: QueuePriority): void {
    this.entries.push({ item, priority, seq: this.nextSeq });
    this.nextSeq += 1;
  }

  /**
   * Index of the entry a full queue must sacrifice for a newcomer of the
   * given priority, or -1 when the newcomer is rejected:
   * - heartbeat (0): the oldest heartbeat, or -1 when none is present;
   * - otherwise: the oldest entry at the lowest present priority, or -1
   *   when even that lowest priority outranks the newcomer.
   */
  private evictionIndex(priority: QueuePriority): number {
    let lowestIndex = -1;
    for (let i = 0; i < this.entries.length; i += 1) {
      const entry = this.entries[i];
      if (priority === 0 && entry.priority !== 0) {
        continue;
      }
      if (lowestIndex === -1 || entry.priority < this.entries[lowestIndex].priority) {
        lowestIndex = i;
      }
    }
    if (lowestIndex === -1) {
      return -1;
    }
    // Iteration order is sequence order for equal priorities, so the first
    // entry found at the lowest priority is also the oldest one.
    return this.entries[lowestIndex].priority <= priority ? lowestIndex : -1;
  }
}
