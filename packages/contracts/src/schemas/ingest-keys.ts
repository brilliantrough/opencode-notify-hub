import type { JSONSchema } from "json-schema-to-ts";

export const createIngestKeyBodySchema = {
  type: "object",
  additionalProperties: false,
  required: ["name"],
  properties: {
    name: { type: "string", minLength: 1, maxLength: 64 },
  },
} as const satisfies JSONSchema;

export const createIngestKeyResponseSchema = {
  type: "object",
  additionalProperties: false,
  required: ["id", "name", "createdAt", "secret"],
  properties: {
    id: { type: "string", minLength: 1 },
    name: { type: "string", minLength: 1, maxLength: 64 },
    createdAt: { type: "string", format: "date-time" },
    secret: { type: "string", minLength: 1 },
  },
} as const satisfies JSONSchema;

// List items deliberately omit `secret`; additionalProperties: false keeps it that way.
export const ingestKeyListItemSchema = {
  type: "object",
  additionalProperties: false,
  required: ["id", "name", "createdAt"],
  properties: {
    id: { type: "string", minLength: 1 },
    name: { type: "string", minLength: 1, maxLength: 64 },
    createdAt: { type: "string", format: "date-time" },
    lastUsedAt: { type: "string", format: "date-time" },
  },
} as const satisfies JSONSchema;

export const ingestKeyListResponseSchema = {
  type: "array",
  items: ingestKeyListItemSchema,
} as const satisfies JSONSchema;
