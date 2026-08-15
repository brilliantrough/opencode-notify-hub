import type { JSONSchema } from "json-schema-to-ts";

// Immediate decisions a user may make for one pending OpenCode permission
// request. `once` allows the exact request and `reject` denies it. There is
// deliberately no `always` here: always allow is a later slice with its own
// confirmation because it persists a reusable pattern.
export const permissionDecisionSchema = {
  type: "string",
  enum: ["once", "reject"],
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
  required: ["commandId", "decision"],
  properties: {
    commandId: { type: "string", format: "uuid" },
    decision: permissionDecisionSchema,
  },
} as const satisfies JSONSchema;

export const permissionCommandResultSchema = {
  type: "object",
  additionalProperties: false,
  required: ["commandId", "status"],
  properties: {
    commandId: { type: "string", format: "uuid" },
    status: permissionCommandStatusSchema,
  },
} as const satisfies JSONSchema;
