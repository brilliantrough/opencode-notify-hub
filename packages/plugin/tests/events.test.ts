import { describe, expect, it } from "vitest";

import { normalizeEvent } from "../src/events.js";
import {
  devPermissionAsked,
  devPermissionReplied,
  devQuestionAsked,
  devQuestionRejected,
  devQuestionReplied,
  makeAssistantMessage,
  makeTextPart,
  makeToolPart,
  makeUserMessage,
  messagePartUpdated,
  messageUpdated,
  permissionRepliedV1,
  permissionUpdated,
  sessionCreated,
  sessionError,
  sessionIdle,
  sessionStatus,
  sessionUpdated,
} from "./helpers.js";

describe("normalizeEvent — session lifecycle", () => {
  it("maps session.created to a session upsert with parent and title", () => {
    expect(sessionCreated({ parentID: "ses_parent9" })).toBeDefined();
    expect(normalizeEvent(sessionCreated({ parentID: "ses_parent9" }))).toEqual({
      kind: "session.upsert",
      sessionID: "ses_abc123",
      parentID: "ses_parent9",
      title: "Fix login redirect",
    });
  });

  it("maps session.updated to a session upsert and reflects title changes", () => {
    expect(normalizeEvent(sessionUpdated({ title: "Renamed session" }))).toEqual({
      kind: "session.upsert",
      sessionID: "ses_abc123",
      title: "Renamed session",
    });
  });

  it("omits parentID for root sessions", () => {
    const result = normalizeEvent(sessionCreated());
    expect(result).toEqual({
      kind: "session.upsert",
      sessionID: "ses_abc123",
      title: "Fix login redirect",
    });
    expect(result).not.toHaveProperty("parentID");
  });

  it("defensively reads a session carried directly on properties (no info wrapper)", () => {
    const devShape = {
      type: "session.updated",
      properties: { id: "ses_dev1", title: "Dev session", parentID: "ses_root" },
    };
    expect(normalizeEvent(devShape)).toEqual({
      kind: "session.upsert",
      sessionID: "ses_dev1",
      parentID: "ses_root",
      title: "Dev session",
    });
  });

  it("ignores session.created without a usable session id", () => {
    expect(normalizeEvent({ type: "session.created", properties: { info: {} } })).toBeNull();
    expect(
      normalizeEvent({ type: "session.created", properties: { info: { id: 42 } } }),
    ).toBeNull();
  });
});

