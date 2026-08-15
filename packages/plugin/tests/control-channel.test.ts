import { afterEach, describe, expect, it, vi } from "vitest";
import type { PendingInteraction } from "@notify/contracts";

import { ControlChannel, type ControlSocket } from "../src/control-channel.js";

class FakeSocket implements ControlSocket {
  readonly sent: string[] = [];
  readonly listeners = new Map<string, Set<(event?: unknown) => void>>();
  closed = false;

  addEventListener(event: string, listener: (event?: unknown) => void): void {
    const listeners = this.listeners.get(event) ?? new Set();
    listeners.add(listener);
    this.listeners.set(event, listeners);
  }

  send(data: string): void {
    this.sent.push(data);
  }

  close(): void {
    this.closed = true;
  }

  emit(event: string, value?: unknown): void {
    for (const listener of this.listeners.get(event) ?? []) {
      listener(value);
    }
  }
}

describe("ControlChannel", () => {
  afterEach(() => {
    vi.useRealTimers();
    vi.unstubAllGlobals();
  });

  it("authenticates and registers the owning OpenCode instance after version discovery", async () => {
    const socket = new FakeSocket();
    const calls: Array<{ url: string; authorization: string }> = [];
    const channel = new ControlChannel({
      gatewayUrl: "https://notify.example.com",
      credential: "key-id.key-secret",
      machine: "devbox",
      project: "notify",
      directory: "/work/notify",
      resolveOpenCodeVersion: async () => "1.18.18",
      randomUUID: () => "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
      socketFactory: (url, authorization) => {
        calls.push({ url, authorization });
        return socket;
      },
    });

    channel.start();
    await vi.waitFor(() => expect(calls).toHaveLength(1));
    expect(calls[0]).toEqual({
      url: "wss://notify.example.com/v1/plugin/ws",
      authorization: "Bearer key-id.key-secret",
    });
    expect(socket.sent).toEqual([]);

    socket.emit("open");
    expect(socket.sent.map((frame) => JSON.parse(frame))).toEqual([
      {
        type: "register",
        instanceId: "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
        machine: "devbox",
        project: "notify",
        directory: "/work/notify",
        openCodeVersion: "1.18.18",
        protocolVersion: 1,
      },
    ]);
  });

  it("uses the runtime WebSocket authorization-header constructor", async () => {
    const socket = new FakeSocket();
    const calls: unknown[][] = [];
    vi.stubGlobal(
      "WebSocket",
      function (...args: unknown[]) {
        calls.push(args);
        return socket;
      },
    );
    const channel = new ControlChannel({
      gatewayUrl: "https://notify.example.com",
      credential: "key-id.key-secret",
      machine: "devbox",
      project: "notify",
      directory: "/work/notify",
      resolveOpenCodeVersion: async () => "1.18.18",
      randomUUID: () => "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
    });

    channel.start();
    await vi.waitFor(() => expect(calls).toHaveLength(1));

    expect(calls[0]).toEqual([
      "wss://notify.example.com/v1/plugin/ws",
      { headers: { Authorization: "Bearer key-id.key-secret" } },
    ]);
    channel.stop();
  });

  it("reconnects with the same instance id and stops without leaving a retry", async () => {
    vi.useFakeTimers();
    const sockets: FakeSocket[] = [];
    const channel = new ControlChannel({
      gatewayUrl: "http://127.0.0.1:3000",
      credential: "key-id.key-secret",
      machine: "devbox",
      project: "notify",
      directory: "/work/notify",
      resolveOpenCodeVersion: async () => "1.18.18",
      randomUUID: () => "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
      random: () => 0.5,
      socketFactory: () => {
        const socket = new FakeSocket();
        sockets.push(socket);
        return socket;
      },
    });

    channel.start();
    await vi.advanceTimersByTimeAsync(0);
    expect(sockets).toHaveLength(1);
    sockets[0].emit("close");
    await vi.advanceTimersByTimeAsync(499);
    expect(sockets).toHaveLength(1);
    await vi.advanceTimersByTimeAsync(1);
    expect(sockets).toHaveLength(2);

    channel.stop();
    sockets[1].emit("close");
    await vi.advanceTimersByTimeAsync(60_000);
    expect(sockets).toHaveLength(2);
    expect(sockets[1].closed).toBe(true);
  });

  it("stops reconnecting after the Gateway reports a revoked Plugin key", async () => {
    vi.useFakeTimers();
    const sockets: FakeSocket[] = [];
    const channel = new ControlChannel({
      gatewayUrl: "https://notify.example.com",
      credential: "key-id.key-secret",
      machine: "devbox",
      project: "notify",
      directory: "/work/notify",
      resolveOpenCodeVersion: async () => "1.18.18",
      randomUUID: () => "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
      socketFactory: () => {
        const socket = new FakeSocket();
        sockets.push(socket);
        return socket;
      },
    });

    channel.start();
    await vi.runAllTimersAsync();
    sockets[0].emit("close", { code: 4403 });
    await vi.advanceTimersByTimeAsync(60_000);

    expect(sockets).toHaveLength(1);
  });

  it("continues with an incompatible unknown version when discovery times out", async () => {
    vi.useFakeTimers();
    const socket = new FakeSocket();
    const channel = new ControlChannel({
      gatewayUrl: "https://notify.example.com",
      credential: "key-id.key-secret",
      machine: "devbox",
      project: "notify",
      directory: "/work/notify",
      resolveOpenCodeVersion: () => new Promise(() => undefined),
      versionTimeoutMs: 50,
      randomUUID: () => "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
      socketFactory: () => socket,
    });

    channel.start();
    await vi.runAllTimersAsync();
    socket.emit("open");

    expect(JSON.parse(socket.sent[0])).toMatchObject({ openCodeVersion: "unknown" });
  });

  it("answers a pending_snapshot_request with the stable instanceId and the seam's interactions", async () => {
    vi.useFakeTimers();
    const socket = new FakeSocket();
    const interaction: PendingInteraction = {
      kind: "question",
      instanceId: "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
      machine: "devbox",
      project: "notify",
      directory: "/work/notify",
      sessionId: "ses_1",
      sessionTitle: "Implement API",
      requestId: "req_1",
      occurredAt: "2026-08-14T09:00:00.000Z",
      questions: [
        { header: "h", question: "Q?", options: [], multiple: false, custom: true },
      ],
    };
    const listPendingInteractions = vi.fn(async (source: { directory: string }) => [
      interaction,
    ]);
    const channel = new ControlChannel({
      gatewayUrl: "https://notify.example.com",
      credential: "key-id.key-secret",
      machine: "devbox",
      project: "notify",
      directory: "/work/notify",
      resolveOpenCodeVersion: async () => "1.18.18",
      randomUUID: () => "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
      socketFactory: () => socket,
      listPendingInteractions,
    });

    channel.start();
    await vi.advanceTimersByTimeAsync(0);
    socket.emit("open");
    socket.emit("message", {
      data: JSON.stringify({
        type: "registration",
        instanceId: "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
        state: "controllable",
      }),
    });
    socket.emit("message", {
      data: JSON.stringify({ type: "pending_snapshot_request", requestId: "0e3f9c2e-1a4d-4e5f-9a6b-7c8d9e0f1a2b" }),
    });
    await vi.advanceTimersByTimeAsync(0);

    expect(listPendingInteractions).toHaveBeenCalledWith(
      {
        instanceId: "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
        machine: "devbox",
        project: "notify",
        directory: "/work/notify",
      },
      expect.any(AbortSignal),
    );
    expect(socket.sent.map((frame) => JSON.parse(frame))).toContainEqual({
      type: "pending_snapshot_response",
      requestId: "0e3f9c2e-1a4d-4e5f-9a6b-7c8d9e0f1a2b",
      instanceId: "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
      interactions: [
        expect.objectContaining({ kind: "question", requestId: "req_1" }),
      ],
    });
  });

  it("ignores pending_snapshot_request frames received before registration", async () => {
    vi.useFakeTimers();
    const socket = new FakeSocket();
    const listPendingInteractions = vi.fn(async () => []);
    const channel = new ControlChannel({
      gatewayUrl: "https://notify.example.com",
      credential: "key-id.key-secret",
      machine: "devbox",
      project: "notify",
      directory: "/work/notify",
      resolveOpenCodeVersion: async () => "1.18.18",
      randomUUID: () => "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
      socketFactory: () => socket,
      listPendingInteractions,
    });

    channel.start();
    await vi.advanceTimersByTimeAsync(0);
    socket.emit("open");
    socket.emit("message", {
      data: JSON.stringify({ type: "pending_snapshot_request", requestId: "0e3f9c2e-1a4d-4e5f-9a6b-7c8d9e0f1a2b" }),
    });
    await vi.advanceTimersByTimeAsync(0);

    expect(listPendingInteractions).not.toHaveBeenCalled();
    expect(socket.sent.map((frame) => JSON.parse(frame))).not.toContainEqual(
      expect.objectContaining({ type: "pending_snapshot_response" }),
    );
  });

  it("coalesces concurrent snapshot requests onto one OpenCode poll", async () => {
    vi.useFakeTimers();
    const socket = new FakeSocket();
    let finish!: (interactions: PendingInteraction[]) => void;
    const poll = new Promise<PendingInteraction[]>((resolve) => {
      finish = resolve;
    });
    const listPendingInteractions = vi.fn(() => poll);
    const channel = new ControlChannel({
      gatewayUrl: "https://notify.example.com",
      credential: "key-id.key-secret",
      machine: "devbox",
      project: "notify",
      directory: "/work/notify",
      resolveOpenCodeVersion: async () => "1.18.18",
      randomUUID: () => "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
      socketFactory: () => socket,
      listPendingInteractions,
    });
    channel.start();
    await vi.advanceTimersByTimeAsync(0);
    socket.emit("open");
    socket.emit("message", {
      data: JSON.stringify({
        type: "registration",
        instanceId: "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
        state: "controllable",
      }),
    });

    for (const requestId of [
      "0e3f9c2e-1a4d-4e5f-9a6b-7c8d9e0f1a2b",
      "1e3f9c2e-1a4d-4e5f-9a6b-7c8d9e0f1a2b",
    ]) {
      socket.emit("message", {
        data: JSON.stringify({ type: "pending_snapshot_request", requestId }),
      });
    }
    await vi.advanceTimersByTimeAsync(0);
    expect(listPendingInteractions).toHaveBeenCalledTimes(1);

    finish([]);
    await vi.advanceTimersByTimeAsync(0);
    const responses = socket.sent
      .map((frame) => JSON.parse(frame))
      .filter((frame) => frame.type === "pending_snapshot_response");
    expect(responses).toHaveLength(2);
  });

  it("replies with an empty snapshot when the adapter fails or times out", async () => {
    vi.useFakeTimers();
    const socket = new FakeSocket();
    const failures: Array<() => Promise<PendingInteraction[]>> = [
      async () => {
        throw new Error("adapter exploded");
      },
      () => new Promise(() => undefined), // hangs forever
    ];
    let latestSignal: AbortSignal | undefined;
    const requestId = "0e3f9c2e-1a4d-4e5f-9a6b-7c8d9e0f1a2b";
    const channel = new ControlChannel({
      gatewayUrl: "https://notify.example.com",
      credential: "key-id.key-secret",
      machine: "devbox",
      project: "notify",
      directory: "/work/notify",
      resolveOpenCodeVersion: async () => "1.18.18",
      randomUUID: () => "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
      pendingSnapshotTimeoutMs: 50,
      socketFactory: () => socket,
      listPendingInteractions: async (_source, signal) => {
        latestSignal = signal;
        const failure = failures.shift()!;
        return failure();
      },
    });

    channel.start();
    await vi.advanceTimersByTimeAsync(0);
    socket.emit("open");
    socket.emit("message", {
      data: JSON.stringify({
        type: "registration",
        instanceId: "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
        state: "controllable",
      }),
    });

    socket.emit("message", { data: JSON.stringify({ type: "pending_snapshot_request", requestId }) });
    await vi.advanceTimersByTimeAsync(0);
    expect(JSON.parse(socket.sent.at(-1)!)?.type).toBe("pending_snapshot_response");
    expect(JSON.parse(socket.sent.at(-1)!)).toMatchObject({
      type: "pending_snapshot_response",
      requestId,
      instanceId: "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
      interactions: [],
    });
    socket.emit("message", { data: JSON.stringify({ type: "pending_snapshot_request", requestId }) });
    await vi.advanceTimersByTimeAsync(50);
    expect(JSON.parse(socket.sent.at(-1)!)).toMatchObject({
      type: "pending_snapshot_response",
      requestId,
      instanceId: "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
      interactions: [],
    });
    expect(latestSignal?.aborted).toBe(true);
  });

  it("ignores unknown and malformed server frames without killing notification behavior", async () => {
    vi.useFakeTimers();
    const socket = new FakeSocket();
    const listPendingInteractions = vi.fn(async () => []);
    const channel = new ControlChannel({
      gatewayUrl: "https://notify.example.com",
      credential: "key-id.key-secret",
      machine: "devbox",
      project: "notify",
      directory: "/work/notify",
      resolveOpenCodeVersion: async () => "1.18.18",
      randomUUID: () => "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
      socketFactory: () => socket,
      listPendingInteractions,
    });

    channel.start();
    await vi.advanceTimersByTimeAsync(0);
    socket.emit("open");

    const garbage: unknown[] = [
      { data: "not json at all {" },
      { data: "{}" },
      { data: JSON.stringify({ type: "bogus", extra: 1 }) },
      { data: JSON.stringify({ type: "pending_snapshot_request" }) }, // missing requestId
      { data: 42 },
      null,
      undefined,
      "bare string",
    ];
    for (const frame of garbage) {
      socket.emit("message", frame);
    }
    await vi.advanceTimersByTimeAsync(60_000);

    expect(listPendingInteractions).not.toHaveBeenCalled();
    expect(socket.sent.map((frame) => JSON.parse(frame))).toEqual([
      expect.objectContaining({ type: "register" }),
    ]);

    // The channel stays alive and still answers a well-formed request.
    socket.emit("message", {
      data: JSON.stringify({
        type: "registration",
        instanceId: "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
        state: "controllable",
      }),
    });
    socket.emit("message", {
      data: JSON.stringify({ type: "pending_snapshot_request", requestId: "0e3f9c2e-1a4d-4e5f-9a6b-7c8d9e0f1a2b" }),
    });
    await vi.advanceTimersByTimeAsync(0);
    expect(listPendingInteractions).toHaveBeenCalledTimes(1);
    expect(socket.sent.map((frame) => JSON.parse(frame))).toContainEqual(
      expect.objectContaining({ type: "pending_snapshot_response" }),
    );
  });

  it("replies with an empty snapshot when no seam is configured", async () => {
    vi.useFakeTimers();
    const socket = new FakeSocket();
    const channel = new ControlChannel({
      gatewayUrl: "https://notify.example.com",
      credential: "key-id.key-secret",
      machine: "devbox",
      project: "notify",
      directory: "/work/notify",
      resolveOpenCodeVersion: async () => "1.18.18",
      randomUUID: () => "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
      socketFactory: () => socket,
    });

    channel.start();
    await vi.advanceTimersByTimeAsync(0);
    socket.emit("open");
    socket.emit("message", {
      data: JSON.stringify({
        type: "registration",
        instanceId: "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
        state: "controllable",
      }),
    });
    socket.emit("message", {
      data: JSON.stringify({ type: "pending_snapshot_request", requestId: "0e3f9c2e-1a4d-4e5f-9a6b-7c8d9e0f1a2b" }),
    });
    await vi.advanceTimersByTimeAsync(0);

    expect(socket.sent.map((frame) => JSON.parse(frame))).toContainEqual({
      type: "pending_snapshot_response",
      requestId: "0e3f9c2e-1a4d-4e5f-9a6b-7c8d9e0f1a2b",
      instanceId: "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
      interactions: [],
    });
  });

  const answerCommandId = "7f3a9b6c-2d4e-4f5a-8b7c-1d2e3f4a5b6c";

  /** Drive an open socket into the post-registration state. */
  function registeredChannel(socket: FakeSocket): void {
    socket.emit("open");
    socket.emit("message", {
      data: JSON.stringify({
        type: "registration",
        instanceId: "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
        state: "controllable",
      }),
    });
  }

  it("answers a question_answer_command with the stable instanceId and the seam's status", async () => {
    vi.useFakeTimers();
    const socket = new FakeSocket();
    const answerQuestion = vi.fn(async () => "confirmed" as const);
    const channel = new ControlChannel({
      gatewayUrl: "https://notify.example.com",
      credential: "key-id.key-secret",
      machine: "devbox",
      project: "notify",
      directory: "/work/notify",
      resolveOpenCodeVersion: async () => "1.18.18",
      randomUUID: () => "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
      socketFactory: () => socket,
      answerQuestion,
    });

    channel.start();
    await vi.advanceTimersByTimeAsync(0);
    registeredChannel(socket);
    socket.emit("message", {
      data: JSON.stringify({
        type: "question_answer_command",
        commandId: answerCommandId,
        requestId: "req_1",
        answers: [["Postgres"]],
      }),
    });
    await vi.advanceTimersByTimeAsync(0);

    expect(answerQuestion).toHaveBeenCalledTimes(1);
    expect(socket.sent.map((frame) => JSON.parse(frame))).toContainEqual({
      type: "question_answer_result",
      commandId: answerCommandId,
      instanceId: "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
      status: "confirmed",
    });
  });

  it("passes the exact ordered answers, the owning directory, and a bounded signal to the seam", async () => {
    vi.useFakeTimers();
    const socket = new FakeSocket();
    const answers = [["Postgres"], ["rust", "go"], ["Custom: as needed"]];
    const answerQuestion = vi.fn(async () => "confirmed" as const);
    const channel = new ControlChannel({
      gatewayUrl: "https://notify.example.com",
      credential: "key-id.key-secret",
      machine: "devbox",
      project: "notify",
      directory: "/work/notify",
      resolveOpenCodeVersion: async () => "1.18.18",
      randomUUID: () => "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
      socketFactory: () => socket,
      answerQuestion,
    });

    channel.start();
    await vi.advanceTimersByTimeAsync(0);
    registeredChannel(socket);
    socket.emit("message", {
      data: JSON.stringify({
        type: "question_answer_command",
        commandId: answerCommandId,
        requestId: "req_1",
        answers,
      }),
    });
    await vi.advanceTimersByTimeAsync(0);

    expect(answerQuestion).toHaveBeenCalledWith(
      "req_1",
      "/work/notify",
      answers,
      expect.any(AbortSignal),
    );
  });

  it("does not coalesce concurrent commands with different commandIds", async () => {
    vi.useFakeTimers();
    const socket = new FakeSocket();
    const resolves: Array<() => void> = [];
    const answerQuestion = vi.fn(
      () =>
        new Promise<"confirmed">((resolve) => {
          resolves.push(() => resolve("confirmed"));
        }),
    );
    const channel = new ControlChannel({
      gatewayUrl: "https://notify.example.com",
      credential: "key-id.key-secret",
      machine: "devbox",
      project: "notify",
      directory: "/work/notify",
      resolveOpenCodeVersion: async () => "1.18.18",
      randomUUID: () => "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
      socketFactory: () => socket,
      answerQuestion,
    });
    const secondCommandId = "8f3a9b6c-2d4e-4f5a-8b7c-1d2e3f4a5b6c";

    channel.start();
    await vi.advanceTimersByTimeAsync(0);
    registeredChannel(socket);
    for (const commandId of [answerCommandId, secondCommandId]) {
      socket.emit("message", {
        data: JSON.stringify({
          type: "question_answer_command",
          commandId,
          requestId: "req_1",
          answers: [["Postgres"]],
        }),
      });
    }
    await vi.advanceTimersByTimeAsync(0);
    // Each command runs independently: the seam is never coalesced onto one call.
    expect(answerQuestion).toHaveBeenCalledTimes(2);

    for (const resolve of resolves) {
      resolve();
    }
    await vi.advanceTimersByTimeAsync(0);
    const results = socket.sent
      .map((frame) => JSON.parse(frame))
      .filter((frame) => frame.type === "question_answer_result");
    expect(results).toHaveLength(2);
    expect(results.map((result) => result.commandId).sort()).toEqual(
      [answerCommandId, secondCommandId].sort(),
    );
  });

  it("ignores a question_answer_command received before registration", async () => {
    vi.useFakeTimers();
    const socket = new FakeSocket();
    const answerQuestion = vi.fn(async () => "confirmed" as const);
    const channel = new ControlChannel({
      gatewayUrl: "https://notify.example.com",
      credential: "key-id.key-secret",
      machine: "devbox",
      project: "notify",
      directory: "/work/notify",
      resolveOpenCodeVersion: async () => "1.18.18",
      randomUUID: () => "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
      socketFactory: () => socket,
      answerQuestion,
    });

    channel.start();
    await vi.advanceTimersByTimeAsync(0);
    socket.emit("open");
    socket.emit("message", {
      data: JSON.stringify({
        type: "question_answer_command",
        commandId: answerCommandId,
        requestId: "req_1",
        answers: [["Postgres"]],
      }),
    });
    await vi.advanceTimersByTimeAsync(0);

    expect(answerQuestion).not.toHaveBeenCalled();
    expect(socket.sent.map((frame) => JSON.parse(frame))).not.toContainEqual(
      expect.objectContaining({ type: "question_answer_result" }),
    );
  });

  it("ignores malformed question_answer_command frames without killing notification behavior", async () => {
    vi.useFakeTimers();
    const socket = new FakeSocket();
    const answerQuestion = vi.fn(async () => "confirmed" as const);
    const channel = new ControlChannel({
      gatewayUrl: "https://notify.example.com",
      credential: "key-id.key-secret",
      machine: "devbox",
      project: "notify",
      directory: "/work/notify",
      resolveOpenCodeVersion: async () => "1.18.18",
      randomUUID: () => "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
      socketFactory: () => socket,
      answerQuestion,
    });

    channel.start();
    await vi.advanceTimersByTimeAsync(0);
    registeredChannel(socket);

    const valid = {
      type: "question_answer_command",
      commandId: answerCommandId,
      requestId: "req_1",
      answers: [["Postgres"]],
    };
    const garbage: Record<string, unknown>[] = [
      { ...valid, commandId: "cmd_1" },
      { ...valid, commandId: "" },
      { ...valid, commandId: 7 },
      { ...valid, requestId: "" },
      { ...valid, requestId: 7 },
      { ...valid, answers: [] },
      { ...valid, answers: [[]] },
      { ...valid, answers: [[""]] },
      { ...valid, answers: [["Postgres", ""]] },
      { ...valid, answers: [[42]] },
      { ...valid, answers: "Postgres" },
      { ...valid, answers: undefined },
      { type: "question_answer_command", commandId: answerCommandId, requestId: "req_1" },
      { type: "question_answer_command", commandId: answerCommandId, answers: [["Postgres"]] },
      { type: "question_answer_command" },
    ];
    for (const frame of garbage) {
      socket.emit("message", { data: JSON.stringify(frame) });
    }
    await vi.advanceTimersByTimeAsync(60_000);

    expect(answerQuestion).not.toHaveBeenCalled();
    expect(socket.sent.map((frame) => JSON.parse(frame))).not.toContainEqual(
      expect.objectContaining({ type: "question_answer_result" }),
    );

    // The channel stays alive and still answers a well-formed command.
    socket.emit("message", { data: JSON.stringify(valid) });
    await vi.advanceTimersByTimeAsync(0);
    expect(answerQuestion).toHaveBeenCalledTimes(1);
    expect(socket.sent.map((frame) => JSON.parse(frame))).toContainEqual(
      expect.objectContaining({
        type: "question_answer_result",
        commandId: answerCommandId,
        status: "confirmed",
      }),
    );
  });

  it("reports result_unknown when no answer seam is configured", async () => {
    vi.useFakeTimers();
    const socket = new FakeSocket();
    const channel = new ControlChannel({
      gatewayUrl: "https://notify.example.com",
      credential: "key-id.key-secret",
      machine: "devbox",
      project: "notify",
      directory: "/work/notify",
      resolveOpenCodeVersion: async () => "1.18.18",
      randomUUID: () => "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
      socketFactory: () => socket,
    });

    channel.start();
    await vi.advanceTimersByTimeAsync(0);
    registeredChannel(socket);
    socket.emit("message", {
      data: JSON.stringify({
        type: "question_answer_command",
        commandId: answerCommandId,
        requestId: "req_1",
        answers: [["Postgres"]],
      }),
    });
    await vi.advanceTimersByTimeAsync(0);

    expect(socket.sent.map((frame) => JSON.parse(frame))).toContainEqual({
      type: "question_answer_result",
      commandId: answerCommandId,
      instanceId: "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
      status: "result_unknown",
    });
  });

  it("reports result_unknown when the answer seam throws", async () => {
    vi.useFakeTimers();
    const socket = new FakeSocket();
    const answerQuestion = vi.fn(async () => {
      throw new Error("sdk exploded");
    });
    const channel = new ControlChannel({
      gatewayUrl: "https://notify.example.com",
      credential: "key-id.key-secret",
      machine: "devbox",
      project: "notify",
      directory: "/work/notify",
      resolveOpenCodeVersion: async () => "1.18.18",
      randomUUID: () => "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
      socketFactory: () => socket,
      answerQuestion,
    });

    channel.start();
    await vi.advanceTimersByTimeAsync(0);
    registeredChannel(socket);
    socket.emit("message", {
      data: JSON.stringify({
        type: "question_answer_command",
        commandId: answerCommandId,
        requestId: "req_1",
        answers: [["Postgres"]],
      }),
    });
    await vi.advanceTimersByTimeAsync(0);

    expect(socket.sent.map((frame) => JSON.parse(frame))).toContainEqual({
      type: "question_answer_result",
      commandId: answerCommandId,
      instanceId: "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
      status: "result_unknown",
    });
  });

  it("aborts the answer seam after the bounded timeout and reports result_unknown", async () => {
    vi.useFakeTimers();
    const socket = new FakeSocket();
    let latestSignal: AbortSignal | undefined;
    const answerQuestion = vi.fn(
      (_requestId: string, _directory: string, _answers: unknown[], signal: AbortSignal) => {
        latestSignal = signal;
        return new Promise<"confirmed">(() => undefined); // hangs forever
      },
    );
    const channel = new ControlChannel({
      gatewayUrl: "https://notify.example.com",
      credential: "key-id.key-secret",
      machine: "devbox",
      project: "notify",
      directory: "/work/notify",
      resolveOpenCodeVersion: async () => "1.18.18",
      randomUUID: () => "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
      answerTimeoutMs: 50,
      socketFactory: () => socket,
      answerQuestion,
    });

    channel.start();
    await vi.advanceTimersByTimeAsync(0);
    registeredChannel(socket);
    socket.emit("message", {
      data: JSON.stringify({
        type: "question_answer_command",
        commandId: answerCommandId,
        requestId: "req_1",
        answers: [["Postgres"]],
      }),
    });
    await vi.advanceTimersByTimeAsync(50);

    expect(latestSignal?.aborted).toBe(true);
    expect(socket.sent.map((frame) => JSON.parse(frame))).toContainEqual({
      type: "question_answer_result",
      commandId: answerCommandId,
      instanceId: "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
      status: "result_unknown",
    });
  });

  it("never leaks answer bodies into the result frame", async () => {
    vi.useFakeTimers();
    const socket = new FakeSocket();
    const answerQuestion = vi.fn(async () => "confirmed" as const);
    const channel = new ControlChannel({
      gatewayUrl: "https://notify.example.com",
      credential: "key-id.key-secret",
      machine: "devbox",
      project: "notify",
      directory: "/work/notify",
      resolveOpenCodeVersion: async () => "1.18.18",
      randomUUID: () => "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
      socketFactory: () => socket,
      answerQuestion,
    });

    channel.start();
    await vi.advanceTimersByTimeAsync(0);
    registeredChannel(socket);
    socket.emit("message", {
      data: JSON.stringify({
        type: "question_answer_command",
        commandId: answerCommandId,
        requestId: "req_1",
        answers: [["SECRET-ANSWER"]],
      }),
    });
    await vi.advanceTimersByTimeAsync(0);

    const frames = socket.sent.map((frame) => JSON.parse(frame));
    const result = frames.find((frame) => frame.type === "question_answer_result");
    expect(result).toEqual({
      type: "question_answer_result",
      commandId: answerCommandId,
      instanceId: "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
      status: "confirmed",
    });
    expect(JSON.stringify(frames)).not.toContain("SECRET-ANSWER");
  });

  const decisionCommandId = "2a4b8d9c-3e5f-4a6b-9c7d-1e2f3a4b5c6d";

  it("answers a permission_decide_command with the stable instanceId and the seam's status", async () => {
    vi.useFakeTimers();
    const socket = new FakeSocket();
    const decidePermission = vi.fn(async () => "confirmed" as const);
    const channel = new ControlChannel({
      gatewayUrl: "https://notify.example.com",
      credential: "key-id.key-secret",
      machine: "devbox",
      project: "notify",
      directory: "/work/notify",
      resolveOpenCodeVersion: async () => "1.18.18",
      randomUUID: () => "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
      socketFactory: () => socket,
      decidePermission,
    });

    channel.start();
    await vi.advanceTimersByTimeAsync(0);
    registeredChannel(socket);
    socket.emit("message", {
      data: JSON.stringify({
        type: "permission_decide_command",
        commandId: decisionCommandId,
        requestId: "per_req_1",
        decision: "once",
      }),
    });
    await vi.advanceTimersByTimeAsync(0);

    expect(decidePermission).toHaveBeenCalledTimes(1);
    expect(socket.sent.map((frame) => JSON.parse(frame))).toContainEqual({
      type: "permission_decide_result",
      commandId: decisionCommandId,
      instanceId: "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
      status: "confirmed",
    });
  });

  it("passes the exact decision, the owning directory, and a bounded signal to the decision seam", async () => {
    vi.useFakeTimers();
    const socket = new FakeSocket();
    const decidePermission = vi.fn(async () => "confirmed" as const);
    const channel = new ControlChannel({
      gatewayUrl: "https://notify.example.com",
      credential: "key-id.key-secret",
      machine: "devbox",
      project: "notify",
      directory: "/work/notify",
      resolveOpenCodeVersion: async () => "1.18.18",
      randomUUID: () => "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
      socketFactory: () => socket,
      decidePermission,
    });

    channel.start();
    await vi.advanceTimersByTimeAsync(0);
    registeredChannel(socket);
    socket.emit("message", {
      data: JSON.stringify({
        type: "permission_decide_command",
        commandId: decisionCommandId,
        requestId: "per_req_1",
        decision: "reject",
      }),
    });
    await vi.advanceTimersByTimeAsync(0);

    expect(decidePermission).toHaveBeenCalledWith(
      "per_req_1",
      "/work/notify",
      "reject",
      expect.any(AbortSignal),
    );
  });

  it("does not coalesce concurrent decision commands with different commandIds", async () => {
    vi.useFakeTimers();
    const socket = new FakeSocket();
    const resolves: Array<() => void> = [];
    const decidePermission = vi.fn(
      () =>
        new Promise<"confirmed">((resolve) => {
          resolves.push(() => resolve("confirmed"));
        }),
    );
    const channel = new ControlChannel({
      gatewayUrl: "https://notify.example.com",
      credential: "key-id.key-secret",
      machine: "devbox",
      project: "notify",
      directory: "/work/notify",
      resolveOpenCodeVersion: async () => "1.18.18",
      randomUUID: () => "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
      socketFactory: () => socket,
      decidePermission,
    });
    const secondCommandId = "3a4b8d9c-3e5f-4a6b-9c7d-1e2f3a4b5c6d";

    channel.start();
    await vi.advanceTimersByTimeAsync(0);
    registeredChannel(socket);
    for (const commandId of [decisionCommandId, secondCommandId]) {
      socket.emit("message", {
        data: JSON.stringify({
          type: "permission_decide_command",
          commandId,
          requestId: "per_req_1",
          decision: "once",
        }),
      });
    }
    await vi.advanceTimersByTimeAsync(0);
    // Each command runs independently: the seam is never coalesced onto one call.
    expect(decidePermission).toHaveBeenCalledTimes(2);

    for (const resolve of resolves) {
      resolve();
    }
    await vi.advanceTimersByTimeAsync(0);
    const results = socket.sent
      .map((frame) => JSON.parse(frame))
      .filter((frame) => frame.type === "permission_decide_result");
    expect(results).toHaveLength(2);
    expect(results.map((result) => result.commandId).sort()).toEqual(
      [decisionCommandId, secondCommandId].sort(),
    );
  });

  it("ignores a permission_decide_command received before registration", async () => {
    vi.useFakeTimers();
    const socket = new FakeSocket();
    const decidePermission = vi.fn(async () => "confirmed" as const);
    const channel = new ControlChannel({
      gatewayUrl: "https://notify.example.com",
      credential: "key-id.key-secret",
      machine: "devbox",
      project: "notify",
      directory: "/work/notify",
      resolveOpenCodeVersion: async () => "1.18.18",
      randomUUID: () => "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
      socketFactory: () => socket,
      decidePermission,
    });

    channel.start();
    await vi.advanceTimersByTimeAsync(0);
    socket.emit("open");
    socket.emit("message", {
      data: JSON.stringify({
        type: "permission_decide_command",
        commandId: decisionCommandId,
        requestId: "per_req_1",
        decision: "once",
      }),
    });
    await vi.advanceTimersByTimeAsync(0);

    expect(decidePermission).not.toHaveBeenCalled();
    expect(socket.sent.map((frame) => JSON.parse(frame))).not.toContainEqual(
      expect.objectContaining({ type: "permission_decide_result" }),
    );
  });

  it("ignores malformed permission_decide_command frames without killing notification behavior", async () => {
    vi.useFakeTimers();
    const socket = new FakeSocket();
    const decidePermission = vi.fn(async () => "confirmed" as const);
    const channel = new ControlChannel({
      gatewayUrl: "https://notify.example.com",
      credential: "key-id.key-secret",
      machine: "devbox",
      project: "notify",
      directory: "/work/notify",
      resolveOpenCodeVersion: async () => "1.18.18",
      randomUUID: () => "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
      socketFactory: () => socket,
      decidePermission,
    });

    channel.start();
    await vi.advanceTimersByTimeAsync(0);
    registeredChannel(socket);

    const valid = {
      type: "permission_decide_command",
      commandId: decisionCommandId,
      requestId: "per_req_1",
      decision: "once",
    };
    const garbage: Record<string, unknown>[] = [
      { ...valid, commandId: "cmd_1" },
      { ...valid, commandId: "" },
      { ...valid, commandId: 7 },
      { ...valid, requestId: "" },
      { ...valid, requestId: 7 },
      { ...valid, decision: "always" },
      { ...valid, decision: "" },
      { ...valid, decision: 1 },
      { ...valid, decision: null },
      { ...valid, decision: undefined },
      { type: "permission_decide_command", commandId: decisionCommandId, requestId: "per_req_1" },
      { type: "permission_decide_command", commandId: decisionCommandId, decision: "once" },
      { type: "permission_decide_command" },
    ];
    for (const frame of garbage) {
      socket.emit("message", { data: JSON.stringify(frame) });
    }
    await vi.advanceTimersByTimeAsync(60_000);

    expect(decidePermission).not.toHaveBeenCalled();
    expect(socket.sent.map((frame) => JSON.parse(frame))).not.toContainEqual(
      expect.objectContaining({ type: "permission_decide_result" }),
    );

    // The channel stays alive and still answers a well-formed command.
    socket.emit("message", { data: JSON.stringify(valid) });
    await vi.advanceTimersByTimeAsync(0);
    expect(decidePermission).toHaveBeenCalledTimes(1);
    expect(socket.sent.map((frame) => JSON.parse(frame))).toContainEqual(
      expect.objectContaining({
        type: "permission_decide_result",
        commandId: decisionCommandId,
        status: "confirmed",
      }),
    );
  });

  it("reports result_unknown when no decision seam is configured", async () => {
    vi.useFakeTimers();
    const socket = new FakeSocket();
    const channel = new ControlChannel({
      gatewayUrl: "https://notify.example.com",
      credential: "key-id.key-secret",
      machine: "devbox",
      project: "notify",
      directory: "/work/notify",
      resolveOpenCodeVersion: async () => "1.18.18",
      randomUUID: () => "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
      socketFactory: () => socket,
    });

    channel.start();
    await vi.advanceTimersByTimeAsync(0);
    registeredChannel(socket);
    socket.emit("message", {
      data: JSON.stringify({
        type: "permission_decide_command",
        commandId: decisionCommandId,
        requestId: "per_req_1",
        decision: "once",
      }),
    });
    await vi.advanceTimersByTimeAsync(0);

    expect(socket.sent.map((frame) => JSON.parse(frame))).toContainEqual({
      type: "permission_decide_result",
      commandId: decisionCommandId,
      instanceId: "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
      status: "result_unknown",
    });
  });

  it("reports result_unknown when the decision seam throws", async () => {
    vi.useFakeTimers();
    const socket = new FakeSocket();
    const decidePermission = vi.fn(async () => {
      throw new Error("sdk exploded");
    });
    const channel = new ControlChannel({
      gatewayUrl: "https://notify.example.com",
      credential: "key-id.key-secret",
      machine: "devbox",
      project: "notify",
      directory: "/work/notify",
      resolveOpenCodeVersion: async () => "1.18.18",
      randomUUID: () => "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
      socketFactory: () => socket,
      decidePermission,
    });

    channel.start();
    await vi.advanceTimersByTimeAsync(0);
    registeredChannel(socket);
    socket.emit("message", {
      data: JSON.stringify({
        type: "permission_decide_command",
        commandId: decisionCommandId,
        requestId: "per_req_1",
        decision: "reject",
      }),
    });
    await vi.advanceTimersByTimeAsync(0);

    expect(socket.sent.map((frame) => JSON.parse(frame))).toContainEqual({
      type: "permission_decide_result",
      commandId: decisionCommandId,
      instanceId: "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
      status: "result_unknown",
    });
  });

  it("aborts the decision seam after the bounded timeout and reports result_unknown", async () => {
    vi.useFakeTimers();
    const socket = new FakeSocket();
    let latestSignal: AbortSignal | undefined;
    const decidePermission = vi.fn(
      (_requestId: string, _directory: string, _decision: unknown, signal: AbortSignal) => {
        latestSignal = signal;
        return new Promise<"confirmed">(() => undefined); // hangs forever
      },
    );
    const channel = new ControlChannel({
      gatewayUrl: "https://notify.example.com",
      credential: "key-id.key-secret",
      machine: "devbox",
      project: "notify",
      directory: "/work/notify",
      resolveOpenCodeVersion: async () => "1.18.18",
      randomUUID: () => "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
      decideTimeoutMs: 50,
      socketFactory: () => socket,
      decidePermission,
    });

    channel.start();
    await vi.advanceTimersByTimeAsync(0);
    registeredChannel(socket);
    socket.emit("message", {
      data: JSON.stringify({
        type: "permission_decide_command",
        commandId: decisionCommandId,
        requestId: "per_req_1",
        decision: "once",
      }),
    });
    await vi.advanceTimersByTimeAsync(50);

    expect(latestSignal?.aborted).toBe(true);
    expect(socket.sent.map((frame) => JSON.parse(frame))).toContainEqual({
      type: "permission_decide_result",
      commandId: decisionCommandId,
      instanceId: "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
      status: "result_unknown",
    });
  });

  it("never leaks decision bodies into the result frame", async () => {
    vi.useFakeTimers();
    const socket = new FakeSocket();
    const decidePermission = vi.fn(async () => "confirmed" as const);
    const channel = new ControlChannel({
      gatewayUrl: "https://notify.example.com",
      credential: "key-id.key-secret",
      machine: "devbox",
      project: "notify",
      directory: "/work/notify",
      resolveOpenCodeVersion: async () => "1.18.18",
      randomUUID: () => "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
      socketFactory: () => socket,
      decidePermission,
    });

    channel.start();
    await vi.advanceTimersByTimeAsync(0);
    registeredChannel(socket);
    socket.emit("message", {
      data: JSON.stringify({
        type: "permission_decide_command",
        commandId: decisionCommandId,
        requestId: "per_req_1",
        decision: "once",
      }),
    });
    await vi.advanceTimersByTimeAsync(0);

    const frames = socket.sent.map((frame) => JSON.parse(frame));
    const result = frames.find((frame) => frame.type === "permission_decide_result");
    expect(result).toEqual({
      type: "permission_decide_result",
      commandId: decisionCommandId,
      instanceId: "6f0d91b0-93e4-43a9-9449-0bed03e651aa",
      status: "confirmed",
    });
    expect(JSON.stringify(frames)).not.toContain("per_req_1");
  });
});
