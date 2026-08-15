/**
 * Loopback-direct fetch for the Plugin's OpenCode SDK client (issue #14).
 *
 * The plugin host process may run with `HTTP_PROXY`/`ALL_PROXY` set and no
 * `no_proxy` entry for localhost (common on developer machines with a local
 * proxy). A proxy-aware global fetch then routes loopback calls to
 * `input.serverUrl` through the proxy, which answers 502 — observed on a
 * real 1.18.18 TUI where every embedded-server call failed this way.
 * Plugin→OpenCode traffic is always loopback and must never traverse a
 * proxy, so the SDK client is constructed with this fetch: plain `node:http`
 * for `http://` URLs, the global fetch for anything else.
 */

import { request as httpRequest } from "node:http";

/** Fetch-compatible function that bypasses proxies for http:// loopback URLs. */
export function createLoopbackDirectFetch(): typeof fetch {
  return (async (input: unknown, init?: unknown): Promise<Response> => {
    const request = await toRequestParts(input, init);
    if (!request.url.startsWith("http://")) {
      const globalFetch = globalThis.fetch as unknown as (
        input: unknown,
        init?: unknown,
      ) => Promise<Response>;
      return globalFetch(input as never, init as never);
    }
    return directHttp(request);
  }) as typeof fetch;
}

interface RequestParts {
  url: string;
  method: string;
  headers: Record<string, string>;
  body: string | null;
  signal: AbortSignal | null;
}

async function toRequestParts(input: unknown, init: unknown): Promise<RequestParts> {
  if (input instanceof Request) {
    return {
      url: input.url,
      method: input.method,
      headers: Object.fromEntries(input.headers.entries()),
      body: input.method === "GET" || input.method === "HEAD" ? null : await input.text(),
      signal: input.signal,
    };
  }
  const url = typeof input === "string" ? input : String((input as { url?: unknown })?.url ?? input);
  const options = (init ?? {}) as {
    method?: string;
    headers?: Record<string, string> | Headers;
    body?: string | null;
    signal?: AbortSignal | null;
  };
  const headers =
    options.headers instanceof Headers
      ? Object.fromEntries(options.headers.entries())
      : { ...(options.headers ?? {}) };
  return {
    url,
    method: options.method ?? "GET",
    headers,
    body: options.body ?? null,
    signal: options.signal ?? null,
  };
}

function directHttp(parts: RequestParts): Promise<Response> {
  return new Promise((resolve, reject) => {
    const request = httpRequest(
      parts.url,
      {
        method: parts.method,
        headers: parts.headers,
        // Never consult proxy environment for this hop.
      },
      (response) => {
        const chunks: Buffer[] = [];
        response.on("data", (chunk: Buffer) => chunks.push(chunk));
        response.on("end", () => {
          const headers = new Headers();
          for (const [name, value] of Object.entries(response.headers)) {
            if (typeof value === "string") {
              headers.set(name, value);
            } else if (Array.isArray(value)) {
              for (const entry of value) {
                headers.append(name, entry);
              }
            }
          }
          resolve(
            new Response(Buffer.concat(chunks), {
              status: response.statusCode ?? 0,
              statusText: response.statusMessage ?? "",
              headers,
            }),
          );
        });
        response.on("error", reject);
      },
    );
    request.on("error", reject);
    if (parts.signal !== null) {
      if (parts.signal.aborted) {
        request.destroy(new DOMException("The operation was aborted.", "AbortError"));
        return;
      }
      parts.signal.addEventListener(
        "abort",
        () => request.destroy(new DOMException("The operation was aborted.", "AbortError")),
        { once: true },
      );
    }
    if (parts.body !== null) {
      request.write(parts.body);
    }
    request.end();
  });
}
