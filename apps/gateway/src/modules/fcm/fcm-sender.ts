/**
 * One Android push delivery: a notification (title/body shown by the OS),
 * the notification channel, and the serialized event envelope carried in
 * `data.event` (already size-budgeted by the caller — see payload.ts).
 */
export interface FcmPush {
  token: string;
  title: string;
  body: string;
  channelId: string;
  /** Serialized event envelope for `data.event` (UTF-8, size-budgeted). */
  dataEvent: string;
}

/**
 * Outbound push boundary (plan: stable interface, like Mailer). The
 * composite dispatcher is the only caller; implementations wrap a concrete
 * FCM transport. Sending is per device: a rejected promise affects only
 * that device, never the dispatch as a whole.
 */
export interface FcmSender {
  send(push: FcmPush): Promise<void>;
}

/**
 * The target registration token is invalid or no longer registered. Not
 * retryable: the dispatcher responds by clearing the device's stored token
 * (the device must re-register) instead of letting ingest retry.
 *
 * The message is deliberately generic and the original transport error is
 * kept only as `cause` — transport messages can embed the token itself, so
 * only the firebase error `code` is safe to propagate/log.
 */
export class InvalidFcmTokenError extends Error {
  /** The firebase-admin error code, e.g. "messaging/registration-token-not-registered". */
  readonly code: string;

  constructor(code: string, options?: { cause?: unknown }) {
    super("FCM registration token is invalid or unregistered", options);
    this.name = "InvalidFcmTokenError";
    this.code = code;
  }
}
