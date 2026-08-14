import { afterEach, describe, expect, it, vi } from "vitest";

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
});
