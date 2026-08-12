import { ConfigError } from "./config.js";

/**
 * Default listen port behind the reverse proxy. PORT is an operational
 * override for local runs and containers; it is not one of the
 * specification environment variables, so it lives outside
 * `GatewayConfig` and is optional.
 */
export const DEFAULT_PORT = 8080;

/**
 * Resolve the listen port from the optional PORT override. Invalid values
 * abort startup with a {@link ConfigError} — silently coercing `NaN` or a
 * `parseInt` prefix would listen on a surprise port (or crash deep inside
 * the server bind) instead of reporting the misconfiguration.
 */
export function resolvePort(env: NodeJS.ProcessEnv = process.env): number {
  const raw = env.PORT;
  if (raw === undefined || raw.trim() === "") {
    return DEFAULT_PORT;
  }
  const value = raw.trim();
  if (!/^\d+$/.test(value)) {
    throw new ConfigError([`PORT must be an integer between 1 and 65535`]);
  }
  const port = Number.parseInt(value, 10);
  if (port < 1 || port > 65535) {
    throw new ConfigError([`PORT must be an integer between 1 and 65535`]);
  }
  return port;
}
