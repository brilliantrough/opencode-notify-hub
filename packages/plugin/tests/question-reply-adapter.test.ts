import { describe, expect, it, vi } from "vitest";

import {
  QuestionReplyAdapter,
  type QuestionReplyClient,
} from "../src/question-reply-adapter.js";

const REQUEST_ID = "req_1";
const DIRECTORY = "/work/api";

interface FakeReplyClient {
  client: QuestionReplyClient & { question: { reject: ReturnType<typeof vi.fn> } };
  reply: ReturnType<typeof vi.fn>;
  reject: ReturnType<typeof vi.fn>;
}

function makeClient(replyImpl: (...args: unknown[]) => unknown): FakeReplyClient {
  const reply = vi.fn(async (...args: unknown[]) => replyImpl(...args));
  const reject = vi.fn();
  const client = { question: { reply, reject } } as FakeReplyClient["client"];
  return { client, reply, reject };
}

function makeAdapter(client: QuestionReplyClient): QuestionReplyAdapter {
  return new QuestionReplyAdapter({ client });
}

describe("QuestionReplyAdapter", () => {
  it("passes a single-select answer through verbatim and reports confirmed", async () => {
    const answers = [["Postgres"]];
    const { client, reply } = makeClient(() => ({ data: true }));
    const adapter = makeAdapter(client);
    const signal = new AbortController().signal;

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, answers, signal);

    expect(status).toBe("confirmed");
    expect(reply).toHaveBeenCalledTimes(1);
    expect(reply).toHaveBeenCalledWith(
      { requestID: REQUEST_ID, directory: DIRECTORY, answers },
      { signal },
    );
    // Exact pass-through: the same array instance, not a copy.
    expect(reply.mock.calls[0][0].answers).toBe(answers);
  });

  it("passes a multi-select answer with labels and custom text through verbatim", async () => {
    const answers = [["rust", "go", "Custom: polyglot"]];
    const { client, reply } = makeClient(() => ({ data: true }));
    const adapter = makeAdapter(client);

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, answers, new AbortController().signal);

    expect(status).toBe("confirmed");
    expect(reply).toHaveBeenCalledWith(
      { requestID: REQUEST_ID, directory: DIRECTORY, answers },
      expect.objectContaining({ signal: expect.any(AbortSignal) }),
    );
    expect(reply.mock.calls[0][0].answers).toBe(answers);
  });

  it("preserves the exact ordered multi-question answer set", async () => {
    const answers = [["Postgres"], ["rust", "go"], ["Custom: as needed"]];
    const { client, reply } = makeClient(() => ({ data: true }));
    const adapter = makeAdapter(client);

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, answers, new AbortController().signal);

    expect(status).toBe("confirmed");
    expect(reply.mock.calls[0][0].answers).toEqual(answers);
    expect(reply.mock.calls[0][0].answers).toBe(answers);
  });

  it("forwards the caller's abort signal to the SDK call", async () => {
    const { client, reply } = makeClient(() => ({ data: true }));
    const adapter = makeAdapter(client);
    const signal = new AbortController().signal;

    await adapter.reply(REQUEST_ID, DIRECTORY, [["Yes"]], signal);

    expect(reply.mock.calls[0][1]).toEqual({ signal });
  });

  it("maps { data: true } to confirmed", async () => {
    const { client } = makeClient(() => ({ data: true, request: {}, response: {} }));
    const adapter = makeAdapter(client);

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, [["Yes"]], new AbortController().signal);

    expect(status).toBe("confirmed");
  });

  it("maps a QuestionNotFoundError envelope to stale", async () => {
    const { client } = makeClient(() => ({
      error: { _tag: "QuestionNotFoundError", status: 404 },
    }));
    const adapter = makeAdapter(client);

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, [["Yes"]], new AbortController().signal);

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
        [["Yes"]],
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

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, [["Yes"]], new AbortController().signal);

    expect(status).toBe("result_unknown");
  });

  it("maps an aborted SDK call to result_unknown", async () => {
    const { client } = makeClient(() => {
      throw new DOMException("The operation was aborted", "AbortError");
    });
    const adapter = makeAdapter(client);

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, [["Yes"]], new AbortController().signal);

    expect(status).toBe("result_unknown");
  });

  it("maps a transport-failure error envelope (no _tag) to result_unknown", async () => {
    const { client } = makeClient(() => ({ error: new TypeError("fetch failed") }));
    const adapter = makeAdapter(client);

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, [["Yes"]], new AbortController().signal);

    expect(status).toBe("result_unknown");
  });

  it("maps a success envelope with non-true data to result_unknown", async () => {
    const { client } = makeClient(() => ({ data: false }));
    const adapter = makeAdapter(client);

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, [["Yes"]], new AbortController().signal);

    expect(status).toBe("result_unknown");
  });

  it("never calls question.reject", async () => {
    const { client, reject } = makeClient(() => ({ data: true }));
    const adapter = makeAdapter(client);

    await adapter.reply(REQUEST_ID, DIRECTORY, [["Yes"]], new AbortController().signal);

    expect(reject).not.toHaveBeenCalled();
  });

  it("never exposes answer bodies in its output", async () => {
    // A hostile reply that embeds the answer body in its failure still only
    // yields a terminal status enum value: no body text can escape.
    const { client } = makeClient(() => {
      throw new Error("leak: [['SECRET-ANSWER']]");
    });
    const adapter = makeAdapter(client);

    const status = await adapter.reply(REQUEST_ID, DIRECTORY, [["SECRET-ANSWER"]], new AbortController().signal);

    expect(status).toBe("result_unknown");
    expect(JSON.stringify(status)).not.toContain("SECRET-ANSWER");
  });
});
