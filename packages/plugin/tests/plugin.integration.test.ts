import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import type { Hooks, PluginInput } from "@opencode-ai/plugin";
import type { NotifyEvent } from "@notify/contracts";
import { validateNotifyEvent } from "@notify/contracts";

import { loadConfig } from "../src/config.js";
import SessionNotifyPlugin, { createSessionNotifyHooks } from "../src/index.js";
import type { PluginControl } from "../src/control-channel.js";
import { createSafeLogger, type LogEntry } from "../src/log.js";
import {
  devQuestionAsked,
  devQuestionReplied,
  makeAssistantMessage,
  makeTextPart,
  makeUserMessage,
  messagePartUpdated,
  messageUpdated,
  permissionRepliedV1,
  permissionUpdated,
  sessionCreated,
  sessionError,
  sessionIdle,
  sessionStatus,
} from "./helpers.js";

/**
 * End-to-end wiring tests for the never-throw plugin entrypoint.
 *
 * The plugin is instantiated through its public seam — the default-exported
 * OpenCode `Plugin` — with a fake OpenCode client (`client.session.get` /
 * `client.app.log`) and a stubbed global `fetch`. No real network happens:
 * every delivery is captured by the recording fetch. Wall-clock time and
 * timers run on vitest fake timers pinned at FIXED_NOW.
 */

const GATEWAY_URL = "https://gateway.example.com";
const KEY_ID = "kidTEST123";
const SECRET = "secTEST456";
const FIXED_NOW = new Date("2026-02-01T12:00:00.000Z");
const SESSION_ID = "ses_abc123";

interface LogBody {
  service: string;
  level: "debug" | "info" | "warn" | "error";
  message: string;
  extra?: Record<string, unknown>;
}

interface FakeClient {
  client: {
    app: { log: (options: { body: LogBody }) => unknown };
    global: { health: () => Promise<{ data: { version: string } }> };
    session: { get: (options: { path: { id: string } }) => Promise<unknown> };
  };
  logBodies: LogBody[];
  getCalls: string[];
}

interface FakeClientOptions {
  getImpl?: (sessionID: string) => Promise<unknown>;
  logImpl?: (options: { body: LogBody }) => unknown;
}

function makeClient(options: FakeClientOptions = {}): FakeClient {
  const logBodies: LogBody[] = [];
  const getCalls: string[] = [];
  return {
    logBodies,
    getCalls,
    client: {
      app: {
        log: (logOptions: { body: LogBody }) => {
          logBodies.push(logOptions.body);
          if (options.logImpl !== undefined) {
            return options.logImpl(logOptions);
          }
          return Promise.resolve({ data: true });
        },
      },
      global: {
        health: async () => ({ data: { version: "1.18.18" } }),
      },
      session: {
        get: ({ path }: { path: { id: string } }) => {
          getCalls.push(path.id);
          if (options.getImpl !== undefined) {
            return options.getImpl(path.id);
          }
          return Promise.resolve({ data: { id: path.id, parentID: null } });
        },
      },
    },
  };
}

function makeInput(client: FakeClient["client"]): PluginInput {
  return {
    client,
    project: { id: "prj_1", worktree: "/home/dev/project", time: { created: 1_700_000_000_000 } },
    directory: "/home/dev/project",
    worktree: "/home/dev/project",
    serverUrl: new URL("http://127.0.0.1:4096"),
    experimental_workspace: { register: () => undefined },
    $: {} as PluginInput["$"],
  } as unknown as PluginInput;
}

interface FetchCall {
  url: string;
  body: string;
  headers: Record<string, string>;
}

function makeRecordingFetch(): { calls: FetchCall[]; fetchImpl: typeof fetch } {
  const calls: FetchCall[] = [];
  const fetchImpl = (async (url: unknown, init?: { headers?: unknown; body?: unknown }) => {
    calls.push({
      url: String(url),
      body: String(init?.body),
      headers: init?.headers as Record<string, string>,
    });
    return new Response("true", { status: 202 });
  }) as unknown as typeof fetch;
  return { calls, fetchImpl };
}

