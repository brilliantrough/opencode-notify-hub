import { readFileSync } from "node:fs";

import { describe, expect, it } from "vitest";
import { parse } from "yaml";
import { buildOpenApiYaml } from "../scripts/generate-openapi.js";
import {
  validateNotifyEvent,
  validateRegisterBody,
  validateLoginBody,
  validateEmailBody,
  validateVerifyEmailBody,
  validateResetPasswordBody,
  validateRefreshBody,
  validateTokenPair,
  validateRegisterDeviceBody,
  validatePatchDeviceBody,
  validateDevice,
  validateDeviceListResponse,
  validateCreateIngestKeyBody,
  validateCreateIngestKeyResponse,
  validateIngestKeyListResponse,
  validateEventIngestResponse,
  validateHealthStatus,
  validateErrorResponse,
  validatePluginControlClientMessage,
  validatePluginControlServerMessage,
  validateWsServerMessage,
  validatePendingInteraction,
  validatePendingSnapshot,
  validateAnswerQuestionBody,
  validateDecidePermissionBody,
  validateCommandAccepted,
  validateCommandOutcome,
} from "../src/index.js";

const EVENT_ID = "3b8f9c2e-1a4d-4e5f-9a6b-7c8d9e0f1a2b";

const envelope = {
  eventId: EVENT_ID,
  occurredAt: new Date().toISOString(),
  source: { machine: "devbox", project: "api", directory: "/work/api" },
  session: { id: "ses_1", title: "Implement API" },
};

const validHeartbeat = {
  ...envelope,
  type: "heartbeat",
  payload: { status: "busy", elapsedSeconds: 60 },
};

const validTerminal = {
  ...envelope,
  type: "terminal",
  payload: { outcome: "completed", elapsedSeconds: 42 },
};

const validActionRequiredQuestion = {
  ...envelope,
  type: "action_required",
  payload: {
    requestId: "req_1",
    kind: "question",
    questions: [
      {
        question: "Which database should I use?",
        options: [
          { label: "Postgres", description: "Relational" },
          { label: "SQLite" },
        ],
        multiple: false,
      },
    ],
  },
};

const validActionRequiredPermission = {
  ...envelope,
  type: "action_required",
  payload: {
    requestId: "per_1",
    kind: "permission",
    permission: { permission: "bash", summary: "Run rm -rf build/" },
  },
};

const validActionRequiredProviderAction = {
  ...envelope,
  type: "action_required",
  payload: {
    requestId: "pro_1",
    kind: "provider_action",
    providerAction: {
      provider: "anthropic",
      title: "Sign-in required",
      message: "Your Anthropic session has expired.",
      label: "Reconnect",
      link: "https://provider.example/reconnect",
    },
  },
};

const validActionResolved = {
  ...envelope,
  type: "action_resolved",
  payload: { requestId: "req_1", kind: "question" },
};

describe("NotifyEvent envelope", () => {
  it("accepts a heartbeat event", () => {
    expect(validateNotifyEvent(validHeartbeat)).toBe(true);
  });

  it("accepts an action_required event", () => {
    expect(validateNotifyEvent(validActionRequiredQuestion)).toBe(true);
  });

  it("accepts an action_resolved event", () => {
    expect(validateNotifyEvent(validActionResolved)).toBe(true);
  });

  it("accepts a terminal event", () => {
    expect(validateNotifyEvent(validTerminal)).toBe(true);
  });

  it("rejects an unknown event type", () => {
    expect(validateNotifyEvent({ ...validTerminal, type: "question" })).toBe(false);
  });

  it("rejects unknown properties on the envelope", () => {
    expect(validateNotifyEvent({ ...validTerminal, extra: "nope" })).toBe(false);
  });

  it("rejects a non-uuid eventId", () => {
    expect(validateNotifyEvent({ ...validTerminal, eventId: "not-a-uuid" })).toBe(false);
  });

  it("rejects a malformed occurredAt", () => {
    expect(validateNotifyEvent({ ...validTerminal, occurredAt: "yesterday" })).toBe(false);
  });

  it("rejects a structurally impossible occurredAt", () => {
    expect(
      validateNotifyEvent({ ...validTerminal, occurredAt: "2026-13-40T99:99:99Z" }),
    ).toBe(false);
  });

  it("rejects an occurredAt without a timezone", () => {
    expect(
      validateNotifyEvent({ ...validTerminal, occurredAt: "2026-08-09T21:00:00" }),
    ).toBe(false);
  });

  it("rejects a heartbeat discriminator carrying a terminal payload", () => {
    expect(validateNotifyEvent({ ...validTerminal, type: "heartbeat" })).toBe(false);
  });

  it("rejects a terminal discriminator carrying an action_required payload", () => {
    expect(
      validateNotifyEvent({ ...validActionRequiredQuestion, type: "terminal" }),
    ).toBe(false);
  });

  it("rejects an action_resolved discriminator carrying a terminal payload", () => {
    expect(validateNotifyEvent({ ...validTerminal, type: "action_resolved" })).toBe(false);
  });
});

describe("heartbeat payload", () => {
  const withPayload = (payload: unknown) => ({ ...validHeartbeat, payload });

  it("accepts the spec example payload", () => {
    expect(validateNotifyEvent(withPayload({ status: "busy", elapsedSeconds: 60 }))).toBe(true);
  });

  it.each(["busy", "retry"])("accepts status %s", (status) => {
    expect(validateNotifyEvent(withPayload({ status, elapsedSeconds: 0 }))).toBe(true);
  });

  it("rejects an empty payload", () => {
    expect(validateNotifyEvent(withPayload({}))).toBe(false);
  });

  it("requires status", () => {
    expect(validateNotifyEvent(withPayload({ elapsedSeconds: 60 }))).toBe(false);
  });

  it("requires elapsedSeconds", () => {
    expect(validateNotifyEvent(withPayload({ status: "busy" }))).toBe(false);
  });

  it("rejects an unknown status", () => {
    expect(validateNotifyEvent(withPayload({ status: "idle", elapsedSeconds: 60 }))).toBe(false);
  });

  it("rejects a fractional elapsedSeconds", () => {
    expect(validateNotifyEvent(withPayload({ status: "busy", elapsedSeconds: 42.5 }))).toBe(false);
  });

  it("rejects a negative elapsedSeconds", () => {
    expect(validateNotifyEvent(withPayload({ status: "busy", elapsedSeconds: -1 }))).toBe(false);
  });

  it("rejects extra fields", () => {
    expect(
      validateNotifyEvent(withPayload({ status: "busy", elapsedSeconds: 60, note: "hi" })),
    ).toBe(false);
  });
});

describe("terminal payload", () => {
  it.each(["completed", "failed", "stopped"])("accepts outcome %s", (outcome) => {
    expect(
      validateNotifyEvent({ ...validTerminal, payload: { ...validTerminal.payload, outcome } }),
    ).toBe(true);
  });

  it("rejects outcome cancelled", () => {
    expect(
      validateNotifyEvent({
        ...validTerminal,
        payload: { ...validTerminal.payload, outcome: "cancelled" },
      }),
    ).toBe(false);
  });

  it("accepts an elapsedSeconds of 0", () => {
    expect(
      validateNotifyEvent({
        ...validTerminal,
        payload: { ...validTerminal.payload, elapsedSeconds: 0 },
      }),
    ).toBe(true);
  });

  it("rejects a negative elapsedSeconds", () => {
    expect(
      validateNotifyEvent({
        ...validTerminal,
        payload: { ...validTerminal.payload, elapsedSeconds: -1 },
      }),
    ).toBe(false);
  });

  it("rejects a non-integer elapsedSeconds", () => {
    expect(
      validateNotifyEvent({
        ...validTerminal,
        payload: { ...validTerminal.payload, elapsedSeconds: 42.5 },
      }),
    ).toBe(false);
  });

  it("accepts a summary of exactly 500 characters", () => {
    expect(
      validateNotifyEvent({
        ...validTerminal,
        payload: { ...validTerminal.payload, summary: "s".repeat(500) },
      }),
    ).toBe(true);
  });

  it("rejects a summary over 500 characters", () => {
    expect(
      validateNotifyEvent({
        ...validTerminal,
        payload: { ...validTerminal.payload, summary: "s".repeat(501) },
      }),
    ).toBe(false);
  });
});

