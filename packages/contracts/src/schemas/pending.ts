import type { JSONSchema } from "json-schema-to-ts";

const nonEmptyString = { type: "string", minLength: 1 } as const;

const toolSchema = {
  type: "object",
  additionalProperties: false,
  required: ["messageId", "callId"],
  properties: {
    messageId: nonEmptyString,
    callId: nonEmptyString,
  },
} as const satisfies JSONSchema;

const pendingQuestionOptionSchema = {
  type: "object",
  additionalProperties: false,
  required: ["label", "description"],
  properties: {
    label: nonEmptyString,
    description: { type: "string" },
  },
} as const satisfies JSONSchema;

const pendingQuestionItemSchema = {
  type: "object",
  additionalProperties: false,
  required: ["header", "question", "options", "multiple", "custom"],
  properties: {
    header: nonEmptyString,
    question: nonEmptyString,
    options: { type: "array", items: pendingQuestionOptionSchema },
    multiple: { type: "boolean" },
    custom: { type: "boolean" },
  },
} as const satisfies JSONSchema;

const pendingPermissionContentSchema = {
  type: "object",
  additionalProperties: false,
  required: ["permission", "patterns", "always", "metadata"],
  properties: {
    permission: nonEmptyString,
    patterns: { type: "array", items: nonEmptyString },
    always: { type: "array", items: nonEmptyString },
    metadata: { type: "object", additionalProperties: true },
    tool: toolSchema,
  },
} as const satisfies JSONSchema;

const pendingSourceProperties = {
  instanceId: { type: "string", format: "uuid" },
  machine: nonEmptyString,
  project: nonEmptyString,
  directory: nonEmptyString,
  sessionId: nonEmptyString,
  sessionTitle: { type: "string" },
  requestId: nonEmptyString,
  occurredAt: { type: "string", format: "date-time" },
} as const;

const pendingSourceRequired = [
  "instanceId",
  "machine",
  "project",
  "directory",
  "sessionId",
  "sessionTitle",
  "requestId",
  "occurredAt",
] as const;

const pendingQuestionInteractionSchema = {
  type: "object",
  additionalProperties: false,
  required: [...pendingSourceRequired, "kind", "questions"],
  properties: {
    ...pendingSourceProperties,
    kind: { const: "question" },
    tool: toolSchema,
    questions: {
      type: "array",
      items: pendingQuestionItemSchema,
      minItems: 1,
    },
  },
} as const satisfies JSONSchema;

const pendingPermissionInteractionSchema = {
  type: "object",
  additionalProperties: false,
  required: [...pendingSourceRequired, "kind", ...pendingPermissionContentSchema.required],
  properties: {
    ...pendingSourceProperties,
    kind: { const: "permission" },
    ...pendingPermissionContentSchema.properties,
  },
} as const satisfies JSONSchema;

export const pendingInteractionSchema = {
  oneOf: [pendingQuestionInteractionSchema, pendingPermissionInteractionSchema],
} as const satisfies JSONSchema;

export const pendingSnapshotSchema = {
  type: "object",
  additionalProperties: false,
  required: ["generatedAt", "interactions"],
  properties: {
    generatedAt: { type: "string", format: "date-time" },
    interactions: { type: "array", items: pendingInteractionSchema },
  },
} as const satisfies JSONSchema;
