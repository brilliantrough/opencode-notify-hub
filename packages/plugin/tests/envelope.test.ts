import { describe, expect, it } from "vitest";
import { validateNotifyEvent } from "@notify/contracts";

import { EnvelopeFactory } from "../src/envelope.js";
import type { EnvelopeSession } from "../src/envelope.js";
import { MessageCache } from "../src/message-cache.js";
import { notifyEventPriority } from "../src/queue.js";
import type {
  SessionActionRequired,
  SessionHeartbeat,
  SessionTerminal,
} from "../src/state-machine.js";

/**
 * Every event built here is validated against the shared gateway contract
 * (`validateNotifyEvent` from `@notify/contracts`) in addition to literal
 * assertions, so a contract drift fails this suite, not production.
 *
 * Time and UUIDs are injected: `now` is frozen at 1_700_000_000_000
 * ("2023-11-14T22:13:20.000Z") and UUIDs come from a deterministic counter,
 * so every expected value below is a hand-computed literal.
 */

const NOW_MS = 1_700_000_000_000;
const NOW_ISO = "2023-11-14T22:13:20.000Z";

const SOURCE = { machine: "devbox", project: "opencode-notify", directory: "/home/dev/project" };

const SESSION: EnvelopeSession = { id: "ses_abc123", title: "Fix login redirect" };

/** Deterministic UUID sequence, valid per the contract's uuid format. */
function uuidSequence(): () => string {
  let next = 0;
  return () => {
    next += 1;
    return `00000000-0000-4000-8000-${String(next).padStart(12, "0")}`;
  };
}

function makeFactory(overrides: {
  includeSummary?: boolean;
  source?: { machine: string; project: string; directory: string };
} = {}): EnvelopeFactory {
  return new EnvelopeFactory({
    source: overrides.source ?? SOURCE,
    includeSummary: overrides.includeSummary ?? false,
    now: () => NOW_MS,
    randomUUID: uuidSequence(),
  });
}

function heartbeatEffect(elapsedMs: number, status: "busy" | "retry" = "busy"): SessionHeartbeat {
  return { sessionID: SESSION.id, status, elapsedMs };
}

function terminalEffect(elapsedMs: number): SessionTerminal {
  return { sessionID: SESSION.id, elapsedMs };
}