describe("action_required payload", () => {
  it.each(["question", "permission", "provider_action"])(
    "rejects kind %s without its content section",
    (kind) => {
      expect(
        validateNotifyEvent({
          ...validActionRequiredQuestion,
          payload: { requestId: "req_1", kind },
        }),
      ).toBe(false);
    },
  );

  it("accepts a question payload", () => {
    expect(validateNotifyEvent(validActionRequiredQuestion)).toBe(true);
  });

  it("accepts a permission payload", () => {
    expect(validateNotifyEvent(validActionRequiredPermission)).toBe(true);
  });

  it("accepts a provider_action payload", () => {
    expect(validateNotifyEvent(validActionRequiredProviderAction)).toBe(true);
  });

  it("rejects an unknown kind", () => {
    expect(
      validateNotifyEvent({
        ...validActionRequiredQuestion,
        payload: { requestId: "req_1", kind: "approval", questions: [] },
      }),
    ).toBe(false);
  });

  it("rejects a question kind carrying a permission section", () => {
    expect(
      validateNotifyEvent({
        ...validActionRequiredPermission,
        payload: { ...validActionRequiredPermission.payload, kind: "question" },
      }),
    ).toBe(false);
  });

  it("rejects a permission kind carrying questions", () => {
    expect(
      validateNotifyEvent({
        ...validActionRequiredQuestion,
        payload: { ...validActionRequiredQuestion.payload, kind: "permission" },
      }),
    ).toBe(false);
  });

  it("rejects a provider_action kind carrying a permission section", () => {
    expect(
      validateNotifyEvent({
        ...validActionRequiredPermission,
        payload: { ...validActionRequiredPermission.payload, kind: "provider_action" },
      }),
    ).toBe(false);
  });

  it("rejects plugin-style requestID in favour of lower-camel requestId", () => {
    expect(
      validateNotifyEvent({
        ...validActionRequiredQuestion,
        payload: { requestID: "req_1", kind: "question", questions: [{ question: "Q?" }] },
      }),
    ).toBe(false);
  });
});

describe("action_required question content", () => {
  const withQuestions = (questions: unknown) => ({
    ...validActionRequiredQuestion,
    payload: { ...validActionRequiredQuestion.payload, questions },
  });

  it("keeps questions as an array", () => {
    expect(validateNotifyEvent(withQuestions({ question: "not an array" }))).toBe(false);
  });

  it("rejects the singular question field", () => {
    const { questions: _questions, ...rest } = validActionRequiredQuestion.payload;
    expect(
      validateNotifyEvent({
        ...validActionRequiredQuestion,
        payload: { ...rest, question: { question: "Q?" } },
      }),
    ).toBe(false);
  });

  it("rejects an empty questions array", () => {
    expect(validateNotifyEvent(withQuestions([]))).toBe(false);
  });

  it("accepts a single question", () => {
    expect(validateNotifyEvent(withQuestions([{ question: "Q?" }]))).toBe(true);
  });

  it("accepts question text of exactly 2000 characters", () => {
    expect(validateNotifyEvent(withQuestions([{ question: "q".repeat(2000) }]))).toBe(true);
  });

  it("rejects question text over 2000 characters", () => {
    expect(validateNotifyEvent(withQuestions([{ question: "q".repeat(2001) }]))).toBe(false);
  });

  it("accepts exactly 8 questions", () => {
    expect(
      validateNotifyEvent(
        withQuestions(Array.from({ length: 8 }, (_, i) => ({ question: `Q${i}?` }))),
      ),
    ).toBe(true);
  });

  it("rejects more than 8 questions", () => {
    expect(
      validateNotifyEvent(
        withQuestions(Array.from({ length: 9 }, (_, i) => ({ question: `Q${i}?` }))),
      ),
    ).toBe(false);
  });

  it("accepts exactly 16 options", () => {
    expect(
      validateNotifyEvent(
        withQuestions([
          {
            question: "Pick one",
            options: Array.from({ length: 16 }, (_, i) => ({ label: `opt-${i}` })),
          },
        ]),
      ),
    ).toBe(true);
  });

  it("rejects more than 16 options", () => {
    expect(
      validateNotifyEvent(
        withQuestions([
          {
            question: "Pick one",
            options: Array.from({ length: 17 }, (_, i) => ({ label: `opt-${i}` })),
          },
        ]),
      ),
    ).toBe(false);
  });
});

describe("action_required permission section", () => {
  it("accepts a permission summary of exactly 500 characters", () => {
    expect(
      validateNotifyEvent({
        ...validActionRequiredPermission,
        payload: {
          ...validActionRequiredPermission.payload,
          permission: { permission: "bash", summary: "s".repeat(500) },
        },
      }),
    ).toBe(true);
  });

  it("rejects a permission summary over 500 characters", () => {
    expect(
      validateNotifyEvent({
        ...validActionRequiredPermission,
        payload: {
          ...validActionRequiredPermission.payload,
          permission: { permission: "bash", summary: "s".repeat(501) },
        },
      }),
    ).toBe(false);
  });
});

describe("action_required providerAction section", () => {
  const withProviderAction = (providerAction: unknown) => ({
    ...validActionRequiredProviderAction,
    payload: { ...validActionRequiredProviderAction.payload, providerAction },
  });
  const validSection = validActionRequiredProviderAction.payload.providerAction;

  it("accepts a full section including link", () => {
    expect(validateNotifyEvent(validActionRequiredProviderAction)).toBe(true);
  });

  it("accepts a section without the optional link", () => {
    const { link: _link, ...withoutLink } = validSection;
    expect(validateNotifyEvent(withProviderAction(withoutLink))).toBe(true);
  });

  it.each(["provider", "title", "message", "label"] as const)("requires %s", (field) => {
    const section = { ...validSection } as Partial<typeof validSection>;
    delete section[field];
    expect(validateNotifyEvent(withProviderAction(section))).toBe(false);
  });

  it.each(["provider", "title", "label"] as const)("rejects %s over 120 characters", (field) => {
    expect(
      validateNotifyEvent(withProviderAction({ ...validSection, [field]: "x".repeat(121) })),
    ).toBe(false);
  });

  it.each(["provider", "title", "label"] as const)("accepts %s of exactly 120 characters", (field) => {
    expect(
      validateNotifyEvent(withProviderAction({ ...validSection, [field]: "x".repeat(120) })),
    ).toBe(true);
  });

  it("rejects a message over 500 characters", () => {
    expect(
      validateNotifyEvent(withProviderAction({ ...validSection, message: "m".repeat(501) })),
    ).toBe(false);
  });

  it("accepts a message of exactly 500 characters", () => {
    expect(
      validateNotifyEvent(withProviderAction({ ...validSection, message: "m".repeat(500) })),
    ).toBe(true);
  });

  it("rejects a malformed link URI", () => {
    expect(
      validateNotifyEvent(withProviderAction({ ...validSection, link: "not a uri" })),
    ).toBe(false);
  });

  it("accepts a link of exactly 2048 characters", () => {
    const link = `https://example.com/${"a".repeat(2048 - 20)}`;
    expect(validateNotifyEvent(withProviderAction({ ...validSection, link }))).toBe(true);
  });

  it("rejects a link over 2048 characters", () => {
    const link = `https://example.com/${"a".repeat(2049 - 20)}`;
    expect(validateNotifyEvent(withProviderAction({ ...validSection, link }))).toBe(false);
  });
});

describe("action_resolved payload", () => {
  it.each(["question", "permission"])("accepts kind %s", (kind) => {
    expect(
      validateNotifyEvent({ ...validActionResolved, payload: { requestId: "req_1", kind } }),
    ).toBe(true);
  });

  it("rejects kind provider_action (provider actions have no resolved event)", () => {
    expect(
      validateNotifyEvent({
        ...validActionResolved,
        payload: { requestId: "req_1", kind: "provider_action" },
      }),
    ).toBe(false);
  });

  it("requires requestId", () => {
    expect(
      validateNotifyEvent({ ...validActionResolved, payload: { kind: "question" } }),
    ).toBe(false);
  });
});

