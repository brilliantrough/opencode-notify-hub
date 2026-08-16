import type { JSONSchema } from "json-schema-to-ts";

import { pendingInteractionSchema } from "./pending.js";
import {
  permissionCommandStatusSchema,
  permissionDecisionSchema,
} from "./permissions.js";
import { questionAnswersSchema, questionCommandStatusSchema } from "./questions.js";

const nonEmptyString = { type: "string", minLength: 1 } as const;
const uuidString = { type: "string", format: "uuid" } as const;

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

const pluginRegistrationSchema = {
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

const pendingSnapshotResponseSchema = {
  type: "object",
  additionalProperties: false,
  required: ["type", "requestId", "instanceId", "interactions"],
  properties: {
    type: { const: "pending_snapshot_response" },
    requestId: { type: "string", format: "uuid" },
    instanceId: { type: "string", format: "uuid" },
    interactions: { type: "array", items: pendingInteractionSchema },
  },
} as const satisfies JSONSchema;

// The gateway routes a client-submitted answer set to the owning Plugin
// instance. `requestId` is the plain OpenCode request identifier and
// `answers` mirrors the strict AnswerQuestion body in exact upstream order.
const questionAnswerCommandSchema = {
  type: "object",
  additionalProperties: false,
  required: ["type", "commandId", "requestId", "sessionID", "answers"],
  properties: {
    type: { const: "question_answer_command" },
    commandId: uuidString,
    requestId: nonEmptyString,
    sessionID: nonEmptyString,
    answers: questionAnswersSchema,
  },
} as const satisfies JSONSchema;

// The Plugin reports the terminal outcome of one answer command back to the
// gateway using the shared question command status enum.
const questionAnswerResultSchema = {
  type: "object",
  additionalProperties: false,
  required: ["type", "commandId", "instanceId", "status"],
  properties: {
    type: { const: "question_answer_result" },
    commandId: uuidString,
    instanceId: uuidString,
    status: questionCommandStatusSchema,
  },
} as const satisfies JSONSchema;

// The gateway routes a client-submitted permission decision to the owning
// Plugin instance. `requestId` is the plain OpenCode request identifier and
// `decision` mirrors the strict DecidePermission body.
const permissionDecideCommandSchema = {
  type: "object",
  additionalProperties: false,
  required: ["type", "commandId", "requestId", "sessionID", "decision"],
  properties: {
    type: { const: "permission_decide_command" },
    commandId: uuidString,
    requestId: nonEmptyString,
    sessionID: nonEmptyString,
    decision: permissionDecisionSchema,
  },
} as const satisfies JSONSchema;

// The Plugin reports the terminal outcome of one decision command back to the
// gateway using the shared permission command status enum.
const permissionDecideResultSchema = {
  type: "object",
  additionalProperties: false,
  required: ["type", "commandId", "instanceId", "status"],
  properties: {
    type: { const: "permission_decide_result" },
    commandId: uuidString,
    instanceId: uuidString,
    status: permissionCommandStatusSchema,
  },
} as const satisfies JSONSchema;

export const pluginControlClientMessageSchema = {
  oneOf: [
    pluginRegistrationSchema,
    pendingSnapshotResponseSchema,
    questionAnswerResultSchema,
    permissionDecideResultSchema,
  ],
} as const satisfies JSONSchema;

const pluginRegistrationResultSchema = {
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

const pendingSnapshotRequestSchema = {
  type: "object",
  additionalProperties: false,
  required: ["type", "requestId"],
  properties: {
    type: { const: "pending_snapshot_request" },
    requestId: uuidString,
  },
} as const satisfies JSONSchema;

export const pluginControlServerMessageSchema = {
  oneOf: [
    pluginRegistrationResultSchema,
    pendingSnapshotRequestSchema,
    questionAnswerCommandSchema,
    permissionDecideCommandSchema,
  ],
} as const satisfies JSONSchema;
