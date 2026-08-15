import { Ajv } from "ajv";
import addFormatsImport from "ajv-formats";

import {
  emailBodySchema,
  loginBodySchema,
  refreshBodySchema,
  registerBodySchema,
  resetPasswordBodySchema,
  tokenPairSchema,
  verifyEmailBodySchema,
} from "./schemas/auth.js";
import { errorResponseSchema, healthStatusSchema } from "./schemas/common.js";
import { commandOutcomeSchema } from "./schemas/commands.js";
import {
  pluginControlClientMessageSchema,
  pluginControlServerMessageSchema,
} from "./schemas/control.js";
import {
  deviceListResponseSchema,
  deviceSchema,
  patchDeviceBodySchema,
  registerDeviceBodySchema,
} from "./schemas/devices.js";
import { eventIngestResponseSchema, notifyEventSchema } from "./schemas/events.js";
import {
  createIngestKeyBodySchema,
  createIngestKeyResponseSchema,
  ingestKeyListResponseSchema,
} from "./schemas/ingest-keys.js";
import { pendingInteractionSchema, pendingSnapshotSchema } from "./schemas/pending.js";
import {
  decidePermissionBodySchema,
  permissionCommandResultSchema,
} from "./schemas/permissions.js";
import { answerQuestionBodySchema, questionCommandResultSchema } from "./schemas/questions.js";
import { wsServerMessageSchema } from "./schemas/ws.js";

// ajv-formats is CJS whose types declare `export default`; under NodeNext the
// default import types as the module namespace. At runtime the package sets
// `module.exports = plugin` and `plugin.default = plugin`, so `.default` is the
// accurately typed and runtime-correct access (verified by the built-ESM smoke test).
const addFormats = addFormatsImport.default;

const ajv = addFormats(new Ajv());

export const validateRegisterBody = ajv.compile(registerBodySchema);
export const validateLoginBody = ajv.compile(loginBodySchema);
export const validateEmailBody = ajv.compile(emailBodySchema);
export const validateVerifyEmailBody = ajv.compile(verifyEmailBodySchema);
export const validateResetPasswordBody = ajv.compile(resetPasswordBodySchema);
export const validateRefreshBody = ajv.compile(refreshBodySchema);
export const validateTokenPair = ajv.compile(tokenPairSchema);

export const validateRegisterDeviceBody = ajv.compile(registerDeviceBodySchema);
export const validatePatchDeviceBody = ajv.compile(patchDeviceBodySchema);
export const validateDevice = ajv.compile(deviceSchema);
export const validateDeviceListResponse = ajv.compile(deviceListResponseSchema);

export const validateCreateIngestKeyBody = ajv.compile(createIngestKeyBodySchema);
export const validateCreateIngestKeyResponse = ajv.compile(createIngestKeyResponseSchema);
export const validateIngestKeyListResponse = ajv.compile(ingestKeyListResponseSchema);

export const validateNotifyEvent = ajv.compile(notifyEventSchema);
export const validateEventIngestResponse = ajv.compile(eventIngestResponseSchema);

export const validateHealthStatus = ajv.compile(healthStatusSchema);
export const validateErrorResponse = ajv.compile(errorResponseSchema);

export const validateWsServerMessage = ajv.compile(wsServerMessageSchema);
export const validatePluginControlClientMessage = ajv.compile(pluginControlClientMessageSchema);
export const validatePluginControlServerMessage = ajv.compile(pluginControlServerMessageSchema);

export const validatePendingInteraction = ajv.compile(pendingInteractionSchema);
export const validatePendingSnapshot = ajv.compile(pendingSnapshotSchema);

export const validateAnswerQuestionBody = ajv.compile(answerQuestionBodySchema);
export const validateQuestionCommandResult = ajv.compile(questionCommandResultSchema);

export const validateDecidePermissionBody = ajv.compile(decidePermissionBodySchema);
export const validatePermissionCommandResult = ajv.compile(permissionCommandResultSchema);

export const validateCommandOutcome = ajv.compile(commandOutcomeSchema);

export * from "./schemas/auth.js";
export * from "./schemas/common.js";
export * from "./schemas/commands.js";
export * from "./schemas/control.js";
export * from "./schemas/devices.js";
export * from "./schemas/events.js";
export * from "./schemas/ingest-keys.js";
export * from "./schemas/pending.js";
export * from "./schemas/permissions.js";
export * from "./schemas/questions.js";
export * from "./schemas/ws.js";
export * from "./types.js";
