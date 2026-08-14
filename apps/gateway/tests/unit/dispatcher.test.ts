import { validateNotifyEvent, type NotifyEvent } from "@notify/contracts";
import type { Message, Messaging } from "firebase-admin/messaging";
import { describe, expect, it } from "vitest";

import type {
  AndroidPushTarget,
  DevicePatch,
} from "../../src/modules/devices/devices.repository.js";
import {
  CompositeEventDispatcher,
  FCM_SEND_TIMEOUT_MS,
  FcmSendTimeoutError,
  type DispatchLogger,
  type PushTargetStore,
} from "../../src/modules/events/dispatcher.js";
import type { EventDispatcher } from "../../src/modules/events/events.routes.js";
import {
  InvalidFcmTokenError,
  type FcmPush,
  type FcmSender,
} from "../../src/modules/fcm/fcm-sender.js";
import { FirebaseAdminFcmSender } from "../../src/modules/fcm/firebase-fcm-sender.js";
import {
  buildPushContent,
  CHANNEL_ALERTS,
  CHANNEL_SILENT,
  FCM_HARD_LIMIT_BYTES,
  FCM_MESSAGE_BUDGET_BYTES,
} from "../../src/modules/fcm/payload.js";

const USER = "user-1";

const BASE = {
  eventId: "3f6f1e2a-7c3b-4d5e-8f60-1a2b3c4d5e6f",
  occurredAt: "2026-08-10T12:00:00.000Z",
  source: { machine: "workstation", project: "notify", directory: "/repo" },
  session: { id: "session-1", title: "Coding" },
} as const;

/** Sentinels: these strings must never appear in log output. */
const SECRET_TOKEN_A = "SECRET_FCM_TOKEN_A";
const SECRET_TOKEN_B = "SECRET_FCM_TOKEN_B";
const SENSITIVE_QUESTION = "SENSITIVE: may I delete the production database?";

const HEARTBEAT: NotifyEvent = {
  ...BASE,
  type: "heartbeat",
  payload: { status: "busy", elapsedSeconds: 12 },
} as NotifyEvent;

const ACTION_RESOLVED: NotifyEvent = {
  ...BASE,
  type: "action_resolved",
  payload: { requestId: "req-1", kind: "question" },
} as NotifyEvent;

const QUESTION_EVENT: NotifyEvent = {
  ...BASE,
  type: "action_required",
  payload: {
    requestId: "req-1",
    kind: "question",
    questions: [{ question: SENSITIVE_QUESTION, options: [{ label: "Yes" }, { label: "No" }] }],
  },
} as NotifyEvent;

const TERMINAL_EVENT: NotifyEvent = {
  ...BASE,
  type: "terminal",
  payload: { outcome: "completed", elapsedSeconds: 42, summary: "All tests pass" },
} as NotifyEvent;

/** Contract-maximal question event: 8 x (2000-char question, 16 options). */
function hugeQuestionEvent(): NotifyEvent {
  const questions = Array.from({ length: 8 }, (_, i) => ({
    question: `Q${i}-${"x".repeat(2000)}`,
    multiple: i % 2 === 0,
    options: Array.from({ length: 16 }, (_, j) => ({
      label: `opt-${i}-${j}-${"y".repeat(80)}`,
      description: "z".repeat(400),
    })),
  }));
  return {
    ...BASE,
    type: "action_required",
    payload: { requestId: "req-big", kind: "question", questions },
  } as NotifyEvent;
}

/** Independent measure of the message the adapter puts on the wire. */
function pushMessageBytes(push: FcmPush): number {
  return Buffer.byteLength(
    JSON.stringify({
      notification: { title: push.title, body: push.body },
      data: { event: push.dataEvent },
    }),
    "utf8",
  );
}

class FakeRealtime implements EventDispatcher {
  calls: { userId: string; event: NotifyEvent }[] = [];

  async dispatch(input: { userId: string; event: NotifyEvent }): Promise<void> {
    this.calls.push(input);
  }
}

