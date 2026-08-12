/**
 * Assistant-only message-text cache.
 *
 * OpenCode delivers a message's role (`message.updated`) and its text
 * (`message.part.updated`) as separate events, in either order. This cache
 * joins them by (sessionID, messageID) so the emitter can attach the
 * latest assistant reply to a terminal envelope as its `summary`.
 *
 * Privacy is the hard rule: ONLY assistant-role text may ever surface as a
 * summary. User text, user metadata, and tool output are never retained
 * once the role is known:
 * - Text for a message already known to be `user` is dropped on arrival.
 * - Text that arrived BEFORE the role is held provisionally; a later
 *   `user` role deletes it, a later `assistant` role makes it eligible.
 * - Role events are last-write-wins: an `assistant -> user` flip deletes
 *   the stored text (removing eligibility permanently — a flip back does
 *   not resurrect it).
 *
 * Semantics:
 * - Repeated streaming updates for a message REPLACE the full text (each
 *   part update carries the complete text snapshot, never a delta).
 * - The summary is the text of the latest eligible assistant message in
 *   the session: most recent activity wins, and empty/whitespace-only
 *   text is ineligible (the scan falls through to an earlier message).
 *
 * Memory is bounded three ways (all code-point safe): retained text is
 * truncated to `maxTextLength` (default 500, the contract's summary cap),
 * each session keeps at most `maxMessagesPerSession` message records
 * (default 100, least-recently-active evicted), and at most `maxSessions`
 * sessions are retained (default 1000, oldest evicted). `clearSession` /
 * `clear` support the session lifecycle.
 */

/** Default per-session bound on retained message records. */
export const DEFAULT_MAX_MESSAGES_PER_SESSION = 100;
/** Default bound on retained text per message, in code points. */
export const DEFAULT_MAX_TEXT_LENGTH = 500;
/** Default bound on retained sessions. */
export const DEFAULT_MAX_SESSIONS = 1000;

export interface MessageCacheOptions {
  maxMessagesPerSession?: number;
  maxTextLength?: number;
  maxSessions?: number;
}

interface MessageRecord {
  role?: "user" | "assistant";
  text?: string;
}

/** Truncate to `max` code points, never splitting a surrogate pair. */
function truncateCodePoints(text: string, max: number): string {
  const points = Array.from(text);
  return points.length <= max ? text : points.slice(0, max).join("");
}

function boundedPositive(value: number, name: string): number {
  if (!Number.isInteger(value) || value <= 0) {
    throw new RangeError(`MessageCache ${name} must be a positive integer, got ${value}`);
  }
  return value;
}

export class MessageCache {
  private readonly sessions = new Map<string, Map<string, MessageRecord>>();
  private readonly maxMessagesPerSession: number;
  private readonly maxTextLength: number;
  private readonly maxSessions: number;

  constructor(options: MessageCacheOptions = {}) {
    this.maxMessagesPerSession = boundedPositive(
      options.maxMessagesPerSession ?? DEFAULT_MAX_MESSAGES_PER_SESSION,
      "maxMessagesPerSession",
    );
    this.maxTextLength = boundedPositive(
      options.maxTextLength ?? DEFAULT_MAX_TEXT_LENGTH,
      "maxTextLength",
    );
    this.maxSessions = boundedPositive(options.maxSessions ?? DEFAULT_MAX_SESSIONS, "maxSessions");
  }

  /**
   * Record a message's role (last-write-wins). A `user` role deletes any
   * stored text for the message: user content is never retained, and a
   * later flip back to `assistant` does not resurrect it.
   */
  onRole(sessionID: string, messageID: string, role: "user" | "assistant"): void {
    const record = this.touch(this.recordsFor(sessionID), messageID);
    record.role = role;
    if (role === "user") {
      delete record.text;
    }
  }

  /**
   * Record a full text snapshot for a message (replacing any previous
   * one). Text for a message already known to be a user message is
   * dropped on arrival; text of unknown role is held provisionally until
   * the role arrives.
   */
  onText(sessionID: string, messageID: string, text: string): void {
    const record = this.touch(this.recordsFor(sessionID), messageID);
    if (record.role === "user") {
      return;
    }
    record.text = truncateCodePoints(text, this.maxTextLength);
  }

  /**
   * The latest eligible assistant text for the session: the most recently
   * active assistant message with nonempty (non-whitespace) text, or
   * `undefined` when none exists.
   */
  summary(sessionID: string): string | undefined {
    const records = this.sessions.get(sessionID);
    if (records === undefined) {
      return undefined;
    }
    // Scan most-recent-first: the first eligible record wins.
    const ordered = Array.from(records.values());
    for (let i = ordered.length - 1; i >= 0; i -= 1) {
      const record = ordered[i];
      if (
        record.role === "assistant" &&
        record.text !== undefined &&
        record.text.trim().length > 0
      ) {
        return record.text;
      }
    }
    return undefined;
  }

  /** Drop all retained state for one session (session lifecycle). */
  clearSession(sessionID: string): void {
    this.sessions.delete(sessionID);
  }

  /** Drop all retained state (plugin shutdown). */
  clear(): void {
    this.sessions.clear();
  }

  /** Get or create the session's record map, evicting the oldest session beyond the cap. */
  private recordsFor(sessionID: string): Map<string, MessageRecord> {
    let records = this.sessions.get(sessionID);
    if (records === undefined) {
      records = new Map();
      this.sessions.set(sessionID, records);
      while (this.sessions.size > this.maxSessions) {
        const oldest = this.sessions.keys().next().value as string;
        this.sessions.delete(oldest);
      }
    }
    return records;
  }

  /**
   * Get or create the message's record and mark it most recently active
   * (moved to the map's tail), evicting the least recently active record
   * beyond the per-session cap.
   */
  private touch(records: Map<string, MessageRecord>, messageID: string): MessageRecord {
    let record = records.get(messageID);
    if (record === undefined) {
      record = {};
      records.set(messageID, record);
    } else {
      records.delete(messageID);
      records.set(messageID, record);
    }
    while (records.size > this.maxMessagesPerSession) {
      const oldest = records.keys().next().value as string;
      records.delete(oldest);
    }
    return record;
  }
}