/** A fetch whose responses hang until `release`; afterwards it answers immediately. */
function makeHangingFetch(): {
  calls: FetchCall[];
  fetchImpl: typeof fetch;
  release: () => void;
} {  const calls: FetchCall[] = [];
  let released = false;
  const pending: Array<(response: Response) => void> = [];
  const fetchImpl = ((url: unknown, init?: { headers?: unknown; body?: unknown }) => {
    calls.push({
      url: String(url),
      body: String(init?.body),
      headers: init?.headers as Record<string, string>,
    });
    if (released) {
      return Promise.resolve(new Response("true", { status: 202 }));
    }
    return new Promise<Response>((resolve) => {
      pending.push(resolve);
    });
  }) as unknown as typeof fetch;
  return {
    calls,
    fetchImpl,
    release: () => {
      released = true;
      for (const respond of pending.splice(0)) {
        respond(new Response("true", { status: 202 }));
      }
    },
  };
}

function postedEvents(calls: FetchCall[]): NotifyEvent[] {
  return calls.map((call) => JSON.parse(call.body) as NotifyEvent);
}

function stubBaseEnv(extra: Record<string, string> = {}): void {
  vi.stubEnv("NOTIFY_GATEWAY_URL", GATEWAY_URL);
  vi.stubEnv("NOTIFY_INGEST_KEY", `${KEY_ID}.${SECRET}`);
  vi.stubEnv("NOTIFY_MACHINE", "test-machine");
  for (const [name, value] of Object.entries(extra)) {
    vi.stubEnv(name, value);
  }
}

async function emit(hooks: Hooks, event: unknown): Promise<void> {
  await hooks.event?.({ event: event as never });
}

/** Flush pending microtasks (normalization, lookup, envelope, drain). */
async function settle(times = 20): Promise<void> {
  for (let i = 0; i < times; i += 1) {
    await Promise.resolve();
  }
}

/** Capturing control socket so the deferred-startup test can drive frames. */
class CapturingSocket {
  readonly sent: string[] = [];
  private readonly listeners = new Map<string, Set<(event?: unknown) => void>>();

  addEventListener(event: string, listener: (event?: unknown) => void): void {
    const listeners = this.listeners.get(event) ?? new Set();
    listeners.add(listener);
    this.listeners.set(event, listeners);
  }

  send(data: string): void {
    this.sent.push(data);
  }

  close(): void {
    this.closed = true;
  }

  closed = false;

  emit(event: string, value?: unknown): void {
    for (const listener of this.listeners.get(event) ?? []) {
      listener(value);
    }
  }
}

