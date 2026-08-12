/**
 * Per-session busy/idle state machine with the completion debounce.
 *
 * The plugin hears three session signals (already normalized by
 * `events.ts`): `busy`, `retry`, and `idle` — where idle arrives either as
 * `session.status` with an idle payload or as the deprecated
 * `session.idle` marker. Both idle forms are the same signal here.
 *
 * Round semantics:
 * - A `busy` or `retry` opens (or continues) a round. The round keeps the
 *   `busySince` of its FIRST busy, so elapsed time measures the whole
 *   working period, not the last status flip.
 * - An `idle` closes the active period, snapshots the round elapsed as
 *   `max(0, idleTime - busySince)` (0 when no busy was seen), and starts
 *   ONE debounce timer. Repeated idles (status form plus legacy form)
 *   merge into the pending timer and keep the FIRST snapshot.
 * - If no busy/retry arrives within `idleDebounceMs`, the machine emits
 *   `completed` exactly once with the frozen snapshot — the debounce delay
 *   itself never inflates elapsed. A busy/retry during the debounce
 *   cancels the pending completion AND discards the snapshot; a later idle
 *   snapshots again from the still-open round's original `busySince`.
 * - A busy after a completion starts a fresh round with a fresh
 *   `busySince`.
 * - An idle with no prior busy (the working period was never observed)
 *   still completes, with `elapsedMs` 0 — it is debounced like any other
 *   idle rather than dropped, so a missed busy event cannot silently lose
 *   the completion.
 *
 * The emitted `elapsedMs` is exact working-period milliseconds. The later
 * emitter task converts it to the contract's integer `elapsedSeconds` with
 * `floor(ms / 1000)` — never rounding up — so a partial second of work is
 * not overreported. That conversion is NOT implemented here.
 *
 * Terminal outcomes:
 * - `failed` and `stopped` (abort-classified errors arrive as `stopped`
 *   via `events.ts`) emit their terminal IMMEDIATELY, exactly once per
 *   round — no debounce. The emitted elapsed is the actual round elapsed
 *   `max(0, now - busySince)`, or the frozen idle snapshot when the
 *   terminal arrives while a completion debounce is pending: in both
 *   cases debounce time is never counted. The pending debounce (and its
 *   snapshot) is cancelled.
 * - Outcome priority is `stopped > failed > completed`: a second
 *   terminal signal in the same round updates the recorded outcome but
 *   never emits again, and a subsequent idle cannot emit `completed`.
 * - A busy after any terminal resets the round terminal state; the next
 *   round may terminate normally.
 *
 * Heartbeat:
 * - While a round is active, a self-rescheduling timer (default
 *   {@link DEFAULT_HEARTBEAT_MS}) emits the CURRENT heartbeat status
 *   (`busy` or `retry`, set by the latest active signal) and the elapsed
 *   from the round's original `busySince`. Each tick re-arms only if the
 *   round is still active after the (possibly reentrant) callback, so
 *   there is never more than one heartbeat timer per session.
 * - Idle, failed, stopped, and dispose clear the heartbeat; a busy that
 *   resumes a debouncing round re-arms it. Graceful shutdown flushes only
 *   completions whose idle debounce is already pending; active rounds are
 *   never turned into completions.
 *
 * All timing goes through the injected {@link TimerScheduler}; the machine
 * never touches global timers or the wall clock directly.
 *
 * Action effects (question / permission / provider action):
 * - `question.asked` and `permission.asked` emit `action_required`
 *   IMMEDIATELY, once per upstream requestID; a duplicate ask while the
 *   request is still pending is suppressed (the first payload wins).
 * - `question.resolved` / `permission.resolved` (rejected questions arrive
 *   as resolved via `events.ts`) emit a SILENT `action_resolved` only when
 *   a request of the SAME kind with that requestID is actually pending,
 *   then drop it; an unknown, already-resolved, or other-kind ID emits
 *   nothing. After a resolve the same ID may be asked again and re-emits.
 *   Pending keys are namespaced by kind, so an identical question and
 *   permission requestID never suppress or resolve each other.
 * - A retry carrying a provider action has no upstream request ID, so it
 *   gets a deterministic synthetic requestId / dedupe key:
 *   `provider:` + SHA-256 hex of the canonical identity JSON
 *   `[sessionID, provider, reason ?? title, label]` (73 chars, bounded).
 *   The array encoding keeps field boundaries unambiguous, so
 *   delimiter-containing values cannot collide, and the free-text
 *   `message`/`link` never feed the hash. A repeated identical action is
 *   suppressed; a changed action replaces the pending one (silently —
 *   provider actions never produce `action_resolved`) and emits again.
 * - The pending provider action is cleared by a busy (busy never carries
 *   an action) and by any terminal. Pending question/permission requests
 *   are cleared by any terminal — including a completed round — always
 *   silently, never fabricating `action_resolved` events. A busy that
 *   merely cancels the debounce keeps them pending.
 * - Actions are orthogonal to the round: asks and resolves may arrive
 *   before any busy and never open a round, arm a heartbeat, start a
 *   debounce, or touch the terminal state.
 *
 * The emitted effect payloads carry the full normalized question,
 * permission, and provider details. Bounding them to the contract's field
 * caps is the emitter task's job, not this machine's.
 */

