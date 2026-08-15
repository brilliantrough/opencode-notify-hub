/**
 * Permission-reply adapter.
 *
 * The write slice of remote unblock for permissions: this adapter submits
 * one complete, ordered decision to the owning OpenCode instance's
 * authoritative `/permission/{requestID}/reply` endpoint through the V2 SDK
 * and maps the upstream outcome onto the strict contract
 * `PermissionCommandStatus`.
 *
 * Guarantees:
 * - **Exact pass-through.** The `decision` (`"once"` | `"always"` | `"reject"`)
 *   is handed to the SDK verbatim. The installed V2 SDK declares the reply
 *   body as `"once" | "always" | "reject"`, so `always` needs no special
 *   handling here beyond passing it through.
 * - **Instance-scoped.** Every reply call passes the plugin's own
 *   `directory`, so one machine with several Servers never answers another
 *   Server's request.
 * - **Terminal mapping.** Any success envelope (no `error`) means OpenCode
 *   applied the decision (`confirmed`); the installed V2 SDK declares the
 *   success body as a bare boolean, and some SDK versions return a data
 *   object instead, so any non-error success envelope counts as confirmed.
 *   A `PermissionNotFoundError` envelope means the request was already
 *   resolved (`stale`); any other SDK error envelope is an upstream
 *   rejection (`upstream_error`); and a thrown call, an aborted signal, a
 *   transport failure, or an unclassifiable response is `result_unknown` —
 *   the outcome could not be determined.
 * - **No reject, no logging.** The adapter never logs at all: decision
 *   bodies cannot leave the process through this seam.
 * - **Never throws.** Every failure path resolves to a terminal status, so
 *   the control channel can report it without an unhandled rejection.
 */

import type { PermissionCommandStatus, PermissionDecision } from "@notify/contracts";

/** Minimal structural surface of the OpenCode V2 SDK permission reply endpoint. */
export interface PermissionReplyClient {
  permission: {
    reply(
      parameters: {
        requestID: string;
        directory?: string;
        reply?: PermissionDecision;
      },
      options?: { signal?: AbortSignal },
    ): Promise<unknown>;
  };
}

export interface PermissionReplyAdapterOptions {
  /** V2 SDK client exposing `permission.reply`. */
  client: PermissionReplyClient;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

/**
 * Map one SDK response to the contract status. Any non-error success
 * envelope confirms; an `_tag`-carrying error envelope is `stale` only for
 * the exact `PermissionNotFoundError` tag and `upstream_error` otherwise;
 * everything else is `result_unknown`. Never throws.
 */
function mapDecision(response: unknown): PermissionCommandStatus {
  if (!isRecord(response)) {
    return "result_unknown";
  }
  if (response.error !== undefined && response.error !== null) {
    const error = response.error;
    if (isRecord(error) && typeof error._tag === "string") {
      // An SDK error envelope: 404 means the request is already resolved.
      return error._tag === "PermissionNotFoundError" ? "stale" : "upstream_error";
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
    directory: string,
    decision: PermissionDecision,
    signal: AbortSignal,
  ): Promise<PermissionCommandStatus> {
    let response: unknown;
    try {
      response = await this.client.permission.reply(
        { requestID: requestId, directory, reply: decision },
        { signal },
      );
    } catch {
      return "result_unknown";
    }
    return mapDecision(response);
  }
}
