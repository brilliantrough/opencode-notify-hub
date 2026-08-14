/**
 * Pending-interaction adapter.
 *
 * The read-only slice of remote unblock: this adapter polls the owning
 * OpenCode instance's authoritative `/question` and `/permission` lists
 * through the V2 SDK and maps them onto the strict contract
 * `PendingInteraction` union.
 *
 * Guarantees:
 * - **Instance-scoped.** Every list call passes the plugin's own
 *   `directory`, so one machine with several Servers never sees another
 *   Server's pending requests.
 * - **Never drops authorization context.** Permission `patterns`,
 *   `always`, `metadata`, and tool identity are retained verbatim; question
 *   options keep their full descriptions.
 * - **Normalizes upstream omissions.** A question item without a `multiple`
 *   flag reads as single-select (`false`), and one without a `custom` flag
 *   reads as custom-enabled (`true`) — OpenCode 1.18.18 accepts custom
 *   answers even when the payload omits the flag.
 * - **Stable first-observed time.** `occurredAt` is the first poll at which
 *   a request was seen and stays stable for as long as the request remains
 *   present; when a request disappears, its entry is dropped so a
 *   reappearance starts a fresh wait.
 * - **Fail closed.** A throwing SDK call or an SDK `{ data, error }` error
 *   envelope contributes no interactions; the control channel turns an
 *   unavailable list into an empty snapshot.
 * - **Provider actions excluded by construction.** The adapter only reads
 *   question and permission endpoints; provider actions are ordinary
 *   notifications and can never enter the pending snapshot.
 *
 * The adapter itself never throws.
 */

import type { PendingInteraction } from "@notify/contracts";

/** Source identity stamped onto every mapped interaction. */
export interface PendingSource {
  instanceId: string;
  machine: string;
  project: string;
  directory: string;
}

/** Minimal structural surface of the OpenCode V2 SDK list endpoints. */
export interface PendingListClient {
  question: {
    list(
      params?: { directory?: string; workspace?: string },
      options?: { signal?: AbortSignal },
    ): Promise<unknown>;
  };
  permission: {
    list(
      params?: { directory?: string; workspace?: string },
      options?: { signal?: AbortSignal },
    ): Promise<unknown>;
  };
}

export interface PendingAdapterOptions {
  /** V2 SDK client exposing `question.list` / `permission.list`. */
  client: PendingListClient;
  /** Best-effort session title lookup; `undefined` becomes `""`. */
  titleForSession: (sessionID: string) => string | undefined;
  /** Clock seam for `occurredAt`; defaults to the wall clock. */
  now?: () => Date;
}

/** Contract question item shape produced by the adapter. */
interface PendingQuestionItem {
  header: string;
  question: string;
  options: Array<{ label: string; description: string }>;
  multiple: boolean;
  custom: boolean;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function asNonEmptyString(value: unknown): string | null {
  return typeof value === "string" && value.length > 0 ? value : null;
}

/**
 * Extract the SDK `{ data, error }` list payload. Returns `null` for an
 * error envelope or any non-array payload so the adapter fails closed.
 */
function listPayload(response: unknown): unknown[] | null {
  if (Array.isArray(response)) {
    return response;
  }
  if (!isRecord(response)) {
    return null;
  }
  if (response.error != null) {
    return null;
  }
  return Array.isArray(response.data) ? response.data : null;
}

/** Rename the upstream tool fields to the contract's lower-camel names. */
function mapTool(tool: unknown): { messageId: string; callId: string } | undefined {
  if (!isRecord(tool)) {
    return undefined;
  }
  const messageId = asNonEmptyString(tool.messageID);
  const callId = asNonEmptyString(tool.callID);
  if (messageId === null || callId === null) {
    return undefined;
  }
  return { messageId, callId };
}

export class PendingAdapter {
  private readonly client: PendingListClient;
  private readonly titleForSession: (sessionID: string) => string | undefined;
  private readonly now: () => Date;
  /** First observed `occurredAt` per `kind:requestId`, dropped once absent. */
  private readonly firstObserved = new Map<string, string>();

  constructor(options: PendingAdapterOptions) {
    this.client = options.client;
    this.titleForSession = options.titleForSession;
    this.now = options.now ?? (() => new Date());
  }

