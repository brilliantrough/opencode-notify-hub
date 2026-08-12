import type { JSONSchema } from "json-schema-to-ts";

const sourceSchema = {
  type: "object",
  additionalProperties: false,
  required: ["machine", "project", "directory"],
  properties: {
    machine: { type: "string", minLength: 1 },
    project: { type: "string", minLength: 1 },
    directory: { type: "string", minLength: 1 },
  },
} as const satisfies JSONSchema;

const sessionSchema = {
  type: "object",
  additionalProperties: false,
  required: ["id", "title"],
  properties: {
    id: { type: "string", minLength: 1 },
    title: { type: "string" },
  },
} as const satisfies JSONSchema;

const requestIdProperty = { type: "string", minLength: 1 } as const;

const heartbeatPayloadSchema = {
  type: "object",
  additionalProperties: false,
  required: ["status", "elapsedSeconds"],
  properties: {
    status: { enum: ["busy", "retry"] },
    elapsedSeconds: { type: "integer", minimum: 0 },
  },
} as const satisfies JSONSchema;

const terminalPayloadSchema = {
  type: "object",
  additionalProperties: false,
  required: ["outcome", "elapsedSeconds"],
  properties: {
    outcome: { enum: ["completed", "failed", "stopped"] },
    elapsedSeconds: { type: "integer", minimum: 0 },
    summary: { type: "string", maxLength: 500 },
  },
} as const satisfies JSONSchema;

const questionOptionSchema = {
  type: "object",
  additionalProperties: false,
  required: ["label"],
  properties: {
    label: { type: "string", minLength: 1 },
    description: { type: "string" },
  },
} as const satisfies JSONSchema;

const questionItemSchema = {
  type: "object",
  additionalProperties: false,
  required: ["question"],
  properties: {
    question: { type: "string", minLength: 1, maxLength: 2000 },
    options: { type: "array", items: questionOptionSchema, maxItems: 16 },
    multiple: { type: "boolean" },
  },
} as const satisfies JSONSchema;

const permissionSectionSchema = {
  type: "object",
  additionalProperties: false,
  required: ["permission", "summary"],
  properties: {
    permission: { type: "string", minLength: 1 },
    summary: { type: "string", minLength: 1, maxLength: 500 },
  },
} as const satisfies JSONSchema;

const providerActionSectionSchema = {
  type: "object",
  additionalProperties: false,
  required: ["provider", "title", "message", "label"],
  properties: {
    provider: { type: "string", minLength: 1, maxLength: 120 },
    title: { type: "string", minLength: 1, maxLength: 120 },
    message: { type: "string", minLength: 1, maxLength: 500 },
    label: { type: "string", minLength: 1, maxLength: 120 },
    link: { type: "string", format: "uri", maxLength: 2048 },
  },
} as const satisfies JSONSchema;

const actionRequiredPayloadSchema = {
  oneOf: [
    {
      type: "object",
      additionalProperties: false,
      required: ["requestId", "kind", "questions"],
      properties: {
        requestId: requestIdProperty,
        kind: { const: "question" },
        questions: { type: "array", items: questionItemSchema, minItems: 1, maxItems: 8 },
      },
    },
    {
      type: "object",
      additionalProperties: false,
      required: ["requestId", "kind", "permission"],
      properties: {
        requestId: requestIdProperty,
        kind: { const: "permission" },
        permission: permissionSectionSchema,
      },
    },
    {
      type: "object",
      additionalProperties: false,
      required: ["requestId", "kind", "providerAction"],
      properties: {
        requestId: requestIdProperty,
        kind: { const: "provider_action" },
        providerAction: providerActionSectionSchema,
      },
    },
  ],
} as const satisfies JSONSchema;

const actionResolvedPayloadSchema = {
  type: "object",
  additionalProperties: false,
  required: ["requestId", "kind"],
  properties: {
    requestId: requestIdProperty,
    kind: { enum: ["question", "permission"] },
  },
} as const satisfies JSONSchema;

const eventEnvelope = {
  type: "object",
  additionalProperties: false,
  required: ["eventId", "type", "occurredAt", "source", "session", "payload"],
  properties: {
    eventId: { type: "string", format: "uuid" },
    occurredAt: { type: "string", format: "date-time" },
    source: sourceSchema,
    session: sessionSchema,
  },
} as const;

export const heartbeatEventSchema = {
  ...eventEnvelope,
  properties: {
    ...eventEnvelope.properties,
    type: { const: "heartbeat" },
    payload: heartbeatPayloadSchema,
  },
} as const satisfies JSONSchema;

export const actionRequiredEventSchema = {
  ...eventEnvelope,
  properties: {
    ...eventEnvelope.properties,
    type: { const: "action_required" },
    payload: actionRequiredPayloadSchema,
  },
} as const satisfies JSONSchema;

export const actionResolvedEventSchema = {
  ...eventEnvelope,
  properties: {
    ...eventEnvelope.properties,
    type: { const: "action_resolved" },
    payload: actionResolvedPayloadSchema,
  },
} as const satisfies JSONSchema;

export const terminalEventSchema = {
  ...eventEnvelope,
  properties: {
    ...eventEnvelope.properties,
    type: { const: "terminal" },
    payload: terminalPayloadSchema,
  },
} as const satisfies JSONSchema;

export const notifyEventSchema = {
  oneOf: [
    heartbeatEventSchema,
    actionRequiredEventSchema,
    actionResolvedEventSchema,
    terminalEventSchema,
  ],
} as const satisfies JSONSchema;

export const eventIngestResponseSchema = {
  type: "object",
  additionalProperties: false,
  required: ["eventId", "deduplicated"],
  properties: {
    eventId: { type: "string", format: "uuid" },
    deduplicated: {
      type: "boolean",
      description: "True when this eventId was already ingested for this user.",
    },
  },
} as const satisfies JSONSchema;
