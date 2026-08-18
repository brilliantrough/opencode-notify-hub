import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { resolve } from "node:path";

import { stringify } from "yaml";

import {
  emailBodySchema,
  loginBodySchema,
  refreshBodySchema,
  registerBodySchema,
  resetPasswordBodySchema,
  tokenPairSchema,
  verifyEmailBodySchema,
} from "../src/schemas/auth.js";
import { errorResponseSchema, healthStatusSchema } from "../src/schemas/common.js";
import {
  commandAcceptedSchema,
  commandOutcomeSchema,
  sendPromptBodySchema,
} from "../src/schemas/commands.js";
import {
  instancePresenceSchema,
  pluginControlClientMessageSchema,
  pluginControlServerMessageSchema,
} from "../src/schemas/control.js";
import {
  deviceListResponseSchema,
  deviceSchema,
  patchDeviceBodySchema,
  registerDeviceBodySchema,
} from "../src/schemas/devices.js";
import { eventIngestResponseSchema, notifyEventSchema } from "../src/schemas/events.js";
import {
  createIngestKeyBodySchema,
  createIngestKeyResponseSchema,
  ingestKeyListResponseSchema,
} from "../src/schemas/ingest-keys.js";
import { pendingInteractionSchema, pendingSnapshotSchema } from "../src/schemas/pending.js";
import { decidePermissionBodySchema } from "../src/schemas/permissions.js";
import { answerQuestionBodySchema } from "../src/schemas/questions.js";
import { wsServerMessageSchema } from "../src/schemas/ws.js";

// The API version is sourced from the package metadata so the document can
// never drift from the published contracts version.
const { version: apiVersion } = JSON.parse(
  readFileSync(new URL("../package.json", import.meta.url), "utf8"),
) as { version: string };

const ref = (name: string) => ({ $ref: `#/components/schemas/${name}` });

const jsonBody = (name: string) => ({
  required: true,
  content: { "application/json": { schema: ref(name) } },
});

const jsonResponse = (description: string, name: string) => ({
  description,
  content: { "application/json": { schema: ref(name) } },
});

const emptyResponse = (description: string) => ({ description });

const errorResponse = (description: string) => jsonResponse(description, "ErrorResponse");

const idPathParameter = (description: string) => ({
  name: "id",
  in: "path",
  required: true,
  description,
  schema: { type: "string", minLength: 1 },
});

const instanceIdPathParameter = {
  name: "instanceId",
  in: "path",
  required: true,
  description: "OpenCode instance identifier.",
  schema: { type: "string", format: "uuid" },
};

const requestIdPathParameter = {
  name: "requestId",
  in: "path",
  required: true,
  description: "OpenCode question request identifier.",
  schema: { type: "string", minLength: 1 },
};

const commandIdPathParameter = {
  name: "commandId",
  in: "path",
  required: true,
  description: "Client-generated command identifier.",
  schema: { type: "string", format: "uuid" },
};

const sessionIdPathParameter = {
  name: "sessionId",
  in: "path",
  required: true,
  description: "OpenCode Session identifier.",
  schema: { type: "string", minLength: 1 },
};

const permissionRequestIdPathParameter = {
  name: "requestId",
  in: "path",
  required: true,
  description: "OpenCode permission request identifier.",
  schema: { type: "string", minLength: 1 },
};

const ingestSignatureParameters = [
  {
    name: "X-Notify-Timestamp",
    in: "header",
    required: true,
    description:
      "Unix milliseconds. Requests more than 5 minutes from server time are rejected.",
    schema: { type: "integer" },
  },
  {
    name: "X-Notify-Signature",
    in: "header",
    required: true,
    description:
      "Hex HMAC-SHA256 of `${timestamp}.${rawBody}` keyed with the ingest-key secret.",
    schema: { type: "string" },
  },
];

const bearerSecurity = [{ bearerAuth: [] }];
const ingestSecurity = [{ ingestKeyAuth: [] }];
const pluginKeySecurity = [{ pluginKeyAuth: [] }];

