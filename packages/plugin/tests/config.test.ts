import { randomBytes } from "node:crypto";
import { hostname } from "node:os";

import { describe, expect, it } from "vitest";

import { loadConfig, parseIngestKey } from "../src/config.js";

/** Minimal valid environment: only the two required variables. */
function baseEnv(): NodeJS.ProcessEnv {
  return {
    NOTIFY_GATEWAY_URL: "https://gateway.example.com",
    NOTIFY_INGEST_KEY: "abcDEF123_-0.c2VjcmV0X3dpdGgtYmFzZTY0dXJs",
  };
}

describe("parseIngestKey", () => {
  it("splits on the first dot and preserves everything after it as the secret", () => {
    expect(parseIngestKey("keyId.secret.with.dots")).toEqual({
      keyId: "keyId",
      secret: "secret.with.dots",
    });
  });

  it("accepts base64url keyId characters (- and _)", () => {
    expect(parseIngestKey("a-b_c0.secret")).toEqual({ keyId: "a-b_c0", secret: "secret" });
  });

  it("returns null when there is no dot", () => {
    expect(parseIngestKey("keyIdOnly")).toBeNull();
  });

  it("returns null when the keyId is empty", () => {
    expect(parseIngestKey(".secret")).toBeNull();
  });

  it("returns null when the secret is empty", () => {
    expect(parseIngestKey("keyId.")).toBeNull();
  });

  it("returns null when the keyId is not base64url", () => {
    expect(parseIngestKey("ke+y.secret")).toBeNull();
    expect(parseIngestKey("key id.secret")).toBeNull();
  });
});