describe("email/password bodies", () => {
  it("accepts valid register and login bodies", () => {
    const body = { email: "dev@example.com", password: "correct horse" };
    expect(validateRegisterBody(body)).toBe(true);
    expect(validateLoginBody(body)).toBe(true);
  });

  it("rejects a malformed email", () => {
    expect(validateRegisterBody({ email: "not-an-email", password: "correct horse" })).toBe(false);
  });

  it("rejects an email with an invalid domain", () => {
    expect(
      validateRegisterBody({ email: "dev@example..com", password: "correct horse" }),
    ).toBe(false);
  });

  it.each([7, 129])("rejects a password of length %i", (length) => {
    const body = { email: "dev@example.com", password: "p".repeat(length) };
    expect(validateRegisterBody(body)).toBe(false);
    expect(validateLoginBody(body)).toBe(false);
  });

  it.each([8, 128])("accepts a password of length %i", (length) => {
    const body = { email: "dev@example.com", password: "p".repeat(length) };
    expect(validateRegisterBody(body)).toBe(true);
    expect(validateLoginBody(body)).toBe(true);
  });

  it("rejects unknown properties", () => {
    expect(
      validateLoginBody({ email: "dev@example.com", password: "correct horse", admin: true }),
    ).toBe(false);
  });
});

describe("device schemas", () => {
  const validDevice = {
    id: "dev_1",
    name: "Pixel 8",
    platform: "android",
    enabled: true,
    soundEnabled: false,
    fcmToken: "fcm-token-abc",
  };

  it.each(["windows", "linux", "android"])("accepts platform %s", (platform) => {
    expect(validateRegisterDeviceBody({ name: "Workstation", platform })).toBe(true);
    expect(validateDevice({ ...validDevice, platform })).toBe(true);
  });

  it("rejects platform ios", () => {
    expect(validateRegisterDeviceBody({ name: "Phone", platform: "ios" })).toBe(false);
    expect(validateDevice({ ...validDevice, platform: "ios" })).toBe(false);
  });

  it("accepts an optional fcmToken", () => {
    const { fcmToken: _fcmToken, ...withoutToken } = validDevice;
    expect(validateDevice(withoutToken)).toBe(true);
    expect(validateRegisterDeviceBody({ name: "Workstation", platform: "linux" })).toBe(true);
  });

  it("requires enabled and soundEnabled on the stored device", () => {
    const { enabled: _enabled, ...withoutEnabled } = validDevice;
    expect(validateDevice(withoutEnabled)).toBe(false);
    const { soundEnabled: _soundEnabled, ...withoutSound } = validDevice;
    expect(validateDevice(withoutSound)).toBe(false);
  });

  it("allows the create body to omit enabled/soundEnabled and rely on defaults", () => {
    expect(validateRegisterDeviceBody({ name: "Workstation", platform: "linux" })).toBe(true);
  });

  it("accepts explicit enabled/soundEnabled on the create body", () => {
    expect(
      validateRegisterDeviceBody({
        name: "Workstation",
        platform: "linux",
        enabled: false,
        soundEnabled: true,
      }),
    ).toBe(true);
  });

  it("accepts a partial patch body", () => {
    expect(validatePatchDeviceBody({ soundEnabled: false })).toBe(true);
    expect(validatePatchDeviceBody({ name: "New name", enabled: true })).toBe(true);
  });

  it("rejects an empty patch body", () => {
    expect(validatePatchDeviceBody({})).toBe(false);
  });

  it("rejects unknown properties on create and patch bodies", () => {
    expect(
      validateRegisterDeviceBody({ name: "Workstation", platform: "linux", jailbroken: true }),
    ).toBe(false);
    expect(validatePatchDeviceBody({ platform: "android" })).toBe(false);
  });

  it.each([0, 65])("rejects a device name of length %i", (length) => {
    expect(validateRegisterDeviceBody({ name: "n".repeat(length), platform: "android" })).toBe(
      false,
    );
  });

  it.each([1, 64])("accepts a device name of length %i", (length) => {
    expect(validateRegisterDeviceBody({ name: "n".repeat(length), platform: "android" })).toBe(
      true,
    );
  });

  it("accepts a device list response", () => {
    expect(validateDeviceListResponse([validDevice])).toBe(true);
  });

  it.each([1, 4096])("accepts an fcmToken of length %i on create, patch, and device", (length) => {
    const fcmToken = "t".repeat(length);
    expect(
      validateRegisterDeviceBody({ name: "Workstation", platform: "android", fcmToken }),
    ).toBe(true);
    expect(validatePatchDeviceBody({ fcmToken })).toBe(true);
    expect(validateDevice({ ...validDevice, fcmToken })).toBe(true);
  });

  it("rejects an fcmToken over 4096 characters on create, patch, and device", () => {
    const fcmToken = "t".repeat(4097);
    expect(
      validateRegisterDeviceBody({ name: "Workstation", platform: "android", fcmToken }),
    ).toBe(false);
    expect(validatePatchDeviceBody({ fcmToken })).toBe(false);
    expect(validateDevice({ ...validDevice, fcmToken })).toBe(false);
  });
});

describe("ingest-key schemas", () => {
  it("accepts a valid create body", () => {
    expect(validateCreateIngestKeyBody({ name: "CI key" })).toBe(true);
  });

  it("accepts a create response that includes the secret once", () => {
    expect(
      validateCreateIngestKeyResponse({
        id: "ink_1",
        name: "CI key",
        createdAt: new Date().toISOString(),
        secret: "nk_secret_value",
      }),
    ).toBe(true);
  });

  it("never allows a secret in list responses", () => {
    expect(
      validateIngestKeyListResponse([
        {
          id: "ink_1",
          name: "CI key",
          createdAt: new Date().toISOString(),
          secret: "nk_secret_value",
        },
      ]),
    ).toBe(false);
  });

  it("accepts a list response without secrets", () => {
    expect(
      validateIngestKeyListResponse([
        { id: "ink_1", name: "CI key", createdAt: new Date().toISOString() },
      ]),
    ).toBe(true);
  });
});

describe("WebSocket messages", () => {
  const presence = {
    instanceId: "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
    machine: "devbox",
    project: "api",
    directory: "/work/api",
    openCodeVersion: "1.18.18",
    protocolVersion: 1,
    state: "controllable",
    lastSeenAt: "2026-08-14T09:00:00.000Z",
  };

  it("wraps events as { type: 'event', event }", () => {
    expect(validateWsServerMessage({ type: "event", event: validTerminal })).toBe(true);
    expect(validateWsServerMessage({ type: "event", event: validHeartbeat })).toBe(true);
  });

  it("rejects a bare event as a server message", () => {
    expect(validateWsServerMessage(validTerminal)).toBe(false);
  });

  it("rejects an event wrapper with an invalid event", () => {
    expect(
      validateWsServerMessage({ type: "event", event: { ...validTerminal, type: "heartbeat" } }),
    ).toBe(false);
  });

  it("accepts an authoritative instance presence snapshot", () => {
    expect(
      validateWsServerMessage({ type: "instance_presence", instances: [presence] }),
    ).toBe(true);
    expect(
      validateWsServerMessage({
        type: "instance_presence",
        instances: [
          { ...presence, state: "conflicting" },
          { ...presence, instanceId: "4604c02c-9298-4b82-bf3a-372493361b99", state: "incompatible" },
          { ...presence, instanceId: "49c93966-9ff7-455c-8a22-83e8ef3c55c5", state: "offline" },
        ],
      }),
    ).toBe(true);
  });

  it("rejects malformed or extended presence snapshots", () => {
    expect(
      validateWsServerMessage({
        type: "instance_presence",
        instances: [{ ...presence, state: "online" }],
      }),
    ).toBe(false);
    expect(
      validateWsServerMessage({ type: "instance_presence", instances: [presence], cursor: 1 }),
    ).toBe(false);
  });

  it("has no client-to-server message schema: the socket is receive-ignored", () => {
    // The server never reads client frames (no message protocol), so the
    // contract must not define question-reply/permission-reply client
    // messages — a published schema would claim support that does not exist.
    const yaml = buildOpenApiYaml();
    expect(yaml).not.toContain("WsClientMessage");
    expect(yaml).not.toContain("question-reply");
    expect(yaml).not.toContain("permission-reply");
  });
});

