import { describe, expect, it } from "vitest";
import type { NotifyEvent } from "@notify/contracts";

import {
  BoundedQueue,
  DEFAULT_QUEUE_CAPACITY,
  notifyEventPriority,
} from "../src/queue.js";

type EventType = NotifyEvent["type"];

/** Minimal event stand-in: the queue only ever reads `type`. */
interface TestEvent {
  id: string;
  type: EventType;
}

function event(id: string, type: EventType): TestEvent {
  return { id, type };
}

function heartbeat(id: string): TestEvent {
  return event(id, "heartbeat");
}

function resolved(id: string): TestEvent {
  return event(id, "action_resolved");
}

function required(id: string): TestEvent {
  return event(id, "action_required");
}

function terminal(id: string): TestEvent {
  return event(id, "terminal");
}

function makeQueue(capacity?: number): BoundedQueue<TestEvent> {
  return capacity === undefined
    ? new BoundedQueue<TestEvent>(notifyEventPriority)
    : new BoundedQueue<TestEvent>(notifyEventPriority, capacity);
}

/** Drain the queue into an id list, in dequeue order. */
function drain(queue: BoundedQueue<TestEvent>): string[] {
  const ids: string[] = [];
  for (let item = queue.dequeue(); item !== undefined; item = queue.dequeue()) {
    ids.push(item.id);
  }
  return ids;
}

describe("notifyEventPriority", () => {
  it("maps heartbeat to 0, action_resolved to 1, and terminal/action_required to 2", () => {
    expect(notifyEventPriority(heartbeat("h"))).toBe(0);
    expect(notifyEventPriority(resolved("r"))).toBe(1);
    expect(notifyEventPriority(required("a"))).toBe(2);
    expect(notifyEventPriority(terminal("t"))).toBe(2);
  });
});

describe("BoundedQueue — construction", () => {
  it("rejects a non-positive or non-integer capacity", () => {
    expect(() => makeQueue(0)).toThrow(RangeError);
    expect(() => makeQueue(-1)).toThrow(RangeError);
    expect(() => makeQueue(1.5)).toThrow(RangeError);
    expect(() => makeQueue(Number.NaN)).toThrow(RangeError);
  });

  it("defaults to a capacity of 100", () => {
    expect(DEFAULT_QUEUE_CAPACITY).toBe(100);
    const queue = makeQueue();
    for (let i = 0; i < 100; i += 1) {
      expect(queue.enqueue(terminal(`t${i}`)).accepted).toBe(true);
    }
    expect(queue.size).toBe(100);
  });
});

describe("BoundedQueue — dequeue order", () => {
  it("returns undefined when empty", () => {
    expect(makeQueue(3).dequeue()).toBeUndefined();
  });

  it("dequeues the highest priority event first", () => {
    const queue = makeQueue(3);
    queue.enqueue(heartbeat("h"));
    queue.enqueue(terminal("t"));
    queue.enqueue(resolved("r"));

    expect(drain(queue)).toEqual(["t", "r", "h"]);
  });

  it("preserves FIFO order within a priority", () => {
    const queue = makeQueue(4);
    queue.enqueue(terminal("t1"));
    queue.enqueue(heartbeat("h1"));
    queue.enqueue(terminal("t2"));
    queue.enqueue(heartbeat("h2"));

    expect(drain(queue)).toEqual(["t1", "t2", "h1", "h2"]);
  });

  it("treats terminal and action_required as one priority level", () => {
    const queue = makeQueue(3);
    queue.enqueue(required("a1"));
    queue.enqueue(terminal("t1"));
    queue.enqueue(required("a2"));

    expect(drain(queue)).toEqual(["a1", "t1", "a2"]);
  });

  it("keeps duplicate object instances as separate entries", () => {
    const queue = makeQueue(3);
    const shared = terminal("shared");
    queue.enqueue(shared);
    queue.enqueue(shared);

    expect(queue.size).toBe(2);
    expect(queue.dequeue()).toBe(shared);
    expect(queue.dequeue()).toBe(shared);
    expect(queue.dequeue()).toBeUndefined();
  });
});