describe("envelope base", () => {
  it("builds a contract-valid heartbeat envelope with the exact base fields", () => {
    const event = makeFactory().heartbeat(SESSION, heartbeatEffect(61_000));
    expect(event).toEqual({
      eventId: "00000000-0000-4000-8000-000000000001",
      type: "heartbeat",
      occurredAt: NOW_ISO,
      source: SOURCE,
      session: { id: "ses_abc123", title: "Fix login redirect" },
      payload: { status: "busy", elapsedSeconds: 61 },
    });
    expect(validateNotifyEvent(event)).toBe(true);
  });

  it("falls back to the session id when the title is empty or missing", () => {
    const factory = makeFactory();
    const untitled = factory.heartbeat({ id: "ses_x", title: "" }, { sessionID: "ses_x", status: "busy", elapsedMs: 0 });
    expect(untitled.session).toEqual({ id: "ses_x", title: "ses_x" });
    const missing = factory.heartbeat({ id: "ses_y" }, { sessionID: "ses_y", status: "busy", elapsedMs: 0 });
    expect(missing.session).toEqual({ id: "ses_y", title: "ses_y" });
    expect(validateNotifyEvent(untitled)).toBe(true);
    expect(validateNotifyEvent(missing)).toBe(true);
  });

  it("assigns a unique UUID eventId to every event", () => {
    const factory = makeFactory();
    const ids = new Set([
      factory.heartbeat(SESSION, heartbeatEffect(0)).eventId,
      factory.heartbeat(SESSION, heartbeatEffect(0)).eventId,
      factory.terminal(SESSION, terminalEffect(0), "completed").eventId,
    ]);
    expect(ids.size).toBe(3);
  });

  it("converts elapsed with floor(max(0, ms) / 1000), never rounding up", () => {
    const factory = makeFactory();
    const cases: Array<[number, number]> = [
      [61_000, 61],
      [1_500, 1],
      [999, 0],
      [0, 0],
      [-5_000, 0],
    ];
    for (const [elapsedMs, expectedSeconds] of cases) {
      const event = factory.heartbeat(SESSION, heartbeatEffect(elapsedMs));
      expect(event.payload).toEqual({ status: "busy", elapsedSeconds: expectedSeconds });
      expect(validateNotifyEvent(event)).toBe(true);
    }
  });

  it("carries the heartbeat status through unchanged", () => {
    const event = makeFactory().heartbeat(SESSION, heartbeatEffect(2_000, "retry"));
    expect(event.payload).toEqual({ status: "retry", elapsedSeconds: 2 });
    expect(validateNotifyEvent(event)).toBe(true);
  });

  it("maps each variant to its contract priority via notifyEventPriority", () => {
    const factory = makeFactory();
    expect(notifyEventPriority(factory.heartbeat(SESSION, heartbeatEffect(0)))).toBe(0);
    expect(
      notifyEventPriority(
        factory.actionResolved(SESSION, {
          sessionID: SESSION.id,
          requestId: "qst_req1",
          kind: "question",
        }),
      ),
    ).toBe(1);
    expect(
      notifyEventPriority(
        factory.actionRequired(SESSION, {
          sessionID: SESSION.id,
          requestId: "per_req1",
          kind: "permission",
          permission: { permission: "bash", summary: "bash: pnpm test" },
        }),
      ),
    ).toBe(2);
    expect(notifyEventPriority(factory.terminal(SESSION, terminalEffect(0), "completed"))).toBe(2);
  });

  it("throws instead of emitting when the built event violates the contract", () => {
    const factory = makeFactory({ source: { machine: "", project: "p", directory: "/d" } });
    expect(() => factory.heartbeat(SESSION, heartbeatEffect(0))).toThrow();
  });
});

