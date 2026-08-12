/**
 * Contract-valid `NotifyEvent` envelopes.
 *
 * This factory turns the internal session-machine effects
 * (`SessionHeartbeat`, `SessionTerminal`, `SessionActionRequired`,
 * `SessionActionResolved`) into the shared gateway contract's four event
 * variants. Its single hard rule: NEVER emit an invalid event. Every built
 * event passes through `validateNotifyEvent` from `@notify/contracts`
 * before it is returned; an event that cannot satisfy the contract throws
 * instead of escaping.
 *
 * Determinism: wall-clock time and UUIDs are injected (`now` /
 * `randomUUID` options, defaulting to `Date.now` and
 * `crypto.randomUUID`), so tests pin exact `occurredAt`/`eventId` values.
 *
 * Field mapping and bounds (all truncation is code-point safe — surrogate
 * pairs are never split — and appends a `…` marker, matching
 * `events.ts` style; truncation always preserves the contract's nonempty
 * minimums):
 * - `elapsedSeconds` = `floor(max(0, elapsedMs) / 1000)` — a partial
 *   second of work is never overreported (conversion reserved for this
 *   emitter by the state machine).
 * - Session title falls back to the session id when empty/missing.
 * - Questions: at most 8 (empties dropped first), text capped at 2000
 *   code points, at most 16 options (empty labels dropped, `options` key
 *   omitted when none remain), `multiple` omitted when undefined.
 * - Permission: `summary` capped at 500; an empty summary cannot satisfy
 *   the contract's `minLength: 1` and throws.
 * - Provider action: `provider`/`title`/`label` capped at 120, `message`
 *   at 500; a `link` that is not a parseable absolute URL, contains
 *   whitespace/control characters, or exceeds 2048 code points is dropped
 *   (deterministically) rather than emitted invalid.
 * - Terminal `summary` (from `MessageCache`): present only when
 *   `includeSummary` is enabled AND the text is nonempty, capped at 500.
 *   `includeSummary: false` (the default) means the key is absent, always.
 *
 * Queue priorities are NOT re-mapped here: callers use the existing
 * `notifyEventPriority` from `queue.ts`, so priority logic cannot drift.
 *
 * Privacy: payloads carry only the normalized action details produced
 * upstream (question text/labels, sanitized permission summaries, provider
 * action fields) plus the optional assistant-only summary. Tool output,
 * user prompts, permission metadata, and full conversation text never
 * reach this layer.
 */

import { randomUUID as nodeRandomUUID } from "node:crypto";

import { validateNotifyEvent } from "@notify/contracts";
import type { NotifyEvent } from "@notify/contracts";

import type { NormalizedQuestion } from "./events.js";
import type {
  SessionActionRequired,
  SessionActionResolved,
  SessionHeartbeat,
  SessionProviderActionDetails,
  SessionTerminal,
} from "./state-machine.js";

/** Contract cap: questions per `action_required` payload. */
export const MAX_QUESTIONS = 8;
/** Contract cap: question text, in code points. */
export const MAX_QUESTION_TEXT_CODE_POINTS = 2000;
/** Contract cap: options per question. */
export const MAX_QUESTION_OPTIONS = 16;
/** Contract cap: permission summary, in code points. */
export const MAX_PERMISSION_SUMMARY_CODE_POINTS = 500;
/** Contract cap: provider action provider/title/label, in code points. */
export const MAX_PROVIDER_FIELD_CODE_POINTS = 120;
/** Contract cap: provider action message, in code points. */
export const MAX_PROVIDER_MESSAGE_CODE_POINTS = 500;
/** Contract cap: provider action link, in code points. */
export const MAX_PROVIDER_LINK_CODE_POINTS = 2048;
/** Contract cap: terminal summary, in code points. */
export const MAX_SUMMARY_CODE_POINTS = 500;

/** Event source identity, delivered on every envelope. */
export interface EnvelopeSource {
  machine: string;
  project: string;
  directory: string;
}

/** Session identity for the envelope; `title` falls back to `id`. */
export interface EnvelopeSession {
  id: string;
  title?: string;
}

/** The outcome emitted by the state machine's terminal callbacks. */
export type TerminalOutcome = "completed" | "failed" | "stopped";