describe("Plugin control WebSocket messages", () => {
  const registration = {
    type: "register",
    instanceId: "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
    machine: "devbox",
    project: "api",
    directory: "/work/api",
    openCodeVersion: "1.18.18",
    protocolVersion: 1,
  };

  it("accepts a strict Plugin instance registration", () => {
    expect(validatePluginControlClientMessage(registration)).toBe(true);
    expect(validatePluginControlClientMessage({ ...registration, extra: true })).toBe(false);
    expect(validatePluginControlClientMessage({ ...registration, instanceId: "runtime-1" })).toBe(
      false,
    );
  });

  it.each(["controllable", "conflicting", "incompatible"])(
    "accepts a %s registration result",
    (state) => {
      expect(
        validatePluginControlServerMessage({
          type: "registration",
          instanceId: registration.instanceId,
          state,
        }),
      ).toBe(true);
    },
  );

  it("carries unsupported control protocol versions for a diagnosable result", () => {
    expect(validatePluginControlClientMessage({ ...registration, protocolVersion: 2 })).toBe(true);
    expect(validatePluginControlClientMessage({ ...registration, protocolVersion: 0 })).toBe(false);
  });

  it("accepts a pending_snapshot_response with no pending interactions", () => {
    expect(
      validatePluginControlClientMessage({
        type: "pending_snapshot_response",
        requestId: "0e3f9c2e-1a4d-4e5f-9a6b-7c8d9e0f1a2b",
        instanceId: registration.instanceId,
        interactions: [],
      }),
    ).toBe(true);
  });

  it("rejects a pending_snapshot_response with a non-uuid requestId or instanceId", () => {
    const response = {
      type: "pending_snapshot_response",
      requestId: "0e3f9c2e-1a4d-4e5f-9a6b-7c8d9e0f1a2b",
      instanceId: registration.instanceId,
      interactions: [],
    };
    expect(validatePluginControlClientMessage({ ...response, requestId: "req_1" })).toBe(false);
    expect(validatePluginControlClientMessage({ ...response, instanceId: "runtime-1" })).toBe(false);
  });

  it("rejects a pending_snapshot_response carrying provider_action interactions", () => {
    expect(
      validatePluginControlClientMessage({
        type: "pending_snapshot_response",
        requestId: "0e3f9c2e-1a4d-4e5f-9a6b-7c8d9e0f1a2b",
        instanceId: registration.instanceId,
        interactions: [
          {
            kind: "provider_action",
            instanceId: registration.instanceId,
            machine: "devbox",
            project: "api",
            directory: "/work/api",
            sessionId: "ses_1",
            sessionTitle: "Implement API",
            requestId: "pro_1",
            occurredAt: "2026-08-14T09:00:00.000Z",
          },
        ],
      }),
    ).toBe(false);
  });

  it("accepts a pending_snapshot_request server frame", () => {
    expect(
      validatePluginControlServerMessage({
        type: "pending_snapshot_request",
        requestId: "0e3f9c2e-1a4d-4e5f-9a6b-7c8d9e0f1a2b",
      }),
    ).toBe(true);
  });

  it("rejects a pending_snapshot_request without a uuid requestId", () => {
    expect(
      validatePluginControlServerMessage({
        type: "pending_snapshot_request",
        requestId: "snap-1",
      }),
    ).toBe(false);
    expect(validatePluginControlServerMessage({ type: "pending_snapshot_request" })).toBe(false);
  });

  it("rejects control frames that mix union members", () => {
    expect(
      validatePluginControlClientMessage({
        ...registration,
        type: "pending_snapshot_request",
      }),
    ).toBe(false);
    expect(
      validatePluginControlServerMessage({
        type: "pending_snapshot_request",
        requestId: "0e3f9c2e-1a4d-4e5f-9a6b-7c8d9e0f1a2b",
        state: "controllable",
      }),
    ).toBe(false);
    expect(
      validatePluginControlServerMessage({
        type: "registration",
        instanceId: registration.instanceId,
        state: "controllable",
        requestId: "0e3f9c2e-1a4d-4e5f-9a6b-7c8d9e0f1a2b",
      }),
    ).toBe(false);
  });

  const answerCommandId = "7f3a9b6c-2d4e-4f5a-8b7c-1d2e3f4a5b6c";

  it("accepts a question_answer_command server frame", () => {
    expect(
      validatePluginControlServerMessage({
        type: "question_answer_command",
        commandId: answerCommandId,
        requestId: "req_1",
        sessionID: "ses_1",
        answers: [["Postgres"], ["rust", "go"]],
      }),
    ).toBe(true);
  });

  it("preserves the exact ordered answer shape on a question_answer_command", () => {
    const answers = [
      ["Postgres"],
      ["rust", "go", "Custom: polyglot"],
      ["Custom: as needed"],
    ];
    expect(
      validatePluginControlServerMessage({
        type: "question_answer_command",
        commandId: answerCommandId,
        requestId: "req_1",
        sessionID: "ses_1",
        answers,
      }),
    ).toBe(true);
    expect(answers).toEqual([
      ["Postgres"],
      ["rust", "go", "Custom: polyglot"],
      ["Custom: as needed"],
    ]);
  });

  it("rejects a malformed question_answer_command frame", () => {
    const command = {
      type: "question_answer_command",
      commandId: answerCommandId,
      requestId: "req_1",
      sessionID: "ses_1",
      answers: [["Postgres"]],
    };
    expect(validatePluginControlServerMessage({ ...command, commandId: "cmd_1" })).toBe(false);
    expect(validatePluginControlServerMessage({ ...command, requestId: "" })).toBe(false);
    expect(validatePluginControlServerMessage({ ...command, answers: [] })).toBe(false);
    expect(validatePluginControlServerMessage({ ...command, answers: [[]] })).toBe(false);
    expect(validatePluginControlServerMessage({ ...command, answers: [[""]] })).toBe(false);
    expect(validatePluginControlServerMessage({ ...command, answers: "Postgres" })).toBe(false);
    expect(
      validatePluginControlServerMessage({
        type: "question_answer_command",
        commandId: answerCommandId,
        requestId: "req_1",
      }),
    ).toBe(false);
  });

  it.each(["confirmed", "stale", "upstream_error", "result_unknown"])(
    "accepts a question_answer_result client frame with status %s",
    (status) => {
      expect(
        validatePluginControlClientMessage({
          type: "question_answer_result",
          commandId: answerCommandId,
          instanceId: registration.instanceId,
          status,
        }),
      ).toBe(true);
    },
  );

  it("rejects a malformed question_answer_result frame", () => {
    const result = {
      type: "question_answer_result",
      commandId: answerCommandId,
      instanceId: registration.instanceId,
      status: "confirmed",
    };
    expect(validatePluginControlClientMessage({ ...result, status: "pending" })).toBe(false);
    expect(validatePluginControlClientMessage({ ...result, commandId: "cmd_1" })).toBe(false);
    expect(validatePluginControlClientMessage({ ...result, instanceId: "runtime-1" })).toBe(false);
    expect(
      validatePluginControlClientMessage({
        type: "question_answer_result",
        commandId: answerCommandId,
        instanceId: registration.instanceId,
      }),
    ).toBe(false);
  });

  it("rejects answer frames that mix union members", () => {
    expect(
      validatePluginControlServerMessage({
        type: "question_answer_command",
        commandId: answerCommandId,
        requestId: "req_1",
        answers: [["Postgres"]],
        instanceId: registration.instanceId,
      }),
    ).toBe(false);
    expect(
      validatePluginControlClientMessage({
        type: "question_answer_result",
        commandId: answerCommandId,
        instanceId: registration.instanceId,
        status: "confirmed",
        answers: [["Postgres"]],
      }),
    ).toBe(false);
  });

  const decideCommandId = "9d4c8a1e-5f2b-4a7d-9e6c-1b3d5f7a9c2e";

  it("accepts a permission_decide_command server frame", () => {
    expect(
      validatePluginControlServerMessage({
        type: "permission_decide_command",
        commandId: decideCommandId,
        requestId: "per_1",
        sessionID: "ses_1",
        decision: "once",
      }),
    ).toBe(true);
    expect(
      validatePluginControlServerMessage({
        type: "permission_decide_command",
        commandId: decideCommandId,
        requestId: "per_1",
        sessionID: "ses_1",
        decision: "always",
      }),
    ).toBe(true);
    expect(
      validatePluginControlServerMessage({
        type: "permission_decide_command",
        commandId: decideCommandId,
        requestId: "per_1",
        sessionID: "ses_1",
        decision: "reject",
      }),
    ).toBe(true);
  });

  it("preserves the exact decision value on a permission_decide_command", () => {
    const command = {
      type: "permission_decide_command",
      commandId: decideCommandId,
      requestId: "per_1",
      sessionID: "ses_1",
      decision: "always",
    };
    expect(validatePluginControlServerMessage(command)).toBe(true);
    expect(command.decision).toBe("always");
  });

  it("rejects a malformed permission_decide_command frame", () => {
    const command = {
      type: "permission_decide_command",
      commandId: decideCommandId,
      requestId: "per_1",
      sessionID: "ses_1",
      decision: "once",
    };
    expect(validatePluginControlServerMessage({ ...command, commandId: "cmd_1" })).toBe(false);
    expect(validatePluginControlServerMessage({ ...command, requestId: "" })).toBe(false);
    expect(validatePluginControlServerMessage({ ...command, decision: "allow" })).toBe(false);
    expect(
      validatePluginControlServerMessage({
        type: "permission_decide_command",
        commandId: decideCommandId,
        requestId: "per_1",
      }),
    ).toBe(false);
  });

  it.each(["confirmed", "stale", "upstream_error", "result_unknown"])(
    "accepts a permission_decide_result client frame with status %s",
    (status) => {
      expect(
        validatePluginControlClientMessage({
          type: "permission_decide_result",
          commandId: decideCommandId,
          instanceId: registration.instanceId,
          status,
        }),
      ).toBe(true);
    },
  );

  it("rejects a malformed permission_decide_result frame", () => {
    const result = {
      type: "permission_decide_result",
      commandId: decideCommandId,
      instanceId: registration.instanceId,
      status: "confirmed",
    };
    expect(validatePluginControlClientMessage({ ...result, status: "pending" })).toBe(false);
    expect(validatePluginControlClientMessage({ ...result, commandId: "cmd_1" })).toBe(false);
    expect(validatePluginControlClientMessage({ ...result, instanceId: "runtime-1" })).toBe(false);
    expect(
      validatePluginControlClientMessage({
        type: "permission_decide_result",
        commandId: decideCommandId,
        instanceId: registration.instanceId,
      }),
    ).toBe(false);
  });

  it("rejects decision frames that mix union members", () => {
    expect(
      validatePluginControlServerMessage({
        type: "permission_decide_command",
        commandId: decideCommandId,
        requestId: "per_1",
        decision: "once",
        answers: [["Postgres"]],
      }),
    ).toBe(false);
    expect(
      validatePluginControlClientMessage({
        type: "permission_decide_result",
        commandId: decideCommandId,
        instanceId: registration.instanceId,
        status: "confirmed",
        decision: "once",
      }),
    ).toBe(false);
  });
});

