import { readFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";
import { validateSessionCatalog, type SessionCatalog, type SessionCatalogQuery, type PermissionDecision } from "@notify/contracts";
import { createLoopbackDirectFetch } from "./direct-fetch.js";
import { isInternalSession } from "./session-registry.js";
import { PendingAdapter, type PendingSource } from "./pending-adapter.js";
import type { HostSession } from "./index.js";
import { WebUiProxy } from "./webui-proxy.js";
import type { WebUiHttpRequest, WebUiResponseFrame } from "./control-channel.js";

export interface V2Session {
  id: string;
  parentID?: string;
  title?: string;
  location: { directory: string };
  time: { updated: number; archived?: number };
}

export interface V2Form {
  id: string;
  sessionID: string;
  metadata?: { kind?: string; tool?: { messageID: string; id: string } };
  fields: Array<{
    key: string;
    type: string;
    title?: string;
    description?: string;
    custom?: boolean;
    options?: Array<{ value: string; label: string; description?: string }>;
  }>;
}

/** Only the built-in question tool has the ordered-answer semantics Notify uses. */
export function questionFromForm(form: V2Form) {
  if (form.metadata?.kind !== "question" || !form.fields?.length || form.fields.some((field, index) =>
    field.key !== `q${index}` || !["string", "multiselect"].includes(field.type) ||
    !field.options || field.options.some(option => option.value !== option.label),
  )) return null;
  return {
    id: form.id,
    sessionID: form.sessionID,
    questions: form.fields.map(field => ({
      header: field.title || "Question",
      question: field.description || field.title || "Question",
      options: field.options,
      multiple: field.type === "multiselect",
      custom: field.custom === true,
    })),
    ...(form.metadata.tool ? { tool: { messageID: form.metadata.tool.messageID, callID: form.metadata.tool.id } } : {}),
  };
}

export function hostSession(session: V2Session): HostSession {
  if (!session || typeof session.id !== "string" || typeof session.location?.directory !== "string" ||
      typeof session.time?.updated !== "number") throw new Error("Invalid V2 session");
  return { ...session, title: session.title ?? "", directory: session.location.directory };
}

class ApiError extends Error {
  constructor(readonly status: number, readonly tag?: string) { super(`OpenCode HTTP ${status}`); }
}

/** V2 HTTP APIs missing from the plugin context, bound to this exact server process. */
export class V2Api {
  private endpoint?: { url: URL; fetch: typeof fetch };
  private connecting?: Promise<{ url: URL; fetch: typeof fetch }>;
  private pending: PendingAdapter;
  webUiAvailable = false;

  constructor(readonly directory: string, title: (id: string) => string | undefined) {
    this.pending = new PendingAdapter({
      titleForSession: title,
      client: {
        question: { request: { list: async (_params, options) => {
          const result = await this.json<{ data: V2Form[] }>(this.locationPath("/api/form"), options?.signal);
          return { data: { data: result.data.map(questionFromForm).filter(Boolean) } };
        } } },
        permission: { request: { list: async (_params, options) => {
          const result = await this.json<{ data: Array<{ source?: { id: string } }> }>(this.locationPath("/api/permission/request"), options?.signal);
          return { data: { data: result.data.map(item => ({ ...item,
            ...(item.source ? { source: { ...item.source, callID: item.source.id } } : {}),
          })) } };
        } } },
      },
    });
  }

  private locationPath(path: string) {
    return `${path}?${new URLSearchParams({ "location[directory]": this.directory })}`;
  }

  private async connect() {
    let url: URL;
    let password: string | undefined;
    if (process.env.NOTIFY_OPENCODE_URL) {
      url = new URL(process.env.NOTIFY_OPENCODE_URL);
      password = process.env.NOTIFY_OPENCODE_PASSWORD || process.env.OPENCODE_PASSWORD || process.env.OPENCODE_SERVER_PASSWORD;
    } else {
      const file = join(process.env.XDG_STATE_HOME ?? join(homedir(), ".local", "state"), "opencode", "service.json");
      const info = JSON.parse(await readFile(file, "utf8"));
      if (info.pid !== process.pid) throw new Error("OpenCode service belongs to another process");
      url = new URL(info.url);
      password = info.password;
    }
    if (!["http:", "https:"].includes(url.protocol) || url.username || url.password ||
        url.pathname !== "/" || url.search || url.hash) throw new Error("Invalid OpenCode origin");
    const direct = createLoopbackDirectFetch();
    const authenticated = (async (input: Parameters<typeof fetch>[0], init?: RequestInit) => {
      const request = new Request(input, init);
      if (new URL(request.url).origin !== url.origin) throw new Error("OpenCode origin mismatch");
      request.headers.delete("authorization");
      if (password) request.headers.set("authorization", `Basic ${Buffer.from(`opencode:${password}`).toString("base64")}`);
      return direct(request);
    }) as typeof fetch;
    const response = await authenticated(new URL("/api/info", url), { signal: AbortSignal.timeout(5000) });
    if (!response.ok) throw new Error("OpenCode V2 health unavailable");
    const info = await response.json() as { pid?: number; version?: string };
    if (info.pid !== process.pid || !/^2\./.test(info.version ?? "")) throw new Error("OpenCode server identity mismatch");
    this.webUiAvailable = true;
    return { url, fetch: authenticated };
  }

  private async server() {
    if (this.endpoint) return this.endpoint;
    this.connecting ??= this.connect();
    try { return this.endpoint = await this.connecting; }
    finally { this.connecting = undefined; }
  }

  async probe() { await this.server(); }

  private async request(path: string, signal?: AbortSignal, body?: unknown) {
    const server = await this.server();
    signal?.throwIfAborted();
    return server.fetch(new URL(path, server.url), {
      method: body === undefined ? "GET" : "POST",
      headers: body === undefined ? {} : { "content-type": "application/json" },
      ...(body === undefined ? {} : { body: JSON.stringify(body) }),
      signal: signal ?? AbortSignal.timeout(5000),
    });
  }

  private async json<T>(path: string, signal?: AbortSignal): Promise<T> {
    const response = await this.request(path, signal);
    if (!response.ok) {
      const error = await response.json().catch(() => ({})) as { _tag?: string };
      throw new ApiError(response.status, error._tag);
    }
    return response.json() as Promise<T>;
  }

  async sessions(limit: number, signal: AbortSignal, search?: string) {
    const query = new URLSearchParams({ directory: this.directory, parentID: "null", limit: String(limit) });
    if (search) query.set("search", search);
    const page = await this.json<{ data: V2Session[] }>(`/api/session?${query}`, signal);
    return { data: page.data.map(hostSession) };
  }

  async session(id: string, signal: AbortSignal) {
    const result = await this.json<{ data: V2Session }>(`/api/session/${encodeURIComponent(id)}`, signal);
    const session = hostSession(result.data);
    if (session.id !== id || session.directory !== this.directory) throw new ApiError(404, "SessionNotFoundError");
    return session;
  }

  async catalog(query: SessionCatalogQuery, signal: AbortSignal) {
    const limit = query.limit ?? 50;
    const [page, active] = await Promise.all([
      this.sessions(limit + 1, signal, query.search),
      this.json<{ data: Record<string, { type: string }> }>("/api/session/active", signal).catch(() => undefined),
    ]);
    const visible = (s: HostSession) => s.directory === this.directory && !s.parentID && !s.time.archived && !isInternalSession(s.title);
    const sessions = new Map(page.data.slice(0, limit).filter(visible).map(s => [s.id, s]));
    for (const id of [...new Set(query.sessionIds?.split(",").filter(Boolean))].slice(0, 50)) {
      if (sessions.has(id)) continue;
      try {
        const s = await this.session(id, signal);
        if (visible(s)) sessions.set(id, s);
      } catch (error) { if (!(error instanceof ApiError && error.status === 404)) throw error; }
    }
    const catalog: SessionCatalog = {
      hasMore: page.data.length > limit,
      sessions: [...sessions.values()].map(s => ({
        sessionId: s.id, title: s.title.slice(0, 1000), directory: s.directory,
        updatedAt: new Date(s.time.updated).toISOString(),
        status: active ? (active.data[s.id] ? "busy" : "idle") : "unknown",
      })),
    };
    if (!validateSessionCatalog(catalog)) throw new Error("Invalid V2 session catalog");
    return catalog;
  }

  listPending(source: PendingSource, signal: AbortSignal) { return this.pending.list(source, signal); }

  private async command(sessionID: string, signal: AbortSignal, path: string, body: () => Promise<unknown>) {
    try {
      await this.session(sessionID, signal);
      const payload = await body();
      const response = await this.request(path, signal, payload);
      if (response.ok) { await response.body?.cancel(); return "confirmed" as const; }
      const error = await response.json().catch(() => ({})) as { _tag?: string };
      return this.commandError(new ApiError(response.status, error._tag));
    } catch (error) { return this.commandError(error); }
  }

  private commandError(error: unknown) {
    if (!(error instanceof ApiError)) return "result_unknown" as const;
    return ["SessionNotFoundError", "FormNotFoundError", "FormAlreadySettledError", "PermissionNotFoundError"].includes(error.tag ?? "")
      ? "stale" as const : "upstream_error" as const;
  }

  answer(requestID: string, sessionID: string, answers: string[][], signal: AbortSignal) {
    const path = `/api/session/${encodeURIComponent(sessionID)}/form/${encodeURIComponent(requestID)}`;
    return this.command(sessionID, signal, `${path}/reply`, async () => {
      const { data: form } = await this.json<{ data: V2Form & { state: { status: string } } }>(path, signal);
      if (form.state.status !== "pending") throw new ApiError(409, "FormAlreadySettledError");
      if (!questionFromForm(form) || form.fields.length !== answers.length ||
          form.fields.some((field, i) => field.type === "string" && answers[i]!.length > 1)) throw new ApiError(400);
      return { answer: Object.fromEntries(form.fields.map((field, i) =>
        [field.key, field.type === "multiselect" ? answers[i] : answers[i]![0] ?? ""],
      )) };
    });
  }

  decide(requestID: string, sessionID: string, decision: PermissionDecision, signal: AbortSignal) {
    return this.command(sessionID, signal,
      `/api/session/${encodeURIComponent(sessionID)}/permission/${encodeURIComponent(requestID)}/reply`,
      async () => ({ decision }));
  }

  async prompt(sessionID: string, text: string, signal: AbortSignal) {
    const status = await this.command(sessionID, signal, `/api/session/${encodeURIComponent(sessionID)}/prompt`, async () => ({ text }));
    return status === "stale" ? "upstream_error" : status;
  }

  async webUi(request: WebUiHttpRequest, signal: AbortSignal, emit: (frame: WebUiResponseFrame) => void) {
    const server = await this.server();
    await new WebUiProxy({ baseUrl: server.url, directory: this.directory, fetch: server.fetch, generation: 2 }).request(request, signal, emit);
  }
}
