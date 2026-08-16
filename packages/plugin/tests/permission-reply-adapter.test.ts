import { describe, expect, it, vi } from "vitest";

import {
  PermissionReplyAdapter,
  type PermissionReplyClient,
} from "../src/permission-reply-adapter.js";

const REQUEST_ID = "per_req_1";
const SESSION_ID = "ses_1";

interface FakeReplyClient {
  client: PermissionReplyClient & {
    permission: {
      request: { list: ReturnType<typeof vi.fn> };
      reject: ReturnType<typeof vi.fn>;
    };
    session: { permission: { reply: ReturnType<typeof vi.fn>; reject: ReturnType<typeof vi.fn> } };
  };
  list: ReturnType<typeof vi.fn>;
  reply: ReturnType<typeof vi.fn>;
  reject: ReturnType<typeof vi.fn>;
}

function makeClient(replyImpl: (...args: unknown[]) => unknown): FakeReplyClient {
  const list = vi.fn();
  const reply = vi.fn(async (...args: unknown[]) => replyImpl(...args));
  const reject = vi.fn();
  const client = {
    permission: { request: { list }, reject },
    session: { permission: { reply, reject } },
  } as FakeReplyClient["client"];
  return { client, list, reply, reject };
}

function makeAdapter(client: PermissionReplyClient): PermissionReplyAdapter {
  return new PermissionReplyAdapter({ client });
}

describe("PermissionReplyAdapter", () => {
  it("replies directly with the event-carried session id without listing pending permissions", async () => {
    const { client, list, reply } = makeClient(() => ({ data: true }));
    const signal = new AbortController().signal;

    const status = await makeAdapter(client).reply(
      REQUEST_ID,
      SESSION_ID,
      "once",
      signal,
    );

    expect(status).toBe("confirmed");
    expect(list).not.toHaveBeenCalled();
    expect(reply).toHaveBeenCalledWith(
      { sessionID: SESSION_ID, requestID: REQUEST_ID, reply: "once" },
      { signal },
    );
  });

  it.each(["once", "always", "reject"] as const)(
    "passes the %s decision through verbatim",
    async (decision) => {
      const { client, reply } = makeClient(() => ({ data: true }));
      const status = await makeAdapter(client).reply(
        REQUEST_ID,
        SESSION_ID,
        decision,
        new AbortController().signal,
      );

      expect(status).toBe("confirmed");
      expect(reply.mock.calls[0][0].reply).toBe(decision);
    },
  );

  it("maps non-error success envelopes to confirmed except literal false", async () => {
    for (const envelope of [
      { data: true },
      { data: undefined, error: undefined },
      { data: {}, error: undefined },
    ]) {
      const { client } = makeClient(() => envelope);
      expect(
        await makeAdapter(client).reply(
          REQUEST_ID,
          SESSION_ID,
          "once",
          new AbortController().signal,
        ),
      ).toBe("confirmed");
    }

    const { client } = makeClient(() => ({ data: false, error: undefined }));
    expect(
      await makeAdapter(client).reply(
        REQUEST_ID,
        SESSION_ID,
        "once",
        new AbortController().signal,
      ),
    ).toBe("result_unknown");
  });

  it.each(["PermissionNotFoundError", "SessionNotFoundError"])(
    "maps %s to stale",
    async (tag) => {
      const { client } = makeClient(() => ({ error: { _tag: tag, status: 404 } }));
      expect(
        await makeAdapter(client).reply(
          REQUEST_ID,
          SESSION_ID,
          "once",
          new AbortController().signal,
        ),
      ).toBe("stale");
    },
  );

  it.each(["BadRequestError", "InvalidRequestError", "InternalError"])(
    "maps other SDK error envelopes (%s) to upstream_error",
    async (tag) => {
      const { client } = makeClient(() => ({ error: { _tag: tag } }));
      expect(
        await makeAdapter(client).reply(
          REQUEST_ID,
          SESSION_ID,
          "once",
          new AbortController().signal,
        ),
      ).toBe("upstream_error");
    },
  );

  it("maps thrown, aborted, and transport-failure replies to result_unknown", async () => {
    const failures = [
      () => {
        throw new Error("sdk exploded");
      },
      () => {
        throw new DOMException("The operation was aborted", "AbortError");
      },
      () => ({ error: new TypeError("fetch failed") }),
    ];
    for (const failure of failures) {
      const { client } = makeClient(failure);
      expect(
        await makeAdapter(client).reply(
          REQUEST_ID,
          SESSION_ID,
          "once",
          new AbortController().signal,
        ),
      ).toBe("result_unknown");
    }
  });

  it("never calls a permission reject endpoint or exposes decision bodies", async () => {
    const { client, reject } = makeClient(() => {
      throw new Error("leak: always");
    });

    const status = await makeAdapter(client).reply(
      REQUEST_ID,
      SESSION_ID,
      "always",
      new AbortController().signal,
    );

    expect(status).toBe("result_unknown");
    expect(JSON.stringify(status)).not.toContain("always");
    expect(reject).not.toHaveBeenCalled();
  });
});
