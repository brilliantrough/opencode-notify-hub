import { randomBytes } from "node:crypto";

import { describe, expect, it } from "vitest";

import { ConfigError, loadConfig } from "../../src/config.js";

// Generated valid base64 decoding to 48 bytes (>= 32 required).
const validJwtSigningKey = randomBytes(48).toString("base64");

const validFirebaseServiceAccount = {
  project_id: "notify-test",
  client_email: "firebase-adminsdk@notify-test.iam.gserviceaccount.com",
  private_key: "-----BEGIN PRIVATE KEY-----\nTEST-KEY\n-----END PRIVATE KEY-----\n",
};

const validEnv: NodeJS.ProcessEnv = {
  DATABASE_URL: "postgres://user:pass@localhost:5432/notify",
  PUBLIC_BASE_URL: "https://notify.example.com",
  JWT_SIGNING_KEY: validJwtSigningKey,
  SMTP_HOST: "smtp.example.com",
  SMTP_PORT: "465",
  SMTP_SECURE: "true",
  SMTP_USER: "smtp-user",
  SMTP_PASSWORD: "smtp-password",
  SMTP_FROM: "OpenCode Notify <notify@example.com>",
  FIREBASE_SERVICE_ACCOUNT_JSON: JSON.stringify(validFirebaseServiceAccount),
  ALLOWED_ORIGINS: "https://app.example.com, https://admin.example.com",
  LOG_LEVEL: "info",
};

/** Runs loadConfig expecting failure and returns the ConfigError message. */
function issues(env: NodeJS.ProcessEnv): string {
  try {
    loadConfig(env);
  } catch (error) {
    expect(error).toBeInstanceOf(ConfigError);
    return (error as ConfigError).message;
  }
  throw new Error("loadConfig should have thrown");
}