describe("normalizeEvent — session status", () => {
  it("maps busy status", () => {
    expect(normalizeEvent(sessionStatus({ type: "busy" }))).toEqual({
      kind: "session.status",
      sessionID: "ses_abc123",
      status: "busy",
    });
  });

  it("maps retry status with the retry action fields", () => {
    expect(
      normalizeEvent(
        sessionStatus({ type: "retry", attempt: 2, message: "rate limited", next: 1_700_000_009_000 }),
      ),
    ).toEqual({
      kind: "session.status",
      sessionID: "ses_abc123",
      status: "retry",
      retry: { attempt: 2, message: "rate limited", next: 1_700_000_009_000 },
    });
  });

  it("maps a retry carrying a dev-source provider action, including link and reason", () => {
    expect(
      normalizeEvent({
        type: "session.status",
        properties: {
          sessionID: "ses_abc123",
          status: {
            type: "retry",
            attempt: 2,
            message: "rate limited",
            next: 1_700_000_009_000,
            action: {
              reason: "oauth_expired",
              provider: "anthropic",
              title: "Re-authenticate",
              message: "OAuth token expired",
              label: "Open login",
              link: "https://example.com/login",
            },
          },
        },
      }),
    ).toEqual({
      kind: "session.status",
      sessionID: "ses_abc123",
      status: "retry",
      retry: {
        attempt: 2,
        message: "rate limited",
        next: 1_700_000_009_000,
        action: {
          reason: "oauth_expired",
          provider: "anthropic",
          title: "Re-authenticate",
          message: "OAuth token expired",
          label: "Open login",
          link: "https://example.com/login",
        },
      },
    });
  });

  it("keeps the retry action without optional reason/link when absent", () => {
    const result = normalizeEvent({
      type: "session.status",
      properties: {
        sessionID: "ses_abc123",
        status: {
          type: "retry",
          attempt: 1,
          message: "m",
          next: 2,
          action: {
            provider: "anthropic",
            title: "Re-authenticate",
            message: "OAuth token expired",
            label: "Open login",
          },
        },
      },
    });
    expect(result).toEqual({
      kind: "session.status",
      sessionID: "ses_abc123",
      status: "retry",
      retry: {
        attempt: 1,
        message: "m",
        next: 2,
        action: {
          provider: "anthropic",
          title: "Re-authenticate",
          message: "OAuth token expired",
          label: "Open login",
        },
      },
    });
    expect((result as { retry: { action: object } }).retry.action).not.toHaveProperty("reason");
    expect((result as { retry: { action: object } }).retry.action).not.toHaveProperty("link");
  });

  it("ignores a retry action missing a required field or carrying non-strings, keeping the retry", () => {
    const base = {
      type: "session.status",
      properties: {
        sessionID: "ses_abc123",
        status: { type: "retry", attempt: 1, message: "m", next: 2 },
      },
    };
    const withAction = (action: unknown) => ({
      ...base,
      properties: {
        ...base.properties,
        status: { ...base.properties.status, action },
      },
    });
    const expectedPlainRetry = {
      kind: "session.status",
      sessionID: "ses_abc123",
      status: "retry",
      retry: { attempt: 1, message: "m", next: 2 },
    };
    const valid = {
      provider: "anthropic",
      title: "Re-authenticate",
      message: "OAuth token expired",
      label: "Open login",
    };
    // Non-record actions degrade to no action.
    expect(normalizeEvent(withAction("re-auth"))).toEqual(expectedPlainRetry);
    expect(normalizeEvent(withAction(null))).toEqual(expectedPlainRetry);
    expect(normalizeEvent(withAction([]))).toEqual(expectedPlainRetry);
    // Missing or empty required fields: the whole action is ignored.
    const { label: _label, ...noLabel } = valid;
    expect(normalizeEvent(withAction(noLabel))).toEqual(expectedPlainRetry);
    expect(normalizeEvent(withAction({ ...valid, provider: "" }))).toEqual(expectedPlainRetry);
    expect(normalizeEvent(withAction({ ...valid, title: 42 }))).toEqual(expectedPlainRetry);
    expect(normalizeEvent(withAction({ ...valid, message: undefined }))).toEqual(expectedPlainRetry);
    // Non-string optional fields are dropped, not fatal.
    expect(normalizeEvent(withAction({ ...valid, reason: 7, link: {} }))).toEqual({
      ...expectedPlainRetry,
      retry: { ...expectedPlainRetry.retry, action: valid },
    });
  });

  it("maps idle status", () => {
    expect(normalizeEvent(sessionStatus({ type: "idle" }))).toEqual({
      kind: "session.status",
      sessionID: "ses_abc123",
      status: "idle",
    });
  });

  it("maps the deprecated session.idle marker to an idle status", () => {
    expect(normalizeEvent(sessionIdle())).toEqual({
      kind: "session.status",
      sessionID: "ses_abc123",
      status: "idle",
    });
  });

  it("ignores unknown or malformed status payloads", () => {
    expect(
      normalizeEvent({ type: "session.status", properties: { sessionID: "s", status: { type: "waiting" } } }),
    ).toBeNull();
    expect(
      normalizeEvent({ type: "session.status", properties: { sessionID: "s" } }),
    ).toBeNull();
    expect(
      normalizeEvent(
        sessionStatus({ type: "retry", attempt: Number.NaN, message: "m", next: 1 } as never),
      ),
    ).toBeNull();
  });
});

