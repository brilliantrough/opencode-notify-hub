export const LOG_LEVELS = [
  "fatal",
  "error",
  "warn",
  "info",
  "debug",
  "trace",
  "silent",
] as const;

export type LogLevel = (typeof LOG_LEVELS)[number];

export interface SmtpConfig {
  host: string;
  port: number;
  secure: boolean;
  user: string;
  password: string;
  from: string;
}

/**
 * Validated runtime configuration of the gateway.
 *
 * Every field maps to one of the environment variables listed in the
 * approved specification (design doc section 13): DATABASE_URL,
 * PUBLIC_BASE_URL, JWT_SIGNING_KEY, SMTP_HOST, SMTP_PORT, SMTP_SECURE,
 * SMTP_USER, SMTP_PASSWORD, SMTP_FROM, FIREBASE_SERVICE_ACCOUNT_JSON,
 * ALLOWED_ORIGINS, LOG_LEVEL.
 */
export interface GatewayConfig {
  databaseUrl: string;
  publicBaseUrl: string;
  jwtSigningKey: string;
  smtp: SmtpConfig;
  firebaseServiceAccountJson: string;
  allowedOrigins: string[];
  logLevel: LogLevel;
}

export class ConfigError extends Error {
  readonly issues: string[];

  constructor(issues: string[]) {
    super(`Invalid gateway configuration: ${issues.join("; ")}`);
    this.name = "ConfigError";
    this.issues = issues;
  }
}

const DATABASE_URL_PROTOCOLS = ["postgres:", "postgresql:"] as const;

const FIREBASE_REQUIRED_FIELDS = ["project_id", "client_email", "private_key"] as const;

const MIN_JWT_SIGNING_KEY_BYTES = 32;

/** Strict base64 whose decoded form is at least `minBytes` long. */
function isBase64OfMinBytes(value: string, minBytes: number): boolean {
  if (value.length % 4 !== 0 || !/^[A-Za-z0-9+/]*={0,2}$/.test(value)) {
    return false;
  }
  return Buffer.from(value, "base64").length >= minBytes;
}

/**
 * Absolute http(s) origin without credentials, path, query, or fragment,
 * normalized via `URL.origin` (lowercase host, default port dropped, no
 * trailing slash). Returns null when the entry is not a usable origin.
 */
function parseOrigin(entry: string): string | null {
  let url: URL;
  try {
    url = new URL(entry);
  } catch {
    return null;
  }
  if (url.protocol !== "https:" && url.protocol !== "http:") {
    return null;
  }
  if (url.username !== "" || url.password !== "") {
    return null;
  }
  if (url.pathname !== "/" || url.search !== "" || url.hash !== "") {
    return null;
  }
  return url.origin;
}

/**
 * Validate the specification environment variables and return the typed
 * configuration. Tests and embedding tools pass an explicit `env` object so
 * no process-global production secrets are required; the entrypoint relies
 * on the `process.env` default. All problems are collected and reported in
 * a single {@link ConfigError}; error messages name variables and fields
 * but never echo secret values.
 */
