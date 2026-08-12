import { hostname } from "node:os";

/** Parsed `keyId.secret` ingest credential issued by the gateway. */
export interface IngestKey {
  keyId: string;
  secret: string;
}

/**
 * Validated plugin configuration. Every field maps to one NOTIFY_*
 * environment variable; absent optional variables resolve to the
 * documented defaults below.
 */
export interface PluginConfig {
  /** Gateway base URL, https (http only for local test development), no trailing slash. */
  gatewayUrl: string;
  ingestKey: IngestKey;
  machine: string;
  includeSummary: boolean;
  queueCapacity: number;
  heartbeatMs: number;
  idleDebounceMs: number;
  httpTimeoutMs: number;
  maxRetries: number;
}

export const DEFAULT_QUEUE_CAPACITY = 100;
export const DEFAULT_HEARTBEAT_MS = 60000;
export const DEFAULT_IDLE_DEBOUNCE_MS = 15000;
export const DEFAULT_HTTP_TIMEOUT_MS = 5000;
export const DEFAULT_MAX_RETRIES = 3;

/**
 * Upper bounds for the numeric overrides. They exist so a mistyped value
 * (extra digits, wrong units) fails closed instead of producing an
 * unbounded queue or a multi-day heartbeat.
 */
const NUMERIC_LIMITS = {
  NOTIFY_QUEUE_CAPACITY: { defaultValue: DEFAULT_QUEUE_CAPACITY, max: 10_000 },
  NOTIFY_HEARTBEAT_MS: { defaultValue: DEFAULT_HEARTBEAT_MS, max: 3_600_000 },
  NOTIFY_IDLE_DEBOUNCE_MS: { defaultValue: DEFAULT_IDLE_DEBOUNCE_MS, max: 600_000 },
  NOTIFY_HTTP_TIMEOUT_MS: { defaultValue: DEFAULT_HTTP_TIMEOUT_MS, max: 300_000 },
  NOTIFY_MAX_RETRIES: { defaultValue: DEFAULT_MAX_RETRIES, max: 100 },
} as const;

/** Base64url charset (RFC 4648 section 5, no padding, no dots). */
const BASE64URL_PATTERN = /^[A-Za-z0-9_-]+$/;

/**
 * Loopback hosts for which plain http is accepted, and the ONLY ones:
 * `localhost`, `127.0.0.1`, and the IPv6 loopback `[::1]` (as serialized
 * by `URL.hostname`). Scope: local test development against a gateway
 * running on the same machine without TLS. Every other http URL — public
 * hosts, LAN addresses, non-loopback IPv6 — is rejected; production must
 * use https. `URL.hostname` is already normalized when this set is
 * consulted (lowercase, integer/octal IPv4 forms resolved), so exotic
 * spellings of loopback collapse to these canonical entries.
 */
const HTTP_LOOPBACK_HOSTS = new Set(["localhost", "127.0.0.1", "[::1]"]);

/**
 * Split a `keyId.secret` credential on its FIRST dot. The keyId is a
 * nonempty base64url token (base64url never contains a dot, so the first
 * dot is unambiguously the delimiter); everything after it is preserved
 * verbatim as the secret, dotted suffix included. The parser is
 * deliberately permissive about the secret's charset so the split rule
 * stays honest; {@link loadConfig} applies the strict base64url check to
 * both parts before accepting the credential. Returns null when there is
 * no usable delimiter or the keyId is not base64url.
 */
export function parseIngestKey(raw: string): IngestKey | null {
  const dot = raw.indexOf(".");
  if (dot <= 0 || dot === raw.length - 1) {
    return null;
  }
  const keyId = raw.slice(0, dot);
  const secret = raw.slice(dot + 1);
  if (!BASE64URL_PATTERN.test(keyId)) {
    return null;
  }
  return { keyId, secret };
}

/**
 * Validate the gateway URL: an absolute https URL for production, with no
 * embedded credentials (username/password) and no query string or fragment
 * (callers append paths to the stored base). Plain http is accepted only
 * for the loopback hosts in {@link HTTP_LOOPBACK_HOSTS} (local test
 * development). The stored value is the URL serialization — lowercase
 * host, default port dropped, IPv6 brackets canonicalized — with trailing
 * slashes removed, so callers can append paths without double slashes.
 */
