import { describe, expect, it, vi } from "vitest";

import {
  PendingAdapter,
  type PendingListClient,
  type PendingSource,
} from "../src/pending-adapter.js";

const INSTANCE_ID = "6f0d91b0-93e4-43a9-9449-0bed03e651aa";
const FIXED_NOW = "2026-08-14T09:00:00.000Z";

const SOURCE: PendingSource = {
  instanceId: INSTANCE_ID,
  machine: "devbox",
  project: "api",
  directory: "/work/api",
};

function questionRequest(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    id: "qst_req1",
    sessionID: "ses_1",
    questions: [
      {
        header: "Database",
        question: "Which database should the migration target?",
        options: [
          { label: "PostgreSQL", description: "Production parity" },
          { label: "SQLite", description: "Fast local runs" },
        ],
        multiple: true,
        custom: false,
      },
      {
        header: "Backfill",
        question: "Backfill existing rows?",
        options: [{ label: "Yes", description: "Backfill in the same migration" }],
      },
    ],
    tool: { messageID: "msg_1", callID: "call_1" },
    ...overrides,
  };
}

function permissionRequest(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    id: "per_req1",
    sessionID: "ses_1",
    permission: "bash",
    patterns: ["rm -rf build/"],
    always: ["printf *"],
    metadata: { source: "interactive", command: "pnpm test" },
    tool: { messageID: "msg_2", callID: "call_2" },
    ...overrides,
  };
}

interface FakeListClient {
  client: PendingListClient;
  questionList: ReturnType<typeof vi.fn>;
  permissionList: ReturnType<typeof vi.fn>;
}

function makeClient(
  questionData: unknown[] = [],
  permissionData: unknown[] = [],
): FakeListClient {
  const questionList = vi.fn(async () => ({ data: questionData, error: undefined }));
  const permissionList = vi.fn(async () => ({ data: permissionData, error: undefined }));
  return {
    client: { question: { list: questionList }, permission: { list: permissionList } },
    questionList,
    permissionList,
  };
}

function makeAdapter(
  client: PendingListClient,
  titleForSession: (sessionID: string) => string | undefined = () => "Implement API",
): PendingAdapter {
  return new PendingAdapter({
    client,
    titleForSession,
    now: () => new Date(FIXED_NOW),
  });
}

