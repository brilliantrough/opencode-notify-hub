import { describe, expect, it, vi } from "vitest";
import type { OpencodeClient } from "@opencode-ai/sdk";

import {
  createSdkLookup,
  SessionRegistry,
  type SessionLookup,
} from "../src/session-registry.js";

/** A lookup that fails (unknown ancestry) for every session. */
function failingLookup(): SessionLookup & { getParentID: ReturnType<typeof vi.fn> } {
  return {
    getParentID: vi.fn(async () => undefined),
  };
}

describe("SessionRegistry — cached ancestry", () => {
  it("returns false for a cached child session without calling the lookup", async () => {
    const lookup = failingLookup();
    const registry = new SessionRegistry(lookup);
    registry.update("ses_child", "ses_parent", "Child task");

    await expect(registry.isMain("ses_child")).resolves.toBe(false);
    expect(lookup.getParentID).not.toHaveBeenCalled();
  });

  it("returns true for a cached top-level session without calling the lookup", async () => {
    const lookup = failingLookup();
    const registry = new SessionRegistry(lookup);
    registry.update("ses_main", null, "Main session");

    await expect(registry.isMain("ses_main")).resolves.toBe(true);
    expect(lookup.getParentID).not.toHaveBeenCalled();
  });

  it("updates cached ancestry and title on later upserts", async () => {
    const lookup = failingLookup();
    const registry = new SessionRegistry(lookup);
    registry.update("ses_1", null, "Original title");
    registry.update("ses_1", "ses_parent", "Renamed");

    await expect(registry.isMain("ses_1")).resolves.toBe(false);
    expect(registry.title("ses_1")).toBe("Renamed");
    expect(lookup.getParentID).not.toHaveBeenCalled();
  });

  it("keeps the previous title when an upsert omits it", () => {
    const registry = new SessionRegistry(failingLookup());
    registry.update("ses_1", null, "Kept title");
    registry.update("ses_1", null);

    expect(registry.title("ses_1")).toBe("Kept title");
  });

  it("returns undefined for an unknown session title", () => {
    const registry = new SessionRegistry(failingLookup());
    expect(registry.title("ses_missing")).toBeUndefined();
  });
});

describe("SessionRegistry — SDK fallback", () => {
  it("queries the lookup once on a cache miss and caches the result", async () => {
    const lookup = { getParentID: vi.fn(async () => null) };
    const registry = new SessionRegistry(lookup);

    await expect(registry.isMain("ses_new")).resolves.toBe(true);
    await expect(registry.isMain("ses_new")).resolves.toBe(true);
    expect(lookup.getParentID).toHaveBeenCalledTimes(1);
    expect(lookup.getParentID).toHaveBeenCalledWith("ses_new");
  });

  it("caches a discovered parent so children stay false without re-querying", async () => {
    const lookup = { getParentID: vi.fn(async () => "ses_parent") };
    const registry = new SessionRegistry(lookup);

    await expect(registry.isMain("ses_new")).resolves.toBe(false);
    await expect(registry.isMain("ses_new")).resolves.toBe(false);
    expect(lookup.getParentID).toHaveBeenCalledTimes(1);
  });

  it("returns null for a failed lookup and does not cache it as main", async () => {
    const lookup = {
      getParentID: vi.fn(async (): Promise<string | null | undefined> => undefined),
    };
    const registry = new SessionRegistry(lookup);

    await expect(registry.isMain("ses_flaky")).resolves.toBeNull();
    expect(lookup.getParentID).toHaveBeenCalledTimes(1);

    // Retry after failure: the miss must query again, and success caches.
    lookup.getParentID.mockResolvedValueOnce(null);
    await expect(registry.isMain("ses_flaky")).resolves.toBe(true);
    await expect(registry.isMain("ses_flaky")).resolves.toBe(true);
    expect(lookup.getParentID).toHaveBeenCalledTimes(2);
  });

  it("returns null instead of rejecting when the lookup throws", async () => {
    const lookup = {
      getParentID: vi.fn(async () => {
        throw new Error("transport exploded");
      }),
    };
    const registry = new SessionRegistry(lookup);

    await expect(registry.isMain("ses_broken")).resolves.toBeNull();
    expect(lookup.getParentID).toHaveBeenCalledTimes(1);
  });

  it("never throws even when the lookup itself is hostile", async () => {
    const lookup = {
      getParentID: () => {
        throw new Error("synchronous boom");
      },
    } as unknown as SessionLookup;
    const registry = new SessionRegistry(lookup);

    await expect(registry.isMain("ses_hostile")).resolves.toBeNull();
  });

  it("prefers a mid-flight session upsert over a stale lookup result", async () => {
    let release!: (value: string | null | undefined) => void;
    const gate = new Promise<string | null | undefined>((resolve) => {
      release = resolve;
    });
    const lookup = { getParentID: vi.fn(() => gate) };
    const registry = new SessionRegistry(lookup);

    const pending = registry.isMain("ses_race");
    expect(lookup.getParentID).toHaveBeenCalledTimes(1);

    // The event bus reports fresher ancestry while the SDK call is in
    // flight; the event wins and is what gets cached.
    registry.update("ses_race", null, "Promoted to main");
    release("ses_parent");

    await expect(pending).resolves.toBe(true);
    expect(registry.title("ses_race")).toBe("Promoted to main");
    await expect(registry.isMain("ses_race")).resolves.toBe(true);
    expect(lookup.getParentID).toHaveBeenCalledTimes(1);
  });

  it("prefers a mid-flight session upsert even when the lookup rejects", async () => {
    let reject!: (reason: unknown) => void;
    const gate = new Promise<string | null | undefined>((_resolve, rejectPromise) => {
      reject = rejectPromise;
    });
    const lookup = { getParentID: vi.fn(() => gate) };
    const registry = new SessionRegistry(lookup);

    const pending = registry.isMain("ses_race");
    expect(lookup.getParentID).toHaveBeenCalledTimes(1);

    // The event bus lands while the SDK call is in flight; when the call
    // then fails, the fresh event ancestry still wins over "unknown".
    registry.update("ses_race", "ses_parent", "Child while racing");
    reject(new Error("transport lost"));

    await expect(pending).resolves.toBe(false);
    expect(registry.title("ses_race")).toBe("Child while racing");
    await expect(registry.isMain("ses_race")).resolves.toBe(false);
    expect(lookup.getParentID).toHaveBeenCalledTimes(1);
  });
});

