import { describe, expect, it, vi } from "vitest";

import {
  PermissionReplyAdapter,
  type PermissionReplyClient,
} from "../src/permission-reply-adapter.js";

const REQUEST_ID = "per_req_1";
const DIRECTORY = "/work/api";

/** A V2 `PermissionV2Request` entry for the pending list. */
function permissionRequest(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    id: REQUEST_ID,
    sessionID: "ses_1",
    action: "bash",
    resources: ["echo hi"],
    save: [],
    source: { type: "tool", messageID: "msg_2", callID: "call_2" },
    ...overrides,
  };
}

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

function makeClient(
  listImpl: () => unknown,
  replyImpl: (...args: unknown[]) => unknown,
): FakeReplyClient {
  const list = vi.fn(async () => listImpl());
  const reply = vi.fn(async (...args: unknown[]) => replyImpl(...args));
  const reject = vi.fn();
  const client = {
    permission: { request: { list }, reject },
    session: { permission: { reply, reject } },
  } as FakeReplyClient["client"];
  return { client, list, reply, reject };
}

/** A V2 location-scoped list envelope carrying one pending permission. */
function pendingEnvelope(): unknown {
  return {
    data: {
      location: { directory: DIRECTORY },
      data: [permissionRequest()],
    },
    error: undefined,
  };
}

/** An empty V2 location-scoped list envelope. */
function emptyEnvelope(): unknown {
  return {
    data: { location: { directory: DIRECTORY }, data: [] },
    error: undefined,
  };
}

function makeAdapter(client: PermissionReplyClient): PermissionReplyAdapter {
  return new PermissionReplyAdapter({ client });
}