export interface EnvelopeFactoryOptions {
  source: EnvelopeSource;
  /** Include the assistant-only summary on terminal events; default false. */
  includeSummary?: boolean;
  /** Clock seam; defaults to `Date.now`. */
  now?: () => number;
  /** UUID seam; defaults to `crypto.randomUUID`. */
  randomUUID?: () => string;
}

/**
 * Truncate to `max` code points, never splitting a surrogate pair. A
 * truncated value ends with `…` (and stays within `max`), so a nonempty
 * input always keeps a nonempty output.
 */
function truncateCodePoints(text: string, max: number): string {
  const points = Array.from(text);
  if (points.length <= max) {
    return text;
  }
  return `${points.slice(0, max - 1).join("")}…`;
}

/** `floor(max(0, ms) / 1000)` — never rounds a partial second up. */
function elapsedSeconds(elapsedMs: number): number {
  return Math.floor(Math.max(0, elapsedMs) / 1000);
}

/**
 * Accept a link only when it is a parseable absolute URL free of
 * whitespace/control characters and within the contract's length cap;
 * anything else is dropped (returns null) so the event stays valid.
 */
function asContractUri(value: string): string | null {
  if (Array.from(value).length > MAX_PROVIDER_LINK_CODE_POINTS) {
    return null;
  }
  // eslint-disable-next-line no-control-regex
  if (/[\s\x00-\x1F\x7F]/.test(value)) {
    return null;
  }
  try {
    new URL(value);
  } catch {
    return null;
  }
  return value;
}

interface ContractQuestionOption {
  label: string;
}

interface ContractQuestion {
  question: string;
  options?: ContractQuestionOption[];
  multiple?: boolean;
}

/** The contract's `action_required` payload union (oneOf). */
type ActionRequiredPayload =
  | { requestId: string; kind: "question"; questions: ContractQuestion[] }
  | {
      requestId: string;
      kind: "permission";
      permission: { permission: string; summary: string };
    }
  | {
      requestId: string;
      kind: "provider_action";
      providerAction: SessionProviderActionDetails;
    };

/**
 * Bound one normalized question to the contract: empty question text is
 * dropped (returns null), empty-label options are removed, `options` and
 * `multiple` keys are omitted when they carry nothing.
 */
function boundQuestion(question: NormalizedQuestion): ContractQuestion | null {
  if (question.question.length === 0) {
    return null;
  }
  const bounded: ContractQuestion = {
    question: truncateCodePoints(question.question, MAX_QUESTION_TEXT_CODE_POINTS),
  };
  const options = question.options
    .filter((option) => option.label.length > 0)
    .slice(0, MAX_QUESTION_OPTIONS)
    .map((option) => ({ label: option.label }));
  if (options.length > 0) {
    bounded.options = options;
  }
  if (question.multiple !== undefined) {
    bounded.multiple = question.multiple;
  }
  return bounded;
}

function boundProviderAction(
  details: SessionProviderActionDetails,
): SessionProviderActionDetails {
  const bounded: SessionProviderActionDetails = {
    provider: truncateCodePoints(details.provider, MAX_PROVIDER_FIELD_CODE_POINTS),
    title: truncateCodePoints(details.title, MAX_PROVIDER_FIELD_CODE_POINTS),
    message: truncateCodePoints(details.message, MAX_PROVIDER_MESSAGE_CODE_POINTS),
    label: truncateCodePoints(details.label, MAX_PROVIDER_FIELD_CODE_POINTS),
  };
  if (details.link !== undefined) {
    const link = asContractUri(details.link);
    if (link !== null) {
      bounded.link = link;
    }
  }
  return bounded;
}

/**
 * Assert the contract on a fully built event. Throws with the ajv failure
 * paths (never event data: ajv runs non-verbose, and only
 * instancePath/keyword/message are copied) instead of letting an invalid
 * envelope escape.
 */
export function assertValidNotifyEvent(event: unknown): asserts event is NotifyEvent {
  if (!validateNotifyEvent(event)) {
    const details = (validateNotifyEvent.errors ?? [])
      .map((error) => `${error.instancePath || "/"} ${error.keyword}: ${error.message ?? ""}`)
      .join("; ");
    throw new Error(`refusing to emit contract-invalid NotifyEvent: ${details}`);
  }
}

export class EnvelopeFactory {
  private readonly source: EnvelopeSource;
  private readonly includeSummary: boolean;
  private readonly now: () => number;
  private readonly randomUUID: () => string;