export function loadConfig(env: NodeJS.ProcessEnv = process.env): GatewayConfig {
  const issues: string[] = [];

  const read = (name: string): string => {
    const value = env[name];
    if (value === undefined || value.trim() === "") {
      issues.push(`${name} is required`);
      return "";
    }
    return value.trim();
  };

  const readUrl = (name: string): { value: string; url: URL | null } => {
    const value = read(name);
    if (value === "") {
      return { value, url: null };
    }
    try {
      return { value, url: new URL(value) };
    } catch {
      issues.push(`${name} must be a valid URL`);
      return { value, url: null };
    }
  };

  const { value: databaseUrlValue, url: databaseUrl } = readUrl("DATABASE_URL");
  if (databaseUrl !== null && !(DATABASE_URL_PROTOCOLS as readonly string[]).includes(databaseUrl.protocol)) {
    issues.push(`DATABASE_URL must use the postgres:// or postgresql:// scheme`);
  }

  const { value: publicBaseUrlValue, url: publicBaseUrl } = readUrl("PUBLIC_BASE_URL");
  if (publicBaseUrl !== null && publicBaseUrl.protocol !== "https:") {
    issues.push(`PUBLIC_BASE_URL must use the https:// scheme`);
  }

  const jwtSigningKey = read("JWT_SIGNING_KEY");
  if (jwtSigningKey !== "" && !isBase64OfMinBytes(jwtSigningKey, MIN_JWT_SIGNING_KEY_BYTES)) {
    issues.push(
      `JWT_SIGNING_KEY must be base64 decoding to at least ${MIN_JWT_SIGNING_KEY_BYTES} bytes`,
    );
  }

  const smtpHost = read("SMTP_HOST");

  const smtpPortRaw = read("SMTP_PORT");
  let smtpPort = 0;
  if (smtpPortRaw !== "") {
    if (!/^\d+$/.test(smtpPortRaw)) {
      issues.push(`SMTP_PORT must be an integer between 1 and 65535`);
    } else {
      smtpPort = Number.parseInt(smtpPortRaw, 10);
      if (smtpPort < 1 || smtpPort > 65535) {
        issues.push(`SMTP_PORT must be an integer between 1 and 65535`);
      }
    }
  }

  const smtpSecureRaw = read("SMTP_SECURE");
  let smtpSecure = false;
  if (smtpSecureRaw !== "") {
    if (smtpSecureRaw === "true") {
      smtpSecure = true;
    } else if (smtpSecureRaw === "false") {
      smtpSecure = false;
    } else {
      issues.push(`SMTP_SECURE must be "true" or "false"`);
    }
  }

  const smtpUser = read("SMTP_USER");
  const smtpPassword = read("SMTP_PASSWORD");
  const smtpFrom = read("SMTP_FROM");

  const firebaseServiceAccountJson = read("FIREBASE_SERVICE_ACCOUNT_JSON");
  if (firebaseServiceAccountJson !== "") {
    let parsed: unknown;
    try {
      parsed = JSON.parse(firebaseServiceAccountJson);
    } catch {
      issues.push(`FIREBASE_SERVICE_ACCOUNT_JSON must be valid JSON`);
      parsed = undefined;
    }
    if (parsed !== undefined) {
      const record =
        typeof parsed === "object" && parsed !== null
          ? (parsed as Record<string, unknown>)
          : {};
      const missing = FIREBASE_REQUIRED_FIELDS.filter(
        (field) => typeof record[field] !== "string" || (record[field] as string).trim() === "",
      );
      if (missing.length > 0) {
        issues.push(
          `FIREBASE_SERVICE_ACCOUNT_JSON requires non-empty fields: ${missing.join(", ")}`,
        );
      }
    }
  }

  const allowedOriginsRaw = read("ALLOWED_ORIGINS");
  const allowedOrigins: string[] = [];
  if (allowedOriginsRaw !== "") {
    const entries = allowedOriginsRaw
      .split(",")
      .map((entry) => entry.trim())
      .filter((entry) => entry !== "");
    if (entries.length === 0) {
      issues.push("ALLOWED_ORIGINS must list at least one origin");
    }
    entries.forEach((entry, index) => {
      const origin = parseOrigin(entry);
      if (origin === null) {
        issues.push(
          `ALLOWED_ORIGINS entry ${index + 1} must be an absolute http(s) origin without credentials, path, query, or fragment`,
        );
      } else {
        allowedOrigins.push(origin);
      }
    });
  }

  const logLevelRaw = read("LOG_LEVEL");
  let logLevel: LogLevel = "info";
  if (logLevelRaw !== "") {
    if ((LOG_LEVELS as readonly string[]).includes(logLevelRaw)) {
      logLevel = logLevelRaw as LogLevel;
    } else {
      issues.push(`LOG_LEVEL must be one of ${LOG_LEVELS.join(", ")}`);
    }
  }

  if (issues.length > 0) {
    throw new ConfigError(issues);
  }

  return {
    databaseUrl: databaseUrlValue,
    publicBaseUrl: publicBaseUrlValue,
    jwtSigningKey,
    smtp: {
      host: smtpHost,
      port: smtpPort,
      secure: smtpSecure,
      user: smtpUser,
      password: smtpPassword,
      from: smtpFrom,
    },
    firebaseServiceAccountJson,
    allowedOrigins,
    logLevel,
  };
}
