/**
 * Normalization of OpenCode runtime events into the plugin's internal
 * representation.
 *
 * The input is the `Event` union from `@opencode-ai/sdk` (1.18.15), but the
 * function is deliberately total: it accepts `unknown`, reads every field
 * defensively, and returns `null` for anything unrecognized or malformed.
 * It never throws and never logs, so values that may carry secrets
 * (permission metadata, error messages, tool input) cannot leak through an
 * output channel.
 *
 * Compatibility notes:
 * - SDK 1.18.15 types `permission.updated` / `permission.replied` with a
 *   `permissionID`; dev sources renamed the ask to `permission.asked` and
 *   moved to `requestID`/`reply`. Both are recognized.
 * - `question.asked` / `question.replied` / `question.rejected` exist only
 *   in dev sources; they are read structurally.
 * - `session.idle` is the deprecated idle marker; `session.status` with an
 *   `idle` payload is the modern form. Both normalize to the same event.
 */

/**
 * A provider action carried by a dev-source `session.status` retry payload
 * (`status.action`). SDK 1.18.15 types only `attempt`/`message`/`next`, so
 * the action is read structurally. `reason` is identity-only: downstream it
 * feeds the synthetic requestId/dedupe key and is never emitted.
 */
export interface RetryActionInfo {
  reason?: string;
  provider: string;
  title: string;
  message: string;
  label: string;
  link?: string;
}

/** Retry status carried by a `session.status` retry payload. */
export interface NormalizedRetry {
  attempt: number;
  message: string;
  next: number;
  action?: RetryActionInfo;
}

/** A question option reduced to its display label. */
export interface NormalizedQuestionOption {
  label: string;
}

/** A single question from a `question.asked` request. */
export interface NormalizedQuestion {
  question: string;
  options: NormalizedQuestionOption[];
  multiple?: boolean;
}

/**
 * Internal representation of the OpenCode events the plugin cares about.
 * `kind` mirrors the upstream event names so the mapping stays traceable.
 */
export type NormalizedEvent =
  | {
      kind: "session.upsert";
      sessionID: string;
      parentID?: string;
      title: string;
    }
  | {
      kind: "session.status";
      sessionID: string;
      status: "busy" | "retry" | "idle";
      retry?: NormalizedRetry;
    }
  | {
      kind: "session.error";
      sessionID?: string;
      outcome: "stopped" | "failed";
    }
  | {
      kind: "message";
      sessionID: string;
      messageID: string;
      role: "user" | "assistant";
      outcome?: "stopped" | "failed";
    }
  | {
      kind: "message.text";
      sessionID: string;
      messageID: string;
      partID: string;
      text: string;
    }
  | {
      kind: "question.asked";
      sessionID: string;
      requestID: string;
      questions: NormalizedQuestion[];
    }
  | {
      kind: "question.resolved";
      sessionID: string;
      requestID: string;
    }
  | {
      kind: "permission.asked";
      sessionID: string;
      requestID: string;
      permission: string;
      summary: string;
    }
  | {
      kind: "permission.resolved";
      sessionID: string;
      requestID: string;
    };

/**
 * Maximum length of a permission summary. Well under the gateway contract
 * cap (500) so downstream emitters never have to re-truncate.
 */
export const PERMISSION_SUMMARY_MAX_LENGTH = 200;

/** Error names that mean "the user aborted the turn", not a failure. */
const ABORT_ERROR_NAMES = new Set(["MessageAbortedError", "AbortError"]);

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function asNonEmptyString(value: unknown): string | null {
  return typeof value === "string" && value.length > 0 ? value : null;
}

function asFiniteNumber(value: unknown): number | null {
  return typeof value === "number" && Number.isFinite(value) ? value : null;
}

/** Map an upstream `{ name, data }` error to a terminal outcome. */
function errorOutcome(error: unknown): "stopped" | "failed" {
  if (isRecord(error) && typeof error.name === "string" && ABORT_ERROR_NAMES.has(error.name)) {
    return "stopped";
  }
  return "failed";
}

/**
 * Reduce a pattern to a single safe line: control characters become
 * spaces, whitespace collapses, ends are trimmed. Patterns come from tool
 * input and may contain embedded newlines or terminal control codes; the
 * summary is a notification string, so it must stay one clean line.
 */
function sanitizePattern(pattern: unknown): string | null {
  if (typeof pattern !== "string") {
    return null;
  }
  // eslint-disable-next-line no-control-regex
  const cleaned = pattern.replace(/[\x00-\x1F\x7F]+/g, " ").replace(/\s+/g, " ").trim();
  return cleaned.length > 0 ? cleaned : null;
}

/**
 * Build the permission summary from the permission type and its sanitized
 * patterns ONLY. Metadata values and the upstream `title` are never read:
 * they can contain full commands, diffs, or credentials. The result is
 * truncated to {@link PERMISSION_SUMMARY_MAX_LENGTH} with an ellipsis.
 */
