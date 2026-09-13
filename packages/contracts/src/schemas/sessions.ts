import type { JSONSchema } from "json-schema-to-ts";

export const sessionCatalogQuerySchema = {
  type: "object",
  additionalProperties: false,
  properties: {
    search: { type: "string", maxLength: 200 },
    limit: { type: "integer", minimum: 1, maximum: 200, default: 50 },
    // Explicit bookmarks are looked up even when outside the recent page.
    sessionIds: { type: "string", maxLength: 4096, pattern: "^[A-Za-z0-9_,.-]*$" },
  },
} as const satisfies JSONSchema;

export const catalogSessionSchema = {
  type: "object",
  additionalProperties: false,
  required: ["sessionId", "title", "directory", "updatedAt", "status"],
  properties: {
    sessionId: { type: "string", minLength: 1, maxLength: 200 },
    title: { type: "string", maxLength: 1000 },
    directory: { type: "string", minLength: 1, maxLength: 4096 },
    updatedAt: { type: "string", format: "date-time" },
    status: { type: "string", enum: ["idle", "busy", "retry", "unknown"] },
  },
} as const satisfies JSONSchema;

export const sessionCatalogSchema = {
  type: "object",
  additionalProperties: false,
  required: ["sessions", "hasMore"],
  properties: {
    sessions: { type: "array", maxItems: 250, items: catalogSessionSchema },
    hasMore: { type: "boolean" },
  },
} as const satisfies JSONSchema;
