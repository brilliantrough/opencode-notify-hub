/**
 * Permission-reply adapter.
 *
 * The write slice of remote unblock for permissions: this adapter submits
 * one complete, ordered decision to the owning OpenCode instance's
 * authoritative pending-permission store through the V2 SDK and maps the
 * upstream outcome onto the strict contract `PermissionCommandStatus`.
 *
 * The command carries only a `requestId`, so the adapter first reads the
 * location-scoped pending-permission list (`v2.permission.request.list`) to
 * confirm the request is still pending and learn its owning session; only
 * then does it call the session-scoped reply
 * (`v2.session.permission.reply`). This mirrors the plugin's read and
 * write paths exactly and works against the natural pending store of
 * 1.18.18, where the V1 global `/permission` list is empty and
 * `/permission/{requestID}/reply` answers 404.
 *
 * Guarantees:
 * - **Exact pass-through.** The `decision` (`"once"` | `"always"` | `"reject"`)
 *   is handed to the SDK verbatim. The installed V2 SDK declares the reply
 *   body as `"once" | "always" | "reject"`, so `always` needs no special
 *   handling here beyond passing it through.
 * - **Instance-scoped.** Every list and reply call passes the plugin's own
 *   `directory`, so one machine with several Servers never answers another
 *   Server's request.
 * - **Terminal mapping.** Any non-error success envelope means OpenCode
 *   applied the decision (`confirmed`) — the V2 reply is a 204 with no
 *   body, so `data` may be undefined or empty; a `PermissionNotFoundError`
 *   or `SessionNotFoundError` envelope means the request was already
 *   resolved (`stale`); a missing request in the pending list is also
 *   `stale` (no reply call is made); any other SDK error envelope is an
 *   upstream rejection (`upstream_error`); and a thrown list/reply call,
 *   an aborted signal, a transport failure, an unavailable or malformed
 *   list is `result_unknown` — the outcome could not be determined. A
 *   literal `data: false` body is typed-possible but not confirmation and
 *   also maps to `result_unknown`.
 * - **No reject, no logging.** The adapter never calls a permission-reject
 *   API and has no logger at all: decision bodies cannot leave the process
 *   through this seam.
 * - **Never throws.** Every failure path resolves to a terminal status, so
 *   the control channel can report it without an unhandled rejection.
 */

import type { PermissionCommandStatus, PermissionDecision } from "@notify/contracts";

/** Minimal structural surface of the OpenCode V2 SDK permission endpoints. */
export interface PermissionReplyClient {
  permission: {
    request: {
      list(
        params?: { location?: { directory?: string; workspace?: string } },
        options?: { signal?: AbortSignal },
      ): Promise<unknown>;
    };
  };
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
  /** V2 SDK client exposing `permission.request.list` / `session.permission.reply`. */
  client: PermissionReplyClient;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function asNonEmptyString(value: unknown): string | null {
  return typeof value === "string" && value.length > 0 ? value : null;
}

/**
 * Extract the pending-permission request array from the `{ data, error }`
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
    directory: string,
    decision: PermissionDecision,
    signal: AbortSignal,
  ): Promise<PermissionCommandStatus> {
    let listResponse: unknown;
    try {
      listResponse = await this.client.permission.request.list(
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