import { createHash } from "node:crypto";

import { DEFAULT_HEARTBEAT_MS, DEFAULT_IDLE_DEBOUNCE_MS } from "./config.js";
import type { NormalizedQuestion } from "./events.js";

/** Opaque timer handle, as returned by the injected scheduler. */
export type TimerHandle = unknown;

/**
 * Timer/clock seam. The default implementation delegates to the global
 * `setTimeout`/`clearTimeout` and `Date.now`; tests inject fakes.
 */
export interface TimerScheduler {
  setTimeout(callback: () => void, delayMs: number): TimerHandle;
  clearTimeout(handle: TimerHandle): void;
  now(): number;
}

/** Emitted once when a session stays idle for the full debounce. */
export interface SessionCompletion {
  sessionID: string;
  /**
   * Working-period milliseconds, frozen at the round's first idle:
   * `max(0, idleTime - busySince)`, or 0 when no busy was seen. The
   * debounce delay is never included.
   */
  elapsedMs: number;
}

/** Emitted every heartbeat interval while a round is active. */
export interface SessionHeartbeat {
  sessionID: string;
  /** Latest active signal of the round: `busy` or `retry`. */
  status: "busy" | "retry";
  /** Working-period milliseconds from the round's original `busySince`. */
  elapsedMs: number;
}

/** Emitted once per round when the session fails or is stopped. */
export interface SessionTerminal {
  sessionID: string;
  /**
   * Working-period milliseconds: the frozen idle snapshot when a
   * completion debounce was pending, else `max(0, now - busySince)`, or
   * 0 when no busy was seen. Debounce time is never included.
   */
  elapsedMs: number;
}

/** Permission details carried by a permission `action_required` effect. */
export interface SessionPermissionDetails {
  permission: string;
  summary: string;
}

/** Provider-action details, mirroring the contract's providerAction section. */
export interface SessionProviderActionDetails {
  provider: string;
  title: string;
  message: string;
  label: string;
  link?: string;
}

/**
 * A provider action carried by a retry. `reason` is identity-only: when
 * present it (not the title) feeds the synthetic requestId/dedupe key; it
 * is never emitted.
 */
export interface SessionProviderAction extends SessionProviderActionDetails {
  reason?: string;
}

/**
 * Emitted immediately when the user (or provider) must act. `requestId` is
 * the external contract field: the upstream requestID for question and
 * permission, a deterministic synthetic key for provider actions.
 */
export type SessionActionRequired =
  | {
      sessionID: string;
      requestId: string;
      kind: "question";
      questions: NormalizedQuestion[];
    }
  | {
      sessionID: string;
      requestId: string;
      kind: "permission";
      permission: SessionPermissionDetails;
    }
  | {
      sessionID: string;
      requestId: string;
      kind: "provider_action";
      providerAction: SessionProviderActionDetails;
    };

/**
 * Emitted when a pending question/permission request is answered or
 * rejected. Silent by design (low queue priority); provider actions never
 * produce one.
 */
export interface SessionActionResolved {
  sessionID: string;
  requestId: string;
  kind: "question" | "permission";
}

