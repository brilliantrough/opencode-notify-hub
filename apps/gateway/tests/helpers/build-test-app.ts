import { generateKeyPairSync } from "node:crypto";

import type { FastifyInstance } from "fastify";

import { buildServer } from "../../src/app.js";
import type { GatewayConfig } from "../../src/config.js";
import type { FcmSender } from "../../src/modules/fcm/fcm-sender.js";

/**
 * Throwaway RSA key generated at load: firebase-admin's `cert()` parses the
 * private key eagerly, so tests need a structurally real PEM (it never
 * leaves the process or touches the network).
 */
const TEST_FIREBASE_PRIVATE_KEY = generateKeyPairSync("rsa", { modulusLength: 2048 })
  .privateKey.export({ type: "pkcs8", format: "pem" })
  .toString();

export const TEST_JWT_SIGNING_KEY = Buffer.from(
  "0123456789abcdef0123456789abcdef",
).toString("base64"); // exactly 32 decoded bytes

export const TEST_FIREBASE_SERVICE_ACCOUNT = {
  project_id: "notify-test",
  client_email: "firebase-adminsdk@notify-test.iam.gserviceaccount.com",
  private_key: TEST_FIREBASE_PRIVATE_KEY,
};

/**
 * No-op push sender for integration tests with fake config: injecting it
 * through `GatewayDeps.fcmSender` keeps the production composition (composite
 * dispatcher) while never initializing Firebase or touching the network.
 */
export const noopFcmSender: FcmSender = {
  async send(): Promise<void> {},
};

export function buildTestConfig(overrides: Partial<GatewayConfig> = {}): GatewayConfig {
  return {
    databaseUrl: "postgres://user:pass@localhost:5432/notify_test",
    publicBaseUrl: "https://notify.test",
    jwtSigningKey: TEST_JWT_SIGNING_KEY,
    smtp: {
      host: "smtp.test",
      port: 587,
      secure: false,
      user: "smtp-user",
      password: "smtp-password",
      from: "OpenCode Notify <notify@test>",
    },
    firebaseServiceAccountJson: JSON.stringify(TEST_FIREBASE_SERVICE_ACCOUNT),
    allowedOrigins: ["https://app.test"],
    logLevel: "silent",
    ...overrides,
  };
}

export async function buildTestApp(
  overrides: Partial<GatewayConfig> = {},
): Promise<FastifyInstance> {
  return buildServer({ config: buildTestConfig(overrides) });
}