function buildPermissionSummary(permission: string, patterns: unknown): string {
  const list = Array.isArray(patterns) ? patterns : patterns === undefined ? [] : [patterns];
  const sanitized = list
    .map(sanitizePattern)
    .filter((pattern): pattern is string => pattern !== null);
  const summary = sanitized.length > 0 ? `${permission}: ${sanitized.join(", ")}` : permission;
  if (summary.length <= PERMISSION_SUMMARY_MAX_LENGTH) {
    return summary;
  }
  return `${summary.slice(0, PERMISSION_SUMMARY_MAX_LENGTH - 1)}…`;
}

/** Read the session info object: `properties.info`, falling back to `properties` itself. */
function readSessionInfo(properties: Record<string, unknown>): Record<string, unknown> | null {
  if (isRecord(properties.info)) {
    return properties.info;
  }
  // Dev-source fallback: some versions carry the session fields directly
  // on the event properties instead of under `info`.
  if (typeof properties.id === "string") {
    return properties;
  }
  return null;
}

function normalizeSessionUpsert(properties: Record<string, unknown>): NormalizedEvent | null {
  const info = readSessionInfo(properties);
  if (info === null) {
    return null;
  }
  const sessionID = asNonEmptyString(info.id);
  if (sessionID === null) {
    return null;
  }
  const title = typeof info.title === "string" ? info.title : "";
  const parentID = asNonEmptyString(info.parentID);
  return parentID === null
    ? { kind: "session.upsert", sessionID, title }
    : { kind: "session.upsert", sessionID, parentID, title };
}

/**
 * Read a dev-source retry `action` defensively. The four contract-required
 * fields (`provider`/`title`/`message`/`label`) must all be nonempty
 * strings or the whole action is ignored — an empty one could never
 * satisfy the contract's `minLength: 1`. Optional `reason`/`link` degrade
 * individually: a non-string value is simply dropped. Never throws.
 */
function normalizeRetryAction(action: unknown): RetryActionInfo | null {
  if (!isRecord(action)) {
    return null;
  }
  const provider = asNonEmptyString(action.provider);
  const title = asNonEmptyString(action.title);
  const message = asNonEmptyString(action.message);
  const label = asNonEmptyString(action.label);
  if (provider === null || title === null || message === null || label === null) {
    return null;
  }
  const normalized: RetryActionInfo = { provider, title, message, label };
  const reason = asNonEmptyString(action.reason);
  if (reason !== null) {
    normalized.reason = reason;
  }
  const link = asNonEmptyString(action.link);
  if (link !== null) {
    normalized.link = link;
  }
  return normalized;
}

function normalizeSessionStatus(properties: Record<string, unknown>): NormalizedEvent | null {
  const sessionID = asNonEmptyString(properties.sessionID);
  if (sessionID === null || !isRecord(properties.status)) {
    return null;
  }
  const status = properties.status;
  switch (status.type) {
    case "busy":
      return { kind: "session.status", sessionID, status: "busy" };
    case "idle":
      return { kind: "session.status", sessionID, status: "idle" };
    case "retry": {
      const attempt = asFiniteNumber(status.attempt);
      const next = asFiniteNumber(status.next);
      if (attempt === null || next === null) {
        return null;
      }
      const message = typeof status.message === "string" ? status.message : "";
      const retry: NormalizedRetry = { attempt, message, next };
      const action = normalizeRetryAction(status.action);
      if (action !== null) {
        retry.action = action;
      }
      return {
        kind: "session.status",
        sessionID,
        status: "retry",
        retry,
      };
    }
    default:
      return null;
  }
}

function normalizeSessionIdle(properties: Record<string, unknown>): NormalizedEvent | null {
  const sessionID = asNonEmptyString(properties.sessionID);
  return sessionID === null
    ? null
    : { kind: "session.status", sessionID, status: "idle" };
}

function normalizeSessionError(properties: Record<string, unknown>): NormalizedEvent {
  const sessionID = asNonEmptyString(properties.sessionID);
  const outcome = errorOutcome(properties.error);
  return sessionID === null
    ? { kind: "session.error", outcome }
    : { kind: "session.error", sessionID, outcome };
}

function normalizeMessage(properties: Record<string, unknown>): NormalizedEvent | null {
  const info = isRecord(properties.info) ? properties.info : null;
  if (info === null) {
    return null;
  }
  const sessionID = asNonEmptyString(info.sessionID);
  const messageID = asNonEmptyString(info.id);
  if (sessionID === null || messageID === null) {
    return null;
  }
  if (info.role !== "user" && info.role !== "assistant") {
    return null;
  }
  if (info.role === "assistant" && info.error !== undefined) {
    return {
      kind: "message",
      sessionID,
      messageID,
      role: "assistant",
      outcome: errorOutcome(info.error),
    };
  }
  return { kind: "message", sessionID, messageID, role: info.role };
}

