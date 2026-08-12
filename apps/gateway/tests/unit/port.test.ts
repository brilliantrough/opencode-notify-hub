import { describe, expect, it } from "vitest";

import { ConfigError } from "../../src/config.js";
import { resolvePort } from "../../src/port.js";

/**
 * PORT is an operational override (not one of the specification variables):
 * optional, an integer in 1..65535, defaulting to 8080. Invalid values abort
 * startup with a ConfigError instead of silently listening on NaN/3000.
 */
describe("resolvePort", () => {
  it("defaults to 8080 when PORT is unset, empty, or whitespace", () => {
    expect(resolvePort({})).toBe(8080);
    expect(resolvePort({ PORT: "" })).toBe(8080);
    expect(resolvePort({ PORT: "   " })).toBe(8080);
  });

  it("accepts the boundary ports 1 and 65535", () => {
    expect(resolvePort({ PORT: "1" })).toBe(1);
    expect(resolvePort({ PORT: "65535" })).toBe(65535);
    expect(resolvePort({ PORT: "8080" })).toBe(8080);
  });

  it("rejects out-of-range ports", () => {
    expect(() => resolvePort({ PORT: "0" })).toThrow(ConfigError);
    expect(() => resolvePort({ PORT: "65536" })).toThrow(ConfigError);
    expect(() => resolvePort({ PORT: "-1" })).toThrow(ConfigError);
  });

  it("rejects non-integer ports instead of coercing them", () => {
    expect(() => resolvePort({ PORT: "abc" })).toThrow(ConfigError);
    expect(() => resolvePort({ PORT: "10.5" })).toThrow(ConfigError);
    // parseInt would accept these prefixes; the override must not.
    expect(() => resolvePort({ PORT: "8080x" })).toThrow(ConfigError);
    expect(() => resolvePort({ PORT: "0x50" })).toThrow(ConfigError);
  });

  it("names PORT in the error without echoing other environment", () => {
    try {
      resolvePort({ PORT: "nope" });
      expect.unreachable("expected a ConfigError");
    } catch (error) {
      expect(error).toBeInstanceOf(ConfigError);
      expect((error as ConfigError).issues.join("; ")).toContain("PORT");
    }
  });
});
