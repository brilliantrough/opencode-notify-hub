/**
 * Release-tooling gateway entry for the Issue #14 live closed loop.
 *
 * Runs the REAL gateway (the same `buildServer` the production entrypoint
 * uses) with three dev-only seams injected through `GatewayDeps`:
 *
 *   - a MailboxMailer that APPENDS `{to, code, at}` JSON lines to
 *     `MAILBOX_PATH` instead of sending SMTP (the closed loop reads the
 *     one-time verification code from that file);
 *   - a no-op FCM sender, so no Firebase app is ever initialized and no
 *     push network is touched;
 *   - a pino destination stream that writes the structured log to
 *     `GATEWAY_LOG` (production redaction still applies).
 *
 * Configuration validation is unchanged: every specification environment
 * variable must be present (`DATABASE_URL`, `PUBLIC_BASE_URL`,
 * `JWT_SIGNING_KEY`, `SMTP_*`, `ALLOWED_ORIGINS`, `LOG_LEVEL`). The
 * `FIREBASE_SERVICE_ACCOUNT_JSON` is synthesized here from a throwaway RSA
 * key so readiness (which parses it) passes while nothing real is used.
 *
 * Release tooling only; never wired into `pnpm test` or CI.
 */

import { generateKeyPairSync } from "node:crypto";
import { appendFileSync, createWriteStream, mkdirSync, type WriteStream } from "node:fs";
import { dirname } from "node:path";

import { buildServer } from "../src/app.js";
import { loadConfig } from "../src/config.js";
import { createDb } from "../src/db/client.js";
import type { FcmSender } from "../src/modules/fcm/fcm-sender.js";
import type { Mailer } from "../src/modules/mail/mailer.js";
import { installGracefulShutdown } from "../src/shutdown.js";

const ENV = process.env;

function required(name: string): string {
  const value = ENV[name]?.trim();
  if (value === undefined || value === "") {
    console.error(`beta dev gateway: ${name} is required`);
    process.exit(1);
  }
  return value;
}

/** Appends one `{to, code, at}` JSON line per delivery; never touches SMTP. */
class MailboxMailer implements Mailer {
  constructor(private readonly path: string) {}

  async sendVerificationEmail(to: string, code: string): Promise<void> {
    this.record(to, code, "verify");
  }

  async sendPasswordResetEmail(to: string, code: string): Promise<void> {
    this.record(to, code, "reset");
  }

  private record(to: string, code: string, kind: "verify" | "reset"): void {
    mkdirSync(dirname(this.path), { recursive: true });
    appendFileSync(
      this.path,
      JSON.stringify({ to, code, kind, at: new Date().toISOString() }) + "\n",
    );
  }
}

const noopFcmSender: FcmSender = { async send(): Promise<void> {} };

// A structurally real PEM (firebase-admin parses the private key eagerly at
// cert(); this key is throwaway and never leaves this process).
const devServiceAccount = {
  project_id: "notify-beta-loop",
  client_email: "firebase-adminsdk@notify-beta-loop.iam.gserviceaccount.com",
  private_key: generateKeyPairSync("rsa", { modulusLength: 2048 })
    .privateKey.export({ type: "pkcs8", format: "pem" })
    .toString(),
};

process.env.FIREBASE_SERVICE_ACCOUNT_JSON = JSON.stringify(devServiceAccount);

const config = loadConfig();
const mailboxPath = required("MAILBOX_PATH");
const gatewayLogPath = required("GATEWAY_LOG");

mkdirSync(dirname(gatewayLogPath), { recursive: true });
const logStream: WriteStream = createWriteStream(gatewayLogPath, { flags: "a" });

const db = createDb(config.databaseUrl);
const app = await buildServer({
  config,
  db: db.db,
  mailer: new MailboxMailer(mailboxPath),
  fcmSender: noopFcmSender,
  loggerStream: logStream,
});

installGracefulShutdown({
  app,
  closeDatabase: async () => {
    try {
      await db.close();
    } finally {
      // The pino stream is owned by this dev entry only; the app's
      // `preClose` hook already drained the realtime sockets.
      logStream.end();
    }
  },
});

const port = Number.parseInt(ENV.PORT ?? "8080", 10);
await app.listen({ host: "0.0.0.0", port });
console.log(`beta dev gateway listening on http://127.0.0.1:${port}`);
