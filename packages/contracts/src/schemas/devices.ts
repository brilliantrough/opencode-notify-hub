import type { JSONSchema } from "json-schema-to-ts";

const deviceName = { type: "string", minLength: 1, maxLength: 64 } as const;
const devicePlatform = { enum: ["windows", "linux", "android"] } as const;
// FCM registration tokens are unbounded upstream; 4096 covers every token
// seen in practice with wide headroom and caps stored/forwarded bytes.
const fcmToken = { type: "string", minLength: 1, maxLength: 4096 } as const;

export const registerDeviceBodySchema = {
  type: "object",
  additionalProperties: false,
  required: ["name", "platform"],
  properties: {
    name: deviceName,
    platform: devicePlatform,
    fcmToken,
    // Optional on create; the server applies these defaults when omitted.
    enabled: { type: "boolean", default: true },
    soundEnabled: { type: "boolean", default: true },
  },
} as const satisfies JSONSchema;

export const patchDeviceBodySchema = {
  type: "object",
  additionalProperties: false,
  minProperties: 1,
  properties: {
    name: deviceName,
    enabled: { type: "boolean" },
    soundEnabled: { type: "boolean" },
    fcmToken,
  },
} as const satisfies JSONSchema;

export const deviceSchema = {
  type: "object",
  additionalProperties: false,
  required: ["id", "name", "platform", "enabled", "soundEnabled"],
  properties: {
    id: { type: "string", minLength: 1 },
    name: deviceName,
    platform: devicePlatform,
    enabled: { type: "boolean" },
    soundEnabled: { type: "boolean" },
    fcmToken,
  },
} as const satisfies JSONSchema;

export const deviceListResponseSchema = {
  type: "array",
  items: deviceSchema,
} as const satisfies JSONSchema;