class FakeDevices implements PushTargetStore {
  targets: AndroidPushTarget[] = [];
  listCalls: string[] = [];
  updates: { userId: string; id: string; patch: DevicePatch }[] = [];
  listError: Error | null = null;
  updateError: Error | null = null;

  async listAndroidPushTargets(userId: string): Promise<AndroidPushTarget[]> {
    this.listCalls.push(userId);
    if (this.listError !== null) {
      throw this.listError;
    }
    return this.targets;
  }

  async update(input: {
    userId: string;
    id: string;
    patch: DevicePatch;
  }): Promise<null> {
    this.updates.push(input);
    if (this.updateError !== null) {
      throw this.updateError;
    }
    return null;
  }
}

class FakeFcm implements FcmSender {
  sent: FcmPush[] = [];
  /** token -> error to throw for that device. */
  failures = new Map<string, unknown>();

  async send(push: FcmPush): Promise<void> {
    const failure = this.failures.get(push.token);
    if (failure !== undefined) {
      throw failure;
    }
    this.sent.push(push);
  }
}

/**
 * Sends that start synchronously but settle only when the test releases
 * them — proves sends run concurrently (a serial sender starts the second
 * send only after the first resolves).
 */
class DeferredFcm implements FcmSender {
  started: FcmPush[] = [];
  private releases: (() => void)[] = [];

  send(push: FcmPush): Promise<void> {
    this.started.push(push);
    return new Promise<void>((resolve) => {
      this.releases.push(resolve);
    });
  }

  resolveAll(): void {
    for (const release of this.releases.splice(0)) {
      release();
    }
  }
}

/** Sends that never settle (only a timeout can cut them). */
class HangingFcm implements FcmSender {
  started: FcmPush[] = [];

  send(push: FcmPush): Promise<void> {
    this.started.push(push);
    return new Promise<void>(() => {});
  }
}

interface LogEntry {
  level: "warn" | "error";
  obj: Record<string, unknown>;
  message: string;
}

class FakeLogger implements DispatchLogger {
  entries: LogEntry[] = [];

  warn(obj: Record<string, unknown>, message: string): void {
    this.entries.push({ level: "warn", obj, message });
  }

  error(obj: Record<string, unknown>, message: string): void {
    this.entries.push({ level: "error", obj, message });
  }

  serialized(): string {
    return JSON.stringify(this.entries);
  }
}

interface DispatcherFixture {
  dispatcher: CompositeEventDispatcher;
  realtime: FakeRealtime;
  devices: FakeDevices;
  logger: FakeLogger;
}

function makeDispatcher(): DispatcherFixture & { fcm: FakeFcm };
function makeDispatcher(overrides: {
  fcm?: FcmSender;
  sendTimeoutMs?: number;
}): DispatcherFixture & { fcm: FcmSender };
function makeDispatcher(overrides: { fcm?: FcmSender; sendTimeoutMs?: number } = {}) {
  const realtime = new FakeRealtime();
  const devices = new FakeDevices();
  const fcm = overrides.fcm ?? new FakeFcm();
  const logger = new FakeLogger();
  const dispatcher = new CompositeEventDispatcher({
    realtime,
    devices,
    fcm,
    logger,
    ...(overrides.sendTimeoutMs !== undefined
      ? { sendTimeoutMs: overrides.sendTimeoutMs }
      : {}),
  });
  return { dispatcher, realtime, devices, fcm, logger };
}

const TARGET_SOUND: AndroidPushTarget = {
  id: "dev-sound",
  fcmToken: SECRET_TOKEN_A,
  soundEnabled: true,
};
const TARGET_SILENT: AndroidPushTarget = {
  id: "dev-silent",
  fcmToken: SECRET_TOKEN_B,
  soundEnabled: false,
};