export interface SessionMachineOptions {
  onCompleted: (completion: SessionCompletion) => void;
  /** Heartbeat tick; when absent no heartbeat timer is ever scheduled. */
  onHeartbeat?: (heartbeat: SessionHeartbeat) => void;
  onFailed?: (terminal: SessionTerminal) => void;
  onStopped?: (terminal: SessionTerminal) => void;
  /** Immediate user-input/provider action request. */
  onActionRequired?: (action: SessionActionRequired) => void;
  /** Silent resolution of a pending question/permission request. */
  onActionResolved?: (resolution: SessionActionResolved) => void;
  /** Debounce window; defaults to {@link DEFAULT_IDLE_DEBOUNCE_MS}. */
  idleDebounceMs?: number;
  /** Heartbeat interval; defaults to {@link DEFAULT_HEARTBEAT_MS}. */
  heartbeatMs?: number;
  scheduler?: TimerScheduler;
}

type SessionStatus = "busy" | "retry" | "idle";

/** Terminal outcomes in ascending priority: later entries win. */
type TerminalOutcome = "completed" | "failed" | "stopped";

const OUTCOME_RANK: Record<TerminalOutcome, number> = {
  completed: 1,
  failed: 2,
  stopped: 3,
};

/** Kind of a pending action request, keyed by requestId in session state. */
type PendingActionKind = "question" | "permission" | "provider_action";

interface SessionState {
  status: SessionStatus;
  /** Timestamp of the round's first busy; `null` between rounds. */
  busySince: number | null;
  /** Pending debounce timer; `null` while no completion is scheduled. */
  idleTimer: TimerHandle | null;
  /**
   * Round elapsed frozen at the first idle of this debounce window;
   * `null` while no completion is pending.
   */
  pendingElapsedMs: number | null;
  /** Pending heartbeat timer; `null` while no round is heartbeating. */
  heartbeatTimer: TimerHandle | null;
  /** Whether the terminal event for the current round has been emitted. */
  terminalSent: boolean;
  /**
   * Highest-priority terminal outcome recorded for the current round;
   * `null` while the round has not terminated.
   */
  terminalOutcome: TerminalOutcome | null;
  /**
   * Pending action requests by INTERNAL key: `${kind}:${requestID}` for
   * question/permission (kind-namespaced, so identical upstream IDs of
   * different kinds never collide), the synthetic `provider:<sha256hex>`
   * requestId itself for a provider action. At most one `provider_action`
   * entry exists at a time.
   */
  pendingActions: Map<string, PendingActionKind>;
}

/**
 * Deterministic synthetic requestId / dedupe key for a provider action:
 * retry actions carry no upstream request ID, so identity is the SHA-256
 * hex of the canonical JSON encoding of
 * `[sessionID, provider, reason ?? title, label]`, prefixed `provider:`
 * (73 chars total — bounded regardless of field lengths). The JSON array
 * keeps field boundaries unambiguous: values containing delimiters cannot
 * collide across positions. Only identity fields are hashed — the
 * free-text `message`/`link` and any secret-bearing content never feed
 * the digest.
 */
function providerActionKey(sessionID: string, action: SessionProviderAction): string {
  const identity = JSON.stringify([
    sessionID,
    action.provider,
    action.reason ?? action.title,
    action.label,
  ]);
  return `provider:${createHash("sha256").update(identity).digest("hex")}`;
}

const systemScheduler: TimerScheduler = {
  setTimeout: (callback, delayMs) => setTimeout(callback, delayMs),
  clearTimeout: (handle) => clearTimeout(handle as Parameters<typeof clearTimeout>[0]),
  now: () => Date.now(),
};

export class SessionMachine {
  private readonly sessions = new Map<string, SessionState>();
  private readonly onCompleted: (completion: SessionCompletion) => void;
  private readonly heartbeatCallback: ((heartbeat: SessionHeartbeat) => void) | undefined;
  private readonly failedCallback: ((terminal: SessionTerminal) => void) | undefined;
  private readonly stoppedCallback: ((terminal: SessionTerminal) => void) | undefined;
  private readonly actionRequiredCallback: ((action: SessionActionRequired) => void) | undefined;
  private readonly actionResolvedCallback: ((resolution: SessionActionResolved) => void) | undefined;
  private readonly idleDebounceMs: number;
  private readonly heartbeatMs: number;
  private readonly scheduler: TimerScheduler;