describe("loadConfig", () => {
  it("returns null when NOTIFY_GATEWAY_URL is missing", () => {
    const env = baseEnv();
    delete env.NOTIFY_GATEWAY_URL;
    expect(loadConfig(env)).toBeNull();
  });

  it("returns null when NOTIFY_INGEST_KEY is missing", () => {
    const env = baseEnv();
    delete env.NOTIFY_INGEST_KEY;
    expect(loadConfig(env)).toBeNull();
  });

  it("returns null when the ingest key is malformed", () => {
    expect(loadConfig({ ...baseEnv(), NOTIFY_INGEST_KEY: "no-dot-here" })).toBeNull();
  });

  it("rejects a dotted secret at load time even though the parser preserves it", () => {
    // parseIngestKey keeps the raw suffix (see its own test); loadConfig
    // enforces the issued format: both parts nonempty base64url, and dots
    // are not base64url.
    expect(parseIngestKey("keyId.secret.with.dots")).not.toBeNull();
    expect(loadConfig({ ...baseEnv(), NOTIFY_INGEST_KEY: "keyId.secret.with.dots" })).toBeNull();
  });

  it("rejects non-base64url keyId or secret at load time", () => {
    expect(loadConfig({ ...baseEnv(), NOTIFY_INGEST_KEY: "ke+y.secret" })).toBeNull();
    expect(loadConfig({ ...baseEnv(), NOTIFY_INGEST_KEY: "keyId.secret+with/slash" })).toBeNull();
    expect(loadConfig({ ...baseEnv(), NOTIFY_INGEST_KEY: "keyId.secret=with=padding" })).toBeNull();
  });

  it("loads a valid generated-style credential (12-char and 43-char base64url parts)", () => {
    const keyId = randomBytes(9).toString("base64url");
    const secret = randomBytes(32).toString("base64url");
    const config = loadConfig({ ...baseEnv(), NOTIFY_INGEST_KEY: `${keyId}.${secret}` });
    expect(config?.ingestKey).toEqual({ keyId, secret });
  });

  it("strips trailing slashes from the gateway URL", () => {
    expect(loadConfig({ ...baseEnv(), NOTIFY_GATEWAY_URL: "https://gateway.example.com/" })?.gatewayUrl).toBe(
      "https://gateway.example.com",
    );
    expect(loadConfig({ ...baseEnv(), NOTIFY_GATEWAY_URL: "https://gateway.example.com///" })?.gatewayUrl).toBe(
      "https://gateway.example.com",
    );
    expect(loadConfig({ ...baseEnv(), NOTIFY_GATEWAY_URL: "https://gateway.example.com/api/" })?.gatewayUrl).toBe(
      "https://gateway.example.com/api",
    );
  });

  it("rejects gateway URLs containing username or password", () => {
    expect(loadConfig({ ...baseEnv(), NOTIFY_GATEWAY_URL: "https://user:pass@gateway.example.com" })).toBeNull();
    expect(loadConfig({ ...baseEnv(), NOTIFY_GATEWAY_URL: "https://user@gateway.example.com" })).toBeNull();
    expect(loadConfig({ ...baseEnv(), NOTIFY_GATEWAY_URL: "http://user:pass@localhost:8080" })).toBeNull();
  });

  it("normalizes the stored URL via URL serialization (lowercase host, default port dropped)", () => {
    expect(
      loadConfig({ ...baseEnv(), NOTIFY_GATEWAY_URL: "https://GATEWAY.Example.COM/" })?.gatewayUrl,
    ).toBe("https://gateway.example.com");
    expect(
      loadConfig({ ...baseEnv(), NOTIFY_GATEWAY_URL: "https://gateway.example.com:443" })?.gatewayUrl,
    ).toBe("https://gateway.example.com");
    expect(
      loadConfig({ ...baseEnv(), NOTIFY_GATEWAY_URL: "https://gateway.example.com:8443/" })?.gatewayUrl,
    ).toBe("https://gateway.example.com:8443");
  });

  it("permits http only for loopback hosts (localhost / 127.0.0.1 / [::1]) in test development", () => {
    expect(
      loadConfig({ ...baseEnv(), NOTIFY_GATEWAY_URL: "http://localhost:8080" })?.gatewayUrl,
    ).toBe("http://localhost:8080");
    expect(
      loadConfig({ ...baseEnv(), NOTIFY_GATEWAY_URL: "http://127.0.0.1:8080/" })?.gatewayUrl,
    ).toBe("http://127.0.0.1:8080");
    expect(
      loadConfig({ ...baseEnv(), NOTIFY_GATEWAY_URL: "http://[::1]:8080/" })?.gatewayUrl,
    ).toBe("http://[::1]:8080");
  });

  it("rejects http for non-loopback hosts, including non-loopback IPv6", () => {
    expect(loadConfig({ ...baseEnv(), NOTIFY_GATEWAY_URL: "http://gateway.example.com" })).toBeNull();
    expect(loadConfig({ ...baseEnv(), NOTIFY_GATEWAY_URL: "ftp://gateway.example.com" })).toBeNull();
    expect(loadConfig({ ...baseEnv(), NOTIFY_GATEWAY_URL: "http://[2001:db8::1]:8080" })).toBeNull();
  });

  it("rejects gateway URLs carrying a query string or fragment", () => {
    expect(loadConfig({ ...baseEnv(), NOTIFY_GATEWAY_URL: "https://gw.example?x=1" })).toBeNull();
    expect(loadConfig({ ...baseEnv(), NOTIFY_GATEWAY_URL: "https://gw.example#frag" })).toBeNull();
    expect(loadConfig({ ...baseEnv(), NOTIFY_GATEWAY_URL: "http://localhost:8080/?a=b" })).toBeNull();
  });

  it("returns null for an unparseable gateway URL", () => {
    expect(loadConfig({ ...baseEnv(), NOTIFY_GATEWAY_URL: "not a url" })).toBeNull();
  });

  it("applies the documented defaults when only required variables are set", () => {
    const config = loadConfig(baseEnv());
    expect(config).toEqual({
      gatewayUrl: "https://gateway.example.com",
      ingestKey: { keyId: "abcDEF123_-0", secret: "c2VjcmV0X3dpdGgtYmFzZTY0dXJs" },
      machine: hostname(),
      includeSummary: false,
      queueCapacity: 100,
      heartbeatMs: 60000,
      idleDebounceMs: 15000,
      httpTimeoutMs: 5000,
      maxRetries: 3,
    });
  });

  it("accepts valid numeric and boolean overrides", () => {
    const config = loadConfig({
      ...baseEnv(),
      NOTIFY_QUEUE_CAPACITY: "250",
      NOTIFY_HEARTBEAT_MS: "30000",
      NOTIFY_IDLE_DEBOUNCE_MS: "5000",
      NOTIFY_HTTP_TIMEOUT_MS: "10000",
      NOTIFY_MAX_RETRIES: "5",
      NOTIFY_INCLUDE_SUMMARY: "true",
      NOTIFY_MACHINE: "build-runner-1",
    });
    expect(config).toMatchObject({
      queueCapacity: 250,
      heartbeatMs: 30000,
      idleDebounceMs: 5000,
      httpTimeoutMs: 10000,
      maxRetries: 5,
      includeSummary: true,
      machine: "build-runner-1",
    });
  });

  it.each([
    ["NOTIFY_QUEUE_CAPACITY", "0"],
    ["NOTIFY_QUEUE_CAPACITY", "10001"],
    ["NOTIFY_HEARTBEAT_MS", "-1000"],
    ["NOTIFY_HEARTBEAT_MS", "60000.5"],
    ["NOTIFY_IDLE_DEBOUNCE_MS", "abc"],
    ["NOTIFY_HTTP_TIMEOUT_MS", "300001"],
    ["NOTIFY_MAX_RETRIES", "1e3"],
    ["NOTIFY_MAX_RETRIES", "0"],
  ])("returns null when %s is the invalid value %j", (name, value) => {
    expect(loadConfig({ ...baseEnv(), [name]: value })).toBeNull();
  });

  it("parses NOTIFY_INCLUDE_SUMMARY only as true/false and rejects anything else", () => {
    expect(loadConfig({ ...baseEnv(), NOTIFY_INCLUDE_SUMMARY: "false" })?.includeSummary).toBe(false);
    expect(loadConfig({ ...baseEnv(), NOTIFY_INCLUDE_SUMMARY: "yes" })).toBeNull();
    expect(loadConfig({ ...baseEnv(), NOTIFY_INCLUDE_SUMMARY: "1" })).toBeNull();
  });

  it("treats a blank optional override as unset and applies the default", () => {
    const config = loadConfig({ ...baseEnv(), NOTIFY_QUEUE_CAPACITY: "   " });
    expect(config?.queueCapacity).toBe(100);
  });

  it("falls back to os.hostname() when NOTIFY_MACHINE is blank", () => {
    expect(loadConfig({ ...baseEnv(), NOTIFY_MACHINE: "   " })?.machine).toBe(hostname());
  });

  it("never throws and never exposes the secret, even for garbage input", () => {
    const garbage: NodeJS.ProcessEnv = {
      NOTIFY_GATEWAY_URL: "://\u0000broken",
      NOTIFY_INGEST_KEY: "..",
      NOTIFY_QUEUE_CAPACITY: "9".repeat(400),
      NOTIFY_HEARTBEAT_MS: "NaN",
      NOTIFY_IDLE_DEBOUNCE_MS: "-0",
      NOTIFY_HTTP_TIMEOUT_MS: "+5",
      NOTIFY_MAX_RETRIES: "0x10",
      NOTIFY_INCLUDE_SUMMARY: "TRUE",
    };
    let result: unknown;
    expect(() => {
      result = loadConfig(garbage);
    }).not.toThrow();
    expect(result).toBeNull();
  });
});
