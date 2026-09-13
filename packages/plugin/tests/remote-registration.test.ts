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

function setup(directory: string, response: () => Response | Promise<Response>, remoteDirectories: string[] = []) {
  const start = vi.fn();
  const warn = vi.fn();
  const fetch = vi.fn(async (request: Request) => {
    const url = new URL(request.url);
    expect(url.pathname).toBe("/session");
    expect(url.searchParams.get("directory")).toBe(directory);
    expect(url.searchParams.get("roots")).toBe("true");
    expect(["1", "50", "200"]).toContain(url.searchParams.get("limit"));
    expect(request.headers.get("authorization")).toBe("Basic fixture");
    return response();
  });
  const client = createOpencodeClient({ baseUrl: "http://localhost:4096", headers: { authorization: "Basic fixture" }, fetch });
  const input = { directory, worktree: directory, project: { worktree: directory }, serverUrl: new URL("http://localhost:4096"), client } as PluginInput;
  const hook = createSessionNotifyHooks(input, { ...config, remoteDirectories }, {
    control: { start, stop: async () => {} },
    pump: { enqueue: () => {}, stop: async () => {} },
    logger: { info: () => {}, debug: () => {}, warn, error: () => {} },
  });
  hooks.push(hook);
  return { hook, start, fetch, warn };
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
