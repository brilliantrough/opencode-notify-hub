import type { JSONSchema } from "json-schema-to-ts";

const nonEmptyString = { type: "string", minLength: 1 } as const;

export const instancePresenceStateSchema = {
  type: "string",
  enum: ["controllable", "conflicting", "incompatible", "offline"],
} as const satisfies JSONSchema;

export const instancePresenceSchema = {
  type: "object",
  additionalProperties: false,
  required: [
    "instanceId",
    "machine",
    "project",
    "directory",
    "openCodeVersion",
    "protocolVersion",
    "state",
    "lastSeenAt",
  ],
  properties: {
    instanceId: { type: "string", format: "uuid" },
    machine: nonEmptyString,
    project: nonEmptyString,
    directory: nonEmptyString,
    openCodeVersion: nonEmptyString,
    protocolVersion: { type: "integer", minimum: 1 },
    state: instancePresenceStateSchema,
    lastSeenAt: { type: "string", format: "date-time" },
  },
} as const satisfies JSONSchema;

export const pluginControlClientMessageSchema = {
  type: "object",
  additionalProperties: false,
  required: [
    "type",
    "instanceId",
    "machine",
    "project",
    "directory",
    "openCodeVersion",
    "protocolVersion",
  ],
  properties: {
    type: { const: "register" },
    instanceId: { type: "string", format: "uuid" },
    machine: nonEmptyString,
    project: nonEmptyString,
    directory: nonEmptyString,
    openCodeVersion: nonEmptyString,
    protocolVersion: { type: "integer", minimum: 1 },
  },
} as const satisfies JSONSchema;

export const pluginControlServerMessageSchema = {
  type: "object",
  additionalProperties: false,
  required: ["type", "instanceId", "state"],
  properties: {
    type: { const: "registration" },
    instanceId: { type: "string", format: "uuid" },
    state: {
      type: "string",
      enum: ["controllable", "conflicting", "incompatible"],
    },
  },
} as const satisfies JSONSchema;
