import type { WebUiHttpRequest, WebUiResponseFrame } from "./control-channel.js";

const MAX_CHUNK_BYTES = 450_000;
const HOP_BY_HOP_HEADERS = new Set([
  "connection",
  "keep-alive",
  "proxy-authenticate",
  "proxy-authorization",
  "te",
  "trailer",
  "transfer-encoding",
  "upgrade",
]);

export interface WebUiProxyOptions {
  baseUrl: URL;
  directory: string;
  fetch?: typeof fetch;
  generation?: 1 | 2;
}

/** HTTP/SSE bridge from Gateway tunnel frames to the local OpenCode server. */
export class WebUiProxy {
  private readonly baseUrl: URL;
  private readonly directory: string;
  private readonly fetch: typeof fetch;
  private readonly generation: 1 | 2;

  constructor(options: WebUiProxyOptions) {
    this.baseUrl = options.baseUrl;
    this.directory = options.directory;
    this.fetch = options.fetch ?? fetch;
    this.generation = options.generation ?? 1;
  }

  async request(
    request: WebUiHttpRequest,
    signal: AbortSignal,
    emit: (frame: WebUiResponseFrame) => void,
  ): Promise<void> {
    const url = new URL(request.path, this.baseUrl);
    if (!request.path.startsWith("/") || request.path.startsWith("//") ||
        request.path.includes("\\") || url.origin !== this.baseUrl.origin) {
      throw new Error("WebUI requests must stay on the local OpenCode origin");
    }
    if (this.generation === 2) {
      // Older Notify clients open V1 deep links; translate in the browser's own origin.
      const legacy = /^\/([A-Za-z0-9_-]+)\/session(?:\/(ses[A-Za-z0-9_-]+))?$/.exec(url.pathname);
      if (request.method === "GET" && legacy && Buffer.from(legacy[1]!, "base64url").toString("utf8") === this.directory) {
        const session = legacy[2];
        const script = session
          ? `const key=btoa(location.origin).replace(/\\+/g,'-').replace(/\\//g,'_').replace(/=+$/,'');location.replace('/server/'+key+'/session/'+${JSON.stringify(session)});`
          : "location.replace('/');";
        emit({ type: "webui_http_response_start", tunnelId: request.tunnelId, requestId: request.requestId,
          status: 200, headers: { "content-type": ["text/html; charset=utf-8"], "cache-control": ["no-store"] } });
        emit({ type: "webui_http_response_chunk", tunnelId: request.tunnelId, requestId: request.requestId,
          body: Buffer.from(`<!doctype html><script>${script}</script>`).toString("base64") });
        emit({ type: "webui_http_response_end", tunnelId: request.tunnelId, requestId: request.requestId });
        return;
      }
    }
    if (this.generation === 1 && !url.searchParams.has("directory") && this.directory !== "unknown") {
      url.searchParams.set("directory", this.directory);
    }
    const headers = new Headers();
    for (const [name, values] of Object.entries(request.headers)) {
      const lower = name.toLowerCase();
      if (
        HOP_BY_HOP_HEADERS.has(lower) ||
        lower === "host" ||
        lower === "origin" ||
        lower === "referer"
      ) {
        continue;
      }
      if (lower === "accept-encoding") {
        continue;
      }
      for (const value of values) {
        headers.append(name, value);
      }
    }
    if (request.headers.origin !== undefined) {
      headers.set("origin", this.baseUrl.origin);
    }
    if (request.headers.referer !== undefined) {
      headers.set("referer", this.baseUrl.toString());
    }
    if (this.generation === 1) headers.set("x-opencode-directory", this.directory);
    const body = request.body === undefined ? undefined : Buffer.from(request.body, "base64");
    const response = await this.fetch(url, {
      method: request.method,
      headers,
      body,
      redirect: "manual",
      signal,
    });
    emit({
      type: "webui_http_response_start",
      tunnelId: request.tunnelId,
      requestId: request.requestId,
      status: response.status,
      headers: responseHeaders(response.headers),
    });
    if (response.body === null) {
      emit({
        type: "webui_http_response_end",
        tunnelId: request.tunnelId,
        requestId: request.requestId,
      });
      return;
    }
    const reader = response.body.getReader();
    try {
      for (;;) {
        const next = await reader.read();
        if (next.done) break;
        const bytes = next.value;
        for (let offset = 0; offset < bytes.length; offset += MAX_CHUNK_BYTES) {
          emit({
            type: "webui_http_response_chunk",
            tunnelId: request.tunnelId,
            requestId: request.requestId,
            body: Buffer.from(bytes.subarray(offset, offset + MAX_CHUNK_BYTES)).toString("base64"),
          });
        }
      }
    } finally {
      reader.releaseLock();
    }
    emit({
      type: "webui_http_response_end",
      tunnelId: request.tunnelId,
      requestId: request.requestId,
    });
  }
}

function responseHeaders(headers: Headers): Record<string, string[]> {
  const result: Record<string, string[]> = {};
  headers.forEach((value, name) => {
    if (
      !HOP_BY_HOP_HEADERS.has(name.toLowerCase()) &&
      name.toLowerCase() !== "content-length" &&
      name.toLowerCase() !== "content-encoding"
    ) {
      result[name] = [value];
    }
  });
  return result;
}
