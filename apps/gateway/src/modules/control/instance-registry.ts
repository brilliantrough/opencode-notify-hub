import {
  validatePluginControlClientMessage,
  type InstancePresence,
  type PluginControlClientMessage,
  type PluginControlServerMessage,
  type WsServerMessage,
} from "@notify/contracts";

import type { Clock } from "../../lib/clock.js";
import type { VerifiedIngestKey } from "../ingest-keys/ingest-keys.service.js";
import {
  WS_CLOSE_SERVER_SHUTDOWN,
  WS_MAX_BUFFERED_BYTES,
  WS_PING_INTERVAL_MS,
  type RealtimeSocket,
} from "../realtime/connection-registry.js";

export const CONTROL_CLOSE_INVALID_FRAME = 4400;
export const CONTROL_CLOSE_KEY_REVOKED = 4403;

const READY_OPEN = 1;
const SUPPORTED_OPENCODE_VERSION = "1.18.18";
const SUPPORTED_PROTOCOL_VERSION = 1;

interface ControlConnection {
  readonly auth: VerifiedIngestKey;
  readonly socket: RealtimeSocket;
  alive: boolean;
  heartbeat: NodeJS.Timeout;
  instanceId?: string;
}

interface InstanceRecord {
  readonly registration: PluginControlClientMessage;
  readonly userId: string;
  readonly sequence: number;
  state: InstancePresence["state"];
  lastSeenAt: string;
  connection?: ControlConnection;
}

export interface InstanceRegistryDeps {
  clock: Clock;
  publish(userId: string, message: WsServerMessage): void;
  pingIntervalMs?: number;
}

/** In-memory owner-scoped projection of Plugin control connections. */
export class InstanceRegistry {
  private readonly records = new Map<string, InstanceRecord>();
  private readonly ownership = new Map<string, string>();
  private readonly connections = new Set<ControlConnection>();
  private readonly clock: Clock;
  private readonly publish: InstanceRegistryDeps["publish"];
  private readonly pingIntervalMs: number;
  private nextSequence = 0;

  constructor(deps: InstanceRegistryDeps) {
    this.clock = deps.clock;
    this.publish = deps.publish;
    this.pingIntervalMs = deps.pingIntervalMs ?? WS_PING_INTERVAL_MS;
  }

  add(auth: VerifiedIngestKey, socket: RealtimeSocket): void {
    const connection: ControlConnection = {
      auth,
      socket,
      alive: true,
      heartbeat: setInterval(() => {
        if (socket.readyState !== READY_OPEN) {
          this.disconnect(connection);
          return;
        }
        if (!connection.alive) {
          this.disconnect(connection);
          socket.terminate();
          return;
        }
        connection.alive = false;
        socket.ping();
      }, this.pingIntervalMs),
    };
    const markAlive = () => {
      connection.alive = true;
      this.touch(connection);
    };
    socket.on("pong", markAlive);
    socket.on("ping", markAlive);
    socket.on("message", (...args: unknown[]) => this.receive(connection, args[0]));
    socket.on("close", () => this.disconnect(connection));
    socket.on("error", () => this.disconnect(connection));
    this.connections.add(connection);
  }

  publishSnapshot(userId: string): void {
    const instances = [...this.records.values()]
      .filter((record) => record.userId === userId)
      .sort((left, right) => left.sequence - right.sequence)
      .map((record) => this.toPresence(record));
    if (instances.length > 0) {
      this.publish(userId, { type: "instance_presence", instances });
    }
  }

  revokeKey(ingestKeyId: string): void {
    for (const connection of [...this.connections]) {
      if (connection.auth.id !== ingestKeyId) {
        continue;
      }
      this.disconnect(connection);
      connection.socket.close(CONTROL_CLOSE_KEY_REVOKED, "Plugin key revoked");
    }
  }

  closeAll(): void {
    for (const connection of [...this.connections]) {
      this.disconnect(connection);
      connection.socket.close(WS_CLOSE_SERVER_SHUTDOWN, "server shutting down");
    }
  }

  private receive(connection: ControlConnection, raw: unknown): void {
    connection.alive = true;
    const value = this.decode(raw);
    if (value === null || !validatePluginControlClientMessage(value)) {
      this.disconnect(connection);
      connection.socket.close(CONTROL_CLOSE_INVALID_FRAME, "invalid control frame");
      return;
    }
    if (connection.instanceId !== undefined) {
      this.disconnect(connection);
      connection.socket.close(CONTROL_CLOSE_INVALID_FRAME, "already registered");
      return;
    }
    this.register(connection, value as PluginControlClientMessage);
  }

