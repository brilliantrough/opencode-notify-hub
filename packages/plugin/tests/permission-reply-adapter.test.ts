import { describe, expect, it, vi } from "vitest";

import {
  PermissionReplyAdapter,
  type PermissionReplyClient,
} from "../src/permission-reply-adapter.js";

const REQUEST_ID = "per_req_1";
const DIRECTORY = "/work/api";

interface FakeReplyClient {
  client: PermissionReplyClient & {
    permission: { reply: ReturnType<typeof vi.fn>; reject: ReturnType<typeof vi.fn> };
  };
  reply: ReturnType<typeof vi.fn>;
  reject: ReturnType<typeof vi.fn>;
}

function makeClient(replyImpl: (...args: unknown[]) => unknown): FakeReplyClient {
  const reply = vi.fn(async (...args: unknown[]) => replyImpl(...args));
  const reject = vi.fn();
  const client = { permission: { reply, reject } } as FakeReplyClient["client"];
  return { client, reply, reject };
}

function makeAdapter(client: PermissionReplyClient): PermissionReplyAdapter {
  return new PermissionReplyAdapter({ client });
}

describe("PermissionReplyAdapter", () => {
  it("passes a once decision through verbatim and reports confirmed", async () => {
    const { client, reply } = makeClient(() => ({ data: true }));
    const adapter = makeAdapter(client);
    const signal = new AbortController().signal;

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, "once", signal);

    expect(status).toBe("confirmed");
    expect(reply).toHaveBeenCalledTimes(1);
    expect(reply).toHaveBeenCalledWith(
      { requestID: REQUEST_ID, directory: DIRECTORY, reply: "once" },
      { signal },
    );
  });

  it("passes a reject decision through verbatim and reports confirmed", async () => {
    const { client, reply } = makeClient(() => ({ data: true }));
    const adapter = makeAdapter(client);

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, "reject", new AbortController().signal);

    expect(status).toBe("confirmed");
    expect(reply).toHaveBeenCalledWith(
      { requestID: REQUEST_ID, directory: DIRECTORY, reply: "reject" },
      expect.objectContaining({ signal: expect.any(AbortSignal) }),
    );
  });

  it("passes an always decision through verbatim and reports confirmed", async () => {
    const { client, reply } = makeClient(() => ({ data: true }));
    const adapter = makeAdapter(client);

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, "always", new AbortController().signal);

    expect(status).toBe("confirmed");
    expect(reply).toHaveBeenCalledTimes(1);
    expect(reply).toHaveBeenCalledWith(
      { requestID: REQUEST_ID, directory: DIRECTORY, reply: "always" },
      expect.objectContaining({ signal: expect.any(AbortSignal) }),
    );
  });

  it("forwards the caller's abort signal to the SDK call", async () => {
    const { client, reply } = makeClient(() => ({ data: true }));
    const adapter = makeAdapter(client);
    const signal = new AbortController().signal;

    await adapter.reply(REQUEST_ID, DIRECTORY, "once", signal);

    expect(reply.mock.calls[0][1]).toEqual({ signal });
  });

  it("maps non-error success envelopes to confirmed except a false body", async () => {
    // The installed SDK declares a bare boolean body, but some versions
    // return a data object instead; every non-error envelope confirms,
    // except `data: false`, whose meaning is not confirmation.
    const envelopes = [
      { data: true },
      { data: true, request: {}, response: {} },
      { data: {} },
      { data: "ok" },
      { data: undefined, error: undefined },
    ];
    for (const envelope of envelopes) {
      const { client } = makeClient(() => envelope);
      const adapter = makeAdapter(client);

      const status = await adapter.reply(REQUEST_ID, DIRECTORY, "once", new AbortController().signal);

      expect(status).toBe("confirmed");
    }
  });

  it("maps a false success body to result_unknown instead of confirming", async () => {
    const { client } = makeClient(() => ({ data: false }));
    const adapter = makeAdapter(client);

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, "once", new AbortController().signal);

    expect(status).toBe("result_unknown");
  });

  it("maps a PermissionNotFoundError envelope to stale", async () => {
    const { client } = makeClient(() => ({
      error: { _tag: "PermissionNotFoundError", status: 404 },
    }));
    const adapter = makeAdapter(client);

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, "once", new AbortController().signal);

    expect(status).toBe("stale");
  });

  it.each(["BadRequestError", "InvalidRequestError", "InternalError"])(
    "maps other SDK error envelopes (%s) to upstream_error",
    async (tag) => {
      const { client } = makeClient(() => ({ error: { _tag: tag } }));
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

  it("maps a thrown SDK call to result_unknown", async () => {
    const { client } = makeClient(() => {
      throw new Error("sdk exploded");
    });
    const adapter = makeAdapter(client);

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, "once", new AbortController().signal);

    expect(status).toBe("result_unknown");
  });

  it("maps an aborted SDK call to result_unknown", async () => {
    const { client } = makeClient(() => {
      throw new DOMException("The operation was aborted", "AbortError");
    });
    const adapter = makeAdapter(client);

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, "once", new AbortController().signal);

    expect(status).toBe("result_unknown");
  });

  it("maps a transport-failure error envelope (no _tag) to result_unknown", async () => {
    const { client } = makeClient(() => ({ error: new TypeError("fetch failed") }));
    const adapter = makeAdapter(client);

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, "once", new AbortController().signal);

    expect(status).toBe("result_unknown");
  });

  it("maps a non-record response to result_unknown", async () => {
    const { client } = makeClient(() => true);
    const adapter = makeAdapter(client);

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, "once", new AbortController().signal);

    expect(status).toBe("result_unknown");
  });

  it("never calls a permission reject API", async () => {
    const { client, reject } = makeClient(() => ({ data: true }));
    const adapter = makeAdapter(client);

    await adapter.reply(REQUEST_ID, DIRECTORY, "reject", new AbortController().signal);

    expect(reject).not.toHaveBeenCalled();
  });

  it("never exposes decision bodies in its output", async () => {
    // A hostile reply that embeds the decision in its failure still only
    // yields a terminal status enum value: no body text can escape.
    const { client } = makeClient(() => {
      throw new Error("leak: SECRET-DECISION");
    });
    const adapter = makeAdapter(client);

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, "once", new AbortController().signal);

    expect(status).toBe("result_unknown");
    expect(JSON.stringify(status)).not.toContain("SECRET-DECISION");
  });
});