describe("normalizeEvent — errors", () => {
  it("maps session.error MessageAbortedError to stopped", () => {
    expect(
      normalizeEvent(sessionError({ name: "MessageAbortedError", data: { message: "aborted" } })),
    ).toEqual({ kind: "session.error", sessionID: "ses_abc123", outcome: "stopped" });
  });

  it("maps session.error AbortError (dev-source name) to stopped", () => {
    expect(
      normalizeEvent(sessionError({ name: "AbortError", data: { message: "aborted" } })),
    ).toEqual({ kind: "session.error", sessionID: "ses_abc123", outcome: "stopped" });
  });

  it("maps non-abort session errors to failed", () => {
    expect(
      normalizeEvent(
        sessionError({
          name: "APIError",
          data: { message: "provider 500", statusCode: 500, isRetryable: true },
        }),
      ),
    ).toEqual({ kind: "session.error", sessionID: "ses_abc123", outcome: "failed" });
    expect(
      normalizeEvent(sessionError({ name: "ProviderAuthError", data: { providerID: "p", message: "m" } })),
    ).toEqual({ kind: "session.error", sessionID: "ses_abc123", outcome: "failed" });
  });

  it("maps session.error without an error payload to failed", () => {
    expect(normalizeEvent(sessionError())).toEqual({
      kind: "session.error",
      sessionID: "ses_abc123",
      outcome: "failed",
    });
  });

  it("keeps a missing sessionID absent on session.error", () => {
    const result = normalizeEvent(sessionError(undefined, null));
    expect(result).toEqual({ kind: "session.error", outcome: "failed" });
    expect(result).not.toHaveProperty("sessionID");
  });

  it("does not leak error message text into the normalized event", () => {
    const result = normalizeEvent(
      sessionError({ name: "UnknownError", data: { message: "token sk-live-SECRET-789 rejected" } }),
    );
    expect(JSON.stringify(result)).not.toContain("sk-live-SECRET-789");
  });
});

describe("normalizeEvent — messages", () => {
  it("maps a user message with its role", () => {
    expect(normalizeEvent(messageUpdated(makeUserMessage()))).toEqual({
      kind: "message",
      sessionID: "ses_abc123",
      messageID: "msg_user1",
      role: "user",
    });
  });

  it("maps an assistant message with its role and no outcome when healthy", () => {
    const result = normalizeEvent(messageUpdated(makeAssistantMessage()));
    expect(result).toEqual({
      kind: "message",
      sessionID: "ses_abc123",
      messageID: "msg_asst1",
      role: "assistant",
    });
    expect(result).not.toHaveProperty("outcome");
  });

  it("maps an assistant MessageAbortedError to stopped", () => {
    expect(
      normalizeEvent(
        messageUpdated(
          makeAssistantMessage({
            error: { name: "MessageAbortedError", data: { message: "aborted" } },
          }),
        ),
      ),
    ).toEqual({
      kind: "message",
      sessionID: "ses_abc123",
      messageID: "msg_asst1",
      role: "assistant",
      outcome: "stopped",
    });
  });

  it("maps an assistant AbortError to stopped and other errors to failed", () => {
    expect(
      normalizeEvent(
        messageUpdated(
          makeAssistantMessage({ error: { name: "AbortError", data: { message: "x" } } as never }),
        ),
      ),
    ).toMatchObject({ outcome: "stopped" });
    expect(
      normalizeEvent(
        messageUpdated(
          makeAssistantMessage({
            error: { name: "APIError", data: { message: "boom", isRetryable: false } },
          }),
        ),
      ),
    ).toMatchObject({ outcome: "failed" });
  });

  it("ignores messages with an unknown role or missing ids", () => {
    expect(
      normalizeEvent(messageUpdated(makeUserMessage({ role: "system" as never }))),
    ).toBeNull();
    expect(
      normalizeEvent({ type: "message.updated", properties: { info: { role: "user" } } }),
    ).toBeNull();
  });
});

describe("normalizeEvent — message parts", () => {
  it("maps text parts to a summary-cache text event", () => {
    expect(normalizeEvent(messagePartUpdated(makeTextPart()))).toEqual({
      kind: "message.text",
      sessionID: "ses_abc123",
      messageID: "msg_asst1",
      partID: "prt_text1",
      text: "I found the redirect bug in the auth middleware.",
    });
  });

  it("ignores non-text parts", () => {
    expect(normalizeEvent(messagePartUpdated(makeToolPart()))).toBeNull();
    expect(
      normalizeEvent(
        messagePartUpdated({
          id: "prt_r1",
          sessionID: "ses_abc123",
          messageID: "msg_asst1",
          type: "reasoning",
          text: "thinking",
          time: { start: 1 },
        }),
      ),
    ).toBeNull();
  });

  it("ignores malformed text parts", () => {
    expect(normalizeEvent(messagePartUpdated(makeTextPart({ text: 42 as never })))).toBeNull();
    expect(
      normalizeEvent({ type: "message.part.updated", properties: { part: { type: "text", text: "x" } } }),
    ).toBeNull();
  });
});