describe("PendingInteraction union", () => {
  const source = {
    instanceId: "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
    machine: "devbox",
    project: "api",
    directory: "/work/api",
    sessionId: "ses_1",
    sessionTitle: "Implement API",
    requestId: "req_1",
    occurredAt: "2026-08-14T09:00:00.000Z",
  };

  const validQuestion = {
    ...source,
    kind: "question",
    tool: { messageId: "msg_1", callId: "call_1" },
    questions: [
      {
        header: "Database",
        question: "Which database should I use?",
        options: [
          { label: "Postgres", description: "Relational" },
          { label: "SQLite", description: "Embedded" },
        ],
        multiple: false,
        custom: true,
      },
    ],
  };

  const validPermission = {
    ...source,
    kind: "permission",
    permission: "bash",
    patterns: ["rm -rf build/"],
    always: ["printf *"],
    metadata: { source: "interactive", depth: 1 },
  };

  it("accepts a question interaction", () => {
    expect(validatePendingInteraction(validQuestion)).toBe(true);
  });

  it("accepts a permission interaction", () => {
    expect(validatePendingInteraction(validPermission)).toBe(true);
  });

  it("rejects provider_action interactions: they stay ordinary notifications", () => {
    expect(validatePendingInteraction({ ...source, kind: "provider_action" })).toBe(false);
  });

  it("rejects an unknown kind", () => {
    expect(validatePendingInteraction({ ...source, kind: "approval", permission: "bash" })).toBe(
      false,
    );
  });

  it("rejects a question kind carrying permission content", () => {
    expect(
      validatePendingInteraction({
        ...validPermission,
        kind: "question",
        questions: [{ header: "h", question: "Q?", options: [], multiple: false, custom: true }],
      }),
    ).toBe(false);
    const { permission: _permission, ...rest } = validPermission;
    expect(validatePendingInteraction({ ...rest, kind: "question" })).toBe(false);
  });

  it("rejects a permission kind carrying questions", () => {
    expect(
      validatePendingInteraction({ ...validQuestion, kind: "permission", permission: "bash" }),
    ).toBe(false);
  });

  it("rejects unknown properties on the common source", () => {
    expect(validatePendingInteraction({ ...validQuestion, extra: "nope" })).toBe(false);
    expect(validatePendingInteraction({ ...validPermission, cursor: 1 })).toBe(false);
  });

  it("rejects a missing common source field", () => {
    const { sessionTitle: _sessionTitle, ...withoutTitle } = validPermission;
    expect(validatePendingInteraction(withoutTitle)).toBe(false);
    const { occurredAt: _occurredAt, ...withoutTime } = validPermission;
    expect(validatePendingInteraction(withoutTime)).toBe(false);
  });

  it("rejects a non-uuid instanceId", () => {
    expect(validatePendingInteraction({ ...validQuestion, instanceId: "runtime-1" })).toBe(false);
  });

  it("rejects a malformed occurredAt", () => {
    expect(validatePendingInteraction({ ...validQuestion, occurredAt: "yesterday" })).toBe(false);
  });

  it("requires a non-empty requestId", () => {
    expect(validatePendingInteraction({ ...validQuestion, requestId: "" })).toBe(false);
  });
});

