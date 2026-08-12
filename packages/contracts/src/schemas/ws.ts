import type { JSONSchema } from "json-schema-to-ts";

import { notifyEventSchema } from "./events.js";

export const wsServerMessageSchema = {
  type: "object",
  additionalProperties: false,
  required: ["type", "event"],
  properties: {
    type: { const: "event" },
    event: notifyEventSchema,
  },
} as const satisfies JSONSchema;

// There is deliberately no client-to-server message schema: the realtime
// channel is receive-ignored (the server never reads client frames), so
// publishing one would claim a protocol that does not exist.
