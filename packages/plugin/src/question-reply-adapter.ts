/**
 * Question-reply adapter.
 *
 * The write slice of remote unblock: this adapter submits one complete,
 * ordered answer set to the owning OpenCode instance's authoritative
 * pending-question store through the V2 SDK and maps the upstream outcome
 * onto the strict contract `QuestionCommandStatus`.
 *
 * The command carries the `sessionID` captured from the original
 * `question.asked` projection, so the adapter calls the session-scoped reply
 * (`v2.session.question.reply`) directly. OpenCode is the only authority: a
 * request already handled locally is reported as stale by that reply call.
 *
 * Guarantees:
 * - **Exact pass-through.** The `answers` `string[][]` is handed to the
 *   SDK verbatim, in exact upstream question order, never copied,
 *   reordered, or otherwise transformed.
 * - **Instance-scoped.** The V2 client belongs to the registered Plugin
 *   instance; the command also names the exact session and request.
 * - **Terminal mapping.** A non-error success envelope means OpenCode
 *   applied the answers (`confirmed`) — the V2 reply is a 204 with no
 *   body, so `data` may be undefined or empty; a `QuestionNotFoundError`
 *   or `SessionNotFoundError` envelope means the request was already
 *   resolved (`stale`); any other SDK error envelope is an upstream rejection
 *   (`upstream_error`); and a thrown reply call, aborted signal, or transport
 *   failure is `result_unknown` — the outcome could not be determined.
 * - **No reject, no logging.** The adapter never calls a question-reject
 *   endpoint and has no logger at all: answer bodies cannot leave the
 *   process through this seam.
 * - **Never throws.** Every failure path resolves to a terminal status, so
 *   the control channel can report it without an unhandled rejection.
 */

import type { QuestionCommandStatus } from "@notify/contracts";

/** Minimal structural surface of the OpenCode V2 SDK question reply endpoint. */
export interface QuestionReplyClient {
  session: {
    question: {
      reply(
        parameters: {
          sessionID: string;
          requestID: string;
          questionV2Reply: { answers: string[][] };
        },
        options?: { signal?: AbortSignal },
      ): Promise<unknown>;
    };
  };
}

export interface QuestionReplyAdapterOptions {
  /** V2 SDK client exposing `session.question.reply`. */
  client: QuestionReplyClient;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

/**
 * Map one reply response to the contract status. Any non-error success
 * envelope confirms (the V2 reply is a 204 with `data` undefined); an
 * `_tag`-carrying error envelope is `stale` only for the exact
 * `QuestionNotFoundError` or `SessionNotFoundError` tags and
 * `upstream_error` otherwise; everything else is `result_unknown`. Never
 * throws.
 */
function mapReply(response: unknown): QuestionCommandStatus {
  if (!isRecord(response)) {
    return "result_unknown";
  }
  if (response.error !== undefined && response.error !== null) {
    const error = response.error;
    if (isRecord(error) && typeof error._tag === "string") {
      const tag = error._tag;
      // Both 404 tags mean the request was already resolved.
      return tag === "QuestionNotFoundError" || tag === "SessionNotFoundError"
        ? "stale"
        : "upstream_error";
    }
    // A transport-level failure (abort, DNS, TLS) has no `_tag`; the
    // upstream outcome cannot be determined.
    return "result_unknown";
  }
  return "confirmed";
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
    sessionID: string,
    answers: string[][],
    signal: AbortSignal,
  ): Promise<QuestionCommandStatus> {
    let response: unknown;
    try {
      response = await this.client.session.question.reply(
        { sessionID, requestID: requestId, questionV2Reply: { answers } },
        { signal },
      );
    } catch {
      return "result_unknown";
    }
    return mapReply(response);
  }
}