describe("PendingInteraction question content", () => {
  const base = {
    kind: "question",
    instanceId: "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
    machine: "devbox",
    project: "api",
    directory: "/work/api",
    sessionId: "ses_1",
    sessionTitle: "Implement API",
    requestId: "req_1",
    occurredAt: "2026-08-14T09:00:00.000Z",
  };

  const withQuestions = (questions: unknown) => ({ ...base, questions });

  it("requires the normalized question fields", () => {
    expect(validatePendingInteraction(withQuestions([{ question: "Q?", options: [] }]))).toBe(false);
    expect(validatePendingInteraction(withQuestions([{ header: "h", options: [] }]))).toBe(false);
    expect(validatePendingInteraction(withQuestions([{ header: "h", question: "Q?" }]))).toBe(false);
    expect(
      validatePendingInteraction(
        withQuestions([{ header: "h", question: "Q?", options: [], custom: true }]),
      ),
    ).toBe(false);
  });

  it("accepts a question with an empty options array and no tool", () => {
    expect(
      validatePendingInteraction(
        withQuestions([
          { header: "h", question: "Q?", options: [], multiple: false, custom: true },
        ]),
      ),
    ).toBe(true);
  });

  it("accepts multiple, custom, and tool", () => {
    expect(
      validatePendingInteraction(
        {
          ...withQuestions([
            {
              header: "h",
              question: "Q?",
              options: [{ label: "A", description: "desc" }],
              multiple: true,
              custom: false,
            },
          ]),
          tool: { messageId: "msg_1", callId: "call_1" },
        },
      ),
    ).toBe(true);
  });

  it("rejects a malformed tool", () => {
    expect(
      validatePendingInteraction(
        {
          ...withQuestions([
            { header: "h", question: "Q?", options: [], multiple: false, custom: true },
          ]),
          tool: { messageId: "msg_1" },
        },
      ),
    ).toBe(false);
  });

  it("retains large complete question payloads", () => {
    expect(
      validatePendingInteraction(
        withQuestions([
          {
            header: "h",
            question: "q".repeat(2001),
            options: Array.from({ length: 17 }, (_, i) => ({
              label: `opt-${i}`,
              description: `description-${i}`,
            })),
            multiple: true,
            custom: true,
          },
        ]),
      ),
    ).toBe(true);
  });

  it("rejects unknown properties on a question item", () => {
    expect(
      validatePendingInteraction(
        withQuestions([
          {
            header: "h",
            question: "Q?",
            options: [],
            multiple: false,
            custom: true,
            note: "nope",
          },
        ]),
      ),
    ).toBe(false);
  });
});

describe("PendingInteraction permission content", () => {
  const base = {
    kind: "permission",
    instanceId: "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
    machine: "devbox",
    project: "api",
    directory: "/work/api",
    sessionId: "ses_1",
    sessionTitle: "Implement API",
    requestId: "per_1",
    occurredAt: "2026-08-14T09:00:00.000Z",
    permission: "bash",
    patterns: ["rm -rf build/"],
    always: ["printf *"],
    metadata: { source: "interactive" },
  };

  it("accepts empty patterns and always arrays", () => {
    expect(validatePendingInteraction({ ...base, patterns: [], always: [] })).toBe(true);
  });

  it("accepts the optional tool identity", () => {
    expect(validatePendingInteraction({ ...base, tool: { messageId: "msg_1", callId: "call_1" } }))
      .toBe(true);
  });

  it("rejects a non-empty permission string", () => {
    expect(validatePendingInteraction({ ...base, permission: "" })).toBe(false);
  });

  it("rejects unknown properties on the permission content", () => {
    expect(validatePendingInteraction({ ...base, summary: "nope" })).toBe(false);
  });

  it("retains arbitrary nested metadata verbatim", () => {
    const metadata = {
      source: "interactive",
      count: 3,
      nested: { list: [1, "two", true, null], deep: { ratio: 0.5 } },
    };
    expect(validatePendingInteraction({ ...base, metadata })).toBe(true);
  });

  it("requires metadata", () => {
    const { metadata: _metadata, ...withoutMetadata } = base;
    expect(validatePendingInteraction(withoutMetadata)).toBe(false);
  });
});

describe("PendingSnapshot", () => {
  const interaction = {
    kind: "question",
    instanceId: "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
    machine: "devbox",
    project: "api",
    directory: "/work/api",
    sessionId: "ses_1",
    sessionTitle: "Implement API",
    requestId: "req_1",
    occurredAt: "2026-08-14T09:00:00.000Z",
    questions: [
      { header: "h", question: "Q?", options: [], multiple: false, custom: true },
    ],
  };

  it("accepts a snapshot with one interaction", () => {
    expect(
      validatePendingSnapshot({
        generatedAt: "2026-08-14T09:00:05.000Z",
        interactions: [interaction],
      }),
    ).toBe(true);
  });

  it("accepts an empty snapshot", () => {
    expect(
      validatePendingSnapshot({ generatedAt: "2026-08-14T09:00:05.000Z", interactions: [] }),
    ).toBe(true);
  });

  it("accepts an optional queriedInstanceIds list", () => {
    expect(
      validatePendingSnapshot({
        generatedAt: "2026-08-14T09:00:05.000Z",
        interactions: [interaction],
        queriedInstanceIds: [
          "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
          "4604c02c-9298-4b82-bf3a-372493361b99",
        ],
      }),
    ).toBe(true);
  });

  it("accepts a snapshot without queriedInstanceIds", () => {
    expect(
      validatePendingSnapshot({ generatedAt: "2026-08-14T09:00:05.000Z", interactions: [] }),
    ).toBe(true);
  });

  it("rejects non-uuid entries in queriedInstanceIds", () => {
    expect(
      validatePendingSnapshot({
        generatedAt: "2026-08-14T09:00:05.000Z",
        interactions: [],
        queriedInstanceIds: ["runtime-1"],
      }),
    ).toBe(false);
  });

  it("rejects a non-array queriedInstanceIds", () => {
    expect(
      validatePendingSnapshot({
        generatedAt: "2026-08-14T09:00:05.000Z",
        interactions: [],
        queriedInstanceIds: "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
      }),
    ).toBe(false);
  });

  it("requires generatedAt and interactions", () => {
    expect(
      validatePendingSnapshot({ interactions: [interaction] }),
    ).toBe(false);
    expect(
      validatePendingSnapshot({ generatedAt: "2026-08-14T09:00:05.000Z" }),
    ).toBe(false);
  });

  it("rejects unknown properties and malformed generatedAt", () => {
    expect(
      validatePendingSnapshot({
        generatedAt: "2026-08-14T09:00:05.000Z",
        interactions: [interaction],
        cursor: 1,
      }),
    ).toBe(false);
    expect(
      validatePendingSnapshot({ generatedAt: "yesterday", interactions: [] }),
    ).toBe(false);
  });

  it("rejects a snapshot containing a provider_action interaction", () => {
    expect(
      validatePendingSnapshot({
        generatedAt: "2026-08-14T09:00:05.000Z",
        interactions: [{ ...interaction, kind: "provider_action" }],
      }),
    ).toBe(false);
  });
});

describe("AnswerQuestion body", () => {
  const commandId = "7f3a9b6c-2d4e-4f5a-8b7c-1d2e3f4a5b6c";
  const sessionId = "ses_1";

  it("accepts a single-select answer with one label", () => {
    expect(
      validateAnswerQuestionBody({
        commandId,
        sessionId,
        answers: [["Postgres"]],
      }),
    ).toBe(true);
  });

  it("accepts a multi-select answer with labels plus custom text", () => {
    expect(
      validateAnswerQuestionBody({
        commandId,
        sessionId,
        answers: [["rust", "go", "Custom: polyglot"]],
      }),
    ).toBe(true);
  });

  it("preserves an exact ordered multi-question shape", () => {
    const answers = [
      ["Postgres"],
      ["rust", "go"],
      ["Custom: as needed"],
    ];
    const body = { commandId, sessionId, answers };
    expect(validateAnswerQuestionBody(body)).toBe(true);
    // The schema validates read-only: the exact upstream question order and
    // per-question groupings survive untouched.
    expect(body.answers).toEqual(answers);
    expect(body.answers.length).toBe(3);
    expect(body.answers[1]).toEqual(["rust", "go"]);
    expect(body.answers[2]).toEqual(["Custom: as needed"]);
  });

  it("accepts many questions without a total-size cap", () => {
    expect(
      validateAnswerQuestionBody({
        commandId,
        sessionId,
        answers: Array.from({ length: 4096 }, () => ["answer"]),
      }),
    ).toBe(true);
  });

  it("accepts complete answers beyond the 1 MiB transport limit", () => {
    const large = "x".repeat(1_048_577);
    expect(
      validateAnswerQuestionBody({ commandId, sessionId, answers: [[large]] }),
    ).toBe(true);
    expect(
      validateAnswerQuestionBody({ commandId, sessionId, answers: [[large], ["y"]] }),
    ).toBe(true);
  });

  it("rejects an empty outer answers array", () => {
    expect(validateAnswerQuestionBody({ commandId, sessionId, answers: [] })).toBe(false);
  });

  it("rejects an empty inner answers array", () => {
    expect(validateAnswerQuestionBody({ commandId, sessionId, answers: [[]] })).toBe(false);
    expect(validateAnswerQuestionBody({ commandId, sessionId, answers: [["Postgres"], []] })).toBe(
      false,
    );
  });

  it("rejects empty answer strings", () => {
    expect(validateAnswerQuestionBody({ commandId, sessionId, answers: [[""]] })).toBe(false);
    expect(validateAnswerQuestionBody({ commandId, sessionId, answers: [["Postgres", ""]] })).toBe(
      false,
    );
  });

  it("rejects non-string answer values", () => {
    expect(validateAnswerQuestionBody({ commandId, sessionId, answers: [[42]] })).toBe(false);
    expect(validateAnswerQuestionBody({ commandId, sessionId, answers: [["Postgres", null]] })).toBe(
      false,
    );
  });

  it("rejects a non-array answers value", () => {
    expect(validateAnswerQuestionBody({ commandId, sessionId, answers: "Postgres" })).toBe(false);
    expect(validateAnswerQuestionBody({ commandId, sessionId, answers: ["Postgres"] })).toBe(false);
  });

  it("requires commandId, sessionId, and answers", () => {
    expect(validateAnswerQuestionBody({ sessionId, answers: [["Postgres"]] })).toBe(false);
    expect(validateAnswerQuestionBody({ commandId, answers: [["Postgres"]] })).toBe(false);
    expect(validateAnswerQuestionBody({ commandId, sessionId })).toBe(false);
    expect(validateAnswerQuestionBody({})).toBe(false);
  });

  it("rejects a non-uuid commandId", () => {
    expect(
      validateAnswerQuestionBody({ commandId: "cmd_1", sessionId, answers: [["Postgres"]] }),
    ).toBe(false);
  });

  it("rejects unknown properties", () => {
    expect(
      validateAnswerQuestionBody({
        commandId,
        sessionId,
        answers: [["Postgres"]],
        instanceId: "nope",
      }),
    ).toBe(false);
  });
});