describe("PendingAdapter", () => {
  it("maps a complete question request with options, descriptions, and tool identity", async () => {
    const { client } = makeClient([questionRequest()]);
    const adapter = makeAdapter(client);

    const interactions = await adapter.list(SOURCE);

    expect(interactions).toHaveLength(1);
    expect(interactions[0]).toMatchObject({
      kind: "question",
      instanceId: INSTANCE_ID,
      machine: "devbox",
      project: "api",
      directory: "/work/api",
      sessionId: "ses_1",
      sessionTitle: "Implement API",
      requestId: "qst_req1",
      occurredAt: FIXED_NOW,
      tool: { messageId: "msg_1", callId: "call_1" },
      questions: [
        {
          header: "Database",
          question: "Which database should the migration target?",
          options: [
            { label: "PostgreSQL", description: "Production parity" },
            { label: "SQLite", description: "Fast local runs" },
          ],
          multiple: true,
          custom: false,
        },
        {
          header: "Backfill",
          question: "Backfill existing rows?",
          options: [{ label: "Yes", description: "Backfill in the same migration" }],
          multiple: false,
          custom: true,
        },
      ],
    });
  });

  it("maps a complete permission request retaining patterns, always, metadata, and tool", async () => {
    const { client } = makeClient([], [permissionRequest()]);
    const adapter = makeAdapter(client);

    const interactions = await adapter.list(SOURCE);

    expect(interactions).toHaveLength(1);
    expect(interactions[0]).toMatchObject({
      kind: "permission",
      instanceId: INSTANCE_ID,
      machine: "devbox",
      project: "api",
      directory: "/work/api",
      sessionId: "ses_1",
      sessionTitle: "Implement API",
      requestId: "per_req1",
      occurredAt: FIXED_NOW,
      permission: "bash",
      patterns: ["rm -rf build/"],
      always: ["printf *"],
      metadata: { source: "interactive", command: "pnpm test" },
      tool: { messageId: "msg_2", callId: "call_2" },
    });
  });

  it("queries only the instance's own directory", async () => {
    const { client, questionList, permissionList } = makeClient([questionRequest()], [permissionRequest()]);
    const adapter = makeAdapter(client);

    await adapter.list(SOURCE);

    expect(questionList).toHaveBeenCalledTimes(1);
    expect(questionList).toHaveBeenCalledWith({ directory: "/work/api" });
    expect(permissionList).toHaveBeenCalledTimes(1);
    expect(permissionList).toHaveBeenCalledWith({ directory: "/work/api" });
  });

  it("supplies a best-effort session title and an empty fallback", async () => {
    const { client } = makeClient([questionRequest()]);
    const adapter = makeAdapter(client, (sessionID) => (sessionID === "ses_1" ? undefined : undefined));

    const interactions = await adapter.list(SOURCE);

    expect(interactions[0]).toMatchObject({ sessionTitle: "" });
  });

  it("maintains a stable first-observed occurredAt while the request is present", async () => {
    const questionData = [questionRequest()];
    const questionList = vi.fn(async () => ({ data: questionData, error: undefined }));
    const permissionList = vi.fn(async () => ({ data: [], error: undefined }));
    const client = { question: { list: questionList }, permission: { list: permissionList } };
    let current = new Date(FIXED_NOW);
    const adapter = new PendingAdapter({
      client,
      titleForSession: () => "Implement API",
      now: () => current,
    });

    const first = await adapter.list(SOURCE);
    expect(first[0].occurredAt).toBe(FIXED_NOW);

    current = new Date("2026-08-14T09:05:00.000Z");
    const second = await adapter.list(SOURCE);
    expect(second[0].occurredAt).toBe(FIXED_NOW);

    current = new Date("2026-08-14T09:10:00.000Z");
    const third = await adapter.list(SOURCE);
    expect(third[0].occurredAt).toBe(FIXED_NOW);
  });

  it("drops the first-observed entry once the request disappears, then restarts it", async () => {
    const questionData: unknown[] = [questionRequest()];
    const questionList = vi.fn(async () => ({ data: questionData, error: undefined }));
    const permissionList = vi.fn(async () => ({ data: [], error: undefined }));
    const client = { question: { list: questionList }, permission: { list: permissionList } };
    let current = new Date(FIXED_NOW);
    const adapter = new PendingAdapter({
      client,
      titleForSession: () => "Implement API",
      now: () => current,
    });

    const first = await adapter.list(SOURCE);
    expect(first[0].occurredAt).toBe(FIXED_NOW);

    questionData.length = 0;
    await adapter.list(SOURCE);

    questionData.push(questionRequest());
    current = new Date("2026-08-14T09:05:00.000Z");
    const restarted = await adapter.list(SOURCE);
    expect(restarted[0].occurredAt).toBe("2026-08-14T09:05:00.000Z");
  });

  it("recognizes an SDK error envelope as no available list (fail closed)", async () => {
    const questionList = vi.fn(async () => ({ data: undefined, error: { _tag: "BadRequestError" } }));
    const permissionList = vi.fn(async () => ({ data: [permissionRequest()], error: undefined }));
    const client = { question: { list: questionList }, permission: { list: permissionList } };
    const adapter = makeAdapter(client);

    const interactions = await adapter.list(SOURCE);

    // One unavailable authoritative list makes the whole snapshot empty.
    expect(interactions).toEqual([]);
  });

  it("treats a thrown SDK call as an unavailable snapshot", async () => {
    const questionList = vi.fn(async () => {
      throw new Error("sdk unreachable");
    });
    const permissionList = vi.fn(async () => ({ data: [permissionRequest()], error: undefined }));
    const client = { question: { list: questionList }, permission: { list: permissionList } };
    const adapter = makeAdapter(client);

    const interactions = await adapter.list(SOURCE);

    expect(interactions).toEqual([]);
  });

  it("skips malformed requests but maps the valid ones", async () => {
    const { client } = makeClient(
      [
        questionRequest(),
        { id: "qst_bad", sessionID: "ses_1", questions: "nope" },
        null,
        42,
      ],
      [permissionRequest(), { id: "per_bad", sessionID: "ses_1", permission: "" }],
    );
    const adapter = makeAdapter(client);

    const interactions = await adapter.list(SOURCE);

    expect(interactions).toHaveLength(2);
    expect(interactions.map((interaction) => interaction.requestId)).toEqual([
      "qst_req1",
      "per_req1",
    ]);
  });

  it("normalizes a question item without multiple/custom flags to false/true", async () => {
    const { client } = makeClient([
      questionRequest({
        questions: [{ header: "h", question: "Q?", options: [] }],
      }),
    ]);
    const adapter = makeAdapter(client);

    const interactions = await adapter.list(SOURCE);

    expect(interactions[0]).toMatchObject({
      questions: [{ header: "h", question: "Q?", options: [], multiple: false, custom: true }],
    });
  });

  it("never emits provider actions by construction", async () => {
    const { client } = makeClient(
      [questionRequest()],
      [permissionRequest()],
    );
    const adapter = makeAdapter(client);

    const interactions = await adapter.list(SOURCE);

    for (const interaction of interactions) {
      expect(interaction.kind === "question" || interaction.kind === "permission").toBe(true);
    }
  });
});