describe("terminal events", () => {
  it("builds completed, failed, and stopped payloads with the emitted outcome", () => {
    const factory = makeFactory();
    for (const outcome of ["completed", "failed", "stopped"] as const) {
      const event = factory.terminal(SESSION, terminalEffect(3_999), outcome);
      expect(event.type).toBe("terminal");
      expect(event.payload).toEqual({ outcome, elapsedSeconds: 3 });
      expect(validateNotifyEvent(event)).toBe(true);
    }
  });

  it("omits the summary by default even when one is provided", () => {
    const event = makeFactory().terminal(SESSION, terminalEffect(0), "completed", "assistant reply");
    expect(event.payload).toEqual({ outcome: "completed", elapsedSeconds: 0 });
    expect("summary" in event.payload).toBe(false);
    expect(validateNotifyEvent(event)).toBe(true);
  });

  it("includes the summary when includeSummary is enabled and the text is nonempty", () => {
    const factory = makeFactory({ includeSummary: true });
    const event = factory.terminal(SESSION, terminalEffect(0), "completed", "assistant reply");
    expect(event.payload).toEqual({
      outcome: "completed",
      elapsedSeconds: 0,
      summary: "assistant reply",
    });
    expect(validateNotifyEvent(event)).toBe(true);
  });

  it("omits the summary when enabled but the text is empty or absent", () => {
    const factory = makeFactory({ includeSummary: true });
    const empty = factory.terminal(SESSION, terminalEffect(0), "completed", "");
    expect("summary" in empty.payload).toBe(false);
    const absent = factory.terminal(SESSION, terminalEffect(0), "failed");
    expect("summary" in absent.payload).toBe(false);
    expect(validateNotifyEvent(empty)).toBe(true);
    expect(validateNotifyEvent(absent)).toBe(true);
  });

  it("bounds the summary to 500 code points, surrogate-safe", () => {
    const factory = makeFactory({ includeSummary: true });
    const longSummary = factory.terminal(
      SESSION,
      terminalEffect(0),
      "completed",
      "s".repeat(600),
    );
    expect(longSummary.payload).toEqual({
      outcome: "completed",
      elapsedSeconds: 0,
      summary: `${"s".repeat(499)}…`,
    });
    // 498 BMP + one astral char + tail = 504 code points: truncation must
    // keep the astral char whole (a UTF-16 slice would orphan a surrogate).
    const astral = factory.terminal(
      SESSION,
      terminalEffect(0),
      "completed",
      `${"s".repeat(498)}\u{1F4A5}tail!`,
    );
    expect(astral.payload).toEqual({
      outcome: "completed",
      elapsedSeconds: 0,
      summary: `${"s".repeat(498)}\u{1F4A5}…`,
    });
    expect(validateNotifyEvent(longSummary)).toBe(true);
    expect(validateNotifyEvent(astral)).toBe(true);
  });

  it("carries an assistant-only cache summary into the event when enabled", () => {
    const cache = new MessageCache();
    cache.onRole("ses_abc123", "msg_user1", "user");
    cache.onText("ses_abc123", "msg_user1", "sk-live-SECRET user prompt");
    cache.onRole("ses_abc123", "msg_asst1", "assistant");
    cache.onText("ses_abc123", "msg_asst1", "Fixed the redirect bug.");
    const factory = makeFactory({ includeSummary: true });
    const event = factory.terminal(
      SESSION,
      terminalEffect(0),
      "completed",
      cache.summary("ses_abc123"),
    );
    expect(event.payload).toEqual({
      outcome: "completed",
      elapsedSeconds: 0,
      summary: "Fixed the redirect bug.",
    });
    expect(JSON.stringify(event)).not.toContain("SECRET");
    expect(validateNotifyEvent(event)).toBe(true);
  });
});