describe("DecidePermission body", () => {
  const commandId = "9d4c8a1e-5f2b-4a7d-9e6c-1b3d5f7a9c2e";
  const sessionId = "ses_1";

  it("accepts the once decision", () => {
    expect(validateDecidePermissionBody({ commandId, sessionId, decision: "once" })).toBe(
      true,
    );
  });

  it("accepts the reject decision", () => {
    expect(validateDecidePermissionBody({ commandId, sessionId, decision: "reject" })).toBe(
      true,
    );
  });

  it("accepts the always decision", () => {
    expect(validateDecidePermissionBody({ commandId, sessionId, decision: "always" })).toBe(
      true,
    );
  });

  it("rejects an unknown decision", () => {
    expect(validateDecidePermissionBody({ commandId, sessionId, decision: "allow" })).toBe(false);
    expect(validateDecidePermissionBody({ commandId, sessionId, decision: "deny" })).toBe(false);
  });

  it("rejects a non-string decision", () => {
    expect(validateDecidePermissionBody({ commandId, sessionId, decision: 1 })).toBe(false);
    expect(validateDecidePermissionBody({ commandId, sessionId, decision: null })).toBe(false);
  });

  it("requires commandId, sessionId, and decision", () => {
    expect(validateDecidePermissionBody({ sessionId, decision: "once" })).toBe(false);
    expect(validateDecidePermissionBody({ commandId, decision: "once" })).toBe(false);
    expect(validateDecidePermissionBody({ commandId, sessionId })).toBe(false);
    expect(validateDecidePermissionBody({})).toBe(false);
  });

  it("rejects a non-uuid commandId", () => {
    expect(validateDecidePermissionBody({ commandId: "cmd_1", sessionId, decision: "once" })).toBe(
      false,
    );
  });

  it("rejects unknown properties", () => {
    expect(
      validateDecidePermissionBody({ commandId, sessionId, decision: "once", patterns: [] }),
    ).toBe(false);
  });
});

describe("CommandAccepted", () => {
  const commandId = "7f3a9b6c-2d4e-4f5a-8b7c-1d2e3f4a5b6c";

  it("accepts only the one-way accepted acknowledgement", () => {
    expect(validateCommandAccepted({ commandId, status: "accepted" })).toBe(true);
    expect(validateCommandAccepted({ commandId, status: "confirmed" })).toBe(false);
    expect(validateCommandAccepted({ commandId })).toBe(false);
    expect(validateCommandAccepted({ commandId, status: "accepted", answers: [] })).toBe(false);
  });
});

describe("CommandOutcome", () => {
  const commandId = "7f3a9b6c-2d4e-4f5a-8b7c-1d2e3f4a5b6c";
  const instanceId = "6f0d91b0-93e4-43a9-9449-0bed03e651aa";
  const validOutcome = {
    commandId,
    requestId: "req_1",
    instanceId,
    kind: "question",
    status: "confirmed",
    updatedAt: "2026-08-14T09:00:05.000Z",
  } as const;

  it("accepts a valid outcome and preserves it verbatim", () => {
    const outcome = { ...validOutcome };
    expect(validateCommandOutcome(outcome)).toBe(true);
    expect(outcome).toEqual(validOutcome);
  });

  it.each(["question", "permission"] as const)("accepts kind %s", (kind) => {
    expect(validateCommandOutcome({ ...validOutcome, kind })).toBe(true);
  });

  it.each(["accepted", "confirmed", "stale", "upstream_error", "result_unknown"] as const)(
    "accepts status %s",
    (status) => {
      expect(validateCommandOutcome({ ...validOutcome, status })).toBe(true);
    },
  );

  it("rejects an unknown kind", () => {
    expect(validateCommandOutcome({ ...validOutcome, kind: "provider_action" })).toBe(false);
  });

  it("rejects an unknown status", () => {
    expect(validateCommandOutcome({ ...validOutcome, status: "pending" })).toBe(false);
    expect(validateCommandOutcome({ ...validOutcome, status: "failed" })).toBe(false);
    expect(validateCommandOutcome({ ...validOutcome, status: "timeout" })).toBe(false);
  });

  it("rejects a non-uuid commandId", () => {
    expect(validateCommandOutcome({ ...validOutcome, commandId: "cmd_1" })).toBe(false);
  });

  it("rejects a non-uuid instanceId", () => {
    expect(validateCommandOutcome({ ...validOutcome, instanceId: "runtime-1" })).toBe(false);
  });

  it("requires a non-empty requestId", () => {
    expect(validateCommandOutcome({ ...validOutcome, requestId: "" })).toBe(false);
  });

  it("rejects a malformed updatedAt", () => {
    expect(validateCommandOutcome({ ...validOutcome, updatedAt: "yesterday" })).toBe(false);
  });

  it("requires every field", () => {
    for (const field of [
      "commandId",
      "requestId",
      "instanceId",
      "kind",
      "status",
      "updatedAt",
    ] as const) {
      const { [field]: _omitted, ...rest } = validOutcome;
      expect(validateCommandOutcome(rest)).toBe(false);
    }
  });

  it("rejects unknown properties", () => {
    expect(validateCommandOutcome({ ...validOutcome, note: "nope" })).toBe(false);
  });

  it("is body-free by construction: rejects answers, decisions, and metadata", () => {
    expect(validateCommandOutcome({ ...validOutcome, answers: [["Postgres"]] })).toBe(false);
    expect(validateCommandOutcome({ ...validOutcome, decision: "once" })).toBe(false);
    expect(
      validateCommandOutcome({ ...validOutcome, metadata: { source: "interactive" } }),
    ).toBe(false);
  });
});

