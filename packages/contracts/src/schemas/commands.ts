import type { JSONSchema } from "json-schema-to-ts";

// The kind of pending interaction a command acts on.
export const commandKindSchema = {
  type: "string",
  enum: ["question", "permission"],
} as const satisfies JSONSchema;

// Lifecycle of one client-generated command in the Gateway's in-memory
// outcome cache. `accepted` means the Gateway routed the command to the
// owning Plugin instance; `confirmed` means OpenCode applied it; `stale`
// means the request was resolved before the command applied; `upstream_error`
// means OpenCode rejected the command; `result_unknown` means the outcome
// could not be determined.
export const commandOutcomeStatusSchema = {
  type: "string",
  enum: ["accepted", "confirmed", "stale", "upstream_error", "result_unknown"],
} as const satisfies JSONSchema;

// Body-free, in-memory command outcome correlation keyed by the
// client-generated commandId for roughly ten minutes. It never carries
// question answers, permission decisions, or any other interaction body;
// `additionalProperties: false` rejects any such field by construction.
export const commandOutcomeSchema = {
  type: "object",
  additionalProperties: false,
  required: ["commandId", "requestId", "instanceId", "kind", "status", "updatedAt"],
  properties: {
    commandId: { type: "string", format: "uuid" },
    requestId: { type: "string", minLength: 1 },
    instanceId: { type: "string", format: "uuid" },
    kind: commandKindSchema,
    status: commandOutcomeStatusSchema,
    updatedAt: { type: "string", format: "date-time" },
  },
} as const satisfies JSONSchema;
