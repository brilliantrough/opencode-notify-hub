import { cert, getApp, getApps, initializeApp } from "firebase-admin/app";
import { getMessaging, type Messaging } from "firebase-admin/messaging";

/**
 * The service account JSON failed validation. Raised before any Firebase
 * state is touched, so a bad config can never leave a half-initialized app.
 * Messages name fields, never echo secret values.
 */
export class InvalidServiceAccountError extends Error {
  constructor(issues: string[]) {
    super(`Invalid Firebase service account: ${issues.join("; ")}`);
    this.name = "InvalidServiceAccountError";
  }
}

interface ServiceAccount {
  projectId: string;
  clientEmail: string;
  privateKey: string;
}

const REQUIRED_FIELDS = ["project_id", "client_email", "private_key"] as const;

/**
 * Parse and validate the service account JSON (the same shape `loadConfig`
 * enforces for FIREBASE_SERVICE_ACCOUNT_JSON; this module re-validates at
 * its own boundary so callers cannot bypass it).
 */
export function parseServiceAccountJson(json: string): ServiceAccount {
  let parsed: unknown;
  try {
    parsed = JSON.parse(json);
  } catch {
    throw new InvalidServiceAccountError(["must be valid JSON"]);
  }
  const record = (
    typeof parsed === "object" && parsed !== null ? parsed : {}
  ) as Record<string, unknown>;
  const missing = REQUIRED_FIELDS.filter(
    (field) => typeof record[field] !== "string" || (record[field] as string).trim() === "",
  );
  if (missing.length > 0) {
    throw new InvalidServiceAccountError([
      `requires non-empty fields: ${missing.join(", ")}`,
    ]);
  }
  return {
    projectId: (record.project_id as string).trim(),
    clientEmail: (record.client_email as string).trim(),
    privateKey: record.private_key as string,
  };
}

/**
 * Duplicate-safe Messaging factory. Firebase apps are process-global and
 * `initializeApp` throws on a duplicate name, so the app is keyed by a
 * stable name derived from the service account's project ID: an existing
 * app (from a prior buildServer call, a test, or a hot reload) is reused
 * via `getApps()`/`getApp()` and only a genuinely absent one is created.
 */
export function messagingFromServiceAccountJson(json: string): Messaging {
  const serviceAccount = parseServiceAccountJson(json);
  const name = `notify-fcm-${serviceAccount.projectId}`;
  const app = getApps().some((candidate) => candidate.name === name)
    ? getApp(name)
    : initializeApp({ credential: cert(serviceAccount) }, name);
  return getMessaging(app);
}
