import { describe, expect, it } from "vitest";

import type { Clock } from "../../src/lib/clock.js";
import {
  ACCESS_TOKEN_TTL_SECONDS,
  createAccessTokens,
  SigningKeyError,
} from "../../src/plugins/jwt.js";

/** Deterministic, manually advanced clock. */
class FakeClock implements Clock {
  nowMsValue = 1_700_000_000_000;

  now(): Date {
    return new Date(this.nowMsValue);
  }

  nowMs(): number {
    return this.nowMsValue;
  }

  advance(ms: number): void {
    this.nowMsValue += ms;
  }
}

/** Exactly 32 decoded bytes, canonical base64. */
const SIGNING_KEY = Buffer.from("0123456789abcdef0123456789abcdef").toString("base64");
/** A different, equally valid 32-byte key. */
const OTHER_KEY = Buffer.from("fedcba9876543210fedcba9876543210").toString("base64");

function makeTokens(signingKey = SIGNING_KEY) {
  const clock = new FakeClock();
  return { tokens: createAccessTokens({ signingKey, clock }), clock };
}

describe("createAccessTokens signing-key validation", () => {
  it("accepts a canonical 32-byte key", () => {
    expect(() => makeTokens()).not.toThrow();
  });

  it("rejects a key decoding to fewer than 32 bytes", () => {
    const short = Buffer.from("sixteen-bytes!!!").toString("base64"); // 16 bytes
    expect(short.length % 4).toBe(0);
    expect(() => createAccessTokens({ signingKey: short, clock: new FakeClock() }))
      .toThrowError(SigningKeyError);
    expect(() => createAccessTokens({ signingKey: short, clock: new FakeClock() }))
      .toThrowError(/at least 32 bytes/);
  });

  it("rejects strings outside the base64 alphabet", () => {
    expect(() =>
      createAccessTokens({ signingKey: `${SIGNING_KEY.slice(0, -4)}!!!=`, clock: new FakeClock() }),
    ).toThrowError(SigningKeyError);
    expect(() =>
      createAccessTokens({ signingKey: "not base64 at all", clock: new FakeClock() }),
    ).toThrowError(SigningKeyError);
  });

  it("rejects non-canonical base64 (unused trailing bits set)", () => {
    // 32 zero bytes encode canonically as 43 "A"s and "=". The final
    // quantum has two unused low bits: flipping them decodes to the very
    // same 32 bytes, but is not the canonical spelling.
    const zeroKey = Buffer.alloc(32).toString("base64");
    expect(zeroKey.endsWith("AA=")).toBe(true);
    const nonCanonical = `${zeroKey.slice(0, -2)}B=`;
    expect(Buffer.from(nonCanonical, "base64")).toEqual(Buffer.alloc(32));
    expect(() =>
      createAccessTokens({ signingKey: nonCanonical, clock: new FakeClock() }),
    ).toThrowError(SigningKeyError);
    expect(() =>
      createAccessTokens({ signingKey: nonCanonical, clock: new FakeClock() }),
    ).toThrowError(/canonical base64/);
  });

  it("rejects lengths that are not a multiple of four", () => {
    expect(() =>
      createAccessTokens({ signingKey: SIGNING_KEY.slice(0, -1), clock: new FakeClock() }),
    ).toThrowError(SigningKeyError);
  });
});

describe("access token sign/verify", () => {
  it("round-trips the subject with an exact 900-second TTL", () => {
    const { tokens, clock } = makeTokens();
    const token = tokens.sign("user-1");
    const payload = tokens.verify(token);
    expect(payload).not.toBeNull();
    expect(payload!.sub).toBe("user-1");
    expect(payload!.iat).toBe(Math.floor(clock.nowMs() / 1000));
    expect(payload!.exp).toBe(payload!.iat + ACCESS_TOKEN_TTL_SECONDS);
    expect(payload!.exp - payload!.iat).toBe(900);
  });

  it("rejects a token signed by a different key", () => {
    const { tokens } = makeTokens();
    const foreign = createAccessTokens({ signingKey: OTHER_KEY, clock: new FakeClock() });
    expect(tokens.verify(foreign.sign("user-1"))).toBeNull();
  });

  it("rejects a tampered payload", () => {
    const { tokens } = makeTokens();
    const [header, payload] = tokens.sign("user-1").split(".");
    const forged = Buffer.from(
      JSON.stringify({ sub: "admin", iat: 1, exp: 9_999_999_999 }),
    ).toString("base64url");
    expect(tokens.verify(`${header}.${forged}.${payload}`)).toBeNull();
    // Re-signing the original payload with a truncated signature also fails.
    const token = tokens.sign("user-1");
    expect(tokens.verify(token.slice(0, -2))).toBeNull();
    expect(tokens.verify(`${header}.${payload}`)).toBeNull();
  });

  it("rejects malformed and unparsable tokens", () => {
    const { tokens } = makeTokens();
    expect(tokens.verify("not-a-jwt")).toBeNull();
    expect(tokens.verify("")).toBeNull();
    // Three parts but the payload is not JSON.
    expect(tokens.verify("e30.e30.e30")).toBeNull();
    // Valid JSON payload with the wrong claim shapes.
    const badClaims = Buffer.from(JSON.stringify({ sub: 42 })).toString("base64url");
    expect(tokens.verify(`e30.${badClaims}.e30`)).toBeNull();
  });

  it("rejects the token exactly at its expiry second", () => {
    const { tokens, clock } = makeTokens();
    const token = tokens.sign("user-1");
    clock.advance(899_000);
    expect(tokens.verify(token)).not.toBeNull();
    clock.advance(1_000);
    expect(tokens.verify(token)).toBeNull();
  });
});
