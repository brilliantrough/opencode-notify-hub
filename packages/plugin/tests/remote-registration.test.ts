import type { Hooks, PluginInput } from "@opencode-ai/plugin";
import { createOpencodeClient } from "@opencode-ai/sdk";
import { afterEach, beforeEach, expect, it, vi } from "vitest";
import { loadConfig } from "../src/config.js";
import { createSessionNotifyHooks } from "../src/index.js";

const config = loadConfig({ NOTIFY_GATEWAY_URL: "https://gateway.example.com", NOTIFY_INGEST_KEY: "test.secret" })!;
const session = (directory: string) => ({ id: "ses_old", directory, title: "idle history", time: { updated: 1 } });
let hooks: Hooks[];

beforeEach(() => { vi.useFakeTimers(); hooks = []; });
afterEach(async () => {
  for (const hook of hooks) await hook.dispose?.();
  vi.useRealTimers();
});

function setup(directory: string, response: (request: Request) => Response | Promise<Response>, remoteDirectories: string[] = []) {
  const start = vi.fn();
  const stop = vi.fn();
  const enqueue = vi.fn();
  const warn = vi.fn();
  const fetch = vi.fn(async (request: Request) => {
    const url = new URL(request.url);
    if (url.pathname === "/session") {
      expect(url.searchParams.get("directory")).toBe(directory);
      expect(url.searchParams.get("roots")).toBe("true");
      expect(["1", "50", "200"]).toContain(url.searchParams.get("limit"));
    } else {
      expect(url.pathname).toBe("/session/ses_old");
    }
    expect(request.headers.get("authorization")).toBe("Basic fixture");
    return response(request);
  });
  const client = createOpencodeClient({ baseUrl: "http://localhost:4096", headers: { authorization: "Basic fixture" }, fetch });
  const input = { directory, worktree: directory, project: { worktree: directory }, serverUrl: new URL("http://localhost:4096"), client } as PluginInput;
  const hook = createSessionNotifyHooks(input, { ...config, remoteDirectories }, {
    control: { start, stop },
    pump: { enqueue, stop: async () => {} },
    logger: { info: () => {}, debug: () => {}, warn, error: () => {} },
  });
  hooks.push(hook);
  return { hook, start, stop, enqueue, fetch, warn };
}

it("130 browsed directories register only the 10 with idle history, without querying status", async () => {
  const entries = Array.from({ length: 130 }, (_, i) => {
    const directory = `/work/project-${i}`;
    return setup(directory, () => Response.json(i < 10 ? [session(directory)] : []));
  });
  expect(entries.every(e => e.fetch.mock.calls.length === 0)).toBe(true);
  await vi.advanceTimersByTimeAsync(0);
  expect(entries.reduce((sum, e) => sum + e.start.mock.calls.length, 0)).toBe(10);
  expect(entries.every(e => e.fetch.mock.calls.length === 1)).toBe(true);
  expect(entries.every(e => e.warn.mock.calls.length === 0)).toBe(true);
});

it("empty directories start exactly once on a main session, ignoring children, foreign and archived sessions", async () => {
  const { hook, start } = setup("/work/project", () => Response.json([]));
  await vi.advanceTimersByTimeAsync(0);
  const emit = async (info: object) => hook.event!({ event: { type: "session.created", properties: { info } } as never });
  await emit({ ...session("/work/project"), parentID: "ses_parent" });
  await emit(session("/work/other"));
  await emit({ ...session("/work/project"), time: { updated: 1, archived: 2 } });
  expect(start).not.toHaveBeenCalled();
  await emit(session("/work/project"));
  await emit(session("/work/project"));
  expect(start).toHaveBeenCalledTimes(1);
});

it("an archived recent session cannot hide older idle history", async () => {
  const archived = { ...session("/work/project"), time: { updated: 2, archived: 3 } };
  let calls = 0;
  const entry = setup("/work/project", () => Response.json(++calls === 1 ? [archived] : [archived, session("/work/project")]));
  const empty = setup("/work/archived", () => Response.json([{ ...archived, directory: "/work/archived" }]));
  await vi.advanceTimersByTimeAsync(0);
  expect(entry.start).toHaveBeenCalledTimes(1);
  expect(calls).toBe(2);
  expect(empty.start).not.toHaveBeenCalled();
  expect(empty.warn).not.toHaveBeenCalled();
});

it.each([
  () => new Response(null, { status: 401 }),
  () => new Response(null, { status: 503 }),
  () => Response.json({ error: "unexpected format" }),
  () => Response.json([session("/work/foreign")]),
  () => { throw new Error("connection refused"); },
  () => { throw new DOMException("request timed out", "TimeoutError"); },
])("preserves the remote entry when discovery is unknown instead of treating it as empty", async response => {
  const { start, warn } = setup("/work/project", response);
  await vi.advanceTimersByTimeAsync(0);
  expect(start).toHaveBeenCalledTimes(1);
  expect(warn).toHaveBeenCalledWith(expect.stringContaining("directory state unknown"));
});

it("explicit directories bypass discovery without enabling their child directories", async () => {
  const entry = setup("/work/project", () => Response.json([]), ["/work/project"]);
  const child = setup("/work/project/node_modules", () => Response.json([]), ["/work/project"]);
  await vi.advanceTimersByTimeAsync(0);
  expect(entry.start).toHaveBeenCalledTimes(1);
  expect(entry.fetch).not.toHaveBeenCalled();
  expect(child.start).not.toHaveBeenCalled();
});

