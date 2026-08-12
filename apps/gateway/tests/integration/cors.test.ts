import type { FastifyInstance } from "fastify";
import { afterEach, describe, expect, it } from "vitest";

import { buildTestApp, buildTestConfig } from "../helpers/build-test-app.js";
import { buildServer } from "../../src/app.js";

describe("HTTP CORS (ALLOWED_ORIGINS)", () => {
  let app: FastifyInstance | undefined;

  afterEach(async () => {
    await app?.close();
    app = undefined;
  });

  it("answers a preflight from a configured origin with matching allow headers", async () => {
    app = await buildTestApp();
    const res = await app.inject({
      method: "OPTIONS",
      url: "/v1/auth/login",
      headers: {
        origin: "https://app.test",
        "access-control-request-method": "POST",
      },
    });
    expect(res.statusCode).toBe(204);
    expect(res.headers["access-control-allow-origin"]).toBe("https://app.test");
    expect(res.headers["access-control-allow-methods"]).toContain("POST");
  });

  it("omits allow headers for an origin that is not configured", async () => {
    app = await buildTestApp();
    const res = await app.inject({
      method: "OPTIONS",
      url: "/v1/auth/login",
      headers: {
        origin: "https://evil.test",
        "access-control-request-method": "POST",
      },
    });
    expect(res.headers["access-control-allow-origin"]).toBeUndefined();

    const simple = await app.inject({
      method: "GET",
      url: "/health/live",
      headers: { origin: "https://evil.test" },
    });
    expect(simple.statusCode).toBe(200);
    expect(simple.headers["access-control-allow-origin"]).toBeUndefined();
  });

  it("matches configured origins exactly, in their normalized form", async () => {
    // Config normalization drops a default port and any trailing slash; the
    // wire Origin header is matched against that normalized form.
    app = await buildServer({
      config: buildTestConfig({ allowedOrigins: ["https://app.test", "http://localhost:5173"] }),
    });
    const allowed = await app.inject({
      method: "GET",
      url: "/health/live",
      headers: { origin: "http://localhost:5173" },
    });
    expect(allowed.headers["access-control-allow-origin"]).toBe("http://localhost:5173");
    const lookalike = await app.inject({
      method: "GET",
      url: "/health/live",
      headers: { origin: "https://app.test.evil.test" },
    });
    expect(lookalike.headers["access-control-allow-origin"]).toBeUndefined();
  });

  it("native clients without an Origin header are unaffected", async () => {
    app = await buildTestApp();
    const res = await app.inject({ method: "GET", url: "/health/live" });
    expect(res.statusCode).toBe(200);
    expect(res.headers["access-control-allow-origin"]).toBeUndefined();
  });
});
