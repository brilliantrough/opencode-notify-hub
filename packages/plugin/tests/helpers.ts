import type {
  AssistantMessage,
  Event,
  Message,
  Part,
  Permission,
  Session,
  SessionStatus,
  TextPart,
  ToolPart,
  UserMessage,
} from "@opencode-ai/sdk";

/**
 * Factories for upstream-shaped OpenCode events.
 *
 * Two families live here on purpose:
 *
 * 1. `make*` / v1 factories return values typed against the
 *    `@opencode-ai/sdk@1.18.15` `Event` union (via `satisfies`), so the
 *    compiler pins the fixtures to the installed SDK shapes. If a future
 *    SDK upgrade changes a shape, these factories fail to compile.
 *
 * 2. `dev*` factories build the shapes emitted by newer OpenCode dev
 *    sources that SDK 1.18.15 does not type yet (`question.*`,
 *    `permission.asked`, `permission.replied` with `requestID`/`reply`).
 *    They are returned as `unknown` exactly the way a runtime event of an
 *    unrecognized type would arrive.
 */

export function makeSession(overrides: Partial<Session> = {}): Session {
  return {
    id: "ses_abc123",
    projectID: "prj_1",
    directory: "/home/dev/project",
    title: "Fix login redirect",
    version: "1.18.15",
    time: { created: 1_700_000_000_000, updated: 1_700_000_000_500 },
    ...overrides,
  };
}

export function sessionCreated(overrides: Partial<Session> = {}): Event {
  return {
    type: "session.created",
    properties: { info: makeSession(overrides) },
  } satisfies Event;
}

export function sessionUpdated(overrides: Partial<Session> = {}): Event {
  return {
    type: "session.updated",
    properties: { info: makeSession(overrides) },
  } satisfies Event;
}

export function sessionStatus(status: SessionStatus, sessionID = "ses_abc123"): Event {
  return {
    type: "session.status",
    properties: { sessionID, status },
  } satisfies Event;
}

/** Deprecated idle marker, still emitted by supported OpenCode versions. */
export function sessionIdle(sessionID = "ses_abc123"): Event {
  return {
    type: "session.idle",
    properties: { sessionID },
  } satisfies Event;
}

export function sessionError(
  error?: { name: string; data: Record<string, unknown> },
  sessionID: string | null = "ses_abc123",
): Event {
  const properties: Record<string, unknown> = { error: error as never };
  if (sessionID !== null) {
    properties.sessionID = sessionID;
  }
  return {
    type: "session.error",
    properties: properties as never,
  } satisfies Event;
}

export function makeUserMessage(overrides: Partial<UserMessage> = {}): UserMessage {
  return {
    id: "msg_user1",
    sessionID: "ses_abc123",
    role: "user",
    time: { created: 1_700_000_001_000 },
    agent: "build",
    model: { providerID: "anthropic", modelID: "claude-sonnet-4" },
    ...overrides,
  };
}

export function makeAssistantMessage(
  overrides: Partial<AssistantMessage> = {},
): AssistantMessage {
  return {
    id: "msg_asst1",
    sessionID: "ses_abc123",
    role: "assistant",
    time: { created: 1_700_000_002_000, completed: 1_700_000_003_000 },
    parentID: "msg_user1",
    modelID: "claude-sonnet-4",
    providerID: "anthropic",
    mode: "build",
    path: { cwd: "/home/dev/project", root: "/home/dev/project" },
    cost: 0.012,
    tokens: {
      input: 1200,
      output: 340,
      reasoning: 0,
      cache: { read: 0, write: 0 },
    },
    ...overrides,
  };
}

export function messageUpdated(info: Message): Event {
  return {
    type: "message.updated",
    properties: { info },
  } satisfies Event;
}

export function makeTextPart(overrides: Partial<TextPart> = {}): TextPart {
  return {
    id: "prt_text1",
    sessionID: "ses_abc123",
    messageID: "msg_asst1",
    type: "text",
    text: "I found the redirect bug in the auth middleware.",
    ...overrides,
  };
}