describe("API support schemas", () => {
  it("accepts a valid EmailBody", () => {
    expect(validateEmailBody({ email: "dev@example.com" })).toBe(true);
  });

  it("rejects a malformed EmailBody email and unknown properties", () => {
    expect(validateEmailBody({ email: "not-an-email" })).toBe(false);
    expect(validateEmailBody({ email: "dev@example.com", code: "AB12CD34" })).toBe(false);
  });

  it("accepts a valid VerifyEmailBody", () => {
    expect(validateVerifyEmailBody({ email: "dev@example.com", code: "AB12CD34" })).toBe(true);
  });

  it.each([7, 9])("rejects a verification code of length %i", (length) => {
    expect(
      validateVerifyEmailBody({ email: "dev@example.com", code: "A".repeat(length) }),
    ).toBe(false);
  });

  it("rejects a non-alphanumeric verification code", () => {
    expect(
      validateVerifyEmailBody({ email: "dev@example.com", code: "AB12CD3!" }),
    ).toBe(false);
  });

  it("accepts a valid ResetPasswordBody", () => {
    expect(
      validateResetPasswordBody({
        email: "dev@example.com",
        code: "AB12CD34",
        password: "correct horse",
      }),
    ).toBe(true);
  });

  it.each([7, 129])("rejects a reset password of length %i", (length) => {
    expect(
      validateResetPasswordBody({
        email: "dev@example.com",
        code: "AB12CD34",
        password: "p".repeat(length),
      }),
    ).toBe(false);
  });

  it("requires the reset code", () => {
    expect(
      validateResetPasswordBody({ email: "dev@example.com", password: "correct horse" }),
    ).toBe(false);
  });

  it("accepts a valid RefreshBody", () => {
    expect(validateRefreshBody({ refreshToken: "rt_abc" })).toBe(true);
  });

  it("rejects an empty or extra-field RefreshBody", () => {
    expect(validateRefreshBody({ refreshToken: "" })).toBe(false);
    expect(validateRefreshBody({ refreshToken: "rt_abc", accessToken: "at" })).toBe(false);
  });

  it("accepts a valid TokenPair", () => {
    expect(validateTokenPair({ accessToken: "at", refreshToken: "rt" })).toBe(true);
  });

  it.each(["accessToken", "refreshToken"] as const)("TokenPair requires %s", (field) => {
    const pair = { accessToken: "at", refreshToken: "rt" } as Record<string, string>;
    delete pair[field];
    expect(validateTokenPair(pair)).toBe(false);
  });

  it("accepts a valid EventIngestResponse", () => {
    expect(validateEventIngestResponse({ eventId: EVENT_ID, deduplicated: false })).toBe(true);
  });

  it("rejects a non-uuid EventIngestResponse eventId", () => {
    expect(validateEventIngestResponse({ eventId: "nope", deduplicated: true })).toBe(false);
  });

  it("requires deduplicated on EventIngestResponse", () => {
    expect(validateEventIngestResponse({ eventId: EVENT_ID })).toBe(false);
  });

  it("accepts the ok HealthStatus", () => {
    expect(validateHealthStatus({ status: "ok" })).toBe(true);
  });

  it("rejects any other HealthStatus", () => {
    expect(validateHealthStatus({ status: "degraded" })).toBe(false);
    expect(validateHealthStatus({ status: "ok", detail: "db" })).toBe(false);
  });

  it("accepts a valid ErrorResponse", () => {
    expect(validateErrorResponse({ error: { code: "NOT_FOUND", message: "Route not found" } })).toBe(
      true,
    );
  });

  it("rejects an ErrorResponse with an empty code or extra fields", () => {
    expect(validateErrorResponse({ error: { code: "", message: "Route not found" } })).toBe(false);
    expect(
      validateErrorResponse({ error: { code: "NOT_FOUND", message: "x", stack: "..." } }),
    ).toBe(false);
  });
});

describe("OpenAPI generation", () => {
  it("matches the checked-in openapi.yaml with no drift", () => {
    expect(buildOpenApiYaml()).toBe(
      readFileSync(new URL("../openapi/openapi.yaml", import.meta.url), "utf8"),
    );
  });

  it("documents POST /v1/events success as 202 Accepted, never 200", () => {
    interface OpenApiLike {
      paths: {
        "/v1/events": {
          post: {
            responses: Record<
              string,
              { content?: { "application/json"?: { schema?: unknown } } }
            >;
          };
        };
      };
    }
    const document = parse(buildOpenApiYaml()) as OpenApiLike;
    const responses = document.paths["/v1/events"].post.responses;
    // The gateway accepts signed events asynchronously: 202 with the ingest
    // outcome, and no 200 variant anywhere in the contract.
    expect(Object.keys(responses)).toContain("202");
    expect(Object.keys(responses)).not.toContain("200");
    expect(responses["202"].content?.["application/json"]?.schema).toEqual({
      $ref: "#/components/schemas/EventIngestResponse",
    });
  });

  it("documents the authenticated question answer command path", () => {
    interface OpenApiLike {
      paths: {
        [path: string]: {
          post?: {
            operationId: string;
            security: Record<string, unknown>[];
            parameters: { name: string; schema: { type: string } }[];
            responses: Record<string, { content?: { "application/json"?: { schema: unknown } } }>;
          };
        };
      };
    }
    const document = parse(buildOpenApiYaml()) as OpenApiLike;
    const path = "/v1/pending-interactions/{instanceId}/questions/{requestId}/answer";
    const operation = document.paths[path]?.post;
    expect(operation).toBeDefined();
    expect(operation?.operationId).toBe("answerQuestion");
    expect(operation?.security).toEqual([{ bearerAuth: [] }]);
    const parameterNames = (operation?.parameters ?? []).map(({ name }) => name);
    expect(parameterNames).toEqual(["instanceId", "requestId"]);
    expect(operation?.responses["202"].content?.["application/json"]?.schema).toEqual({
      $ref: "#/components/schemas/CommandAccepted",
    });
    expect(Object.keys(operation?.responses ?? {}).sort()).toEqual([
      "202",
      "400",
      "401",
      "404",
      "409",
    ]);
  });

  it("documents the authenticated permission decision command path", () => {
    interface OpenApiLike {
      paths: {
        [path: string]: {
          post?: {
            operationId: string;
            security: Record<string, unknown>[];
            parameters: { name: string; schema: { type: string } }[];
            responses: Record<string, { content?: { "application/json"?: { schema: unknown } } }>;
          };
        };
      };
    }
    const document = parse(buildOpenApiYaml()) as OpenApiLike;
    const path = "/v1/pending-interactions/{instanceId}/permissions/{requestId}/decision";
    const operation = document.paths[path]?.post;
    expect(operation).toBeDefined();
    expect(operation?.operationId).toBe("decidePermission");
    expect(operation?.security).toEqual([{ bearerAuth: [] }]);
    const parameterNames = (operation?.parameters ?? []).map(({ name }) => name);
    expect(parameterNames).toEqual(["instanceId", "requestId"]);
    expect(operation?.responses["202"].content?.["application/json"]?.schema).toEqual({
      $ref: "#/components/schemas/CommandAccepted",
    });
    expect(Object.keys(operation?.responses ?? {}).sort()).toEqual([
      "202",
      "400",
      "401",
      "404",
      "409",
    ]);
  });

  it("documents the authenticated command outcome GET path", () => {
    interface OpenApiLike {
      paths: {
        [path: string]: {
          get?: {
            operationId: string;
            security: Record<string, unknown>[];
            parameters: { name: string; schema: { type: string; format?: string } }[];
            responses: Record<string, { content?: { "application/json"?: { schema: unknown } } }>;
          };
        };
      };
      components: {
        schemas: Record<string, unknown>;
      };
    }
    const document = parse(buildOpenApiYaml()) as OpenApiLike;
    const path = "/v1/pending-interactions/commands/{commandId}";
    const operation = document.paths[path]?.get;
    expect(operation).toBeDefined();
    expect(operation?.operationId).toBe("getCommandOutcome");
    expect(operation?.security).toEqual([{ bearerAuth: [] }]);
    expect(operation?.parameters).toEqual([
      {
        name: "commandId",
        in: "path",
        required: true,
        description: "Client-generated command identifier.",
        schema: { type: "string", format: "uuid" },
      },
    ]);
    expect(operation?.responses["200"].content?.["application/json"]?.schema).toEqual({
      $ref: "#/components/schemas/CommandOutcome",
    });
    expect(Object.keys(operation?.responses ?? {}).sort()).toEqual(["200", "401", "404"]);
    expect(document.components.schemas.CommandOutcome).toBeDefined();
  });
});