describe("BoundedQueue — eviction at capacity", () => {
  it("lets a heartbeat replace the oldest heartbeat only", () => {
    const queue = makeQueue(3);
    queue.enqueue(heartbeat("h1"));
    queue.enqueue(heartbeat("h2"));
    queue.enqueue(terminal("t1"));

    const result = queue.enqueue(heartbeat("h3"));

    expect(result).toEqual({ accepted: true, evicted: heartbeat("h1") });
    expect(drain(queue)).toEqual(["t1", "h2", "h3"]);
  });

  it("rejects a heartbeat when no heartbeat slot can be reclaimed", () => {
    const queue = makeQueue(3);
    queue.enqueue(resolved("r1"));
    queue.enqueue(terminal("t1"));
    queue.enqueue(required("a1"));

    const result = queue.enqueue(heartbeat("h-new"));

    expect(result).toEqual({ accepted: false });
    expect(result.evicted).toBeUndefined();
    expect(drain(queue)).toEqual(["t1", "a1", "r1"]);
  });

  it("lets a terminal event evict the oldest heartbeat", () => {
    const queue = makeQueue(3);
    queue.enqueue(heartbeat("h1"));
    queue.enqueue(heartbeat("h2"));
    queue.enqueue(resolved("r1"));

    const result = queue.enqueue(terminal("t1"));

    expect(result).toEqual({ accepted: true, evicted: heartbeat("h1") });
    expect(drain(queue)).toEqual(["t1", "r1", "h2"]);
  });

  it("lets an action_resolved event evict a heartbeat", () => {
    const queue = makeQueue(3);
    queue.enqueue(heartbeat("h1"));
    queue.enqueue(heartbeat("h2"));
    queue.enqueue(heartbeat("h3"));

    const result = queue.enqueue(resolved("r1"));

    expect(result).toEqual({ accepted: true, evicted: heartbeat("h1") });
    expect(drain(queue)).toEqual(["r1", "h2", "h3"]);
  });

  it("evicts the oldest event from the lowest present priority", () => {
    const queue = makeQueue(3);
    queue.enqueue(terminal("t1"));
    queue.enqueue(resolved("r1"));
    queue.enqueue(resolved("r2"));

    const result = queue.enqueue(terminal("t2"));

    expect(result).toEqual({ accepted: true, evicted: resolved("r1") });
    expect(drain(queue)).toEqual(["t1", "t2", "r2"]);
  });

  it("evicts the oldest high-priority event from a full high-priority queue and returns it for error logging", () => {
    const queue = makeQueue(3);
    queue.enqueue(terminal("t1"));
    queue.enqueue(terminal("t2"));
    queue.enqueue(terminal("t3"));

    const result = queue.enqueue(terminal("t4"));

    expect(result.accepted).toBe(true);
    expect(result.evicted).toEqual(terminal("t1"));
    expect(drain(queue)).toEqual(["t2", "t3", "t4"]);
  });

  it("never lets a lower-priority event evict a higher-priority one", () => {
    const queue = makeQueue(3);
    queue.enqueue(terminal("t1"));
    queue.enqueue(terminal("t2"));
    queue.enqueue(required("a1"));

    const result = queue.enqueue(resolved("r1"));

    expect(result).toEqual({ accepted: false });
    expect(drain(queue)).toEqual(["t1", "t2", "a1"]);
  });
});

describe("BoundedQueue — capacity boundaries", () => {
  it("at capacity 1 a terminal event replaces a heartbeat", () => {
    const queue = makeQueue(1);
    queue.enqueue(heartbeat("h1"));

    const result = queue.enqueue(terminal("t1"));

    expect(result).toEqual({ accepted: true, evicted: heartbeat("h1") });
    expect(queue.dequeue()).toEqual(terminal("t1"));
    expect(queue.dequeue()).toBeUndefined();
  });

  it("at capacity 1 a heartbeat cannot evict a terminal event", () => {
    const queue = makeQueue(1);
    queue.enqueue(terminal("t1"));

    const result = queue.enqueue(heartbeat("h1"));

    expect(result).toEqual({ accepted: false });
    expect(queue.dequeue()).toEqual(terminal("t1"));
  });

  it("at capacity 3 a heartbeat replaces the oldest heartbeat among mixed priorities", () => {
    const queue = makeQueue(3);
    queue.enqueue(required("a1"));
    queue.enqueue(heartbeat("h1"));
    queue.enqueue(resolved("r1"));

    const result = queue.enqueue(heartbeat("h2"));

    expect(result).toEqual({ accepted: true, evicted: heartbeat("h1") });
    expect(drain(queue)).toEqual(["a1", "r1", "h2"]);
  });
});