describe("normalizeEvent — questions (dev-source shapes)", () => {
  it("maps question.asked preserving all questions as an array with label-only options", () => {
    expect(normalizeEvent(devQuestionAsked())).toEqual({
      kind: "question.asked",
      sessionID: "ses_abc123",
      requestID: "qst_req1",
      questions: [
        {
          question: "Which database should the migration target?",
          options: [{ label: "PostgreSQL" }, { label: "SQLite" }],
          multiple: false,
        },
        {
          question: "Backfill existing rows?",
          options: [{ label: "Yes" }, { label: "No" }],
        },
      ],
    });
  });

  it("preserves multiple only when true and drops malformed options", () => {
    const event = devQuestionAsked({
      id: "qst_req2",
      questions: [
        {
          question: "Pick one",
          options: [{ label: "A" }, { description: "no label" }, "garbage", { label: "B" }],
          multiple: true,
        },
      ],
    });
    expect(normalizeEvent(event)).toEqual({
      kind: "question.asked",
      sessionID: "ses_abc123",
      requestID: "qst_req2",
      questions: [{ question: "Pick one", options: [{ label: "A" }, { label: "B" }], multiple: true }],
    });
  });

  it("maps question.replied and question.rejected to question.resolved", () => {
    expect(normalizeEvent(devQuestionReplied())).toEqual({
      kind: "question.resolved",
      sessionID: "ses_abc123",
      requestID: "qst_req1",
    });
    expect(normalizeEvent(devQuestionRejected())).toEqual({
      kind: "question.resolved",
      sessionID: "ses_abc123",
      requestID: "qst_req1",
    });
  });

  it("ignores question.asked without any usable question", () => {
    expect(normalizeEvent(devQuestionAsked({ questions: [{ header: "x" }] }))).toBeNull();
    expect(normalizeEvent(devQuestionAsked({ questions: "nope" }))).toBeNull();
    expect(normalizeEvent(devQuestionAsked({ id: 7 }))).toBeNull();
  });
});

