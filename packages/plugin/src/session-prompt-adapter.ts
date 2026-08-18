import type { PromptCommandStatus } from "@notify/contracts";

/** Minimal structural surface of the OpenCode V2 Session prompt endpoint. */
export interface SessionPromptClient {
  session: {
    prompt(
      parameters: { sessionID: string; prompt: { text: string } },
      options?: { signal?: AbortSignal },
    ): Promise<unknown>;
  };
}

export class SessionPromptAdapter {
  constructor(private readonly client: SessionPromptClient) {}

  /** Send one exact text prompt. Every failure becomes an explicit status. */
  async send(
    sessionID: string,
    text: string,
    signal: AbortSignal,
  ): Promise<PromptCommandStatus> {
    let response: unknown;
    try {
      response = await this.client.session.prompt(
        { sessionID, prompt: { text } },
        { signal },
      );
    } catch {
      return "result_unknown";
    }
    if (response === null || typeof response !== "object" || Array.isArray(response)) {
      return "result_unknown";
    }
    const error = (response as Record<string, unknown>).error;
    if (error === undefined || error === null) {
      return "confirmed";
    }
    return error instanceof TypeError ? "result_unknown" : "upstream_error";
  }
}