  private register(
    connection: ControlConnection,
    registration: PluginControlClientMessage,
  ): void {
    const recordKey = this.recordKey(connection.auth.userId, registration.instanceId);
    const existing = this.records.get(recordKey);
    if (existing?.connection !== undefined && existing.connection !== connection) {
      this.disconnect(existing.connection);
      existing.connection.socket.close(CONTROL_CLOSE_INVALID_FRAME, "instance replaced");
    }

    connection.instanceId = registration.instanceId;
    const compatible =
      registration.openCodeVersion === SUPPORTED_OPENCODE_VERSION &&
      registration.protocolVersion === SUPPORTED_PROTOCOL_VERSION;
    const ownershipKey = this.ownershipKey(connection.auth.userId, registration);
    this.pruneOfflineOwnership(
      connection.auth.userId,
      ownershipKey,
      registration.instanceId,
    );
    const owner = this.ownership.get(ownershipKey);
    const state: InstanceRecord["state"] = !compatible
      ? "incompatible"
      : owner === undefined || owner === registration.instanceId
        ? "controllable"
        : "conflicting";
    if (state === "controllable") {
      this.ownership.set(ownershipKey, registration.instanceId);
    }

    const record: InstanceRecord = {
      registration,
      userId: connection.auth.userId,
      sequence: existing?.sequence ?? this.nextSequence++,
      state,
      lastSeenAt: this.clock.now().toISOString(),
      connection,
    };
    this.records.set(recordKey, record);
    this.send(connection, {
      type: "registration",
      instanceId: registration.instanceId,
      state,
    });
    this.publishSnapshot(record.userId);
  }

  private disconnect(connection: ControlConnection): void {
    if (!this.connections.delete(connection)) {
      return;
    }
    clearInterval(connection.heartbeat);
    const instanceId = connection.instanceId;
    if (instanceId === undefined) {
      return;
    }
    const record = this.records.get(this.recordKey(connection.auth.userId, instanceId));
    if (record === undefined || record.connection !== connection) {
      return;
    }
    record.connection = undefined;
    const wasControllable = record.state === "controllable";
    record.state = "offline";
    record.lastSeenAt = this.clock.now().toISOString();
    if (wasControllable) {
      const ownershipKey = this.ownershipKey(record.userId, record.registration);
      if (this.ownership.get(ownershipKey) === instanceId) {
        this.ownership.delete(ownershipKey);
        this.promote(ownershipKey, record.userId);
      }
    }
    this.publishSnapshot(record.userId);
  }

  private promote(ownershipKey: string, userId: string): void {
    const candidate = [...this.records.values()]
      .filter(
        (record) =>
          record.userId === userId &&
          record.state === "conflicting" &&
          record.connection !== undefined &&
          this.ownershipKey(record.userId, record.registration) === ownershipKey,
      )
      .sort((left, right) => left.sequence - right.sequence)[0];
    if (candidate === undefined) {
      return;
    }
    candidate.state = "controllable";
    candidate.lastSeenAt = this.clock.now().toISOString();
    this.ownership.set(ownershipKey, candidate.registration.instanceId);
    this.send(candidate.connection!, {
      type: "registration",
      instanceId: candidate.registration.instanceId,
      state: "controllable",
    });
  }

  private touch(connection: ControlConnection): void {
    if (connection.instanceId === undefined) {
      return;
    }
    const record = this.records.get(
      this.recordKey(connection.auth.userId, connection.instanceId),
    );
    if (record?.connection === connection) {
      record.lastSeenAt = this.clock.now().toISOString();
    }
  }

  private send(connection: ControlConnection, message: PluginControlServerMessage): void {
    if (
      connection.socket.readyState !== READY_OPEN ||
      connection.socket.bufferedAmount > WS_MAX_BUFFERED_BYTES
    ) {
      this.disconnect(connection);
      connection.socket.terminate();
      return;
    }
    try {
      connection.socket.send(JSON.stringify(message), (error?: Error | null) => {
        if (error != null) {
          this.disconnect(connection);
        }
      });
    } catch {
      this.disconnect(connection);
    }
  }

  private toPresence(record: InstanceRecord): InstancePresence {
    return {
      instanceId: record.registration.instanceId,
      machine: record.registration.machine,
      project: record.registration.project,
      directory: record.registration.directory,
      openCodeVersion: record.registration.openCodeVersion,
      protocolVersion: record.registration.protocolVersion,
      state: record.state,
      lastSeenAt: record.lastSeenAt,
    };
  }

  private ownershipKey(userId: string, registration: PluginControlClientMessage): string {
    const machine = registration.machine.trim().toLocaleLowerCase("en-US");
    let directory = registration.directory.trim().replaceAll("\\", "/").replace(/\/{2,}/g, "/");
    if (directory.length > 1) {
      directory = directory.replace(/\/$/, "");
    }
    if (/^[A-Za-z]:\//.test(directory)) {
      directory = directory.toLocaleLowerCase("en-US");
    }
    return `${userId}\u0000${machine}\u0000${directory}`;
  }

  private recordKey(userId: string, instanceId: string): string {
    return `${userId}\u0000${instanceId}`;
  }

  private pruneOfflineOwnership(
    userId: string,
    ownershipKey: string,
    exceptInstanceId: string,
  ): void {
    for (const [key, record] of this.records) {
      if (
        record.userId === userId &&
        record.registration.instanceId !== exceptInstanceId &&
        record.state === "offline" &&
        this.ownershipKey(userId, record.registration) === ownershipKey
      ) {
        this.records.delete(key);
      }
    }
  }

  private decode(raw: unknown): unknown | null {
    const text =
      typeof raw === "string"
        ? raw
        : Buffer.isBuffer(raw)
          ? raw.toString("utf8")
          : raw instanceof ArrayBuffer
            ? Buffer.from(raw).toString("utf8")
            : null;
    if (text === null) {
      return null;
    }
    try {
      return JSON.parse(text) as unknown;
    } catch {
      return null;
    }
  }
}
