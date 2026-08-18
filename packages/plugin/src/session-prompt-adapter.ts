import type { PromptCommandStatus } from "@notify/contracts";

export interface SessionPromptAdapterOptions {
  baseUrl: URL;
  directory: string;
  fetch?: typeof fetch;
}

export class SessionPromptAdapter {
  private readonly baseUrl: URL;
  private readonly directory: string;
  private readonly fetch: typeof fetch;

  constructor(options: SessionPromptAdapterOptions) {
    this.baseUrl = options.baseUrl;
    this.directory = options.directory;
    this.fetch = options.fetch ?? fetch;
  }

  /**
   * Start one exact text prompt through the V1 agent loop.
   *
   * The V2 input-admission endpoint accepts an input into its projection but
   * does not resume the TUI/WebUI loop started by `opencode --port`.
   */
  async send(
    sessionID: string,
    text: string,
    signal: AbortSignal,
  ): Promise<PromptCommandStatus> {
    const url = new URL(
      `/session/${encodeURIComponent(sessionID)}/prompt_async`,
      this.baseUrl,
    );
    url.searchParams.set("directory", this.directory);
    try {
      const response = await this.fetch(url, {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ parts: [{ type: "text", text }] }),
        signal,
      });
      return response.ok ? "confirmed" : "upstream_error";
    } catch {
      return "result_unknown";
    }
  }
}
