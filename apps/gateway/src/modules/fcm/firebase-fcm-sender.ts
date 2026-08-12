import type { Messaging } from "firebase-admin/messaging";

import { InvalidFcmTokenError, type FcmPush, type FcmSender } from "./fcm-sender.js";

/**
 * firebase-admin error codes that mean the registration token itself is
 * dead (invalid format or unregistered). Everything else (quota, internal,
 * unavailable, ...) is a generic, potentially transient failure.
 */
const INVALID_TOKEN_CODES: ReadonlySet<string> = new Set([
  "messaging/invalid-registration-token",
  "messaging/registration-token-not-registered",
]);

/**
 * FcmSender over the firebase-admin Messaging API. The Messaging handle is
 * injected (created from app credentials by the composition root), so this
 * adapter stays unit-testable with a fake and holds no auth state.
 *
 * Message shape: a visible notification plus the event envelope in
 * `data.event`; Android delivery is immediate-or-never (`ttl: 0` — the
 * event makes no sense delivered late) at high priority so doze does not
 * delay actionable alerts, routed into the device's notification channel.
 */
export class FirebaseAdminFcmSender implements FcmSender {
  constructor(private readonly messaging: Messaging) {}

  async send(push: FcmPush): Promise<void> {
    try {
      await this.messaging.send({
        token: push.token,
        notification: { title: push.title, body: push.body },
        data: { event: push.dataEvent },
        android: {
          ttl: 0,
          priority: "high",
          notification: { channelId: push.channelId },
        },
      });
    } catch (error) {
      const code = (error as { code?: unknown }).code;
      if (typeof code === "string" && INVALID_TOKEN_CODES.has(code)) {
        throw new InvalidFcmTokenError(code, { cause: error });
      }
      throw error;
    }
  }
}
