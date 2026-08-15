import { randomUUID as nodeRandomUUID } from "node:crypto";

import type {
  PendingInteraction,
  PluginControlClientMessage,
  QuestionAnswers,
  QuestionCommandStatus,
} from "@notify/contracts";

import type { PendingSource } from "./pending-adapter.js";

export interface ControlSocket {
  addEventListener(event: string, listener: (event?: unknown) => void): void;
  send(data: string): void;
  close(code?: number, reason?: string): void;
}

export interface PluginControl {
  start(): void;
  stop(): void | Promise<void>;
}

type SocketFactory = (url: string, authorization: string) => ControlSocket;

export interface ControlChannelOptions {
  gatewayUrl: string;
  credential: string;
  machine: string;
  project: string;
  directory: string;
  resolveOpenCodeVersion: () => Promise<string>;
  socketFactory?: SocketFactory;
  randomUUID?: () => string;
  random?: () => number;
  versionTimeoutMs?: number;
  /**
   * Injected pending-interaction seam. When set, a `pending_snapshot_request`
   * server frame (after registration) is answered with a
   * `pending_snapshot_response` carrying the channel's stable instanceId.
   * The seam is invoked with the channel's own source identity.
   */
  listPendingInteractions?: (
    source: PendingSource,
    signal: AbortSignal,
  ) => Promise<PendingInteraction[]>;
  /** Bounded time to wait for the injected seam; defaults to 2 seconds. */
  pendingSnapshotTimeoutMs?: number;
  /**
   * Injected question-answer seam. When set, a `question_answer_command`
   * server frame (after registration) is answered with a
   * `question_answer_result` carrying the channel's stable instanceId and
   * the seam's mapped terminal status. The seam receives the exact ordered
   * answer set and the channel's bounded abort signal; it must never
   * throw, so its failures also map to `result_unknown`.
   */
  answerQuestion?: (
    requestId: string,
    directory: string,
    answers: QuestionAnswers,
    signal: AbortSignal,
  ) => Promise<QuestionCommandStatus>;
  /** Bounded time to wait for the injected seam; defaults to 10 seconds. */
  answerTimeoutMs?: number;
}

const BASE_BACKOFF_MS = 500;
const MAX_BACKOFF_MS = 30_000;
const DEFAULT_PENDING_SNAPSHOT_TIMEOUT_MS = 2_000;

/**
 * Bounded wait for one question answer command. Deliberately shorter than
 * the Gateway's `ANSWER_TIMEOUT_MS` (10 seconds, issue #9) so the Plugin
 * aborts its upstream OpenCode reply and reports `result_unknown` before
 * the Gateway gives up and reports a timeout of its own.
 */
const QUESTION_ANSWER_TIMEOUT_MS = 8_000;

/** Never-throw outbound Plugin control connection. */
export class ControlChannel implements PluginControl {
  private readonly options: ControlChannelOptions;
  private readonly instanceId: string;
  private readonly socketFactory: SocketFactory;
  private readonly random: () => number;
  private socket: ControlSocket | null = null;
  private reconnectTimer: NodeJS.Timeout | null = null;
  private running = false;
  private attempt = 0;
  private openCodeVersion: string | null = null;
  private registered = false;
  private collectionInFlight: Promise<PendingInteraction[]> | null = null;

  constructor(options: ControlChannelOptions) {
    this.options = options;
    this.instanceId = (options.randomUUID ?? nodeRandomUUID)();
    this.random = options.random ?? Math.random;
    this.socketFactory = options.socketFactory ?? defaultSocketFactory;
  }

  start(): void {
    if (this.running) {
      return;
    }
    this.running = true;
    void this.connect();
  }

