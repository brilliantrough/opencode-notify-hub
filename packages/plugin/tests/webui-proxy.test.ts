import { describe, expect, it, vi } from "vitest";

import type { WebUiHttpRequest, WebUiResponseFrame } from "../src/control-channel.js";
import { WebUiProxy } from "../src/webui-proxy.js";

const request: WebUiHttpRequest = {
  tunnelId: "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
  requestId: "7f0d91b0-93e4-43a9-9449-0bed03e651aa",
  method: "POST",
  path: "/api/session/ses_1/prompt?mode=steer",
  headers: {
    host: ["127.0.0.1:9000"],
    cookie: ["session=abc"],
    "accept-encoding": ["gzip"],
  },
  body: Buffer.from("prompt-body").toString("base64"),
};

describe("WebUiProxy", () => {
  it("forwards one HTTP request to the local OpenCode origin and streams the response", async () => {
    const fetchMock = vi.fn(async (_url: URL | RequestInfo, init?: RequestInit) => {
      expect(init?.method).toBe("POST");
      const headers = new Headers(init?.headers);
      expect(headers.get("host")).toBeNull();
      expect(headers.get("accept-encoding")).toBeNull();
      expect(headers.get("cookie")).toBe("session=abc");
      expect(headers.get("x-opencode-directory")).toBe("/work/notify");
      expect(Buffer.from(init?.body as Uint8Array).toString("utf8")).toBe("prompt-body");
      return new Response("ok", {
        status: 201,
        headers: { "content-type": "text/plain", "content-length": "2" },
      });
    });
    const frames: WebUiResponseFrame[] = [];
    const proxy = new WebUiProxy({
      baseUrl: new URL("http://127.0.0.1:4096/"),
      directory: "/work/notify",
      fetch: fetchMock as typeof fetch,
    });

    await proxy.request(request, new AbortController().signal, (frame) => frames.push(frame));

    expect(fetchMock.mock.calls[0][0].toString()).toBe(
      "http://127.0.0.1:4096/api/session/ses_1/prompt?mode=steer",
    );
    expect(frames[0]).toMatchObject({
      type: "webui_http_response_start",
      status: 201,
      headers: { "content-type": ["text/plain"] },
    });
    expect(frames[1]).toMatchObject({
      type: "webui_http_response_chunk",
      body: Buffer.from("ok").toString("base64"),
    });
    expect(frames[2]).toMatchObject({ type: "webui_http_response_end" });
  });

  it("splits large response chunks below the control-frame ceiling", async () => {
    const bytes = new Uint8Array(900_001).fill(65);
    const proxy = new WebUiProxy({
      baseUrl: new URL("http://127.0.0.1:4096/"),
      directory: "/work/notify",
      fetch: vi.fn(async () => new Response(bytes)) as typeof fetch,
    });
    const frames: WebUiResponseFrame[] = [];

    await proxy.request(
      { ...request, method: "GET", body: undefined },
      new AbortController().signal,
      (frame) => frames.push(frame),
    );

    const chunks = frames.filter((frame) => frame.type === "webui_http_response_chunk");
    expect(chunks).toHaveLength(3);
    expect(
      Buffer.concat(chunks.map((frame) => Buffer.from(frame.body, "base64"))).length,
    ).toBe(bytes.length);
  });
});
