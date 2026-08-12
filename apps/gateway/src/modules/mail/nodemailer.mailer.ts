import nodemailer, { type Transporter } from "nodemailer";

import type { SmtpConfig } from "../../config.js";
import { MailerError, type Mailer } from "./mailer.js";

/**
 * Delivery timeouts keep a dead SMTP server from stalling requests:
 * Nodemailer's defaults wait minutes, far beyond any HTTP client.
 */
const SMTP_TIMEOUT_MS = 10_000;

/**
 * Nodemailer-backed {@link Mailer} over the configured SMTP account. A new
 * transporter is created per adapter; the transport pool lives for the
 * adapter's lifetime.
 */
export class NodemailerMailer implements Mailer {
  private readonly transporter: Transporter;
  private readonly from: string;

  constructor(smtp: SmtpConfig) {
    this.from = smtp.from;
    this.transporter = nodemailer.createTransport({
      host: smtp.host,
      port: smtp.port,
      secure: smtp.secure,
      auth: { user: smtp.user, pass: smtp.password },
      connectionTimeout: SMTP_TIMEOUT_MS,
      greetingTimeout: SMTP_TIMEOUT_MS,
      socketTimeout: SMTP_TIMEOUT_MS,
    });
  }

  async sendVerificationEmail(to: string, code: string): Promise<void> {
    await this.send({
      to,
      subject: "Verify your OpenCode Notify account",
      text: `Your verification code is ${code}. It expires in 24 hours.`,
    });
  }

  async sendPasswordResetEmail(to: string, code: string): Promise<void> {
    await this.send({
      to,
      subject: "Reset your OpenCode Notify password",
      text: `Your password reset code is ${code}. It expires in 1 hour.`,
    });
  }

  /** Transport failures surface as a generic, retryable {@link MailerError}. */
  private async send(message: { to: string; subject: string; text: string }): Promise<void> {
    try {
      await this.transporter.sendMail({ from: this.from, ...message });
    } catch (cause) {
      throw new MailerError("Email delivery failed", { cause });
    }
  }
}