describe("SessionRegistry — concurrency", () => {
  it("coalesces concurrent cache misses for the same session into one lookup call", async () => {
    let release!: (value: string | null | undefined) => void;
    const gate = new Promise<string | null | undefined>((resolve) => {
      release = resolve;
    });
    const lookup = { getParentID: vi.fn(() => gate) };
    const registry = new SessionRegistry(lookup);

    const first = registry.isMain("ses_race");
    const second = registry.isMain("ses_race");
    const third = registry.isMain("ses_race");
    expect(lookup.getParentID).toHaveBeenCalledTimes(1);

    release("ses_parent");
    await expect(first).resolves.toBe(false);
    await expect(second).resolves.toBe(false);
    await expect(third).resolves.toBe(false);

    // In-flight cleared on success and result cached: no further lookups.
    await expect(registry.isMain("ses_race")).resolves.toBe(false);
    expect(lookup.getParentID).toHaveBeenCalledTimes(1);
  });

  it("clears the in-flight entry after failure so a later call retries", async () => {
    let release!: (value: string | null | undefined) => void;
    const gate = new Promise<string | null | undefined>((resolve) => {
      release = resolve;
    });
    const lookup = { getParentID: vi.fn(() => gate) };
    const registry = new SessionRegistry(lookup);

    const first = registry.isMain("ses_race");
    const second = registry.isMain("ses_race");
    expect(lookup.getParentID).toHaveBeenCalledTimes(1);

    release(undefined);
    await expect(first).resolves.toBeNull();
    await expect(second).resolves.toBeNull();

    // Unknown results are not cached; the next miss queries again.
    lookup.getParentID.mockResolvedValue(null);
    await expect(registry.isMain("ses_race")).resolves.toBe(true);
    expect(lookup.getParentID).toHaveBeenCalledTimes(2);
  });

  it("tracks in-flight lookups per session, not globally", async () => {
    const lookup = {
      getParentID: vi.fn(async (sessionID: string) =>
        sessionID === "ses_a" ? null : "ses_parent",
      ),
    };
    const registry = new SessionRegistry(lookup);

    const [a, b] = await Promise.all([registry.isMain("ses_a"), registry.isMain("ses_b")]);
    expect(a).toBe(true);
    expect(b).toBe(false);
    expect(lookup.getParentID).toHaveBeenCalledTimes(2);
  });
});

