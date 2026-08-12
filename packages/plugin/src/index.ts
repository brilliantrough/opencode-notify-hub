/**
 * OpenCode plugin entrypoint: the never-throw notification pipeline.
 *
 * Wiring (valid configuration only):
 *   OpenCode event hook → `normalizeEvent` → fail-closed main-session gate
 *   (`SessionRegistry` over `createSdkLookup(client.session)`) →
 *   `SessionMachine` / `MessageCache` → machine effects →
 *   `EnvelopeFactory` (contract-validated) → `QueuePump` →
 *   `GatewaySender` (signed POST).
 *
 * The hard rules of this module:
 * - **The hook never throws and never awaits the network.** Its async
 *   body catches everything and resolves; the only await is the SDK
 *   ancestry lookup (explicitly permitted). Delivery is fire-and-forget
 *   through the pump's non-blocking kick.
 * - **Fail closed.** An invalid configuration disables the plugin (empty
 *   hooks plus one secret-free warning). Unknown session ancestry drops
 *   the event with a warning that carries only the session id.
 * - **Nothing sensitive is logged.** Log context carries ids, kinds, and
 *   counts only — never message/action/permission payloads. The logger
 *   additionally scrubs the ingest credential from anything it emits.
 * - **The envelope boundary never lets an invalid event escape.** Any
 *   validator/factory failure drops the event and logs a sanitized
 *   reason; queue/enqueue throws are absorbed the same way.
 *
 * `dispose` flushes any already-pending idle completion, clears machine
 * timers, drains accepted deliveries, and drops cached message state. It
 * never throws.
 */

import type { Hooks, Plugin, PluginInput } from "@opencode-ai/plugin";
import type { NotifyEvent } from "@notify/contracts";

import { loadConfig, type PluginConfig } from "./config.js";
import {
  EnvelopeFactory,
  type EnvelopeSession,
  type TerminalOutcome,
} from "./envelope.js";
import { normalizeEvent, type NormalizedEvent } from "./events.js";
import { createSafeLogger, type SafeLogger } from "./log.js";
import { MessageCache } from "./message-cache.js";
import { QueuePump } from "./pump.js";
import { GatewaySender } from "./sender.js";
import {
  createSdkLookup,
  SessionRegistry,
  type SessionLookup,
} from "./session-registry.js";
import { SessionMachine, type SessionTerminal } from "./state-machine.js";

/** Service name stamped on every structured log entry. */
export const LOG_SERVICE = "opencode-notify";

/**
 * The pump surface the wiring consumes (`QueuePump` satisfies it).
 * Injectable so tests can prove queue throws are absorbed.
 */
export interface NotificationPump {
  enqueue(event: NotifyEvent): unknown;
  stop(): Promise<void>;
}

/** Construction seams; production uses none of them. */
export interface SessionNotifyDeps {
  /** Ancestry lookup; defaults to `createSdkLookup(input.client.session)`. */
  lookup?: SessionLookup;
  /** Structured logger; defaults to a safe logger over `client.app.log`. */
  logger?: SafeLogger;
  /** Fetch seam handed to the gateway sender. */
  fetch?: typeof fetch;
  /** Queue/pump seam; defaults to a real `QueuePump` over `GatewaySender`. */
  pump?: NotificationPump;
}

/** Contract sections require nonempty strings; fall back instead of dropping. */
function safeNonEmpty(value: unknown, fallback: string): string {
  return typeof value === "string" && value.trim().length > 0 ? value : fallback;
}

function describeError(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}

/**
 * Build the enabled plugin hooks from a validated configuration. Every
 * callback path is defensive: machine effects, envelope construction,
 * cache access, and queue insertion are individually wrapped, so one
 * failing subsystem can never take down the event hook.
 */
