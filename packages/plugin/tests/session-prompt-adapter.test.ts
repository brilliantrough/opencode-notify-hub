import { describe, expect, it, vi } from "vitest";

import {
  SessionPromptAdapter,
  type SessionPromptClient,
} from "../src/session-prompt-adapter.js";

const SESSION_ID = "ses_1";
const TEXT = "Continue with the migration and run the tests.";

function makeClient(promptImpl: (...args: unknown[]) => unknown) {
  const prompt = vi.fn(async (...args: unknown[]) => promptImpl(...args));
  const client = { session: { prompt } } as SessionPromptClient;
  return { client, prompt };
}

describe("SessionPromptAdapter", () => {
  it("passes the exact session id and text to the V2 prompt endpoint", async () => {
    const { client, prompt } = makeClient(() => ({ data: { data: { admitted: true } } }));
    const signal = new AbortController().signal;

    await expect(new SessionPromptAdapter(client).send(SESSION_ID, TEXT, signal)).resolves.toBe(
      "confirmed",
    );
    expect(prompt).toHaveBeenCalledWith(
      { sessionID: SESSION_ID, prompt: { text: TEXT } },
      { signal },
    );
  });

  it("maps SDK errors to upstream_error and transport failures to result_unknown", async () => {
    const { client: rejected } = makeClient(() => ({ error: { _tag: "BadRequestError" } }));
    await expect(
      new SessionPromptAdapter(rejected).send(SESSION_ID, TEXT, new AbortController().signal),
    ).resolves.toBe("upstream_error");

    const { client: failed } = makeClient(() => {
      throw new Error("connection lost");
    });
    await expect(
      new SessionPromptAdapter(failed).send(SESSION_ID, TEXT, new AbortController().signal),
    ).resolves.toBe("result_unknown");
  });

  it("never exposes the prompt text through a status", async () => {
    const { client } = makeClient(() => {
      throw new Error(`sensitive prompt: ${TEXT}`);
    });
    const status = await new SessionPromptAdapter(client).send(
      SESSION_ID,
      TEXT,
      new AbortController().signal,
    );
    expect(status).toBe("result_unknown");
    expect(JSON.stringify(status)).not.toContain(TEXT);
  });
});
