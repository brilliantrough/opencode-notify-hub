import type { JSONSchema } from "json-schema-to-ts";

// Immediate decisions a user may make for one pending OpenCode permission
// request. `once` allows the exact request, `always` allows the request and
// persists a reusable pattern for future matching requests, and `reject`
// denies it.
export const permissionDecisionSchema = {
  type: "string",
  enum: ["once", "reject", "always"],
} as const satisfies JSONSchema;

// Terminal outcomes of one client-generated decision command. `confirmed`
// means OpenCode applied the decision; `stale` means the request was resolved
// before the command applied; `upstream_error` means OpenCode rejected the
// command; `result_unknown` means the Plugin could not determine the outcome.
export const permissionCommandStatusSchema = {
  type: "string",
  enum: ["confirmed", "stale", "upstream_error", "result_unknown"],
} as const satisfies JSONSchema;

export const decidePermissionBodySchema = {
  type: "object",
  additionalProperties: false,
  required: ["commandId", "sessionId", "decision"],
  properties: {
    commandId: { type: "string", format: "uuid" },
    sessionId: { type: "string", minLength: 1 },
    decision: permissionDecisionSchema,
  },
} as const satisfies JSONSchema;