  constructor(options: SessionMachineOptions) {
    this.onCompleted = options.onCompleted;
    this.heartbeatCallback = options.onHeartbeat;
    this.failedCallback = options.onFailed;
    this.stoppedCallback = options.onStopped;
    this.actionRequiredCallback = options.onActionRequired;
    this.actionResolvedCallback = options.onActionResolved;
    this.idleDebounceMs = options.idleDebounceMs ?? DEFAULT_IDLE_DEBOUNCE_MS;
    this.heartbeatMs = options.heartbeatMs ?? DEFAULT_HEARTBEAT_MS;
    this.scheduler = options.scheduler ?? systemScheduler;
  }

  /**
   * A session started (or continued) working: cancel any pending
   * completion and open the round if none is active, keeping the original
   * `busySince` of an already-active round. A busy never carries an
   * action, so any pending provider action is dropped silently; pending
   * question/permission requests survive.
   */
  onBusy(sessionID: string): void {
    this.onActive(sessionID, "busy");
    this.clearPendingProviderAction(this.stateFor(sessionID));
  }

  /**
   * A retry is the same core transition as busy: the session is still
   * working, so any pending completion is cancelled and the round (and its
   * original `busySince`) is kept.
   *
   * A retry may carry a provider action: it emits `action_required`
   * immediately with a deterministic synthetic requestId, deduped while
   * the identical action is still pending; a changed action replaces the
   * pending one (silently) and emits again.
   */
  onRetry(sessionID: string, action?: SessionProviderAction): void {
    this.onActive(sessionID, "retry");
    if (action !== undefined) {
      this.onProviderAction(sessionID, action);
    }
  }

  /**
   * A question request: emit `action_required` immediately, once per
   * upstream requestID. A duplicate ask while pending is suppressed and
   * keeps the first payload. Never touches round or timer state, so an
   * ask before any busy starts nothing.
   */
  onQuestionAsked(sessionID: string, requestID: string, questions: NormalizedQuestion[]): void {
    const state = this.stateFor(sessionID);
    const key = `question:${requestID}`;
    if (state.pendingActions.has(key)) {
      return;
    }
    // Recorded BEFORE the callback: a reentrant resolve from inside it
    // finds the request pending and resolves it exactly once.
    state.pendingActions.set(key, "question");
    this.actionRequiredCallback?.({ sessionID, requestId: requestID, kind: "question", questions });
  }

  /**
   * A permission request: same once-per-requestID immediate emission as
   * {@link onQuestionAsked}, carrying the permission name and its
   * sanitized summary.
   */
  onPermissionAsked(sessionID: string, requestID: string, permission: string, summary: string): void {
    const state = this.stateFor(sessionID);
    const key = `permission:${requestID}`;
    if (state.pendingActions.has(key)) {
      return;
    }
    state.pendingActions.set(key, "permission");
    this.actionRequiredCallback?.({
      sessionID,
      requestId: requestID,
      kind: "permission",
      permission: { permission, summary },
    });
  }

  /**
   * A question was answered or rejected (rejections arrive here via
   * `events.ts` as resolved): emit the silent `action_resolved` only if
   * the request is still pending, then drop it. Unknown or
   * already-resolved IDs emit nothing; the same ID may be asked again
   * afterwards.
   */
  onQuestionResolved(sessionID: string, requestID: string): void {
    this.onResolved(sessionID, "question", requestID);
  }

  /** A permission request was replied: same path as {@link onQuestionResolved}. */
  onPermissionResolved(sessionID: string, requestID: string): void {
    this.onResolved(sessionID, "permission", requestID);
  }

  /**
   * The session failed: emit the terminal immediately (once per round),
   * cancelling any pending completion debounce. The elapsed is the frozen
   * idle snapshot when a debounce was pending, else the actual round
   * elapsed — debounce time is never counted.
   */
  onFailed(sessionID: string): void {
    this.onTerminalSignal(sessionID, "failed");
  }

  /**
   * The session was stopped (user abort; abort-classified errors arrive
   * here via `events.ts`): same immediate, once-per-round terminal as
   * {@link onFailed}, with `stopped` outranking `failed` for the round's
   * recorded outcome.
   */
  onStopped(sessionID: string): void {
    this.onTerminalSignal(sessionID, "stopped");
  }

