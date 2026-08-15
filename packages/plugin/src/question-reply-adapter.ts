/**
 * Question-reply adapter.
 *
 * The write slice of remote unblock: this adapter submits one complete,
 * ordered answer set to the owning OpenCode instance's authoritative
 * `/question/{requestID}/reply` endpoint through the V2 SDK and maps the
 * upstream outcome onto the strict contract `QuestionCommandStatus`.
 *
 * Guarantees:
 * - **Exact pass-through.** The `answers` `string[][]` is handed to the
 *   SDK verbatim, in exact upstream question order, never copied,
 *   reordered, or otherwise transformed.
 * - **Instance-scoped.** Every reply call passes the plugin's own
 *   `directory`, so one machine with several Servers never answers another
 *   Server's request.
 * - **Terminal mapping.** `{ data: true }` means OpenCode applied the
 *   answers (`confirmed`); a `QuestionNotFoundError` envelope means the
 *   request was already resolved (`stale`); any other SDK error envelope
 *   is an upstream rejection (`upstream_error`); and a thrown call, an
 *   aborted signal, a transport failure, or an unclassifiable response is
 *   `result_unknown` — the outcome could not be determined.
 * - **No reject, no logging.** The adapter never calls `question.reject`
 *   and has no logger at all: answer bodies cannot leave the process
 *   through this seam.
 * - **Never throws.** Every failure path resolves to a terminal status, so
 *   the control channel can report it without an unhandled rejection.
 */

import type { QuestionCommandStatus } from "@notify/contracts";

/** Minimal structural surface of the OpenCode V2 SDK question reply endpoint. */
export interface QuestionReplyClient {
  question: {
    reply(
      parameters?: {
        requestID?: string;
        directory?: string;
        answers?: string[][];
      },
      options?: { signal?: AbortSignal },
    ): Promise<unknown>;
  };
}

export interface QuestionReplyAdapterOptions {
  /** V2 SDK client exposing `question.reply`. */
  client: QuestionReplyClient;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

/**
 * Map one SDK response to the contract status. Only a literal `data:
 * true` confirms success; every other outcome is either an upstream error
 * (`_tag`-carrying envelope) or unknown (transport failure, non-confirmed
 * data). Never throws.
 */
function mapReply(response: unknown): QuestionCommandStatus {
  if (!isRecord(response)) {
    return "result_unknown";
  }
  if (response.error !== undefined && response.error !== null) {
    const error = response.error;
    if (isRecord(error) && typeof error._tag === "string") {
      // An SDK error envelope: 404 means the request is already resolved.
      return error._tag === "QuestionNotFoundError" ? "stale" : "upstream_error";
    }
    // A transport-level failure (abort, DNS, TLS) has no `_tag`; the
    // upstream outcome cannot be determined.
    return "result_unknown";
  }
  return response.data === true ? "confirmed" : "result_unknown";
}

export class QuestionReplyAdapter {
  private readonly client: QuestionReplyClient;

  constructor(options: QuestionReplyAdapterOptions) {
    this.client = options.client;
  }

  /**
   * Submit one exact ordered answer set to the owning instance. Never
   * throws: every outcome maps to a terminal {@link QuestionCommandStatus}.
   * The caller owns the abort signal (the control channel bounds it).
   */
  async reply(
    requestId: string,
    directory: string,
    answers: string[][],
    signal: AbortSignal,
  ): Promise<QuestionCommandStatus> {
    let response: unknown;
    try {
      response = await this.client.question.reply(
        { requestID: requestId, directory, answers },
        { signal },
      );
    } catch {
      return "result_unknown";
    }
    return mapReply(response);
  }
}