function normalizeMessagePart(properties: Record<string, unknown>): NormalizedEvent | null {
  const part = isRecord(properties.part) ? properties.part : null;
  if (part === null || part.type !== "text") {
    return null;
  }
  const sessionID = asNonEmptyString(part.sessionID);
  const messageID = asNonEmptyString(part.messageID);
  const partID = asNonEmptyString(part.id);
  if (sessionID === null || messageID === null || partID === null) {
    return null;
  }
  if (typeof part.text !== "string") {
    return null;
  }
  return { kind: "message.text", sessionID, messageID, partID, text: part.text };
}

function normalizeQuestion(question: unknown): NormalizedQuestion | null {
  if (!isRecord(question) || !asNonEmptyString(question.question)) {
    return null;
  }
  const options: NormalizedQuestionOption[] = [];
  if (Array.isArray(question.options)) {
    for (const option of question.options) {
      if (isRecord(option)) {
        const label = asNonEmptyString(option.label);
        if (label !== null) {
          // Label-only on purpose: the upstream description stays behind.
          options.push({ label });
        }
      }
    }
  }
  const normalized: NormalizedQuestion = {
    question: question.question as string,
    options,
  };
  if (question.multiple === true) {
    normalized.multiple = true;
  } else if (question.multiple === false) {
    normalized.multiple = false;
  }
  return normalized;
}

function normalizeQuestionAsked(properties: Record<string, unknown>): NormalizedEvent | null {
  const sessionID = asNonEmptyString(properties.sessionID);
  const requestID = asNonEmptyString(properties.id);
  if (sessionID === null || requestID === null || !Array.isArray(properties.questions)) {
    return null;
  }
  const questions = properties.questions
    .map(normalizeQuestion)
    .filter((question): question is NormalizedQuestion => question !== null);
  if (questions.length === 0) {
    return null;
  }
  return { kind: "question.asked", sessionID, requestID, questions };
}

function normalizeResolved(
  kind: "question.resolved" | "permission.resolved",
  properties: Record<string, unknown>,
): NormalizedEvent | null {
  const sessionID = asNonEmptyString(properties.sessionID);
  // Dev sources use `requestID`; SDK 1.18.15 permission.replied uses
  // `permissionID`. Accept either.
  const requestID = asNonEmptyString(properties.requestID) ?? asNonEmptyString(properties.permissionID);
  if (sessionID === null || requestID === null) {
    return null;
  }
  return { kind, sessionID, requestID };
}

function normalizePermissionAsked(properties: Record<string, unknown>): NormalizedEvent | null {
  const sessionID = asNonEmptyString(properties.sessionID);
  const requestID = asNonEmptyString(properties.id);
  // Dev sources call it `permission`; SDK 1.18.15 (permission.updated)
  // calls it `type`. Accept either. Metadata and `title` are never read.
  const permission = asNonEmptyString(properties.permission) ?? asNonEmptyString(properties.type);
  if (sessionID === null || requestID === null || permission === null) {
    return null;
  }
  const patterns = properties.patterns !== undefined ? properties.patterns : properties.pattern;
  return {
    kind: "permission.asked",
    sessionID,
    requestID,
    permission,
    summary: buildPermissionSummary(permission, patterns),
  };
}

/**
 * Normalize one OpenCode event. Returns `null` for every event the plugin
 * does not act on and for anything malformed; never throws.
 */
export function normalizeEvent(event: unknown): NormalizedEvent | null {
  try {
    if (!isRecord(event) || typeof event.type !== "string") {
      return null;
    }
    const properties = isRecord(event.properties) ? event.properties : null;
    switch (event.type) {
      case "session.created":
      case "session.updated":
        return properties === null ? null : normalizeSessionUpsert(properties);
      case "session.status":
        return properties === null ? null : normalizeSessionStatus(properties);
      case "session.idle":
        return properties === null ? null : normalizeSessionIdle(properties);
      case "session.error":
        return properties === null ? null : normalizeSessionError(properties);
      case "message.updated":
        return properties === null ? null : normalizeMessage(properties);
      case "message.part.updated":
        return properties === null ? null : normalizeMessagePart(properties);
      case "question.asked":
        return properties === null ? null : normalizeQuestionAsked(properties);
      case "question.replied":
      case "question.rejected":
        return properties === null ? null : normalizeResolved("question.resolved", properties);
      case "permission.asked":
      case "permission.updated":
        return properties === null ? null : normalizePermissionAsked(properties);
      case "permission.replied":
        return properties === null ? null : normalizeResolved("permission.resolved", properties);
      default:
        return null;
    }
  } catch {
    return null;
  }
}