  /**
   * The session went idle (status form or deprecated marker — identical
   * here): close the active period, snapshot the round elapsed, and ensure
   * exactly one debounce timer is pending. A repeat idle while a timer is
   * pending merges into it, keeping the first snapshot.
   */
  onIdle(sessionID: string): void {
    const state = this.stateFor(sessionID);
    state.status = "idle";
    this.clearHeartbeat(state);
    if (state.idleTimer !== null) {
      return;
    }
    // After a terminal (completed/failed/stopped), a further idle without
    // an intervening busy is a duplicate signal, not a new round.
    if (state.terminalSent) {
      return;
    }
    state.pendingElapsedMs =
      state.busySince === null
        ? 0
        : Math.max(0, this.scheduler.now() - state.busySince);
    state.idleTimer = this.scheduler.setTimeout(() => {
      state.idleTimer = null;
      this.completePendingIdle(sessionID, state);
    }, this.idleDebounceMs);
  }

  /**
   * Settle every round that has already entered the idle debounce. OpenCode
   * calls plugin disposal immediately after `opencode run` becomes idle, so
   * its process may end before even a 1 ms timer gets a turn. Shutdown proves
   * that no later busy signal can invalidate the pending idle, making it safe
   * to emit these completions early. Active rounds are left untouched.
   */
  flushPendingCompletions(): void {
    for (const [sessionID, state] of this.sessions) {
      if (state.idleTimer === null) {
        continue;
      }
      this.scheduler.clearTimeout(state.idleTimer);
      state.idleTimer = null;
      this.completePendingIdle(sessionID, state);
    }
  }

  /** Clear every timer and all per-session state. */
  disposeAll(): void {
    for (const state of this.sessions.values()) {
      if (state.idleTimer !== null) {
        this.scheduler.clearTimeout(state.idleTimer);
        state.idleTimer = null;
      }
      if (state.heartbeatTimer !== null) {
        this.scheduler.clearTimeout(state.heartbeatTimer);
        state.heartbeatTimer = null;
      }
    }
    this.sessions.clear();
  }

  private onActive(sessionID: string, status: "busy" | "retry"): void {
    const state = this.stateFor(sessionID);
    if (state.idleTimer !== null) {
      this.scheduler.clearTimeout(state.idleTimer);
      state.idleTimer = null;
    }
    // A busy/retry also discards any frozen snapshot: the round is active
    // again, so the next idle re-snapshots from the original busySince.
    state.pendingElapsedMs = null;
    if (state.busySince === null) {
      // A fresh round (also after any terminal): reset the terminal state.
      state.busySince = this.scheduler.now();
      state.terminalSent = false;
      state.terminalOutcome = null;
    }
    state.status = status;
    this.armHeartbeat(sessionID, state);
  }

  /**
   * Schedule the heartbeat unless one is already pending — a busy/retry
   * inside an active round updates the status only, never the timer. No
   * heartbeat exists without the callback: there would be no observer.
   */
  private armHeartbeat(sessionID: string, state: SessionState): void {
    if (this.heartbeatCallback === undefined || state.heartbeatTimer !== null) {
      return;
    }
    state.heartbeatTimer = this.scheduler.setTimeout(
      () => this.onHeartbeatTick(sessionID, state),
      this.heartbeatMs,
    );
  }

  /**
   * Emit one heartbeat with the current status and the elapsed from the
   * round's original `busySince`, then re-arm ONLY if the round is still
   * active after the (possibly reentrant) callback — an idle or terminal
   * delivered from inside the callback must not keep the heartbeat alive.
   */
  private onHeartbeatTick(sessionID: string, state: SessionState): void {
    state.heartbeatTimer = null;
    if (state.busySince !== null && state.status !== "idle") {
      const status: "busy" | "retry" = state.status;
      this.heartbeatCallback?.({
        sessionID,
        status,
        elapsedMs: Math.max(0, this.scheduler.now() - state.busySince),
      });
    }
    if (
      this.sessions.get(sessionID) === state &&
      state.busySince !== null &&
      state.status !== "idle" &&
      state.heartbeatTimer === null
    ) {
      this.armHeartbeat(sessionID, state);
    }
  }

  private clearHeartbeat(state: SessionState): void {
    if (state.heartbeatTimer !== null) {
      this.scheduler.clearTimeout(state.heartbeatTimer);
      state.heartbeatTimer = null;
    }
  }