describe("createSdkLookup", () => {
  it("calls session.get on the subclient with the SDK path argument shape", async () => {
    const get = vi.fn(async () => ({ data: { id: "ses_x", parentID: null } }));
    const lookup = createSdkLookup({ get });

    await lookup.getParentID("ses_x");
    expect(get).toHaveBeenCalledWith({ path: { id: "ses_x" } });
  });

  it("keeps `this` bound: an instance method depending on instance state works", async () => {
    // Mirrors the real SDK's `class Session extends HeyApiClient`, whose
    // methods read `this._client`. Passing the subclient object (not a
    // detached method) must keep the method working.
    class FakeSessionClient {
      constructor(private readonly sessions: Record<string, unknown>) {}

      async get(options: { path: { id: string } }): Promise<unknown> {
        const session = this.sessions[options.path.id];
        if (session === undefined) {
          throw new Error("not found");
        }
        return { data: session };
      }
    }
    const client = new FakeSessionClient({
      ses_main: { id: "ses_main" },
      ses_child: { id: "ses_child", parentID: "ses_main" },
    });
    const lookup = createSdkLookup(client);

    await expect(lookup.getParentID("ses_main")).resolves.toBeNull();
    await expect(lookup.getParentID("ses_child")).resolves.toBe("ses_main");
    await expect(lookup.getParentID("ses_missing")).resolves.toBeUndefined();
  });

  it("accepts the real SDK session subclient type (compile-time contract)", () => {
    // `as` builds a typed placeholder; the assignability check that matters
    // is passing it to createSdkLookup below — a type mismatch fails tsc.
    const sessionSubclient = {} as OpencodeClient["session"];
    expect(createSdkLookup(sessionSubclient)).toBeDefined();
  });

  it("unwraps a `{ data: session }` response: string parentID means child", async () => {
    const get = vi.fn(async () => ({ data: { id: "ses_x", parentID: "ses_parent" } }));
    const lookup = createSdkLookup({ get });

    await expect(lookup.getParentID("ses_x")).resolves.toBe("ses_parent");
  });

  it("accepts a direct session response: string parentID means child", async () => {
    const get = vi.fn(async () => ({ id: "ses_x", parentID: "ses_parent" }));
    const lookup = createSdkLookup({ get });

    await expect(lookup.getParentID("ses_x")).resolves.toBe("ses_parent");
  });

  it("maps an explicit null parentID to top-level (null) for both response shapes", async () => {
    const wrapped = createSdkLookup({
      get: async () => ({ data: { id: "ses_x", parentID: null } }),
    });
    const direct = createSdkLookup({ get: async () => ({ id: "ses_x", parentID: null }) });

    await expect(wrapped.getParentID("ses_x")).resolves.toBeNull();
    await expect(direct.getParentID("ses_x")).resolves.toBeNull();
  });

  it("maps an absent parentID to top-level (null) for both response shapes", async () => {
    const wrapped = createSdkLookup({ get: async () => ({ data: { id: "ses_x" } }) });
    const direct = createSdkLookup({ get: async () => ({ id: "ses_x" }) });

    await expect(wrapped.getParentID("ses_x")).resolves.toBeNull();
    await expect(direct.getParentID("ses_x")).resolves.toBeNull();
  });

  it("treats a session whose id does not match the request as unknown", async () => {
    const get = vi.fn(async () => ({ data: { id: "ses_other", parentID: null } }));
    const lookup = createSdkLookup({ get });

    await expect(lookup.getParentID("ses_x")).resolves.toBeUndefined();
  });

  it("recognizes SDK error envelopes as unknown", async () => {
    // Non-throwing SDK calls resolve to `{ data, error, ... }`; a populated
    // `error` means the request failed and carries no trustworthy session.
    const envelopes: Array<[string, unknown]> = [
      ["error only", { error: { message: "not found" } }],
      ["data undefined with error", { data: undefined, error: { message: "HTTP 404" } }],
      // A valid response shape with `error: undefined` is NOT an error
      // envelope and must still resolve normally.
    ];
    for (const [name, response] of envelopes) {
      const lookup = createSdkLookup({ get: async () => response });
      await expect(lookup.getParentID("ses_x"), name).resolves.toBeUndefined();
    }
    const ok = createSdkLookup({
      get: async () => ({ data: { id: "ses_x" }, error: undefined }),
    });
    await expect(ok.getParentID("ses_x")).resolves.toBeNull();
  });

  it("returns undefined (unknown) when the SDK call rejects", async () => {
    const get = vi.fn(async () => {
      throw new Error("HTTP 500");
    });
    const lookup = createSdkLookup({ get });

    await expect(lookup.getParentID("ses_x")).resolves.toBeUndefined();
  });

  it("returns undefined (unknown) for malformed responses", async () => {
    const malformed: Array<[string, unknown]> = [
      ["null", null],
      ["non-record", "session"],
      ["empty object", {}],
      ["data as non-record", { data: "garbage" }],
      ["data missing id", { data: { parentID: "ses_parent" } }],
      ["non-string parentID", { data: { id: "ses_x", parentID: 42 } }],
    ];
    for (const [name, response] of malformed) {
      const lookup = createSdkLookup({ get: async () => response });
      await expect(lookup.getParentID("ses_x"), name).resolves.toBeUndefined();
    }
  });

  it("never throws, even for a synchronously throwing getter", async () => {
    const sessionClient = {
      get() {
        throw new Error("unbound this");
      },
    };
    const lookup = createSdkLookup(sessionClient as never);

    await expect(lookup.getParentID("ses_x")).resolves.toBeUndefined();
  });
});

describe("SessionRegistry — mismatched SDK session id", () => {
  it("fails closed on a mismatched id and retries instead of caching", async () => {
    const get = vi
      .fn()
      .mockResolvedValueOnce({ data: { id: "ses_wrong", parentID: null } })
      .mockResolvedValueOnce({ data: { id: "ses_x", parentID: "ses_parent" } });
    const registry = new SessionRegistry(createSdkLookup({ get }));

    // Mismatch: unknown, must not be cached as main (or at all).
    await expect(registry.isMain("ses_x")).resolves.toBeNull();
    expect(get).toHaveBeenCalledTimes(1);

    // The next miss queries again; a matching response caches normally.
    await expect(registry.isMain("ses_x")).resolves.toBe(false);
    await expect(registry.isMain("ses_x")).resolves.toBe(false);
    expect(get).toHaveBeenCalledTimes(2);
  });
});