describe("action_required events", () => {
  it("maps a question request to the external lower-camel shape", () => {
    const action: SessionActionRequired = {
      sessionID: SESSION.id,
      requestId: "qst_req1",
      kind: "question",
      questions: [
        {
          question: "Which database?",
          options: [{ label: "PostgreSQL" }, { label: "SQLite" }],
          multiple: false,
        },
      ],
    };
    const event = makeFactory().actionRequired(SESSION, action);
    expect(event).toEqual({
      eventId: "00000000-0000-4000-8000-000000000001",
      type: "action_required",
      occurredAt: NOW_ISO,
      source: SOURCE,
      session: { id: "ses_abc123", title: "Fix login redirect" },
      payload: {
        requestId: "qst_req1",
        kind: "question",
        questions: [
          {
            question: "Which database?",
            options: [{ label: "PostgreSQL" }, { label: "SQLite" }],
            multiple: false,
          },
        ],
      },
    });
    expect(validateNotifyEvent(event)).toBe(true);
  });

  it("omits the options and multiple keys when they carry nothing", () => {
    const event = makeFactory().actionRequired(SESSION, {
      sessionID: SESSION.id,
      requestId: "qst_req2",
      kind: "question",
      questions: [{ question: "Free-form answer?", options: [] }],
    });
    expect(event.payload).toEqual({
      requestId: "qst_req2",
      kind: "question",
      questions: [{ question: "Free-form answer?" }],
    });
    expect(validateNotifyEvent(event)).toBe(true);
  });

  it("keeps only the first 8 questions and bounds text to 2000 code points", () => {
    const questions = Array.from({ length: 10 }, (_, i) => ({
      question: `Question number ${i}`,
      options: [],
    }));
    questions[9] = { question: "q".repeat(2_100), options: [] };
    const event = makeFactory().actionRequired(SESSION, {
      sessionID: SESSION.id,
      requestId: "qst_req3",
      kind: "question",
      questions,
    });
    expect(event.payload).toEqual({
      requestId: "qst_req3",
      kind: "question",
      questions: Array.from({ length: 8 }, (_, i) => ({
        question: `Question number ${i}`,
      })),
    });
    const bounded = makeFactory().actionRequired(SESSION, {
      sessionID: SESSION.id,
      requestId: "qst_req4",
      kind: "question",
      questions: [{ question: "q".repeat(2_100), options: [] }],
    });
    expect(bounded.payload).toEqual({
      requestId: "qst_req4",
      kind: "question",
      questions: [{ question: `${"q".repeat(1_999)}…` }],
    });
    expect(validateNotifyEvent(event)).toBe(true);
    expect(validateNotifyEvent(bounded)).toBe(true);
  });

  it("bounds question text code-point safely across surrogate pairs", () => {
    // 1998 BMP + one astral char + tail = 2003 code points.
    const event = makeFactory().actionRequired(SESSION, {
      sessionID: SESSION.id,
      requestId: "qst_req5",
      kind: "question",
      questions: [{ question: `${"q".repeat(1_998)}\u{1F600}tail`, options: [] }],
    });
    expect(event.payload).toEqual({
      requestId: "qst_req5",
      kind: "question",
      questions: [{ question: `${"q".repeat(1_998)}\u{1F600}…` }],
    });
    expect(validateNotifyEvent(event)).toBe(true);
  });

  it("keeps only the first 16 options and drops empty labels", () => {
    const options = Array.from({ length: 18 }, (_, i) => ({ label: `Option ${i}` }));
    options[3] = { label: "" };
    const event = makeFactory().actionRequired(SESSION, {
      sessionID: SESSION.id,
      requestId: "qst_req6",
      kind: "question",
      questions: [{ question: "Pick one", options }],
    });
    const payload = event.payload as {
      questions: Array<{ options: Array<{ label: string }> }>;
    };
    expect(payload.questions[0]?.options).toHaveLength(16);
    expect(payload.questions[0]?.options.map((o) => o.label)).not.toContain("");
    expect(validateNotifyEvent(event)).toBe(true);
  });

  it("drops empty questions deterministically and throws when none remain", () => {
    const event = makeFactory().actionRequired(SESSION, {
      sessionID: SESSION.id,
      requestId: "qst_req7",
      kind: "question",
      questions: [
        { question: "", options: [] },
        { question: "Real question", options: [] },
      ],
    });
    expect(event.payload).toEqual({
      requestId: "qst_req7",
      kind: "question",
      questions: [{ question: "Real question" }],
    });
    expect(validateNotifyEvent(event)).toBe(true);
    expect(() =>
      makeFactory().actionRequired(SESSION, {
        sessionID: SESSION.id,
        requestId: "qst_req8",
        kind: "question",
        questions: [{ question: "", options: [] }],
      }),
    ).toThrow();
  });

  it("maps a permission request with permission and summary", () => {
    const event = makeFactory().actionRequired(SESSION, {
      sessionID: SESSION.id,
      requestId: "per_req1",
      kind: "permission",
      permission: { permission: "bash", summary: "bash: pnpm test, git status" },
    });
    expect(event.payload).toEqual({
      requestId: "per_req1",
      kind: "permission",
      permission: { permission: "bash", summary: "bash: pnpm test, git status" },
    });
    expect(validateNotifyEvent(event)).toBe(true);
  });

  it("bounds the permission summary to 500 code points and rejects an empty one", () => {
    const event = makeFactory().actionRequired(SESSION, {
      sessionID: SESSION.id,
      requestId: "per_req2",
      kind: "permission",
      permission: { permission: "bash", summary: "p".repeat(600) },
    });
    expect(event.payload).toEqual({
      requestId: "per_req2",
      kind: "permission",
      permission: { permission: "bash", summary: `${"p".repeat(499)}…` },
    });
    expect(validateNotifyEvent(event)).toBe(true);
    expect(() =>
      makeFactory().actionRequired(SESSION, {
        sessionID: SESSION.id,
        requestId: "per_req3",
        kind: "permission",
        permission: { permission: "bash", summary: "" },
      }),
    ).toThrow();
  });

  it("maps a provider action with all fields", () => {
    const event = makeFactory().actionRequired(SESSION, {
      sessionID: SESSION.id,
      requestId: "provider:" + "a".repeat(64),
      kind: "provider_action",
      providerAction: {
        provider: "anthropic",
        title: "Re-authenticate",
        message: "Your OAuth token expired.",
        label: "Sign in",
        link: "https://provider.example/reauth",
      },
    });
    expect(event.payload).toEqual({
      requestId: `provider:${"a".repeat(64)}`,
      kind: "provider_action",
      providerAction: {
        provider: "anthropic",
        title: "Re-authenticate",
        message: "Your OAuth token expired.",
        label: "Sign in",
        link: "https://provider.example/reauth",
      },
    });
    expect(validateNotifyEvent(event)).toBe(true);
  });

  it("bounds provider fields to the exact contract limits", () => {
    const event = makeFactory().actionRequired(SESSION, {
      sessionID: SESSION.id,
      requestId: "provider:" + "b".repeat(64),
      kind: "provider_action",
      providerAction: {
        provider: "p".repeat(130),
        title: "t".repeat(130),
        message: "m".repeat(600),
        label: "l".repeat(130),
      },
    });
    expect(event.payload).toEqual({
      requestId: `provider:${"b".repeat(64)}`,
      kind: "provider_action",
      providerAction: {
        provider: `${"p".repeat(119)}…`,
        title: `${"t".repeat(119)}…`,
        message: `${"m".repeat(499)}…`,
        label: `${"l".repeat(119)}…`,
      },
    });
    expect(validateNotifyEvent(event)).toBe(true);
  });

  it("drops a malformed, whitespace-bearing, or overlong link but still emits", () => {
    const base = {
      sessionID: SESSION.id,
      kind: "provider_action" as const,
      providerAction: {
        provider: "anthropic",
        title: "Re-authenticate",
        message: "Token expired.",
        label: "Sign in",
      },
    };
    for (const [index, link] of [
      "not a url",
      "https://example.com/a b",
      `https://example.com/${"a".repeat(2_080)}`,
    ].entries()) {
      const event = makeFactory().actionRequired(SESSION, {
        ...base,
        requestId: `provider:${String(index).padStart(64, "0")}`,
        providerAction: { ...base.providerAction, link },
      });
      expect(event.payload).toEqual({
        requestId: `provider:${String(index).padStart(64, "0")}`,
        kind: "provider_action",
        providerAction: base.providerAction,
      });
      expect(validateNotifyEvent(event)).toBe(true);
    }
  });
});

describe("action_resolved events", () => {
  it("builds question and permission resolutions", () => {
    const factory = makeFactory();
    const question = factory.actionResolved(SESSION, {
      sessionID: SESSION.id,
      requestId: "qst_req1",
      kind: "question",
    });
    expect(question).toEqual({
      eventId: "00000000-0000-4000-8000-000000000001",
      type: "action_resolved",
      occurredAt: NOW_ISO,
      source: SOURCE,
      session: { id: "ses_abc123", title: "Fix login redirect" },
      payload: { requestId: "qst_req1", kind: "question" },
    });
    const permission = factory.actionResolved(SESSION, {
      sessionID: SESSION.id,
      requestId: "per_req1",
      kind: "permission",
    });
    expect(permission.payload).toEqual({ requestId: "per_req1", kind: "permission" });
    expect(validateNotifyEvent(question)).toBe(true);
    expect(validateNotifyEvent(permission)).toBe(true);
  });
});