it("a late discovery response cannot reopen a disposed plugin or undo event-driven registration", async () => {
  let resolve!: (response: Response) => void;
  const delayed = new Promise<Response>(r => { resolve = r; });
  const entry = setup("/work/project", () => delayed);
  const disposed = setup("/work/disposed", () => delayed);
  await vi.advanceTimersByTimeAsync(0);
  await entry.hook.event!({ event: { type: "session.created", properties: { info: session("/work/project") } } as never });
  await disposed.hook.dispose!();
  resolve(Response.json([]));
  await vi.advanceTimersByTimeAsync(0);
  expect(entry.start).toHaveBeenCalledTimes(1);
  expect(disposed.start).not.toHaveBeenCalled();
});

const emit = (hook: Hooks, type: string, info: object) =>
  hook.event!({ event: { type, properties: { info } } as never });

it("ignores root Magic Context workers in history, creation and subsequent notifications", async () => {
  const info = { ...session("/work/project"), title: "magic-context-dream-user-memories" };
  const entry = setup(info.directory, () => Response.json([info]));
  await vi.advanceTimersByTimeAsync(0);
  await emit(entry.hook, "session.created", info);
  await entry.hook.event!({ event: { type: "session.status", properties: { sessionID: info.id, status: { type: "busy" } } } as never });
  await entry.hook.event!({ event: { type: "session.error", properties: { sessionID: info.id, error: { name: "UnknownError" } } } as never });
  await emit(entry.hook, "session.deleted", info);
  await vi.advanceTimersByTimeAsync(10_000);
  expect(entry.start).not.toHaveBeenCalled();
  expect(entry.enqueue).not.toHaveBeenCalled();
});

it.each(["session.deleted", "session.updated"])("withdraws an empty entry after %s and permits a later real session", async type => {
  const info = session("/work/project");
  let rows = [info];
  const entry = setup(info.directory, () => Response.json(rows));
  await vi.advanceTimersByTimeAsync(0);
  expect(entry.start).toHaveBeenCalledTimes(1);
  rows = [];
  await emit(entry.hook, type, { ...info, time: { updated: 2, archived: 2 } });
  await vi.advanceTimersByTimeAsync(0);
  expect(entry.stop).toHaveBeenCalledTimes(1);
  await entry.hook.event!({ event: { type: "session.status", properties: { sessionID: info.id, status: { type: "busy" } } } as never });
  expect(entry.start).toHaveBeenCalledTimes(1);
  await emit(entry.hook, "session.created", { ...info, id: "ses_new" });
  expect(entry.start).toHaveBeenCalledTimes(2);
});

it("keeps idle history, explicit entries and unknown directories on deletion", async () => {
  const info = session("/work/project");
  const idle = setup(info.directory, () => Response.json([{ ...info, id: "ses_other" }]));
  const explicit = setup(info.directory, () => Response.json([]), [info.directory]);
  const unknown = setup(info.directory, () => new Response(null, { status: 503 }));
  await vi.advanceTimersByTimeAsync(0);
  for (const entry of [idle, explicit, unknown]) await emit(entry.hook, "session.deleted", info);
  await vi.advanceTimersByTimeAsync(0);
  for (const entry of [idle, explicit, unknown]) expect(entry.stop).not.toHaveBeenCalled();
});

it("an empty deletion snapshot cannot withdraw a newly created session", async () => {
  const info = session("/work/project");
  let resolve!: (response: Response) => void;
  let response = () => Promise.resolve(Response.json([info]));
  const entry = setup(info.directory, () => response());
  await vi.advanceTimersByTimeAsync(0);
  response = () => new Promise(r => { resolve = r; });
  await emit(entry.hook, "session.deleted", info);
  await vi.advanceTimersByTimeAsync(0);
  await emit(entry.hook, "session.created", { ...info, id: "ses_new" });
  resolve(Response.json([]));
  await vi.advanceTimersByTimeAsync(0);
  expect(entry.stop).not.toHaveBeenCalled();
});

it("filters internal workers through SDK lookup even if their creation event was missed", async () => {
  const info = { ...session("/work/project"), title: "magic-context-dream-user-memories" };
  const entry = setup(info.directory, request => Response.json(new URL(request.url).pathname === "/session" ? [] : info));
  await vi.advanceTimersByTimeAsync(0);
  for (let i = 0; i < 2; i++) {
    await entry.hook.event!({ event: { type: "session.status", properties: { sessionID: info.id, status: { type: "busy" } } } as never });
  }
  await vi.advanceTimersByTimeAsync(10_000);
  expect(entry.start).not.toHaveBeenCalled();
  expect(entry.enqueue).not.toHaveBeenCalled();
  expect(entry.fetch).toHaveBeenCalledTimes(2); // initial list and one cached lookup
});

it("ignores foreign deletion and restores an archived session with archived=0", async () => {
  const info = session("/work/project");
  const entry = setup(info.directory, () => Response.json([]));
  await vi.advanceTimersByTimeAsync(0);
  await emit(entry.hook, "session.created", info);
  await emit(entry.hook, "session.deleted", { ...info, directory: "/work/other" });
  await vi.advanceTimersByTimeAsync(0);
  expect(entry.stop).not.toHaveBeenCalled();
  await emit(entry.hook, "session.updated", { ...info, time: { archived: 2 } });
  await vi.advanceTimersByTimeAsync(0);
  expect(entry.stop).toHaveBeenCalledTimes(1);
  await emit(entry.hook, "session.updated", { ...info, time: { archived: 0 } });
  expect(entry.start).toHaveBeenCalledTimes(2);
});