  /**
   * Poll both authoritative lists for the owning instance and return the
   * mapped pending interactions. Never throws: a failed or unavailable
   * list yields an empty snapshot.
   */
  async list(source: PendingSource, signal?: AbortSignal): Promise<PendingInteraction[]> {
    let questionResponse: unknown;
    let permissionResponse: unknown;
    try {
      const options = signal === undefined ? undefined : { signal };
      [questionResponse, permissionResponse] = await Promise.all([
        options === undefined
          ? this.client.question.list({ directory: source.directory })
          : this.client.question.list({ directory: source.directory }, options),
        options === undefined
          ? this.client.permission.list({ directory: source.directory })
          : this.client.permission.list({ directory: source.directory }, options),
      ]);
    } catch {
      return [];
    }
    const questionRequests = listPayload(questionResponse);
    const permissionRequests = listPayload(permissionResponse);
    if (questionRequests === null || permissionRequests === null) {
      // Either authoritative list is unavailable; a partial projection
      // would claim authority the adapter does not hold.
      return [];
    }

    const interactions: PendingInteraction[] = [];
    for (const raw of questionRequests) {
      const mapped = this.mapQuestion(raw, source);
      if (mapped !== null) {
        interactions.push(mapped);
      }
    }
    for (const raw of permissionRequests) {
      const mapped = this.mapPermission(raw, source);
      if (mapped !== null) {
        interactions.push(mapped);
      }
    }
    return this.stampOccurredAt(interactions);
  }

  private mapQuestion(raw: unknown, source: PendingSource): PendingInteraction | null {
    if (!isRecord(raw)) {
      return null;
    }
    const id = asNonEmptyString(raw.id);
    const sessionID = asNonEmptyString(raw.sessionID);
    if (id === null || sessionID === null || !Array.isArray(raw.questions)) {
      return null;
    }
    const items: PendingQuestionItem[] = [];
    for (const item of raw.questions) {
      const mapped = this.mapQuestionItem(item);
      if (mapped !== null) {
        items.push(mapped);
      }
    }
    if (items.length === 0) {
      return null;
    }
    const tool = mapTool(raw.tool);
    return {
      kind: "question",
      instanceId: source.instanceId,
      machine: source.machine,
      project: source.project,
      directory: source.directory,
      sessionId: sessionID,
      sessionTitle: this.titleForSession(sessionID) ?? "",
      requestId: id,
      occurredAt: "",
      questions: items,
      ...(tool !== undefined ? { tool } : {}),
    };
  }

  private mapQuestionItem(item: unknown): PendingQuestionItem | null {
    if (!isRecord(item)) {
      return null;
    }
    const header = asNonEmptyString(item.header);
    const question = asNonEmptyString(item.question);
    if (header === null || question === null || !Array.isArray(item.options)) {
      return null;
    }
    const options: Array<{ label: string; description: string }> = [];
    for (const option of item.options) {
      if (!isRecord(option)) {
        continue;
      }
      const label = asNonEmptyString(option.label);
      if (label === null) {
        continue;
      }
      options.push({
        label,
        description: typeof option.description === "string" ? option.description : "",
      });
    }
    return {
      header,
      question,
      options,
      multiple: typeof item.multiple === "boolean" ? item.multiple : false,
      custom: typeof item.custom === "boolean" ? item.custom : true,
    };
  }

  private mapPermission(raw: unknown, source: PendingSource): PendingInteraction | null {
    if (!isRecord(raw)) {
      return null;
    }
    const id = asNonEmptyString(raw.id);
    const sessionID = asNonEmptyString(raw.sessionID);
    const permission = asNonEmptyString(raw.permission);
    if (
      id === null ||
      sessionID === null ||
      permission === null ||
      !Array.isArray(raw.patterns) ||
      !Array.isArray(raw.always)
    ) {
      return null;
    }
    const strings = (value: unknown): string[] =>
      Array.isArray(value) ? value.filter((entry): entry is string => typeof entry === "string") : [];
    const mappedTool = mapTool(raw.tool);
    return {
      kind: "permission",
      instanceId: source.instanceId,
      machine: source.machine,
      project: source.project,
      directory: source.directory,
      sessionId: sessionID,
      sessionTitle: this.titleForSession(sessionID) ?? "",
      requestId: id,
      occurredAt: "",
      permission,
      patterns: strings(raw.patterns),
      always: strings(raw.always),
      metadata: isRecord(raw.metadata) ? raw.metadata : {},
      ...(mappedTool !== undefined ? { tool: mappedTool } : {}),
    };
  }

  /**
   * Assign a stable first-observed `occurredAt` per `kind:requestId` while
   * the request stays present, then drop entries for requests that left.
   */
  private stampOccurredAt(interactions: PendingInteraction[]): PendingInteraction[] {
    const seen = new Set<string>();
    const nowIso = this.now().toISOString();
    for (const interaction of interactions) {
      const key = `${interaction.kind}:${interaction.requestId}`;
      seen.add(key);
      const first = this.firstObserved.get(key);
      const occurredAt = first ?? nowIso;
      interaction.occurredAt = occurredAt;
      if (first === undefined) {
        this.firstObserved.set(key, occurredAt);
      }
    }
    for (const key of this.firstObserved.keys()) {
      if (!seen.has(key)) {
        this.firstObserved.delete(key);
      }
    }
    return interactions;
  }
}
