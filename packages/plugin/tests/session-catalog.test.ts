import { expect, it } from "vitest";
import { SessionCatalogAdapter } from "../src/session-catalog.js";

it("discovers idle sessions and old bookmarks without mistaking status failures for idle", async () => {
  let statusFailed = false;
  const session = (id: string) => ({ id, directory: "/work/notify", title: id, time: { updated: 1_800_000_000_000 } });
  const adapter = new SessionCatalogAdapter("/work/notify", new URL("http://127.0.0.1:4096"),
    (async (input: Request) => {
      const url = new URL(input.url);
      expect(url.searchParams.get("directory")).toBe("/work/notify");
      if (url.pathname === "/session/status") {
        return Response.json(statusFailed ? {} : { busy: { type: "busy" } }, { status: statusFailed ? 503 : 200 });
      }
      if (url.pathname === "/session/old") return Response.json(session("old"));
      if (url.pathname === "/session/gone") return new Response(null, { status: 404 });
      expect(url.searchParams.get("roots")).toBe("true");
      return Response.json([session("idle"), session("busy"),
        { ...session("child"), parentID: "parent" },
        { ...session("other"), directory: "/work/other" }]);
    }) as typeof fetch);
  const query = { limit: 50, sessionIds: "old,gone" };
  const result = await adapter.list(query, new AbortController().signal);
  expect(result.sessions.map(s => [s.sessionId, s.status])).toEqual([
    ["idle", "idle"], ["busy", "busy"], ["old", "idle"],
  ]);
  statusFailed = true;
  expect((await adapter.list(query, new AbortController().signal)).sessions.every(s => s.status === "unknown")).toBe(true);
});