describe("loadConfig", () => {
  it("parses a fully specified environment", () => {
    const config = loadConfig(validEnv);
    expect(config).toEqual({
      databaseUrl: "postgres://user:pass@localhost:5432/notify",
      publicBaseUrl: "https://notify.example.com",
      jwtSigningKey: validJwtSigningKey,
      smtp: {
        host: "smtp.example.com",
        port: 465,
        secure: true,
        user: "smtp-user",
        password: "smtp-password",
        from: "OpenCode Notify <notify@example.com>",
      },
      firebaseServiceAccountJson: validEnv.FIREBASE_SERVICE_ACCOUNT_JSON,
      allowedOrigins: ["https://app.example.com", "https://admin.example.com"],
      logLevel: "info",
    });
  });

  it("collects every missing variable instead of reading process.env", () => {
    const message = issues({});
    for (const name of Object.keys(validEnv)) {
      expect(message).toContain(name);
    }
  });

  it("rejects a blank required value", () => {
    expect(issues({ ...validEnv, JWT_SIGNING_KEY: "  " })).toContain("JWT_SIGNING_KEY");
  });

  it.each(["abc", "0", "70000", "1.5"])("rejects SMTP_PORT %s", (port) => {
    expect(issues({ ...validEnv, SMTP_PORT: port })).toContain("SMTP_PORT");
  });

  it.each(["yes", "1", "TRUE"])("rejects SMTP_SECURE %s", (secure) => {
    expect(issues({ ...validEnv, SMTP_SECURE: secure })).toContain("SMTP_SECURE");
  });

  it("rejects an unknown LOG_LEVEL", () => {
    expect(issues({ ...validEnv, LOG_LEVEL: "verbose" })).toContain("LOG_LEVEL");
  });

  it.each(["DATABASE_URL", "PUBLIC_BASE_URL"])("rejects a malformed %s", (name) => {
    expect(issues({ ...validEnv, [name]: "not a url" })).toContain(name);
  });

  it("rejects a non-https PUBLIC_BASE_URL", () => {
    expect(issues({ ...validEnv, PUBLIC_BASE_URL: "http://notify.example.com" })).toContain(
      "PUBLIC_BASE_URL",
    );
  });

  it.each(["postgresql://user:pass@localhost:5432/notify"])(
    "accepts DATABASE_URL scheme %s",
    (databaseUrl) => {
      expect(loadConfig({ ...validEnv, DATABASE_URL: databaseUrl }).databaseUrl).toBe(
        databaseUrl,
      );
    },
  );

  it.each(["mysql://user:pass@localhost/notify", "https://localhost/notify", "localhost/notify"])(
    "rejects DATABASE_URL scheme %s",
    (databaseUrl) => {
      expect(issues({ ...validEnv, DATABASE_URL: databaseUrl })).toContain("DATABASE_URL");
    },
  );

  it("accepts a base64 JWT_SIGNING_KEY decoding to exactly 32 bytes", () => {
    const key = randomBytes(32).toString("base64");
    expect(loadConfig({ ...validEnv, JWT_SIGNING_KEY: key }).jwtSigningKey).toBe(key);
  });

  it("rejects a JWT_SIGNING_KEY that is not valid base64", () => {
    expect(
      issues({ ...validEnv, JWT_SIGNING_KEY: "not valid base64!!!" }),
    ).toContain("JWT_SIGNING_KEY");
  });

  it("rejects a base64 JWT_SIGNING_KEY decoding below 32 bytes", () => {
    const shortKey = randomBytes(16).toString("base64");
    expect(issues({ ...validEnv, JWT_SIGNING_KEY: shortKey })).toContain("JWT_SIGNING_KEY");
  });

  it("rejects FIREBASE_SERVICE_ACCOUNT_JSON that does not parse", () => {
    expect(
      issues({ ...validEnv, FIREBASE_SERVICE_ACCOUNT_JSON: "{ not json" }),
    ).toContain("FIREBASE_SERVICE_ACCOUNT_JSON");
  });

  it("rejects FIREBASE_SERVICE_ACCOUNT_JSON missing required fields", () => {
    const message = issues({
      ...validEnv,
      FIREBASE_SERVICE_ACCOUNT_JSON: JSON.stringify({ project_id: "notify-test" }),
    });
    expect(message).toContain("FIREBASE_SERVICE_ACCOUNT_JSON");
    expect(message).toContain("client_email");
    expect(message).toContain("private_key");
  });

  it("rejects FIREBASE_SERVICE_ACCOUNT_JSON with empty required fields", () => {
    const message = issues({
      ...validEnv,
      FIREBASE_SERVICE_ACCOUNT_JSON: JSON.stringify({
        project_id: "  ",
        client_email: "sa@example.com",
        private_key: "key",
      }),
    });
    expect(message).toContain("project_id");
  });

  it("never includes FIREBASE_SERVICE_ACCOUNT_JSON values in the error", () => {
    const sentinel = "SENTINEL-PRIVATE-KEY-VALUE";
    const message = issues({
      ...validEnv,
      FIREBASE_SERVICE_ACCOUNT_JSON: JSON.stringify({
        project_id: "notify-test",
        private_key: sentinel,
      }),
    });
    expect(message).toContain("FIREBASE_SERVICE_ACCOUNT_JSON");
    expect(message).not.toContain(sentinel);
  });

  it("rejects ALLOWED_ORIGINS with no usable origin", () => {
    expect(issues({ ...validEnv, ALLOWED_ORIGINS: " , ," })).toContain("ALLOWED_ORIGINS");
  });

  it.each([
    "https://user:pass@app.example.com",
    "https://app.example.com/path",
    "https://app.example.com?x=1",
    "https://app.example.com#frag",
    "ftp://app.example.com",
    "app.example.com",
  ])("rejects ALLOWED_ORIGINS entry %s", (origin) => {
    expect(issues({ ...validEnv, ALLOWED_ORIGINS: origin })).toContain("ALLOWED_ORIGINS");
  });

  it("normalizes ALLOWED_ORIGINS entries to plain origins", () => {
    const config = loadConfig({
      ...validEnv,
      ALLOWED_ORIGINS: "https://app.example.com/, https://admin.example.com:8443",
    });
    expect(config.allowedOrigins).toEqual([
      "https://app.example.com",
      "https://admin.example.com:8443",
    ]);
  });

  it("accepts http origins for local development", () => {
    const config = loadConfig({ ...validEnv, ALLOWED_ORIGINS: "http://localhost:3000" });
    expect(config.allowedOrigins).toEqual(["http://localhost:3000"]);
  });
});