  constructor(options: EnvelopeFactoryOptions) {
    this.source = options.source;
    this.includeSummary = options.includeSummary ?? false;
    this.now = options.now ?? Date.now;
    this.randomUUID = options.randomUUID ?? nodeRandomUUID;
  }

  /** A heartbeat with the current status and working-period elapsed. */
  heartbeat(session: EnvelopeSession, heartbeat: SessionHeartbeat): NotifyEvent {
    return this.finalize({
      eventId: this.randomUUID(),
      type: "heartbeat",
      occurredAt: this.occurredAt(),
      source: this.source,
      session: this.sessionSection(session),
      payload: {
        status: heartbeat.status,
        elapsedSeconds: elapsedSeconds(heartbeat.elapsedMs),
      },
    });
  }

  /**
   * The round's terminal event. `outcome` is the one the state machine
   * emitted on its callback channel (never a later internal record).
   * `summary` is included only when `includeSummary` is enabled and the
   * text is nonempty.
   */
  terminal(
    session: EnvelopeSession,
    terminal: SessionTerminal,
    outcome: TerminalOutcome,
    summary?: string,
  ): NotifyEvent {
    const payload: {
      outcome: TerminalOutcome;
      elapsedSeconds: number;
      summary?: string;
    } = {
      outcome,
      elapsedSeconds: elapsedSeconds(terminal.elapsedMs),
    };
    if (this.includeSummary && summary !== undefined && summary.length > 0) {
      payload.summary = truncateCodePoints(summary, MAX_SUMMARY_CODE_POINTS);
    }
    return this.finalize({
      eventId: this.randomUUID(),
      type: "terminal",
      occurredAt: this.occurredAt(),
      source: this.source,
      session: this.sessionSection(session),
      payload,
    });
  }

  /**
   * An action request, mapped from the internal effect to the external
   * lower-camel contract shape (`requestId`, exact section/field names)
   * with every field bounded to the contract caps.
   */
  actionRequired(session: EnvelopeSession, action: SessionActionRequired): NotifyEvent {
    let payload: ActionRequiredPayload;
    switch (action.kind) {
      case "question": {
        const questions = action.questions
          .map(boundQuestion)
          .filter((question): question is ContractQuestion => question !== null)
          .slice(0, MAX_QUESTIONS);
        if (questions.length === 0) {
          throw new Error(
            `refusing to emit action_required ${action.requestId}: no nonempty question remains`,
          );
        }
        payload = { requestId: action.requestId, kind: "question", questions };
        break;
      }
      case "permission": {
        if (action.permission.summary.length === 0) {
          throw new Error(
            `refusing to emit action_required ${action.requestId}: empty permission summary`,
          );
        }
        payload = {
          requestId: action.requestId,
          kind: "permission",
          permission: {
            permission: action.permission.permission,
            summary: truncateCodePoints(
              action.permission.summary,
              MAX_PERMISSION_SUMMARY_CODE_POINTS,
            ),
          },
        };
        break;
      }
      case "provider_action": {
        payload = {
          requestId: action.requestId,
          kind: "provider_action",
          providerAction: boundProviderAction(action.providerAction),
        };
        break;
      }
    }
    return this.finalize({
      eventId: this.randomUUID(),
      type: "action_required",
      occurredAt: this.occurredAt(),
      source: this.source,
      session: this.sessionSection(session),
      payload,
    });
  }

  /** The silent resolution of a pending question/permission request. */
  actionResolved(session: EnvelopeSession, resolution: SessionActionResolved): NotifyEvent {
    return this.finalize({
      eventId: this.randomUUID(),
      type: "action_resolved",
      occurredAt: this.occurredAt(),
      source: this.source,
      session: this.sessionSection(session),
      payload: { requestId: resolution.requestId, kind: resolution.kind },
    });
  }

  private occurredAt(): string {
    return new Date(this.now()).toISOString();
  }

  private sessionSection(session: EnvelopeSession): { id: string; title: string } {
    const title =
      session.title !== undefined && session.title.length > 0 ? session.title : session.id;
    return { id: session.id, title };
  }

  /** The single exit point: validate, then return — never emit invalid. */
  private finalize(event: unknown): NotifyEvent {
    assertValidNotifyEvent(event);
    return event;
  }
}