describe("PermissionReplyAdapter", () => {
  it("lists pending permissions, then passes a once decision verbatim and reports confirmed", async () => {
    const { client, list, reply } = makeClient(pendingEnvelope, () => ({ data: true }));
    const adapter = makeAdapter(client);
    const signal = new AbortController().signal;

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, "once", signal);

    expect(status).toBe("confirmed");
    // Reads the pending list first to confirm the request and learn the session.
    expect(list).toHaveBeenCalledTimes(1);
    expect(list).toHaveBeenCalledWith({ location: { directory: DIRECTORY } }, { signal });
    expect(reply).toHaveBeenCalledTimes(1);
    expect(reply).toHaveBeenCalledWith(
      { sessionID: "ses_1", requestID: REQUEST_ID, reply: "once" },
      { signal },
    );
  });

  it("passes a reject decision through verbatim and reports confirmed", async () => {
    const { client, reply } = makeClient(pendingEnvelope, () => ({ data: true }));
    const adapter = makeAdapter(client);

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, "reject", new AbortController().signal);

    expect(status).toBe("confirmed");
    expect(reply).toHaveBeenCalledWith(
      { sessionID: "ses_1", requestID: REQUEST_ID, reply: "reject" },
      expect.objectContaining({ signal: expect.any(AbortSignal) }),
    );
  });

  it("passes an always decision through verbatim and reports confirmed", async () => {
    const { client, reply } = makeClient(pendingEnvelope, () => ({ data: true }));
    const adapter = makeAdapter(client);

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, "always", new AbortController().signal);

    expect(status).toBe("confirmed");
    expect(reply).toHaveBeenCalledTimes(1);
    expect(reply).toHaveBeenCalledWith(
      { sessionID: "ses_1", requestID: REQUEST_ID, reply: "always" },
      expect.objectContaining({ signal: expect.any(AbortSignal) }),
    );
  });

  it("forwards the caller's abort signal to the list and reply calls", async () => {
    const { client, reply } = makeClient(pendingEnvelope, () => ({ data: true }));
    const adapter = makeAdapter(client);
    const signal = new AbortController().signal;

    await adapter.reply(REQUEST_ID, DIRECTORY, "once", signal);

    expect(reply.mock.calls[0][1]).toEqual({ signal });
  });

  it("maps non-error success envelopes to confirmed except a false body", async () => {
    // The V2 reply is a 204 with no body, so `data` may be undefined or
    // empty; every non-error envelope confirms, except `data: false`.
    const envelopes = [
      { data: true },
      { data: true, request: {}, response: {} },
      { data: {} },
      { data: "ok" },
      { data: undefined, error: undefined },
      { data: [], error: undefined },
    ];
    for (const envelope of envelopes) {
      const { client } = makeClient(pendingEnvelope, () => envelope);
      const adapter = makeAdapter(client);

      const status = await adapter.reply(REQUEST_ID, DIRECTORY, "once", new AbortController().signal);

      expect(status).toBe("confirmed");
    }
  });

  it("maps a false success body to result_unknown instead of confirming", async () => {
    const { client } = makeClient(pendingEnvelope, () => ({ data: false }));
    const adapter = makeAdapter(client);

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, "once", new AbortController().signal);

    expect(status).toBe("result_unknown");
  });

  it("maps a PermissionNotFoundError envelope to stale", async () => {
    const { client } = makeClient(pendingEnvelope, () => ({
      error: { _tag: "PermissionNotFoundError", status: 404 },
    }));
    const adapter = makeAdapter(client);

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, "once", new AbortController().signal);

    expect(status).toBe("stale");
  });

  it("maps a SessionNotFoundError envelope to stale", async () => {
    const { client } = makeClient(pendingEnvelope, () => ({
      error: { _tag: "SessionNotFoundError", status: 404 },
    }));
    const adapter = makeAdapter(client);

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, "once", new AbortController().signal);

    expect(status).toBe("stale");
  });

  it.each(["BadRequestError", "InvalidRequestError", "InternalError"])(
    "maps other SDK error envelopes (%s) to upstream_error",
    async (tag) => {
      const { client } = makeClient(pendingEnvelope, () => ({ error: { _tag: tag } }));
      const adapter = makeAdapter(client);

      const status = await adapter.reply(
        REQUEST_ID,
        DIRECTORY,
        "reject",
        new AbortController().signal,
      );

      expect(status).toBe("upstream_error");
    },
  );

  it("reports stale without replying when the request is no longer pending", async () => {
    const { client, reply } = makeClient(emptyEnvelope, () => ({ data: true }));
    const adapter = makeAdapter(client);

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, "once", new AbortController().signal);

    expect(status).toBe("stale");
    expect(reply).not.toHaveBeenCalled();
  });

  it("reports stale without replying when the list only holds other requests", async () => {
    const { client, reply } = makeClient(() => ({
      data: {
        location: { directory: DIRECTORY },
        data: [permissionRequest({ id: "per_other" })],
      },
      error: undefined,
    }), () => ({ data: true }));
    const adapter = makeAdapter(client);

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, "once", new AbortController().signal);

    expect(status).toBe("stale");
    expect(reply).not.toHaveBeenCalled();
  });

  it("maps a thrown list call to result_unknown without replying", async () => {
    const { client, reply } = makeClient(() => {
      throw new Error("sdk unreachable");
    }, () => ({ data: true }));
    const adapter = makeAdapter(client);

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, "once", new AbortController().signal);

    expect(status).toBe("result_unknown");
    expect(reply).not.toHaveBeenCalled();
  });

  it("maps a list error envelope to result_unknown", async () => {
    const { client } = makeClient(() => ({ data: undefined, error: { _tag: "BadRequestError" } }), () => ({ data: true }));
    const adapter = makeAdapter(client);

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, "once", new AbortController().signal);

    expect(status).toBe("result_unknown");
  });

  it("maps a malformed list payload to result_unknown", async () => {
    const malformed: unknown[] = [
      null,
      42,
      "nope",
      true,
      { data: undefined, error: undefined },
      { data: { error: { _tag: "InternalError" } }, error: undefined },
      { data: { location: {}, data: "nope" }, error: undefined },
    ];
    for (const payload of malformed) {
      const { client } = makeClient(() => payload, () => ({ data: true }));
      const adapter = makeAdapter(client);

      const status = await adapter.reply(
        REQUEST_ID,
        DIRECTORY,
        "once",
        new AbortController().signal,
      );

      expect(status).toBe("result_unknown");
    }
  });

  it("maps a thrown reply call to result_unknown", async () => {
    const { client } = makeClient(pendingEnvelope, () => {
      throw new Error("sdk exploded");
    });
    const adapter = makeAdapter(client);

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, "once", new AbortController().signal);

    expect(status).toBe("result_unknown");
  });

  it("maps an aborted SDK call to result_unknown", async () => {
    const { client } = makeClient(pendingEnvelope, () => {
      throw new DOMException("The operation was aborted", "AbortError");
    });
    const adapter = makeAdapter(client);

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, "once", new AbortController().signal);

    expect(status).toBe("result_unknown");
  });

  it("maps a transport-failure error envelope (no _tag) to result_unknown", async () => {
    const { client } = makeClient(pendingEnvelope, () => ({ error: new TypeError("fetch failed") }));
    const adapter = makeAdapter(client);

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, "once", new AbortController().signal);

    expect(status).toBe("result_unknown");
  });

  it("maps a non-record response to result_unknown", async () => {
    const { client } = makeClient(pendingEnvelope, () => true);
    const adapter = makeAdapter(client);

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, "once", new AbortController().signal);

    expect(status).toBe("result_unknown");
  });

  it("never calls a permission reject API", async () => {
    const { client, reject } = makeClient(pendingEnvelope, () => ({ data: true }));
    const adapter = makeAdapter(client);

    await adapter.reply(REQUEST_ID, DIRECTORY, "reject", new AbortController().signal);

    expect(reject).not.toHaveBeenCalled();
  });

  it("never exposes decision bodies in its output", async () => {
    // A hostile list or reply that embeds the decision in its failure still
    // only yields a terminal status enum value: no body text escapes.
    const { client } = makeClient(pendingEnvelope, () => {
      throw new Error("leak: SECRET-DECISION");
    });
    const adapter = makeAdapter(client);

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, "once", new AbortController().signal);

    expect(status).toBe("result_unknown");
    expect(JSON.stringify(status)).not.toContain("SECRET-DECISION");
  });
});