describe("CompositeEventDispatcher", () => {
  it("heartbeat fans out over WebSocket only — no target lookup, no FCM", async () => {
    const { dispatcher, realtime, devices, fcm } = makeDispatcher();
    await dispatcher.dispatch({ userId: USER, event: HEARTBEAT });
    expect(realtime.calls).toEqual([{ userId: USER, event: HEARTBEAT }]);
    expect(devices.listCalls).toEqual([]);
    expect(fcm.sent).toEqual([]);
  });

  it("action_resolved fans out over WebSocket only — no target lookup, no FCM", async () => {
    const { dispatcher, realtime, devices, fcm } = makeDispatcher();
    await dispatcher.dispatch({ userId: USER, event: ACTION_RESOLVED });
    expect(realtime.calls).toEqual([{ userId: USER, event: ACTION_RESOLVED }]);
    expect(devices.listCalls).toEqual([]);
    expect(fcm.sent).toEqual([]);
  });

  it("action_required pushes to every enabled Android target of exactly this user", async () => {
    const { dispatcher, realtime, devices, fcm } = makeDispatcher();
    devices.targets = [TARGET_SOUND, TARGET_SILENT];
    await dispatcher.dispatch({ userId: USER, event: QUESTION_EVENT });
    expect(realtime.calls).toEqual([{ userId: USER, event: QUESTION_EVENT }]);
    expect(devices.listCalls).toEqual([USER]);
    expect(fcm.sent.map((p) => p.token)).toEqual(
      expect.arrayContaining([SECRET_TOKEN_A, SECRET_TOKEN_B]),
    );
  });

  it("terminal pushes to every enabled Android target", async () => {
    const { dispatcher, devices, fcm } = makeDispatcher();
    devices.targets = [TARGET_SOUND];
    await dispatcher.dispatch({ userId: USER, event: TERMINAL_EVENT });
    expect(fcm.sent).toHaveLength(1);
    expect(fcm.sent[0]?.token).toBe(SECRET_TOKEN_A);
  });

  it("sound-enabled devices use the alerts channel, sound-disabled the silent channel", async () => {
    const { dispatcher, devices, fcm } = makeDispatcher();
    devices.targets = [TARGET_SOUND, TARGET_SILENT];
    await dispatcher.dispatch({ userId: USER, event: QUESTION_EVENT });
    const byToken = new Map(fcm.sent.map((p) => [p.token, p]));
    expect(byToken.get(SECRET_TOKEN_A)?.channelId).toBe(CHANNEL_ALERTS);
    expect(byToken.get(SECRET_TOKEN_B)?.channelId).toBe(CHANNEL_SILENT);
  });

  it("typical events carry the complete serialized envelope, byte-for-byte", async () => {
    const { dispatcher, devices, fcm } = makeDispatcher();
    devices.targets = [TARGET_SOUND];
    await dispatcher.dispatch({ userId: USER, event: QUESTION_EVENT });
    const dataEvent = fcm.sent[0]?.dataEvent ?? "";
    expect(dataEvent).toBe(JSON.stringify(QUESTION_EVENT));
    expect(JSON.parse(dataEvent)).toEqual(QUESTION_EVENT);
  });

  it("push uses a concise project, machine, and status title", async () => {
    const { dispatcher, devices, fcm } = makeDispatcher();
    devices.targets = [TARGET_SOUND];
    await dispatcher.dispatch({ userId: USER, event: QUESTION_EVENT });
    expect(fcm.sent[0]?.title).toBe("notify · workstation · 需要回答");
    expect(fcm.sent[0]?.body).toBe(`${SENSITIVE_QUESTION}\n选项：Yes、No`);
  });

  it("terminal push uses a readable outcome and duration body", async () => {
    const { dispatcher, devices, fcm } = makeDispatcher();
    devices.targets = [TARGET_SOUND];
    await dispatcher.dispatch({ userId: USER, event: TERMINAL_EVENT });
    expect(fcm.sent[0]?.title).toBe("notify · workstation · 任务已完成");
    expect(fcm.sent[0]?.body).toBe("用时 42 秒\nAll tests pass");
  });

  it("replaces a legacy internal project id and never falls back to a session id", () => {
    const sessionId = "ses_internal_123";
    const event = {
      ...BASE,
      source: {
        machine: "workstation",
        project: "03c3139669b073a1c6f2d7daa73a08eb70a3c037",
        directory: String.raw`C:\work\opencode-notify`,
      },
      session: { id: sessionId, title: sessionId },
      type: "terminal",
      payload: { outcome: "completed", elapsedSeconds: 5 },
    } as NotifyEvent;

    const content = buildPushContent(event);

    expect(content?.title).toBe("opencode-notify · workstation · 任务已完成");
    expect(content?.body).toBe("用时 5 秒");
    expect(content?.title).not.toContain(sessionId);
    expect(content?.body).not.toContain(sessionId);
  });

  it("question push shows three prompts and summarizes the remainder", () => {
    const event = {
      ...QUESTION_EVENT,
      payload: {
        ...QUESTION_EVENT.payload,
        questions: ["Q1", "Q2", "Q3", "Q4"].map((question) => ({ question })),
      },
    } as NotifyEvent;

    const content = buildPushContent(event);

    expect(content?.body).toBe("Q1\nQ2\nQ3\n还有 1 个问题");
  });

  it("zero targets resolves without any FCM send", async () => {
    const { dispatcher, devices, fcm } = makeDispatcher();
    devices.targets = [];
    await expect(
      dispatcher.dispatch({ userId: USER, event: QUESTION_EVENT }),
    ).resolves.toBeUndefined();
    expect(fcm.sent).toEqual([]);
  });

  it("a maximal contract event fits the total message budget and keeps essential fields", async () => {
    const event = hugeQuestionEvent();
    expect(Buffer.byteLength(JSON.stringify(event), "utf8")).toBeGreaterThan(
      FCM_MESSAGE_BUDGET_BYTES,
    );
    const { dispatcher, devices, fcm } = makeDispatcher();
    devices.targets = [TARGET_SOUND];
    await dispatcher.dispatch({ userId: USER, event });

    const push = fcm.sent[0];
    expect(push).toBeDefined();
    expect(pushMessageBytes(push as FcmPush)).toBeLessThanOrEqual(FCM_MESSAGE_BUDGET_BYTES);
    const parsed = JSON.parse(push?.dataEvent ?? "") as Record<string, unknown>;
    expect(validateNotifyEvent(parsed), JSON.stringify(validateNotifyEvent.errors)).toBe(true);
    expect(parsed.eventId).toBe(event.eventId);
    expect(parsed.type).toBe("action_required");
    expect(parsed.occurredAt).toBe(event.occurredAt);
    expect(parsed.source).toEqual(event.source);
    expect(parsed.session).toEqual(event.session);
    const payload = parsed.payload as {
      requestId: string;
      kind: string;
      questions: unknown[];
    };
    expect(payload.requestId).toBe("req-big");
    expect(payload.kind).toBe("question");
    expect(payload.questions).toHaveLength(8);
  });

  it("multibyte display text is truncated by code points: budget holds, no split surrogates", async () => {
    const event = {
      ...BASE,
      type: "action_required",
      payload: {
        requestId: "req-emoji",
        kind: "question",
        questions: [{ question: "🔥".repeat(1000) }],
      },
    } as NotifyEvent;
    const { dispatcher, devices, fcm } = makeDispatcher();
    devices.targets = [TARGET_SOUND];
    await dispatcher.dispatch({ userId: USER, event });

    const push = fcm.sent[0] as FcmPush;
    expect(pushMessageBytes(push)).toBeLessThanOrEqual(FCM_MESSAGE_BUDGET_BYTES);
    // Pin: even a maximal multibyte event stays under the FCM wire ceiling.
    expect(pushMessageBytes(push)).toBeLessThan(FCM_HARD_LIMIT_BYTES);
    const parsed = JSON.parse(push.dataEvent) as {
      payload: { questions: { question: string }[] };
    };
    expect(validateNotifyEvent(parsed)).toBe(true);
    const text = parsed.payload.questions[0]?.question ?? "";
    // Truncated (4000 raw bytes cannot fit), but never mid-surrogate-pair.
    expect([...text].length).toBeLessThan(1000);
    expect(() => encodeURIComponent(text)).not.toThrow();
    expect(() => encodeURIComponent(push.body)).not.toThrow();
  });

  it("compaction is deterministic: the same event yields the same bytes", async () => {
    const event = hugeQuestionEvent();
    const first = buildPushContent(event);
    const second = buildPushContent(event);
    expect(first).not.toBeNull();
    expect(second?.dataEvent).toBe(first?.dataEvent);
    expect(second?.title).toBe(first?.title);
    expect(second?.body).toBe(first?.body);
  });

  it("a terminal event over budget drops the optional summary but keeps outcome", async () => {
    const event = {
      ...BASE,
      session: { id: "session-1", title: "t".repeat(3000) },
      type: "terminal",
      payload: { outcome: "failed", elapsedSeconds: 3, summary: "s".repeat(500) },
    } as NotifyEvent;
    const content = buildPushContent(event);
    expect(content).not.toBeNull();
    expect(
      Buffer.byteLength(
        JSON.stringify({
          notification: { title: content?.title, body: content?.body },
          data: { event: content?.dataEvent },
        }),
        "utf8",
      ),
    ).toBeLessThanOrEqual(FCM_MESSAGE_BUDGET_BYTES);
    const parsed = JSON.parse(content?.dataEvent ?? "") as {
      payload: { outcome: string; summary?: string };
    };
    expect(validateNotifyEvent(parsed)).toBe(true);
    expect(parsed.payload.outcome).toBe("failed");
    expect(parsed.payload.summary).toBeUndefined();
  });

  it("an impossible event never reaches FCM or the target lookup: sanitized warn, dispatch resolves", async () => {
    const event = {
      ...BASE,
      session: { id: "session-1", title: "t".repeat(10_000) },
      type: "terminal",
      payload: { outcome: "completed", elapsedSeconds: 3 },
    } as NotifyEvent;
    const { dispatcher, realtime, devices, fcm, logger } = makeDispatcher();
    devices.targets = [TARGET_SOUND];
    await expect(
      dispatcher.dispatch({ userId: USER, event }),
    ).resolves.toBeUndefined();
    expect(realtime.calls).toHaveLength(1);
    // Content is built before the lookup, so an unsendable event skips the DB.
    expect(devices.listCalls).toEqual([]);
    expect(fcm.sent).toEqual([]);
    expect(logger.entries.some((e) => e.level === "warn")).toBe(true);
    expect(logger.serialized()).toContain(event.eventId);
    expect(logger.serialized()).not.toContain("tttt");
    expect(logger.serialized()).not.toContain(SECRET_TOKEN_A);
  });

  it("device sends run concurrently, not serially", async () => {
    const fcm = new DeferredFcm();
    const { dispatcher, devices } = makeDispatcher({ fcm });
    devices.targets = [TARGET_SOUND, TARGET_SILENT];
    const pending = dispatcher.dispatch({ userId: USER, event: QUESTION_EVENT });
    // Let the dispatch reach the sends.
    await new Promise<void>((resolve) => {
      setImmediate(resolve);
    });
    // A serial sender would have started only the first send.
    expect(fcm.started.map((p) => p.token)).toEqual(
      expect.arrayContaining([SECRET_TOKEN_A, SECRET_TOKEN_B]),
    );
    expect(fcm.started).toHaveLength(2);
    fcm.resolveAll();
    await expect(pending).resolves.toBeUndefined();
  });

  it(
    "a hanging send is cut by the timeout, logged sanitized, and never rejects dispatch",
    { timeout: 5000 },
    async () => {
      const fcm = new HangingFcm();
      const { dispatcher, devices, logger } = makeDispatcher({ fcm, sendTimeoutMs: 25 });
      devices.targets = [TARGET_SOUND];
      await expect(
        dispatcher.dispatch({ userId: USER, event: QUESTION_EVENT }),
      ).resolves.toBeUndefined();
      expect(fcm.started).toHaveLength(1);
      const errors = logger.entries.filter((e) => e.level === "error");
      expect(errors).toHaveLength(1);
      expect(errors[0]?.obj).toMatchObject({
        userId: USER,
        deviceId: TARGET_SOUND.id,
        eventId: QUESTION_EVENT.eventId,
        code: "notify/fcm-send-timeout",
      });
      expect(logger.serialized()).not.toContain(SECRET_TOKEN_A);
      expect(logger.serialized()).not.toContain(SENSITIVE_QUESTION);
    },
  );

  it("a timed-out device does not delay or block another device's send", async () => {
    const hanging = new HangingFcm();
    const fcm: FcmSender = {
      send(push: FcmPush): Promise<void> {
        if (push.token === SECRET_TOKEN_A) {
          return hanging.send(push);
        }
        return Promise.resolve();
      },
    };
    const { dispatcher, devices } = makeDispatcher({ fcm, sendTimeoutMs: 25 });
    devices.targets = [TARGET_SOUND, TARGET_SILENT];
    await expect(
      dispatcher.dispatch({ userId: USER, event: QUESTION_EVENT }),
    ).resolves.toBeUndefined();
    expect(hanging.started).toHaveLength(1);
  });

  it("one device's generic failure does not stop other devices and never rejects dispatch", async () => {
    const { dispatcher, devices, fcm } = makeDispatcher();
    devices.targets = [TARGET_SOUND, TARGET_SILENT];
    fcm.failures.set(
      SECRET_TOKEN_A,
      Object.assign(new Error(`send failed for token ${SECRET_TOKEN_A}`), {
        code: "messaging/internal-error",
      }),
    );
    await expect(
      dispatcher.dispatch({ userId: USER, event: QUESTION_EVENT }),
    ).resolves.toBeUndefined();
    expect(fcm.sent.map((p) => p.token)).toEqual([SECRET_TOKEN_B]);
  });

  it("generic failures are logged sanitized: IDs and code, no token, no payload, no error message", async () => {
    const { dispatcher, devices, fcm, logger } = makeDispatcher();
    devices.targets = [TARGET_SOUND];
    fcm.failures.set(
      SECRET_TOKEN_A,
      Object.assign(new Error(`send failed for token ${SECRET_TOKEN_A}`), {
        code: "messaging/internal-error",
      }),
    );
    await dispatcher.dispatch({ userId: USER, event: QUESTION_EVENT });
    const errors = logger.entries.filter((e) => e.level === "error");
    expect(errors).toHaveLength(1);
    expect(errors[0]?.obj).toMatchObject({
      userId: USER,
      deviceId: TARGET_SOUND.id,
      eventId: QUESTION_EVENT.eventId,
      code: "messaging/internal-error",
    });
    expect(logger.serialized()).not.toContain(SECRET_TOKEN_A);
    expect(logger.serialized()).not.toContain(SENSITIVE_QUESTION);
    expect(logger.serialized()).not.toContain("send failed for token");
  });

  it("an invalid/unregistered token clears only that device's fcmToken and other devices continue", async () => {
    const { dispatcher, devices, fcm } = makeDispatcher();
    devices.targets = [TARGET_SOUND, TARGET_SILENT];
    fcm.failures.set(
      SECRET_TOKEN_A,
      new InvalidFcmTokenError("messaging/registration-token-not-registered"),
    );
    await expect(
      dispatcher.dispatch({ userId: USER, event: QUESTION_EVENT }),
    ).resolves.toBeUndefined();
    expect(devices.updates).toEqual([
      { userId: USER, id: TARGET_SOUND.id, patch: { fcmToken: null } },
    ]);
    expect(fcm.sent.map((p) => p.token)).toEqual([SECRET_TOKEN_B]);
  });

  it("invalid-token cleanup is logged sanitized: IDs and code, no token, no payload", async () => {
    const { dispatcher, devices, fcm, logger } = makeDispatcher();
    devices.targets = [TARGET_SOUND];
    fcm.failures.set(
      SECRET_TOKEN_A,
      new InvalidFcmTokenError("messaging/registration-token-not-registered"),
    );
    await dispatcher.dispatch({ userId: USER, event: QUESTION_EVENT });
    const warns = logger.entries.filter((e) => e.level === "warn");
    expect(warns).toHaveLength(1);
    expect(warns[0]?.obj).toMatchObject({
      userId: USER,
      deviceId: TARGET_SOUND.id,
      eventId: QUESTION_EVENT.eventId,
      code: "messaging/registration-token-not-registered",
    });
    expect(logger.serialized()).not.toContain(SECRET_TOKEN_A);
    expect(logger.serialized()).not.toContain(SENSITIVE_QUESTION);
  });

  it("a failed token cleanup never rejects dispatch and is logged sanitized", async () => {
    const { dispatcher, devices, fcm, logger } = makeDispatcher();
    devices.targets = [TARGET_SOUND];
    devices.updateError = new Error(`db write leaked token ${SECRET_TOKEN_A}`);
    fcm.failures.set(
      SECRET_TOKEN_A,
      new InvalidFcmTokenError("messaging/invalid-registration-token"),
    );
    await expect(
      dispatcher.dispatch({ userId: USER, event: QUESTION_EVENT }),
    ).resolves.toBeUndefined();
    expect(logger.entries.some((e) => e.level === "error")).toBe(true);
    expect(logger.serialized()).not.toContain(SECRET_TOKEN_A);
    expect(logger.serialized()).not.toContain("db write leaked token");
  });

  it("a target-lookup failure propagates so the ingest route can answer a retryable 503", async () => {
    const { dispatcher, realtime, devices, fcm } = makeDispatcher();
    const dbError = new Error("connection ended");
    devices.listError = dbError;
    await expect(dispatcher.dispatch({ userId: USER, event: QUESTION_EVENT })).rejects.toBe(
      dbError,
    );
    // WebSocket fanout always happens, even when the push leg then fails.
    expect(realtime.calls).toHaveLength(1);
    expect(fcm.sent).toEqual([]);
  });

  it("pins the per-device send timeout at 5 seconds", () => {
    expect(FCM_SEND_TIMEOUT_MS).toBe(5000);
    expect(new FcmSendTimeoutError().code).toBe("notify/fcm-send-timeout");
  });
});

