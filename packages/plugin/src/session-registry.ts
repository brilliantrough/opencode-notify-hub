/**
 * Main-session ancestry registry.
 *
 * The plugin only notifies for top-level sessions. Ancestry usually arrives
 * on the event bus (`session.created` / `session.updated` carry a
 * `parentID`), but the first event for a session can be something else, so a
 * cache miss falls back to one SDK `session.get` call per session.
 *
 * Semantics (fail-closed throughout — `isMain` never throws):
 * - cached `parentID` string  → child session, `isMain` → `false`
 * - cached `parentID` null    → top-level session, `isMain` → `true`
 * - cache miss                → one SDK lookup, result cached
 * - lookup error / malformed  → unknown, `isMain` → `null`, NOT cached, so
 *   a later call retries. Unknown is never reported as main.
 *
 * Concurrent misses for the same session coalesce into a single in-flight
 * SDK call; the in-flight entry is cleared on success and on failure. An
 * upsert that arrives while a lookup is in flight wins over the (staler)
 * SDK answer.
 */

/**
 * Ancestry lookup. Returns the session's `parentID` (string for a child,
 * `null` for a top-level session) or `undefined` when ancestry is unknown
 * (transport error, malformed response). `undefined` results are never
 * cached as main; they are not cached at all.
 */
export interface SessionLookup {
  getParentID(sessionID: string): Promise<string | null | undefined>;
}

/**
 * Minimal structural type of the SDK session subclient (`client.session`).
 * Accepting the subclient object — rather than a detached `get` method —
 * keeps `this` bound naturally: the generated SDK methods read
 * `this._client`, so an unbound method reference would throw. Declared with
 * method syntax so the SDK's generic `get` stays assignable.
 */
export interface SessionGetClient {
  get(options: { path: { id: string } }): Promise<unknown>;
}

interface CacheEntry {
  /** `undefined` = ancestry not yet known. */
  parentID?: string | null;
  title?: string;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

export class SessionRegistry {
  private readonly entries = new Map<string, CacheEntry>();
  private readonly inflight = new Map<string, Promise<boolean | null>>();

  constructor(private readonly lookup: SessionLookup) {}

  /**
   * Record ancestry (and optionally the title) from a session upsert.
   * Events are authoritative: this overwrites any previously cached or
   * in-flight ancestry for the session.
   */
  update(sessionID: string, parentID: string | null, title?: string): void {
    const entry = this.entries.get(sessionID) ?? {};
    entry.parentID = parentID;
    if (title !== undefined) {
      entry.title = title;
    }
    this.entries.set(sessionID, entry);
  }

  /** The last title seen for the session, if any. */
  title(sessionID: string): string | undefined {
    return this.entries.get(sessionID)?.title;
  }

  /**
   * Whether the session is top-level. Returns `null` when ancestry is
   * unknown (failed/malformed lookup). Never throws, never rejects.
   */
  async isMain(sessionID: string): Promise<boolean | null> {
    try {
      const entry = this.entries.get(sessionID);
      if (entry?.parentID !== undefined) {
        return entry.parentID === null;
      }
      const pending = this.inflight.get(sessionID);
      if (pending !== undefined) {
        return pending;
      }
      const promise = this.resolve(sessionID);
      this.inflight.set(sessionID, promise);
      try {
        return await promise;
      } finally {
        this.inflight.delete(sessionID);
      }
    } catch {
      return null;
    }
  }

  /**
   * One SDK lookup for a cache miss. Unknown results stay uncached so the
   * next call retries. An upsert that landed while the lookup was in flight
   * (entry now has ancestry) wins over the SDK answer.
   */
  private async resolve(sessionID: string): Promise<boolean | null> {
    let parentID: string | null | undefined;
    try {
      parentID = await this.lookup.getParentID(sessionID);
    } catch {
      parentID = undefined;
    }
    // An upsert that landed while the lookup was in flight (entry now has
    // ancestry) wins over the SDK answer — and over its failure.
    const entry = this.entries.get(sessionID);
    if (entry?.parentID !== undefined) {
      return entry.parentID === null;
    }
    if (parentID === undefined) {
      return null;
    }
    this.entries.set(sessionID, { ...entry, parentID });
    return parentID === null;
  }
}

/**
 * Adapt the SDK session subclient (`client.session`) into a
 * {@link SessionLookup}: `createSdkLookup(client.session)`.
 *
 * The response may be a `{ data: session }` envelope or the session object
 * directly. The returned session's `id` must equal the requested
 * `sessionID`; a mismatch is treated as unknown (and never cached), so a
 * confused or stale response can never mark the wrong session as main.
 *
 * SDK error envelopes are recognized explicitly: a non-nullish `error`
 * property on the response means the request failed (`{ data, error, ... }`
 * in the SDK's non-throwing mode) and is unknown regardless of what `data`
 * holds. A `data`-carrying response with `error: undefined` is still valid.
 *
 * Anything else — rejection, non-record payload, missing `id`, or a
 * non-string/non-null `parentID` — is unknown (`undefined`), never main.
 */
export function createSdkLookup(sessionClient: SessionGetClient): SessionLookup {
  return {
    async getParentID(sessionID: string): Promise<string | null | undefined> {
      let response: unknown;
      try {
        response = await sessionClient.get({ path: { id: sessionID } });
      } catch {
        return undefined;
      }
      if (isRecord(response) && response.error != null) {
        // SDK error envelope: the request failed; nothing here is a session.
        return undefined;
      }
      const session =
        isRecord(response) && isRecord(response.data) ? response.data : response;
      if (!isRecord(session) || session.id !== sessionID) {
        return undefined;
      }
      const parentID = session.parentID;
      if (typeof parentID === "string" && parentID.length > 0) {
        return parentID;
      }
      if (parentID === null || parentID === undefined) {
        return null;
      }
      return undefined;
    },
  };
}
