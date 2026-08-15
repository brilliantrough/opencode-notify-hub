import { randomUUID } from "node:crypto";

import {
  validatePluginControlClientMessage,
  type InstancePresence,
  type PendingInteraction,
  type PendingSnapshot,
  type PermissionCommandResult,
  type PermissionDecision,
  type PluginControlClientMessage,
  type PluginControlServerMessage,
  type QuestionAnswers,
  type QuestionCommandResult,
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
export const CONTROL_MAX_FRAME_BYTES = 1024 * 1024;

/**
 * Default per-instance wait for a `pending_snapshot_response` during a
 * pending-interactions collection (issue #8). Injectable through
 * {@link InstanceRegistryDeps.snapshotTimeoutMs}; tests shrink it.
 */
export const PENDING_SNAPSHOT_TIMEOUT_MS = 2500;

/**
 * Default bounded wait for the terminal `question_answer_result` after the
 * gateway routes one answer command (issue #9). Injectable through
 * {@link InstanceRegistryDeps.answerTimeoutMs}; tests shrink it. On timeout
 * the command settles as result_unknown, never an error.
 */
export const ANSWER_TIMEOUT_MS = 10_000;

/**
 * Ceiling on remembered stale request ids per instance. Stale ids only
 * distinguish a 409 from a 404 for a short window; the bound keeps the
 * per-instance memory constant regardless of request churn.
 */
export const MAX_STALE_REQUEST_IDS = 256;

const READY_OPEN = 1;
const SUPPORTED_OPENCODE_VERSION = "1.18.18";
const SUPPORTED_PROTOCOL_VERSION = 1;

/** The `register` member of the extended Plugin control client protocol. */
type RegisterMessage = Extract<PluginControlClientMessage, { type: "register" }>;

type PendingSnapshotResponse = Extract<
  PluginControlClientMessage,
  { type: "pending_snapshot_response" }
>;

interface ControlConnection {
  readonly auth: VerifiedIngestKey;
  readonly socket: RealtimeSocket;
  readonly uid: number;
  alive: boolean;
  heartbeat: NodeJS.Timeout;
  instanceId?: string;
}

interface InstanceRecord {
  readonly registration: RegisterMessage;
  readonly userId: string;
  readonly sequence: number;
  state: InstancePresence["state"];
  lastSeenAt: string;
  connection?: ControlConnection;
  /**
   * Issue #9: requestId -> interaction kind projection of the last accepted
   * `pending_snapshot_response` (request ids only, never bodies). Answering
   * is authorized only against this projection, so a Plugin cannot make a
   * request answerable that it never reported pending.
   */
  readonly projectedRequests: Map<string, PendingInteraction["kind"]>;
  /**
   * Request ids that were projected but are no longer pending (removed by a
   * newer snapshot or by a confirmed answer command). Answering one of these
   * is a stale conflict (409), distinct from an id that was never projected
   * (404). Bounded by {@link MAX_STALE_REQUEST_IDS}.
   */
  readonly staleRequests: Map<string, number>;
}

/** One outstanding `pending_snapshot_request` awaiting its response. */
interface PendingSnapshotRequest {
  readonly connection: ControlConnection;
  readonly requestId: string;
  /** Authoritative source identity from the registered record (enrichment). */
  readonly registration: RegisterMessage;
  readonly timer: NodeJS.Timeout;
  readonly resolve: (interactions: PendingInteraction[]) => void;
}

/** One outstanding `question_answer_command` awaiting its terminal result. */
interface PendingAnswerCommand {
  readonly connection: ControlConnection;
  readonly requestId: string;
  readonly commandId: string;
  readonly timer: NodeJS.Timeout;
  readonly resolve: (result: QuestionCommandResult) => void;
}

type QuestionAnswerResultMessage = Extract<
  PluginControlClientMessage,
  { type: "question_answer_result" }
>;

/** One outstanding `permission_decide_command` awaiting its terminal result. */
interface PendingDecideCommand {
  readonly connection: ControlConnection;
  readonly requestId: string;
  readonly commandId: string;
  readonly timer: NodeJS.Timeout;
  readonly resolve: (result: PermissionCommandResult) => void;
}

type PermissionDecideResultMessage = Extract<
  PluginControlClientMessage,
  { type: "permission_decide_result" }
>;

export interface InstanceRegistryDeps {
  clock: Clock;
  publish(userId: string, message: WsServerMessage): void;
  pingIntervalMs?: number;
  /** Defaults to {@link PENDING_SNAPSHOT_TIMEOUT_MS}; tests inject a short wait. */
  snapshotTimeoutMs?: number;
  /** Defaults to {@link ANSWER_TIMEOUT_MS}; tests inject a short wait. */
  answerTimeoutMs?: number;
}

/**
 * A rejected answer command. `not_found` covers unknown instances, foreign
 * accounts, offline/conflicting/incompatible records, and request ids that
 * were never projected; `conflict` covers stale requests and the wrong
 * interaction kind. The route maps them to the uniform 404/409 responses.
 */
export type AnswerQuestionError =
  | { readonly code: "not_found" }
  | { readonly code: "conflict" };

export type AnswerQuestionOutcome =
  | { readonly ok: false; readonly error: AnswerQuestionError }
  | { readonly ok: true; readonly result: QuestionCommandResult };

/**
 * A rejected decision command. The codes mirror {@link AnswerQuestionError}:
 * `not_found` covers unknown instances, foreign accounts,
 * offline/conflicting/incompatible records, and request ids that were never
 * projected; `conflict` covers stale requests, the wrong interaction kind,
 * and a second in-flight decision on the same connection. The route maps
 * them to the uniform 404/409 responses.
 */
export type DecidePermissionError =
  | { readonly code: "not_found" }
  | { readonly code: "conflict" };

export type DecidePermissionOutcome =
  | { readonly ok: false; readonly error: DecidePermissionError }
  | { readonly ok: true; readonly result: PermissionCommandResult };

/**
 * In-memory owner-scoped projection of Plugin control connections. Owns
 * registration rules (first machine/project owner wins, incompatible and
 * conflicting instances are not actionable) and the owner-scoped read-only
 * pending-interaction collection: only connected `controllable` instances of
 * one user are ever queried, responses are accepted only after registration
 * and only for the exact requestId+connection+instanceId that was issued,
 * and every query settles after {@link PENDING_SNAPSHOT_TIMEOUT_MS} (partial
 * snapshot on timeouts). Issue #9 adds owner-scoped answer routing: a command
 * is accepted only for a projected pending question of a connected
 * `controllable` own record, is correlated by connection+commandId, and
 * settles under {@link ANSWER_TIMEOUT_MS}. Issue #10 adds owner-scoped
 * decision routing for pending permissions under the same gate and timeout:
 * a decision command is accepted only for a projected pending `permission`
 * of a connected `controllable` own record, is correlated by
 * connection+commandId, and a confirmed decision removes the projected
 * request. Late or unknown responses and results are ignored; malformed
 * frames and registration violations still close the control connection.
 */
export class InstanceRegistry {
  private readonly records = new Map<string, InstanceRecord>();
  private readonly ownership = new Map<string, string>();
  private readonly connections = new Set<ControlConnection>();
  private readonly pendingRequests = new Map<string, PendingSnapshotRequest>();
  private readonly pendingAnswerCommands = new Map<string, PendingAnswerCommand>();
  private readonly pendingDecideCommands = new Map<string, PendingDecideCommand>();
  private readonly clock: Clock;
  private readonly publish: InstanceRegistryDeps["publish"];
  private readonly pingIntervalMs: number;
  private readonly snapshotTimeoutMs: number;
  private readonly answerTimeoutMs: number;
  private nextSequence = 0;
  private nextConnectionUid = 0;

  constructor(deps: InstanceRegistryDeps) {
    this.clock = deps.clock;
    this.publish = deps.publish;
    this.pingIntervalMs = deps.pingIntervalMs ?? WS_PING_INTERVAL_MS;
    this.snapshotTimeoutMs = deps.snapshotTimeoutMs ?? PENDING_SNAPSHOT_TIMEOUT_MS;
    this.answerTimeoutMs = deps.answerTimeoutMs ?? ANSWER_TIMEOUT_MS;
  }

  add(auth: VerifiedIngestKey, socket: RealtimeSocket): void {
    const connection: ControlConnection = {
      auth,
      socket,
      uid: this.nextConnectionUid++,
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

  /**
   * Issue #8: collect a read-only pending-interaction snapshot for one user.
   * Only connected, `controllable` instances of the user are queried; every
   * other account's instances are invisible. Each instance gets its own UUID
   * correlation and settles after {@link PENDING_SNAPSHOT_TIMEOUT_MS}, so the
   * result is a partial 200 snapshot when some instances never answer.
   * Interaction source identity (instanceId/machine/project/directory) is
   * always overwritten from the registered record, never trusted from the
   * wire.
   */
  async collectPendingInteractions(userId: string): Promise<PendingSnapshot> {
    const targets = [...this.records.values()].filter(
      (record) =>
        record.userId === userId &&
        record.state === "controllable" &&
        record.connection !== undefined &&
        record.connection.socket.readyState === READY_OPEN,
    );
    if (targets.length === 0) {
      return { generatedAt: this.clock.now().toISOString(), interactions: [] };
    }
    const batches = await Promise.all(
      targets.map((record) => this.queryPendingSnapshot(record)),
    );
    return {
      generatedAt: this.clock.now().toISOString(),
      interactions: batches.flat(),
    };
  }

  /**
   * Issue #9: route one client answer command to the owning Plugin instance
   * and await its terminal result. Only a connected, `controllable` record
   * of the authenticated user whose projection shows a pending `question`
   * for `requestId` is actionable; unknown instances, foreign accounts,
   * offline/conflicting/incompatible records, and request ids that were
   * never projected answer the uniform `not_found`, while stale requests
   * and the wrong interaction kind answer `conflict`. The command is
   * correlated by connection+commandId and sent verbatim; it settles under
   * {@link ANSWER_TIMEOUT_MS}, and a timeout or a disconnect resolves as
   * result_unknown, never as an error.
   */
  async answerQuestion(
    userId: string,
    instanceId: string,
    requestId: string,
    commandId: string,
    answers: QuestionAnswers,
  ): Promise<AnswerQuestionOutcome> {
    const record = this.records.get(this.recordKey(userId, instanceId));
    if (
      record === undefined ||
      record.userId !== userId ||
      record.state !== "controllable" ||
      record.connection === undefined ||
      record.connection.socket.readyState !== READY_OPEN
    ) {
      return { ok: false, error: { code: "not_found" } };
    }
    const projected = record.projectedRequests.get(requestId);
    if (projected === undefined) {
      return record.staleRequests.has(requestId)
        ? { ok: false, error: { code: "conflict" } }
        : { ok: false, error: { code: "not_found" } };
    }
    if (projected !== "question") {
      return { ok: false, error: { code: "conflict" } };
    }

    const connection = record.connection;
    for (const pending of this.pendingAnswerCommands.values()) {
      if (
        pending.connection === connection &&
        (pending.requestId === requestId || pending.commandId === commandId)
      ) {
        return { ok: false, error: { code: "conflict" } };
      }
    }
    const result = await new Promise<QuestionCommandResult>((resolve) => {
      const key = this.commandKey(connection, commandId);
      const entry: PendingAnswerCommand = {
        connection,
        requestId,
        commandId,
        timer: setTimeout(() => {
          this.pendingAnswerCommands.delete(key);
          resolve({ commandId, status: "result_unknown" });
        }, this.answerTimeoutMs),
        resolve,
      };
      this.pendingAnswerCommands.set(key, entry);
      this.send(connection, { type: "question_answer_command", commandId, requestId, answers });
    });
    return { ok: true, result };
  }

  /**
   * Issue #10: route one client permission decision to the owning Plugin
   * instance and await its terminal result. Mirrors {@link answerQuestion}
   * against the same pending projection, but the projected interaction must
   * be a `permission` (answering a question is a different route and a
   * `conflict` here). Unknown instances, foreign accounts,
   * offline/conflicting/incompatible records, and request ids that were
   * never projected answer the uniform `not_found`; stale requests, the
   * wrong interaction kind, and a second in-flight decision for the same
   * `requestId` or `commandId` on the same connection answer `conflict`. The
   * command is correlated by connection+commandId and sent verbatim; it
   * settles under {@link ANSWER_TIMEOUT_MS}, and a timeout or a disconnect
   * resolves as result_unknown, never as an error. A confirmed decision
   * removes the projected request (the same state transition as a confirmed
   * answer), so a repeat decision for it is stale.
   */
  async decidePermission(
    userId: string,
    instanceId: string,
    requestId: string,
    commandId: string,
    decision: PermissionDecision,
  ): Promise<DecidePermissionOutcome> {
    const record = this.records.get(this.recordKey(userId, instanceId));
    if (
      record === undefined ||
      record.userId !== userId ||
      record.state !== "controllable" ||
      record.connection === undefined ||
      record.connection.socket.readyState !== READY_OPEN
    ) {
      return { ok: false, error: { code: "not_found" } };
    }
    const projected = record.projectedRequests.get(requestId);
    if (projected === undefined) {
      return record.staleRequests.has(requestId)
        ? { ok: false, error: { code: "conflict" } }
        : { ok: false, error: { code: "not_found" } };
    }
    if (projected !== "permission") {
      return { ok: false, error: { code: "conflict" } };
    }

    const connection = record.connection;
    for (const pending of this.pendingDecideCommands.values()) {
      if (
        pending.connection === connection &&
        (pending.requestId === requestId || pending.commandId === commandId)
      ) {
        return { ok: false, error: { code: "conflict" } };
      }
    }
    const result = await new Promise<PermissionCommandResult>((resolve) => {
      const key = this.commandKey(connection, commandId);
      const entry: PendingDecideCommand = {
        connection,
        requestId,
        commandId,
        timer: setTimeout(() => {
          this.pendingDecideCommands.delete(key);
          resolve({ commandId, status: "result_unknown" });
        }, this.answerTimeoutMs),
        resolve,
      };
      this.pendingDecideCommands.set(key, entry);
      this.send(connection, {
        type: "permission_decide_command",
        commandId,
        requestId,
        decision,
      });
    });
    return { ok: true, result };
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
    const message = value as PluginControlClientMessage;
    if (message.type === "pending_snapshot_response") {
      // Validated snapshot answers are not registration traffic: unknown,
      // late, or foreign responses are ignored, never a connection error.
      this.handleSnapshotResponse(connection, message);
      return;
    }
    if (message.type === "question_answer_result") {
      // Validated command results are not registration traffic: unknown,
      // late, or foreign results are ignored, never a connection error.
      this.handleQuestionAnswerResult(connection, message);
      return;
    }
    if (message.type === "permission_decide_result") {
      // Validated decision results are not registration traffic: unknown,
      // late, or foreign results are ignored, never a connection error.
      this.handlePermissionDecideResult(connection, message);
      return;
    }
    if (connection.instanceId !== undefined) {
      this.disconnect(connection);
      connection.socket.close(CONTROL_CLOSE_INVALID_FRAME, "already registered");
      return;
    }
    this.register(connection, message as RegisterMessage);
  }

  private queryPendingSnapshot(record: InstanceRecord): Promise<PendingInteraction[]> {
    const connection = record.connection as ControlConnection;
    const requestId = randomUUID();
    return new Promise<PendingInteraction[]>((resolve) => {
      const entry: PendingSnapshotRequest = {
        connection,
        requestId,
        registration: record.registration,
        timer: setTimeout(() => {
          this.pendingRequests.delete(this.pendingKey(connection, requestId));
          resolve([]);
        }, this.snapshotTimeoutMs),
        resolve,
      };
      this.pendingRequests.set(this.pendingKey(connection, requestId), entry);
      this.send(connection, { type: "pending_snapshot_request", requestId });
    });
  }

  private handleSnapshotResponse(
    connection: ControlConnection,
    message: PendingSnapshotResponse,
  ): void {
    if (connection.instanceId === undefined) {
      // A response before registration cannot be correlated to anything.
      return;
    }
    if (message.instanceId !== connection.instanceId) {
      // The frame names an instance this connection does not own: ignore.
      return;
    }
    const key = this.pendingKey(connection, message.requestId);
    const pending = this.pendingRequests.get(key);
    if (pending === undefined) {
      // Unknown, already-settled (late), or duplicate requestId: ignore.
      return;
    }
    this.pendingRequests.delete(key);
    clearTimeout(pending.timer);
    const record = this.records.get(
      this.recordKey(connection.auth.userId, connection.instanceId),
    );
    if (record?.connection === connection) {
      // The projection always tracks the latest authoritative pending set,
      // so request ids that disappeared were resolved upstream.
      this.applyProjection(record, message.interactions);
    }
    pending.resolve(
      message.interactions.map((interaction) => this.enrich(interaction, pending.registration)),
    );
  }

  private handleQuestionAnswerResult(
    connection: ControlConnection,
    message: QuestionAnswerResultMessage,
  ): void {
    if (connection.instanceId === undefined) {
      // A result before registration cannot be correlated to anything.
      return;
    }
    if (message.instanceId !== connection.instanceId) {
      // The frame names an instance this connection does not own: ignore.
      return;
    }
    const key = this.commandKey(connection, message.commandId);
    const pending = this.pendingAnswerCommands.get(key);
    if (pending === undefined) {
      // Unknown, already-settled (late), or duplicate commandId: ignore.
      return;
    }
    this.pendingAnswerCommands.delete(key);
    clearTimeout(pending.timer);
    if (message.status === "confirmed") {
      const record = this.records.get(
        this.recordKey(connection.auth.userId, connection.instanceId),
      );
      if (record?.connection === connection) {
        // A confirmed command resolves the request: drop it from the
        // projection and remember it as stale, so concurrent clients that
        // race the same request get a 409 instead of a second command.
        record.projectedRequests.delete(pending.requestId);
        this.rememberStale(record, pending.requestId);
      }
    }
    pending.resolve({ commandId: pending.commandId, status: message.status });
  }

  private handlePermissionDecideResult(
    connection: ControlConnection,
    message: PermissionDecideResultMessage,
  ): void {
    if (connection.instanceId === undefined) {
      // A result before registration cannot be correlated to anything.
      return;
    }
    if (message.instanceId !== connection.instanceId) {
      // The frame names an instance this connection does not own: ignore.
      return;
    }
    const key = this.commandKey(connection, message.commandId);
    const pending = this.pendingDecideCommands.get(key);
    if (pending === undefined) {
      // Unknown, already-settled (late), or duplicate commandId: ignore.
      return;
    }
    this.pendingDecideCommands.delete(key);
    clearTimeout(pending.timer);
    if (message.status === "confirmed") {
      const record = this.records.get(
        this.recordKey(connection.auth.userId, connection.instanceId),
      );
      if (record?.connection === connection) {
        // A confirmed decision resolves the request exactly like a confirmed
        // answer: drop it from the projection and remember it as stale.
        record.projectedRequests.delete(pending.requestId);
        this.rememberStale(record, pending.requestId);
      }
    }
    pending.resolve({ commandId: pending.commandId, status: message.status });
  }

  /**
   * Replace the record's requestId -> kind projection with the interactions
   * of one accepted snapshot. Ids that are no longer present were resolved
   * upstream and become stale (a later answer is a 409 conflict), so the
   * projection always mirrors the most recent authoritative pending set.
   */
  private applyProjection(
    record: InstanceRecord,
    interactions: PendingInteraction[],
  ): void {
    const incoming = new Map<string, PendingInteraction["kind"]>();
    for (const interaction of interactions) {
      incoming.set(interaction.requestId, interaction.kind);
    }
    for (const requestId of record.projectedRequests.keys()) {
      if (!incoming.has(requestId)) {
        this.rememberStale(record, requestId);
      }
    }
    record.projectedRequests.clear();
    for (const [requestId, kind] of incoming) {
      record.projectedRequests.set(requestId, kind);
    }
  }

  /** Remember a request id that stopped being pending, bounded in size. */
  private rememberStale(record: InstanceRecord, requestId: string): void {
    record.staleRequests.set(requestId, this.clock.nowMs());
    while (record.staleRequests.size > MAX_STALE_REQUEST_IDS) {
      const oldest = record.staleRequests.keys().next().value;
      if (oldest === undefined) {
        return;
      }
      record.staleRequests.delete(oldest);
    }
  }

  /**
   * Authoritative source enrichment: the interaction's instance/machine/
   * project/directory always come from the registered record, so a Plugin
   * cannot misattribute its pending requests. All other fields (requestId,
   * session, kind, and complete question/permission content) pass through
   * verbatim.
   */
  private enrich(interaction: PendingInteraction, registration: RegisterMessage): PendingInteraction {
    return {
      ...interaction,
      instanceId: registration.instanceId,
      machine: registration.machine,
      project: registration.project,
      directory: registration.directory,
    };
  }

  private register(connection: ControlConnection, registration: RegisterMessage): void {
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
      projectedRequests: new Map(),
      staleRequests: new Map(),
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
    for (const [key, pending] of this.pendingRequests) {
      if (pending.connection === connection) {
        this.pendingRequests.delete(key);
        clearTimeout(pending.timer);
        pending.resolve([]);
      }
    }
    for (const [key, pending] of this.pendingAnswerCommands) {
      if (pending.connection === connection) {
        this.pendingAnswerCommands.delete(key);
        clearTimeout(pending.timer);
        pending.resolve({ commandId: pending.commandId, status: "result_unknown" });
      }
    }
    for (const [key, pending] of this.pendingDecideCommands) {
      if (pending.connection === connection) {
        this.pendingDecideCommands.delete(key);
        clearTimeout(pending.timer);
        pending.resolve({ commandId: pending.commandId, status: "result_unknown" });
      }
    }
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

  private ownershipKey(userId: string, registration: RegisterMessage): string {
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

  private pendingKey(connection: ControlConnection, requestId: string): string {
    return `${connection.uid}\u0000${requestId}`;
  }

  private commandKey(connection: ControlConnection, commandId: string): string {
    return `${connection.uid}\u0000${commandId}`;
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
    if (Buffer.byteLength(text, "utf8") > CONTROL_MAX_FRAME_BYTES) {
      return null;
    }
    try {
      return JSON.parse(text) as unknown;
    } catch {
      return null;
    }
  }
}
