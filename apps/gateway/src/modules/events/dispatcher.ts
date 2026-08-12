import type { NotifyEvent } from "@notify/contracts";

import type {
  AndroidPushTarget,
  DevicePatch,
  DeviceRecord,
} from "../devices/devices.repository.js";
import { InvalidFcmTokenError, type FcmSender } from "../fcm/fcm-sender.js";
import {
  buildPushContent,
  CHANNEL_ALERTS,
  CHANNEL_SILENT,
  type PushContent,
} from "../fcm/payload.js";
import type { EventDispatcher } from "./events.routes.js";

/** Per-device ceiling for one FCM send; the send is abandoned, not retried. */
export const FCM_SEND_TIMEOUT_MS = 5000;

/**
 * One device send exceeded {@link FCM_SEND_TIMEOUT_MS}. Isolated and logged
 * like a generic send failure; the hanging send's late settlement is
 * ignored. Carries a log-safe code like the firebase errors do.
 */
export class FcmSendTimeoutError extends Error {
  readonly code = "notify/fcm-send-timeout";

  constructor() {
    super("FCM send timed out");
    this.name = "FcmSendTimeoutError";
  }
}

/**
 * The logging subset the dispatcher needs (pino-compatible). Only ever
 * called with IDs and error codes — never with tokens, event payloads, or
 * transport error messages (those can embed the token).
 */
export interface DispatchLogger {
  warn(obj: Record<string, unknown>, message: string): void;
  error(obj: Record<string, unknown>, message: string): void;
}

/**
 * The device-store subset the dispatcher needs. Structurally satisfied by
 * `DeviceRepository`; lookups are scoped to the event-owning user.
 */
export interface PushTargetStore {
  listAndroidPushTargets(userId: string): Promise<AndroidPushTarget[]>;
  update(input: {
    userId: string;
    id: string;
    patch: DevicePatch;
  }): Promise<DeviceRecord | null>;
}

export interface CompositeEventDispatcherDeps {
  /** WebSocket fanout (the connection registry). */
  realtime: EventDispatcher;
  devices: PushTargetStore;
  fcm: FcmSender;
  logger: DispatchLogger;
  /** Defaults to {@link FCM_SEND_TIMEOUT_MS}; tests pass a small value. */
  sendTimeoutMs?: number;
}

/**
 * Extract a log-safe transport code. The error message is deliberately
 * never logged: FCM error messages can embed the registration token.
 */
function errorCode(error: unknown): string | undefined {
  const code = (error as { code?: unknown } | null)?.code;
  return typeof code === "string" ? code : undefined;
}

/**
 * Composite fanout behind the ingest route's dispatcher seam.
 *
 * Every event is fanned out over WebSocket first (the registry never
 * rejects). Android push applies only to actionable events —
 * `action_required` and `terminal`; `heartbeat` and `action_resolved` are
 * realtime-only by design. The push content is built BEFORE the target
 * lookup, so an event that can never fit FCM skips the database entirely.
 * The lookup is scoped to the event-owning user's enabled Android targets.
 *
 * Devices are sent concurrently, each bounded by a per-device timeout; a
 * timeout is isolated and logged sanitized exactly like a generic failure.
 * Per-device failures never reject dispatch: an invalid or unregistered
 * token clears only that device's stored token (push eligibility), a
 * generic failure is logged sanitized and the remaining devices still send.
 *
 * The one failure that propagates is the target lookup itself: without the
 * target list no push decision is possible, so the error surfaces to the
 * ingest route, which answers a safe retryable 503 (nothing was committed).
 */
export class CompositeEventDispatcher implements EventDispatcher {
  private readonly realtime: EventDispatcher;
  private readonly devices: PushTargetStore;
  private readonly fcm: FcmSender;
  private readonly logger: DispatchLogger;
  private readonly sendTimeoutMs: number;

  constructor(deps: CompositeEventDispatcherDeps) {
    this.realtime = deps.realtime;
    this.devices = deps.devices;
    this.fcm = deps.fcm;
    this.logger = deps.logger;
    this.sendTimeoutMs = deps.sendTimeoutMs ?? FCM_SEND_TIMEOUT_MS;
  }

  async dispatch(input: { userId: string; event: NotifyEvent }): Promise<void> {
    const { userId, event } = input;
    await this.realtime.dispatch(input);
    if (event.type !== "action_required" && event.type !== "terminal") {
      return;
    }
    const content = buildPushContent(event);
    if (content === null) {
      // Never submit an oversized message; IDs only, no payload.
      this.logger.warn(
        { userId, eventId: event.eventId, type: event.type },
        "event exceeds the FCM size budget; skipping Android push",
      );
      return;
    }
    const targets = await this.devices.listAndroidPushTargets(userId);
    if (targets.length === 0) {
      return;
    }
    // Concurrent sends: one slow or hanging device must not delay the
    // others. allSettled cannot reject; per-device handling below absorbs
    // every failure, so dispatch itself stays rejection-free here.
    await Promise.allSettled(
      targets.map((target) => this.sendToTarget(userId, event.eventId, target, content)),
    );
  }

  private async sendToTarget(
    userId: string,
    eventId: string,
    target: AndroidPushTarget,
    content: PushContent,
  ): Promise<void> {
    try {
      await this.withTimeout(
        this.fcm.send({
          token: target.fcmToken,
          title: content.title,
          body: content.body,
          channelId: target.soundEnabled ? CHANNEL_ALERTS : CHANNEL_SILENT,
          dataEvent: content.dataEvent,
        }),
      );
    } catch (error) {
      if (error instanceof InvalidFcmTokenError) {
        this.logger.warn(
          {
            userId,
            deviceId: target.id,
            eventId,
            code: error.code,
          },
          "fcm registration token invalid; clearing device token",
        );
        try {
          // Clear only the token (mobile push eligibility); the device
          // itself and its enabled/sound preferences stay untouched.
          await this.devices.update({ userId, id: target.id, patch: { fcmToken: null } });
        } catch (cleanupError) {
          this.logger.error(
            {
              userId,
              deviceId: target.id,
              eventId,
              code: errorCode(cleanupError),
            },
            "failed to clear invalid fcm token",
          );
        }
      } else {
        this.logger.error(
          {
            userId,
            deviceId: target.id,
            eventId,
            code: errorCode(error),
          },
          "fcm send failed",
        );
      }
    }
  }

  /**
   * Race the send against the timeout. Both outcomes clear the timer; the
   * send's own settlement handler is attached up front, so a send that
   * rejects after the timeout fired is handled and never unhandled.
   */
  private withTimeout(promise: Promise<void>): Promise<void> {
    return new Promise<void>((resolve, reject) => {
      const timer = setTimeout(() => {
        reject(new FcmSendTimeoutError());
      }, this.sendTimeoutMs);
      promise.then(
        () => {
          clearTimeout(timer);
          resolve();
        },
        (error: unknown) => {
          clearTimeout(timer);
          reject(error instanceof Error ? error : new Error("fcm send failed"));
        },
      );
    });
  }
}
