import { validateErrorResponse, validateHealthStatus } from "@notify/contracts";
import { describe, expect, it } from "vitest";

import { buildTestApp } from "../helpers/build-test-app.js";

describe("liveness and error shape", () => {
  it("GET /health/live responds ok without any database access", async () => {
    const app = await buildTestApp();
    try {
      const res = await app.inject({ method: "GET", url: "/health/live" });
      expect(res.statusCode).toBe(200);
      expect(res.json()).toEqual({ status: "ok" });
      expect(validateHealthStatus(res.json())).toBe(true);
    } finally {
      await app.close();
    }
  });

  it("unknown routes map to the NOT_FOUND error shape", async () => {
    const app = await buildTestApp();
    try {
      const res = await app.inject({ method: "GET", url: "/missing" });
      expect(res.statusCode).toBe(404);
      expect(res.json()).toEqual({
        error: { code: "NOT_FOUND", message: "Route not found" },
      });
      expect(validateErrorResponse(res.json())).toBe(true);
    } finally {
      await app.close();
    }
  });

  it("request validation failures map to VALIDATION_FAILED", async () => {
    const app = await buildTestApp();
    // Probe route standing in for the schema-validated routes of later tasks:
    // it exists only to drive a Fastify body-validation failure through the
    // app's public error handling.
    app.post(
      "/_probe-validation",
      {
        schema: {
          body: {
            type: "object",
            additionalProperties: false,
            required: ["email"],
            properties: { email: { type: "string", format: "email" } },
          },
        },
      },
      async () => ({ status: "ok" }),
    );
    try {
      const res = await app.inject({
        method: "POST",
        url: "/_probe-validation",
        payload: {},
      });
      expect(res.statusCode).toBe(400);
      expect(res.json().error.code).toBe("VALIDATION_FAILED");
      expect(validateErrorResponse(res.json())).toBe(true);
    } finally {
      await app.close();
    }
  });

  it("malformed JSON maps to a 400 contract error, not a 500", async () => {
    const app = await buildTestApp();
    app.post("/_probe-json", async () => ({ status: "ok" }));
    try {
      const res = await app.inject({
        method: "POST",
        url: "/_probe-json",
        headers: { "content-type": "application/json" },
        payload: "{ not json",
      });
      expect(res.statusCode).toBe(400);
      expect(res.json().error.code).toBe("BAD_REQUEST");
      expect(validateErrorResponse(res.json())).toBe(true);
    } finally {
      await app.close();
    }
  });

  it("unsupported media type maps to a 415 contract error, not a 500", async () => {
    const app = await buildTestApp();
    app.post("/_probe-json", async () => ({ status: "ok" }));
    try {
      const res = await app.inject({
        method: "POST",
        url: "/_probe-json",
        headers: { "content-type": "application/xml" },
        payload: "<not>supported</not>",
      });
      expect(res.statusCode).toBe(415);
      expect(res.json().error.code).toBe("UNSUPPORTED_MEDIA_TYPE");
      expect(validateErrorResponse(res.json())).toBe(true);
    } finally {
      await app.close();
    }
  });
});
