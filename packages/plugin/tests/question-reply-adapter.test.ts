import { describe, expect, it, vi } from "vitest";

import {
  QuestionReplyAdapter,
  type QuestionReplyClient,
} from "../src/question-reply-adapter.js";

const REQUEST_ID = "req_1";
const SESSION_ID = "ses_1";

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

function makeClient(replyImpl: (...args: unknown[]) => unknown): FakeReplyClient {
  const list = vi.fn();
  const reply = vi.fn(async (...args: unknown[]) => replyImpl(...args));
  const reject = vi.fn();
  const client = {
    question: { request: { list }, reject },
    session: { question: { reply, reject } },
  } as FakeReplyClient["client"];
  return { client, list, reply, reject };
}

function makeAdapter(client: QuestionReplyClient): QuestionReplyAdapter {
  return new QuestionReplyAdapter({ client });
}

describe("QuestionReplyAdapter", () => {
  it("replies directly with the event-carried session id without listing pending questions", async () => {
    const answers = [["Postgres"]];
    const { client, list, reply } = makeClient(() => ({ data: true }));
    const adapter = makeAdapter(client);
    const signal = new AbortController().signal;

    const status = await adapter.reply(REQUEST_ID, SESSION_ID, answers, signal);

    expect(status).toBe("confirmed");
    expect(list).not.toHaveBeenCalled();
    expect(reply).toHaveBeenCalledWith(
      {
        sessionID: SESSION_ID,
        requestID: REQUEST_ID,
        questionV2Reply: { answers },
      },
      { signal },
    );
    expect(reply.mock.calls[0][0].questionV2Reply.answers).toBe(answers);
  });

  it("preserves the exact ordered multi-question answer set", async () => {
    const answers = [["Postgres"], ["rust", "go", "Custom: polyglot"], ["Custom: as needed"]];
    const { client, reply } = makeClient(() => ({ data: true }));

    const status = await makeAdapter(client).reply(
      REQUEST_ID,
      SESSION_ID,
      answers,
      new AbortController().signal,
    );

    expect(status).toBe("confirmed");
    expect(reply.mock.calls[0][0].questionV2Reply.answers).toEqual(answers);
    expect(reply.mock.calls[0][0].questionV2Reply.answers).toBe(answers);
  });

  it("maps non-error success envelopes to confirmed even when data is absent", async () => {
    const envelopes = [
      { data: true },
      { data: undefined, error: undefined, request: {}, response: {} },
      { data: {}, error: undefined },
      { data: [], error: undefined },
    ];
    for (const envelope of envelopes) {
      const { client } = makeClient(() => envelope);
      expect(
        await makeAdapter(client).reply(
          REQUEST_ID,
          SESSION_ID,
          [["Yes"]],
          new AbortController().signal,
        ),
      ).toBe("confirmed");
    }
  });

  it.each(["QuestionNotFoundError", "SessionNotFoundError"])(
    "maps %s to stale",
    async (tag) => {
      const { client } = makeClient(() => ({ error: { _tag: tag, status: 404 } }));
      expect(
        await makeAdapter(client).reply(
          REQUEST_ID,
          SESSION_ID,
          [["Yes"]],
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
          [["Yes"]],
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
          [["Yes"]],
          new AbortController().signal,
        ),
      ).toBe("result_unknown");
    }
  });

  it("never calls a question reject endpoint or exposes answer bodies", async () => {
    const { client, reject } = makeClient(() => {
      throw new Error("leak: [['SECRET-ANSWER']]");
    });

    const status = await makeAdapter(client).reply(
      REQUEST_ID,
      SESSION_ID,
      [["SECRET-ANSWER"]],
      new AbortController().signal,
    );

    expect(status).toBe("result_unknown");
    expect(JSON.stringify(status)).not.toContain("SECRET-ANSWER");
    expect(reject).not.toHaveBeenCalled();
  });
});
