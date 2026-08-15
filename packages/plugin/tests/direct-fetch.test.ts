import { createServer, type Server } from "node:http";

import { afterEach, describe, expect, it } from "vitest";

import { createLoopbackDirectFetch } from "../src/direct-fetch.js";

describe("createLoopbackDirectFetch", () => {
  let server: Server | null = null;

  afterEach(async () => {
    if (server !== null) {
      await new Promise<void>((resolve) => server!.close(() => resolve()));
      server = null;
    }
  });

  async function serve(
    handler: (req: { method?: string; body: string }, res: import("node:http").ServerResponse) => void,
  ): Promise<string> {
    server = createServer((req, res) => {
      const chunks: Buffer[] = [];
      req.on("data", (chunk) => chunks.push(chunk));
      req.on("end", () => handler({ method: req.method, body: Buffer.concat(chunks).toString() }, res));
    });
    await new Promise<void>((resolve) => server!.listen(0, "127.0.0.1", resolve));
    const address = server!.address();
    if (address === null || typeof address === "string") {
      throw new Error("no ephemeral port");
    }
    return `http://127.0.0.1:${address.port}`;
  }

  it("performs a GET against a real loopback server with a Request object", async () => {
    const base = await serve((req, res) => {
      res.writeHead(200, { "content-type": "application/json" });
      res.end(JSON.stringify({ healthy: true, method: req.method }));
    });
    const fetchDirect = createLoopbackDirectFetch();

    const response = await fetchDirect(new Request(`${base}/global/health`));

    expect(response.status).toBe(200);
    await expect(response.json()).resolves.toEqual({ healthy: true, method: "GET" });
  });

  it("posts a JSON body and honors abort signals", async () => {
    const base = await serve((req, res) => {
      res.writeHead(200);
      res.end(JSON.stringify({ echo: req.body, method: req.method }));
    });
    const fetchDirect = createLoopbackDirectFetch();

    const response = await fetchDirect(
      new Request(`${base}/question/req_1/reply`, {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ answers: [["A"]] }),
      }),
    );
    await expect(response.json()).resolves.toEqual({
      echo: '{"answers":[["A"]]}',
      method: "POST",
    });

    const aborted = new AbortController();
    aborted.abort();
    await expect(
      fetchDirect(new Request(`${base}/slow`, { signal: aborted.signal })),
    ).rejects.toMatchObject({ name: "AbortError" });
  });

  it("does not consult proxy environment variables for http loopback URLs", async () => {
    const base = await serve((_req, res) => {
      res.writeHead(200);
      res.end("direct");
    });
    const fetchDirect = createLoopbackDirectFetch();
    const previous = process.env.HTTP_PROXY;
    process.env.HTTP_PROXY = "http://127.0.0.1:9";
    try {
      const response = await fetchDirect(`${base}/health`);
      expect(response.status).toBe(200);
      await expect(response.text()).resolves.toBe("direct");
    } finally {
      if (previous === undefined) {
        delete process.env.HTTP_PROXY;
      } else {
        process.env.HTTP_PROXY = previous;
      }
    }
  });
});
