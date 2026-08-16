/**
 * Permission-reply adapter.
 *
 * The write slice of remote unblock for permissions: this adapter submits
 * one complete, ordered decision to the owning OpenCode instance's
 * authoritative pending-permission store through the V2 SDK and maps the
 * upstream outcome onto the strict contract `PermissionCommandStatus`.
 *
 * The command carries the `sessionID` captured from the original
 * `permission.asked` projection, so the adapter calls the session-scoped
 * reply (`v2.session.permission.reply`) directly. OpenCode is the only
 * authority: a request already handled locally is reported as stale by that
 * reply call.
 *
 * Guarantees:
 * - **Exact pass-through.** The `decision` (`"once"` | `"always"` | `"reject"`)
 *   is handed to the SDK verbatim. The installed V2 SDK declares the reply
 *   body as `"once" | "always" | "reject"`, so `always` needs no special
 *   handling here beyond passing it through.
 * - **Instance-scoped.** The V2 client belongs to the registered Plugin
 *   instance; the command also names the exact session and request.
 * - **Terminal mapping.** Any non-error success envelope means OpenCode
 *   applied the decision (`confirmed`) — the V2 reply is a 204 with no
 *   body, so `data` may be undefined or empty; a `PermissionNotFoundError`
 *   or `SessionNotFoundError` envelope means the request was already
 *   resolved (`stale`); any other SDK error envelope is an upstream rejection
 *   (`upstream_error`); and a thrown reply call, aborted signal, or transport
 *   failure is `result_unknown` — the outcome could not be determined. A
 *   literal `data: false` body is typed-possible but not confirmation and
 *   also maps to `result_unknown`.
 * - **No reject, no logging.** The adapter never calls a permission-reject
 *   API and has no logger at all: decision bodies cannot leave the process
 *   through this seam.
 * - **Never throws.** Every failure path resolves to a terminal status, so
 *   the control channel can report it without an unhandled rejection.
 */

import type { PermissionCommandStatus, PermissionDecision } from "@notify/contracts";

/** Minimal structural surface of the OpenCode V2 SDK permission reply endpoint. */
export interface PermissionReplyClient {
  session: {
    permission: {
      reply(
        parameters: {
          sessionID: string;
          requestID: string;
          reply: PermissionDecision;
        },
        options?: { signal?: AbortSignal },
      ): Promise<unknown>;
    };
  };
}

export interface PermissionReplyAdapterOptions {
  /** V2 SDK client exposing `session.permission.reply`. */
  client: PermissionReplyClient;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

/**
 * Map one reply response to the contract status. Any non-error success
 * envelope confirms (the V2 reply is a 204 with `data` undefined); an
 * `_tag`-carrying error envelope is `stale` only for the exact
 * `PermissionNotFoundError` or `SessionNotFoundError` tags and
 * `upstream_error` otherwise; everything else is `result_unknown`. Never
 * throws.
 */
function mapDecision(response: unknown): PermissionCommandStatus {
  if (!isRecord(response)) {
    return "result_unknown";
  }
  if (response.error !== undefined && response.error !== null) {
    const error = response.error;
    if (isRecord(error) && typeof error._tag === "string") {
      const tag = error._tag;
      // Both 404 tags mean the request was already resolved.
      return tag === "PermissionNotFoundError" || tag === "SessionNotFoundError"
        ? "stale"
        : "upstream_error";
    }
    // A transport-level failure (abort, DNS, TLS) has no `_tag`; the
    // upstream outcome cannot be determined.
    return "result_unknown";
  }
  // A bare `data: false` is typed-possible (the SDK declares `200: boolean`)
  // but its meaning is not confirmation; report result_unknown instead of
  // dropping the pending request on a guess.
  if (response.data === false) {
    return "result_unknown";
  }
  // Any other non-error success envelope is confirmation, whether the
  // installed SDK yields `data: true` or another version returns an object.
  return "confirmed";
}

export class PermissionReplyAdapter {
  private readonly client: PermissionReplyClient;

  constructor(options: PermissionReplyAdapterOptions) {
    this.client = options.client;
  }

  /**
   * Submit one exact decision to the owning instance. Never throws: every
   * outcome maps to a terminal {@link PermissionCommandStatus}. The caller
   * owns the abort signal (the control channel bounds it).
   */
  async reply(
    requestId: string,
    sessionID: string,
    decision: PermissionDecision,
    signal: AbortSignal,
  ): Promise<PermissionCommandStatus> {
    let response: unknown;
    try {
      response = await this.client.session.permission.reply(
        { sessionID, requestID: requestId, reply: decision },
        { signal },
      );
    } catch {
      return "result_unknown";
    }
    return mapDecision(response);
  }
}
