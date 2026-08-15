/**
 * Question-reply adapter.
 *
 * The write slice of remote unblock: this adapter submits one complete,
 * ordered answer set to the owning OpenCode instance's authoritative
 * pending-question store through the V2 SDK and maps the upstream outcome
 * onto the strict contract `QuestionCommandStatus`.
 *
 * The command carries only a `requestId`, so the adapter first reads the
 * location-scoped pending-question list (`v2.question.request.list`) to
 * confirm the request is still pending and learn its owning session; only
 * then does it call the session-scoped reply
 * (`v2.session.question.reply`). This mirrors the plugin's read and write
 * paths exactly and works against the natural pending store of 1.18.18,
 * where the V1 global `/question` list is empty and `/question/{id}/reply`
 * answers 404.
 *
 * Guarantees:
 * - **Exact pass-through.** The `answers` `string[][]` is handed to the
 *   SDK verbatim, in exact upstream question order, never copied,
 *   reordered, or otherwise transformed.
 * - **Instance-scoped.** Every list and reply call passes the plugin's own
 *   `directory`, so one machine with several Servers never answers another
 *   Server's request.
 * - **Terminal mapping.** A non-error success envelope means OpenCode
 *   applied the answers (`confirmed`) — the V2 reply is a 204 with no
 *   body, so `data` may be undefined or empty; a `QuestionNotFoundError`
 *   or `SessionNotFoundError` envelope means the request was already
 *   resolved (`stale`); a missing request in the pending list is also
 *   `stale` (no reply call is made); any other SDK error envelope is an
 *   upstream rejection (`upstream_error`); and a thrown list/reply call,
 *   an aborted signal, a transport failure, an unavailable or malformed
 *   list is `result_unknown` — the outcome could not be determined.
 * - **No reject, no logging.** The adapter never calls a question-reject
 *   endpoint and has no logger at all: answer bodies cannot leave the
 *   process through this seam.
 * - **Never throws.** Every failure path resolves to a terminal status, so
 *   the control channel can report it without an unhandled rejection.
 */

import type { QuestionCommandStatus } from "@notify/contracts";

/** Minimal structural surface of the OpenCode V2 SDK question endpoints. */
export interface QuestionReplyClient {
  question: {
    request: {
      list(
        params?: { location?: { directory?: string; workspace?: string } },
        options?: { signal?: AbortSignal },
      ): Promise<unknown>;
    };
  };
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
  /** V2 SDK client exposing `question.request.list` / `session.question.reply`. */
  client: QuestionReplyClient;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function asNonEmptyString(value: unknown): string | null {
  return typeof value === "string" && value.length > 0 ? value : null;
}

/**
 * Extract the pending-question request array from the `{ data, error }`
 * envelope whose `data` is the `{ location, data }` list payload. Returns
 * `null` for an error envelope or a malformed shape, which the caller maps
 * to `result_unknown` (the list never confirmed the request state).
 */
function listRequests(response: unknown): unknown[] | null {
  if (!isRecord(response)) {
    return null;
  }
  if (response.error != null) {
    return null;
  }
  if (!isRecord(response.data)) {
    return null;
  }
  if (response.data.error != null) {
    return null;
  }
  return Array.isArray(response.data.data) ? response.data.data : null;
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
    directory: string,
    answers: string[][],
    signal: AbortSignal,
  ): Promise<QuestionCommandStatus> {
    let listResponse: unknown;
    try {
      listResponse = await this.client.question.request.list(
        { location: { directory } },
        { signal },
      );
    } catch {
      return "result_unknown";
    }
    const requests = listRequests(listResponse);
    if (requests === null) {
      // The list is unavailable or malformed; the request state could not
      // be confirmed, so the outcome is unknown.
      return "result_unknown";
    }
    let sessionID: string | null = null;
    for (const raw of requests) {
      if (isRecord(raw) && raw.id === requestId) {
        sessionID = asNonEmptyString(raw.sessionID);
        break;
      }
    }
    if (sessionID === null) {
      // Not pending any longer (or never ours): already resolved.
      return "stale";
    }

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
