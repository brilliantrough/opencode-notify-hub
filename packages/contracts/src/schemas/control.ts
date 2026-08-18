import type { JSONSchema } from "json-schema-to-ts";

import { pendingInteractionSchema } from "./pending.js";
import {
  permissionCommandStatusSchema,
  permissionDecisionSchema,
} from "./permissions.js";
import { promptCommandStatusSchema } from "./commands.js";
import { questionAnswersSchema, questionCommandStatusSchema } from "./questions.js";

const nonEmptyString = { type: "string", minLength: 1 } as const;
const uuidString = { type: "string", format: "uuid" } as const;
const webUiHeadersSchema = {
  type: "object",
  additionalProperties: { type: "array", items: { type: "string" } },
} as const;
const webUiBodySchema = { type: "string", maxLength: 700_000 } as const;

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

// The Gateway routes one free-form prompt to the owning Plugin instance. The
// Plugin calls the session-scoped V2 prompt endpoint and reports admission.
const sessionPromptCommandSchema = {
  type: "object",
  additionalProperties: false,
  required: ["type", "commandId", "sessionID", "text"],
  properties: {
    type: { const: "session_prompt_command" },
    commandId: uuidString,
    sessionID: nonEmptyString,
    text: { type: "string", minLength: 1, maxLength: 32_000 },
  },
} as const satisfies JSONSchema;

const sessionPromptResultSchema = {
  type: "object",
  additionalProperties: false,
  required: ["type", "commandId", "instanceId", "status"],
  properties: {
    type: { const: "session_prompt_result" },
    commandId: uuidString,
    instanceId: uuidString,
    status: promptCommandStatusSchema,
  },
} as const satisfies JSONSchema;

const webUiHttpRequestSchema = {
  type: "object",
  additionalProperties: false,
  required: ["type", "tunnelId", "requestId", "method", "path", "headers"],
  properties: {
    type: { const: "webui_http_request" },
    tunnelId: uuidString,
    requestId: uuidString,
    method: { type: "string", minLength: 1, maxLength: 16 },
    path: { type: "string", minLength: 1, maxLength: 8192 },
    headers: webUiHeadersSchema,
    body: webUiBodySchema,
  },
} as const satisfies JSONSchema;

const webUiTunnelCloseSchema = {
  type: "object",
  additionalProperties: false,
  required: ["type", "tunnelId"],
  properties: {
    type: { const: "webui_tunnel_close" },
    tunnelId: uuidString,
  },
} as const satisfies JSONSchema;

const webUiHttpResponseStartSchema = {
  type: "object",
  additionalProperties: false,
  required: ["type", "tunnelId", "requestId", "status", "headers"],
  properties: {
    type: { const: "webui_http_response_start" },
    tunnelId: uuidString,
    requestId: uuidString,
    status: { type: "integer", minimum: 100, maximum: 599 },
    headers: webUiHeadersSchema,
  },
} as const satisfies JSONSchema;

const webUiHttpResponseChunkSchema = {
  type: "object",
  additionalProperties: false,
  required: ["type", "tunnelId", "requestId", "body"],
  properties: {
    type: { const: "webui_http_response_chunk" },
    tunnelId: uuidString,
    requestId: uuidString,
    body: webUiBodySchema,
  },
} as const satisfies JSONSchema;

const webUiHttpResponseEndSchema = {
  type: "object",
  additionalProperties: false,
  required: ["type", "tunnelId", "requestId"],
  properties: {
    type: { const: "webui_http_response_end" },
    tunnelId: uuidString,
    requestId: uuidString,
  },
} as const satisfies JSONSchema;

export const pluginControlClientMessageSchema = {
  oneOf: [
    pluginRegistrationSchema,
    pendingSnapshotResponseSchema,
    questionAnswerResultSchema,
    permissionDecideResultSchema,
    sessionPromptResultSchema,
    webUiHttpResponseStartSchema,
    webUiHttpResponseChunkSchema,
    webUiHttpResponseEndSchema,
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
    sessionPromptCommandSchema,
    webUiHttpRequestSchema,
    webUiTunnelCloseSchema,
  ],
} as const satisfies JSONSchema;