export function createSessionNotifyHooks(
  input: PluginInput,
  config: PluginConfig,
  deps: SessionNotifyDeps = {},
): Hooks {
  const logger =
    deps.logger ??
    createSafeLogger({
      service: LOG_SERVICE,
      secrets: [
        `${config.ingestKey.keyId}.${config.ingestKey.secret}`,
        config.ingestKey.secret,
        config.ingestKey.keyId,
      ],
      sink: (entry) => input.client.app.log({ body: entry }),
    });
  const registry = new SessionRegistry(
    deps.lookup ?? createSdkLookup(input.client.session),
  );
  const cache = new MessageCache();
  const envelopes = new EnvelopeFactory({
    source: {
      machine: config.machine,
      project: safeNonEmpty(input.project?.id, "unknown"),
      directory: safeNonEmpty(input.directory, safeNonEmpty(input.worktree, "unknown")),
    },
    includeSummary: config.includeSummary,
  });
  const pump =
    deps.pump ??
    new QueuePump({
      sender: new GatewaySender({
        gatewayUrl: config.gatewayUrl,
        ingestKey: config.ingestKey,
        timeoutMs: config.httpTimeoutMs,
        maxRetries: config.maxRetries,
        fetch: deps.fetch,
      }),
      logger,
      capacity: config.queueCapacity,
    });

  function sessionOf(sessionID: string): EnvelopeSession {
    return { id: sessionID, title: registry.title(sessionID) };
  }

  /** Enqueue an already-valid event; a broken queue drops it, logged. */
  function enqueueSafe(event: NotifyEvent): void {
    try {
      pump.enqueue(event);
    } catch (error) {
      logger.error("notify: failed to queue event; dropping it", {
        eventId: event.eventId,
        eventType: event.type,
        reason: describeError(error),
      });
    }
  }

  /**
   * Build one envelope and hand it to the pump. A validator/factory
   * failure drops the event with a sanitized reason (envelope errors are
   * contract paths and ids, never payload data).
   */
  function emit(build: () => NotifyEvent): void {
    let event: NotifyEvent;
    try {
      event = build();
    } catch (error) {
      logger.error("notify: event failed validation; dropping it", {
        reason: describeError(error),
      });
      return;
    }
    enqueueSafe(event);
  }

  /**
   * The round's terminal event. The outcome is exactly the one the
   * machine emitted on this callback channel. The assistant-only summary
   * is read BEFORE the session's cache is cleared (the round is over),
   * and clearing happens even when the envelope cannot be built.
   */
  function emitTerminal(
    sessionID: string,
    terminal: SessionTerminal,
    outcome: TerminalOutcome,
  ): void {
    let summary: string | undefined;
    try {
      summary = cache.summary(sessionID);
    } catch (error) {
      logger.error("notify: failed to read message summary", {
        sessionID,
        reason: describeError(error),
      });
    }
    emit(() => envelopes.terminal(sessionOf(sessionID), terminal, outcome, summary));
    try {
      cache.clearSession(sessionID);
    } catch (error) {
      logger.error("notify: failed to clear message cache", {
        sessionID,
        reason: describeError(error),
      });
    }
  }

  const machine = new SessionMachine({
    idleDebounceMs: config.idleDebounceMs,
    heartbeatMs: config.heartbeatMs,
    onCompleted: (completion) => emitTerminal(completion.sessionID, completion, "completed"),
    onHeartbeat: (heartbeat) =>
      emit(() => envelopes.heartbeat(sessionOf(heartbeat.sessionID), heartbeat)),
    onFailed: (terminal) => emitTerminal(terminal.sessionID, terminal, "failed"),
    onStopped: (terminal) => emitTerminal(terminal.sessionID, terminal, "stopped"),
    onActionRequired: (action) =>
      emit(() => envelopes.actionRequired(sessionOf(action.sessionID), action)),
    onActionResolved: (resolution) =>
      emit(() => envelopes.actionResolved(sessionOf(resolution.sessionID), resolution)),
  });
  let disposed = false;

  /** Route one normalized main-session event; never throws. */
  function dispatch(normalized: NormalizedEvent): void {
    try {
      switch (normalized.kind) {
        case "session.status":
          if (normalized.status === "busy") {
            machine.onBusy(normalized.sessionID);
          } else if (normalized.status === "retry") {
            machine.onRetry(normalized.sessionID, normalized.retry?.action);
          } else {
            machine.onIdle(normalized.sessionID);
          }
          break;
        case "session.error":
          if (normalized.sessionID === undefined) {
            break; // unreachable: filtered before the ancestry gate
          }
          if (normalized.outcome === "stopped") {
            machine.onStopped(normalized.sessionID);
          } else {
            machine.onFailed(normalized.sessionID);
          }
          break;
        case "message":
          cache.onRole(normalized.sessionID, normalized.messageID, normalized.role);
          if (normalized.outcome === "stopped") {
            machine.onStopped(normalized.sessionID);
          } else if (normalized.outcome === "failed") {
            machine.onFailed(normalized.sessionID);
          }
          break;
        case "message.text":
          cache.onText(normalized.sessionID, normalized.messageID, normalized.text);
          break;
        case "question.asked":
          machine.onQuestionAsked(normalized.sessionID, normalized.requestID, normalized.questions);
          break;
        case "question.resolved":
          machine.onQuestionResolved(normalized.sessionID, normalized.requestID);
          break;
        case "permission.asked":
          machine.onPermissionAsked(
            normalized.sessionID,
            normalized.requestID,
            normalized.permission,
            normalized.summary,
          );
          break;
        case "permission.resolved":
          machine.onPermissionResolved(normalized.sessionID, normalized.requestID);
          break;
      }
    } catch (error) {
      logger.error("notify: dispatch failed; dropping event", {
        kind: normalized.kind,
        sessionID: normalized.sessionID,
        reason: describeError(error),
      });
    }
  }

  /**
   * The whole event pipeline, fail-closed at every stage. Only the
   * ancestry lookup is awaited; normalization happens inside a blanket
   * catch, and no return path rejects.
   */
  async function onEvent(raw: unknown): Promise<void> {
    if (disposed) {
      return;
    }
    let normalized: NormalizedEvent | null;
    try {
      normalized = normalizeEvent(raw);
    } catch {
      logger.error("notify: event normalization failed; dropping event");
      return;
    }
    if (normalized === null) {
      return;
    }

    // Session info is authoritative ancestry/title data; it updates the
    // registry directly and never passes through the main-session gate.
    if (normalized.kind === "session.upsert") {
      try {
        registry.update(normalized.sessionID, normalized.parentID ?? null, normalized.title);
      } catch {
        logger.error("notify: failed to record session info", {
          sessionID: normalized.sessionID,
        });
      }
      return;
    }

    const sessionID = normalized.sessionID;
    if (sessionID === undefined) {
      // A session error without a session id cannot be attributed to a
      // main session; drop it quietly (there is no safe id to log).
      logger.debug("notify: dropping session error without a session id");
      return;
    }

    let main: boolean | null;
    try {
      main = await registry.isMain(sessionID);
    } catch {
      main = null; // isMain is fail-closed by contract; belt and braces
    }
    if (main === null) {
      logger.warn("notify: session ancestry unknown; dropping event", { sessionID });
      return;
    }
    if (!main) {
      return; // child sessions are never notified
    }
    if (disposed) {
      return; // an ancestry lookup may have completed while disposal began
    }
    dispatch(normalized);
  }

  return {
    event: async ({ event: raw }) => {
      try {
        await onEvent(raw);
      } catch {
        // Unreachable by construction; the hook contract is absolute.
        logger.error("notify: unexpected event-hook failure; dropping event");
      }
    },
    dispose: async () => {
      disposed = true;
      try {
        machine.flushPendingCompletions();
      } catch {
        logger.error("notify: pending completion flush failed during dispose");
      }
      try {
        machine.disposeAll();
      } catch {
        logger.error("notify: session machine dispose failed");
      }
      try {
        await pump.stop();
      } catch {
        logger.error("notify: pump stop failed during dispose");
      }
      try {
        cache.clear();
      } catch {
        logger.error("notify: message cache clear failed");
      }
    },
  };
}

/**
 * The plugin entrypoint OpenCode loads. With a missing or invalid
 * NOTIFY_* configuration the plugin disables itself: empty hooks plus a
 * single warning that never echoes any environment value (above all the
 * ingest credential). Construction of the enabled pipeline is equally
 * fail-closed.
 */
export const SessionNotifyPlugin: Plugin = async (input) => {
  const bootstrapLogger = createSafeLogger({
    service: LOG_SERVICE,
    sink: (entry) => input.client.app.log({ body: entry }),
  });
  let config: PluginConfig | null;
  try {
    config = loadConfig();
  } catch {
    config = null; // loadConfig never throws by contract; belt and braces
  }
  if (config === null) {
    bootstrapLogger.warn(
      "opencode-notify disabled: missing or invalid NOTIFY_* configuration",
    );
    return {};
  }
  try {
    return createSessionNotifyHooks(input, config);
  } catch {
    bootstrapLogger.error("opencode-notify disabled: notification pipeline failed to initialize");
    return {};
  }
};

export default SessionNotifyPlugin;
