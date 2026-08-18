import { describe, expect, it, vi } from "vitest";

import {
  SessionPromptAdapter,
} from "../src/session-prompt-adapter.js";

const SESSION_ID = "ses_1";
const TEXT = "Continue with the migration and run the tests.";

function makeFetch(response: () => Response | Promise<Response>) {
  return vi.fn(async () => response()) as typeof fetch;
}

describe("SessionPromptAdapter", () => {
  it("sends the exact session id and text to the V1 async prompt endpoint", async () => {
    const fetch = makeFetch(() => new Response(null, { status: 204 }));
    const adapter = new SessionPromptAdapter({
      baseUrl: new URL("http://127.0.0.1:1142/"),
      directory: "/work/notify",
      fetch,
    });
    const signal = new AbortController().signal;

    await expect(adapter.send(SESSION_ID, TEXT, signal)).resolves.toBe("confirmed");
    expect(fetch).toHaveBeenCalledWith(
      new URL(
        "http://127.0.0.1:1142/session/ses_1/prompt_async?directory=%2Fwork%2Fnotify",
      ),
      expect.objectContaining({
        method: "POST",
        signal,
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ parts: [{ type: "text", text: TEXT }] }),
      }),
    );
  });

  it("maps non-success responses to upstream_error and transport failures to result_unknown", async () => {
    const rejected = new SessionPromptAdapter({
      baseUrl: new URL("http://127.0.0.1:1142/"),
      directory: "/work/notify",
      fetch: makeFetch(() => new Response(null, { status: 409 })),
    });
    await expect(
      rejected.send(SESSION_ID, TEXT, new AbortController().signal),
    ).resolves.toBe("upstream_error");

    const failed = new SessionPromptAdapter({
      baseUrl: new URL("http://127.0.0.1:1142/"),
      directory: "/work/notify",
      fetch: vi.fn(() => {
        throw new Error("connection lost");
      }) as typeof fetch,
    });
    await expect(
      failed.send(SESSION_ID, TEXT, new AbortController().signal),
    ).resolves.toBe("result_unknown");
  });

  it("never exposes the prompt text through a status", async () => {
    const adapter = new SessionPromptAdapter({
      baseUrl: new URL("http://127.0.0.1:1142/"),
      directory: "/work/notify",
      fetch: vi.fn(() => {
        throw new Error(`sensitive prompt: ${TEXT}`);
      }) as typeof fetch,
    });
    const status = await adapter.send(SESSION_ID, TEXT, new AbortController().signal);
    expect(status).toBe("result_unknown");
    expect(JSON.stringify(status)).not.toContain(TEXT);
  });
});
