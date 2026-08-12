/**
 * Outbound mail boundary (plan: stable interface). Implementations deliver
 * plaintext one-time codes over SMTP; nothing hashed ever crosses this
 * boundary. Password reset mails are part of the interface from the start
 * and are wired by the reset task.
 */
export interface Mailer {
  sendVerificationEmail(to: string, code: string): Promise<void>;
  sendPasswordResetEmail(to: string, code: string): Promise<void>;
}

/**
 * Delivery failure of the underlying transport. Callers treat this as
 * retryable: the operation that triggered the mail can be repeated later.
 * The message is generic on purpose — transport internals must not leak
 * into API responses.
 */
export class MailerError extends Error {
  constructor(message = "Email delivery failed", options?: { cause?: unknown }) {
    super(message, options);
    this.name = "MailerError";
  }
}
