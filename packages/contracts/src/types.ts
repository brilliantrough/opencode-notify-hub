import type { FromSchema } from "json-schema-to-ts";

import type {
  emailBodySchema,
  loginBodySchema,
  refreshBodySchema,
  registerBodySchema,
  resetPasswordBodySchema,
  tokenPairSchema,
  verifyEmailBodySchema,
} from "./schemas/auth.js";
import type { errorResponseSchema, healthStatusSchema } from "./schemas/common.js";
import type {
  instancePresenceSchema,
  pluginControlClientMessageSchema,
  pluginControlServerMessageSchema,
} from "./schemas/control.js";
import type {
  deviceListResponseSchema,
  deviceSchema,
  patchDeviceBodySchema,
  registerDeviceBodySchema,
} from "./schemas/devices.js";
import type {
  actionRequiredEventSchema,
  actionResolvedEventSchema,
  eventIngestResponseSchema,
  heartbeatEventSchema,
  notifyEventSchema,
  terminalEventSchema,
} from "./schemas/events.js";
import type {
  createIngestKeyBodySchema,
  createIngestKeyResponseSchema,
  ingestKeyListItemSchema,
  ingestKeyListResponseSchema,
} from "./schemas/ingest-keys.js";
import type { wsServerMessageSchema } from "./schemas/ws.js";

export type RegisterBody = FromSchema<typeof registerBodySchema>;
export type LoginBody = FromSchema<typeof loginBodySchema>;
export type EmailBody = FromSchema<typeof emailBodySchema>;
export type VerifyEmailBody = FromSchema<typeof verifyEmailBodySchema>;
export type ResetPasswordBody = FromSchema<typeof resetPasswordBodySchema>;
export type RefreshBody = FromSchema<typeof refreshBodySchema>;
export type TokenPair = FromSchema<typeof tokenPairSchema>;

export type RegisterDeviceBody = FromSchema<typeof registerDeviceBodySchema>;
export type PatchDeviceBody = FromSchema<typeof patchDeviceBodySchema>;
export type Device = FromSchema<typeof deviceSchema>;
export type DeviceListResponse = FromSchema<typeof deviceListResponseSchema>;

export type CreateIngestKeyBody = FromSchema<typeof createIngestKeyBodySchema>;
export type CreateIngestKeyResponse = FromSchema<typeof createIngestKeyResponseSchema>;
export type IngestKeyListItem = FromSchema<typeof ingestKeyListItemSchema>;
export type IngestKeyListResponse = FromSchema<typeof ingestKeyListResponseSchema>;

export type HeartbeatEvent = FromSchema<typeof heartbeatEventSchema>;
export type ActionRequiredEvent = FromSchema<typeof actionRequiredEventSchema>;
export type ActionResolvedEvent = FromSchema<typeof actionResolvedEventSchema>;
export type TerminalEvent = FromSchema<typeof terminalEventSchema>;
export type NotifyEvent = FromSchema<typeof notifyEventSchema>;
export type EventIngestResponse = FromSchema<typeof eventIngestResponseSchema>;

export type HealthStatus = FromSchema<typeof healthStatusSchema>;
export type ErrorResponse = FromSchema<typeof errorResponseSchema>;

export type WsServerMessage = FromSchema<typeof wsServerMessageSchema>;
export type InstancePresence = FromSchema<typeof instancePresenceSchema>;
export type PluginControlClientMessage = FromSchema<typeof pluginControlClientMessageSchema>;
export type PluginControlServerMessage = FromSchema<typeof pluginControlServerMessageSchema>;
