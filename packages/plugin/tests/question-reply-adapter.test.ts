import { describe, expect, it, vi } from "vitest";

import {
  QuestionReplyAdapter,
  type QuestionReplyClient,
} from "../src/question-reply-adapter.js";

const REQUEST_ID = "req_1";
const DIRECTORY = "/work/api";

/** A V2 `QuestionV2Request` entry for the pending list. */
function questionRequest(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    id: REQUEST_ID,
    sessionID: "ses_1",
    questions: [
      { header: "Database", question: "Which database?", options: [], multiple: false },
    ],
    tool: { messageID: "msg_1", callID: "call_1" },
    ...overrides,
  };
}

interface FakeReplyClient {
  client: QuestionReplyClient & {
    question: {
      request: { list: ReturnType<typeof vi.fn> };
      reject: ReturnType<typeof vi.fn>;
    };
    session: { question: { reply: ReturnType<typeof vi.fn>; reject: ReturnType<typeof vi.fn> } };
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
    question: { request: { list }, reject },
    session: { question: { reply, reject } },
  } as FakeReplyClient["client"];
  return { client, list, reply, reject };
}

/** A V2 location-scoped list envelope carrying one pending question. */
function pendingEnvelope(): unknown {
  return {
    data: {
      location: { directory: DIRECTORY },
      data: [questionRequest()],
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

function makeAdapter(client: QuestionReplyClient): QuestionReplyAdapter {
  return new QuestionReplyAdapter({ client });
}

describe("QuestionReplyAdapter", () => {
  it("lists pending questions, then passes the answers verbatim and reports confirmed", async () => {
    const answers = [["Postgres"]];
    const { client, list, reply } = makeClient(pendingEnvelope, () => ({ data: true }));
    const adapter = makeAdapter(client);
    const signal = new AbortController().signal;

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, answers, signal);

    expect(status).toBe("confirmed");
    // Reads the pending list first to confirm the request and learn the session.
    expect(list).toHaveBeenCalledTimes(1);
    expect(list).toHaveBeenCalledWith({ location: { directory: DIRECTORY } }, { signal });
    expect(reply).toHaveBeenCalledTimes(1);
    expect(reply).toHaveBeenCalledWith(
      {
        sessionID: "ses_1",
        requestID: REQUEST_ID,
        questionV2Reply: { answers },
      },
      { signal },
    );
    // Exact pass-through: the same array instance, not a copy.
    expect(reply.mock.calls[0][0].questionV2Reply.answers).toBe(answers);
  });

  it("passes a multi-select answer with labels and custom text through verbatim", async () => {
    const answers = [["rust", "go", "Custom: polyglot"]];
    const { client, reply } = makeClient(pendingEnvelope, () => ({ data: true }));
    const adapter = makeAdapter(client);

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, answers, new AbortController().signal);

    expect(status).toBe("confirmed");
    expect(reply).toHaveBeenCalledWith(
      {
        sessionID: "ses_1",
        requestID: REQUEST_ID,
        questionV2Reply: { answers },
      },
      expect.objectContaining({ signal: expect.any(AbortSignal) }),
    );
    expect(reply.mock.calls[0][0].questionV2Reply.answers).toBe(answers);
  });

  it("preserves the exact ordered multi-question answer set", async () => {
    const answers = [["Postgres"], ["rust", "go"], ["Custom: as needed"]];
    const { client, reply } = makeClient(pendingEnvelope, () => ({ data: true }));
    const adapter = makeAdapter(client);

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, answers, new AbortController().signal);

    expect(status).toBe("confirmed");
    expect(reply.mock.calls[0][0].questionV2Reply.answers).toEqual(answers);
    expect(reply.mock.calls[0][0].questionV2Reply.answers).toBe(answers);
  });

  it("forwards the caller's abort signal to the list and reply calls", async () => {
    const { client, reply } = makeClient(pendingEnvelope, () => ({ data: true }));
    const adapter = makeAdapter(client);
    const signal = new AbortController().signal;

    await adapter.reply(REQUEST_ID, DIRECTORY, [["Yes"]], signal);

    expect(reply.mock.calls[0][1]).toEqual({ signal });
  });

  it("maps a non-error success envelope to confirmed even when data is absent (204)", async () => {
    const envelopes = [
      { data: true },
      { data: undefined, error: undefined, request: {}, response: {} },
      { data: {}, error: undefined },
      { data: [], error: undefined },
    ];
    for (const envelope of envelopes) {
      const { client } = makeClient(pendingEnvelope, () => envelope);
      const adapter = makeAdapter(client);

      const status = await adapter.reply(
        REQUEST_ID,
        DIRECTORY,
        [["Yes"]],
        new AbortController().signal,
      );

      expect(status).toBe("confirmed");
    }
  });

  it("maps a QuestionNotFoundError envelope to stale", async () => {
    const { client } = makeClient(pendingEnvelope, () => ({
      error: { _tag: "QuestionNotFoundError", status: 404 },
    }));
    const adapter = makeAdapter(client);

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, [["Yes"]], new AbortController().signal);

    expect(status).toBe("stale");
  });

  it("maps a SessionNotFoundError envelope to stale", async () => {
    const { client } = makeClient(pendingEnvelope, () => ({
      error: { _tag: "SessionNotFoundError", status: 404 },
    }));
    const adapter = makeAdapter(client);

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, [["Yes"]], new AbortController().signal);

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
        [["Yes"]],
        new AbortController().signal,
      );

      expect(status).toBe("upstream_error");
    },
  );

  it("reports stale without replying when the request is no longer pending", async () => {
    const { client, reply } = makeClient(emptyEnvelope, () => ({ data: true }));
    const adapter = makeAdapter(client);

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, [["Yes"]], new AbortController().signal);

    expect(status).toBe("stale");
    expect(reply).not.toHaveBeenCalled();
  });

  it("reports stale without replying when the list only holds other requests", async () => {
    const { client, reply } = makeClient(() => ({
      data: {
        location: { directory: DIRECTORY },
        data: [questionRequest({ id: "req_other" })],
      },
      error: undefined,
    }), () => ({ data: true }));
    const adapter = makeAdapter(client);

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, [["Yes"]], new AbortController().signal);

    expect(status).toBe("stale");
    expect(reply).not.toHaveBeenCalled();
  });

  it("maps a thrown list call to result_unknown without replying", async () => {
    const { client, reply } = makeClient(() => {
      throw new Error("sdk unreachable");
    }, () => ({ data: true }));
    const adapter = makeAdapter(client);

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, [["Yes"]], new AbortController().signal);

    expect(status).toBe("result_unknown");
    expect(reply).not.toHaveBeenCalled();
  });

  it("maps a list error envelope to result_unknown", async () => {
    const { client } = makeClient(() => ({ data: undefined, error: { _tag: "BadRequestError" } }), () => ({ data: true }));
    const adapter = makeAdapter(client);

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, [["Yes"]], new AbortController().signal);

    expect(status).toBe("result_unknown");
  });

  it("maps a malformed list payload to result_unknown", async () => {
    const malformed: unknown[] = [
      null,
      42,
      "nope",
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
        [["Yes"]],
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

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, [["Yes"]], new AbortController().signal);

    expect(status).toBe("result_unknown");
  });

  it("maps an aborted SDK call to result_unknown", async () => {
    const { client } = makeClient(pendingEnvelope, () => {
      throw new DOMException("The operation was aborted", "AbortError");
    });
    const adapter = makeAdapter(client);

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, [["Yes"]], new AbortController().signal);

    expect(status).toBe("result_unknown");
  });

  it("maps a transport-failure error envelope (no _tag) to result_unknown", async () => {
    const { client } = makeClient(pendingEnvelope, () => ({ error: new TypeError("fetch failed") }));
    const adapter = makeAdapter(client);

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, [["Yes"]], new AbortController().signal);

    expect(status).toBe("result_unknown");
  });

  it("never calls a question reject endpoint", async () => {
    const { client, reject } = makeClient(pendingEnvelope, () => ({ data: true }));
    const adapter = makeAdapter(client);

    await adapter.reply(REQUEST_ID, DIRECTORY, [["Yes"]], new AbortController().signal);

    expect(reject).not.toHaveBeenCalled();
  });

  it("never exposes answer bodies in its output", async () => {
    // A hostile list or reply that embeds the answer body in its failure
    // still only yields a terminal status enum value: no body text escapes.
    const { client } = makeClient(pendingEnvelope, () => {
      throw new Error("leak: [['SECRET-ANSWER']]");
    });
    const adapter = makeAdapter(client);

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, [["SECRET-ANSWER"]], new AbortController().signal);

    expect(status).toBe("result_unknown");
    expect(JSON.stringify(status)).not.toContain("SECRET-ANSWER");
  });
});