describe("normalizeEvent — permissions", () => {
  it("maps dev-source permission.asked to type plus a pattern summary", () => {
    expect(normalizeEvent(devPermissionAsked())).toEqual({
      kind: "permission.asked",
      sessionID: "ses_abc123",
      requestID: "per_req2",
      permission: "edit",
      summary: "edit: src/auth.ts, src/config.ts",
    });
  });

  it("maps SDK 1.18.15 permission.updated with an array pattern", () => {
    expect(normalizeEvent(permissionUpdated())).toEqual({
      kind: "permission.asked",
      sessionID: "ses_abc123",
      requestID: "per_req1",
      permission: "bash",
      summary: "bash: pnpm test, git status",
    });
  });

  it("maps SDK 1.18.15 permission.updated with a single string pattern", () => {
    expect(normalizeEvent(permissionUpdated({ pattern: "src/index.ts", type: "edit" }))).toEqual({
      kind: "permission.asked",
      sessionID: "ses_abc123",
      requestID: "per_req1",
      permission: "edit",
      summary: "edit: src/index.ts",
    });
  });

  it("falls back to the bare permission type when there are no patterns", () => {
    expect(normalizeEvent(permissionUpdated({ pattern: undefined, type: "webfetch" }))).toEqual({
      kind: "permission.asked",
      sessionID: "ses_abc123",
      requestID: "per_req1",
      permission: "webfetch",
      summary: "webfetch",
    });
  });

  it("never exposes permission metadata or title values", () => {
    const v1 = normalizeEvent(permissionUpdated());
    const dev = normalizeEvent(devPermissionAsked());
    for (const result of [v1, dev]) {
      const serialized = JSON.stringify(result);
      expect(serialized).not.toContain("sk-live-SECRET-123");
      expect(serialized).not.toContain("sk-live-SECRET-456");
      expect(serialized).not.toContain("SECRET-PATCH-456");
      expect(serialized).not.toContain("metadata");
      expect(serialized).not.toContain("title");
    }
  });

  it("sanitizes control characters out of patterns", () => {
    const result = normalizeEvent(
      devPermissionAsked({ patterns: ["rm -rf /tmp/x\n--token=abc\tDEF\r\n"] }),
    );
    expect(result).toMatchObject({ permission: "edit" });
    const summary = (result as { summary: string }).summary;
    expect(summary).toBe("edit: rm -rf /tmp/x --token=abc DEF");
    expect(summary).not.toMatch(/[\n\r\t]/);
  });

  it("caps the permission summary length", () => {
    const longPattern = `/src/${"very-long-path-segment/".repeat(40)}file.ts`;
    const result = normalizeEvent(devPermissionAsked({ patterns: [longPattern, longPattern] }));
    const summary = (result as { summary: string }).summary;
    expect(summary.length).toBeLessThanOrEqual(200);
    expect(summary.endsWith("…")).toBe(true);
    expect(summary.startsWith("edit: ")).toBe(true);
  });

  it("maps dev-source permission.replied to permission.resolved", () => {
    expect(normalizeEvent(devPermissionReplied())).toEqual({
      kind: "permission.resolved",
      sessionID: "ses_abc123",
      requestID: "per_req2",
    });
  });

  it("maps SDK 1.18.15 permission.replied (permissionID) to permission.resolved", () => {
    expect(normalizeEvent(permissionRepliedV1())).toEqual({
      kind: "permission.resolved",
      sessionID: "ses_abc123",
      requestID: "per_req1",
    });
  });

  it("ignores permission events without a request id", () => {
    expect(normalizeEvent(devPermissionAsked({ id: undefined }))).toBeNull();
    expect(
      normalizeEvent({ type: "permission.replied", properties: { sessionID: "s" } }),
    ).toBeNull();
  });
});

describe("normalizeEvent — ignored and malformed input", () => {
  it("ignores unrelated SDK events", () => {
    const unrelated = [
      { type: "todo.updated", properties: { sessionID: "s", todos: [] } },
      { type: "file.edited", properties: { file: "a.ts" } },
      {
        type: "pty.created",
        properties: {
          info: { id: "pty_1", title: "t", command: "bash", args: [], cwd: "/", status: "running", pid: 1 },
        },
      },
      { type: "server.connected", properties: {} },
      { type: "session.deleted", properties: { info: { id: "s", title: "t" } } },
      { type: "session.compacted", properties: { sessionID: "s" } },
      { type: "message.removed", properties: { sessionID: "s", messageID: "m" } },
      { type: "message.part.removed", properties: { sessionID: "s", messageID: "m", partID: "p" } },
      { type: "session.next.prompted", properties: { sessionID: "s" } },
    ];
    for (const event of unrelated) {
      expect(normalizeEvent(event)).toBeNull();
    }
  });

  it("ignores garbage input without throwing", () => {
    const garbage = [
      null,
      undefined,
      true,
      42,
      "session.idle",
      [],
      {},
      { type: null },
      { type: 42 },
      { type: "session.created" },
      { type: "session.created", properties: null },
      { type: "session.created", properties: "info" },
      { type: "session.status", properties: { sessionID: "s", status: "busy" } },
      { type: "question.asked", properties: null },
    ];
    for (const event of garbage) {
      expect(() => normalizeEvent(event)).not.toThrow();
      expect(normalizeEvent(event)).toBeNull();
    }
  });

  it("never throws, even on hostile objects", () => {
    const hostile = Object.create(null) as Record<string, unknown>;
    Object.defineProperty(hostile, "type", {
      get() {
        throw new Error("hostile getter");
      },
    });
    expect(() => normalizeEvent(hostile)).not.toThrow();
    expect(normalizeEvent(hostile)).toBeNull();

    const selfReferential: Record<string, unknown> = { type: "session.created" };
    selfReferential.properties = selfReferential;
    expect(() => normalizeEvent(selfReferential)).not.toThrow();
    expect(normalizeEvent(selfReferential)).toBeNull();
  });
});