  /** Complete one round whose idle timer fired or was flushed at shutdown. */
  private completePendingIdle(sessionID: string, state: SessionState): void {
    if (state.terminalSent) {
      return;
    }
    state.terminalSent = true;
    state.terminalOutcome = "completed";
    state.busySince = null;
    // A completed round drops every pending action silently — no
    // fabricated action_resolved events.
    state.pendingActions.clear();
    const elapsedMs = state.pendingElapsedMs ?? 0;
    state.pendingElapsedMs = null;
    this.onCompleted({ sessionID, elapsedMs });
  }

  /**
   * Drop the pending provider action (at most one exists) without any
   * `action_resolved` — provider actions never resolve.
   */
  private clearPendingProviderAction(state: SessionState): void {
    for (const [requestId, kind] of state.pendingActions) {
      if (kind === "provider_action") {
        state.pendingActions.delete(requestId);
      }
    }
  }

  /**
   * A retry carrying a provider action: emit immediately with the
   * deterministic synthetic requestId. The identical action still pending
   * is suppressed; a changed action replaces the pending one (silently)
   * and emits again.
   */
  private onProviderAction(sessionID: string, action: SessionProviderAction): void {
    const state = this.stateFor(sessionID);
    const requestId = providerActionKey(sessionID, action);
    if (state.pendingActions.get(requestId) === "provider_action") {
      return;
    }
    this.clearPendingProviderAction(state);
    state.pendingActions.set(requestId, "provider_action");
    const details: SessionProviderActionDetails = {
      provider: action.provider,
      title: action.title,
      message: action.message,
      label: action.label,
      ...(action.link === undefined ? {} : { link: action.link }),
    };
    this.actionRequiredCallback?.({
      sessionID,
      requestId,
      kind: "provider_action",
      providerAction: details,
    });
  }

  /**
   * Shared question/permission resolve: emit the silent `action_resolved`
   * only when a request of the SAME kind is pending under that requestID
   * (the kind-namespaced key makes a provider action — or the other kind —
   * under the same upstream ID unreachable here), then drop it. Removed
   * BEFORE the callback so a reentrant duplicate resolve from inside it
   * emits nothing.
   */
  private onResolved(sessionID: string, kind: "question" | "permission", requestID: string): void {
    const state = this.stateFor(sessionID);
    const key = `${kind}:${requestID}`;
    if (state.pendingActions.get(key) !== kind) {
      return;
    }
    state.pendingActions.delete(key);
    this.actionResolvedCallback?.({ sessionID, requestId: requestID, kind });
  }

  /**
   * Shared failed/stopped transition: cancel the debounce and heartbeat,
   * close the round, record the outcome by priority
   * (`stopped > failed > completed`), and emit the terminal exactly once
   * per round — immediately, never debounced.
   */
  private onTerminalSignal(sessionID: string, outcome: "failed" | "stopped"): void {
    const state = this.stateFor(sessionID);
    // Frozen idle snapshot when the debounce is pending, else the actual
    // round elapsed: both exclude any debounce wait.
    const elapsedMs =
      state.pendingElapsedMs ??
      (state.busySince === null ? 0 : Math.max(0, this.scheduler.now() - state.busySince));
    if (state.idleTimer !== null) {
      this.scheduler.clearTimeout(state.idleTimer);
      state.idleTimer = null;
    }
    state.pendingElapsedMs = null;
    this.clearHeartbeat(state);
    state.busySince = null;
    state.status = "idle";
    // A terminal round drops every pending action silently — no fabricated
    // action_resolved events.
    state.pendingActions.clear();
    if (
      state.terminalOutcome === null ||
      OUTCOME_RANK[outcome] > OUTCOME_RANK[state.terminalOutcome]
    ) {
      state.terminalOutcome = outcome;
    }
    if (state.terminalSent) {
      return;
    }
    // All state is settled BEFORE the callback: a reentrant busy from
    // inside it opens a fresh round without being clobbered.
    state.terminalSent = true;
    const terminal: SessionTerminal = { sessionID, elapsedMs };
    if (outcome === "failed") {
      this.failedCallback?.(terminal);
    } else {
      this.stoppedCallback?.(terminal);
    }
  }

  private stateFor(sessionID: string): SessionState {
    let state = this.sessions.get(sessionID);
    if (state === undefined) {
      state = {
        status: "idle",
        busySince: null,
        idleTimer: null,
        pendingElapsedMs: null,
        heartbeatTimer: null,
        terminalSent: false,
        terminalOutcome: null,
        pendingActions: new Map(),
      };
      this.sessions.set(sessionID, state);
    }
    return state;
  }
}
