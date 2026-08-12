import type { JSONSchema } from "json-schema-to-ts";

export const healthStatusSchema = {
  type: "object",
  additionalProperties: false,
  required: ["status"],
  properties: { status: { const: "ok" } },
} as const satisfies JSONSchema;

export const errorResponseSchema = {
  type: "object",
  additionalProperties: false,
  required: ["error"],
  properties: {
    error: {
      type: "object",
      additionalProperties: false,
      required: ["code", "message"],
      properties: {
        code: { type: "string", minLength: 1 },
        message: { type: "string", minLength: 1 },
      },
    },
  },
} as const satisfies JSONSchema;