describe("FirebaseAdminFcmSender", () => {
  class FakeMessaging {
    sent: Message[] = [];
    error: unknown = null;

    async send(message: Message): Promise<string> {
      this.sent.push(message);
      if (this.error !== null) {
        throw this.error;
      }
      return "projects/p/messages/1";
    }
  }

  function makeSender() {
    const messaging = new FakeMessaging();
    const sender = new FirebaseAdminFcmSender(messaging as unknown as Messaging);
    return { sender, messaging };
  }

  const PUSH: FcmPush = {
    token: SECRET_TOKEN_A,
    title: "Action required",
    body: "body",
    channelId: CHANNEL_ALERTS,
    dataEvent: '{"eventId":"x"}',
  };

  it("sends notification + data.event with android ttl 0, high priority and the channel id", async () => {
    const { sender, messaging } = makeSender();
    await sender.send(PUSH);
    expect(messaging.sent).toHaveLength(1);
    const message = messaging.sent[0];
    expect(message).toEqual({
      token: SECRET_TOKEN_A,
      notification: { title: "Action required", body: "body" },
      data: { event: '{"eventId":"x"}' },
      android: {
        ttl: 0,
        priority: "high",
        notification: { channelId: CHANNEL_ALERTS },
      },
    });
    // ttl must be exactly zero (immediate-or-never), not undefined.
    expect(message.android?.ttl).toBe(0);
  });

  it("maps registration-token-not-registered to InvalidFcmTokenError", async () => {
    const { sender, messaging } = makeSender();
    messaging.error = Object.assign(new Error("not registered"), {
      code: "messaging/registration-token-not-registered",
    });
    const failure = await sender.send(PUSH).catch((e: unknown) => e);
    expect(failure).toBeInstanceOf(InvalidFcmTokenError);
    expect((failure as InvalidFcmTokenError).code).toBe(
      "messaging/registration-token-not-registered",
    );
  });

  it("maps invalid-registration-token to InvalidFcmTokenError", async () => {
    const { sender, messaging } = makeSender();
    messaging.error = Object.assign(new Error("bad token"), {
      code: "messaging/invalid-registration-token",
    });
    const failure = await sender.send(PUSH).catch((e: unknown) => e);
    expect(failure).toBeInstanceOf(InvalidFcmTokenError);
    expect((failure as InvalidFcmTokenError).code).toBe("messaging/invalid-registration-token");
  });

  it("other firebase errors pass through untouched", async () => {
    const { sender, messaging } = makeSender();
    const internal = Object.assign(new Error("internal"), {
      code: "messaging/internal-error",
    });
    messaging.error = internal;
    await expect(sender.send(PUSH)).rejects.toBe(internal);
  });
});