  stop(): void {
    this.running = false;
    this.registered = false;
    if (this.reconnectTimer !== null) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = null;
    }
    const socket = this.socket;
    this.socket = null;
    try {
      socket?.close(1000, "Plugin disposed");
    } catch {
      // Control teardown must never affect OpenCode shutdown.
    }
  }

  private async connect(): Promise<void> {
    if (!this.running || this.socket !== null) {
      return;
    }
    if (this.openCodeVersion === null) {
      try {
        const version = await this.resolveVersion();
        this.openCodeVersion = version.trim().length > 0 ? version.trim() : "unknown";
      } catch {
        this.openCodeVersion = "unknown";
      }
    }
    if (!this.running) {
      return;
    }

    let socket: ControlSocket;
    try {
      socket = this.socketFactory(
        controlUrl(this.options.gatewayUrl),
        `Bearer ${this.options.credential}`,
      );
    } catch {
      this.scheduleReconnect();
      return;
    }
    this.socket = socket;
    this.registered = false;
    socket.addEventListener("open", () => {
      if (!this.running || this.socket !== socket) {
        return;
      }
      this.attempt = 0;
      const registration: PluginControlClientMessage = {
        type: "register",
        instanceId: this.instanceId,
        machine: this.options.machine,
        project: this.options.project,
        directory: this.options.directory,
        openCodeVersion: this.openCodeVersion ?? "unknown",
        protocolVersion: 1,
      };
      try {
        socket.send(JSON.stringify(registration));
      } catch {
        this.drop(socket);
      }
    });
    socket.addEventListener("close", (event) => {
      if (closeCode(event) === 4403) {
        this.running = false;
        this.socket = null;
        return;
      }
      this.drop(socket);
    });
    socket.addEventListener("error", () => this.drop(socket));
    socket.addEventListener("message", (event) => {
      if (!this.running || this.socket !== socket) {
        return;
      }
      this.onServerFrame(socket, event);
    });
  }

  /**
   * Handle one server frame. Only a `pending_snapshot_request` or a
   * `question_answer_command` received after the Gateway confirmed
   * registration produces a reply; every other frame — registration
   * results, unknown types, malformed JSON, non-string payloads, and
   * either request type before registration — is ignored without ever
   * throwing, so notification behavior is unaffected.
   */
  private onServerFrame(socket: ControlSocket, event: unknown): void {
    const data = messageData(event);
    if (data === null) {
      return;
    }
    let parsed: unknown;
    try {
      parsed = JSON.parse(data) as unknown;
    } catch {
      return; // malformed frame: ignore and keep the channel alive
    }
    if (parsed === null || typeof parsed !== "object") {
      return;
    }
    const frame = parsed as Record<string, unknown>;
    if (frame.type === "registration") {
      this.registered = true;
      return;
    }
    if (!this.registered) {
      return; // commands and requests before registration are ignored
    }
    if (frame.type === "pending_snapshot_request") {
      if (typeof frame.requestId !== "string" || frame.requestId.length === 0) {
        return;
      }
      void this.answerSnapshot(socket, frame.requestId);
      return;
    }
    if (frame.type === "question_answer_command") {
      const command = parseAnswerCommand(frame);
      if (command === null) {
        return; // malformed answer command: ignore and keep the channel alive
      }
      void this.answerCommand(socket, command);
    }
  }

  /**
   * Answer a snapshot request with the channel's stable instanceId. Never
   * throws: adapter failures and timeouts both yield an empty interaction
   * list, and a socket that vanished mid-query is left alone.
   */
  private async answerSnapshot(socket: ControlSocket, requestId: string): Promise<void> {
    const interactions = await this.collectInteractions();
    if (!this.running || this.socket !== socket) {
      return;
    }
    const response: PluginControlClientMessage = {
      type: "pending_snapshot_response",
      requestId,
      instanceId: this.instanceId,
      interactions,
    };
    try {
      socket.send(JSON.stringify(response));
    } catch {
      // A failed reply must never affect notification behavior.
    }
  }

  /**
   * Answer an answer command with the channel's stable instanceId and the
   * seam's terminal status. Every command runs independently (different
   * commandIds are never coalesced onto one upstream call). Never throws:
   * a missing seam, seam failure, or timeout all report `result_unknown`,
   * and a socket that vanished mid-reply is left alone.
   */
  private async answerCommand(socket: ControlSocket, command: AnswerCommand): Promise<void> {
    const status = await this.runAnswer(command);
    if (!this.running || this.socket !== socket) {
      return;
    }
    const result: PluginControlClientMessage = {
      type: "question_answer_result",
      commandId: command.commandId,
      instanceId: this.instanceId,
      status,
    };
    try {
      socket.send(JSON.stringify(result));
    } catch {
      // A failed reply must never affect notification behavior.
    }
  }

  /** Run the injected answer seam under a bounded abort timeout. */
  private async runAnswer(command: AnswerCommand): Promise<QuestionCommandStatus> {
    if (this.options.answerQuestion === undefined) {
      return "result_unknown";
    }
    const abort = new AbortController();
    let timeout: NodeJS.Timeout | null = null;
    try {
      return await Promise.race([
        this.options.answerQuestion(
          command.requestId,
          this.options.directory,
          command.answers,
          abort.signal,
        ),
        new Promise<QuestionCommandStatus>((resolve) => {
          timeout = setTimeout(() => {
            abort.abort();
            resolve("result_unknown");
          }, this.options.answerTimeoutMs ?? QUESTION_ANSWER_TIMEOUT_MS);
        }),
      ]);
    } catch {
      return "result_unknown";
    } finally {
      if (timeout !== null) {
        clearTimeout(timeout);
      }
    }
  }

  /** Run the injected seam under a bounded timeout, failing closed to []. */
  private async collectInteractions(): Promise<PendingInteraction[]> {
    const active = this.collectionInFlight;
    if (active !== null) {
      return active;
    }
    const operation = this.runCollection();
    this.collectionInFlight = operation;
    void operation.finally(() => {
      if (this.collectionInFlight === operation) {
        this.collectionInFlight = null;
      }
    });
    return operation;
  }

  private async runCollection(): Promise<PendingInteraction[]> {
    if (this.options.listPendingInteractions === undefined) {
      return [];
    }
    const source: PendingSource = {
      instanceId: this.instanceId,
      machine: this.options.machine,
      project: this.options.project,
      directory: this.options.directory,
    };
    const abort = new AbortController();
    let timeout: NodeJS.Timeout | null = null;
    try {
      return await Promise.race([
        this.options.listPendingInteractions(source, abort.signal),
        new Promise<PendingInteraction[]>((resolve) => {
          timeout = setTimeout(
            () => {
              abort.abort();
              resolve([]);
            },
            this.options.pendingSnapshotTimeoutMs ?? DEFAULT_PENDING_SNAPSHOT_TIMEOUT_MS,
          );
        }),
      ]);
    } catch {
      return [];
    } finally {
      if (timeout !== null) {
        clearTimeout(timeout);
      }
    }
  }

  private drop(socket: ControlSocket): void {
    if (this.socket !== socket) {
      return;
    }
    this.socket = null;
    this.registered = false;
    try {
      socket.close();
    } catch {
      // Ignore platform close failures; reconnect remains best-effort.
    }
    this.scheduleReconnect();
  }

  private scheduleReconnect(): void {
    if (!this.running || this.reconnectTimer !== null) {
      return;
    }
    const exponential = Math.min(BASE_BACKOFF_MS * 2 ** Math.min(this.attempt++, 6), MAX_BACKOFF_MS);
    const delay = Math.round(exponential * (0.75 + 0.5 * this.random()));
    this.reconnectTimer = setTimeout(() => {
      this.reconnectTimer = null;
      void this.connect();
    }, delay);
  }

  private async resolveVersion(): Promise<string> {
    let timeout: NodeJS.Timeout | null = null;
    try {
      return await Promise.race([
        this.options.resolveOpenCodeVersion(),
        new Promise<string>((resolve) => {
          timeout = setTimeout(
            () => resolve("unknown"),
            this.options.versionTimeoutMs ?? 5_000,
          );
        }),
      ]);
    } finally {
      if (timeout !== null) {
        clearTimeout(timeout);
      }
    }
  }
}