export function makeToolPart(overrides: Partial<ToolPart> = {}): ToolPart {
  return {
    id: "prt_tool1",
    sessionID: "ses_abc123",
    messageID: "msg_asst1",
    type: "tool",
    callID: "call_1",
    tool: "bash",
    state: {
      status: "completed",
      input: { command: "pnpm test" },
      output: "ok",
      title: "Run tests",
      metadata: {},
      time: { start: 1_700_000_002_100, end: 1_700_000_002_900 },
    },
    ...overrides,
  };
}

export function messagePartUpdated(part: Part): Event {
  return {
    type: "message.part.updated",
    properties: { part },
  } satisfies Event;
}

/**
 * SDK 1.18.15 permission request event (`permission.updated`, the v1 name
 * for what dev sources call `permission.asked`). The default metadata and
 * title deliberately carry secret-looking values so tests can assert they
 * never reach the normalized output.
 */
export function permissionUpdated(overrides: Partial<Permission> = {}): Event {
  return {
    type: "permission.updated",
    properties: {
      id: "per_req1",
      type: "bash",
      pattern: ["pnpm test", "git status"],
      sessionID: "ses_abc123",
      messageID: "msg_asst1",
      callID: "call_1",
      title: "bash: pnpm test --token=sk-live-SECRET-123",
      metadata: { command: "pnpm test --token=sk-live-SECRET-123", apiKey: "sk-live-SECRET-123" },
      time: { created: 1_700_000_004_000 },
      ...overrides,
    },
  } satisfies Event;
}

/** SDK 1.18.15 permission reply (`permissionID` + free-form `response`). */
export function permissionRepliedV1(
  sessionID = "ses_abc123",
  permissionID = "per_req1",
  response = "once",
): Event {
  return {
    type: "permission.replied",
    properties: { sessionID, permissionID, response },
  } satisfies Event;
}

/** Dev-source `permission.asked` (not in the SDK 1.18.15 v1 union). */
export function devPermissionAsked(
  overrides: Record<string, unknown> = {},
): unknown {
  return {
    id: "evt_1",
    type: "permission.asked",
    properties: {
      id: "per_req2",
      sessionID: "ses_abc123",
      permission: "edit",
      patterns: ["src/auth.ts", "src/config.ts"],
      metadata: { diff: "-----SECRET-PATCH-456-----", token: "sk-live-SECRET-456" },
      always: ["src/*"],
      tool: { messageID: "msg_asst1", callID: "call_2" },
      ...overrides,
    },
  };
}

/** Dev-source `permission.replied` (`requestID` + typed `reply`). */
export function devPermissionReplied(
  sessionID = "ses_abc123",
  requestID = "per_req2",
  reply: "once" | "always" | "reject" = "always",
): unknown {
  return {
    id: "evt_2",
    type: "permission.replied",
    properties: { sessionID, requestID, reply },
  };
}

/** Dev-source `question.asked` with the upstream `QuestionInfo` shape. */
export function devQuestionAsked(overrides: Record<string, unknown> = {}): unknown {
  return {
    id: "evt_3",
    type: "question.asked",
    properties: {
      id: "qst_req1",
      sessionID: "ses_abc123",
      questions: [
        {
          question: "Which database should the migration target?",
          header: "Database",
          options: [
            { label: "PostgreSQL", description: "Production parity" },
            { label: "SQLite", description: "Fast local runs" },
          ],
          multiple: false,
          custom: true,
        },
        {
          question: "Backfill existing rows?",
          header: "Backfill",
          options: [
            { label: "Yes", description: "Backfill in the same migration" },
            { label: "No", description: "Defer to a follow-up job" },
          ],
        },
      ],
      tool: { messageID: "msg_asst1", callID: "call_3" },
      ...overrides,
    },
  };
}

/** Dev-source `question.replied`. */
export function devQuestionReplied(
  sessionID = "ses_abc123",
  requestID = "qst_req1",
): unknown {
  return {
    id: "evt_4",
    type: "question.replied",
    properties: { sessionID, requestID, answers: [["PostgreSQL"], ["No"]] },
  };
}

/** Dev-source `question.rejected`. */
export function devQuestionRejected(
  sessionID = "ses_abc123",
  requestID = "qst_req1",
): unknown {
  return {
    id: "evt_5",
    type: "question.rejected",
    properties: { sessionID, requestID },
  };
}
