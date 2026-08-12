/**
 * Never-throw structured logging for the plugin.
 *
 * Every internal subsystem (wiring, pump, envelope boundary) reports
 * through a {@link SafeLogger}. The hard guarantees:
 * - **Never throws.** A misbehaving sink (synchronous throw, rejection,
 *   hostile thenable) is absorbed; logging can never break the event
 *   pipeline it observes.
 * - **Never awaited.** The sink is fired and forgotten; a rejection
 *   handler is attached so no unhandled rejection can escape. The OpenCode
 *   `client.app.log` call is itself a server round-trip, so the hook path
 *   must not wait for it.
 * - **Never leaks.** Messages and context string values are scrubbed of
 *   every configured secret (the ingest credential and its parts) and
 *   length-bounded. Context values are restricted to primitives —
 *   strings, finite numbers, booleans, null — so an object that might
 *   embed a payload can never reach the log stream.
 *
 * Payloads (message text, question text, permission metadata, event
 * bodies) must never be passed to this logger in the first place; the
 * redaction and primitive-only context are the belt-and-braces layer, not
 * the primary defense.
 */

/** Levels supported by the OpenCode `/log` endpoint. */
export type LogLevel = "debug" | "info" | "warn" | "error";

/** One structured entry, matching the `client.app.log` body shape. */
export interface LogEntry {
  service: string;
  level: LogLevel;
  message: string;
  extra?: Record<string, unknown>;
}

/** The minimal logging surface the plugin consumes. */
export interface SafeLogger {
  debug(message: string, context?: Record<string, unknown>): void;
  info(message: string, context?: Record<string, unknown>): void;
  warn(message: string, context?: Record<string, unknown>): void;
  error(message: string, context?: Record<string, unknown>): void;
}

export interface SafeLoggerOptions {
  /**
   * Fire-and-forget destination for one entry, e.g.
   * `(entry) => client.app.log({ body: entry })`. May return a promise
   * (handled, never awaited) and may throw (absorbed).
   */
  sink: (entry: LogEntry) => unknown;
  /** Service name stamped on every entry; default `opencode-notify`. */
  service?: string;
  /**
   * Sensitive substrings scrubbed from messages and context string values
   * (replaced with `[redacted]`). Pass the full `keyId.secret` credential
   * plus each part separately.
   */
  secrets?: readonly string[];
  /** Bound on the message length; default 500. */
  maxMessageLength?: number;
  /** Bound on each context string value; default 200. */
  maxContextValueLength?: number;
}

const DEFAULT_SERVICE = "opencode-notify";
const DEFAULT_MAX_MESSAGE_LENGTH = 500;
const DEFAULT_MAX_CONTEXT_VALUE_LENGTH = 200;
const REDACTED = "[redacted]";

/** Truncate to `max` code points, never splitting a surrogate pair. */
function truncateCodePoints(text: string, max: number): string {
  const points = Array.from(text);
  return points.length <= max ? text : points.slice(0, max).join("");
}

/** Scrub every configured secret from `text`. */
function redact(text: string, secrets: readonly string[]): string {
  let out = text;
  for (const secret of secrets) {
    if (secret.length > 0 && out.includes(secret)) {
      out = out.split(secret).join(REDACTED);
    }
  }
  return out;
}

/**
 * Keep only primitive context values, redacting and bounding strings.
 * Objects, arrays, functions, and undefined are dropped: their safety
 * cannot be proven, and the callers pass ids and counts only.
 */
function sanitizeContext(
  context: Record<string, unknown>,
  secrets: readonly string[],
  maxValueLength: number,
): Record<string, unknown> {
  const out: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(context)) {
    if (typeof value === "string") {
      out[key] = truncateCodePoints(redact(value, secrets), maxValueLength);
    } else if (typeof value === "number" && Number.isFinite(value)) {
      out[key] = value;
    } else if (typeof value === "boolean" || value === null) {
      out[key] = value;
    }
  }
  return out;
}

function isThenable(value: unknown): value is PromiseLike<unknown> {
  return (
    (typeof value === "object" && value !== null) || typeof value === "function"
  ) && typeof (value as { then?: unknown }).then === "function";
}

/**
 * Create a logger that satisfies every guarantee in the module doc. All
 * four levels share one code path; the sink is invoked inside a blanket
 * try/catch and any returned promise gets a swallow handler.
 */
export function createSafeLogger(options: SafeLoggerOptions): SafeLogger {
  const service = options.service ?? DEFAULT_SERVICE;
  const secrets = options.secrets ?? [];
  const maxMessageLength = options.maxMessageLength ?? DEFAULT_MAX_MESSAGE_LENGTH;
  const maxContextValueLength = options.maxContextValueLength ?? DEFAULT_MAX_CONTEXT_VALUE_LENGTH;

  function emit(level: LogLevel, message: string, context?: Record<string, unknown>): void {
    try {
      const entry: LogEntry = {
        service,
        level,
        message: truncateCodePoints(redact(message, secrets), maxMessageLength),
      };
      if (context !== undefined) {
        const extra = sanitizeContext(context, secrets, maxContextValueLength);
        if (Object.keys(extra).length > 0) {
          entry.extra = extra;
        }
      }
      const result = options.sink(entry);
      if (isThenable(result)) {
        // Handled, never awaited: a rejected log call must not surface as
        // an unhandled rejection, and the caller must not stall on it.
        result.then(undefined, () => undefined);
      }
    } catch {
      // Logging observes the pipeline; it must never break it.
    }
  }

  return {
    debug: (message, context) => emit("debug", message, context),
    info: (message, context) => emit("info", message, context),
    warn: (message, context) => emit("warn", message, context),
    error: (message, context) => emit("error", message, context),
  };
}
