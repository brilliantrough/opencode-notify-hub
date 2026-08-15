import type { JSONSchema } from "json-schema-to-ts";

// A complete, ordered answer set for one pending interaction. Each outer entry
// corresponds to one upstream question in order; a single-select answer holds
// one label or custom value, a multi-select answer may hold several labels
// plus custom text. Every entry is non-empty and every answer string is
// non-empty. There is deliberately no total-size cap here: complete valid
// answers may exceed the transport limit, which is enforced by the transport
// itself, not by the contract.
export const questionAnswersSchema = {
  type: "array",
  minItems: 1,
  items: {
    type: "array",
    minItems: 1,
    items: { type: "string", minLength: 1 },
  },
} as const satisfies JSONSchema;

// Terminal outcomes of one client-generated answer command. `confirmed` means
// OpenCode applied the answers; `stale` means the request was resolved before
// the command applied; `upstream_error` means OpenCode rejected the command;
// `result_unknown` means the Plugin could not determine the outcome.
export const questionCommandStatusSchema = {
  type: "string",
  enum: ["confirmed", "stale", "upstream_error", "result_unknown"],
} as const satisfies JSONSchema;

export const answerQuestionBodySchema = {
  type: "object",
  additionalProperties: false,
  required: ["commandId", "answers"],
  properties: {
    commandId: { type: "string", format: "uuid" },
    answers: questionAnswersSchema,
  },
} as const satisfies JSONSchema;

export const questionCommandResultSchema = {
  type: "object",
  additionalProperties: false,
  required: ["commandId", "status"],
  properties: {
    commandId: { type: "string", format: "uuid" },
    status: questionCommandStatusSchema,
  },
} as const satisfies JSONSchema;