describe("buildPushContent", () => {
  it("pins the size contract: total message budget 3600 bytes, FCM hard limit 4096 bytes", () => {
    // 3600 leaves headroom for a maximum-length registration token and the
    // Android config (ttl/priority/channel) under the 4096 wire ceiling.
    expect(FCM_MESSAGE_BUDGET_BYTES).toBe(3600);
    expect(FCM_HARD_LIMIT_BYTES).toBe(4096);
  });

  it("pins the Android notification channels", () => {
    expect(CHANNEL_ALERTS).toBe("opencode_alerts");
    expect(CHANNEL_SILENT).toBe("opencode_silent");
  });

  it("returns null when even the fully compacted message exceeds the budget", () => {
    const event = {
      ...BASE,
      session: { id: "session-1", title: "t".repeat(10_000) },
      type: "terminal",
      payload: { outcome: "completed", elapsedSeconds: 3 },
    } as NotifyEvent;
    expect(buildPushContent(event)).toBeNull();
  });

  it("every push title carries the project and a readable status", () => {
    const permission: NotifyEvent = {
      ...BASE,
      type: "action_required",
      payload: {
        requestId: "per-1",
        kind: "permission",
        permission: { permission: "bash", summary: "Run rm -rf build/" },
      },
    } as NotifyEvent;
    const providerAction: NotifyEvent = {
      ...BASE,
      type: "action_required",
      payload: {
        requestId: "pro-1",
        kind: "provider_action",
        providerAction: {
          provider: "anthropic",
          title: "Sign-in required",
          message: "Your Anthropic session has expired.",
          label: "Reconnect",
        },
      },
    } as NotifyEvent;
    for (const event of [QUESTION_EVENT, permission, providerAction, TERMINAL_EVENT]) {
      const content = buildPushContent(event);
      expect(content).not.toBeNull();
      expect(content?.title).toContain(event.source.project);
      expect(content?.title).toContain(event.source.machine);
    }
  });

  it("a maximal multibyte source keeps title and message within budget, code-point safe", () => {
    const event = {
      ...BASE,
      source: {
        machine: `devbox-${"🔥".repeat(200)}`,
        project: `proj-${"界".repeat(200)}`,
        directory: "/repo",
      },
      type: "terminal",
      payload: { outcome: "failed", elapsedSeconds: 7, summary: "s".repeat(500) },
    } as NotifyEvent;
    const content = buildPushContent(event);
    expect(content).not.toBeNull();
    const bytes = Buffer.byteLength(
      JSON.stringify({
        notification: { title: content?.title, body: content?.body },
        data: { event: content?.dataEvent },
      }),
      "utf8",
    );
    expect(bytes).toBeLessThanOrEqual(FCM_MESSAGE_BUDGET_BYTES);
    // Compacted, but never mid-surrogate-pair.
    expect(() => encodeURIComponent(content?.title ?? "")).not.toThrow();
    expect(() => encodeURIComponent(content?.body ?? "")).not.toThrow();
  });
});