const document = {
  openapi: "3.1.0",
  info: {
    title: "opencode-notify gateway",
    version: apiVersion,
    license: {
      name: "MIT",
      identifier: "MIT",
    },
    description:
      "Single protocol source for the opencode-notify gateway, the OpenCode plugin, " +
      "and the Flutter clients. Generated from the shared JSON schemas in " +
      "@notify/contracts; do not edit by hand.",
  },
  paths: {
    "/v1/auth/register": {
      post: {
        operationId: "register",
        tags: ["auth"],
        security: [],
        summary: "Register an account and send a verification email.",
        requestBody: jsonBody("RegisterBody"),
        responses: {
          "201": emptyResponse("Account created; verification email sent."),
          "400": errorResponse("Validation failed."),
          "409": errorResponse("Email already registered."),
          "429": errorResponse("Rate limited."),
          "503": errorResponse(
            "Verification email delivery failed; the unverified account can resend later.",
          ),
        },
      },
    },
    "/v1/auth/verify-email": {
      post: {
        operationId: "verifyEmail",
        tags: ["auth"],
        security: [],
        summary: "Verify an email address with the SMTP-delivered code.",
        requestBody: jsonBody("VerifyEmailBody"),
        responses: {
          "204": emptyResponse("Email verified."),
          "400": errorResponse("Invalid, expired, or already used code."),
          "429": errorResponse("Rate limited."),
        },
      },
    },
    "/v1/auth/resend-verification": {
      post: {
        operationId: "resendVerification",
        tags: ["auth"],
        security: [],
        summary: "Resend the verification email.",
        description:
          "Returns the same response for known and unknown emails to avoid enumeration.",
        requestBody: jsonBody("EmailBody"),
        responses: {
          "204": emptyResponse("Verification email sent when the account exists."),
          "429": errorResponse("Rate limited."),
          "503": errorResponse("Email delivery failed; retry later."),
        },
      },
    },
    "/v1/auth/login": {
      post: {
        operationId: "login",
        tags: ["auth"],
        security: [],
        summary: "Log in with email and password.",
        requestBody: jsonBody("LoginBody"),
        responses: {
          "200": jsonResponse("Session tokens.", "TokenPair"),
          "400": errorResponse("Validation failed."),
          "401": errorResponse("Invalid credentials."),
          "403": errorResponse("Email address is not verified."),
          "429": errorResponse("Rate limited."),
        },
      },
    },
    "/v1/auth/refresh": {
      post: {
        operationId: "refresh",
        tags: ["auth"],
        security: [],
        summary: "Rotate a refresh token for a new token pair.",
        description:
          "Every refresh rotates the refresh token. Presenting an already rotated " +
          "token revokes the whole token family (REFRESH_REUSED).",
        requestBody: jsonBody("RefreshBody"),
        responses: {
          "200": jsonResponse("Rotated session tokens.", "TokenPair"),
          "400": errorResponse("Validation failed."),
          "401": errorResponse("Invalid, expired, or reused refresh token."),
          "429": errorResponse("Rate limited."),
        },
      },
    },
    "/v1/auth/logout": {
      post: {
        operationId: "logout",
        tags: ["auth"],
        security: [],
        summary: "Revoke a refresh token.",
        description: "Idempotent: unknown or already revoked tokens still return 204.",
        requestBody: jsonBody("RefreshBody"),
        responses: {
          "204": emptyResponse("Refresh token revoked."),
          "400": errorResponse("Validation failed."),
        },
      },
    },
    "/v1/auth/forgot-password": {
      post: {
        operationId: "forgotPassword",
        tags: ["auth"],
        security: [],
        summary: "Send a password reset email.",
        description:
          "Returns the same response for known and unknown emails to avoid enumeration.",
        requestBody: jsonBody("EmailBody"),
        responses: {
          "204": emptyResponse("Reset email sent when the account exists."),
          "429": errorResponse("Rate limited."),
        },
      },
    },
    "/v1/auth/reset-password": {
      post: {
        operationId: "resetPassword",
        tags: ["auth"],
        security: [],
        summary: "Reset the password with the SMTP-delivered code.",
        description: "A successful reset revokes every refresh-token family of the user.",
        requestBody: jsonBody("ResetPasswordBody"),
        responses: {
          "204": emptyResponse("Password reset."),
          "400": errorResponse("Invalid, expired, or already used code."),
          "429": errorResponse("Rate limited."),
        },
      },
    },
    "/v1/devices": {
      get: {
        operationId: "listDevices",
        tags: ["devices"],
        security: bearerSecurity,
        summary: "List the authenticated user's devices.",
        responses: {
          "200": jsonResponse("Registered devices.", "DeviceListResponse"),
          "401": errorResponse("Missing or invalid access token."),
        },
      },
      post: {
        operationId: "registerDevice",
        tags: ["devices"],
        security: bearerSecurity,
        summary: "Register a device.",
        description:
          "The server applies enabled/soundEnabled defaults when the body omits them.",
        requestBody: jsonBody("RegisterDeviceBody"),
        responses: {
          "201": jsonResponse("Registered device.", "Device"),
          "400": errorResponse("Validation failed."),
          "401": errorResponse("Missing or invalid access token."),
        },
      },
    },
    "/v1/devices/{id}": {
      patch: {
        operationId: "updateDevice",
        tags: ["devices"],
        security: bearerSecurity,
        summary: "Update a device.",
        parameters: [idPathParameter("Device identifier.")],
        requestBody: jsonBody("PatchDeviceBody"),
        responses: {
          "200": jsonResponse("Updated device.", "Device"),
          "400": errorResponse("Validation failed."),
          "401": errorResponse("Missing or invalid access token."),
          "404": errorResponse("Unknown device for this user."),
        },
      },
      delete: {
        operationId: "deleteDevice",
        tags: ["devices"],
        security: bearerSecurity,
        summary: "Delete a device.",
        parameters: [idPathParameter("Device identifier.")],
        responses: {
          "204": emptyResponse("Device deleted."),
          "401": errorResponse("Missing or invalid access token."),
          "404": errorResponse("Unknown device for this user."),
        },
      },
    },
    "/v1/ingest-keys": {
      get: {
        operationId: "listIngestKeys",
        tags: ["ingest-keys"],
        security: bearerSecurity,
        summary: "List ingest keys.",
        description: "List items never include the key secret.",
        responses: {
          "200": jsonResponse("Ingest keys without secrets.", "IngestKeyListResponse"),
          "401": errorResponse("Missing or invalid access token."),
        },
      },
      post: {
        operationId: "createIngestKey",
        tags: ["ingest-keys"],
        security: bearerSecurity,
        summary: "Create an ingest key.",
        description:
          "The secret is returned exactly once in this response and is never " +
          "recoverable afterwards; the server stores only SHA-256(secret).",
        requestBody: jsonBody("CreateIngestKeyBody"),
        responses: {
          "201": jsonResponse(
            "Created ingest key including the one-time secret.",
            "CreateIngestKeyResponse",
          ),
          "400": errorResponse("Validation failed."),
          "401": errorResponse("Missing or invalid access token."),
        },
      },
    },
    "/v1/ingest-keys/{id}": {
      delete: {
        operationId: "revokeIngestKey",
        tags: ["ingest-keys"],
        security: bearerSecurity,
        summary: "Revoke an ingest key.",
        parameters: [idPathParameter("Ingest-key identifier.")],
        responses: {
          "204": emptyResponse("Ingest key revoked."),
          "401": errorResponse("Missing or invalid access token."),
          "404": errorResponse("Unknown ingest key for this user."),
        },
      },
    },
    "/v1/events": {
      post: {
        operationId: "ingestEvent",
        tags: ["events"],
        security: ingestSecurity,
        summary: "Ingest a signed notification event from the OpenCode plugin.",
        description:
          "Authenticate with `Authorization: Bearer keyId.secret` plus the " +
          "X-Notify-Timestamp and X-Notify-Signature HMAC headers. Events are " +
          "deduplicated per user by eventId for a short window.",
        parameters: ingestSignatureParameters,
        requestBody: jsonBody("NotifyEvent"),
        responses: {
          "202": jsonResponse("Ingest outcome.", "EventIngestResponse"),
          "400": errorResponse("Validation failed."),
          "401": errorResponse("Unknown, revoked, or badly signed ingest credentials."),
          "429": errorResponse("Rate limited."),
        },
      },
    },
    "/v1/pending-interactions": {
      get: {
        operationId: "getPendingInteractions",
        tags: ["pending"],
        security: bearerSecurity,
        summary: "List the authenticated user's pending interactions.",
        description:
          "Asks every owned online compatible Plugin instance for its current " +
          "OpenCode questions and permissions and returns a unified snapshot. " +
          "OpenCode is authoritative; the snapshot is a projection. Conflicting, " +
          "incompatible, and offline instances are not queried, and provider " +
          "actions never appear here.",
        responses: {
          "200": jsonResponse("Pending interactions snapshot.", "PendingSnapshot"),
          "401": errorResponse("Missing or invalid access token."),
        },
      },
    },
    "/v1/pending-interactions/{instanceId}/questions/{requestId}/answer": {
      post: {
        operationId: "answerQuestion",
        tags: ["pending"],
        security: bearerSecurity,
        summary: "Submit a complete answer set for a pending OpenCode question.",
        description:
          "Validates and submits one complete ordered answer set for a pending " +
          "question owned by the authenticated account and routes the command to " +
          "the exact Plugin instance. The body includes the event-derived sessionId, " +
          "so the Plugin can call the session-scoped OpenCode reply directly. The " +
          "202 response only acknowledges best-effort delivery; it does not confirm " +
          "that OpenCode applied the answers. Leaving the request unanswered has " +
          "no OpenCode side effect and never invokes question reject.",
        parameters: [instanceIdPathParameter, requestIdPathParameter],
        requestBody: jsonBody("AnswerQuestionBody"),
        responses: {
          "202": jsonResponse("Command accepted for best-effort delivery.", "CommandAccepted"),
          "400": errorResponse("Validation failed."),
          "401": errorResponse("Missing or invalid access token."),
          "404": errorResponse(
            "Unknown instance for this user, or no matching pending question request.",
          ),
          "409": errorResponse(
            "Command conflicts with existing state; for example the request is stale " +
              "or a conflicting command is already in flight.",
          ),
        },
      },
    },
    "/v1/pending-interactions/{instanceId}/permissions/{requestId}/decision": {
      post: {
        operationId: "decidePermission",
        tags: ["pending"],
        security: bearerSecurity,
        summary: "Submit an immediate decision for a pending OpenCode permission.",
        description:
          "Validates and submits one immediate allow-once, always-allow, or " +
          "reject decision for a pending permission owned by the authenticated " +
          "account and routes the command to the exact Plugin instance. The body " +
          "includes the event-derived sessionId, and the 202 response only " +
          "acknowledges best-effort delivery; it does not confirm that OpenCode applied the " +
          "decision. Leaving the request undecided has no OpenCode side effect.",
        parameters: [instanceIdPathParameter, permissionRequestIdPathParameter],
        requestBody: jsonBody("DecidePermissionBody"),
        responses: {
          "202": jsonResponse("Command accepted for best-effort delivery.", "CommandAccepted"),
          "400": errorResponse("Validation failed."),
          "401": errorResponse("Missing or invalid access token."),
          "404": errorResponse(
            "Unknown instance for this user, or no matching pending permission request.",
          ),
          "409": errorResponse(
            "Command conflicts with existing state; for example the request is stale " +
              "or a conflicting command is already in flight.",
          ),
        },
      },
    },
    "/v1/pending-interactions/commands/{commandId}": {
      get: {
        operationId: "getCommandOutcome",
        tags: ["pending"],
        security: bearerSecurity,
        summary: "Query the body-free outcome of a client-generated command.",
        description:
          "Returns the in-memory outcome correlation for a command submitted by " +
          "the authenticated account, keyed by the client-generated commandId. " +
          "The outcome is body-free: it carries only correlation and status " +
          "metadata, never the question answers or permission decision. This is " +
          "an optional diagnostic surface; successful best-effort submissions " +
          "do not wait for it.",
        parameters: [commandIdPathParameter],
        responses: {
          "200": jsonResponse("Body-free command outcome.", "CommandOutcome"),
          "401": errorResponse("Missing or invalid access token."),
          "404": errorResponse("Unknown command outcome for this user."),
        },
      },
    },
    "/v1/instances/{instanceId}/sessions/{sessionId}/prompt": {
      post: {
        operationId: "sendSessionPrompt",
        tags: ["sessions"],
        security: bearerSecurity,
        summary: "Send one free-form prompt to an online OpenCode Session.",
        description:
          "Routes one text prompt to the authenticated user's exact online Plugin " +
          "instance. The 202 response acknowledges that the Gateway wrote the " +
          "command to the Plugin control connection; it does not wait for OpenCode " +
          "to admit or execute the prompt. Prompts are never queued or retried.",
        parameters: [instanceIdPathParameter, sessionIdPathParameter],
        requestBody: jsonBody("SendPromptBody"),
        responses: {
          "202": jsonResponse("Prompt accepted for best-effort delivery.", "CommandAccepted"),
          "400": errorResponse("Validation failed."),
          "401": errorResponse("Missing or invalid access token."),
          "404": errorResponse("Unknown or non-actionable instance for this user."),
          "409": errorResponse("The same command is already in flight."),
        },
      },
    },
    "/v1/ws": {
      get: {
        operationId: "connectEvents",
        tags: ["realtime"],
        security: bearerSecurity,
        summary: "Upgrade to the realtime WebSocket.",
        description:
          "The HTTP Upgrade request authenticates with the bearer access token. " +
          "After the upgrade the server sends WsServerMessage frames; there is " +
          "no client-to-server message protocol and incoming frames are " +
          "ignored. The socket closes with code 4401 when the access token " +
          "expires; reconnect with a fresh token. Events missed while " +
          "disconnected are not replayed.",
        responses: {
          "101": emptyResponse(
            "WebSocket upgrade accepted; frames carry WsServerMessage only.",
          ),
          "401": errorResponse("Missing or invalid access token."),
        },
      },
    },
    "/v1/webui/ws": {
      get: {
        operationId: "connectWebUiTunnel",
        tags: ["sessions"],
        security: bearerSecurity,
        summary: "Upgrade a temporary WebUI tunnel.",
        description:
          "The client sends one webui_tunnel_open frame naming an online instance, " +
          "then proxies HTTP and SSE requests through the authenticated tunnel. " +
          "The tunnel is memory-only and ends when either WebSocket closes.",
        responses: {
          "101": emptyResponse("WebUI tunnel upgrade accepted."),
          "401": errorResponse("Missing or invalid access token."),
          "403": errorResponse("Origin is not allowed."),
        },
      },
    },
    "/v1/plugin/ws": {
      get: {
        operationId: "connectPluginControl",
        tags: ["realtime"],
        security: pluginKeySecurity,
        summary: "Upgrade an OpenCode Plugin to its control WebSocket.",
        description:
          "The HTTP Upgrade authenticates with the existing Plugin key. The " +
          "Plugin sends one PluginControlClientMessage registration and receives " +
          "a PluginControlServerMessage result. Notification ingestion remains " +
          "available when control is conflicting or incompatible.",
        responses: {
          "101": emptyResponse("WebSocket upgrade accepted for Plugin control frames."),
          "401": errorResponse("Missing, unknown, or revoked Plugin key."),
        },
      },
    },
    "/health/live": {
      get: {
        operationId: "checkLiveness",
        tags: ["health"],
        security: [],
        summary: "Liveness probe.",
        responses: {
          "200": jsonResponse("Process is alive.", "HealthStatus"),
        },
      },
    },
    "/health/ready": {
      get: {
        operationId: "checkReadiness",
        tags: ["health"],
        security: [],
        summary: "Readiness probe.",
        description:
          "Ready only when the database is reachable and migrations are current.",
        responses: {
          "200": jsonResponse("Ready to serve.", "HealthStatus"),
          "503": errorResponse("Database unavailable or schema not migrated."),
        },
      },
    },
  },
  components: {
    securitySchemes: {
      bearerAuth: {
        type: "http",
        scheme: "bearer",
        bearerFormat: "JWT",
        description: "Short-lived (15 minute) JWT access token from login or refresh.",
      },
      ingestKeyAuth: {
        type: "http",
        scheme: "bearer",
        description:
          "Ingest credentials `keyId.secret`; every request must also carry valid " +
          "X-Notify-Timestamp and X-Notify-Signature HMAC headers.",
      },
      pluginKeyAuth: {
        type: "http",
        scheme: "bearer",
        description:
          "Plugin credential `keyId.secret`; the control WebSocket does not use " +
          "the event-ingest HMAC headers.",
      },
    },
    schemas: {
      AnswerQuestionBody: answerQuestionBodySchema,
      CommandAccepted: commandAcceptedSchema,
      CommandOutcome: commandOutcomeSchema,
      CreateIngestKeyBody: createIngestKeyBodySchema,
      CreateIngestKeyResponse: createIngestKeyResponseSchema,
      DecidePermissionBody: decidePermissionBodySchema,
      Device: deviceSchema,
      DeviceListResponse: deviceListResponseSchema,
      EmailBody: emailBodySchema,
      ErrorResponse: errorResponseSchema,
      EventIngestResponse: eventIngestResponseSchema,
      HealthStatus: healthStatusSchema,
      IngestKeyListResponse: ingestKeyListResponseSchema,
      InstancePresence: instancePresenceSchema,
      LoginBody: loginBodySchema,
      NotifyEvent: notifyEventSchema,
      PendingInteraction: pendingInteractionSchema,
      PendingSnapshot: pendingSnapshotSchema,
      PluginControlClientMessage: pluginControlClientMessageSchema,
      PluginControlServerMessage: pluginControlServerMessageSchema,
      PatchDeviceBody: patchDeviceBodySchema,
      RefreshBody: refreshBodySchema,
      RegisterBody: registerBodySchema,
      RegisterDeviceBody: registerDeviceBodySchema,
      ResetPasswordBody: resetPasswordBodySchema,
      SendPromptBody: sendPromptBodySchema,
      TokenPair: tokenPairSchema,
      VerifyEmailBody: verifyEmailBodySchema,
      WsServerMessage: wsServerMessageSchema,
    },
  },
};

const sortKeys = (value: unknown): unknown => {
  if (Array.isArray(value)) {
    return value.map(sortKeys);
  }
  if (value !== null && typeof value === "object") {
    return Object.fromEntries(
      Object.entries(value as Record<string, unknown>)
        .sort(([left], [right]) => (left < right ? -1 : left > right ? 1 : 0))
        .map(([key, entry]) => [key, sortKeys(entry)]),
    );
  }
  return value;
};

// Deterministic by construction: every object key is sorted recursively before
// serialization and the YAML emitter is given a fixed configuration.
export function buildOpenApiYaml(): string {
  return stringify(sortKeys(document), { lineWidth: 0 });
}

const isMain =
  process.argv[1] !== undefined && fileURLToPath(import.meta.url) === resolve(process.argv[1]);

if (isMain) {
  const target = new URL("../openapi/openapi.yaml", import.meta.url);
  mkdirSync(new URL("../openapi/", import.meta.url), { recursive: true });
  writeFileSync(target, buildOpenApiYaml());
  console.log(`wrote ${fileURLToPath(target)}`);
}