function controlUrl(gatewayUrl: string): string {
  const url = new URL(`${gatewayUrl}/v1/plugin/ws`);
  url.protocol = url.protocol === "https:" ? "wss:" : "ws:";
  return url.toString();
}

/** One validated `question_answer_command` server frame. */
interface AnswerCommand {
  commandId: string;
  requestId: string;
  answers: QuestionAnswers;
}

/**
 * Structurally validate a `question_answer_command` frame against the
 * contract's shape (uuid commandId, nonempty requestId, non-empty ordered
 * `string[][]` answers). Returns null for anything malformed so the
 * channel ignores it without a reply.
 */
function parseAnswerCommand(frame: Record<string, unknown>): AnswerCommand | null {
  if (!isUuid(frame.commandId)) {
    return null;
  }
  if (typeof frame.requestId !== "string" || frame.requestId.length === 0) {
    return null;
  }
  if (!isQuestionAnswers(frame.answers)) {
    return null;
  }
  return {
    commandId: frame.commandId,
    requestId: frame.requestId,
    answers: frame.answers,
  };
}

/** Contract `format: "uuid"` (same charset ajv-formats accepts). */
const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function isUuid(value: unknown): value is string {
  return typeof value === "string" && UUID_PATTERN.test(value);
}

/** Contract `QuestionAnswers` check: non-empty array of non-empty strings. */
function isQuestionAnswers(value: unknown): value is QuestionAnswers {
  if (!Array.isArray(value) || value.length === 0) {
    return false;
  }
  for (const outer of value) {
    if (!Array.isArray(outer) || outer.length === 0) {
      return false;
    }
    for (const answer of outer) {
      if (typeof answer !== "string" || answer.length === 0) {
        return false;
      }
    }
  }
  return true;
}

function defaultSocketFactory(url: string, authorization: string): ControlSocket {
  const Constructor = globalThis.WebSocket as unknown as new (
    url: string,
    options: { headers: Record<string, string> },
  ) => ControlSocket;
  return new Constructor(url, { headers: { Authorization: authorization } });
}

function closeCode(event: unknown): number | null {
  if (event === null || typeof event !== "object" || !("code" in event)) {
    return null;
  }
  const code = (event as { code?: unknown }).code;
  return typeof code === "number" ? code : null;
}

/** Extract the string payload of a WebSocket message event, if present. */
function messageData(event: unknown): string | null {
  if (event === null || typeof event !== "object" || !("data" in event)) {
    return null;
  }
  const data = (event as { data?: unknown }).data;
  return typeof data === "string" ? data : null;
}