describe("SessionNotifyPlugin", () => {
  beforeEach(() => {
    vi.useFakeTimers({ now: FIXED_NOW });
    stubBaseEnv();
    vi.stubGlobal(
      "WebSocket",
      class {
        addEventListener(): void {}
        send(): void {}
        close(): void {}
      },
    );
  });

  afterEach(() => {
    vi.useRealTimers();
    vi.unstubAllEnvs();
    vi.unstubAllGlobals();
  });

  it("returns empty hooks and a secret-free warning when the configuration is invalid", async () => {
    vi.stubEnv("NOTIFY_GATEWAY_URL", "");
    const { client, logBodies } = makeClient();

    const hooks = await SessionNotifyPlugin(makeInput(client));

    expect(hooks).toEqual({});
    expect(logBodies).toHaveLength(1);
    expect(logBodies[0].level).toBe("warn");
    expect(logBodies[0].service).toBe("opencode-notify");
    // The warning must not echo any environment value, above all the key.
    expect(JSON.stringify(logBodies)).not.toContain(SECRET);
    expect(JSON.stringify(logBodies)).not.toContain(KEY_ID);
  });

  it("starts control after hook construction and stops it during dispose", async () => {
    const config = loadConfig({
      NOTIFY_GATEWAY_URL: GATEWAY_URL,
      NOTIFY_INGEST_KEY: `${KEY_ID}.${SECRET}`,
      NOTIFY_MACHINE: "test-machine",
    });
    expect(config).not.toBeNull();
    const starts: string[] = [];
    const control: PluginControl = {
      start: () => {
        starts.push("start");
      },
      stop: () => {
        starts.push("stop");
      },
    };
    const { client } = makeClient();

    const hooks = createSessionNotifyHooks(makeInput(client), config!, {
      control,
      pump: { enqueue: () => undefined, stop: async () => undefined },
    });
    expect(starts).toEqual([]);
    await vi.advanceTimersByTimeAsync(0);
    expect(starts).toEqual(["start"]);

    await hooks.dispose?.();
    expect(starts).toEqual(["start", "stop"]);
  });

  it("ignores events for a child session without any SDK lookup", async () => {
    const { calls, fetchImpl } = makeRecordingFetch();
    vi.stubGlobal("fetch", fetchImpl);
    const { client, getCalls } = makeClient();
    const hooks = await SessionNotifyPlugin(makeInput(client));

    await emit(hooks, sessionCreated({ id: "ses_child", parentID: "ses_main", title: "Child" }));
    await emit(hooks, devQuestionAsked({ sessionID: "ses_child" }));
    await settle();

    expect(calls).toHaveLength(0);
    expect(getCalls).toHaveLength(0);
  });

  it("resolves a cache-miss main session through one SDK lookup and caches it", async () => {
    const { calls, fetchImpl } = makeRecordingFetch();
    vi.stubGlobal("fetch", fetchImpl);
    const { client, getCalls } = makeClient();
    const hooks = await SessionNotifyPlugin(makeInput(client));

    await emit(hooks, devQuestionAsked());
    await settle();

    expect(getCalls).toEqual([SESSION_ID]);
    let posted = postedEvents(calls);
    expect(posted.map((event) => event.type)).toEqual(["action_required"]);
    expect(posted[0].payload).toMatchObject({ requestId: "qst_req1", kind: "question" });
    // Internal session ids never become user-facing fallback titles.
    expect(posted[0].session).toEqual({ id: SESSION_ID, title: "未命名会话" });

    await emit(hooks, devQuestionReplied());
    await settle();

    expect(getCalls).toEqual([SESSION_ID]); // cached: no second lookup
    posted = postedEvents(calls);
    expect(posted.map((event) => event.type)).toEqual(["action_required", "action_resolved"]);
    expect(posted[1].payload).toEqual({ requestId: "qst_req1", kind: "question" });
  });

  it("drops the event with a session-id-only warning when ancestry lookup fails", async () => {
    const { calls, fetchImpl } = makeRecordingFetch();
    vi.stubGlobal("fetch", fetchImpl);
    const { client, logBodies, getCalls } = makeClient({
      getImpl: () => Promise.reject(new Error("sdk unreachable")),
    });
    const hooks = await SessionNotifyPlugin(makeInput(client));

    await emit(hooks, devQuestionAsked());
    await settle();

    expect(calls).toHaveLength(0);
    const warnings = logBodies.filter((body) => body.level === "warn");
    expect(warnings).toHaveLength(1);
    expect(warnings[0].extra).toEqual({ sessionID: SESSION_ID });
    // Only the session id: no request id, question text, or error payload.
    expect(JSON.stringify(logBodies)).not.toContain("qst_req1");
    expect(JSON.stringify(logBodies)).not.toContain("database");

    // Unknown ancestry is not cached: the next event retries the lookup.
    await emit(hooks, devQuestionReplied());
    await settle();
    expect(getCalls).toHaveLength(2);
    expect(calls).toHaveLength(0);
  });

  it("posts a heartbeat after 60 seconds busy, then keeps beating", async () => {
    const { calls, fetchImpl } = makeRecordingFetch();
    vi.stubGlobal("fetch", fetchImpl);
    const { client } = makeClient();
    const hooks = await SessionNotifyPlugin(makeInput(client));

    await emit(hooks, sessionCreated());
    await emit(hooks, sessionStatus({ type: "busy" }));
    await settle();
    expect(calls).toHaveLength(0);

    await vi.advanceTimersByTimeAsync(60_000);
    await settle();

    let posted = postedEvents(calls);
    expect(posted).toHaveLength(1);
    expect(calls[0].url).toBe(`${GATEWAY_URL}/v1/events`);
    expect(calls[0].headers.Authorization).toBe(`Bearer ${KEY_ID}.${SECRET}`);
    expect(calls[0].headers["X-Notify-Signature"]).toMatch(/^[0-9a-f]{64}$/);
    expect(calls[0].headers["X-Notify-Timestamp"]).toMatch(/^\d+$/);
    expect(posted[0].type).toBe("heartbeat");
    expect(posted[0].payload).toEqual({ status: "busy", elapsedSeconds: 60 });
    expect(posted[0].source).toEqual({
      machine: "test-machine",
      project: "project",
      directory: "/home/dev/project",
    });
    expect(posted[0].session).toEqual({ id: SESSION_ID, title: "Fix login redirect" });

    await vi.advanceTimersByTimeAsync(60_000);
    await settle();
    posted = postedEvents(calls);
    expect(posted).toHaveLength(2);
    expect(posted[1].payload).toEqual({ status: "busy", elapsedSeconds: 120 });
  });

  it("derives a readable project label from a Windows worktree", async () => {
    const { calls, fetchImpl } = makeRecordingFetch();
    vi.stubGlobal("fetch", fetchImpl);
    const { client } = makeClient();
    const input = makeInput(client);
    input.project.worktree = String.raw`C:\work\opencode-notify`;
    input.worktree = String.raw`C:\work\opencode-notify`;
    input.directory = String.raw`C:\work\opencode-notify`;
    const hooks = await SessionNotifyPlugin(input);

    await emit(hooks, sessionCreated());
    await emit(hooks, devQuestionAsked());
    await settle();

    expect(postedEvents(calls)[0].source.project).toBe("opencode-notify");
  });

  it("reports retry status on the heartbeat", async () => {
    const { calls, fetchImpl } = makeRecordingFetch();
    vi.stubGlobal("fetch", fetchImpl);
    const { client } = makeClient();
    const hooks = await SessionNotifyPlugin(makeInput(client));

    await emit(hooks, sessionCreated());
    await emit(
      hooks,
      sessionStatus({ type: "retry", attempt: 2, message: "rate limited", next: 1_700_000_010_000 }),
    );
    await vi.advanceTimersByTimeAsync(60_000);
    await settle();

    const posted = postedEvents(calls);
    expect(posted).toHaveLength(1);
    expect(posted[0].payload).toEqual({ status: "retry", elapsedSeconds: 60 });
  });

  it("emits exactly one completion across the dual idle event forms", async () => {
    const { calls, fetchImpl } = makeRecordingFetch();
    vi.stubGlobal("fetch", fetchImpl);
    const { client } = makeClient();
    const hooks = await SessionNotifyPlugin(makeInput(client));

    await emit(hooks, sessionCreated());
    await emit(hooks, sessionStatus({ type: "busy" }));
    await vi.advanceTimersByTimeAsync(5_000);

    await emit(hooks, sessionIdle());
    await emit(hooks, sessionStatus({ type: "idle" }));
    await settle();
    expect(calls).toHaveLength(0);

    await vi.advanceTimersByTimeAsync(14_999);
    await settle();
    expect(calls).toHaveLength(0);

    await vi.advanceTimersByTimeAsync(1);
    await settle();
    const posted = postedEvents(calls);
    expect(posted).toHaveLength(1);
    expect(posted[0].type).toBe("terminal");
    expect(posted[0].payload).toEqual({ outcome: "completed", elapsedSeconds: 5 });
  });

  it("emits an immediate stopped terminal for an abort-classified session error", async () => {
    const { calls, fetchImpl } = makeRecordingFetch();
    vi.stubGlobal("fetch", fetchImpl);
    const { client } = makeClient();
    const hooks = await SessionNotifyPlugin(makeInput(client));

    await emit(hooks, sessionCreated());
    await emit(hooks, sessionStatus({ type: "busy" }));
    await vi.advanceTimersByTimeAsync(3_000);
    await emit(hooks, sessionError({ name: "MessageAbortedError", data: {} }));
    await settle();

    const posted = postedEvents(calls);
    expect(posted).toHaveLength(1);
    expect(posted[0].payload).toEqual({ outcome: "stopped", elapsedSeconds: 3 });

    // No heartbeat, no later completion for the terminated round.
    await vi.advanceTimersByTimeAsync(120_000);
    await settle();
    expect(postedEvents(calls)).toHaveLength(1);
  });

  it("emits an immediate failed terminal without leaking error payload text", async () => {
    const { calls, fetchImpl } = makeRecordingFetch();
    vi.stubGlobal("fetch", fetchImpl);
    const { client } = makeClient();
    const hooks = await SessionNotifyPlugin(makeInput(client));

    await emit(hooks, sessionCreated());
    await emit(hooks, sessionStatus({ type: "busy" }));
    await vi.advanceTimersByTimeAsync(2_000);
    await emit(hooks, sessionError({ name: "ProviderError", data: { message: "boom sk-live-x9" } }));
    await settle();

    const posted = postedEvents(calls);
    expect(posted).toHaveLength(1);
    expect(posted[0].payload).toEqual({ outcome: "failed", elapsedSeconds: 2 });
    expect(calls[0].body).not.toContain("sk-live-x9");
  });

  it("routes permission ask and reply to action_required and action_resolved", async () => {
    const { calls, fetchImpl } = makeRecordingFetch();
    vi.stubGlobal("fetch", fetchImpl);
    const { client } = makeClient();
    const hooks = await SessionNotifyPlugin(makeInput(client));

    await emit(hooks, sessionCreated());
    await emit(hooks, permissionUpdated());
    await settle();

    let posted = postedEvents(calls);
    expect(posted).toHaveLength(1);
    expect(posted[0].type).toBe("action_required");
    expect(posted[0].payload).toEqual({
      requestId: "per_req1",
      kind: "permission",
      permission: { permission: "bash", summary: "bash: pnpm test, git status" },
    });
    // Permission metadata and upstream title never leave the process.
    expect(calls[0].body).not.toContain("sk-live-SECRET-123");

    await emit(hooks, permissionRepliedV1());
    await settle();
    posted = postedEvents(calls);
    expect(posted).toHaveLength(2);
    expect(posted[1].type).toBe("action_resolved");
    expect(posted[1].payload).toEqual({ requestId: "per_req1", kind: "permission" });
  });

  it("emits a provider_action action_required immediately for a retry carrying an action", async () => {
    const { calls, fetchImpl } = makeRecordingFetch();
    vi.stubGlobal("fetch", fetchImpl);
    const config = loadConfig();
    expect(config).not.toBeNull();
    const { client } = makeClient();
    const hooks = createSessionNotifyHooks(makeInput(client), config!);

    await emit(hooks, sessionCreated());
    await emit(hooks, {
      type: "session.status",
      properties: {
        sessionID: SESSION_ID,
        status: {
          type: "retry",
          attempt: 2,
          message: "rate limited",
          next: 1_700_000_010_000,
          action: {
            provider: "anthropic",
            title: "Re-authenticate",
            message: "OAuth token expired",
            label: "Open login",
            link: "https://example.com/login",
          },
        },
      },
    });
    await settle();

    // Immediate: no debounce, no timer advance, one send already attempted.
    const posted = postedEvents(calls);
    expect(posted).toHaveLength(1);
    expect(validateNotifyEvent(posted[0])).toBe(true);
    expect(posted[0].type).toBe("action_required");
    expect(posted[0].session).toEqual({ id: SESSION_ID, title: "Fix login redirect" });
    expect(posted[0].payload).toEqual({
      // sha256 hex of '["ses_abc123","anthropic","Re-authenticate","Open
      // login"]' — the pinned literal from the state-machine tests.
      requestId: "provider:d1008f9c2f698b8810721133eccfb31593e5dc884e05fea1800c9d01373bff6c",
      kind: "provider_action",
      providerAction: {
        provider: "anthropic",
        title: "Re-authenticate",
        message: "OAuth token expired",
        label: "Open login",
        link: "https://example.com/login",
      },
    });

    await hooks.dispose?.();
  });

  it("resolves malformed and hostile events without rejecting the hook", async () => {
    const { calls, fetchImpl } = makeRecordingFetch();
    vi.stubGlobal("fetch", fetchImpl);
    const { client } = makeClient();
    const hooks = await SessionNotifyPlugin(makeInput(client));

    const hostile = Object.defineProperty({}, "type", {
      get: () => {
        throw new Error("hostile getter");
      },
    });
    const garbage: unknown[] = [
      null,
      undefined,
      42,
      "session.status",
      [],
      {},
      { type: 7 },
      { type: "session.status" },
      { type: "session.status", properties: null },
      { type: "session.status", properties: { sessionID: 1, status: { type: "busy" } } },
      { type: "todo.updated", properties: {} },
      hostile,
    ];
    for (const event of garbage) {
      await expect(hooks.event?.({ event: event as never })).resolves.toBeUndefined();
    }
    await settle();
    expect(calls).toHaveLength(0);
  });

  it("never delays hook resolution on a pending delivery", async () => {
    const { calls, fetchImpl, release } = makeHangingFetch();
    vi.stubGlobal("fetch", fetchImpl);
    const { client } = makeClient();
    const hooks = await SessionNotifyPlugin(makeInput(client));

    await emit(hooks, sessionCreated());
    await emit(hooks, sessionStatus({ type: "busy" }));
    await vi.advanceTimersByTimeAsync(60_000);
    await settle();
    // The heartbeat delivery is in flight and hanging.
    expect(calls).toHaveLength(1);

    // The hook keeps resolving while the send is pending.
    await expect(emit(hooks, sessionStatus({ type: "busy" }))).resolves.toBeUndefined();
    await expect(emit(hooks, sessionError())).resolves.toBeUndefined();
    await settle();
    expect(calls).toHaveLength(1); // terminal queued behind the hung send

    release();
    await settle();
    const posted = postedEvents(calls);
    expect(posted.map((event) => event.type)).toEqual(["heartbeat", "terminal"]);
    expect(posted[1].payload).toMatchObject({ outcome: "failed" });

    await hooks.dispose?.();
  });

  it("summarizes assistant text only and clears it after the terminal", async () => {
    stubBaseEnv({ NOTIFY_INCLUDE_SUMMARY: "true" });
    const { calls, fetchImpl } = makeRecordingFetch();
    vi.stubGlobal("fetch", fetchImpl);
    const { client } = makeClient();
    const hooks = await SessionNotifyPlugin(makeInput(client));

    await emit(hooks, sessionCreated());
    await emit(hooks, sessionStatus({ type: "busy" }));
    await emit(hooks, messageUpdated(makeUserMessage({ id: "msg_u1" })));
    await emit(
      hooks,
      messagePartUpdated(makeTextPart({ id: "prt_u1", messageID: "msg_u1", text: "USER PROMPT SECRET panda" })),
    );
    await emit(hooks, messageUpdated(makeAssistantMessage({ id: "msg_a1" })));
    await emit(
      hooks,
      messagePartUpdated(
        makeTextPart({ id: "prt_a1", messageID: "msg_a1", text: "Fixed the auth middleware redirect." }),
      ),
    );
    await emit(hooks, sessionIdle());
    await vi.advanceTimersByTimeAsync(15_000);
    await settle();

    let posted = postedEvents(calls);
    expect(posted).toHaveLength(1);
    expect(posted[0].payload).toMatchObject({
      outcome: "completed",
      summary: "Fixed the auth middleware redirect.",
    });
    expect(JSON.stringify(calls.map((call) => call.body))).not.toContain("USER PROMPT SECRET panda");

    // The next round completes without a summary: the cache was cleared.
    await emit(hooks, sessionStatus({ type: "busy" }));
    await emit(hooks, sessionIdle());
    await vi.advanceTimersByTimeAsync(15_000);
    await settle();
    posted = postedEvents(calls);
    expect(posted).toHaveLength(2);
    expect(posted[1].payload).toMatchObject({ outcome: "completed" });
    expect(posted[1].payload).not.toHaveProperty("summary");
  });

  it("keeps working when the log sink throws synchronously or rejects", async () => {
    const { calls, fetchImpl } = makeRecordingFetch();
    vi.stubGlobal("fetch", fetchImpl);
    let logCalls = 0;
    const { client } = makeClient({
      getImpl: () => Promise.reject(new Error("sdk unreachable")),
      logImpl: () => {
        logCalls += 1;
        if (logCalls === 1) {
          throw new Error("log sink down");
        }
        return Promise.reject(new Error("log sink down"));
      },
    });
    const hooks = await SessionNotifyPlugin(makeInput(client));

    // First event: warn logging throws synchronously — absorbed.
    await expect(emit(hooks, devQuestionAsked())).resolves.toBeUndefined();
    // Second event: warn logging rejects — absorbed.
    await expect(emit(hooks, devQuestionReplied())).resolves.toBeUndefined();
    await settle();
    expect(logCalls).toBe(2);
    expect(calls).toHaveLength(0);

    // Delivery still works with a broken logger.
    await emit(hooks, sessionCreated());
    await emit(hooks, sessionStatus({ type: "busy" }));
    await vi.advanceTimersByTimeAsync(60_000);
    await settle();
    expect(postedEvents(calls).map((event) => event.type)).toEqual(["heartbeat"]);
  });

  it("absorbs a throwing queue and reports it through the safe logger", async () => {
    const config = loadConfig();
    expect(config).not.toBeNull();
    const entries: LogEntry[] = [];
    const logger = createSafeLogger({
      sink: (entry) => {
        entries.push(entry);
      },
    });
    const throwingPump = {
      enqueue: () => {
        throw new Error("queue exploded");
      },
      stop: () => Promise.resolve(),
    };
    const { client } = makeClient();
    const hooks = createSessionNotifyHooks(makeInput(client), config!, {
      logger,
      pump: throwingPump,
    });

    await emit(hooks, sessionCreated());
    await emit(hooks, sessionStatus({ type: "busy" }));
    await vi.advanceTimersByTimeAsync(60_000);
    await settle();

    const errors = entries.filter((entry) => entry.level === "error");
    expect(errors.length).toBeGreaterThan(0);
    await expect(hooks.dispose?.()).resolves.toBeUndefined();
  });

  it("dispose waits for the in-flight delivery, then refuses new work without throwing", async () => {
    const { calls, fetchImpl, release } = makeHangingFetch();
    vi.stubGlobal("fetch", fetchImpl);
    const { client } = makeClient();
    const hooks = await SessionNotifyPlugin(makeInput(client));

    await emit(hooks, sessionCreated());
    await emit(hooks, sessionStatus({ type: "busy" }));
    await vi.advanceTimersByTimeAsync(60_000);
    await settle();
    expect(calls).toHaveLength(1);

    let disposed = false;
    const disposal = hooks.dispose?.().then(() => {
      disposed = true;
    });
    await settle();
    expect(disposed).toBe(false); // the hung send is still in flight

    release();
    await disposal;
    expect(disposed).toBe(true);

    // Idempotent and never throwing, even with events arriving afterwards.
    await expect(hooks.dispose?.()).resolves.toBeUndefined();
    await expect(emit(hooks, sessionStatus({ type: "busy" }))).resolves.toBeUndefined();
    await vi.advanceTimersByTimeAsync(60_000);
    await settle();
    expect(calls).toHaveLength(1); // the stopped pump accepted nothing more
  });

  it("dispose clears pending timers so nothing fires afterwards", async () => {
    const { calls, fetchImpl } = makeRecordingFetch();
    vi.stubGlobal("fetch", fetchImpl);
    const { client } = makeClient();
    const hooks = await SessionNotifyPlugin(makeInput(client));

    await emit(hooks, sessionCreated());
    await emit(hooks, sessionStatus({ type: "busy" }));
    await vi.advanceTimersByTimeAsync(1_000);
    await hooks.dispose?.();

    await vi.advanceTimersByTimeAsync(300_000);
    await settle();
    expect(calls).toHaveLength(0);
  });

  it("dispose flushes a pending idle completion and waits for delivery", async () => {
    const { calls, fetchImpl } = makeRecordingFetch();
    vi.stubGlobal("fetch", fetchImpl);
    const { client } = makeClient();
    const hooks = await SessionNotifyPlugin(makeInput(client));

    await emit(hooks, sessionCreated());
    await emit(hooks, sessionStatus({ type: "busy" }));
    await vi.advanceTimersByTimeAsync(5_000);
    await emit(hooks, sessionStatus({ type: "idle" }));

    await hooks.dispose?.();

    expect(postedEvents(calls)).toMatchObject([
      { type: "terminal", payload: { outcome: "completed", elapsedSeconds: 5 } },
    ]);
    await vi.advanceTimersByTimeAsync(60_000);
    await settle();
    expect(calls).toHaveLength(1);
  });

  it("defers pending-interaction queries until a snapshot request arrives (no self-HTTP at init)", async () => {
    const calls: FetchCall[] = [];
    const fetchImpl = (async (url: unknown, init?: { headers?: unknown; body?: unknown }) => {
      const requestUrl =
        url !== null && typeof url === "object" && "url" in url
          ? String((url as { url: unknown }).url)
          : String(url);
      calls.push({
        url: requestUrl,
        body: String(init?.body),
        headers: init?.headers as Record<string, string>,
      });
      return new Response("true", { status: 202 });
    }) as unknown as typeof fetch;
    vi.stubGlobal("fetch", fetchImpl);
    const sockets: CapturingSocket[] = [];
    vi.stubGlobal(
      "WebSocket",
      class {
        readonly delegate: CapturingSocket;
        constructor() {
          this.delegate = new CapturingSocket();
          sockets.push(this.delegate);
        }
        addEventListener(event: string, listener: (event?: unknown) => void): void {
          this.delegate.addEventListener(event, listener);
        }
        send(data: string): void {
          this.delegate.send(data);
        }
        close(): void {
          this.delegate.close();
        }
      },
    );
    const { client } = makeClient();

    const hooks = await SessionNotifyPlugin(makeInput(client));

    // Initialization made no pending queries and no self-HTTP: the adapter
    // and its V2 SDK client are only constructed on the first snapshot
    // request, never during plugin startup.
    expect(sockets).toHaveLength(0);
    expect(calls.filter((call) => call.url.startsWith("http://127.0.0.1"))).toHaveLength(0);

    await vi.advanceTimersByTimeAsync(0); // deferred control start
    expect(sockets).toHaveLength(1);
    expect(calls.filter((call) => call.url.startsWith("http://127.0.0.1"))).toHaveLength(0);

    sockets[0].emit("open");
    sockets[0].emit("message", {
      data: JSON.stringify({
        type: "registration",
        instanceId: "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
        state: "controllable",
      }),
    });
    expect(calls.filter((call) => call.url.startsWith("http://127.0.0.1"))).toHaveLength(0);

    sockets[0].emit("message", {
      data: JSON.stringify({
        type: "pending_snapshot_request",
        requestId: "0e3f9c2e-1a4d-4e5f-9a6b-7c8d9e0f1a2b",
      }),
    });
    await settle();

    // The lazy adapter now queried its own OpenCode instance (self-HTTP only
    // after initialization) and answered with a snapshot response.
    const selfCalls = calls.filter((call) => call.url.startsWith("http://127.0.0.1"));
    expect(selfCalls.length).toBeGreaterThan(0);
    const frames = sockets[0].sent.map((frame) => JSON.parse(frame));
    expect(frames).toContainEqual(
      expect.objectContaining({
        type: "pending_snapshot_response",
        requestId: "0e3f9c2e-1a4d-4e5f-9a6b-7c8d9e0f1a2b",
        instanceId: expect.any(String),
      }),
    );

    await hooks.dispose?.();
  });
});
