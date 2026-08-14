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
});