function parseGatewayUrl(raw: string): string | null {
  let url: URL;
  try {
    url = new URL(raw);
  } catch {
    return null;
  }
  if (url.username !== "" || url.password !== "") {
    return null;
  }
  // The stored value is a base URL callers append paths to; a query string
  // or fragment would corrupt every appended route, so reject it outright.
  if (url.search !== "" || url.hash !== "") {
    return null;
  }
  if (url.protocol === "http:") {
    if (!HTTP_LOOPBACK_HOSTS.has(url.hostname)) {
      return null;
    }
  } else if (url.protocol !== "https:") {
    return null;
  }
  return url.toString().replace(/\/+$/, "");
}

/**
 * Read an optional positive bounded integer override. Returns the default
 * when the variable is unset or blank, and null when the value is present
 * but not an integer in `[1, max]`.
 */
function parseNumericOverride(
  env: NodeJS.ProcessEnv,
  name: keyof typeof NUMERIC_LIMITS,
): number | null {
  const { defaultValue, max } = NUMERIC_LIMITS[name];
  const raw = env[name];
  if (raw === undefined || raw.trim() === "") {
    return defaultValue;
  }
  const trimmed = raw.trim();
  if (!/^\d+$/.test(trimmed)) {
    return null;
  }
  const value = Number.parseInt(trimmed, 10);
  if (value < 1 || value > max) {
    return null;
  }
  return value;
}

/**
 * Validate the plugin environment and return the typed configuration, or
 * null when anything is missing or invalid. Never throws and never logs:
 * the ingest secret must not appear in any output channel, so failures
 * are reported solely by the null return.
 */
export function loadConfig(env: NodeJS.ProcessEnv = process.env): PluginConfig | null {
  try {
    const gatewayUrlRaw = env.NOTIFY_GATEWAY_URL?.trim();
    if (gatewayUrlRaw === undefined || gatewayUrlRaw === "") {
      return null;
    }
    const gatewayUrl = parseGatewayUrl(gatewayUrlRaw);
    if (gatewayUrl === null) {
      return null;
    }

    const ingestKeyRaw = env.NOTIFY_INGEST_KEY?.trim();
    if (ingestKeyRaw === undefined || ingestKeyRaw === "") {
      return null;
    }
    const ingestKey = parseIngestKey(ingestKeyRaw);
    // The parser intentionally preserves a dotted raw suffix; the loader
    // enforces the issued credential format: both parts nonempty base64url
    // (base64url contains no dots, so a valid credential has exactly one).
    if (
      ingestKey === null ||
      !BASE64URL_PATTERN.test(ingestKey.keyId) ||
      !BASE64URL_PATTERN.test(ingestKey.secret)
    ) {
      return null;
    }

    const machineRaw = env.NOTIFY_MACHINE?.trim();
    const machine = machineRaw === undefined || machineRaw === "" ? hostname() : machineRaw;

    const includeSummaryRaw = env.NOTIFY_INCLUDE_SUMMARY?.trim();
    let includeSummary = false;
    if (includeSummaryRaw !== undefined && includeSummaryRaw !== "") {
      if (includeSummaryRaw === "true") {
        includeSummary = true;
      } else if (includeSummaryRaw !== "false") {
        return null;
      }
    }

    const queueCapacity = parseNumericOverride(env, "NOTIFY_QUEUE_CAPACITY");
    const heartbeatMs = parseNumericOverride(env, "NOTIFY_HEARTBEAT_MS");
    const idleDebounceMs = parseNumericOverride(env, "NOTIFY_IDLE_DEBOUNCE_MS");
    const httpTimeoutMs = parseNumericOverride(env, "NOTIFY_HTTP_TIMEOUT_MS");
    const maxRetries = parseNumericOverride(env, "NOTIFY_MAX_RETRIES");
    if (
      queueCapacity === null ||
      heartbeatMs === null ||
      idleDebounceMs === null ||
      httpTimeoutMs === null ||
      maxRetries === null
    ) {
      return null;
    }

    return {
      gatewayUrl,
      ingestKey,
      machine,
      includeSummary,
      queueCapacity,
      heartbeatMs,
      idleDebounceMs,
      httpTimeoutMs,
      maxRetries,
    };
  } catch {
    return null;
  }
}
