import type { JSONSchema } from "json-schema-to-ts";

import { instancePresenceSchema } from "./control.js";
import { notifyEventSchema } from "./events.js";

export const wsServerMessageSchema = {
  oneOf: [
    {
      type: "object",
      additionalProperties: false,
      required: ["type", "event"],
      properties: {
        type: { const: "event" },
        event: notifyEventSchema,
      },
    },
    {
      type: "object",
      additionalProperties: false,
      required: ["type", "instances"],
      properties: {
        type: { const: "instance_presence" },
        instances: { type: "array", items: instancePresenceSchema },
      },
    },
  ],
} as const satisfies JSONSchema;

// The desktop realtime channel remains receive-only. Plugin control traffic
// uses its own schemas and endpoint instead of adding desktop commands here.
